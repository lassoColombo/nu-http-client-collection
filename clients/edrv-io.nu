# Auto-generated client for eDRV API v1
# Source: https://api.apis.guru/v2/specs/edrv.io/v1/openapi.json
# Auth: --token flag or $env.EDRV_API_TOKEN

const CLIENT = {
  base_url: "http://localhost//api.edrv.io"
  token_env_var: "EDRV_API_TOKEN"
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

def base-url-completer [] { ["http://localhost//api.edrv.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-order-completer [] { ["asc" "desc"] }
def variable-completer [] { ["ConnectionTimeOut" "HeartbeatInterval" "MeterValueSampleInterval" "TransactionMessageAttempts" "TransactionMessageRetryInterval" "WebSocketPingInterval"] }
def source-completer [] { ["physical" "slack" "sms" "telegram"] }
def channel-completer [] { ["physical" "slack" "sms" "telegram"] }
def status-completer [] { ["Ended" "Started"] }
def action-completer [] { ["START" "STOP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-charge-stations: "record<chargestation: record, message: string, ok: bool>"
    patch-charge-station: "record<message: string, ok: bool, result: record>"
    cancelreservation: "record<message: string, ok: bool, result: record>"
    deletechargingschedule: "record<command: record, message: string, ok: bool>"
    setchargingschedule: "record<command: record, message: string, ok: bool>"
    remotestart: "record<command: record, message: string, ok: bool>"
    reserve: "record<command: record, message: string, ok: bool>"
    reset: "record<message: string, ok: bool, result: record>"
    unlockconnector: "record<command: record, message: string, ok: bool>"
    patch-charge-station-variable: "record<message: string, ok: bool, result: record>"
    post-configurations: "record<message: string, ok: bool, result: record>"
    post-connectors: "record<message: string, ok: bool, result: record>"
    patch-connector: "record<message: string, ok: bool, result: record>"
    get-drivers: "record<message: string, ok: bool, result: list<any>>"
    post-drivers: "record<message: string, ok: bool, result: record>"
    patch-driver: "record<message: string, ok: bool, result: list<any>>"
    patch-location: "record<message: string, ok: bool, result: list<any>>"
    post-locations: "record<message: string, ok: bool, result: record>"
    updatereservation: "record<message: string, ok: bool, result: record>"
    get-tokens: "record<message: string, ok: bool, result: list<any>>"
    post-tokens: "record<message: string, ok: bool, result: list<any>>"
    patch-token: "record<message: string, ok: bool, result: list<any>>"
    get-transactions: "record<hasNext: bool, hasPrevious: bool, message: string, ok: bool, result: list<any>>"
    get-vehicles: "record<message: string, ok: bool, result: list<any>>"
    post-charge: "record<message: string, ok: bool, result: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-charge-stations" "post-charge-stations" "delete-charge-station" "get-charge-station" "patch-charge-station" "get-charge-station-connectors" "get-commands" "cancelreservation" "deletechargingschedule" "setchargingschedule" "remotestart" "remotestop" "reserve" "reset" "unlockconnector" "get-variables" "patch-charge-station-variable" "get-configurations" "post-configurations" "get-configuration" "get-connectors" "post-connectors" "delete-connector" "get-connector" "patch-connector" "get-drivers" "post-drivers" "delete-driver" "get-driver" "patch-driver" "delete-location" "get-location" "patch-location" "get-locations" "post-locations" "get-organizations" "get-organization" "patch-organization" "get-realtime" "get-reservations" "get-reservation" "updatereservation" "get-tokens" "post-tokens" "delete-token" "get-token" "patch-token" "get-transactions" "get-transaction" "get-transaction-cost" "get-vehicles" "get-vehicle" "get-vehicle-battery" "get-vehicle-charge" "post-charge" "get-vehicle-location" "get-vehicle-odometer" "commands"] | sort) } | get name | first)
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

# List all Chargestations
#
# GET /v1/chargestations
# operationId: getChargeStations
export def "get-charge-stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization: string # Filter by Org. Id
  --location: string # Filter by Location Id
  --online: oneof<nothing, bool> # Filter by Online Status
  --active: oneof<nothing, bool> # Chargestations that have been activated/deactivated by the admin
  --public: oneof<nothing, bool> # Chargestations that are public
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-location: oneof<nothing, bool> # Populate location
  --include-evses: oneof<nothing, bool> # Populate evses
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/chargestations"
    query: [{name: organization, var: organization}, {name: location, var: location}, {name: online, var: online}, {name: active, var: active}, {name: public, var: public}, {name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_location, var: include_location}, {name: include_evses, var: include_evses}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization: $organization, location: $location, online: $online, active: $active, public: $public, paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_location: $include_location, include_evses: $include_evses, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new charge station
#
# POST /v1/chargestations
# Returns: record<chargestation: record, message: string, ok: bool>
# operationId: postChargeStations
export def "post-charge-stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: string
  --manufacturer: string
  --model: string
  --protocol: string
  --public: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/chargestations"
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: manufacturer, var: manufacturer}, {name: model, var: model}, {name: protocol, var: protocol}, {name: public, var: public}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    location: $location, manufacturer: $manufacturer, model: $model, protocol: $protocol, public: $public
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to delete a charge station
#
# DELETE /v1/chargestations/{id}
# operationId: deleteChargeStation
export def "delete-charge-station" [
  id: string
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
    path: "/v1/chargestations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single charge station's data
#
# GET /v1/chargestations/{id}
# operationId: getChargeStation
export def "get-charge-station" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-location: oneof<nothing, bool> # Populate location
  --include-evses: oneof<nothing, bool> # Populate evses
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/chargestations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_location, var: include_location}, {name: include_evses, var: include_evses}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_location: $include_location, include_evses: $include_evses, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a charge station's data
#
# PATCH /v1/chargestations/{id}
# Returns: record<message: string, ok: bool, result: record>
# operationId: patchChargeStation
export def "patch-charge-station" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: string
  --manufacturer: string
  --model: string
  --protocol: string
  --public: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/chargestations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: manufacturer, var: manufacturer}, {name: model, var: model}, {name: protocol, var: protocol}, {name: public, var: public}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, location: $location, manufacturer: $manufacturer, model: $model, protocol: $protocol, public: $public
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List connectors for a chargestation
#
# GET /v1/chargestations/{id}/connectors
# operationId: getChargeStationConnectors
export def "get-charge-station-connectors" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/chargestations/{id}/connectors"
    path_params: [{name: id, var: id}]
    query: [{name: include_evse, var: include_evse}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_evse: $include_evse, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Commands data
#
# GET /v1/commands
# operationId: getCommands
export def "get-commands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-transaction: oneof<nothing, bool> # Populate transaction
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/commands"
    query: [{name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_chargestation, var: include_chargestation}, {name: include_driver, var: include_driver}, {name: include_transaction, var: include_transaction}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_chargestation: $include_chargestation, include_driver: $include_driver, include_transaction: $include_transaction, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request a delete an existing reservation. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/cancelreservation
# Returns: record<message: string, ok: bool, result: record>
# operationId: cancelreservation
export def "cancelreservation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/commands/cancelreservation"
    body: {content_type: "application/json", kind: json, fields: [{name: reservation, var: reservation}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    reservation: $reservation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a smart charging schedule
#
# DELETE /v1/commands/chargingschedule
# Returns: record<command: record, message: string, ok: bool>
# operationId: deletechargingschedule
export def "deletechargingschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v1/commands/chargingschedule"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set one of charging power or current of a specific chargestation connector
#
# POST /v1/commands/chargingschedule
# Returns: record<command: record, message: string, ok: bool>
# operationId: setchargingschedule
export def "setchargingschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connector: string
  --schedule: list # item shape: {endDate?: string, limit?: float, startDate?: string, unit?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/commands/chargingschedule"
    body: {content_type: "application/json", kind: json, fields: [{name: connector, var: connector}, {name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    connector: $connector, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request a remote start command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/remotestart
# Returns: record<command: record, message: string, ok: bool>
# operationId: remotestart
export def "remotestart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
  --driver: string
  --body-token: string # (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/commands/remotestart"
    body: {content_type: "application/json", kind: json, fields: [{name: chargestation, var: chargestation}, {name: connector, var: connector}, {name: driver, var: driver}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    chargestation: $chargestation, connector: $connector, driver: $driver, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request a remote stop command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/remotestop
# operationId: remotestop
export def "remotestop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --driver: string
  --transaction: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/commands/remotestop"
    body: {content_type: "application/json", kind: json, fields: [{name: chargestation, var: chargestation}, {name: driver, var: driver}, {name: transaction, var: transaction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    chargestation: $chargestation, driver: $driver, transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request a reserve command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/reserve
# Returns: record<command: record, message: string, ok: bool>
# operationId: reserve
export def "reserve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
  --driver: string
  --end-date: string
  --body-token: string # (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/commands/reserve"
    body: {content_type: "application/json", kind: json, fields: [{name: chargestation, var: chargestation}, {name: connector, var: connector}, {name: driver, var: driver}, {name: endDate, var: end_date}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    chargestation: $chargestation, connector: $connector, driver: $driver, end_date: $end_date, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request a reset command. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/reset
# Returns: record<message: string, ok: bool, result: record>
# operationId: reset
export def "reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/commands/reset"
    body: {content_type: "application/json", kind: json, fields: [{name: chargestation, var: chargestation}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    chargestation: $chargestation, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request an unlock command for a connector. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# POST /v1/commands/unlockconnector
# Returns: record<command: record, message: string, ok: bool>
# operationId: unlockconnector
export def "unlockconnector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --connector: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/commands/unlockconnector"
    body: {content_type: "application/json", kind: json, fields: [{name: chargestation, var: chargestation}, {name: connector, var: connector}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    chargestation: $chargestation, connector: $connector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a charge station's config variables
#
# GET /v1/commands/{id}/variables
# operationId: getVariables
export def "get-variables" [
  id: string
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
    path: "/v1/commands/{id}/variables"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update config variables for a chargestation
#
# PATCH /v1/commands/{id}/variables
# Returns: record<message: string, ok: bool, result: record>
# operationId: patchChargeStationVariable
export def "patch-charge-station-variable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
  --variable: string@variable-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/commands/{id}/variables"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}, {name: variable, var: variable}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, value: $value, variable: $variable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Configurations data
#
# GET /v1/configurations
# operationId: getConfigurations
export def "get-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/configurations"
    query: [{name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create connector with parameters
#
# POST /v1/configurations
# Returns: record<message: string, ok: bool, result: record>
# operationId: postConfigurations
export def "post-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/configurations"
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one Configuration data
#
# GET /v1/configurations/{id}
# operationId: getConfiguration
export def "get-configuration" [
  id: string
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
    path: "/v1/configurations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List connectors
#
# GET /v1/connectors
# operationId: getConnectors
export def "get-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/connectors"
    query: [{name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_evse, var: include_evse}, {name: include_organization, var: include_organization}, {name: include_rate, var: include_rate}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_evse: $include_evse, include_organization: $include_organization, include_rate: $include_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new connector
#
# POST /v1/connectors
# Returns: record<message: string, ok: bool, result: record>
# operationId: postConnectors
export def "post-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --format: string
  --power: int
  --power-type: string
  --rate: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connectors"
    body: {content_type: "application/json", kind: json, fields: [{name: chargestation, var: chargestation}, {name: format, var: format}, {name: power, var: power}, {name: power_type, var: power_type}, {name: rate, var: rate}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chargestation: $chargestation, format: $format, power: $power, power_type: $power_type, rate: $rate, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a connector
#
# DELETE /v1/connectors/{id}
# operationId: deleteConnector
export def "delete-connector" [
  id: string
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
    path: "/v1/connectors/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a connector
#
# GET /v1/connectors/{id}
# operationId: getConnector
export def "get-connector" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/connectors/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_evse, var: include_evse}, {name: include_organization, var: include_organization}, {name: include_rate, var: include_rate}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_evse: $include_evse, include_organization: $include_organization, include_rate: $include_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a connector's data
#
# PATCH /v1/connectors/{id}
# Returns: record<message: string, ok: bool, result: record>
# operationId: patchConnector
export def "patch-connector" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chargestation: string
  --format: string
  --power: int
  --power-type: string
  --rate: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/connectors/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: chargestation, var: chargestation}, {name: format, var: format}, {name: power, var: power}, {name: power_type, var: power_type}, {name: rate, var: rate}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, chargestation: $chargestation, format: $format, power: $power, power_type: $power_type, rate: $rate, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all drivers
#
# GET /v1/drivers
# Returns: record<message: string, ok: bool, result: list<any>>
# operationId: getDrivers
export def "get-drivers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Get a list of active drivers
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-tokens: oneof<nothing, bool> # Populate tokens
  --include-group: oneof<nothing, bool> # Populate group
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/drivers"
    query: [{name: active, var: active}, {name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_tokens, var: include_tokens}, {name: include_group, var: include_group}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    active: $active, paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_tokens: $include_tokens, include_group: $include_group, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new driver
#
# POST /v1/drivers
# Returns: record<message: string, ok: bool, result: record>
# operationId: postDrivers
export def "post-drivers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  --address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --email: string
  firstname: string
  lastname: string
  --phone: record # shape: {home?: string, mobile?: string, work?: string}
  source: string@source-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/drivers"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: address, var: address}, {name: email, var: email}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: phone, var: phone}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    active: $active, address: $address, email: $email, firstname: $firstname, lastname: $lastname, phone: $phone, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a driver
#
# DELETE /v1/drivers/{id}
# operationId: deleteDriver
export def "delete-driver" [
  id: string
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
    path: "/v1/drivers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a driver's data
#
# GET /v1/drivers/{id}
# operationId: getDriver
export def "get-driver" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-tokens: oneof<nothing, bool> # Populate tokens
  --include-group: oneof<nothing, bool> # Populate group
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/drivers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_tokens, var: include_tokens}, {name: include_group, var: include_group}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_tokens: $include_tokens, include_group: $include_group, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a driver's data
#
# PATCH /v1/drivers/{id}
# Returns: record<message: string, ok: bool, result: list<any>>
# operationId: patchDriver
export def "patch-driver" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --email: string
  --firstname: string
  --lastname: string
  --phone: record # shape: {home?: string, mobile?: string, work?: string}
  --source: string
  --tokens: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/drivers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: address, var: address}, {name: email, var: email}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: phone, var: phone}, {name: source, var: source}, {name: tokens, var: tokens}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, address: $address, email: $email, firstname: $firstname, lastname: $lastname, phone: $phone, source: $source, tokens: $tokens
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a location
#
# DELETE /v1/location/{id}
# operationId: deleteLocation
export def "delete-location" [
  id: string
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
    path: "/v1/location/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a location's data
#
# GET /v1/location/{id}
# operationId: getLocation
export def "get-location" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-chargestations: oneof<nothing, bool> # Populate chargestations
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/location/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_chargestations, var: include_chargestations}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_chargestations: $include_chargestations, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a location's data
#
# PATCH /v1/location/{id}
# Returns: record<message: string, ok: bool, result: list<any>>
# operationId: patchLocation
export def "patch-location" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  --address: record # shape: {city?: string, country?: string, postalCode?: string, state?: string, streetAndNumber?: string}
  --chargestations: list
  --coordinates: record # shape: {latitude?: float, longitude?: float}
  --opening-hours: record # shape: {0?: list, 1?: list, 2?: list, 3?: list, 4?: list, 5?: list, 6?: list}
  --operator-name: string
  --timezone: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/location/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: address, var: address}, {name: chargestations, var: chargestations}, {name: coordinates, var: coordinates}, {name: openingHours, var: opening_hours}, {name: operatorName, var: operator_name}, {name: timezone, var: timezone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, active: $active, address: $address, chargestations: $chargestations, coordinates: $coordinates, opening_hours: $opening_hours, operator_name: $operator_name, timezone: $timezone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Locations data
#
# GET /v1/locations
# operationId: getLocations
export def "get-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/locations"
    query: [{name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new location
#
# POST /v1/locations
# Returns: record<message: string, ok: bool, result: record>
# operationId: postLocations
export def "post-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --chargestations: list
  coordinates: record # shape: {latitude?: float, longitude?: float}
  operator_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/locations"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: address, var: address}, {name: chargestations, var: chargestations}, {name: coordinates, var: coordinates}, {name: operatorName, var: operator_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    active: $active, address: $address, chargestations: $chargestations, coordinates: $coordinates, operator_name: $operator_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an array of all Organizations
#
# GET /v1/organizations
# operationId: getOrganizations
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
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-locations: oneof<nothing, bool> # Populate locations
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/organizations"
    query: [{name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_locations, var: include_locations}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_locations: $include_locations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one organization's data by id
#
# GET /v1/organizations/{id}
# operationId: getOrganization
export def "get-organization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-locations: oneof<nothing, bool> # Populate locations
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/organizations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_locations, var: include_locations}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_locations: $include_locations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an organization's data
#
# PATCH /v1/organizations/{id}
# operationId: patchOrganization
export def "patch-organization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --address: record # shape: {city?: string, country?: string, postalCode?: string, streetAndNumber?: string}
  --channels: record # shape: {slack?: record, telegram?: record}
  --configurations: record # shape: {basicAuthEnabled?: bool, basicAuthPassword?: bool}
  --links: record # shape: {about?: string, contact?: string, privacy?: string, support?: string}
  --locations: list
  --logo: string
  --name: string
  --otp: string
  --stripe-connected-account-id: string
  --stripe-country: string
  --stripe-currency: string
  --stripe-reserve-amount: int
  --support: record # shape: {business_hours?: string, chat?: record, contact_number?: string, email?: string}
  --support-chat: record # shape: {id?: string, name?: string}
  --theme: record # shape: {colors?: record}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/organizations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: address, var: address}, {name: channels, var: channels}, {name: configurations, var: configurations}, {name: links, var: links}, {name: locations, var: locations}, {name: logo, var: logo}, {name: name, var: name}, {name: otp, var: otp}, {name: stripe_connected_account_id, var: stripe_connected_account_id}, {name: stripe_country, var: stripe_country}, {name: stripe_currency, var: stripe_currency}, {name: stripe_reserve_amount, var: stripe_reserve_amount}, {name: support, var: support}, {name: supportChat, var: support_chat}, {name: theme, var: theme}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, active: $active, address: $address, channels: $channels, configurations: $configurations, links: $links, locations: $locations, logo: $logo, name: $name, otp: $otp, stripe_connected_account_id: $stripe_connected_account_id, stripe_country: $stripe_country, stripe_currency: $stripe_currency, stripe_reserve_amount: $stripe_reserve_amount, support: $support, support_chat: $support_chat, theme: $theme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request a Websockets handshake
#
# GET /v1/realtime
# operationId: getRealtime
export def "get-realtime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sec-websocket-protocol: string # The JWT token to use for auth (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/realtime"
    header: [{name: sec-websocket-protocol, var: sec_websocket_protocol, required: true}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    sec_websocket_protocol: $sec_websocket_protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Reservations data
#
# GET /v1/reservations
# operationId: getReservations
export def "get-reservations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/reservations"
    query: [{name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_chargestation, var: include_chargestation}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_chargestation: $include_chargestation, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one reservation data
#
# GET /v1/reservations/{id}
# operationId: getReservation
export def "get-reservation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/reservations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_chargestation, var: include_chargestation}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_chargestation: $include_chargestation, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to request a update an existing reservation. The request will wait for the charge station to process the command. It will timeout after 60 seconds.
#
# PATCH /v1/reservations/{id}
# Returns: record<message: string, ok: bool, result: record>
# operationId: updatereservation
export def "updatereservation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connector: int
  --driver: string
  --end-date: string
  --evse: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/reservations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: connector, var: connector}, {name: driver, var: driver}, {name: endDate, var: end_date}, {name: evse, var: evse}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, connector: $connector, driver: $driver, end_date: $end_date, evse: $evse
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tokens
#
# GET /v1/tokens
# Returns: record<message: string, ok: bool, result: list<any>>
# operationId: getTokens
export def "get-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/tokens"
    query: [{name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_driver, var: include_driver}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_driver: $include_driver, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new token
#
# POST /v1/tokens
# Returns: record<message: string, ok: bool, result: list<any>>
# operationId: postTokens
export def "post-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  channel: string@channel-completer
  driver: string
  physical_id: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/tokens"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active, required: true}, {name: channel, var: channel}, {name: driver, var: driver}, {name: physicalId, var: physical_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, channel: $channel, driver: $driver, physical_id: $physical_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use to delete a token
#
# DELETE /v1/tokens/{id}
# operationId: deleteToken
export def "delete-token" [
  id: string
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
    path: "/v1/tokens/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single token's data
#
# GET /v1/tokens/{id}
# operationId: getToken
export def "get-token" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/tokens/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_driver, var: include_driver}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_driver: $include_driver, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a token
#
# PATCH /v1/tokens/{id}
# Returns: record<message: string, ok: bool, result: list<any>>
# operationId: patchToken
export def "patch-token" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: true
  --channel: string@channel-completer
  --driver: string
  --physical-id: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/tokens/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: channel, var: channel}, {name: driver, var: driver}, {name: physicalId, var: physical_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, active: $active, channel: $channel, driver: $driver, physical_id: $physical_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of transactions
#
# GET /v1/transactions
# Returns: record<hasNext: bool, hasPrevious: bool, message: string, ok: bool, result: list<any>>
# operationId: getTransactions
export def "get-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Started to get only active transactions
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-connector: oneof<nothing, bool> # Populate connector
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-reservation: oneof<nothing, bool> # Populate reservation
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/transactions"
    query: [{name: status, var: status}, {name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_chargestation, var: include_chargestation}, {name: include_evse, var: include_evse}, {name: include_connector, var: include_connector}, {name: include_driver, var: include_driver}, {name: include_token, var: include_token}, {name: include_reservation, var: include_reservation}, {name: include_organization, var: include_organization}, {name: include_rate, var: include_rate}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_chargestation: $include_chargestation, include_evse: $include_evse, include_connector: $include_connector, include_driver: $include_driver, include_token: $include_token, include_reservation: $include_reservation, include_organization: $include_organization, include_rate: $include_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific transaction
#
# GET /v1/transactions/{id}
# operationId: getTransaction
export def "get-transaction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-chargestation: oneof<nothing, bool> # Populate chargestation
  --include-evse: oneof<nothing, bool> # Populate evse
  --include-connector: oneof<nothing, bool> # Populate connector
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-reservation: oneof<nothing, bool> # Populate reservation
  --include-organization: oneof<nothing, bool> # Populate organization
  --include-rate: oneof<nothing, bool> # Populate rate
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/transactions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_chargestation, var: include_chargestation}, {name: include_evse, var: include_evse}, {name: include_connector, var: include_connector}, {name: include_driver, var: include_driver}, {name: include_token, var: include_token}, {name: include_reservation, var: include_reservation}, {name: include_organization, var: include_organization}, {name: include_rate, var: include_rate}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_chargestation: $include_chargestation, include_evse: $include_evse, include_connector: $include_connector, include_driver: $include_driver, include_token: $include_token, include_reservation: $include_reservation, include_organization: $include_organization, include_rate: $include_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific transaction's cost
#
# GET /v1/transactions/{id}/cost
# operationId: getTransactionCost
export def "get-transaction-cost" [
  id: string
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
    path: "/v1/transactions/{id}/cost"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all vehicles
#
# GET /v1/vehicles
# Returns: record<message: string, ok: bool, result: list<any>>
# operationId: getVehicles
export def "get-vehicles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Get a list of active vehicles
  --paginate-limit: int # Number of results per page (default: 20)
  --paginate-page: string # The queried page index
  --paginate-enabled: oneof<nothing, bool> # Enable pagination (default: true)
  --sort-by: string # Sort data by this key (default: createdAt)
  --sort-order: string@sort-order-completer # asc to sort ascending (default is desc - descending) (default: desc)
  --created-at-gte: string # Date as ISO String (format: date-time)
  --created-at-lte: string # Date as ISO String (format: date-time)
  --updated-at-gte: string # Date as ISO String (format: date-time)
  --updated-at-lte: string # Date as ISO String (format: date-time)
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/vehicles"
    query: [{name: active, var: active}, {name: paginate_limit, var: paginate_limit}, {name: paginate_page, var: paginate_page}, {name: paginate_enabled, var: paginate_enabled}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: "createdAt[$gte]", var: created_at_gte}, {name: "createdAt[$lte]", var: created_at_lte}, {name: "updatedAt[$gte]", var: updated_at_gte}, {name: "updatedAt[$lte]", var: updated_at_lte}, {name: include_driver, var: include_driver}, {name: include_token, var: include_token}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    active: $active, paginate_limit: $paginate_limit, paginate_page: $paginate_page, paginate_enabled: $paginate_enabled, sort_by: $sort_by, sort_order: $sort_order, created_at_gte: $created_at_gte, created_at_lte: $created_at_lte, updated_at_gte: $updated_at_gte, updated_at_lte: $updated_at_lte, include_driver: $include_driver, include_token: $include_token, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a vehicle's data
#
# GET /v1/vehicles/{id}
# operationId: getVehicle
export def "get-vehicle" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-driver: oneof<nothing, bool> # Populate driver
  --include-token: oneof<nothing, bool> # Populate token
  --include-organization: oneof<nothing, bool> # Populate organization
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/vehicles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include_driver, var: include_driver}, {name: include_token, var: include_token}, {name: include_organization, var: include_organization}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_driver: $include_driver, include_token: $include_token, include_organization: $include_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a vehicle's battery
#
# GET /v1/vehicles/{id}/battery
# operationId: getVehicleBattery
export def "get-vehicle-battery" [
  id: string
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
    path: "/v1/vehicles/{id}/battery"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a vehicle's charge
#
# GET /v1/vehicles/{id}/charge
# operationId: getVehicleCharge
export def "get-vehicle-charge" [
  id: string
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
    path: "/v1/vehicles/{id}/charge"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change charge
#
# POST /v1/vehicles/{id}/charge
# Returns: record<message: string, ok: bool, result: record>
# operationId: postCharge
export def "post-charge" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string@action-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/vehicles/{id}/charge"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a vehicle's location
#
# GET /v1/vehicles/{id}/location
# operationId: getVehicleLocation
export def "get-vehicle-location" [
  id: string
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
    path: "/v1/vehicles/{id}/location"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a vehicle's odometer
#
# GET /v1/vehicles/{id}/odometer
# operationId: getVehicleOdometer
export def "get-vehicle-odometer" [
  id: string
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
    path: "/v1/vehicles/{id}/odometer"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
