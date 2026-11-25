# Auto-generated client for Microcks API v1.7 v1.7.0
# Source: https://api.apis.guru/v2/specs/microcks.local/1.7.0/openapi.json
# Auth: --token flag or $env.MICROCKS_API_V1_7_TOKEN

const CLIENT = {
  base_url: "http://microcks.local"
  token_env_var: "MICROCKS_API_V1_7_TOKEN"
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

def base-url-completer [] { ["http://microcks.local" "http://microcks.example.com/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def runner-type-completer [] { ["ASYNC_API_SCHEMA" "GRAPHQL_SCHEMA" "GRPC_PROTOBUF" "HTTP" "OPEN_API_SCHEMA" "POSTMAN" "SOAP_HTTP" "SOAP_UI"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    upload-artifact: "string"
    export-snapshot: "binary"
    get-import-jobs: "table<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: list<record>>"
    create-import-job: "record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>"
    get-import-job-counter: "record<counter: int>"
    get-jobs-id: "record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>"
    post-jobs-id: "record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>"
    activate-import-job: "record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>"
    start-import-job: "record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>"
    stop-import-job: "record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>"
    get-keycloak-config: "record<auth-server-url: string, enabled: bool, public-client: string, realm: string, resource: string, ssl-required: any>"
    get-conformance-metrics-aggregation: "table<name: string, value: int, weight: int>"
    get-service-test-conformance-metric: "record<aggregationLabelValue: string, currentScore: float, id: string, lastUpdateDay: string, latestScores: record, latestTrend: string, maxPossibleScore: float, serviceId: string>"
    get-aggregated-invocations-stats: "record<dailyCount: float, day: string, hourlyCount: record, id: string, minuteCount: record, serviceName: string, serviceVersion: string>"
    get-latest-aggregated-invocations-stats: "record"
    get-top-ivnocations-stats-by-day: "table<dailyCount: float, day: string, hourlyCount: record, id: string, minuteCount: record, serviceName: string, serviceVersion: string>"
    get-invocation-stats-by-service: "record<dailyCount: float, day: string, hourlyCount: record, id: string, minuteCount: record, serviceName: string, serviceVersion: string>"
    get-latest-test-results: "table<id: string, serviceId: string, success: bool, testDate: int>"
    get-resources-by-service: "table<content: string, id: string, name: string, path: string, serviceId: string, sourceArtifact: string, type: string>"
    get-resource: "record<content: string, id: string, name: string, path: string, serviceId: string, sourceArtifact: string, type: string>"
    get-secrets: "table<caCertPem: string, description: string, id: string, name: string, password: string, token: string, tokenHeader: string, username: string>"
    create-secret: "record<caCertPem: string, description: string, id: string, name: string, password: string, token: string, tokenHeader: string, username: string>"
    get-secrets-counter: "record<counter: int>"
    get-secret: "record<caCertPem: string, description: string, id: string, name: string, password: string, token: string, tokenHeader: string, username: string>"
    get-services: "record<id: string, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, operations: table<bindings: record, defaultDelay: float, dispatcher: string, dispatcherRules: string, inputName: string, method: string, name: string, outputName: string, parameterContraints: list, resourcePaths: list>, type: string, version: string, xmlNS: string>"
    get-services-counter: "record<counter: int>"
    get-services-labels: "record"
    search-services: "table<id: string, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, operations: list<record>, type: string, version: string, xmlNS: string>"
    create-test: "record<elapsedTime: float, id: string, inProgress: bool, operationHeaders: record, runnerType: string, secretRef: record<name: string, secretId: string>, serviceId: string, success: bool, testCaseResults: table<elapsedTime: float, operationName: string, success: bool, testStepResults: list>, testDate: int, testNumber: float, testedEndpoint: string, timeout: int, version: float>"
    get-test-results-by-service: "table<elapsedTime: float, id: string, inProgress: bool, operationHeaders: record, runnerType: string, secretRef: record<name: string, secretId: string>, serviceId: string, success: bool, testCaseResults: list<record>, testDate: int, testNumber: float, testedEndpoint: string, timeout: int, version: float>"
    get-test-results-by-service-counter: "record<counter: int>"
    get-test-result: "record<elapsedTime: float, id: string, inProgress: bool, operationHeaders: record, runnerType: string, secretRef: record<name: string, secretId: string>, serviceId: string, success: bool, testCaseResults: table<elapsedTime: float, operationName: string, success: bool, testStepResults: list>, testDate: int, testNumber: float, testedEndpoint: string, timeout: int, version: float>"
    get-events-by-test-case: "table<eventMessage: record<content: string, headers: list, id: string, mediaType: string, name: string, operationId: string, testCaseId: string>, type: string>"
    get-messages-by-test-case: "table<request: record<content: string, headers: list, id: string, name: string, operationId: string, testCaseId: string>, response: record<content: string, headers: list, id: string, name: string, operationId: string, testCaseId: string>, type: string>"
    report-test-case-result: "record<elapsedTime: float, operationName: string, success: bool, testStepResults: table<elapsedTime: float, eventMessageName: string, message: string, requestName: string, success: bool>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["upload-artifact" "export-snapshot" "get-features-configuration" "import-snapshot" "get-import-jobs" "create-import-job" "get-import-job-counter" "delete-import-job" "get-jobs-id" "post-jobs-id" "activate-import-job" "start-import-job" "stop-import-job" "get-keycloak-config" "get-conformance-metrics-aggregation" "get-service-test-conformance-metric" "get-aggregated-invocations-stats" "get-latest-aggregated-invocations-stats" "get-top-ivnocations-stats-by-day" "get-invocation-stats-by-service" "get-latest-test-results" "get-resources-by-service" "get-resource" "get-secrets" "create-secret" "get-secrets-counter" "delete-secret" "get-secret" "update-secret" "get-services" "get-services-counter" "get-services-labels" "search-services" "delete-service" "get-service" "update-service-metadata" "override-service-operation" "create-test" "get-test-results-by-service" "get-test-results-by-service-counter" "get-test-result" "get-events-by-test-case" "get-messages-by-test-case" "report-test-case-result" "commands"] | sort) } | get name | first)
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

# Upload an artifact
#
# POST /artifact/upload
# Returns: string
# operationId: uploadArtifact
export def "upload-artifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --main-artifact: oneof<nothing, bool> # Flag telling if this should be considered as primary or secondary artifact. Default to 'true' (required)
  file: string # The artifact to upload (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/artifact/upload"
    query: [{name: mainArtifact, var: main_artifact, required: true}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["text/plain"]
    ok: [201, 204]
    auth: bearer
  } {
    main_artifact: $main_artifact, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export a snapshot
#
# GET /export
# Returns: binary
# operationId: exportSnapshot
export def "export-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-ids: list<string> # List of service identifiers to export (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/export"
    query: [{name: serviceIds, var: service_ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_ids: $service_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get features configuration
#
# GET /features/config
# operationId: GetFeaturesConfiguration
export def "get-features-configuration" [
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
    path: "/features/config"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a snapshot
#
# POST /import
# operationId: importSnapshot
export def "import-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The repository snapshot file (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/import"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ImportJobs
#
# GET /jobs
# Returns: table<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: list<record>>
# operationId: GetImportJobs
export def "get-import-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page of ImportJobs to retrieve (starts at and defaults to 0)
  --size: int # Size of a page. Maximum number of ImportJobs to include in a response (defaults to 20)
  --name: string # Name like criterion for query
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/jobs"
    query: [{name: page, var: page}, {name: size, var: size}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, size: $size, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create ImportJob
#
# POST /jobs
# Returns: record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>
# operationId: CreateImportJob
export def "create-import-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether this ImportJob is active (ie. scheduled for execution)
  --created-date: string # Creation date for this ImportJob (format: date-time)
  --etag: string # Etag of repository URL during previous import. Is used for not re-importing if no recent changes
  --frequency: string # Reserved for future usage
  --id: string # Unique identifier of ImportJob
  --last-import-date: string # Date last import was done (format: date-time)
  --last-import-error: string # Error message of last import (if any)
  --main-artifact: oneof<nothing, bool> # Flag telling if considered as primary or secondary artifact. Default to `true`
  --metadata: record # Commodity object for holding metadata on any entity. This object is inspired by Kubernetes metadata. — shape: {annotations?: record, createdOn: int, labels?: record, lastUpdate: int}
  name: string # Unique distinct name of this ImportJob
  --repository-disable-ssl-validation: oneof<nothing, bool> # Whether to disable SSL certificate verification when checking repository
  repository_url: string # URL of mocks and tests repository artifact
  --secret-ref: any # Lightweight reference for an existing Secret (e.g. {     "secretId": "5be58fb51ed744d1b87481bd",     "name": "Gogs internal" }) — shape: {name: string, secretId: string}
  --service-refs: list # References of Services discovered when checking repository — item shape: {name: string, serviceId: string, version: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/jobs"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: createdDate, var: created_date}, {name: etag, var: etag}, {name: frequency, var: frequency}, {name: id, var: id}, {name: lastImportDate, var: last_import_date}, {name: lastImportError, var: last_import_error}, {name: mainArtifact, var: main_artifact}, {name: metadata, var: metadata}, {name: name, var: name}, {name: repositoryDisableSSLValidation, var: repository_disable_ssl_validation}, {name: repositoryUrl, var: repository_url}, {name: secretRef, var: secret_ref}, {name: serviceRefs, var: service_refs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, created_date: $created_date, etag: $etag, frequency: $frequency, id: $id, last_import_date: $last_import_date, last_import_error: $last_import_error, main_artifact: $main_artifact, metadata: $metadata, name: $name, repository_disable_ssl_validation: $repository_disable_ssl_validation, repository_url: $repository_url, secret_ref: $secret_ref, service_refs: $service_refs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the ImportJobs counter
#
# GET /jobs/count
# Returns: record<counter: int>
# operationId: GetImportJobCounter
export def "get-import-job-counter" [
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
    path: "/jobs/count"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete ImportJob
#
# DELETE /jobs/{id}
# operationId: DeleteImportJob
export def "delete-import-job" [
  id: string
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

# Get ImportJob
#
# GET /jobs/{id}
# Returns: record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>
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
]: nothing -> oneof<record, string, nothing> {
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

# Update ImportJob
#
# POST /jobs/{id}
# Returns: record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>
export def "post-jobs-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether this ImportJob is active (ie. scheduled for execution)
  --created-date: string # Creation date for this ImportJob (format: date-time)
  --etag: string # Etag of repository URL during previous import. Is used for not re-importing if no recent changes
  --frequency: string # Reserved for future usage
  --body-id: string # Unique identifier of ImportJob (spec name: id)
  --last-import-date: string # Date last import was done (format: date-time)
  --last-import-error: string # Error message of last import (if any)
  --main-artifact: oneof<nothing, bool> # Flag telling if considered as primary or secondary artifact. Default to `true`
  --metadata: record # Commodity object for holding metadata on any entity. This object is inspired by Kubernetes metadata. — shape: {annotations?: record, createdOn: int, labels?: record, lastUpdate: int}
  name: string # Unique distinct name of this ImportJob
  --repository-disable-ssl-validation: oneof<nothing, bool> # Whether to disable SSL certificate verification when checking repository
  repository_url: string # URL of mocks and tests repository artifact
  --secret-ref: any # Lightweight reference for an existing Secret (e.g. {     "secretId": "5be58fb51ed744d1b87481bd",     "name": "Gogs internal" }) — shape: {name: string, secretId: string}
  --service-refs: list # References of Services discovered when checking repository — item shape: {name: string, serviceId: string, version: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/jobs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: createdDate, var: created_date}, {name: etag, var: etag}, {name: frequency, var: frequency}, {name: id, var: body_id}, {name: lastImportDate, var: last_import_date}, {name: lastImportError, var: last_import_error}, {name: mainArtifact, var: main_artifact}, {name: metadata, var: metadata}, {name: name, var: name}, {name: repositoryDisableSSLValidation, var: repository_disable_ssl_validation}, {name: repositoryUrl, var: repository_url}, {name: secretRef, var: secret_ref}, {name: serviceRefs, var: service_refs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, created_date: $created_date, etag: $etag, frequency: $frequency, body_id: $body_id, last_import_date: $last_import_date, last_import_error: $last_import_error, main_artifact: $main_artifact, metadata: $metadata, name: $name, repository_disable_ssl_validation: $repository_disable_ssl_validation, repository_url: $repository_url, secret_ref: $secret_ref, service_refs: $service_refs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate an ImportJob
#
# PUT /jobs/{id}/activate
# Returns: record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>
# operationId: ActivateImportJob
export def "activate-import-job" [
  id: string
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
    method: put
    path: "/jobs/{id}/activate"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start an ImportJob
#
# PUT /jobs/{id}/start
# Returns: record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>
# operationId: StartImportJob
export def "start-import-job" [
  id: string
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
    method: put
    path: "/jobs/{id}/start"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop an ImportJob
#
# PUT /jobs/{id}/stop
# Returns: record<active: bool, createdDate: string, etag: string, frequency: string, id: string, lastImportDate: string, lastImportError: string, mainArtifact: bool, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, repositoryDisableSSLValidation: bool, repositoryUrl: string, secretRef: record<name: string, secretId: string>, serviceRefs: table<name: string, serviceId: string, version: string>>
# operationId: StopImportJob
export def "stop-import-job" [
  id: string
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
    method: put
    path: "/jobs/{id}/stop"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get authentification configuration
#
# GET /keycloak/config
# Returns: record<auth-server-url: string, enabled: bool, public-client: string, realm: string, resource: string, ssl-required: any>
# operationId: GetKeycloakConfig
export def "get-keycloak-config" [
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
    path: "/keycloak/config"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get aggregation of conformance metrics
#
# GET /metrics/conformance/aggregate
# Returns: table<name: string, value: int, weight: int>
# operationId: GetConformanceMetricsAggregation
export def "get-conformance-metrics-aggregation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/conformance/aggregate"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get conformance metrics for a Service
#
# GET /metrics/conformance/service/{serviceId}
# Returns: record<aggregationLabelValue: string, currentScore: float, id: string, lastUpdateDay: string, latestScores: record, latestTrend: string, maxPossibleScore: float, serviceId: string>
# operationId: GetServiceTestConformanceMetric
export def "get-service-test-conformance-metric" [
  service_id: string
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
    path: "/metrics/conformance/service/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get aggregated invocation statistics for a day
#
# GET /metrics/invocations/global
# Returns: record<dailyCount: float, day: string, hourlyCount: record, id: string, minuteCount: record, serviceName: string, serviceVersion: string>
# operationId: GetAggregatedInvocationsStats
export def "get-aggregated-invocations-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --day: string # The day to get statistics for (formatted with yyyyMMdd pattern). Default to today if not provided.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/invocations/global"
    query: [{name: day, var: day}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get aggregated invocations statistics for latest days
#
# GET /metrics/invocations/global/latest
# Returns: record
# operationId: GetLatestAggregatedInvocationsStats
export def "get-latest-aggregated-invocations-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of days to get back in time. Default is 20.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/invocations/global/latest"
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get top invocation statistics for a day
#
# GET /metrics/invocations/top
# Returns: table<dailyCount: float, day: string, hourlyCount: record, id: string, minuteCount: record, serviceName: string, serviceVersion: string>
# operationId: GetTopIvnocationsStatsByDay
export def "get-top-ivnocations-stats-by-day" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --day: string # The day to get statistics for (formatted with yyyyMMdd pattern). Default to today if not provided.
  --limit: int # The number of top invoked mocks to return
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/invocations/top"
    query: [{name: day, var: day}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    day: $day, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invocation statistics for Service
#
# GET /metrics/invocations/{serviceName}/{serviceVersion}
# Returns: record<dailyCount: float, day: string, hourlyCount: record, id: string, minuteCount: record, serviceName: string, serviceVersion: string>
# operationId: GetInvocationStatsByService
export def "get-invocation-stats-by-service" [
  service_name: string
  service_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --day: string # The day to get statistics for (formatted with yyyyMMdd pattern). Default to today if not provided.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/invocations/{serviceName}/{serviceVersion}"
    path_params: [{name: serviceName, var: service_name}, {name: serviceVersion, var: service_version}]
    query: [{name: day, var: day}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_version: $service_version, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get latest tests results
#
# GET /metrics/tests/latest
# Returns: table<id: string, serviceId: string, success: bool, testDate: int>
# operationId: GetLatestTestResults
export def "get-latest-test-results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of days to consider for test results to return. Default is 7 (one week)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/tests/latest"
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Resources by Service
#
# GET /resources/service/{serviceId}
# Returns: table<content: string, id: string, name: string, path: string, serviceId: string, sourceArtifact: string, type: string>
# operationId: GetResourcesByService
export def "get-resources-by-service" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/service/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Resource
#
# GET /resources/{name}
# Returns: record<content: string, id: string, name: string, path: string, serviceId: string, sourceArtifact: string, type: string>
# operationId: GetResource
export def "get-resource" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Secrets
#
# GET /secrets
# Returns: table<caCertPem: string, description: string, id: string, name: string, password: string, token: string, tokenHeader: string, username: string>
# operationId: GetSecrets
export def "get-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page of Secrets to retrieve (starts at and defaults to 0)
  --size: int # Size of a page. Maximum number of Secrets to include in a response (defaults to 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/secrets"
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Secret
#
# POST /secrets
# Returns: record<caCertPem: string, description: string, id: string, name: string, password: string, token: string, tokenHeader: string, username: string>
# operationId: CreateSecret
export def "create-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ca-cert-pem: string
  description: string # Description of this Secret
  --id: string # Unique identifier of Secret
  name: string # Unique distinct name of Secret
  --password: string
  --body-token: string # (spec name: token)
  --token-header: string
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/secrets"
    body: {content_type: "application/json", kind: json, fields: [{name: caCertPem, var: ca_cert_pem}, {name: description, var: description}, {name: id, var: id}, {name: name, var: name}, {name: password, var: password}, {name: token, var: body_token}, {name: tokenHeader, var: token_header}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ca_cert_pem: $ca_cert_pem, description: $description, id: $id, name: $name, password: $password, body_token: $body_token, token_header: $token_header, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Secrets counter
#
# GET /secrets/count
# Returns: record<counter: int>
# operationId: GetSecretsCounter
export def "get-secrets-counter" [
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
    path: "/secrets/count"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Secret
#
# DELETE /secrets/{id}
# operationId: DeleteSecret
export def "delete-secret" [
  id: string
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
    path: "/secrets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Secret
#
# GET /secrets/{id}
# Returns: record<caCertPem: string, description: string, id: string, name: string, password: string, token: string, tokenHeader: string, username: string>
# operationId: GetSecret
export def "get-secret" [
  id: string
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
    path: "/secrets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Secret
#
# PUT /secrets/{id}
# operationId: UpdateSecret
export def "update-secret" [
  id: string
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
    path: "/secrets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Services and APIs
#
# GET /services
# Returns: record<id: string, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, operations: table<bindings: record, defaultDelay: float, dispatcher: string, dispatcherRules: string, inputName: string, method: string, name: string, outputName: string, parameterContraints: list, resourcePaths: list>, type: string, version: string, xmlNS: string>
# operationId: GetServices
export def "get-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page of Services to retrieve (starts at and defaults to 0)
  --size: int # Size of a page. Maximum number of Services to include in a response (defaults to 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/services"
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Services counter
#
# GET /services/count
# Returns: record<counter: int>
# operationId: GetServicesCounter
export def "get-services-counter" [
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
    path: "/services/count"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the already used labels for Services
#
# GET /services/labels
# Returns: record
# operationId: GetServicesLabels
export def "get-services-labels" [
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
    path: "/services/labels"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for Services and APIs
#
# GET /services/search
# Returns: table<id: string, metadata: record<annotations: record, createdOn: int, labels: record, lastUpdate: int>, name: string, operations: list<record>, type: string, version: string, xmlNS: string>
# operationId: SearchServices
export def "search-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query-map: record # Map of criterion. Key can be simply 'name' with value as the searched string. You can also search by label using keys like 'labels.x' where 'x' is the label and value the label value (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/services/search"
    query: [{name: queryMap, var: query_map, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query_map: $query_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Service
#
# DELETE /services/{id}
# operationId: DeleteService
export def "delete-service" [
  id: string
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
    path: "/services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Service
#
# GET /services/{id}
# operationId: GetService
export def "get-service" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --messages: oneof<nothing, bool> # Whether to include details on services messages into result. Default is false
]: nothing -> any {
  http-request {
    method: get
    path: "/services/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: messages, var: messages}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, messages: $messages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Service Metadata
#
# PUT /services/{id}/metadata
# operationId: UpdateServiceMetadata
export def "update-service-metadata" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # Annotations of attached object
  created_on: int # Creation date of attached object
  --labels: record # Labels put on attached object
  last_update: int # Last update of attached object
]: any -> any {
  $in | http-request {
    method: put
    path: "/services/{id}/metadata"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: createdOn, var: created_on}, {name: labels, var: labels}, {name: lastUpdate, var: last_update}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, annotations: $annotations, created_on: $created_on, labels: $labels, last_update: $last_update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Override Service Operation
#
# PUT /services/{id}/operation
# operationId: OverrideServiceOperation
export def "override-service-operation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation-name: string # Name of operation to update (required)
  --default-delay: int # Default delay in milliseconds to apply to mock responses on this operation
  --dispatcher: string # Type of dispatcher to apply for this operation
  --dispatcher-rules: string # Rules of dispatcher for this operation
  --parameter-constraints: list # Constraints that may apply to incoming parameters on this operation — item shape: {in?: "path"|"query"|"header", mustMatchRegexp?: string, name: string, recopy?: bool, required?: bool}
]: any -> any {
  $in | http-request {
    method: put
    path: "/services/{id}/operation"
    path_params: [{name: id, var: id}]
    query: [{name: operationName, var: operation_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultDelay, var: default_delay}, {name: dispatcher, var: dispatcher}, {name: dispatcherRules, var: dispatcher_rules}, {name: parameterConstraints, var: parameter_constraints}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, operation_name: $operation_name, default_delay: $default_delay, dispatcher: $dispatcher, dispatcher_rules: $dispatcher_rules, parameter_constraints: $parameter_constraints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Test
#
# POST /tests
# Returns: record<elapsedTime: float, id: string, inProgress: bool, operationHeaders: record, runnerType: string, secretRef: record<name: string, secretId: string>, serviceId: string, success: bool, testCaseResults: table<elapsedTime: float, operationName: string, success: bool, testStepResults: list>, testDate: int, testNumber: float, testedEndpoint: string, timeout: int, version: float>
# operationId: CreateTest
export def "create-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filtered-operations: list<string> # A restriction on service operations to test
  --operation-headers: record # Specification of additional headers for a Service/API operations. Keys are operation name or "globals" (if header applies to all), values are Header objects DTO.
  runner_type: string@runner-type-completer # Type of test strategy (different strategies are implemented by different runners)
  --secret-name: string # The name of Secret to use for connecting the test endpoint
  service_id: string # Unique identifier of service to test
  test_endpoint: string # Endpoint to test for this service
  timeout: int # The maximum time (in milliseconds) to wait for this test ends
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tests"
    body: {content_type: "application/json", kind: json, fields: [{name: filteredOperations, var: filtered_operations}, {name: operationHeaders, var: operation_headers}, {name: runnerType, var: runner_type}, {name: secretName, var: secret_name}, {name: serviceId, var: service_id}, {name: testEndpoint, var: test_endpoint}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    filtered_operations: $filtered_operations, operation_headers: $operation_headers, runner_type: $runner_type, secret_name: $secret_name, service_id: $service_id, test_endpoint: $test_endpoint, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get TestResults by Service
#
# GET /tests/service/{serviceId}
# Returns: table<elapsedTime: float, id: string, inProgress: bool, operationHeaders: record, runnerType: string, secretRef: record<name: string, secretId: string>, serviceId: string, success: bool, testCaseResults: list<record>, testDate: int, testNumber: float, testedEndpoint: string, timeout: int, version: float>
# operationId: GetTestResultsByService
export def "get-test-results-by-service" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tests/service/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the TestResults for Service counter
#
# GET /tests/service/{serviceId}/count
# Returns: record<counter: int>
# operationId: GetTestResultsByServiceCounter
export def "get-test-results-by-service-counter" [
  service_id: string
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
    path: "/tests/service/{serviceId}/count"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get TestResult
#
# GET /tests/{id}
# Returns: record<elapsedTime: float, id: string, inProgress: bool, operationHeaders: record, runnerType: string, secretRef: record<name: string, secretId: string>, serviceId: string, success: bool, testCaseResults: table<elapsedTime: float, operationName: string, success: bool, testStepResults: list>, testDate: int, testNumber: float, testedEndpoint: string, timeout: int, version: float>
# operationId: GetTestResult
export def "get-test-result" [
  id: string
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
    path: "/tests/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events for TestCase
#
# GET /tests/{id}/events/{testCaseId}
# Returns: table<eventMessage: record<content: string, headers: list, id: string, mediaType: string, name: string, operationId: string, testCaseId: string>, type: string>
# operationId: GetEventsByTestCase
export def "get-events-by-test-case" [
  id: string
  test_case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tests/{id}/events/{testCaseId}"
    path_params: [{name: id, var: id}, {name: testCaseId, var: test_case_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, test_case_id: $test_case_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get messages for TestCase
#
# GET /tests/{id}/messages/{testCaseId}
# Returns: table<request: record<content: string, headers: list, id: string, name: string, operationId: string, testCaseId: string>, response: record<content: string, headers: list, id: string, name: string, operationId: string, testCaseId: string>, type: string>
# operationId: GetMessagesByTestCase
export def "get-messages-by-test-case" [
  id: string
  test_case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tests/{id}/messages/{testCaseId}"
    path_params: [{name: id, var: id}, {name: testCaseId, var: test_case_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, test_case_id: $test_case_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report and create a new TestCaseResult
#
# POST /tests/{id}/testCaseResult
# Returns: record<elapsedTime: float, operationName: string, success: bool, testStepResults: table<elapsedTime: float, eventMessageName: string, message: string, requestName: string, success: bool>>
# operationId: ReportTestCaseResult
export def "report-test-case-result" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  operation_name: string # Name of related operation for this TestCase
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tests/{id}/testCaseResult"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: operationName, var: operation_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, operation_name: $operation_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
