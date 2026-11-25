# Auto-generated client for Orthanc API v1.11.3
# Source: https://api.apis.guru/v2/specs/orthanc-server.com/1.11.3/openapi.json
# Auth: --token flag or $env.ORTHANC_API_TOKEN

const CLIENT = {
  base_url: "https://demo.orthanc-server.com"
  token_env_var: "ORTHANC_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://demo.orthanc-server.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/dicom" "application/dicom+json" "application/dicom+xml"] }
def accept-completer-1 [] { ["image/jpeg" "image/png" "image/x-portable-arbitrarymap"] }
def accept-completer-2 [] { ["application/json" "application/zip"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-changes: "record<Changes: list<record>, Done: bool, Last: float>"
    post-instances: "record<ID: string, ParentPatient: string, ParentSeries: string, ParentStudy: string, Path: string, Status: string>"
    get-instances-id-statistics: "record<DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>"
    post-modalities-id-move: "record<ID: string, Path: string>"
    post-modalities-id-query: "record<ID: record, Path: record>"
    post-modalities-id-storage-commitment: "record<ID: record, Path: record>"
    post-modalities-id-store: "record<ID: string, Path: string>"
    post-modalities-id-store-straight: "record<SOPClassUID: string, SOPInstanceUID: string>"
    post-patients-id-anonymize: "record<ID: string, Path: string>"
    post-patients-id-archive: "record<ID: string, Path: string>"
    post-patients-id-media: "record<ID: string, Path: string>"
    post-patients-id-modify: "record<ID: string, Path: string>"
    get-patients-id-statistics: "record<CountInstances: float, CountSeries: float, CountStudies: float, DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>"
    post-peers-id-store: "record<ID: string, Path: string>"
    post-peers-id-store-straight: "record<ID: string, ParentPatient: string, ParentSeries: string, ParentStudy: string, Path: string, Status: string>"
    post-queries-id-answers-index-query-instances: "record<ID: record, Path: record>"
    post-queries-id-answers-index-query-series: "record<ID: record, Path: record>"
    post-queries-id-answers-index-query-studies: "record<ID: record, Path: record>"
    post-queries-id-answers-index-retrieve: "record<ID: string, Path: string>"
    post-queries-id-retrieve: "record<ID: string, Path: string>"
    post-series-id-anonymize: "record<ID: string, Path: string>"
    post-series-id-archive: "record<ID: string, Path: string>"
    post-series-id-media: "record<ID: string, Path: string>"
    post-series-id-modify: "record<ID: string, Path: string>"
    get-series-id-ordered-slices: "record<Dicom: list<string>, Slices: list<string>, SlicesShort: list<record>, Type: string>"
    get-series-id-statistics: "record<CountInstances: float, DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>"
    get-statistics: "record<CountInstances: float, CountPatients: float, CountSeries: float, CountStudies: float, TotalDiskSize: string, TotalDiskSizeMB: float, TotalUncompressedSize: string, TotalUncompressedSizeMB: float>"
    get-storage-commitment-id: "record<Failures: list<record>, RemoteAET: string, Status: string, Success: list<record>>"
    post-studies-id-anonymize: "record<ID: string, Path: string>"
    post-studies-id-archive: "record<ID: string, Path: string>"
    post-studies-id-media: "record<ID: string, Path: string>"
    post-studies-id-merge: "record<ID: string, Path: string>"
    post-studies-id-modify: "record<ID: string, Path: string>"
    post-studies-id-split: "record<ID: string, Path: string>"
    get-studies-id-statistics: "record<CountInstances: float, CountSeries: float, DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>"
    get-system: "record<ApiVersion: float, CheckRevisions: bool, DatabaseBackendPlugin: string, DatabaseServerIdentifier: string, DatabaseVersion: float, DicomAet: string, DicomPort: float, HttpPort: float, IngestTranscoding: string, IsHttpServerSecure: bool, MainDicomTags: record, MaximumStorageMode: string, MaximumStorageSize: float, Name: string, OverwriteInstances: bool, PluginsEnabled: bool, StorageAreaPlugin: string, StorageCompression: bool, Version: string>"
    post-tools-bulk-anonymize: "record<ID: string, Path: string>"
    post-tools-bulk-modify: "record<ID: string, Path: string>"
    post-tools-create-archive: "record<ID: string, Path: string>"
    post-tools-create-dicom: "record<ID: string, Path: string>"
    post-tools-create-media: "record<ID: string, Path: string>"
    post-tools-create-media-extended: "record<ID: string, Path: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-changes" "get-changes" "delete-exports" "get-exports" "get-instances" "post-instances" "delete-instances-id" "get-instances-id" "post-instances-id-anonymize" "get-instances-id-attachments" "delete-instances-id-attachments-name" "get-instances-id-attachments-name" "put-instances-id-attachments-name" "post-instances-id-attachments-name-compress" "get-instances-id-attachments-name-compressed-data" "get-instances-id-attachments-name-compressed-md5" "get-instances-id-attachments-name-compressed-size" "get-instances-id-attachments-name-data" "get-instances-id-attachments-name-info" "get-instances-id-attachments-name-is-compressed" "get-instances-id-attachments-name-md5" "get-instances-id-attachments-name-size" "post-instances-id-attachments-name-uncompress" "post-instances-id-attachments-name-verify-md5" "get-instances-id-content" "post-instances-id-export" "get-instances-id-file" "get-instances-id-frames" "get-instances-id-frames-frame" "get-instances-id-frames-frame-image-int16" "get-instances-id-frames-frame-image-uint16" "get-instances-id-frames-frame-image-uint8" "get-instances-id-frames-frame-matlab" "get-instances-id-frames-frame-numpy" "get-instances-id-frames-frame-preview" "get-instances-id-frames-frame-raw" "get-instances-id-frames-frame-raw-gz" "get-instances-id-frames-frame-rendered" "get-instances-id-header" "get-instances-id-image-int16" "get-instances-id-image-uint16" "get-instances-id-image-uint8" "get-instances-id-matlab" "get-instances-id-metadata" "delete-instances-id-metadata-name" "get-instances-id-metadata-name" "put-instances-id-metadata-name" "post-instances-id-modify" "get-instances-id-module" "get-instances-id-numpy" "get-instances-id-patient" "get-instances-id-pdf" "get-instances-id-preview" "post-instances-id-reconstruct" "get-instances-id-rendered" "get-instances-id-series" "get-instances-id-simplified-tags" "get-instances-id-statistics" "get-instances-id-study" "get-instances-id-tags" "get-jobs" "get-jobs-id" "post-jobs-id-cancel" "post-jobs-id-pause" "post-jobs-id-resubmit" "post-jobs-id-resume" "get-jobs-id-key" "get-modalities" "delete-modalities-id" "get-modalities-id" "put-modalities-id" "get-modalities-id-configuration" "post-modalities-id-echo" "post-modalities-id-find" "post-modalities-id-find-instance" "post-modalities-id-find-patient" "post-modalities-id-find-series" "post-modalities-id-find-study" "post-modalities-id-find-worklist" "post-modalities-id-move" "post-modalities-id-query" "post-modalities-id-storage-commitment" "post-modalities-id-store" "post-modalities-id-store-straight" "get-patients" "delete-patients-id" "get-patients-id" "post-patients-id-anonymize" "get-patients-id-archive" "post-patients-id-archive" "get-patients-id-attachments" "delete-patients-id-attachments-name" "get-patients-id-attachments-name" "put-patients-id-attachments-name" "post-patients-id-attachments-name-compress" "get-patients-id-attachments-name-compressed-data" "get-patients-id-attachments-name-compressed-md5" "get-patients-id-attachments-name-compressed-size" "get-patients-id-attachments-name-data" "get-patients-id-attachments-name-info" "get-patients-id-attachments-name-is-compressed" "get-patients-id-attachments-name-md5" "get-patients-id-attachments-name-size" "post-patients-id-attachments-name-uncompress" "post-patients-id-attachments-name-verify-md5" "get-patients-id-instances" "get-patients-id-instances-tags" "get-patients-id-media" "post-patients-id-media" "get-patients-id-metadata" "delete-patients-id-metadata-name" "get-patients-id-metadata-name" "put-patients-id-metadata-name" "post-patients-id-modify" "get-patients-id-module" "get-patients-id-protected" "put-patients-id-protected" "post-patients-id-reconstruct" "get-patients-id-series" "get-patients-id-shared-tags" "get-patients-id-statistics" "get-patients-id-studies" "get-peers" "delete-peers-id" "get-peers-id" "put-peers-id" "get-peers-id-configuration" "post-peers-id-store" "post-peers-id-store-straight" "get-peers-id-system" "get-plugins" "get-plugins-explorer-js" "get-plugins-id" "get-queries" "delete-queries-id" "get-queries-id" "get-queries-id-answers" "get-queries-id-answers-index" "get-queries-id-answers-index-content" "post-queries-id-answers-index-query-instances" "post-queries-id-answers-index-query-series" "post-queries-id-answers-index-query-studies" "post-queries-id-answers-index-retrieve" "get-queries-id-level" "get-queries-id-modality" "get-queries-id-query" "post-queries-id-retrieve" "get-series" "delete-series-id" "get-series-id" "post-series-id-anonymize" "get-series-id-archive" "post-series-id-archive" "get-series-id-attachments" "delete-series-id-attachments-name" "get-series-id-attachments-name" "put-series-id-attachments-name" "post-series-id-attachments-name-compress" "get-series-id-attachments-name-compressed-data" "get-series-id-attachments-name-compressed-md5" "get-series-id-attachments-name-compressed-size" "get-series-id-attachments-name-data" "get-series-id-attachments-name-info" "get-series-id-attachments-name-is-compressed" "get-series-id-attachments-name-md5" "get-series-id-attachments-name-size" "post-series-id-attachments-name-uncompress" "post-series-id-attachments-name-verify-md5" "get-series-id-instances" "get-series-id-instances-tags" "get-series-id-media" "post-series-id-media" "get-series-id-metadata" "delete-series-id-metadata-name" "get-series-id-metadata-name" "put-series-id-metadata-name" "post-series-id-modify" "get-series-id-module" "get-series-id-numpy" "get-series-id-ordered-slices" "get-series-id-patient" "post-series-id-reconstruct" "get-series-id-shared-tags" "get-series-id-statistics" "get-series-id-study" "get-statistics" "get-storage-commitment-id" "post-storage-commitment-id-remove" "get-studies" "delete-studies-id" "get-studies-id" "post-studies-id-anonymize" "get-studies-id-archive" "post-studies-id-archive" "get-studies-id-attachments" "delete-studies-id-attachments-name" "get-studies-id-attachments-name" "put-studies-id-attachments-name" "post-studies-id-attachments-name-compress" "get-studies-id-attachments-name-compressed-data" "get-studies-id-attachments-name-compressed-md5" "get-studies-id-attachments-name-compressed-size" "get-studies-id-attachments-name-data" "get-studies-id-attachments-name-info" "get-studies-id-attachments-name-is-compressed" "get-studies-id-attachments-name-md5" "get-studies-id-attachments-name-size" "post-studies-id-attachments-name-uncompress" "post-studies-id-attachments-name-verify-md5" "get-studies-id-instances" "get-studies-id-instances-tags" "get-studies-id-media" "post-studies-id-media" "post-studies-id-merge" "get-studies-id-metadata" "delete-studies-id-metadata-name" "get-studies-id-metadata-name" "put-studies-id-metadata-name" "post-studies-id-modify" "get-studies-id-module" "get-studies-id-module-patient" "get-studies-id-patient" "post-studies-id-reconstruct" "get-studies-id-series" "get-studies-id-shared-tags" "post-studies-id-split" "get-studies-id-statistics" "get-system" "get-tools" "get-tools-accepted-transfer-syntaxes" "put-tools-accepted-transfer-syntaxes" "post-tools-bulk-anonymize" "post-tools-bulk-content" "post-tools-bulk-delete" "post-tools-bulk-modify" "post-tools-create-archive" "post-tools-create-dicom" "post-tools-create-media" "post-tools-create-media-extended" "get-tools-default-encoding" "put-tools-default-encoding" "get-tools-dicom-conformance" "post-tools-dicom-echo" "post-tools-execute-script" "post-tools-find" "get-tools-generate-uid" "post-tools-invalidate-tags" "get-tools-log-level" "put-tools-log-level" "get-tools-log-level-dicom" "put-tools-log-level-dicom" "get-tools-log-level-generic" "put-tools-log-level-generic" "get-tools-log-level-http" "put-tools-log-level-http" "get-tools-log-level-jobs" "put-tools-log-level-jobs" "get-tools-log-level-lua" "put-tools-log-level-lua" "get-tools-log-level-plugins" "put-tools-log-level-plugins" "get-tools-log-level-sqlite" "put-tools-log-level-sqlite" "post-tools-lookup" "get-tools-metrics" "put-tools-metrics" "get-tools-metrics-prometheus" "get-tools-now" "get-tools-now-local" "post-tools-reconstruct" "post-tools-reset" "post-tools-shutdown" "get-tools-unknown-sop-class-accepted" "put-tools-unknown-sop-class-accepted" "commands"] | sort) } | get name | first)
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

# Clear changes
#
# DELETE /changes
export def "delete-changes" [
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
    path: "/changes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List changes
#
# GET /changes
# Returns: record<Changes: list<record>, Done: bool, Last: float>
export def "get-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Limit the number of results
  --since: float # Show only the resources since the provided index
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changes"
    query: [{name: limit, var: limit}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear exports
#
# DELETE /exports
export def "delete-exports" [
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
    path: "/exports"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List exports
#
# GET /exports
export def "get-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Limit the number of results
  --since: float # Show only the resources since the provided index
]: nothing -> any {
  http-request {
    method: get
    path: "/exports"
    query: [{name: limit, var: limit}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the available instances
#
# GET /instances
export def "get-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # If present, retrieve detailed information about the individual instances
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --limit: float # Limit the number of results
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --since: float # Show only the resources since the provided index
]: nothing -> any {
  http-request {
    method: get
    path: "/instances"
    query: [{name: expand, var: expand}, {name: full, var: qp_full}, {name: limit, var: limit}, {name: requestedTags, var: requested_tags}, {name: short, var: short}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, qp_full: $qp_full, limit: $limit, requested_tags: $requested_tags, short: $short, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload DICOM instances
#
# POST /instances
# Returns: record<ID: string, ParentPatient: string, ParentSeries: string, ParentStudy: string, Path: string, Status: string>
export def "post-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/instances"
    body: {content_type: "application/dicom", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete some instance
#
# DELETE /instances/{id}
export def "delete-instances-id" [
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
    path: "/instances/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about some instance
#
# GET /instances/{id}
export def "get-instances-id" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Anonymize instance
#
# POST /instances/{id}/anonymize
export def "post-instances-id-anonymize" [
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
  --dicom-version: string # Version of the DICOM standard to be used for anonymization. Check out configuration option `DeidentifyLogsDicomVersion` for possible values.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # List of DICOM tags whose value must not be destroyed by the anonymization. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --keep-private-tags: oneof<nothing, bool> # Keep the private tags from the DICOM instances (defaults to `false`)
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of additional tags to be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> any {
  $in | http-request {
    method: post
    path: "/instances/{id}/anonymize"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DicomVersion, var: dicom_version}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepPrivateTags, var: keep_private_tags}, {name: KeepSource, var: keep_source}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: Replace, var: replace}, {name: Transcode, var: transcode}]}
    accept: ["application/dicom"]
    ok: [200]
    auth: bearer
  } {
    id: $id, dicom_version: $dicom_version, force: $force, keep: $keep, keep_private_tags: $keep_private_tags, keep_source: $keep_source, private_creator: $private_creator, remove: $remove, replace: $replace, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List attachments
#
# GET /instances/{id}/attachments
export def "get-instances-id-attachments" [
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
  --qp-full: string # If present, retrieve the attachments list and their numerical ids (spec name: full)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attachment
#
# DELETE /instances/{id}/attachments/{name}
export def "delete-instances-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/instances/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on attachments
#
# GET /instances/{id}/attachments/{name}
export def "get-instances-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set attachment
#
# PUT /instances/{id}/attachments/{name}
export def "put-instances-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, if this is not the first time this attachment is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/instances/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compress attachment
#
# POST /instances/{id}/attachments/{name}/compress
export def "post-instances-id-attachments-name-compress" [
  id: string
  name: string
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
    path: "/instances/{id}/attachments/{name}/compress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment (no decompression)
#
# GET /instances/{id}/attachments/{name}/compressed-data
export def "get-instances-id-attachments-name-compressed-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/compressed-data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment on disk
#
# GET /instances/{id}/attachments/{name}/compressed-md5
export def "get-instances-id-attachments-name-compressed-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/compressed-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment on disk
#
# GET /instances/{id}/attachments/{name}/compressed-size
export def "get-instances-id-attachments-name-compressed-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/compressed-size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment
#
# GET /instances/{id}/attachments/{name}/data
export def "get-instances-id-attachments-name-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info about the attachment
#
# GET /instances/{id}/attachments/{name}/info
export def "get-instances-id-attachments-name-info" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/info"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Is attachment compressed?
#
# GET /instances/{id}/attachments/{name}/is-compressed
export def "get-instances-id-attachments-name-is-compressed" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/is-compressed"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment
#
# GET /instances/{id}/attachments/{name}/md5
export def "get-instances-id-attachments-name-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment
#
# GET /instances/{id}/attachments/{name}/size
export def "get-instances-id-attachments-name-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/attachments/{name}/size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uncompress attachment
#
# POST /instances/{id}/attachments/{name}/uncompress
export def "post-instances-id-attachments-name-uncompress" [
  id: string
  name: string
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
    path: "/instances/{id}/attachments/{name}/uncompress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify attachment
#
# POST /instances/{id}/attachments/{name}/verify-md5
export def "post-instances-id-attachments-name-verify-md5" [
  id: string
  name: string
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
    path: "/instances/{id}/attachments/{name}/verify-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get raw tag
#
# GET /instances/{id}/content
export def "get-instances-id-content" [
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
  --param: string # Path to the DICOM tag. This is the interleaving of one DICOM tag, possibly followed by an index for sequences. Sequences are accessible as, for instance, `/0008-1140/1/0008-1150` (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/content"
    path_params: [{name: id, var: id}]
    query: [{name: "...", var: param, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, param: $param
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Write DICOM onto filesystem
#
# POST /instances/{id}/export
export def "post-instances-id-export" [
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
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/instances/{id}/export"
    path_params: [{name: id, var: id}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download DICOM
#
# GET /instances/{id}/file
export def "get-instances-id-file" [
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
  --hdr-accept: string # This HTTP header can be set to retrieve the DICOM instance in DICOMweb format (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/file"
    path_params: [{name: id, var: id}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["application/dicom", "application/dicom+json", "application/dicom+xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List available frames
#
# GET /instances/{id}/frames
export def "get-instances-id-frames" [
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
    method: get
    path: "/instances/{id}/frames"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations
#
# GET /instances/{id}/frames/{frame}
export def "get-instances-id-frames-frame" [
  id: string
  frame: string
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
    method: get
    path: "/instances/{id}/frames/{frame}"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decode a frame (int16)
#
# GET /instances/{id}/frames/{frame}/image-int16
export def "get-instances-id-frames-frame-image-int16" [
  id: string
  frame: float
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
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/frames/{frame}/image-int16"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Decode a frame (uint16)
#
# GET /instances/{id}/frames/{frame}/image-uint16
export def "get-instances-id-frames-frame-image-uint16" [
  id: string
  frame: float
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
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/frames/{frame}/image-uint16"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Decode a frame (uint8)
#
# GET /instances/{id}/frames/{frame}/image-uint8
export def "get-instances-id-frames-frame-image-uint8" [
  id: string
  frame: float
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
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/frames/{frame}/image-uint8"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Decode frame for Matlab
#
# GET /instances/{id}/frames/{frame}/matlab
export def "get-instances-id-frames-frame-matlab" [
  id: string
  frame: float
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
    method: get
    path: "/instances/{id}/frames/{frame}/matlab"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decode frame for numpy
#
# GET /instances/{id}/frames/{frame}/numpy
export def "get-instances-id-frames-frame-numpy" [
  id: string
  frame: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compress: oneof<nothing, bool> # Compress the file as `.npz`
  --rescale: oneof<nothing, bool> # On grayscale images, apply the rescaling and return floating-point values
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/frames/{frame}/numpy"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    query: [{name: compress, var: compress}, {name: rescale, var: rescale}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame, compress: $compress, rescale: $rescale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decode a frame (preview)
#
# GET /instances/{id}/frames/{frame}/preview
export def "get-instances-id-frames-frame-preview" [
  id: string
  frame: float
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
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/frames/{frame}/preview"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Access raw frame
#
# GET /instances/{id}/frames/{frame}/raw
export def "get-instances-id-frames-frame-raw" [
  id: string
  frame: float
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
    method: get
    path: "/instances/{id}/frames/{frame}/raw"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Access raw frame (compressed)
#
# GET /instances/{id}/frames/{frame}/raw.gz
export def "get-instances-id-frames-frame-raw-gz" [
  id: string
  frame: float
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
    method: get
    path: "/instances/{id}/frames/{frame}/raw.gz"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    accept: ["application/gzip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Render a frame
#
# GET /instances/{id}/frames/{frame}/rendered
export def "get-instances-id-frames-frame-rendered" [
  id: string
  frame: float
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
  --height: float # Height of the resized image
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --smooth: oneof<nothing, bool> # Whether to smooth image on resize
  --width: float # Width of the resized image
  --window-center: float # Windowing center
  --window-width: float # Windowing width
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/frames/{frame}/rendered"
    path_params: [{name: id, var: id}, {name: frame, var: frame}]
    query: [{name: height, var: height}, {name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}, {name: smooth, var: smooth}, {name: width, var: width}, {name: window-center, var: window_center}, {name: window-width, var: window_width}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, frame: $frame, height: $height, quality: $quality, return_unsupported_image: $return_unsupported_image, smooth: $smooth, width: $width, window_center: $window_center, window_width: $window_width, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get DICOM meta-header
#
# GET /instances/{id}/header
export def "get-instances-id-header" [
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
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/header"
    path_params: [{name: id, var: id}]
    query: [{name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decode an image (int16)
#
# GET /instances/{id}/image-int16
export def "get-instances-id-image-int16" [
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
  --accept: string@accept-completer-1 # Response content type
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/image-int16"
    path_params: [{name: id, var: id}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Decode an image (uint16)
#
# GET /instances/{id}/image-uint16
export def "get-instances-id-image-uint16" [
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
  --accept: string@accept-completer-1 # Response content type
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/image-uint16"
    path_params: [{name: id, var: id}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Decode an image (uint8)
#
# GET /instances/{id}/image-uint8
export def "get-instances-id-image-uint8" [
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
  --accept: string@accept-completer-1 # Response content type
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/image-uint8"
    path_params: [{name: id, var: id}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Decode frame for Matlab
#
# GET /instances/{id}/matlab
export def "get-instances-id-matlab" [
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
    method: get
    path: "/instances/{id}/matlab"
    path_params: [{name: id, var: id}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /instances/{id}/metadata
export def "get-instances-id-metadata" [
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
  --expand: string # If present, also retrieve the value of the individual metadata
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/metadata"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete metadata
#
# DELETE /instances/{id}/metadata/{name}
export def "delete-instances-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/instances/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata
#
# GET /instances/{id}/metadata/{name}
export def "get-instances-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set metadata
#
# PUT /instances/{id}/metadata/{name}
export def "put-instances-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, if this is not the first time this metadata is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/instances/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify instance
#
# POST /instances/{id}/modify
export def "post-instances-id-modify" [
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
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # Keep the original value of the specified tags, to be chosen among the `StudyInstanceUID`, `SeriesInstanceUID` and `SOPInstanceUID` tags. Avoid this feature as much as possible, as this breaks the DICOM model of the real world.
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of tags that must be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --remove-private-tags: oneof<nothing, bool> # Remove the private tags from the DICOM instances (defaults to `false`)
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> any {
  $in | http-request {
    method: post
    path: "/instances/{id}/modify"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Force, var: force}, {name: Keep, var: keep}, {name: KeepSource, var: keep_source}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: RemovePrivateTags, var: remove_private_tags}, {name: Replace, var: replace}, {name: Transcode, var: transcode}]}
    accept: ["application/dicom"]
    ok: [200]
    auth: bearer
  } {
    id: $id, force: $force, keep: $keep, keep_source: $keep_source, private_creator: $private_creator, remove: $remove, remove_private_tags: $remove_private_tags, replace: $replace, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance module
#
# GET /instances/{id}/module
export def "get-instances-id-module" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/module"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decode instance for numpy
#
# GET /instances/{id}/numpy
export def "get-instances-id-numpy" [
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
  --compress: oneof<nothing, bool> # Compress the file as `.npz`
  --rescale: oneof<nothing, bool> # On grayscale images, apply the rescaling and return floating-point values
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/numpy"
    path_params: [{name: id, var: id}]
    query: [{name: compress, var: compress}, {name: rescale, var: rescale}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, compress: $compress, rescale: $rescale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get parent patient
#
# GET /instances/{id}/patient
export def "get-instances-id-patient" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/patient"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get embedded PDF
#
# GET /instances/{id}/pdf
export def "get-instances-id-pdf" [
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
    method: get
    path: "/instances/{id}/pdf"
    path_params: [{name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decode an image (preview)
#
# GET /instances/{id}/preview
export def "get-instances-id-preview" [
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
  --accept: string@accept-completer-1 # Response content type
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/preview"
    path_params: [{name: id, var: id}]
    query: [{name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, quality: $quality, return_unsupported_image: $return_unsupported_image, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Reconstruct tags & optionally files of instance
#
# POST /instances/{id}/reconstruct
export def "post-instances-id-reconstruct" [
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
  --reconstruct-files: oneof<nothing, bool> # Also reconstruct the files of the resources (e.g: apply IngestTranscoding, StorageCompression). 'false' by default. (New in Orthanc 1.11.0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/instances/{id}/reconstruct"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReconstructFiles, var: reconstruct_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, reconstruct_files: $reconstruct_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Render an image
#
# GET /instances/{id}/rendered
export def "get-instances-id-rendered" [
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
  --accept: string@accept-completer-1 # Response content type
  --height: float # Height of the resized image
  --quality: float # Quality for JPEG images (between 1 and 100, defaults to 90)
  --return-unsupported-image: oneof<nothing, bool> # Returns an unsupported.png placeholder image if unable to provide the image instead of returning a 415 HTTP error (defaults to false)
  --smooth: oneof<nothing, bool> # Whether to smooth image on resize
  --width: float # Width of the resized image
  --window-center: float # Windowing center
  --window-width: float # Windowing width
  --hdr-accept: string # Format of the resulting image. Can be `image/png` (default), `image/jpeg` or `image/x-portable-arbitrarymap` (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/rendered"
    path_params: [{name: id, var: id}]
    query: [{name: height, var: height}, {name: quality, var: quality}, {name: returnUnsupportedImage, var: return_unsupported_image}, {name: smooth, var: smooth}, {name: width, var: width}, {name: window-center, var: window_center}, {name: window-width, var: window_width}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["image/jpeg", "image/png", "image/x-portable-arbitrarymap"]
    ok: [200]
    auth: bearer
  } {
    id: $id, height: $height, quality: $quality, return_unsupported_image: $return_unsupported_image, smooth: $smooth, width: $width, window_center: $window_center, window_width: $window_width, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get parent series
#
# GET /instances/{id}/series
export def "get-instances-id-series" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/series"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get human-readable tags
#
# GET /instances/{id}/simplified-tags
export def "get-instances-id-simplified-tags" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/simplified-tags"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance statistics
#
# GET /instances/{id}/statistics
# Returns: record<DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>
export def "get-instances-id-statistics" [
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
    path: "/instances/{id}/statistics"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get parent study
#
# GET /instances/{id}/study
export def "get-instances-id-study" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/study"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get DICOM tags
#
# GET /instances/{id}/tags
export def "get-instances-id-tags" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/instances/{id}/tags"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List jobs
#
# GET /jobs
export def "get-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # If present, retrieve detailed information about the individual jobs
]: nothing -> any {
  http-request {
    method: get
    path: "/jobs"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get job
#
# GET /jobs/{id}
export def "get-jobs-id" [
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
    method: get
    path: "/jobs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel job
#
# POST /jobs/{id}/cancel
export def "post-jobs-id-cancel" [
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
    method: post
    path: "/jobs/{id}/cancel"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause job
#
# POST /jobs/{id}/pause
export def "post-jobs-id-pause" [
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
    method: post
    path: "/jobs/{id}/pause"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resubmit job
#
# POST /jobs/{id}/resubmit
export def "post-jobs-id-resubmit" [
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
    method: post
    path: "/jobs/{id}/resubmit"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resume job
#
# POST /jobs/{id}/resume
export def "post-jobs-id-resume" [
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
    method: post
    path: "/jobs/{id}/resume"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get job output
#
# GET /jobs/{id}/{key}
export def "get-jobs-id-key" [
  id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/jobs/{id}/{key}"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List DICOM modalities
#
# GET /modalities
export def "get-modalities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # If present, retrieve detailed information about the individual DICOM modalities
]: nothing -> any {
  http-request {
    method: get
    path: "/modalities"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete DICOM modality
#
# DELETE /modalities/{id}
export def "delete-modalities-id" [
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
    path: "/modalities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on modality
#
# GET /modalities/{id}
export def "get-modalities-id" [
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
    method: get
    path: "/modalities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update DICOM modality
#
# PUT /modalities/{id}
export def "put-modalities-id" [
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
  --aet: string # AET of the remote DICOM modality
  --allow-echo: oneof<nothing, bool> # Whether to accept C-ECHO SCU commands issued by the remote modality
  --allow-find: oneof<nothing, bool> # Whether to accept C-FIND SCU commands issued by the remote modality
  --allow-find-worklist: oneof<nothing, bool> # Whether to accept C-FIND SCU commands for worklists issued by the remote modality
  --allow-get: oneof<nothing, bool> # Whether to accept C-GET SCU commands issued by the remote modality
  --allow-move: oneof<nothing, bool> # Whether to accept C-MOVE SCU commands issued by the remote modality
  --allow-storage-commitment: oneof<nothing, bool> # Whether to accept storage commitment requests issued by the remote modality
  --allow-store: oneof<nothing, bool> # Whether to accept C-STORE SCU commands issued by the remote modality
  --allow-transcoding: oneof<nothing, bool> # Whether to allow transcoding for operations initiated by this modality. This option applies to Orthanc C-GET SCP and to Orthanc C-STORE SCU. It only has an effect if the global option `EnableTranscoding` is set to `true`.
  --host: string # Host address of the remote DICOM modality (typically, an IP address)
  --manufacturer: string # Manufacturer of the remote DICOM modality (check configuration option `DicomModalities` for possible values
  --port: float # TCP port of the remote DICOM modality
  --use-dicom-tls: oneof<nothing, bool> # Whether to use DICOM TLS in the SCU connection initiated by Orthanc (new in Orthanc 1.9.0)
]: any -> any {
  $in | http-request {
    method: put
    path: "/modalities/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AET, var: aet}, {name: AllowEcho, var: allow_echo}, {name: AllowFind, var: allow_find}, {name: AllowFindWorklist, var: allow_find_worklist}, {name: AllowGet, var: allow_get}, {name: AllowMove, var: allow_move}, {name: AllowStorageCommitment, var: allow_storage_commitment}, {name: AllowStore, var: allow_store}, {name: AllowTranscoding, var: allow_transcoding}, {name: Host, var: host}, {name: Manufacturer, var: manufacturer}, {name: Port, var: port}, {name: UseDicomTls, var: use_dicom_tls}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, aet: $aet, allow_echo: $allow_echo, allow_find: $allow_find, allow_find_worklist: $allow_find_worklist, allow_get: $allow_get, allow_move: $allow_move, allow_storage_commitment: $allow_storage_commitment, allow_store: $allow_store, allow_transcoding: $allow_transcoding, host: $host, manufacturer: $manufacturer, port: $port, use_dicom_tls: $use_dicom_tls
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get modality configuration
#
# GET /modalities/{id}/configuration
export def "get-modalities-id-configuration" [
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
    method: get
    path: "/modalities/{id}/configuration"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger C-ECHO SCU
#
# POST /modalities/{id}/echo
export def "post-modalities-id-echo" [
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
  --check-find: oneof<nothing, bool> # Issue a dummy C-FIND command after the C-GET SCU, in order to check whether the remote modality knows about Orthanc. This field defaults to the value of the `DicomEchoChecksFind` configuration option. New in Orthanc 1.8.1.
  --timeout: float # Timeout for the C-ECHO command, in seconds
]: any -> any {
  $in | http-request {
    method: post
    path: "/modalities/{id}/echo"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: CheckFind, var: check_find}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, check_find: $check_find, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hierarchical C-FIND SCU
#
# POST /modalities/{id}/find
# DEPRECATED
@deprecated
export def "post-modalities-id-find" [
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
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/modalities/{id}/find"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# C-FIND SCU for instances
#
# POST /modalities/{id}/find-instance
# DEPRECATED
@deprecated
export def "post-modalities-id-find-instance" [
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
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/modalities/{id}/find-instance"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# C-FIND SCU for patients
#
# POST /modalities/{id}/find-patient
# DEPRECATED
@deprecated
export def "post-modalities-id-find-patient" [
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
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/modalities/{id}/find-patient"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# C-FIND SCU for series
#
# POST /modalities/{id}/find-series
# DEPRECATED
@deprecated
export def "post-modalities-id-find-series" [
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
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/modalities/{id}/find-series"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# C-FIND SCU for studies
#
# POST /modalities/{id}/find-study
# DEPRECATED
@deprecated
export def "post-modalities-id-find-study" [
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
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/modalities/{id}/find-study"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# C-FIND SCU for worklist
#
# POST /modalities/{id}/find-worklist
export def "post-modalities-id-find-worklist" [
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
  --body-full: oneof<nothing, bool> # If set to `true`, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: Full)
  --query: record # Associative array containing the filter on the values of the DICOM tags
  --short: oneof<nothing, bool> # If set to `true`, report the DICOM tags in hexadecimal format
]: any -> any {
  $in | http-request {
    method: post
    path: "/modalities/{id}/find-worklist"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Full, var: body_full}, {name: Query, var: query}, {name: Short, var: short}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_full: $body_full, query: $query, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger C-MOVE SCU
#
# POST /modalities/{id}/move
# Returns: record<ID: string, Path: string>
export def "post-modalities-id-move" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --level: string # Level of the query (`Patient`, `Study`, `Series` or `Instance`)
  --local-aet: string # Local AET that is used for this commands, defaults to `DicomAet` configuration option. Ignored if `DicomModalities` already sets `LocalAet` for this modality.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --resources: list # List of queries identifying all the DICOM resources to be sent
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --target-aet: string # Target AET that will be used by the remote DICOM modality as a target for its C-STORE SCU commands, defaults to `DicomAet` configuration option in order to do a simple query/retrieve
  --timeout: float # Timeout for the C-MOVE command, in seconds
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/modalities/{id}/move"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Level, var: level}, {name: LocalAet, var: local_aet}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}, {name: TargetAet, var: target_aet}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, level: $level, local_aet: $local_aet, permissive: $permissive, priority: $priority, resources: $resources, synchronous: $synchronous, target_aet: $target_aet, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger C-FIND SCU
#
# POST /modalities/{id}/query
# Returns: record<ID: record, Path: record>
export def "post-modalities-id-query" [
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
  --level: string # Level of the query (`Patient`, `Study`, `Series` or `Instance`)
  --local-aet: string # Local AET that is used for this commands, defaults to `DicomAet` configuration option. Ignored if `DicomModalities` already sets `LocalAet` for this modality.
  --normalize: oneof<nothing, bool> # Whether to normalize the query, i.e. whether to wipe out from the query, the DICOM tags that are not applicable for the query-retrieve level of interest
  --query: record # Associative array containing the filter on the values of the DICOM tags
  --timeout: float # Timeout for the C-FIND command and subsequent C-MOVE retrievals, in seconds (new in Orthanc 1.9.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/modalities/{id}/query"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Level, var: level}, {name: LocalAet, var: local_aet}, {name: Normalize, var: normalize}, {name: Query, var: query}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, level: $level, local_aet: $local_aet, normalize: $normalize, query: $query, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger storage commitment request
#
# POST /modalities/{id}/storage-commitment
# Returns: record<ID: record, Path: record>
export def "post-modalities-id-storage-commitment" [
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
  --dicom-instances: list # List of DICOM resources that are not necessarily stored within Orthanc, but that must be checked by storage commitment. This is a list of JSON objects that must contain the `SOPClassUID` and `SOPInstanceUID` fields.
  --resources: list<string> # List of the Orthanc identifiers of the DICOM resources to be checked by storage commitment
  --timeout: float # Timeout for the storage commitment command (new in Orthanc 1.9.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/modalities/{id}/storage-commitment"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DicomInstances, var: dicom_instances}, {name: Resources, var: resources}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, dicom_instances: $dicom_instances, resources: $resources, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger C-STORE SCU
#
# POST /modalities/{id}/store
# Returns: record<ID: string, Path: string>
export def "post-modalities-id-store" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --called-aet: string # Called AET that is used for this commands, defaults to `AET` configuration option. Allows you to overwrite the destination AET for a specific operation.
  --host: string # Host that is used for this commands, defaults to `Host` configuration option. Allows you to overwrite the destination host for a specific operation.
  --local-aet: string # Local AET that is used for this commands, defaults to `DicomAet` configuration option. Ignored if `DicomModalities` already sets `LocalAet` for this modality.
  --move-originator-aet: string # Move originator AET that is used for this commands, in order to fake a C-MOVE SCU
  --move-originator-id: float # Move originator ID that is used for this commands, in order to fake a C-MOVE SCU
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --port: float # Port that is used for this commands, defaults to `Port` configuration option. Allows you to overwrite the destination port for a specific operation.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --resources: list<string> # List of the Orthanc identifiers of all the DICOM resources to be sent
  --storage-commitment: oneof<nothing, bool> # Whether to chain C-STORE with DICOM storage commitment to validate the success of the transmission: https://book.orthanc-server.com/users/storage-commitment.html#chaining-c-store-with-storage-commitment
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --timeout: float # Timeout for the C-STORE command, in seconds
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/modalities/{id}/store"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: CalledAet, var: called_aet}, {name: Host, var: host}, {name: LocalAet, var: local_aet}, {name: MoveOriginatorAet, var: move_originator_aet}, {name: MoveOriginatorID, var: move_originator_id}, {name: Permissive, var: permissive}, {name: Port, var: port}, {name: Priority, var: priority}, {name: Resources, var: resources}, {name: StorageCommitment, var: storage_commitment}, {name: Synchronous, var: synchronous}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, called_aet: $called_aet, host: $host, local_aet: $local_aet, move_originator_aet: $move_originator_aet, move_originator_id: $move_originator_id, permissive: $permissive, port: $port, priority: $priority, resources: $resources, storage_commitment: $storage_commitment, synchronous: $synchronous, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Straight C-STORE SCU
#
# POST /modalities/{id}/store-straight
# Returns: record<SOPClassUID: string, SOPInstanceUID: string>
export def "post-modalities-id-store-straight" [
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
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/modalities/{id}/store-straight"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/dicom", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the available patients
#
# GET /patients
export def "get-patients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # If present, retrieve detailed information about the individual patients
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --limit: float # Limit the number of results
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --since: float # Show only the resources since the provided index
]: nothing -> any {
  http-request {
    method: get
    path: "/patients"
    query: [{name: expand, var: expand}, {name: full, var: qp_full}, {name: limit, var: limit}, {name: requestedTags, var: requested_tags}, {name: short, var: short}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, qp_full: $qp_full, limit: $limit, requested_tags: $requested_tags, short: $short, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete some patient
#
# DELETE /patients/{id}
export def "delete-patients-id" [
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
    path: "/patients/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about some patient
#
# GET /patients/{id}
export def "get-patients-id" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Anonymize patient
#
# POST /patients/{id}/anonymize
# Returns: record<ID: string, Path: string>
export def "post-patients-id-anonymize" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --dicom-version: string # Version of the DICOM standard to be used for anonymization. Check out configuration option `DeidentifyLogsDicomVersion` for possible values.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # List of DICOM tags whose value must not be destroyed by the anonymization. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --keep-private-tags: oneof<nothing, bool> # Keep the private tags from the DICOM instances (defaults to `false`)
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of additional tags to be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/patients/{id}/anonymize"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: DicomVersion, var: dicom_version}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepPrivateTags, var: keep_private_tags}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: Replace, var: replace}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, dicom_version: $dicom_version, force: $force, keep: $keep, keep_private_tags: $keep_private_tags, keep_source: $keep_source, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, replace: $replace, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ZIP archive
#
# GET /patients/{id}/archive
export def "get-patients-id-archive" [
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
  --filename: string # Filename to set in the "Content-Disposition" HTTP header (including file extension)
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/archive"
    path_params: [{name: id, var: id}]
    query: [{name: filename, var: filename}, {name: transcode, var: transcode}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filename: $filename, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ZIP archive
#
# POST /patients/{id}/archive
# Returns: record<ID: string, Path: string>
export def "post-patients-id-archive" [
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
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/patients/{id}/archive"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Priority, var: priority}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, priority: $priority, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List attachments
#
# GET /patients/{id}/attachments
export def "get-patients-id-attachments" [
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
  --qp-full: string # If present, retrieve the attachments list and their numerical ids (spec name: full)
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attachment
#
# DELETE /patients/{id}/attachments/{name}
export def "delete-patients-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/patients/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on attachments
#
# GET /patients/{id}/attachments/{name}
export def "get-patients-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set attachment
#
# PUT /patients/{id}/attachments/{name}
export def "put-patients-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, if this is not the first time this attachment is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/patients/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compress attachment
#
# POST /patients/{id}/attachments/{name}/compress
export def "post-patients-id-attachments-name-compress" [
  id: string
  name: string
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
    path: "/patients/{id}/attachments/{name}/compress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment (no decompression)
#
# GET /patients/{id}/attachments/{name}/compressed-data
export def "get-patients-id-attachments-name-compressed-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/compressed-data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment on disk
#
# GET /patients/{id}/attachments/{name}/compressed-md5
export def "get-patients-id-attachments-name-compressed-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/compressed-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment on disk
#
# GET /patients/{id}/attachments/{name}/compressed-size
export def "get-patients-id-attachments-name-compressed-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/compressed-size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment
#
# GET /patients/{id}/attachments/{name}/data
export def "get-patients-id-attachments-name-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info about the attachment
#
# GET /patients/{id}/attachments/{name}/info
export def "get-patients-id-attachments-name-info" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/info"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Is attachment compressed?
#
# GET /patients/{id}/attachments/{name}/is-compressed
export def "get-patients-id-attachments-name-is-compressed" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/is-compressed"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment
#
# GET /patients/{id}/attachments/{name}/md5
export def "get-patients-id-attachments-name-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment
#
# GET /patients/{id}/attachments/{name}/size
export def "get-patients-id-attachments-name-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/attachments/{name}/size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uncompress attachment
#
# POST /patients/{id}/attachments/{name}/uncompress
export def "post-patients-id-attachments-name-uncompress" [
  id: string
  name: string
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
    path: "/patients/{id}/attachments/{name}/uncompress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify attachment
#
# POST /patients/{id}/attachments/{name}/verify-md5
export def "post-patients-id-attachments-name-verify-md5" [
  id: string
  name: string
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
    path: "/patients/{id}/attachments/{name}/verify-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child instances
#
# GET /patients/{id}/instances
export def "get-patients-id-instances" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/instances"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags of instances
#
# GET /patients/{id}/instances-tags
export def "get-patients-id-instances-tags" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/instances-tags"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create DICOMDIR media
#
# GET /patients/{id}/media
export def "get-patients-id-media" [
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
  --extended: string # If present, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*
  --filename: string # Filename to set in the "Content-Disposition" HTTP header (including file extension)
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: extended, var: extended}, {name: filename, var: filename}, {name: transcode, var: transcode}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, extended: $extended, filename: $filename, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create DICOMDIR media
#
# POST /patients/{id}/media
# Returns: record<ID: string, Path: string>
export def "post-patients-id-media" [
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
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --extended: oneof<nothing, bool> # If `true`, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*. Default value is `false`.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/patients/{id}/media"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Extended, var: extended}, {name: Priority, var: priority}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, extended: $extended, priority: $priority, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List metadata
#
# GET /patients/{id}/metadata
export def "get-patients-id-metadata" [
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
  --expand: string # If present, also retrieve the value of the individual metadata
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/metadata"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete metadata
#
# DELETE /patients/{id}/metadata/{name}
export def "delete-patients-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/patients/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata
#
# GET /patients/{id}/metadata/{name}
export def "get-patients-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set metadata
#
# PUT /patients/{id}/metadata/{name}
export def "put-patients-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, if this is not the first time this metadata is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/patients/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify patient
#
# POST /patients/{id}/modify
# Returns: record<ID: string, Path: string>
export def "post-patients-id-modify" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # Keep the original value of the specified tags, to be chosen among the `StudyInstanceUID`, `SeriesInstanceUID` and `SOPInstanceUID` tags. Avoid this feature as much as possible, as this breaks the DICOM model of the real world.
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of tags that must be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --remove-private-tags: oneof<nothing, bool> # Remove the private tags from the DICOM instances (defaults to `false`)
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/patients/{id}/modify"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: RemovePrivateTags, var: remove_private_tags}, {name: Replace, var: replace}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, force: $force, keep: $keep, keep_source: $keep_source, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, remove_private_tags: $remove_private_tags, replace: $replace, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get patient module
#
# GET /patients/{id}/module
export def "get-patients-id-module" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/module"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Is the patient protected against recycling?
#
# GET /patients/{id}/protected
export def "get-patients-id-protected" [
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
    method: get
    path: "/patients/{id}/protected"
    path_params: [{name: id, var: id}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Protect one patient against recycling
#
# PUT /patients/{id}/protected
export def "put-patients-id-protected" [
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
    method: put
    path: "/patients/{id}/protected"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconstruct tags & optionally files of patient
#
# POST /patients/{id}/reconstruct
export def "post-patients-id-reconstruct" [
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
  --reconstruct-files: oneof<nothing, bool> # Also reconstruct the files of the resources (e.g: apply IngestTranscoding, StorageCompression). 'false' by default. (New in Orthanc 1.11.0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/patients/{id}/reconstruct"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReconstructFiles, var: reconstruct_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, reconstruct_files: $reconstruct_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child series
#
# GET /patients/{id}/series
export def "get-patients-id-series" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/series"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shared tags
#
# GET /patients/{id}/shared-tags
export def "get-patients-id-shared-tags" [
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
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/shared-tags"
    path_params: [{name: id, var: id}]
    query: [{name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get patient statistics
#
# GET /patients/{id}/statistics
# Returns: record<CountInstances: float, CountSeries: float, CountStudies: float, DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>
export def "get-patients-id-statistics" [
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
    path: "/patients/{id}/statistics"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child studies
#
# GET /patients/{id}/studies
export def "get-patients-id-studies" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/patients/{id}/studies"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Orthanc peers
#
# GET /peers
export def "get-peers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # If present, retrieve detailed information about the individual Orthanc peers
]: nothing -> any {
  http-request {
    method: get
    path: "/peers"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Orthanc peer
#
# DELETE /peers/{id}
export def "delete-peers-id" [
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
    path: "/peers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on peer
#
# GET /peers/{id}
export def "get-peers-id" [
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
    method: get
    path: "/peers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Orthanc peer
#
# PUT /peers/{id}
export def "put-peers-id" [
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
  --certificate-file: string # SSL certificate for the HTTPS connections
  --certificate-key-file: string # Key file for the SSL certificate for the HTTPS connections
  --certificate-key-password: string # Key password for the SSL certificate for the HTTPS connections
  --http-headers: record # HTTP headers to be used for the connections to the remote peer
  --password: string # Password for the credentials
  --url: string # URL of the root of the REST API of the remote Orthanc peer, for instance `http://localhost:8042/`
  --username: string # Username for the credentials
]: any -> any {
  $in | http-request {
    method: put
    path: "/peers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: CertificateFile, var: certificate_file}, {name: CertificateKeyFile, var: certificate_key_file}, {name: CertificateKeyPassword, var: certificate_key_password}, {name: HttpHeaders, var: http_headers}, {name: Password, var: password}, {name: URL, var: url}, {name: Username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, certificate_file: $certificate_file, certificate_key_file: $certificate_key_file, certificate_key_password: $certificate_key_password, http_headers: $http_headers, password: $password, url: $url, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get peer configuration
#
# GET /peers/{id}/configuration
export def "get-peers-id-configuration" [
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
    method: get
    path: "/peers/{id}/configuration"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send to Orthanc peer
#
# POST /peers/{id}/store
# Returns: record<ID: string, Path: string>
export def "post-peers-id-store" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --compress: oneof<nothing, bool> # Whether to compress the DICOM instances using gzip before the actual sending
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --resources: list<string> # List of the Orthanc identifiers of all the DICOM resources to be sent
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode to the provided DICOM transfer syntax before the actual sending
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/peers/{id}/store"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Compress, var: compress}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, compress: $compress, permissive: $permissive, priority: $priority, resources: $resources, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Straight store to peer
#
# POST /peers/{id}/store-straight
# Returns: record<ID: string, ParentPatient: string, ParentSeries: string, ParentStudy: string, Path: string, Status: string>
export def "post-peers-id-store-straight" [
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
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/peers/{id}/store-straight"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/dicom", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get peer system information
#
# GET /peers/{id}/system
export def "get-peers-id-system" [
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
    method: get
    path: "/peers/{id}/system"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List plugins
#
# GET /plugins
export def "get-plugins" [
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
    method: get
    path: "/plugins"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# JavaScript extensions to Orthanc Explorer
#
# GET /plugins/explorer.js
export def "get-plugins-explorer-js" [
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
    method: get
    path: "/plugins/explorer.js"
    accept: ["application/javascript"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get plugin
#
# GET /plugins/{id}
export def "get-plugins-id" [
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
    method: get
    path: "/plugins/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List query/retrieve operations
#
# GET /queries
export def "get-queries" [
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
    method: get
    path: "/queries"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a query
#
# DELETE /queries/{id}
export def "delete-queries-id" [
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
    path: "/queries/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on a query
#
# GET /queries/{id}
export def "get-queries-id" [
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
    method: get
    path: "/queries/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List answers to a query
#
# GET /queries/{id}/answers
export def "get-queries-id-answers" [
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
  --expand: string # If present, retrieve detailed information about the individual answers
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/queries/{id}/answers"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on an answer
#
# GET /queries/{id}/answers/{index}
export def "get-queries-id-answers-index" [
  id: string
  index: string
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
    method: get
    path: "/queries/{id}/answers/{index}"
    path_params: [{name: id, var: id}, {name: index, var: index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, index: $index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one answer
#
# GET /queries/{id}/answers/{index}/content
export def "get-queries-id-answers-index-content" [
  id: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/queries/{id}/answers/{index}/content"
    path_params: [{name: id, var: id}, {name: index, var: index}]
    query: [{name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, index: $index, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query the child instances of an answer
#
# POST /queries/{id}/answers/{index}/query-instances
# Returns: record<ID: record, Path: record>
export def "post-queries-id-answers-index-query-instances" [
  id: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: record # Associative array containing the filter on the values of the DICOM tags
  --timeout: float # Timeout for the C-FIND command, in seconds (new in Orthanc 1.9.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/queries/{id}/answers/{index}/query-instances"
    path_params: [{name: id, var: id}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: Query, var: query}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, index: $index, query: $query, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query the child series of an answer
#
# POST /queries/{id}/answers/{index}/query-series
# Returns: record<ID: record, Path: record>
export def "post-queries-id-answers-index-query-series" [
  id: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: record # Associative array containing the filter on the values of the DICOM tags
  --timeout: float # Timeout for the C-FIND command, in seconds (new in Orthanc 1.9.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/queries/{id}/answers/{index}/query-series"
    path_params: [{name: id, var: id}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: Query, var: query}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, index: $index, query: $query, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query the child studies of an answer
#
# POST /queries/{id}/answers/{index}/query-studies
# Returns: record<ID: record, Path: record>
export def "post-queries-id-answers-index-query-studies" [
  id: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: record # Associative array containing the filter on the values of the DICOM tags
  --timeout: float # Timeout for the C-FIND command, in seconds (new in Orthanc 1.9.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/queries/{id}/answers/{index}/query-studies"
    path_params: [{name: id, var: id}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: Query, var: query}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, index: $index, query: $query, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve one answer
#
# POST /queries/{id}/answers/{index}/retrieve
# Returns: record<ID: string, Path: string>
export def "post-queries-id-answers-index-retrieve" [
  id: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --body-full: oneof<nothing, bool> # If set to `true`, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: Full)
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --simplify: oneof<nothing, bool> # If set to `true`, report the DICOM tags in human-readable format (using the symbolic name of the tags)
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --target-aet: string # AET of the target modality. By default, the AET of Orthanc is used, as defined in the `DicomAet` configuration option.
  --timeout: float # Timeout for the C-MOVE command, in seconds
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/queries/{id}/answers/{index}/retrieve"
    path_params: [{name: id, var: id}, {name: index, var: index}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Full, var: body_full}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: Simplify, var: simplify}, {name: Synchronous, var: synchronous}, {name: TargetAet, var: target_aet}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, index: $index, asynchronous: $asynchronous, body_full: $body_full, permissive: $permissive, priority: $priority, simplify: $simplify, synchronous: $synchronous, target_aet: $target_aet, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get level of original query
#
# GET /queries/{id}/level
export def "get-queries-id-level" [
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
    method: get
    path: "/queries/{id}/level"
    path_params: [{name: id, var: id}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get modality of original query
#
# GET /queries/{id}/modality
export def "get-queries-id-modality" [
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
    method: get
    path: "/queries/{id}/modality"
    path_params: [{name: id, var: id}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get original query arguments
#
# GET /queries/{id}/query
export def "get-queries-id-query" [
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
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/queries/{id}/query"
    path_params: [{name: id, var: id}]
    query: [{name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all answers
#
# POST /queries/{id}/retrieve
# Returns: record<ID: string, Path: string>
export def "post-queries-id-retrieve" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --body-full: oneof<nothing, bool> # If set to `true`, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: Full)
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --simplify: oneof<nothing, bool> # If set to `true`, report the DICOM tags in human-readable format (using the symbolic name of the tags)
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --target-aet: string # AET of the target modality. By default, the AET of Orthanc is used, as defined in the `DicomAet` configuration option.
  --timeout: float # Timeout for the C-MOVE command, in seconds
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/queries/{id}/retrieve"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Full, var: body_full}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: Simplify, var: simplify}, {name: Synchronous, var: synchronous}, {name: TargetAet, var: target_aet}, {name: Timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, body_full: $body_full, permissive: $permissive, priority: $priority, simplify: $simplify, synchronous: $synchronous, target_aet: $target_aet, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the available series
#
# GET /series
export def "get-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # If present, retrieve detailed information about the individual series
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --limit: float # Limit the number of results
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --since: float # Show only the resources since the provided index
]: nothing -> any {
  http-request {
    method: get
    path: "/series"
    query: [{name: expand, var: expand}, {name: full, var: qp_full}, {name: limit, var: limit}, {name: requestedTags, var: requested_tags}, {name: short, var: short}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, qp_full: $qp_full, limit: $limit, requested_tags: $requested_tags, short: $short, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete some series
#
# DELETE /series/{id}
export def "delete-series-id" [
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
    path: "/series/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about some series
#
# GET /series/{id}
export def "get-series-id" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Anonymize series
#
# POST /series/{id}/anonymize
# Returns: record<ID: string, Path: string>
export def "post-series-id-anonymize" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --dicom-version: string # Version of the DICOM standard to be used for anonymization. Check out configuration option `DeidentifyLogsDicomVersion` for possible values.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # List of DICOM tags whose value must not be destroyed by the anonymization. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --keep-private-tags: oneof<nothing, bool> # Keep the private tags from the DICOM instances (defaults to `false`)
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of additional tags to be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/series/{id}/anonymize"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: DicomVersion, var: dicom_version}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepPrivateTags, var: keep_private_tags}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: Replace, var: replace}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, dicom_version: $dicom_version, force: $force, keep: $keep, keep_private_tags: $keep_private_tags, keep_source: $keep_source, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, replace: $replace, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ZIP archive
#
# GET /series/{id}/archive
export def "get-series-id-archive" [
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
  --filename: string # Filename to set in the "Content-Disposition" HTTP header (including file extension)
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/archive"
    path_params: [{name: id, var: id}]
    query: [{name: filename, var: filename}, {name: transcode, var: transcode}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filename: $filename, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ZIP archive
#
# POST /series/{id}/archive
# Returns: record<ID: string, Path: string>
export def "post-series-id-archive" [
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
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/series/{id}/archive"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Priority, var: priority}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, priority: $priority, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List attachments
#
# GET /series/{id}/attachments
export def "get-series-id-attachments" [
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
  --qp-full: string # If present, retrieve the attachments list and their numerical ids (spec name: full)
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attachment
#
# DELETE /series/{id}/attachments/{name}
export def "delete-series-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/series/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on attachments
#
# GET /series/{id}/attachments/{name}
export def "get-series-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set attachment
#
# PUT /series/{id}/attachments/{name}
export def "put-series-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, if this is not the first time this attachment is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/series/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compress attachment
#
# POST /series/{id}/attachments/{name}/compress
export def "post-series-id-attachments-name-compress" [
  id: string
  name: string
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
    path: "/series/{id}/attachments/{name}/compress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment (no decompression)
#
# GET /series/{id}/attachments/{name}/compressed-data
export def "get-series-id-attachments-name-compressed-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/compressed-data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment on disk
#
# GET /series/{id}/attachments/{name}/compressed-md5
export def "get-series-id-attachments-name-compressed-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/compressed-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment on disk
#
# GET /series/{id}/attachments/{name}/compressed-size
export def "get-series-id-attachments-name-compressed-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/compressed-size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment
#
# GET /series/{id}/attachments/{name}/data
export def "get-series-id-attachments-name-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info about the attachment
#
# GET /series/{id}/attachments/{name}/info
export def "get-series-id-attachments-name-info" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/info"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Is attachment compressed?
#
# GET /series/{id}/attachments/{name}/is-compressed
export def "get-series-id-attachments-name-is-compressed" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/is-compressed"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment
#
# GET /series/{id}/attachments/{name}/md5
export def "get-series-id-attachments-name-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment
#
# GET /series/{id}/attachments/{name}/size
export def "get-series-id-attachments-name-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/attachments/{name}/size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uncompress attachment
#
# POST /series/{id}/attachments/{name}/uncompress
export def "post-series-id-attachments-name-uncompress" [
  id: string
  name: string
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
    path: "/series/{id}/attachments/{name}/uncompress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify attachment
#
# POST /series/{id}/attachments/{name}/verify-md5
export def "post-series-id-attachments-name-verify-md5" [
  id: string
  name: string
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
    path: "/series/{id}/attachments/{name}/verify-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child instances
#
# GET /series/{id}/instances
export def "get-series-id-instances" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/instances"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags of instances
#
# GET /series/{id}/instances-tags
export def "get-series-id-instances-tags" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/instances-tags"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create DICOMDIR media
#
# GET /series/{id}/media
export def "get-series-id-media" [
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
  --extended: string # If present, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*
  --filename: string # Filename to set in the "Content-Disposition" HTTP header (including file extension)
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: extended, var: extended}, {name: filename, var: filename}, {name: transcode, var: transcode}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, extended: $extended, filename: $filename, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create DICOMDIR media
#
# POST /series/{id}/media
# Returns: record<ID: string, Path: string>
export def "post-series-id-media" [
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
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --extended: oneof<nothing, bool> # If `true`, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*. Default value is `false`.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/series/{id}/media"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Extended, var: extended}, {name: Priority, var: priority}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, extended: $extended, priority: $priority, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List metadata
#
# GET /series/{id}/metadata
export def "get-series-id-metadata" [
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
  --expand: string # If present, also retrieve the value of the individual metadata
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/metadata"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete metadata
#
# DELETE /series/{id}/metadata/{name}
export def "delete-series-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/series/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata
#
# GET /series/{id}/metadata/{name}
export def "get-series-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set metadata
#
# PUT /series/{id}/metadata/{name}
export def "put-series-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, if this is not the first time this metadata is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/series/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify series
#
# POST /series/{id}/modify
# Returns: record<ID: string, Path: string>
export def "post-series-id-modify" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # Keep the original value of the specified tags, to be chosen among the `StudyInstanceUID`, `SeriesInstanceUID` and `SOPInstanceUID` tags. Avoid this feature as much as possible, as this breaks the DICOM model of the real world.
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of tags that must be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --remove-private-tags: oneof<nothing, bool> # Remove the private tags from the DICOM instances (defaults to `false`)
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/series/{id}/modify"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: RemovePrivateTags, var: remove_private_tags}, {name: Replace, var: replace}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, force: $force, keep: $keep, keep_source: $keep_source, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, remove_private_tags: $remove_private_tags, replace: $replace, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get series module
#
# GET /series/{id}/module
export def "get-series-id-module" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/module"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decode series for numpy
#
# GET /series/{id}/numpy
export def "get-series-id-numpy" [
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
  --compress: oneof<nothing, bool> # Compress the file as `.npz`
  --rescale: oneof<nothing, bool> # On grayscale images, apply the rescaling and return floating-point values
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/numpy"
    path_params: [{name: id, var: id}]
    query: [{name: compress, var: compress}, {name: rescale, var: rescale}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, compress: $compress, rescale: $rescale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order the slices
#
# GET /series/{id}/ordered-slices
# DEPRECATED
# Returns: record<Dicom: list<string>, Slices: list<string>, SlicesShort: list<record>, Type: string>
@deprecated
export def "get-series-id-ordered-slices" [
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
    path: "/series/{id}/ordered-slices"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get parent patient
#
# GET /series/{id}/patient
export def "get-series-id-patient" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/patient"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconstruct tags & optionally files of series
#
# POST /series/{id}/reconstruct
export def "post-series-id-reconstruct" [
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
  --reconstruct-files: oneof<nothing, bool> # Also reconstruct the files of the resources (e.g: apply IngestTranscoding, StorageCompression). 'false' by default. (New in Orthanc 1.11.0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/series/{id}/reconstruct"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReconstructFiles, var: reconstruct_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, reconstruct_files: $reconstruct_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shared tags
#
# GET /series/{id}/shared-tags
export def "get-series-id-shared-tags" [
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
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/shared-tags"
    path_params: [{name: id, var: id}]
    query: [{name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get series statistics
#
# GET /series/{id}/statistics
# Returns: record<CountInstances: float, DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>
export def "get-series-id-statistics" [
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
    path: "/series/{id}/statistics"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get parent study
#
# GET /series/{id}/study
export def "get-series-id-study" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/series/{id}/study"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get database statistics
#
# GET /statistics
# Returns: record<CountInstances: float, CountPatients: float, CountSeries: float, CountStudies: float, TotalDiskSize: string, TotalDiskSizeMB: float, TotalUncompressedSize: string, TotalUncompressedSizeMB: float>
export def "get-statistics" [
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
    path: "/statistics"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get storage commitment report
#
# GET /storage-commitment/{id}
# Returns: record<Failures: list<record>, RemoteAET: string, Status: string, Success: list<record>>
export def "get-storage-commitment-id" [
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
    path: "/storage-commitment/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove after storage commitment
#
# POST /storage-commitment/{id}/remove
export def "post-storage-commitment-id-remove" [
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
    method: post
    path: "/storage-commitment/{id}/remove"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the available studies
#
# GET /studies
export def "get-studies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # If present, retrieve detailed information about the individual studies
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --limit: float # Limit the number of results
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --since: float # Show only the resources since the provided index
]: nothing -> any {
  http-request {
    method: get
    path: "/studies"
    query: [{name: expand, var: expand}, {name: full, var: qp_full}, {name: limit, var: limit}, {name: requestedTags, var: requested_tags}, {name: short, var: short}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, qp_full: $qp_full, limit: $limit, requested_tags: $requested_tags, short: $short, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete some study
#
# DELETE /studies/{id}
export def "delete-studies-id" [
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
    path: "/studies/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about some study
#
# GET /studies/{id}
export def "get-studies-id" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Anonymize study
#
# POST /studies/{id}/anonymize
# Returns: record<ID: string, Path: string>
export def "post-studies-id-anonymize" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --dicom-version: string # Version of the DICOM standard to be used for anonymization. Check out configuration option `DeidentifyLogsDicomVersion` for possible values.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # List of DICOM tags whose value must not be destroyed by the anonymization. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --keep-private-tags: oneof<nothing, bool> # Keep the private tags from the DICOM instances (defaults to `false`)
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of additional tags to be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/studies/{id}/anonymize"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: DicomVersion, var: dicom_version}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepPrivateTags, var: keep_private_tags}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: Replace, var: replace}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, dicom_version: $dicom_version, force: $force, keep: $keep, keep_private_tags: $keep_private_tags, keep_source: $keep_source, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, replace: $replace, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ZIP archive
#
# GET /studies/{id}/archive
export def "get-studies-id-archive" [
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
  --filename: string # Filename to set in the "Content-Disposition" HTTP header (including file extension)
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/archive"
    path_params: [{name: id, var: id}]
    query: [{name: filename, var: filename}, {name: transcode, var: transcode}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filename: $filename, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ZIP archive
#
# POST /studies/{id}/archive
# Returns: record<ID: string, Path: string>
export def "post-studies-id-archive" [
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
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/studies/{id}/archive"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Priority, var: priority}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, priority: $priority, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List attachments
#
# GET /studies/{id}/attachments
export def "get-studies-id-attachments" [
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
  --qp-full: string # If present, retrieve the attachments list and their numerical ids (spec name: full)
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attachment
#
# DELETE /studies/{id}/attachments/{name}
export def "delete-studies-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/studies/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations on attachments
#
# GET /studies/{id}/attachments/{name}
export def "get-studies-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set attachment
#
# PUT /studies/{id}/attachments/{name}
export def "put-studies-id-attachments-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the attachment, if this is not the first time this attachment is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/studies/{id}/attachments/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compress attachment
#
# POST /studies/{id}/attachments/{name}/compress
export def "post-studies-id-attachments-name-compress" [
  id: string
  name: string
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
    path: "/studies/{id}/attachments/{name}/compress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment (no decompression)
#
# GET /studies/{id}/attachments/{name}/compressed-data
export def "get-studies-id-attachments-name-compressed-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/compressed-data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment on disk
#
# GET /studies/{id}/attachments/{name}/compressed-md5
export def "get-studies-id-attachments-name-compressed-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/compressed-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment on disk
#
# GET /studies/{id}/attachments/{name}/compressed-size
export def "get-studies-id-attachments-name-compressed-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/compressed-size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment
#
# GET /studies/{id}/attachments/{name}/data
export def "get-studies-id-attachments-name-data" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/data"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info about the attachment
#
# GET /studies/{id}/attachments/{name}/info
export def "get-studies-id-attachments-name-info" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/info"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Is attachment compressed?
#
# GET /studies/{id}/attachments/{name}/is-compressed
export def "get-studies-id-attachments-name-is-compressed" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/is-compressed"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MD5 of attachment
#
# GET /studies/{id}/attachments/{name}/md5
export def "get-studies-id-attachments-name-md5" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get size of attachment
#
# GET /studies/{id}/attachments/{name}/size
export def "get-studies-id-attachments-name-size" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the attachment, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/attachments/{name}/size"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uncompress attachment
#
# POST /studies/{id}/attachments/{name}/uncompress
export def "post-studies-id-attachments-name-uncompress" [
  id: string
  name: string
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
    path: "/studies/{id}/attachments/{name}/uncompress"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify attachment
#
# POST /studies/{id}/attachments/{name}/verify-md5
export def "post-studies-id-attachments-name-verify-md5" [
  id: string
  name: string
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
    path: "/studies/{id}/attachments/{name}/verify-md5"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child instances
#
# GET /studies/{id}/instances
export def "get-studies-id-instances" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/instances"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags of instances
#
# GET /studies/{id}/instances-tags
export def "get-studies-id-instances-tags" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/instances-tags"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create DICOMDIR media
#
# GET /studies/{id}/media
export def "get-studies-id-media" [
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
  --extended: string # If present, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*
  --filename: string # Filename to set in the "Content-Disposition" HTTP header (including file extension)
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: extended, var: extended}, {name: filename, var: filename}, {name: transcode, var: transcode}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, extended: $extended, filename: $filename, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create DICOMDIR media
#
# POST /studies/{id}/media
# Returns: record<ID: string, Path: string>
export def "post-studies-id-media" [
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
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --extended: oneof<nothing, bool> # If `true`, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*. Default value is `false`.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/studies/{id}/media"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Extended, var: extended}, {name: Priority, var: priority}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, extended: $extended, priority: $priority, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Merge study
#
# POST /studies/{id}/merge
# Returns: record<ID: string, Path: string>
export def "post-studies-id-merge" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --keep-source: oneof<nothing, bool> # If set to `true`, instructs Orthanc to keep a copy of the original resources in their source study. By default, the original resources are deleted from Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --resources: list<string> # The list of DICOM resources (studies, series, and/or instances) to be merged into the study of interest (mandatory option)
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/studies/{id}/merge"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, keep_source: $keep_source, permissive: $permissive, priority: $priority, resources: $resources, synchronous: $synchronous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata
#
# GET /studies/{id}/metadata
export def "get-studies-id-metadata" [
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
  --expand: string # If present, also retrieve the value of the individual metadata
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/metadata"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete metadata
#
# DELETE /studies/{id}/metadata/{name}
export def "delete-studies-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, to check if its content has not changed and can be deleted. This header is mandatory if `CheckRevisions` option is `true`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/studies/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata
#
# GET /studies/{id}/metadata/{name}
export def "get-studies-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Optional revision of the metadata, to check if its content has changed
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set metadata
#
# PUT /studies/{id}/metadata/{name}
export def "put-studies-id-metadata-name" [
  id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Revision of the metadata, if this is not the first time this metadata is set.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/studies/{id}/metadata/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, if_match: $if_match, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify study
#
# POST /studies/{id}/modify
# Returns: record<ID: string, Path: string>
export def "post-studies-id-modify" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # Keep the original value of the specified tags, to be chosen among the `StudyInstanceUID`, `SeriesInstanceUID` and `SOPInstanceUID` tags. Avoid this feature as much as possible, as this breaks the DICOM model of the real world.
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of tags that must be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --remove-private-tags: oneof<nothing, bool> # Remove the private tags from the DICOM instances (defaults to `false`)
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/studies/{id}/modify"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: RemovePrivateTags, var: remove_private_tags}, {name: Replace, var: replace}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, force: $force, keep: $keep, keep_source: $keep_source, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, remove_private_tags: $remove_private_tags, replace: $replace, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get study module
#
# GET /studies/{id}/module
export def "get-studies-id-module" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/module"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get patient module of study
#
# GET /studies/{id}/module-patient
export def "get-studies-id-module-patient" [
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
  --ignore-length: list<string> # Also include the DICOM tags that are provided in this list, even if their associated value is long
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/module-patient"
    path_params: [{name: id, var: id}]
    query: [{name: ignore-length, var: ignore_length, style: multi}, {name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_length: $ignore_length, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get parent patient
#
# GET /studies/{id}/patient
export def "get-studies-id-patient" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/patient"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconstruct tags & optionally files of study
#
# POST /studies/{id}/reconstruct
export def "post-studies-id-reconstruct" [
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
  --reconstruct-files: oneof<nothing, bool> # Also reconstruct the files of the resources (e.g: apply IngestTranscoding, StorageCompression). 'false' by default. (New in Orthanc 1.11.0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/studies/{id}/reconstruct"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReconstructFiles, var: reconstruct_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, reconstruct_files: $reconstruct_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get child series
#
# GET /studies/{id}/series
export def "get-studies-id-series" [
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
  --qp-full: oneof<nothing, bool> # If present, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: full)
  --requested-tags: string # If present, list the DICOM Tags you want to list in the response. This argument is a semi-column separated list of DICOM Tags identifiers; e.g: 'requestedTags=0010,0010;PatientBirthDate'. The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/series"
    path_params: [{name: id, var: id}]
    query: [{name: full, var: qp_full}, {name: requestedTags, var: requested_tags}, {name: short, var: short}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_full: $qp_full, requested_tags: $requested_tags, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shared tags
#
# GET /studies/{id}/shared-tags
export def "get-studies-id-shared-tags" [
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
  --short: oneof<nothing, bool> # If present, report the DICOM tags in hexadecimal format
  --simplify: oneof<nothing, bool> # If present, report the DICOM tags in human-readable format (using the symbolic name of the tags)
]: nothing -> any {
  http-request {
    method: get
    path: "/studies/{id}/shared-tags"
    path_params: [{name: id, var: id}]
    query: [{name: short, var: short}, {name: simplify, var: simplify}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, short: $short, simplify: $simplify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Split study
#
# POST /studies/{id}/split
# Returns: record<ID: string, Path: string>
export def "post-studies-id-split" [
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
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --instances: list<string> # The list of instances to be separated from the parent study. These instances must all be children of the same source study, that is specified in the URI.
  --keep-source: oneof<nothing, bool> # If set to `true`, instructs Orthanc to keep a copy of the original series/instances in the source study. By default, the original series/instances are deleted from Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --remove: list<string> # List of tags that must be removed in the new study (from the same modules as in the `Replace` option)
  --replace: record # Associative array to change the value of some DICOM tags in the new study. These tags must be part of the "Patient Module Attributes" or the "General Study Module Attributes", as specified by the DICOM 2011 standard in Tables C.7-1 and C.7-3.
  --series: list<string> # The list of series to be separated from the parent study. These series must all be children of the same source study, that is specified in the URI.
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/studies/{id}/split"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Instances, var: instances}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: Remove, var: remove}, {name: Replace, var: replace}, {name: Series, var: series}, {name: Synchronous, var: synchronous}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, asynchronous: $asynchronous, instances: $instances, keep_source: $keep_source, permissive: $permissive, priority: $priority, remove: $remove, replace: $replace, series: $series, synchronous: $synchronous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get study statistics
#
# GET /studies/{id}/statistics
# Returns: record<CountInstances: float, CountSeries: float, DicomDiskSize: string, DicomDiskSizeMB: float, DicomUncompressedSize: string, DicomUncompressedSizeMB: float, DiskSize: string, DiskSizeMB: float, UncompressedSize: string, UncompressedSizeMB: float>
export def "get-studies-id-statistics" [
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
    path: "/studies/{id}/statistics"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get system information
#
# GET /system
# Returns: record<ApiVersion: float, CheckRevisions: bool, DatabaseBackendPlugin: string, DatabaseServerIdentifier: string, DatabaseVersion: float, DicomAet: string, DicomPort: float, HttpPort: float, IngestTranscoding: string, IsHttpServerSecure: bool, MainDicomTags: record, MaximumStorageMode: string, MaximumStorageSize: float, Name: string, OverwriteInstances: bool, PluginsEnabled: bool, StorageAreaPlugin: string, StorageCompression: bool, Version: string>
export def "get-system" [
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
    path: "/system"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List operations
#
# GET /tools
export def "get-tools" [
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
    method: get
    path: "/tools"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get accepted transfer syntaxes
#
# GET /tools/accepted-transfer-syntaxes
export def "get-tools-accepted-transfer-syntaxes" [
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
    method: get
    path: "/tools/accepted-transfer-syntaxes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set accepted transfer syntaxes
#
# PUT /tools/accepted-transfer-syntaxes
export def "put-tools-accepted-transfer-syntaxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/accepted-transfer-syntaxes"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Anonymize a set of resources
#
# POST /tools/bulk-anonymize
# Returns: record<ID: string, Path: string>
export def "post-tools-bulk-anonymize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --dicom-version: string # Version of the DICOM standard to be used for anonymization. Check out configuration option `DeidentifyLogsDicomVersion` for possible values.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # List of DICOM tags whose value must not be destroyed by the anonymization. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --keep-private-tags: oneof<nothing, bool> # Keep the private tags from the DICOM instances (defaults to `false`)
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of additional tags to be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --resources: list<string> # List of the Orthanc identifiers of the patients/studies/series/instances of interest.
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tools/bulk-anonymize"
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: DicomVersion, var: dicom_version}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepPrivateTags, var: keep_private_tags}, {name: KeepSource, var: keep_source}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: Replace, var: replace}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asynchronous: $asynchronous, dicom_version: $dicom_version, force: $force, keep: $keep, keep_private_tags: $keep_private_tags, keep_source: $keep_source, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, replace: $replace, resources: $resources, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe a set of resources
#
# POST /tools/bulk-content
export def "post-tools-bulk-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-full: oneof<nothing, bool> # If set to `true`, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: Full)
  --level: string # This optional argument specifies the level of interest (can be `Patient`, `Study`, `Series` or `Instance`). Orthanc will loop over the items inside `Resources`, and explore upward or downward in the DICOM hierarchy in order to find the level of interest.
  --metadata: oneof<nothing, bool> # If set to `true` (default value), the metadata associated with the resources will also be retrieved.
  --resources: list<string> # List of the Orthanc identifiers of the patients/studies/series/instances of interest.
  --short: oneof<nothing, bool> # If set to `true`, report the DICOM tags in hexadecimal format
]: any -> any {
  $in | http-request {
    method: post
    path: "/tools/bulk-content"
    body: {content_type: "application/json", kind: json, fields: [{name: Full, var: body_full}, {name: Level, var: level}, {name: Metadata, var: metadata}, {name: Resources, var: resources}, {name: Short, var: short}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body_full: $body_full, level: $level, metadata: $metadata, resources: $resources, short: $short
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a set of resources
#
# POST /tools/bulk-delete
export def "post-tools-bulk-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resources: list<string> # List of the Orthanc identifiers of the patients/studies/series/instances of interest.
]: any -> any {
  $in | http-request {
    method: post
    path: "/tools/bulk-delete"
    body: {content_type: "application/json", kind: json, fields: [{name: Resources, var: resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a set of resources
#
# POST /tools/bulk-modify
# Returns: record<ID: string, Path: string>
export def "post-tools-bulk-modify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asynchronous: oneof<nothing, bool> # If `true`, run the job in asynchronous mode, which means that the REST API call will immediately return, reporting the identifier of a job. Prefer this flavor wherever possible.
  --force: oneof<nothing, bool> # Allow the modification of tags related to DICOM identifiers, at the risk of breaking the DICOM model of the real world
  --keep: list<string> # Keep the original value of the specified tags, to be chosen among the `StudyInstanceUID`, `SeriesInstanceUID` and `SOPInstanceUID` tags. Avoid this feature as much as possible, as this breaks the DICOM model of the real world.
  --keep-source: oneof<nothing, bool> # If set to `false`, instructs Orthanc to the remove original resources. By default, the original resources are kept in Orthanc.
  --level: string # Level of the modification (`Patient`, `Study`, `Series` or `Instance`). If absent, the level defaults to `Instance`, but is set to `Patient` if `PatientID` is modified, to `Study` if `StudyInstanceUID` is modified, or to `Series` if `SeriesInstancesUID` is modified. (new in Orthanc 1.9.7)
  --permissive: oneof<nothing, bool> # If `true`, ignore errors during the individual steps of the job.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --private-creator: string # The private creator to be used for private tags in `Replace`
  --remove: list<string> # List of tags that must be removed from the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --remove-private-tags: oneof<nothing, bool> # Remove the private tags from the DICOM instances (defaults to `false`)
  --replace: record # Associative array to change the value of some DICOM tags in the DICOM instances. Starting with Orthanc 1.9.4, paths to subsequences can be provided using the same syntax as the `dcmodify` command-line tool (wildcards are supported as well).
  --resources: list<string> # List of the Orthanc identifiers of the patients/studies/series/instances of interest.
  --synchronous: oneof<nothing, bool> # If `true`, run the job in synchronous mode, which means that the HTTP answer will directly contain the result of the job. This is the default, easy behavior, but it is *not* desirable for long jobs, as it might lead to network timeouts.
  --transcode: string # Transcode the DICOM instances to the provided DICOM transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tools/bulk-modify"
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Force, var: force}, {name: Keep, var: keep}, {name: KeepSource, var: keep_source}, {name: Level, var: level}, {name: Permissive, var: permissive}, {name: Priority, var: priority}, {name: PrivateCreator, var: private_creator}, {name: Remove, var: remove}, {name: RemovePrivateTags, var: remove_private_tags}, {name: Replace, var: replace}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asynchronous: $asynchronous, force: $force, keep: $keep, keep_source: $keep_source, level: $level, permissive: $permissive, priority: $priority, private_creator: $private_creator, remove: $remove, remove_private_tags: $remove_private_tags, replace: $replace, resources: $resources, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ZIP archive
#
# POST /tools/create-archive
# Returns: record<ID: string, Path: string>
export def "post-tools-create-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --resources: list<string> # The list of Orthanc identifiers of interest.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tools/create-archive"
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Priority, var: priority}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    asynchronous: $asynchronous, priority: $priority, resources: $resources, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create one DICOM instance
#
# POST /tools/create-dicom
# Returns: record<ID: string, Path: string>
export def "post-tools-create-dicom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # This field can be used to embed an image (pixel data) or a PDF inside the created DICOM instance. The PNG image, the JPEG image or the PDF file must be provided using their [data URI scheme encoding](https://en.wikipedia.org/wiki/Data_URI_scheme). This field can possibly contain a JSON array, in which case a DICOM series is created containing one DICOM instance for each item in the `Content` field.
  --force: oneof<nothing, bool> # Avoid the consistency checks for the DICOM tags that enforce the DICOM model of the real-world. You can notably use this flag if you need to manually set the tags `StudyInstanceUID`, `SeriesInstanceUID`, or `SOPInstanceUID`. Be careful with this feature.
  --interpret-binary-tags: oneof<nothing, bool> # If some value in the `Tags` associative array is formatted according to some [data URI scheme encoding](https://en.wikipedia.org/wiki/Data_URI_scheme), whether this value is decoded to a binary value or kept as such (`true` by default)
  --parent: string # If present, the newly created instance will be attached to the parent DICOM resource whose Orthanc identifier is contained in this field. The DICOM tags of the parent modules in the DICOM hierarchy will be automatically copied to the newly created instance.
  --private-creator: string # The private creator to be used for private tags in `Tags`
  --tags: record # Associative array containing the tags of the new instance to be created
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tools/create-dicom"
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}, {name: Force, var: force}, {name: InterpretBinaryTags, var: interpret_binary_tags}, {name: Parent, var: parent}, {name: PrivateCreator, var: private_creator}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content: $content, force: $force, interpret_binary_tags: $interpret_binary_tags, parent: $parent, private_creator: $private_creator, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create DICOMDIR media
#
# POST /tools/create-media
# Returns: record<ID: string, Path: string>
export def "post-tools-create-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --extended: oneof<nothing, bool> # If `true`, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*. Default value is `false`.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --resources: list<string> # The list of Orthanc identifiers of interest.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tools/create-media"
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Extended, var: extended}, {name: Priority, var: priority}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    asynchronous: $asynchronous, extended: $extended, priority: $priority, resources: $resources, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create DICOMDIR media
#
# POST /tools/create-media-extended
# Returns: record<ID: string, Path: string>
export def "post-tools-create-media-extended" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --asynchronous: oneof<nothing, bool> # If `true`, create the archive in asynchronous mode, which means that a job is submitted to create the archive in background.
  --extended: oneof<nothing, bool> # If `true`, will include additional tags such as `SeriesDescription`, leading to a so-called *extended DICOMDIR*. Default value is `true`.
  --priority: float # In asynchronous mode, the priority of the job. The lower the value, the higher the priority.
  --resources: list<string> # The list of Orthanc identifiers of interest.
  --synchronous: oneof<nothing, bool> # If `true`, create the archive in synchronous mode, which means that the HTTP answer will directly contain the ZIP file. This is the default, easy behavior. However, if global configuration option "SynchronousZipStream" is set to "false", asynchronous transfers should be preferred for large amount of data, as the creation of the temporary file might lead to network timeouts.
  --transcode: string # If present, the DICOM files in the archive will be transcoded to the provided transfer syntax: https://book.orthanc-server.com/faq/transcoding.html
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tools/create-media-extended"
    body: {content_type: "application/json", kind: json, fields: [{name: Asynchronous, var: asynchronous}, {name: Extended, var: extended}, {name: Priority, var: priority}, {name: Resources, var: resources}, {name: Synchronous, var: synchronous}, {name: Transcode, var: transcode}]}
    accept: ["application/json", "application/zip"]
    ok: [200]
    auth: bearer
  } {
    asynchronous: $asynchronous, extended: $extended, priority: $priority, resources: $resources, synchronous: $synchronous, transcode: $transcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get default encoding
#
# GET /tools/default-encoding
export def "get-tools-default-encoding" [
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
    method: get
    path: "/tools/default-encoding"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set default encoding
#
# PUT /tools/default-encoding
export def "put-tools-default-encoding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/default-encoding"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get DICOM conformance
#
# GET /tools/dicom-conformance
export def "get-tools-dicom-conformance" [
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
    method: get
    path: "/tools/dicom-conformance"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger C-ECHO SCU
#
# POST /tools/dicom-echo
export def "post-tools-dicom-echo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aet: string # AET of the remote DICOM modality
  --check-find: oneof<nothing, bool> # Issue a dummy C-FIND command after the C-GET SCU, in order to check whether the remote modality knows about Orthanc. This field defaults to the value of the `DicomEchoChecksFind` configuration option. New in Orthanc 1.8.1.
  --host: string # Host address of the remote DICOM modality (typically, an IP address)
  --manufacturer: string # Manufacturer of the remote DICOM modality (check configuration option `DicomModalities` for possible values
  --port: float # TCP port of the remote DICOM modality
  --timeout: float # Timeout for the C-ECHO command, in seconds
  --use-dicom-tls: oneof<nothing, bool> # Whether to use DICOM TLS in the SCU connection initiated by Orthanc (new in Orthanc 1.9.0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/tools/dicom-echo"
    body: {content_type: "application/json", kind: json, fields: [{name: AET, var: aet}, {name: CheckFind, var: check_find}, {name: Host, var: host}, {name: Manufacturer, var: manufacturer}, {name: Port, var: port}, {name: Timeout, var: timeout}, {name: UseDicomTls, var: use_dicom_tls}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aet: $aet, check_find: $check_find, host: $host, manufacturer: $manufacturer, port: $port, timeout: $timeout, use_dicom_tls: $use_dicom_tls
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute Lua script
#
# POST /tools/execute-script
export def "post-tools-execute-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/tools/execute-script"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Look for local resources
#
# POST /tools/find
export def "post-tools-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --case-sensitive: oneof<nothing, bool> # Enable case-sensitive search for PN value representations (defaults to configuration option `CaseSensitivePN`)
  --expand: oneof<nothing, bool> # Also retrieve the content of the matching resources, not only their Orthanc identifiers
  --body-full: oneof<nothing, bool> # If set to `true`, report the DICOM tags in full format (tags indexed by their hexadecimal format, associated with their symbolic name and their value) (spec name: Full)
  --level: string # Level of the query (`Patient`, `Study`, `Series` or `Instance`)
  --limit: float # Limit the number of reported resources
  --query: record # Associative array containing the filter on the values of the DICOM tags
  --requested-tags: list<string> # A list of DICOM tags to include in the response (applicable only if "Expand" is set to true). The tags requested tags are returned in the 'RequestedTags' field in the response. Note that, if you are requesting tags that are not listed in the Main Dicom Tags stored in DB, building the response might be slow since Orthanc will need to access the DICOM files. If not specified, Orthanc will return all Main Dicom Tags to keep backward compatibility with Orthanc prior to 1.11.0.
  --short: oneof<nothing, bool> # If set to `true`, report the DICOM tags in hexadecimal format
  --since: float # Show only the resources since the provided index (in conjunction with `Limit`)
]: any -> any {
  $in | http-request {
    method: post
    path: "/tools/find"
    body: {content_type: "application/json", kind: json, fields: [{name: CaseSensitive, var: case_sensitive}, {name: Expand, var: expand}, {name: Full, var: body_full}, {name: Level, var: level}, {name: Limit, var: limit}, {name: Query, var: query}, {name: RequestedTags, var: requested_tags}, {name: Short, var: short}, {name: Since, var: since}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_sensitive: $case_sensitive, expand: $expand, body_full: $body_full, level: $level, limit: $limit, query: $query, requested_tags: $requested_tags, short: $short, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an identifier
#
# GET /tools/generate-uid
export def "get-tools-generate-uid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string # Type of DICOM resource among: `patient`, `study`, `series` or `instance` (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/tools/generate-uid"
    query: [{name: level, var: level, required: true}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invalidate DICOM-as-JSON summaries
#
# POST /tools/invalidate-tags
export def "post-tools-invalidate-tags" [
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
    path: "/tools/invalidate-tags"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get main log level
#
# GET /tools/log-level
export def "get-tools-log-level" [
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
    method: get
    path: "/tools/log-level"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set main log level
#
# PUT /tools/log-level
export def "put-tools-log-level" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log level for `dicom`
#
# GET /tools/log-level-dicom
export def "get-tools-log-level-dicom" [
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
    method: get
    path: "/tools/log-level-dicom"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set log level for `dicom`
#
# PUT /tools/log-level-dicom
export def "put-tools-log-level-dicom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level-dicom"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log level for `generic`
#
# GET /tools/log-level-generic
export def "get-tools-log-level-generic" [
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
    method: get
    path: "/tools/log-level-generic"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set log level for `generic`
#
# PUT /tools/log-level-generic
export def "put-tools-log-level-generic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level-generic"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log level for `http`
#
# GET /tools/log-level-http
export def "get-tools-log-level-http" [
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
    method: get
    path: "/tools/log-level-http"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set log level for `http`
#
# PUT /tools/log-level-http
export def "put-tools-log-level-http" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level-http"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log level for `jobs`
#
# GET /tools/log-level-jobs
export def "get-tools-log-level-jobs" [
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
    method: get
    path: "/tools/log-level-jobs"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set log level for `jobs`
#
# PUT /tools/log-level-jobs
export def "put-tools-log-level-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level-jobs"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log level for `lua`
#
# GET /tools/log-level-lua
export def "get-tools-log-level-lua" [
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
    method: get
    path: "/tools/log-level-lua"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set log level for `lua`
#
# PUT /tools/log-level-lua
export def "put-tools-log-level-lua" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level-lua"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log level for `plugins`
#
# GET /tools/log-level-plugins
export def "get-tools-log-level-plugins" [
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
    method: get
    path: "/tools/log-level-plugins"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set log level for `plugins`
#
# PUT /tools/log-level-plugins
export def "put-tools-log-level-plugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level-plugins"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log level for `sqlite`
#
# GET /tools/log-level-sqlite
export def "get-tools-log-level-sqlite" [
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
    method: get
    path: "/tools/log-level-sqlite"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set log level for `sqlite`
#
# PUT /tools/log-level-sqlite
export def "put-tools-log-level-sqlite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/log-level-sqlite"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Look for DICOM identifiers
#
# POST /tools/lookup
export def "post-tools-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/tools/lookup"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Are metrics collected?
#
# GET /tools/metrics
export def "get-tools-metrics" [
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
    method: get
    path: "/tools/metrics"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable collection of metrics
#
# PUT /tools/metrics
export def "put-tools-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/metrics"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get usage metrics
#
# GET /tools/metrics-prometheus
export def "get-tools-metrics-prometheus" [
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
    method: get
    path: "/tools/metrics-prometheus"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get UTC time
#
# GET /tools/now
export def "get-tools-now" [
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
    method: get
    path: "/tools/now"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get local time
#
# GET /tools/now-local
export def "get-tools-now-local" [
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
    method: get
    path: "/tools/now-local"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconstruct all the index
#
# POST /tools/reconstruct
export def "post-tools-reconstruct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reconstruct-files: oneof<nothing, bool> # Also reconstruct the files of the resources (e.g: apply IngestTranscoding, StorageCompression). 'false' by default. (New in Orthanc 1.11.0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/tools/reconstruct"
    body: {content_type: "application/json", kind: json, fields: [{name: ReconstructFiles, var: reconstruct_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reconstruct_files: $reconstruct_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restart Orthanc
#
# POST /tools/reset
export def "post-tools-reset" [
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
    path: "/tools/reset"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shutdown Orthanc
#
# POST /tools/shutdown
export def "post-tools-shutdown" [
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
    path: "/tools/shutdown"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Is unknown SOP class accepted?
#
# GET /tools/unknown-sop-class-accepted
export def "get-tools-unknown-sop-class-accepted" [
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
    method: get
    path: "/tools/unknown-sop-class-accepted"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set unknown SOP class accepted
#
# PUT /tools/unknown-sop-class-accepted
export def "put-tools-unknown-sop-class-accepted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/tools/unknown-sop-class-accepted"
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
