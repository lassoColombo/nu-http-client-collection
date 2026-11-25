# Auto-generated client for Cloud Storage JSON API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/storage/v1/openapi.json
# Auth: --token flag or $env.CLOUD_STORAGE_JSON_API_TOKEN

const CLIENT = {
  base_url: "https://storage.googleapis.com/storage/v1"
  token_env_var: "CLOUD_STORAGE_JSON_API_TOKEN"
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

def base-url-completer [] { ["https://storage.googleapis.com/storage/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def projection-completer [] { ["full" "noAcl"] }
def predefined-acl-completer [] { ["authenticatedRead" "private" "projectPrivate" "publicRead" "publicReadWrite"] }
def predefined-default-object-acl-completer [] { ["authenticatedRead" "bucketOwnerFullControl" "bucketOwnerRead" "private" "projectPrivate" "publicRead"] }
def predefined-acl-completer-1 [] { ["authenticatedRead" "bucketOwnerFullControl" "bucketOwnerRead" "private" "projectPrivate" "publicRead"] }
def destination-predefined-acl-completer [] { ["authenticatedRead" "bucketOwnerFullControl" "bucketOwnerRead" "private" "projectPrivate" "publicRead"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    storage-buckets-list: "record<items: table<acl: list, autoclass: record, billing: record, cors: list, customPlacementConfig: record, defaultEventBasedHold: bool, defaultObjectAcl: list, encryption: record, etag: string, iamConfiguration: record, id: string, kind: string, labels: record, lifecycle: record, location: string, locationType: string, logging: record, metageneration: string, name: string, owner: record, projectNumber: string, retentionPolicy: record, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record, website: record>, kind: string, nextPageToken: string>"
    storage-buckets-insert: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>"
    storage-buckets-get: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>"
    storage-buckets-patch: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>"
    storage-buckets-update: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>"
    storage-bucket-access-controls-list: "record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, kind: string>"
    storage-bucket-access-controls-insert: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-bucket-access-controls-get: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-bucket-access-controls-patch: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-bucket-access-controls-update: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-default-object-access-controls-list: "record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, kind: string>"
    storage-default-object-access-controls-insert: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-default-object-access-controls-get: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-default-object-access-controls-patch: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-default-object-access-controls-update: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-buckets-get-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>"
    storage-buckets-set-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>"
    storage-buckets-test-iam-permissions: "record<kind: string, permissions: list<string>>"
    storage-buckets-lock-retention-policy: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>"
    storage-notifications-list: "record<items: table<custom_attributes: record, etag: string, event_types: list, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string>, kind: string>"
    storage-notifications-insert: "record<custom_attributes: record, etag: string, event_types: list<string>, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string>"
    storage-notifications-get: "record<custom_attributes: record, etag: string, event_types: list<string>, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string>"
    storage-objects-list: "record<items: table<acl: list, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>, kind: string, nextPageToken: string, prefixes: list<string>>"
    storage-objects-insert: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>"
    storage-objects-watch-all: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    storage-objects-get: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>"
    storage-objects-patch: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>"
    storage-objects-update: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>"
    storage-object-access-controls-list: "record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, kind: string>"
    storage-object-access-controls-insert: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-object-access-controls-get: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-object-access-controls-patch: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-object-access-controls-update: "record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>"
    storage-objects-get-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>"
    storage-objects-set-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>"
    storage-objects-test-iam-permissions: "record<kind: string, permissions: list<string>>"
    storage-objects-compose: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>"
    storage-objects-copy: "record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>"
    storage-objects-rewrite: "record<done: bool, kind: string, objectSize: string, resource: record<acl: list<record>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>, rewriteToken: string, totalBytesRewritten: string>"
    storage-projects-hmac-keys-list: "record<items: table<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>, kind: string, nextPageToken: string>"
    storage-projects-hmac-keys-create: "record<kind: string, metadata: record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>, secret: string>"
    storage-projects-hmac-keys-get: "record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>"
    storage-projects-hmac-keys-update: "record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>"
    storage-projects-service-account-get: "record<email_address: string, kind: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["storage-buckets-list" "storage-buckets-insert" "storage-buckets-delete" "storage-buckets-get" "storage-buckets-patch" "storage-buckets-update" "storage-bucket-access-controls-list" "storage-bucket-access-controls-insert" "storage-bucket-access-controls-delete" "storage-bucket-access-controls-get" "storage-bucket-access-controls-patch" "storage-bucket-access-controls-update" "storage-default-object-access-controls-list" "storage-default-object-access-controls-insert" "storage-default-object-access-controls-delete" "storage-default-object-access-controls-get" "storage-default-object-access-controls-patch" "storage-default-object-access-controls-update" "storage-buckets-get-iam-policy" "storage-buckets-set-iam-policy" "storage-buckets-test-iam-permissions" "storage-buckets-lock-retention-policy" "storage-notifications-list" "storage-notifications-insert" "storage-notifications-delete" "storage-notifications-get" "storage-objects-list" "storage-objects-insert" "storage-objects-watch-all" "storage-objects-delete" "storage-objects-get" "storage-objects-patch" "storage-objects-update" "storage-object-access-controls-list" "storage-object-access-controls-insert" "storage-object-access-controls-delete" "storage-object-access-controls-get" "storage-object-access-controls-patch" "storage-object-access-controls-update" "storage-objects-get-iam-policy" "storage-objects-set-iam-policy" "storage-objects-test-iam-permissions" "storage-objects-compose" "storage-objects-copy" "storage-objects-rewrite" "storage-channels-stop" "storage-projects-hmac-keys-list" "storage-projects-hmac-keys-create" "storage-projects-hmac-keys-delete" "storage-projects-hmac-keys-get" "storage-projects-hmac-keys-update" "storage-projects-service-account-get" "commands"] | sort) } | get name | first)
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

# Retrieves a list of buckets for a given project.
#
# GET /b
# Returns: record<items: table<acl: list, autoclass: record, billing: record, cors: list, customPlacementConfig: record, defaultEventBasedHold: bool, defaultObjectAcl: list, encryption: record, etag: string, iamConfiguration: record, id: string, kind: string, labels: record, lifecycle: record, location: string, locationType: string, logging: record, metageneration: string, name: string, owner: record, projectNumber: string, retentionPolicy: record, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record, website: record>, kind: string, nextPageToken: string>
# operationId: storage.buckets.list
export def "storage-buckets-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --project: string # A valid API project identifier. (required)
  --max-results: int # Maximum number of buckets to return in a single response. The service will use this parameter or 1,000 items, whichever is smaller.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --prefix: string # Filter results to buckets whose names begin with this prefix.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --user-project: string # The project to be billed for this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: project, var: project, required: true}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: prefix, var: prefix}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, project: $project, max_results: $max_results, page_token: $page_token, prefix: $prefix, projection: $projection, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new bucket.
#
# POST /b
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>
# operationId: storage.buckets.insert
export def "storage-buckets-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --project: string # A valid API project identifier. (required)
  --predefined-acl: string@predefined-acl-completer # Apply a predefined set of access controls to this bucket.
  --predefined-default-object-acl: string@predefined-default-object-acl-completer # Apply a predefined set of default object access controls to this bucket.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the bucket resource specifies acl or defaultObjectAcl properties, when it defaults to full.
  --user-project: string # The project to be billed for this request.
  --acl: list # Access controls on the bucket. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
  --autoclass: record # The bucket's Autoclass configuration. — shape: {enabled?: bool, toggleTime?: string}
  --billing: record # The bucket's billing configuration. — shape: {requesterPays?: bool}
  --cors: list # The bucket's Cross-Origin Resource Sharing (CORS) configuration. — item shape: {maxAgeSeconds?: int, method?: list<string>, origin?: list<string>, responseHeader?: list<string>}
  --custom-placement-config: record # The bucket's custom placement configuration for Custom Dual Regions. — shape: {dataLocations?: list<string>}
  --default-event-based-hold: oneof<nothing, bool> # The default value for event-based hold on newly created objects in this bucket. Event-based hold is a way to retain objects indefinitely until an event occurs, signified by the hold's release. After being released, such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false. Objects under event-based hold cannot be deleted, overwritten or archived until the hold is removed.
  --default-object-acl: list # Default access controls to apply to new objects when no ACL is provided. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --encryption: record # Encryption configuration for a bucket. — shape: {defaultKmsKeyName?: string}
  --etag: string # HTTP 1.1 Entity tag for the bucket.
  --iam-configuration: record # The bucket's IAM configuration. — shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
  --id: string # The ID of the bucket. For buckets, the id and name properties are the same.
  --kind: string # The kind of item this is. For buckets, this is always storage#bucket. (default: storage#bucket)
  --labels: record # User-provided labels, in key/value pairs.
  --lifecycle: record # The bucket's lifecycle configuration. See lifecycle management for more information. — shape: {rule?: list}
  --location: string # The location of the bucket. Object data for objects in the bucket resides in physical storage within this region. Defaults to US. See the developer's guide for the authoritative list.
  --location-type: string # The type of the bucket location.
  --logging: record # The bucket's logging configuration, which defines the destination bucket and optional name prefix for the current bucket's logs. — shape: {logBucket?: string, logObjectPrefix?: string}
  --metageneration: string # The metadata generation of this bucket. (format: int64)
  --name: string # The name of the bucket.
  --owner: record # The owner of the bucket. This is always the project team's owner group. — shape: {entity?: string, entityId?: string}
  --project-number: string # The project number of the project the bucket belongs to. (format: uint64)
  --retention-policy: record # The bucket's retention policy. The retention policy enforces a minimum retention time for all objects contained in the bucket, based on their creation time. Any attempt to overwrite or delete objects younger than the retention period will result in a PERMISSION_DENIED error. An unlocked retention policy can be modified or removed from the bucket via a storage.buckets.update operation. A locked retention policy cannot be removed or shortened in duration for the lifetime of the bucket. Attempting to remove or decrease period of a locked retention policy will result in a PERMISSION_DENIED error. — shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
  --rpo: string # The Recovery Point Objective (RPO) of this bucket. Set to ASYNC_TURBO to turn on Turbo Replication on a bucket.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use.
  --self-link: string # The URI of this bucket.
  --storage-class: string # The bucket's default storage class, used whenever no storageClass is specified for a newly-created object. This defines how objects in the bucket are stored and determines the SLA and the cost of storage. Values include MULTI_REGIONAL, REGIONAL, STANDARD, NEARLINE, COLDLINE, ARCHIVE, and DURABLE_REDUCED_AVAILABILITY. If this value is not specified when the bucket is created, it will default to STANDARD. For more information, see storage classes.
  --time-created: string # The creation time of the bucket in RFC 3339 format. (format: date-time)
  --updated: string # The modification time of the bucket in RFC 3339 format. (format: date-time)
  --versioning: record # The bucket's versioning configuration. — shape: {enabled?: bool}
  --website: record # The bucket's website configuration, controlling how the service behaves when accessing bucket contents as a web site. See the Static Website Examples for more information. — shape: {mainPageSuffix?: string, notFoundPage?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: project, var: project, required: true}, {name: predefinedAcl, var: predefined_acl}, {name: predefinedDefaultObjectAcl, var: predefined_default_object_acl}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: autoclass, var: autoclass}, {name: billing, var: billing}, {name: cors, var: cors}, {name: customPlacementConfig, var: custom_placement_config}, {name: defaultEventBasedHold, var: default_event_based_hold}, {name: defaultObjectAcl, var: default_object_acl}, {name: encryption, var: encryption}, {name: etag, var: etag}, {name: iamConfiguration, var: iam_configuration}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lifecycle, var: lifecycle}, {name: location, var: location}, {name: locationType, var: location_type}, {name: logging, var: logging}, {name: metageneration, var: metageneration}, {name: name, var: name}, {name: owner, var: owner}, {name: projectNumber, var: project_number}, {name: retentionPolicy, var: retention_policy}, {name: rpo, var: rpo}, {name: satisfiesPZS, var: satisfies_pzs}, {name: selfLink, var: self_link}, {name: storageClass, var: storage_class}, {name: timeCreated, var: time_created}, {name: updated, var: updated}, {name: versioning, var: versioning}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, project: $project, predefined_acl: $predefined_acl, predefined_default_object_acl: $predefined_default_object_acl, projection: $projection, user_project: $user_project, acl: $acl, autoclass: $autoclass, billing: $billing, cors: $cors, custom_placement_config: $custom_placement_config, default_event_based_hold: $default_event_based_hold, default_object_acl: $default_object_acl, encryption: $encryption, etag: $etag, iam_configuration: $iam_configuration, id: $id, kind: $kind, labels: $labels, lifecycle: $lifecycle, location: $location, location_type: $location_type, logging: $logging, metageneration: $metageneration, name: $name, owner: $owner, project_number: $project_number, retention_policy: $retention_policy, rpo: $rpo, satisfies_pzs: $satisfies_pzs, self_link: $self_link, storage_class: $storage_class, time_created: $time_created, updated: $updated, versioning: $versioning, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes an empty bucket.
#
# DELETE /b/{bucket}
# operationId: storage.buckets.delete
export def "storage-buckets-delete" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # If set, only deletes the bucket if its metageneration matches this value.
  --if-metageneration-not-match: string # If set, only deletes the bucket if its metageneration does not match this value.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  http-request {
    method: delete
    path: "/b/{bucket}"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata for the specified bucket.
#
# GET /b/{bucket}
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>
# operationId: storage.buckets.get
export def "storage-buckets-get" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration does not match the given value.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, projection: $projection, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a bucket. Changes to the bucket will be readable immediately after writing, but configuration changes may take time to propagate.
#
# PATCH /b/{bucket}
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>
# operationId: storage.buckets.patch
export def "storage-buckets-patch" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer # Apply a predefined set of access controls to this bucket.
  --predefined-default-object-acl: string@predefined-default-object-acl-completer # Apply a predefined set of default object access controls to this bucket.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the bucket. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
  --autoclass: record # The bucket's Autoclass configuration. — shape: {enabled?: bool, toggleTime?: string}
  --billing: record # The bucket's billing configuration. — shape: {requesterPays?: bool}
  --cors: list # The bucket's Cross-Origin Resource Sharing (CORS) configuration. — item shape: {maxAgeSeconds?: int, method?: list<string>, origin?: list<string>, responseHeader?: list<string>}
  --custom-placement-config: record # The bucket's custom placement configuration for Custom Dual Regions. — shape: {dataLocations?: list<string>}
  --default-event-based-hold: oneof<nothing, bool> # The default value for event-based hold on newly created objects in this bucket. Event-based hold is a way to retain objects indefinitely until an event occurs, signified by the hold's release. After being released, such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false. Objects under event-based hold cannot be deleted, overwritten or archived until the hold is removed.
  --default-object-acl: list # Default access controls to apply to new objects when no ACL is provided. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --encryption: record # Encryption configuration for a bucket. — shape: {defaultKmsKeyName?: string}
  --etag: string # HTTP 1.1 Entity tag for the bucket.
  --iam-configuration: record # The bucket's IAM configuration. — shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
  --id: string # The ID of the bucket. For buckets, the id and name properties are the same.
  --kind: string # The kind of item this is. For buckets, this is always storage#bucket. (default: storage#bucket)
  --labels: record # User-provided labels, in key/value pairs.
  --lifecycle: record # The bucket's lifecycle configuration. See lifecycle management for more information. — shape: {rule?: list}
  --location: string # The location of the bucket. Object data for objects in the bucket resides in physical storage within this region. Defaults to US. See the developer's guide for the authoritative list.
  --location-type: string # The type of the bucket location.
  --logging: record # The bucket's logging configuration, which defines the destination bucket and optional name prefix for the current bucket's logs. — shape: {logBucket?: string, logObjectPrefix?: string}
  --metageneration: string # The metadata generation of this bucket. (format: int64)
  --name: string # The name of the bucket.
  --owner: record # The owner of the bucket. This is always the project team's owner group. — shape: {entity?: string, entityId?: string}
  --project-number: string # The project number of the project the bucket belongs to. (format: uint64)
  --retention-policy: record # The bucket's retention policy. The retention policy enforces a minimum retention time for all objects contained in the bucket, based on their creation time. Any attempt to overwrite or delete objects younger than the retention period will result in a PERMISSION_DENIED error. An unlocked retention policy can be modified or removed from the bucket via a storage.buckets.update operation. A locked retention policy cannot be removed or shortened in duration for the lifetime of the bucket. Attempting to remove or decrease period of a locked retention policy will result in a PERMISSION_DENIED error. — shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
  --rpo: string # The Recovery Point Objective (RPO) of this bucket. Set to ASYNC_TURBO to turn on Turbo Replication on a bucket.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use.
  --self-link: string # The URI of this bucket.
  --storage-class: string # The bucket's default storage class, used whenever no storageClass is specified for a newly-created object. This defines how objects in the bucket are stored and determines the SLA and the cost of storage. Values include MULTI_REGIONAL, REGIONAL, STANDARD, NEARLINE, COLDLINE, ARCHIVE, and DURABLE_REDUCED_AVAILABILITY. If this value is not specified when the bucket is created, it will default to STANDARD. For more information, see storage classes.
  --time-created: string # The creation time of the bucket in RFC 3339 format. (format: date-time)
  --updated: string # The modification time of the bucket in RFC 3339 format. (format: date-time)
  --versioning: record # The bucket's versioning configuration. — shape: {enabled?: bool}
  --website: record # The bucket's website configuration, controlling how the service behaves when accessing bucket contents as a web site. See the Static Website Examples for more information. — shape: {mainPageSuffix?: string, notFoundPage?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/b/{bucket}"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: predefinedAcl, var: predefined_acl}, {name: predefinedDefaultObjectAcl, var: predefined_default_object_acl}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: autoclass, var: autoclass}, {name: billing, var: billing}, {name: cors, var: cors}, {name: customPlacementConfig, var: custom_placement_config}, {name: defaultEventBasedHold, var: default_event_based_hold}, {name: defaultObjectAcl, var: default_object_acl}, {name: encryption, var: encryption}, {name: etag, var: etag}, {name: iamConfiguration, var: iam_configuration}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lifecycle, var: lifecycle}, {name: location, var: location}, {name: locationType, var: location_type}, {name: logging, var: logging}, {name: metageneration, var: metageneration}, {name: name, var: name}, {name: owner, var: owner}, {name: projectNumber, var: project_number}, {name: retentionPolicy, var: retention_policy}, {name: rpo, var: rpo}, {name: satisfiesPZS, var: satisfies_pzs}, {name: selfLink, var: self_link}, {name: storageClass, var: storage_class}, {name: timeCreated, var: time_created}, {name: updated, var: updated}, {name: versioning, var: versioning}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, predefined_acl: $predefined_acl, predefined_default_object_acl: $predefined_default_object_acl, projection: $projection, user_project: $user_project, acl: $acl, autoclass: $autoclass, billing: $billing, cors: $cors, custom_placement_config: $custom_placement_config, default_event_based_hold: $default_event_based_hold, default_object_acl: $default_object_acl, encryption: $encryption, etag: $etag, iam_configuration: $iam_configuration, id: $id, kind: $kind, labels: $labels, lifecycle: $lifecycle, location: $location, location_type: $location_type, logging: $logging, metageneration: $metageneration, name: $name, owner: $owner, project_number: $project_number, retention_policy: $retention_policy, rpo: $rpo, satisfies_pzs: $satisfies_pzs, self_link: $self_link, storage_class: $storage_class, time_created: $time_created, updated: $updated, versioning: $versioning, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a bucket. Changes to the bucket will be readable immediately after writing, but configuration changes may take time to propagate.
#
# PUT /b/{bucket}
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>
# operationId: storage.buckets.update
export def "storage-buckets-update" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the return of the bucket metadata conditional on whether the bucket's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer # Apply a predefined set of access controls to this bucket.
  --predefined-default-object-acl: string@predefined-default-object-acl-completer # Apply a predefined set of default object access controls to this bucket.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the bucket. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, id?: string, kind?: string, projectTeam?: record, role?: string, selfLink?: string}
  --autoclass: record # The bucket's Autoclass configuration. — shape: {enabled?: bool, toggleTime?: string}
  --billing: record # The bucket's billing configuration. — shape: {requesterPays?: bool}
  --cors: list # The bucket's Cross-Origin Resource Sharing (CORS) configuration. — item shape: {maxAgeSeconds?: int, method?: list<string>, origin?: list<string>, responseHeader?: list<string>}
  --custom-placement-config: record # The bucket's custom placement configuration for Custom Dual Regions. — shape: {dataLocations?: list<string>}
  --default-event-based-hold: oneof<nothing, bool> # The default value for event-based hold on newly created objects in this bucket. Event-based hold is a way to retain objects indefinitely until an event occurs, signified by the hold's release. After being released, such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false. Objects under event-based hold cannot be deleted, overwritten or archived until the hold is removed.
  --default-object-acl: list # Default access controls to apply to new objects when no ACL is provided. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --encryption: record # Encryption configuration for a bucket. — shape: {defaultKmsKeyName?: string}
  --etag: string # HTTP 1.1 Entity tag for the bucket.
  --iam-configuration: record # The bucket's IAM configuration. — shape: {bucketPolicyOnly?: record, publicAccessPrevention?: string, uniformBucketLevelAccess?: record}
  --id: string # The ID of the bucket. For buckets, the id and name properties are the same.
  --kind: string # The kind of item this is. For buckets, this is always storage#bucket. (default: storage#bucket)
  --labels: record # User-provided labels, in key/value pairs.
  --lifecycle: record # The bucket's lifecycle configuration. See lifecycle management for more information. — shape: {rule?: list}
  --location: string # The location of the bucket. Object data for objects in the bucket resides in physical storage within this region. Defaults to US. See the developer's guide for the authoritative list.
  --location-type: string # The type of the bucket location.
  --logging: record # The bucket's logging configuration, which defines the destination bucket and optional name prefix for the current bucket's logs. — shape: {logBucket?: string, logObjectPrefix?: string}
  --metageneration: string # The metadata generation of this bucket. (format: int64)
  --name: string # The name of the bucket.
  --owner: record # The owner of the bucket. This is always the project team's owner group. — shape: {entity?: string, entityId?: string}
  --project-number: string # The project number of the project the bucket belongs to. (format: uint64)
  --retention-policy: record # The bucket's retention policy. The retention policy enforces a minimum retention time for all objects contained in the bucket, based on their creation time. Any attempt to overwrite or delete objects younger than the retention period will result in a PERMISSION_DENIED error. An unlocked retention policy can be modified or removed from the bucket via a storage.buckets.update operation. A locked retention policy cannot be removed or shortened in duration for the lifetime of the bucket. Attempting to remove or decrease period of a locked retention policy will result in a PERMISSION_DENIED error. — shape: {effectiveTime?: string, isLocked?: bool, retentionPeriod?: string}
  --rpo: string # The Recovery Point Objective (RPO) of this bucket. Set to ASYNC_TURBO to turn on Turbo Replication on a bucket.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use.
  --self-link: string # The URI of this bucket.
  --storage-class: string # The bucket's default storage class, used whenever no storageClass is specified for a newly-created object. This defines how objects in the bucket are stored and determines the SLA and the cost of storage. Values include MULTI_REGIONAL, REGIONAL, STANDARD, NEARLINE, COLDLINE, ARCHIVE, and DURABLE_REDUCED_AVAILABILITY. If this value is not specified when the bucket is created, it will default to STANDARD. For more information, see storage classes.
  --time-created: string # The creation time of the bucket in RFC 3339 format. (format: date-time)
  --updated: string # The modification time of the bucket in RFC 3339 format. (format: date-time)
  --versioning: record # The bucket's versioning configuration. — shape: {enabled?: bool}
  --website: record # The bucket's website configuration, controlling how the service behaves when accessing bucket contents as a web site. See the Static Website Examples for more information. — shape: {mainPageSuffix?: string, notFoundPage?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/b/{bucket}"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: predefinedAcl, var: predefined_acl}, {name: predefinedDefaultObjectAcl, var: predefined_default_object_acl}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: autoclass, var: autoclass}, {name: billing, var: billing}, {name: cors, var: cors}, {name: customPlacementConfig, var: custom_placement_config}, {name: defaultEventBasedHold, var: default_event_based_hold}, {name: defaultObjectAcl, var: default_object_acl}, {name: encryption, var: encryption}, {name: etag, var: etag}, {name: iamConfiguration, var: iam_configuration}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lifecycle, var: lifecycle}, {name: location, var: location}, {name: locationType, var: location_type}, {name: logging, var: logging}, {name: metageneration, var: metageneration}, {name: name, var: name}, {name: owner, var: owner}, {name: projectNumber, var: project_number}, {name: retentionPolicy, var: retention_policy}, {name: rpo, var: rpo}, {name: satisfiesPZS, var: satisfies_pzs}, {name: selfLink, var: self_link}, {name: storageClass, var: storage_class}, {name: timeCreated, var: time_created}, {name: updated, var: updated}, {name: versioning, var: versioning}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, predefined_acl: $predefined_acl, predefined_default_object_acl: $predefined_default_object_acl, projection: $projection, user_project: $user_project, acl: $acl, autoclass: $autoclass, billing: $billing, cors: $cors, custom_placement_config: $custom_placement_config, default_event_based_hold: $default_event_based_hold, default_object_acl: $default_object_acl, encryption: $encryption, etag: $etag, iam_configuration: $iam_configuration, id: $id, kind: $kind, labels: $labels, lifecycle: $lifecycle, location: $location, location_type: $location_type, logging: $logging, metageneration: $metageneration, name: $name, owner: $owner, project_number: $project_number, retention_policy: $retention_policy, rpo: $rpo, satisfies_pzs: $satisfies_pzs, self_link: $self_link, storage_class: $storage_class, time_created: $time_created, updated: $updated, versioning: $versioning, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves ACL entries on the specified bucket.
#
# GET /b/{bucket}/acl
# Returns: record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, kind: string>
# operationId: storage.bucketAccessControls.list
export def "storage-bucket-access-controls-list" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/acl"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ACL entry on the specified bucket.
#
# POST /b/{bucket}/acl
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.bucketAccessControls.insert
export def "storage-bucket-access-controls-insert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For bucket access control entries, this is always storage#bucketAccessControl. (default: storage#bucketAccessControl)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{bucket}/acl"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, entity: $entity, entity_id: $entity_id, etag: $etag, id: $id, kind: $kind, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the ACL entry for the specified entity on the specified bucket.
#
# DELETE /b/{bucket}/acl/{entity}
# operationId: storage.bucketAccessControls.delete
export def "storage-bucket-access-controls-delete" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  http-request {
    method: delete
    path: "/b/{bucket}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the ACL entry for the specified entity on the specified bucket.
#
# GET /b/{bucket}/acl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.bucketAccessControls.get
export def "storage-bucket-access-controls-get" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches an ACL entry on the specified bucket.
#
# PATCH /b/{bucket}/acl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.bucketAccessControls.patch
export def "storage-bucket-access-controls-patch" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com. (spec name: entity)
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For bucket access control entries, this is always storage#bucketAccessControl. (default: storage#bucketAccessControl)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/b/{bucket}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: body_entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, body_entity: $body_entity, entity_id: $entity_id, etag: $etag, id: $id, kind: $kind, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an ACL entry on the specified bucket.
#
# PUT /b/{bucket}/acl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.bucketAccessControls.update
export def "storage-bucket-access-controls-update" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com. (spec name: entity)
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For bucket access control entries, this is always storage#bucketAccessControl. (default: storage#bucketAccessControl)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/b/{bucket}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: body_entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, body_entity: $body_entity, entity_id: $entity_id, etag: $etag, id: $id, kind: $kind, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves default object ACL entries on the specified bucket.
#
# GET /b/{bucket}/defaultObjectAcl
# Returns: record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, kind: string>
# operationId: storage.defaultObjectAccessControls.list
export def "storage-default-object-access-controls-list" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # If present, only return default ACL listing if the bucket's current metageneration matches this value.
  --if-metageneration-not-match: string # If present, only return default ACL listing if the bucket's current metageneration does not match the given value.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/defaultObjectAcl"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new default object ACL entry on the specified bucket.
#
# POST /b/{bucket}/defaultObjectAcl
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.defaultObjectAccessControls.insert
export def "storage-default-object-access-controls-insert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{bucket}/defaultObjectAcl"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: generation, var: generation}, {name: id, var: id}, {name: kind, var: kind}, {name: object, var: object}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, entity: $entity, entity_id: $entity_id, etag: $etag, generation: $generation, id: $id, kind: $kind, object: $object, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the default object ACL entry for the specified entity on the specified bucket.
#
# DELETE /b/{bucket}/defaultObjectAcl/{entity}
# operationId: storage.defaultObjectAccessControls.delete
export def "storage-default-object-access-controls-delete" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  http-request {
    method: delete
    path: "/b/{bucket}/defaultObjectAcl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default object ACL entry for the specified entity on the specified bucket.
#
# GET /b/{bucket}/defaultObjectAcl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.defaultObjectAccessControls.get
export def "storage-default-object-access-controls-get" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/defaultObjectAcl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a default object ACL entry on the specified bucket.
#
# PATCH /b/{bucket}/defaultObjectAcl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.defaultObjectAccessControls.patch
export def "storage-default-object-access-controls-patch" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com. (spec name: entity)
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/b/{bucket}/defaultObjectAcl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: body_entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: generation, var: generation}, {name: id, var: id}, {name: kind, var: kind}, {name: object, var: object}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, body_entity: $body_entity, entity_id: $entity_id, etag: $etag, generation: $generation, id: $id, kind: $kind, object: $object, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a default object ACL entry on the specified bucket.
#
# PUT /b/{bucket}/defaultObjectAcl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.defaultObjectAccessControls.update
export def "storage-default-object-access-controls-update" [
  bucket: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com. (spec name: entity)
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --generation: string # The content generation of the object, if applied to an object. (format: int64)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --object: string # The name of the object, if applied to an object.
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/b/{bucket}/defaultObjectAcl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: body_entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: generation, var: generation}, {name: id, var: id}, {name: kind, var: kind}, {name: object, var: object}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, body_entity: $body_entity, entity_id: $entity_id, etag: $etag, generation: $generation, id: $id, kind: $kind, object: $object, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an IAM policy for the specified bucket.
#
# GET /b/{bucket}/iam
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>
# operationId: storage.buckets.getIamPolicy
export def "storage-buckets-get-iam-policy" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --options-requested-policy-version: int # The IAM policy format version to be returned. If the optionsRequestedPolicyVersion is for an older version that doesn't support part of the requested IAM policy, the request fails.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/iam"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: optionsRequestedPolicyVersion, var: options_requested_policy_version}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, options_requested_policy_version: $options_requested_policy_version, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an IAM policy for the specified bucket.
#
# PUT /b/{bucket}/iam
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>
# operationId: storage.buckets.setIamPolicy
export def "storage-buckets-set-iam-policy" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --bindings: list # An association between a role, which comes with a set of permissions, and members who may assume that role. — item shape: {condition?: record, members?: list<string>, role?: string}
  --etag: string # HTTP 1.1 Entity tag for the policy. (format: byte)
  --kind: string # The kind of item this is. For policies, this is always storage#policy. This field is ignored on input. (default: storage#policy)
  --resource-id: string # The ID of the resource to which this policy belongs. Will be of the form projects/_/buckets/bucket for buckets, and projects/_/buckets/bucket/objects/object for objects. A specific generation may be specified by appending #generationNumber to the end of the object name, e.g. projects/_/buckets/my-bucket/objects/data.txt#17. The current generation can be denoted with #0. This field is ignored on input.
  --version: int # The IAM policy format version. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/b/{bucket}/iam"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bindings, var: bindings}, {name: etag, var: etag}, {name: kind, var: kind}, {name: resourceId, var: resource_id}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, bindings: $bindings, etag: $etag, kind: $kind, resource_id: $resource_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests a set of permissions on the given bucket to see which, if any, are held by the caller.
#
# GET /b/{bucket}/iam/testPermissions
# Returns: record<kind: string, permissions: list<string>>
# operationId: storage.buckets.testIamPermissions
export def "storage-buckets-test-iam-permissions" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --permissions: list<string> # Permissions to test. (required)
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/iam/testPermissions"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: permissions, var: permissions, style: multi, required: true}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, permissions: $permissions, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locks retention policy on a bucket.
#
# POST /b/{bucket}/lockRetentionPolicy
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, id: string, kind: string, projectTeam: record, role: string, selfLink: string>, autoclass: record<enabled: bool, toggleTime: string>, billing: record<requesterPays: bool>, cors: table<maxAgeSeconds: int, method: list, origin: list, responseHeader: list>, customPlacementConfig: record<dataLocations: list<string>>, defaultEventBasedHold: bool, defaultObjectAcl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, encryption: record<defaultKmsKeyName: string>, etag: string, iamConfiguration: record<bucketPolicyOnly: record<enabled: bool, lockedTime: string>, publicAccessPrevention: string, uniformBucketLevelAccess: record<enabled: bool, lockedTime: string>>, id: string, kind: string, labels: record, lifecycle: record<rule: list<record>>, location: string, locationType: string, logging: record<logBucket: string, logObjectPrefix: string>, metageneration: string, name: string, owner: record<entity: string, entityId: string>, projectNumber: string, retentionPolicy: record<effectiveTime: string, isLocked: bool, retentionPeriod: string>, rpo: string, satisfiesPZS: bool, selfLink: string, storageClass: string, timeCreated: string, updated: string, versioning: record<enabled: bool>, website: record<mainPageSuffix: string, notFoundPage: string>>
# operationId: storage.buckets.lockRetentionPolicy
export def "storage-buckets-lock-retention-policy" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --if-metageneration-match: string # Makes the operation conditional on whether bucket's current metageneration matches the given value. (required)
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/b/{bucket}/lockRetentionPolicy"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: ifMetagenerationMatch, var: if_metageneration_match, required: true}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, if_metageneration_match: $if_metageneration_match, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of notification subscriptions for a given bucket.
#
# GET /b/{bucket}/notificationConfigs
# Returns: record<items: table<custom_attributes: record, etag: string, event_types: list, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string>, kind: string>
# operationId: storage.notifications.list
export def "storage-notifications-list" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/notificationConfigs"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a notification subscription for a given bucket.
#
# POST /b/{bucket}/notificationConfigs
# Returns: record<custom_attributes: record, etag: string, event_types: list<string>, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string>
# operationId: storage.notifications.insert
export def "storage-notifications-insert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --custom-attributes: record # An optional list of additional attributes to attach to each Cloud PubSub message published for this notification subscription.
  --etag: string # HTTP 1.1 Entity tag for this subscription notification.
  --event-types: list<string> # If present, only send notifications about listed event types. If empty, sent notifications for all event types.
  --id: string # The ID of the notification.
  --kind: string # The kind of item this is. For notifications, this is always storage#notification. (default: storage#notification)
  --object-name-prefix: string # If present, only apply this notification configuration to object names that begin with this prefix.
  --payload-format: string # The desired content of the Payload. (default: JSON_API_V1)
  --self-link: string # The canonical URL of this notification.
  --topic: string # The Cloud PubSub topic to which this subscription publishes. Formatted as: '//pubsub.googleapis.com/projects/{project-identifier}/topics/{my-topic}'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{bucket}/notificationConfigs"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_attributes, var: custom_attributes}, {name: etag, var: etag}, {name: event_types, var: event_types}, {name: id, var: id}, {name: kind, var: kind}, {name: object_name_prefix, var: object_name_prefix}, {name: payload_format, var: payload_format}, {name: selfLink, var: self_link}, {name: topic, var: topic}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, custom_attributes: $custom_attributes, etag: $etag, event_types: $event_types, id: $id, kind: $kind, object_name_prefix: $object_name_prefix, payload_format: $payload_format, self_link: $self_link, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes a notification subscription.
#
# DELETE /b/{bucket}/notificationConfigs/{notification}
# operationId: storage.notifications.delete
export def "storage-notifications-delete" [
  bucket: string
  notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  http-request {
    method: delete
    path: "/b/{bucket}/notificationConfigs/{notification}"
    path_params: [{name: bucket, var: bucket}, {name: notification, var: notification}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, notification: $notification, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a notification configuration.
#
# GET /b/{bucket}/notificationConfigs/{notification}
# Returns: record<custom_attributes: record, etag: string, event_types: list<string>, id: string, kind: string, object_name_prefix: string, payload_format: string, selfLink: string, topic: string>
# operationId: storage.notifications.get
export def "storage-notifications-get" [
  bucket: string
  notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/notificationConfigs/{notification}"
    path_params: [{name: bucket, var: bucket}, {name: notification, var: notification}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, notification: $notification, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of objects matching the criteria.
#
# GET /b/{bucket}/o
# Returns: record<items: table<acl: list, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>, kind: string, nextPageToken: string, prefixes: list<string>>
# operationId: storage.objects.list
export def "storage-objects-list" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --delimiter: string # Returns results in a directory-like mode. items will contain only objects whose names, aside from the prefix, do not contain delimiter. Objects whose names, aside from the prefix, contain delimiter will have their name, truncated after the delimiter, returned in prefixes. Duplicate prefixes are omitted.
  --end-offset: string # Filter results to objects whose names are lexicographically before endOffset. If startOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --include-trailing-delimiter: oneof<nothing, bool> # If true, objects that end in exactly one instance of delimiter will have their metadata included in items in addition to prefixes.
  --match-glob: string # Filter results to objects and prefixes that match this glob pattern.
  --max-results: int # Maximum number of items plus prefixes to return in a single page of responses. As duplicate prefixes are omitted, fewer total results may be returned than requested. The service will use this parameter or 1,000 items, whichever is smaller.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --prefix: string # Filter results to objects whose names begin with this prefix.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --start-offset: string # Filter results to objects whose names are lexicographically equal to or after startOffset. If endOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --versions: oneof<nothing, bool> # If true, lists all versions of an object as distinct results. The default is false. For more information, see Object Versioning.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/o"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: delimiter, var: delimiter}, {name: endOffset, var: end_offset}, {name: includeTrailingDelimiter, var: include_trailing_delimiter}, {name: matchGlob, var: match_glob}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: prefix, var: prefix}, {name: projection, var: projection}, {name: startOffset, var: start_offset}, {name: userProject, var: user_project}, {name: versions, var: versions}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, delimiter: $delimiter, end_offset: $end_offset, include_trailing_delimiter: $include_trailing_delimiter, match_glob: $match_glob, max_results: $max_results, page_token: $page_token, prefix: $prefix, projection: $projection, start_offset: $start_offset, user_project: $user_project, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stores a new object and metadata.
#
# POST /b/{bucket}/o
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>
# operationId: storage.objects.insert
export def "storage-objects-insert" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --content-encoding: string # If set, sets the contentEncoding property of the final object to this value. Setting this parameter is equivalent to setting the contentEncoding metadata property. This can be useful when uploading an object with uploadType=media to indicate the encoding of the content being uploaded.
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --name: string # Name of the object. Required when the object metadata is not otherwise provided. Overrides the object metadata's name value, if any. For information about how to URL encode object names to be path safe, see Encoding URI Path Parts.
  --predefined-acl: string@predefined-acl-completer-1 # Apply a predefined set of access controls to this object.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the object resource specifies the acl property, when it defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{bucket}/o"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: contentEncoding, var: content_encoding}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifGenerationNotMatch, var: if_generation_not_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: kmsKeyName, var: kms_key_name}, {name: name, var: name}, {name: predefinedAcl, var: predefined_acl}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, content_encoding: $content_encoding, if_generation_match: $if_generation_match, if_generation_not_match: $if_generation_not_match, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, kms_key_name: $kms_key_name, name: $name, predefined_acl: $predefined_acl, projection: $projection, user_project: $user_project, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watch for changes on all objects in a bucket.
#
# POST /b/{bucket}/o/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: storage.objects.watchAll
export def "storage-objects-watch-all" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --delimiter: string # Returns results in a directory-like mode. items will contain only objects whose names, aside from the prefix, do not contain delimiter. Objects whose names, aside from the prefix, contain delimiter will have their name, truncated after the delimiter, returned in prefixes. Duplicate prefixes are omitted.
  --end-offset: string # Filter results to objects whose names are lexicographically before endOffset. If startOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --include-trailing-delimiter: oneof<nothing, bool> # If true, objects that end in exactly one instance of delimiter will have their metadata included in items in addition to prefixes.
  --max-results: int # Maximum number of items plus prefixes to return in a single page of responses. As duplicate prefixes are omitted, fewer total results may be returned than requested. The service will use this parameter or 1,000 items, whichever is smaller.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --prefix: string # Filter results to objects whose names begin with this prefix.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --start-offset: string # Filter results to objects whose names are lexicographically equal to or after startOffset. If endOffset is also set, the objects listed will have names between startOffset (inclusive) and endOffset (exclusive).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --versions: oneof<nothing, bool> # If true, lists all versions of an object as distinct results. The default is false. For more information, see Object Versioning.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{bucket}/o/watch"
    path_params: [{name: bucket, var: bucket}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: delimiter, var: delimiter}, {name: endOffset, var: end_offset}, {name: includeTrailingDelimiter, var: include_trailing_delimiter}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: prefix, var: prefix}, {name: projection, var: projection}, {name: startOffset, var: start_offset}, {name: userProject, var: user_project}, {name: versions, var: versions}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, delimiter: $delimiter, end_offset: $end_offset, include_trailing_delimiter: $include_trailing_delimiter, max_results: $max_results, page_token: $page_token, prefix: $prefix, projection: $projection, start_offset: $start_offset, user_project: $user_project, versions: $versions, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an object and its metadata. Deletions are permanent if versioning is not enabled for the bucket, or if the generation parameter is used.
#
# DELETE /b/{bucket}/o/{object}
# operationId: storage.objects.delete
export def "storage-objects-delete" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, permanently deletes a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  http-request {
    method: delete
    path: "/b/{bucket}/o/{object}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifGenerationNotMatch, var: if_generation_not_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, if_generation_match: $if_generation_match, if_generation_not_match: $if_generation_not_match, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an object or its metadata.
#
# GET /b/{bucket}/o/{object}
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>
# operationId: storage.objects.get
export def "storage-objects-get" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/o/{object}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifGenerationNotMatch, var: if_generation_not_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, if_generation_match: $if_generation_match, if_generation_not_match: $if_generation_not_match, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, projection: $projection, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches an object's metadata.
#
# PATCH /b/{bucket}/o/{object}
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>
# operationId: storage.objects.patch
export def "storage-objects-patch" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer-1 # Apply a predefined set of access controls to this object.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request, for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --body-bucket: string # The name of the bucket containing this object. (spec name: bucket)
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --body-generation: string # The content generation of this object. Used for object versioning. (format: int64) (spec name: generation)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/b/{bucket}/o/{object}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifGenerationNotMatch, var: if_generation_not_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: predefinedAcl, var: predefined_acl}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: bucket, var: body_bucket}, {name: cacheControl, var: cache_control}, {name: componentCount, var: component_count}, {name: contentDisposition, var: content_disposition}, {name: contentEncoding, var: content_encoding}, {name: contentLanguage, var: content_language}, {name: contentType, var: content_type}, {name: crc32c, var: crc32c}, {name: customTime, var: custom_time}, {name: customerEncryption, var: customer_encryption}, {name: etag, var: etag}, {name: eventBasedHold, var: event_based_hold}, {name: generation, var: body_generation}, {name: id, var: id}, {name: kind, var: kind}, {name: kmsKeyName, var: kms_key_name}, {name: md5Hash, var: md5_hash}, {name: mediaLink, var: media_link}, {name: metadata, var: metadata}, {name: metageneration, var: metageneration}, {name: name, var: name}, {name: owner, var: owner}, {name: retentionExpirationTime, var: retention_expiration_time}, {name: selfLink, var: self_link}, {name: size, var: size}, {name: storageClass, var: storage_class}, {name: temporaryHold, var: temporary_hold}, {name: timeCreated, var: time_created}, {name: timeDeleted, var: time_deleted}, {name: timeStorageClassUpdated, var: time_storage_class_updated}, {name: updated, var: updated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, if_generation_match: $if_generation_match, if_generation_not_match: $if_generation_not_match, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, predefined_acl: $predefined_acl, projection: $projection, user_project: $user_project, acl: $acl, body_bucket: $body_bucket, cache_control: $cache_control, component_count: $component_count, content_disposition: $content_disposition, content_encoding: $content_encoding, content_language: $content_language, content_type: $content_type, crc32c: $crc32c, custom_time: $custom_time, customer_encryption: $customer_encryption, etag: $etag, event_based_hold: $event_based_hold, body_generation: $body_generation, id: $id, kind: $kind, kms_key_name: $kms_key_name, md5_hash: $md5_hash, media_link: $media_link, metadata: $metadata, metageneration: $metageneration, name: $name, owner: $owner, retention_expiration_time: $retention_expiration_time, self_link: $self_link, size: $size, storage_class: $storage_class, temporary_hold: $temporary_hold, time_created: $time_created, time_deleted: $time_deleted, time_storage_class_updated: $time_storage_class_updated, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an object's metadata.
#
# PUT /b/{bucket}/o/{object}
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>
# operationId: storage.objects.update
export def "storage-objects-update" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the object's current metageneration does not match the given value.
  --predefined-acl: string@predefined-acl-completer-1 # Apply a predefined set of access controls to this object.
  --projection: string@projection-completer # Set of properties to return. Defaults to full.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --body-bucket: string # The name of the bucket containing this object. (spec name: bucket)
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --body-generation: string # The content generation of this object. Used for object versioning. (format: int64) (spec name: generation)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/b/{bucket}/o/{object}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifGenerationNotMatch, var: if_generation_not_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: predefinedAcl, var: predefined_acl}, {name: projection, var: projection}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: bucket, var: body_bucket}, {name: cacheControl, var: cache_control}, {name: componentCount, var: component_count}, {name: contentDisposition, var: content_disposition}, {name: contentEncoding, var: content_encoding}, {name: contentLanguage, var: content_language}, {name: contentType, var: content_type}, {name: crc32c, var: crc32c}, {name: customTime, var: custom_time}, {name: customerEncryption, var: customer_encryption}, {name: etag, var: etag}, {name: eventBasedHold, var: event_based_hold}, {name: generation, var: body_generation}, {name: id, var: id}, {name: kind, var: kind}, {name: kmsKeyName, var: kms_key_name}, {name: md5Hash, var: md5_hash}, {name: mediaLink, var: media_link}, {name: metadata, var: metadata}, {name: metageneration, var: metageneration}, {name: name, var: name}, {name: owner, var: owner}, {name: retentionExpirationTime, var: retention_expiration_time}, {name: selfLink, var: self_link}, {name: size, var: size}, {name: storageClass, var: storage_class}, {name: temporaryHold, var: temporary_hold}, {name: timeCreated, var: time_created}, {name: timeDeleted, var: time_deleted}, {name: timeStorageClassUpdated, var: time_storage_class_updated}, {name: updated, var: updated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, if_generation_match: $if_generation_match, if_generation_not_match: $if_generation_not_match, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, predefined_acl: $predefined_acl, projection: $projection, user_project: $user_project, acl: $acl, body_bucket: $body_bucket, cache_control: $cache_control, component_count: $component_count, content_disposition: $content_disposition, content_encoding: $content_encoding, content_language: $content_language, content_type: $content_type, crc32c: $crc32c, custom_time: $custom_time, customer_encryption: $customer_encryption, etag: $etag, event_based_hold: $event_based_hold, body_generation: $body_generation, id: $id, kind: $kind, kms_key_name: $kms_key_name, md5_hash: $md5_hash, media_link: $media_link, metadata: $metadata, metageneration: $metageneration, name: $name, owner: $owner, retention_expiration_time: $retention_expiration_time, self_link: $self_link, size: $size, storage_class: $storage_class, temporary_hold: $temporary_hold, time_created: $time_created, time_deleted: $time_deleted, time_storage_class_updated: $time_storage_class_updated, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves ACL entries on the specified object.
#
# GET /b/{bucket}/o/{object}/acl
# Returns: record<items: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, kind: string>
# operationId: storage.objectAccessControls.list
export def "storage-object-access-controls-list" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/o/{object}/acl"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ACL entry on the specified object.
#
# POST /b/{bucket}/o/{object}/acl
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.objectAccessControls.insert
export def "storage-object-access-controls-insert" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com.
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --body-generation: string # The content generation of the object, if applied to an object. (format: int64) (spec name: generation)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --body-object: string # The name of the object, if applied to an object. (spec name: object)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{bucket}/o/{object}/acl"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: generation, var: body_generation}, {name: id, var: id}, {name: kind, var: kind}, {name: object, var: body_object}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, entity: $entity, entity_id: $entity_id, etag: $etag, body_generation: $body_generation, id: $id, kind: $kind, body_object: $body_object, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the ACL entry for the specified entity on the specified object.
#
# DELETE /b/{bucket}/o/{object}/acl/{entity}
# operationId: storage.objectAccessControls.delete
export def "storage-object-access-controls-delete" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> any {
  http-request {
    method: delete
    path: "/b/{bucket}/o/{object}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the ACL entry for the specified entity on the specified object.
#
# GET /b/{bucket}/o/{object}/acl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.objectAccessControls.get
export def "storage-object-access-controls-get" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/o/{object}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches an ACL entry on the specified object.
#
# PATCH /b/{bucket}/o/{object}/acl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.objectAccessControls.patch
export def "storage-object-access-controls-patch" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com. (spec name: entity)
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --body-generation: string # The content generation of the object, if applied to an object. (format: int64) (spec name: generation)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --body-object: string # The name of the object, if applied to an object. (spec name: object)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/b/{bucket}/o/{object}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: body_entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: generation, var: body_generation}, {name: id, var: id}, {name: kind, var: kind}, {name: object, var: body_object}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, body_entity: $body_entity, entity_id: $entity_id, etag: $etag, body_generation: $body_generation, id: $id, kind: $kind, body_object: $body_object, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an ACL entry on the specified object.
#
# PUT /b/{bucket}/o/{object}/acl/{entity}
# Returns: record<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record<projectNumber: string, team: string>, role: string, selfLink: string>
# operationId: storage.objectAccessControls.update
export def "storage-object-access-controls-update" [
  bucket: string
  object: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --body-bucket: string # The name of the bucket. (spec name: bucket)
  --domain: string # The domain associated with the entity, if any.
  --email: string # The email address associated with the entity, if any.
  --body-entity: string # The entity holding the permission, in one of the following forms: - user-userId - user-email - group-groupId - group-email - domain-domain - project-team-projectId - allUsers - allAuthenticatedUsers Examples: - The user liz@example.com would be user-liz@example.com. - The group example@googlegroups.com would be group-example@googlegroups.com. - To refer to all members of the Google Apps for Business domain example.com, the entity would be domain-example.com. (spec name: entity)
  --entity-id: string # The ID for the entity, if any.
  --etag: string # HTTP 1.1 Entity tag for the access-control entry.
  --body-generation: string # The content generation of the object, if applied to an object. (format: int64) (spec name: generation)
  --id: string # The ID of the access-control entry.
  --kind: string # The kind of item this is. For object access control entries, this is always storage#objectAccessControl. (default: storage#objectAccessControl)
  --body-object: string # The name of the object, if applied to an object. (spec name: object)
  --project-team: record # The project team associated with the entity, if any. — shape: {projectNumber?: string, team?: string}
  --role: string # The access permission for the entity.
  --self-link: string # The link to this access-control entry.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/b/{bucket}/o/{object}/acl/{entity}"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}, {name: entity, var: entity}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucket, var: body_bucket}, {name: domain, var: domain}, {name: email, var: email}, {name: entity, var: body_entity}, {name: entityId, var: entity_id}, {name: etag, var: etag}, {name: generation, var: body_generation}, {name: id, var: id}, {name: kind, var: kind}, {name: object, var: body_object}, {name: projectTeam, var: project_team}, {name: role, var: role}, {name: selfLink, var: self_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, entity: $entity, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project, body_bucket: $body_bucket, domain: $domain, email: $email, body_entity: $body_entity, entity_id: $entity_id, etag: $etag, body_generation: $body_generation, id: $id, kind: $kind, body_object: $body_object, project_team: $project_team, role: $role, self_link: $self_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an IAM policy for the specified object.
#
# GET /b/{bucket}/o/{object}/iam
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>
# operationId: storage.objects.getIamPolicy
export def "storage-objects-get-iam-policy" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/o/{object}/iam"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an IAM policy for the specified object.
#
# PUT /b/{bucket}/o/{object}/iam
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, kind: string, resourceId: string, version: int>
# operationId: storage.objects.setIamPolicy
export def "storage-objects-set-iam-policy" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --bindings: list # An association between a role, which comes with a set of permissions, and members who may assume that role. — item shape: {condition?: record, members?: list<string>, role?: string}
  --etag: string # HTTP 1.1 Entity tag for the policy. (format: byte)
  --kind: string # The kind of item this is. For policies, this is always storage#policy. This field is ignored on input. (default: storage#policy)
  --resource-id: string # The ID of the resource to which this policy belongs. Will be of the form projects/_/buckets/bucket for buckets, and projects/_/buckets/bucket/objects/object for objects. A specific generation may be specified by appending #generationNumber to the end of the object name, e.g. projects/_/buckets/my-bucket/objects/data.txt#17. The current generation can be denoted with #0. This field is ignored on input.
  --version: int # The IAM policy format version. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/b/{bucket}/o/{object}/iam"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: bindings, var: bindings}, {name: etag, var: etag}, {name: kind, var: kind}, {name: resourceId, var: resource_id}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, generation: $generation, user_project: $user_project, bindings: $bindings, etag: $etag, kind: $kind, resource_id: $resource_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests a set of permissions on the given object to see which, if any, are held by the caller.
#
# GET /b/{bucket}/o/{object}/iam/testPermissions
# Returns: record<kind: string, permissions: list<string>>
# operationId: storage.objects.testIamPermissions
export def "storage-objects-test-iam-permissions" [
  bucket: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --permissions: list<string> # Permissions to test. (required)
  --generation: string # If present, selects a specific revision of this object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/b/{bucket}/o/{object}/iam/testPermissions"
    path_params: [{name: bucket, var: bucket}, {name: object, var: object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: permissions, var: permissions, style: multi, required: true}, {name: generation, var: generation}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, object: $object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, permissions: $permissions, generation: $generation, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Concatenates a list of existing objects into a new object in the same bucket.
#
# POST /b/{destinationBucket}/o/{destinationObject}/compose
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>
# operationId: storage.objects.compose
export def "storage-objects-compose" [
  destination_bucket: string
  destination_object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --destination-predefined-acl: string@destination-predefined-acl-completer # Apply a predefined set of access controls to the destination object.
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the object's current metageneration matches the given value.
  --kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --destination: record # An object. — shape: {acl?: list, bucket?: string, cacheControl?: string, componentCount?: int, contentDisposition?: string, contentEncoding?: string, contentLanguage?: string, contentType?: string, crc32c?: string, customTime?: string, customerEncryption?: record, etag?: string, eventBasedHold?: bool, generation?: string, id?: string, kind?: string, kmsKeyName?: string, md5Hash?: string, mediaLink?: string, metadata?: record, metageneration?: string, name?: string, owner?: record, retentionExpirationTime?: string, ... (8 more fields)}
  --kind: string # The kind of item this is. (default: storage#composeRequest)
  --source-objects: list # The list of source objects that will be concatenated into a single object. — item shape: {generation?: string, name?: string, objectPreconditions?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{destinationBucket}/o/{destinationObject}/compose"
    path_params: [{name: destinationBucket, var: destination_bucket}, {name: destinationObject, var: destination_object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: destinationPredefinedAcl, var: destination_predefined_acl}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: kmsKeyName, var: kms_key_name}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: destination, var: destination}, {name: kind, var: kind}, {name: sourceObjects, var: source_objects}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_bucket: $destination_bucket, destination_object: $destination_object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, destination_predefined_acl: $destination_predefined_acl, if_generation_match: $if_generation_match, if_metageneration_match: $if_metageneration_match, kms_key_name: $kms_key_name, user_project: $user_project, destination: $destination, kind: $kind, source_objects: $source_objects
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies a source object to a destination object. Optionally overrides metadata.
#
# POST /b/{sourceBucket}/o/{sourceObject}/copyTo/b/{destinationBucket}/o/{destinationObject}
# Returns: record<acl: table<bucket: string, domain: string, email: string, entity: string, entityId: string, etag: string, generation: string, id: string, kind: string, object: string, projectTeam: record, role: string, selfLink: string>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>
# operationId: storage.objects.copy
export def "storage-objects-copy" [
  source_bucket: string
  source_object: string
  destination_bucket: string
  destination_object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --destination-kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --destination-predefined-acl: string@destination-predefined-acl-completer # Apply a predefined set of access controls to the destination object.
  --if-generation-match: string # Makes the operation conditional on whether the destination object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the destination object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the destination object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the destination object's current metageneration does not match the given value.
  --if-source-generation-match: string # Makes the operation conditional on whether the source object's current generation matches the given value.
  --if-source-generation-not-match: string # Makes the operation conditional on whether the source object's current generation does not match the given value.
  --if-source-metageneration-match: string # Makes the operation conditional on whether the source object's current metageneration matches the given value.
  --if-source-metageneration-not-match: string # Makes the operation conditional on whether the source object's current metageneration does not match the given value.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the object resource specifies the acl property, when it defaults to full.
  --source-generation: string # If present, selects a specific revision of the source object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --bucket: string # The name of the bucket containing this object.
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --generation: string # The content generation of this object. Used for object versioning. (format: int64)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{sourceBucket}/o/{sourceObject}/copyTo/b/{destinationBucket}/o/{destinationObject}"
    path_params: [{name: sourceBucket, var: source_bucket}, {name: sourceObject, var: source_object}, {name: destinationBucket, var: destination_bucket}, {name: destinationObject, var: destination_object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: destinationKmsKeyName, var: destination_kms_key_name}, {name: destinationPredefinedAcl, var: destination_predefined_acl}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifGenerationNotMatch, var: if_generation_not_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: ifSourceGenerationMatch, var: if_source_generation_match}, {name: ifSourceGenerationNotMatch, var: if_source_generation_not_match}, {name: ifSourceMetagenerationMatch, var: if_source_metageneration_match}, {name: ifSourceMetagenerationNotMatch, var: if_source_metageneration_not_match}, {name: projection, var: projection}, {name: sourceGeneration, var: source_generation}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: bucket, var: bucket}, {name: cacheControl, var: cache_control}, {name: componentCount, var: component_count}, {name: contentDisposition, var: content_disposition}, {name: contentEncoding, var: content_encoding}, {name: contentLanguage, var: content_language}, {name: contentType, var: content_type}, {name: crc32c, var: crc32c}, {name: customTime, var: custom_time}, {name: customerEncryption, var: customer_encryption}, {name: etag, var: etag}, {name: eventBasedHold, var: event_based_hold}, {name: generation, var: generation}, {name: id, var: id}, {name: kind, var: kind}, {name: kmsKeyName, var: kms_key_name}, {name: md5Hash, var: md5_hash}, {name: mediaLink, var: media_link}, {name: metadata, var: metadata}, {name: metageneration, var: metageneration}, {name: name, var: name}, {name: owner, var: owner}, {name: retentionExpirationTime, var: retention_expiration_time}, {name: selfLink, var: self_link}, {name: size, var: size}, {name: storageClass, var: storage_class}, {name: temporaryHold, var: temporary_hold}, {name: timeCreated, var: time_created}, {name: timeDeleted, var: time_deleted}, {name: timeStorageClassUpdated, var: time_storage_class_updated}, {name: updated, var: updated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_bucket: $source_bucket, source_object: $source_object, destination_bucket: $destination_bucket, destination_object: $destination_object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, destination_kms_key_name: $destination_kms_key_name, destination_predefined_acl: $destination_predefined_acl, if_generation_match: $if_generation_match, if_generation_not_match: $if_generation_not_match, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, if_source_generation_match: $if_source_generation_match, if_source_generation_not_match: $if_source_generation_not_match, if_source_metageneration_match: $if_source_metageneration_match, if_source_metageneration_not_match: $if_source_metageneration_not_match, projection: $projection, source_generation: $source_generation, user_project: $user_project, acl: $acl, bucket: $bucket, cache_control: $cache_control, component_count: $component_count, content_disposition: $content_disposition, content_encoding: $content_encoding, content_language: $content_language, content_type: $content_type, crc32c: $crc32c, custom_time: $custom_time, customer_encryption: $customer_encryption, etag: $etag, event_based_hold: $event_based_hold, generation: $generation, id: $id, kind: $kind, kms_key_name: $kms_key_name, md5_hash: $md5_hash, media_link: $media_link, metadata: $metadata, metageneration: $metageneration, name: $name, owner: $owner, retention_expiration_time: $retention_expiration_time, self_link: $self_link, size: $size, storage_class: $storage_class, temporary_hold: $temporary_hold, time_created: $time_created, time_deleted: $time_deleted, time_storage_class_updated: $time_storage_class_updated, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rewrites a source object to a destination object. Optionally overrides metadata.
#
# POST /b/{sourceBucket}/o/{sourceObject}/rewriteTo/b/{destinationBucket}/o/{destinationObject}
# Returns: record<done: bool, kind: string, objectSize: string, resource: record<acl: list<record>, bucket: string, cacheControl: string, componentCount: int, contentDisposition: string, contentEncoding: string, contentLanguage: string, contentType: string, crc32c: string, customTime: string, customerEncryption: record<encryptionAlgorithm: string, keySha256: string>, etag: string, eventBasedHold: bool, generation: string, id: string, kind: string, kmsKeyName: string, md5Hash: string, mediaLink: string, metadata: record, metageneration: string, name: string, owner: record<entity: string, entityId: string>, retentionExpirationTime: string, selfLink: string, size: string, storageClass: string, temporaryHold: bool, timeCreated: string, timeDeleted: string, timeStorageClassUpdated: string, updated: string>, rewriteToken: string, totalBytesRewritten: string>
# operationId: storage.objects.rewrite
export def "storage-objects-rewrite" [
  source_bucket: string
  source_object: string
  destination_bucket: string
  destination_object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --destination-kms-key-name: string # Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
  --destination-predefined-acl: string@destination-predefined-acl-completer # Apply a predefined set of access controls to the destination object.
  --if-generation-match: string # Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
  --if-generation-not-match: string # Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
  --if-metageneration-match: string # Makes the operation conditional on whether the destination object's current metageneration matches the given value.
  --if-metageneration-not-match: string # Makes the operation conditional on whether the destination object's current metageneration does not match the given value.
  --if-source-generation-match: string # Makes the operation conditional on whether the source object's current generation matches the given value.
  --if-source-generation-not-match: string # Makes the operation conditional on whether the source object's current generation does not match the given value.
  --if-source-metageneration-match: string # Makes the operation conditional on whether the source object's current metageneration matches the given value.
  --if-source-metageneration-not-match: string # Makes the operation conditional on whether the source object's current metageneration does not match the given value.
  --max-bytes-rewritten-per-call: string # The maximum number of bytes that will be rewritten per rewrite request. Most callers shouldn't need to specify this parameter - it is primarily in place to support testing. If specified the value must be an integral multiple of 1 MiB (1048576). Also, this only applies to requests where the source and destination span locations and/or storage classes. Finally, this value must not change across rewrite calls else you'll get an error that the rewriteToken is invalid.
  --projection: string@projection-completer # Set of properties to return. Defaults to noAcl, unless the object resource specifies the acl property, when it defaults to full.
  --rewrite-token: string # Include this field (from the previous rewrite response) on each rewrite request after the first one, until the rewrite response 'done' flag is true. Calls that provide a rewriteToken can omit all other request fields, but if included those fields must match the values provided in the first rewrite request.
  --source-generation: string # If present, selects a specific revision of the source object (as opposed to the latest version, the default).
  --user-project: string # The project to be billed for this request. Required for Requester Pays buckets.
  --acl: list # Access controls on the object. — item shape: {bucket?: string, domain?: string, email?: string, entity?: string, entityId?: string, etag?: string, generation?: string, id?: string, kind?: string, object?: string, projectTeam?: record, role?: string, selfLink?: string}
  --bucket: string # The name of the bucket containing this object.
  --cache-control: string # Cache-Control directive for the object data. If omitted, and the object is accessible to all anonymous users, the default will be public, max-age=3600.
  --component-count: int # Number of underlying components that make up this object. Components are accumulated by compose operations. (format: int32)
  --content-disposition: string # Content-Disposition of the object data.
  --content-encoding: string # Content-Encoding of the object data.
  --content-language: string # Content-Language of the object data.
  --content-type: string # Content-Type of the object data. If an object is stored without a Content-Type, it is served as application/octet-stream.
  --crc32c: string # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in big-endian byte order. For more information about using the CRC32c checksum, see Hashes and ETags: Best Practices.
  --custom-time: string # A timestamp in RFC 3339 format specified by the user for an object. (format: date-time)
  --customer-encryption: record # Metadata of customer-supplied encryption key, if the object is encrypted by such a key. — shape: {encryptionAlgorithm?: string, keySha256?: string}
  --etag: string # HTTP 1.1 Entity tag for the object.
  --event-based-hold: oneof<nothing, bool> # Whether an object is under event-based hold. Event-based hold is a way to retain objects until an event occurs, which is signified by the hold's release (i.e. this value is set to false). After being released (set to false), such objects will be subject to bucket-level retention (if any). One sample use case of this flag is for banks to hold loan documents for at least 3 years after loan is paid in full. Here, bucket-level retention is 3 years and the event is the loan being paid in full. In this example, these objects will be held intact for any number of years until the event has occurred (event-based hold on the object is released) and then 3 more years after that. That means retention duration of the objects begins from the moment event-based hold transitioned from true to false.
  --generation: string # The content generation of this object. Used for object versioning. (format: int64)
  --id: string # The ID of the object, including the bucket name, object name, and generation number.
  --kind: string # The kind of item this is. For objects, this is always storage#object. (default: storage#object)
  --kms-key-name: string # Not currently supported. Specifying the parameter causes the request to fail with status code 400 - Bad Request.
  --md5-hash: string # MD5 hash of the data; encoded using base64. For more information about using the MD5 hash, see Hashes and ETags: Best Practices.
  --media-link: string # Media download link.
  --metadata: record # User-provided metadata, in key/value pairs.
  --metageneration: string # The version of the metadata for this object at this generation. Used for preconditions and for detecting changes in metadata. A metageneration number is only meaningful in the context of a particular generation of a particular object. (format: int64)
  --name: string # The name of the object. Required if not specified by URL parameter.
  --owner: record # The owner of the object. This will always be the uploader of the object. — shape: {entity?: string, entityId?: string}
  --retention-expiration-time: string # A server-determined value that specifies the earliest time that the object's retention period expires. This value is in RFC 3339 format. Note 1: This field is not provided for objects with an active event-based hold, since retention expiration is unknown until the hold is removed. Note 2: This value can be provided even when temporary hold is set (so that the user can reason about policy without having to first unset the temporary hold). (format: date-time)
  --self-link: string # The link to this object.
  --size: string # Content-Length of the data in bytes. (format: uint64)
  --storage-class: string # Storage class of the object.
  --temporary-hold: oneof<nothing, bool> # Whether an object is under temporary hold. While this flag is set to true, the object is protected against deletion and overwrites. A common use case of this flag is regulatory investigations where objects need to be retained while the investigation is ongoing. Note that unlike event-based hold, temporary hold does not impact retention expiration time of an object.
  --time-created: string # The creation time of the object in RFC 3339 format. (format: date-time)
  --time-deleted: string # The deletion time of the object in RFC 3339 format. Will be returned if and only if this version of the object has been deleted. (format: date-time)
  --time-storage-class-updated: string # The time at which the object's storage class was last changed. When the object is initially created, it will be set to timeCreated. (format: date-time)
  --updated: string # The modification time of the object metadata in RFC 3339 format. Set initially to object creation time and then updated whenever any metadata of the object changes. This includes changes made by a requester, such as modifying custom metadata, as well as changes made by Cloud Storage on behalf of a requester, such as changing the storage class based on an Object Lifecycle Configuration. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/b/{sourceBucket}/o/{sourceObject}/rewriteTo/b/{destinationBucket}/o/{destinationObject}"
    path_params: [{name: sourceBucket, var: source_bucket}, {name: sourceObject, var: source_object}, {name: destinationBucket, var: destination_bucket}, {name: destinationObject, var: destination_object}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: destinationKmsKeyName, var: destination_kms_key_name}, {name: destinationPredefinedAcl, var: destination_predefined_acl}, {name: ifGenerationMatch, var: if_generation_match}, {name: ifGenerationNotMatch, var: if_generation_not_match}, {name: ifMetagenerationMatch, var: if_metageneration_match}, {name: ifMetagenerationNotMatch, var: if_metageneration_not_match}, {name: ifSourceGenerationMatch, var: if_source_generation_match}, {name: ifSourceGenerationNotMatch, var: if_source_generation_not_match}, {name: ifSourceMetagenerationMatch, var: if_source_metageneration_match}, {name: ifSourceMetagenerationNotMatch, var: if_source_metageneration_not_match}, {name: maxBytesRewrittenPerCall, var: max_bytes_rewritten_per_call}, {name: projection, var: projection}, {name: rewriteToken, var: rewrite_token}, {name: sourceGeneration, var: source_generation}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: bucket, var: bucket}, {name: cacheControl, var: cache_control}, {name: componentCount, var: component_count}, {name: contentDisposition, var: content_disposition}, {name: contentEncoding, var: content_encoding}, {name: contentLanguage, var: content_language}, {name: contentType, var: content_type}, {name: crc32c, var: crc32c}, {name: customTime, var: custom_time}, {name: customerEncryption, var: customer_encryption}, {name: etag, var: etag}, {name: eventBasedHold, var: event_based_hold}, {name: generation, var: generation}, {name: id, var: id}, {name: kind, var: kind}, {name: kmsKeyName, var: kms_key_name}, {name: md5Hash, var: md5_hash}, {name: mediaLink, var: media_link}, {name: metadata, var: metadata}, {name: metageneration, var: metageneration}, {name: name, var: name}, {name: owner, var: owner}, {name: retentionExpirationTime, var: retention_expiration_time}, {name: selfLink, var: self_link}, {name: size, var: size}, {name: storageClass, var: storage_class}, {name: temporaryHold, var: temporary_hold}, {name: timeCreated, var: time_created}, {name: timeDeleted, var: time_deleted}, {name: timeStorageClassUpdated, var: time_storage_class_updated}, {name: updated, var: updated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_bucket: $source_bucket, source_object: $source_object, destination_bucket: $destination_bucket, destination_object: $destination_object, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, destination_kms_key_name: $destination_kms_key_name, destination_predefined_acl: $destination_predefined_acl, if_generation_match: $if_generation_match, if_generation_not_match: $if_generation_not_match, if_metageneration_match: $if_metageneration_match, if_metageneration_not_match: $if_metageneration_not_match, if_source_generation_match: $if_source_generation_match, if_source_generation_not_match: $if_source_generation_not_match, if_source_metageneration_match: $if_source_metageneration_match, if_source_metageneration_not_match: $if_source_metageneration_not_match, max_bytes_rewritten_per_call: $max_bytes_rewritten_per_call, projection: $projection, rewrite_token: $rewrite_token, source_generation: $source_generation, user_project: $user_project, acl: $acl, bucket: $bucket, cache_control: $cache_control, component_count: $component_count, content_disposition: $content_disposition, content_encoding: $content_encoding, content_language: $content_language, content_type: $content_type, crc32c: $crc32c, custom_time: $custom_time, customer_encryption: $customer_encryption, etag: $etag, event_based_hold: $event_based_hold, generation: $generation, id: $id, kind: $kind, kms_key_name: $kms_key_name, md5_hash: $md5_hash, media_link: $media_link, metadata: $metadata, metageneration: $metageneration, name: $name, owner: $owner, retention_expiration_time: $retention_expiration_time, self_link: $self_link, size: $size, storage_class: $storage_class, temporary_hold: $temporary_hold, time_created: $time_created, time_deleted: $time_deleted, time_storage_class_updated: $time_storage_class_updated, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop watching resources through this channel
#
# POST /channels/stop
# operationId: storage.channels.stop
export def "storage-channels-stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel.
]: any -> any {
  $in | http-request {
    method: post
    path: "/channels/stop"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of HMAC keys matching the criteria.
#
# GET /projects/{projectId}/hmacKeys
# Returns: record<items: table<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>, kind: string, nextPageToken: string>
# operationId: storage.projects.hmacKeys.list
export def "storage-projects-hmac-keys-list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of items to return in a single page of responses. The service uses this parameter or 250 items, whichever is smaller. The max number of items per page will also be limited by the number of distinct service accounts in the response. If the number of service accounts in a single response is too high, the page will truncated and a next page token will be returned.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
  --service-account-email: string # If present, only keys for the given service account are returned.
  --show-deleted-keys: oneof<nothing, bool> # Whether or not to show keys in the DELETED state.
  --user-project: string # The project to be billed for this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/hmacKeys"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: serviceAccountEmail, var: service_account_email}, {name: showDeletedKeys, var: show_deleted_keys}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, max_results: $max_results, page_token: $page_token, service_account_email: $service_account_email, show_deleted_keys: $show_deleted_keys, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new HMAC key for the specified service account.
#
# POST /projects/{projectId}/hmacKeys
# Returns: record<kind: string, metadata: record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>, secret: string>
# operationId: storage.projects.hmacKeys.create
export def "storage-projects-hmac-keys-create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --service-account-email: string # Email address of the service account. (required)
  --user-project: string # The project to be billed for this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectId}/hmacKeys"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: serviceAccountEmail, var: service_account_email, required: true}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, service_account_email: $service_account_email, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an HMAC key.
#
# DELETE /projects/{projectId}/hmacKeys/{accessId}
# operationId: storage.projects.hmacKeys.delete
export def "storage-projects-hmac-keys-delete" [
  project_id: string
  access_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/hmacKeys/{accessId}"
    path_params: [{name: projectId, var: project_id}, {name: accessId, var: access_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, access_id: $access_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an HMAC key's metadata
#
# GET /projects/{projectId}/hmacKeys/{accessId}
# Returns: record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>
# operationId: storage.projects.hmacKeys.get
export def "storage-projects-hmac-keys-get" [
  project_id: string
  access_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/hmacKeys/{accessId}"
    path_params: [{name: projectId, var: project_id}, {name: accessId, var: access_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, access_id: $access_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the state of an HMAC key. See the HMAC Key resource descriptor for valid states.
#
# PUT /projects/{projectId}/hmacKeys/{accessId}
# Returns: record<accessId: string, etag: string, id: string, kind: string, projectId: string, selfLink: string, serviceAccountEmail: string, state: string, timeCreated: string, updated: string>
# operationId: storage.projects.hmacKeys.update
export def "storage-projects-hmac-keys-update" [
  project_id: string
  access_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
  --body-access-id: string # The ID of the HMAC Key. (spec name: accessId)
  --etag: string # HTTP 1.1 Entity tag for the HMAC key.
  --id: string # The ID of the HMAC key, including the Project ID and the Access ID.
  --kind: string # The kind of item this is. For HMAC Key metadata, this is always storage#hmacKeyMetadata. (default: storage#hmacKeyMetadata)
  --body-project-id: string # Project ID owning the service account to which the key authenticates. (spec name: projectId)
  --self-link: string # The link to this resource.
  --service-account-email: string # The email address of the key's associated service account.
  --state: string # The state of the key. Can be one of ACTIVE, INACTIVE, or DELETED.
  --time-created: string # The creation time of the HMAC key in RFC 3339 format. (format: date-time)
  --updated: string # The last modification time of the HMAC key metadata in RFC 3339 format. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/hmacKeys/{accessId}"
    path_params: [{name: projectId, var: project_id}, {name: accessId, var: access_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessId, var: body_access_id}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: projectId, var: body_project_id}, {name: selfLink, var: self_link}, {name: serviceAccountEmail, var: service_account_email}, {name: state, var: state}, {name: timeCreated, var: time_created}, {name: updated, var: updated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, access_id: $access_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project, body_access_id: $body_access_id, etag: $etag, id: $id, kind: $kind, body_project_id: $body_project_id, self_link: $self_link, service_account_email: $service_account_email, state: $state, time_created: $time_created, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the email address of this project's Google Cloud Storage service account.
#
# GET /projects/{projectId}/serviceAccount
# Returns: record<email_address: string, kind: string>
# operationId: storage.projects.serviceAccount.get
export def "storage-projects-service-account-get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --upload-type: string # Upload protocol for media (e.g. "media", "multipart", "resumable").
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --user-project: string # The project to be billed for this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/serviceAccount"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: uploadType, var: upload_type}, {name: userIp, var: user_ip}, {name: userProject, var: user_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_type: $upload_type, user_ip: $user_ip, user_project: $user_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
