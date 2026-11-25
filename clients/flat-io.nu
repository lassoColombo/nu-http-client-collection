# Auto-generated client for Flat API v2.13.0
# Source: https://api.apis.guru/v2/specs/flat.io/2.13.0/openapi.json
# Auth: --token flag or $env.FLAT_API_TOKEN

const CLIENT = {
  base_url: "https://api.flat.io/v2"
  token_env_var: "FLAT_API_TOKEN"
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

def base-url-completer [] { ["https://api.flat.io/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["active" "archived" "inactive"] }
def assignee-mode-completer [] { ["everyone" "selected"] }
def state-completer-1 [] { ["active" "draft"] }
def type-completer [] { ["newScore" "none" "performance" "scoreTemplate" "sharedWriting" "worksheet"] }
def sort-completer [] { ["creationDate" "title"] }
def direction-completer [] { ["asc" "desc"] }
def privacy-completer [] { ["private"] }
def sort-completer-1 [] { ["creationDate" "modificationDate" "title"] }
def source-completer [] { ["clever" "googleClassroom" "microsoftGraph"] }
def role-completer [] { ["admin" "teacher" "user"] }
def organization-role-completer [] { ["admin" "billing" "teacher" "user"] }
def lms-completer [] { ["blackboard" "canvas" "desire2learn" "moodle" "other" "sakai" "schoolbox" "schoology"] }
def locale-completer [] { ["de" "en" "en-GB" "es" "fr" "it" "ja" "ko" "nl" "pl" "pt" "pt-BR" "ro" "ru" "sv" "tr" "zh-Hans"] }
def data-encoding-completer [] { ["base64"] }
def privacy-completer-1 [] { ["organizationPublic" "private" "privateLink" "public"] }
def creation-type-completer [] { ["arrangement" "original" "other"] }
def license-completer [] { ["cc-by" "cc-by-nc" "cc-by-nc-nd" "cc-by-nc-sa" "cc-by-nd" "cc-by-sa" "cc0" "copyright"] }
def type-completer-1 [] { ["document" "inline"] }
def sort-completer-2 [] { ["date"] }
def format-completer [] { ["json" "midi" "mp3" "mxl" "synchronizationPoints" "thumbnail.png" "wav" "xml"] }
def accept-completer [] { ["application/json" "application/vnd.recordare.musicxml" "application/vnd.recordare.musicxml+xml" "audio/midi" "audio/mp3" "audio/wav" "image/png"] }
def state-completer-2 [] { ["completed" "deleted" "draft"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-classes: "table<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    create-class: "record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    enroll-class: "record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    get-class: "record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    update-class: "record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    activate-class: "record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    unarchive-class: "record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    archive-class: "record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>"
    list-assignments: "table<attachments: list<record>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list, id: string, state: string>, scheduledDate: string, state: string, submissions: list<record>, title: string, type: string>"
    create-assignment: "record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>"
    unarchive-assignment: "record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>"
    archive-assignment: "record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>"
    copy-assignment: "record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>"
    get-submissions: "table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>"
    create-submission: "record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>"
    export-submissions-reviews-as-csv: "binary"
    export-submissions-reviews-as-excel: "binary"
    get-submission: "record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>"
    edit-submission: "record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>"
    get-submission-comments: "table<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string>"
    post-submission-comment: "record<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string>"
    update-submission-comment: "record<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string>"
    get-submission-history: "table<attachment: record<revision: string, score: string>, date: string, draftGrade: float, grade: float, maxPoints: float, state: string, users: list<string>>"
    list-class-student-submissions: "table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>"
    list-collections: "table<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: list<record>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>"
    create-collection: "record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>"
    get-collection: "record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>"
    edit-collection: "record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>"
    list-collection-scores: "table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    add-score-to-collection: "record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    get-group-details: "record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>"
    get-group-scores: "table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    list-group-users: "table<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>"
    get-authenticated-user: "record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string, coverPictureFile: string, locale: string, pictureFile: string, privateProfile: bool>"
    list-organization-invitations: "table<customCode: string, email: string, id: string, invitedBy: string, organization: string, organizationRole: string, usedBy: string>"
    create-organization-invitation: "record<customCode: string, email: string, id: string, invitedBy: string, organization: string, organizationRole: string, usedBy: string>"
    list-lti-credentials: "table<consumerKey: string, consumerSecret: string, creationDate: string, creator: string, id: string, lastUsage: string, lms: string, name: string, organization: string>"
    create-lti-credentials: "record<consumerKey: string, consumerSecret: string, creationDate: string, creator: string, id: string, lastUsage: string, lms: string, name: string, organization: string>"
    list-organization-users: "table<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>>"
    create-organization-user: "record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>>"
    count-orga-users: "int"
    update-organization-user: "record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>>"
    create-score: "record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    get-score: "record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    edit-score: "record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    get-score-collaborators: "table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string>"
    add-score-collaborator: "record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string>"
    get-score-collaborator: "record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string>"
    get-score-comments: "table<comment: string, context: record<measureUuids: list, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string>"
    post-score-comment: "record<comment: string, context: record<measureUuids: list<string>, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string>"
    update-score-comment: "record<comment: string, context: record<measureUuids: list<string>, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string>"
    fork-score: "record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    get-score-revisions: "table<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string>"
    create-score-revision: "record<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string>"
    get-score-revision: "record<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string>"
    get-score-revision-data: "binary"
    get-score-submissions: "table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>"
    list-score-tracks: "table<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: list<record>, title: string, type: string, url: string>"
    add-score-track: "record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string>"
    get-score-track: "record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string>"
    update-score-track: "record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string>"
    get-user: "record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>"
    ger-user-likes: "table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
    get-user-scores: "table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-classes" "create-class" "enroll-class" "get-class" "update-class" "activate-class" "unarchive-class" "archive-class" "list-assignments" "create-assignment" "unarchive-assignment" "archive-assignment" "copy-assignment" "get-submissions" "create-submission" "export-submissions-reviews-as-csv" "export-submissions-reviews-as-excel" "delete-submission" "get-submission" "edit-submission" "get-submission-comments" "post-submission-comment" "delete-submission-comment" "update-submission-comment" "get-submission-history" "list-class-student-submissions" "delete-class-user" "add-class-user" "list-collections" "create-collection" "delete-collection" "get-collection" "edit-collection" "list-collection-scores" "delete-score-from-collection" "add-score-to-collection" "untrash-collection" "get-group-details" "get-group-scores" "list-group-users" "get-authenticated-user" "list-organization-invitations" "create-organization-invitation" "remove-organization-invitation" "list-lti-credentials" "create-lti-credentials" "revoke-lti-credentials" "list-organization-users" "create-organization-user" "count-orga-users" "remove-organization-user" "update-organization-user" "create-score" "delete-score" "get-score" "edit-score" "get-score-collaborators" "add-score-collaborator" "remove-score-collaborator" "get-score-collaborator" "get-score-comments" "post-score-comment" "delete-score-comment" "update-score-comment" "mark-score-comment-unresolved" "mark-score-comment-resolved" "fork-score" "get-score-revisions" "create-score-revision" "get-score-revision" "get-score-revision-data" "get-score-submissions" "list-score-tracks" "add-score-track" "delete-score-track" "get-score-track" "update-score-track" "untrash-score" "get-user" "ger-user-likes" "get-user-scores" "commands"] | sort) } | get name | first)
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

# List the classes available for the current user
#
# GET /classes
# Returns: table<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: listClasses
export def "list-classes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Filter the classes by state (default: active)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classes"
    query: [{name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new class
#
# POST /classes
# Returns: record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: createClass
export def "create-class" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new class
  --section: string # The section of the new class
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/classes"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: section, var: section}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, section: $section
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Join a class
#
# POST /classes/enroll/{enrollmentCode}
# Returns: record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: enrollClass
export def "enroll-class" [
  enrollment_code: string
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
    method: post
    path: "/classes/enroll/{enrollmentCode}"
    path_params: [{name: enrollmentCode, var: enrollment_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    enrollment_code: $enrollment_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of a single class
#
# GET /classes/{class}
# Returns: record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: getClass
export def "get-class" [
  class: string
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
    path: "/classes/{class}"
    path_params: [{name: class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the class
#
# PUT /classes/{class}
# Returns: record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: updateClass
export def "update-class" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the class
  --section: string # The section of the class
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/classes/{class}"
    path_params: [{name: class, var: class}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: section, var: section}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, name: $name, section: $section
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate the class
#
# POST /classes/{class}/activate
# Returns: record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: activateClass
export def "activate-class" [
  class: string
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
    method: post
    path: "/classes/{class}/activate"
    path_params: [{name: class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive the class
#
# DELETE /classes/{class}/archive
# Returns: record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: unarchiveClass
export def "unarchive-class" [
  class: string
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
    method: delete
    path: "/classes/{class}/archive"
    path_params: [{name: class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive the class
#
# POST /classes/{class}/archive
# Returns: record<assignmentsCount: float, canvas: record<domain: string, id: string>, clever: record<creationDate: string, id: string, modificationDate: string, subject: string, termEndDate: string, termName: string, termStartDate: string>, creationDate: string, description: string, enrollmentCode: string, googleClassroom: record<alternateLink: string, id: string>, googleDrive: record<teacherFolderAlternateLink: string, teacherFolderId: string>, id: string, issues: record<sync: list<record>>, lti: record<contextId: string, contextLabel: string, contextTitle: string>, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<id: string>, name: string, organization: string, owner: string, section: string, state: string, studentsGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, teachersGroup: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, theme: string>
# operationId: archiveClass
export def "archive-class" [
  class: string
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
    method: post
    path: "/classes/{class}/archive"
    path_params: [{name: class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assignments listing
#
# GET /classes/{class}/assignments
# Returns: table<attachments: list<record>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list, id: string, state: string>, scheduledDate: string, state: string, submissions: list<record>, title: string, type: string>
# operationId: listAssignments
export def "list-assignments" [
  class: string
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
    path: "/classes/{class}/assignments"
    path_params: [{name: class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assignment creation
#
# POST /classes/{class}/assignments
# Returns: record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>
# operationId: createAssignment
export def "create-assignment" [
  class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assigned-students: list<string> # Identifiers for the students that have access to the assignment
  --assignee-mode: string@assignee-mode-completer # Possible modes of assigning assignments
  --attachments: list # item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
  --cover: string # The URL of the cover to display (nullable)
  --cover-file: string # The id of the cover to display (nullable)
  --description: string # Description and content of the assignment
  --due-date: string # The due date of this assignment, late submissions will be marked as paste due. If not set, the assignment won't have a due date. (nullable, format: date-time)
  --google-classroom: record # Google Classroom options for this assignment — shape: {topicId?: string}
  --max-points: float # If set, the grading will be enabled for the assignement with this value as the maximum of points (nullable)
  --microsoft-graph: record # Microsoft Graph options for this assignment — shape: {categories?: list<string>}
  --nb-playback-authorized: float # The number of playback authorized on the scores of the assignment. (nullable)
  --scheduled-date: string # The publication (scheduled) date of the assignment. If this one is specified, the assignment will only be listed to the teachers of the class. (nullable, format: date-time)
  --state: string@state-completer-1 # State of the assignment
  --title: string # Title of the assignment
  --toolset: string # The id of the associated toolset (nullable)
  --type: string@type-completer # Type of the assignment
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/classes/{class}/assignments"
    path_params: [{name: class, var: class}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignedStudents, var: assigned_students}, {name: assigneeMode, var: assignee_mode}, {name: attachments, var: attachments}, {name: cover, var: cover}, {name: coverFile, var: cover_file}, {name: description, var: description}, {name: dueDate, var: due_date}, {name: googleClassroom, var: google_classroom}, {name: maxPoints, var: max_points}, {name: microsoftGraph, var: microsoft_graph}, {name: nbPlaybackAuthorized, var: nb_playback_authorized}, {name: scheduledDate, var: scheduled_date}, {name: state, var: state}, {name: title, var: title}, {name: toolset, var: toolset}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assigned_students: $assigned_students, assignee_mode: $assignee_mode, attachments: $attachments, cover: $cover, cover_file: $cover_file, description: $description, due_date: $due_date, google_classroom: $google_classroom, max_points: $max_points, microsoft_graph: $microsoft_graph, nb_playback_authorized: $nb_playback_authorized, scheduled_date: $scheduled_date, state: $state, title: $title, toolset: $toolset, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive the assignment.
#
# DELETE /classes/{class}/assignments/{assignment}/archive
# Returns: record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>
# operationId: unarchiveAssignment
export def "unarchive-assignment" [
  class: string
  assignment: string
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
    method: delete
    path: "/classes/{class}/assignments/{assignment}/archive"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive the assignment
#
# POST /classes/{class}/assignments/{assignment}/archive
# Returns: record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>
# operationId: archiveAssignment
export def "archive-assignment" [
  class: string
  assignment: string
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
    method: post
    path: "/classes/{class}/assignments/{assignment}/archive"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy an assignment
#
# POST /classes/{class}/assignments/{assignment}/copy
# Returns: record<attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, canvas: record<alternateLink: string, id: string>, classroom: string, cover: string, coverFile: string, creationDate: string, creator: string, description: string, dueDate: string, googleClassroom: record<alternateLink: string, id: string, state: string, topicId: string>, lti: record<id: string>, maxPoints: float, mfc: record<alternateLink: string, id: string>, microsoftGraph: record<alternateLink: string, categories: list<string>, id: string, state: string>, scheduledDate: string, state: string, submissions: table<assignment: string, attachments: list, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record, grade: float, id: string, maxPoints: float, microsoftGraph: record, returnCreator: string, returnDate: string, state: string, submissionDate: string>, title: string, type: string>
# operationId: copyAssignment
export def "copy-assignment" [
  class: string
  assignment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-assignment: string # An optional destination assignment where the original assignement will be copied. Must be a draft. (spec name: assignment)
  --classroom: string # The destination classroom where the assignment will be copied
  --scheduled-date: string # The publication (scheduled) date of the assignment. If this one is specified, the assignment will only be listed to the teachers of the class. Alternatively the existing `scheduledDate` from the copied assignment will be used. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/classes/{class}/assignments/{assignment}/copy"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignment, var: body_assignment}, {name: classroom, var: classroom}, {name: scheduledDate, var: scheduled_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, body_assignment: $body_assignment, classroom: $classroom, scheduled_date: $scheduled_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the students' submissions
#
# GET /classes/{class}/assignments/{assignment}/submissions
# Returns: table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>
# operationId: getSubmissions
export def "get-submissions" [
  class: string
  assignment: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or edit a submission
#
# PUT /classes/{class}/assignments/{assignment}/submissions
# Returns: record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>
# operationId: createSubmission
export def "create-submission" [
  class: string
  assignment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
  --comments: record # shape: {total?: float, unread?: float}
  --draft-grade: float # Optional grade. If unset, no grade was set. This value is only visible by the teacher, and we will be set to `grade` once the teacher returns the submission (nullable)
  --grade: float # Optional grade. If unset, no grade was set. (nullable)
  --return: oneof<nothing, bool> # If `true`, the submission will be marked as done
  --submit: oneof<nothing, bool> # If `true`, the submission will be marked as done
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/classes/{class}/assignments/{assignment}/submissions"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: comments, var: comments}, {name: draftGrade, var: draft_grade}, {name: grade, var: grade}, {name: return, var: return}, {name: submit, var: submit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, attachments: $attachments, comments: $comments, draft_grade: $draft_grade, grade: $grade, return: $return, submit: $submit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CSV Grades exports
#
# GET /classes/{class}/assignments/{assignment}/submissions/csv
# Returns: binary
# operationId: exportSubmissionsReviewsAsCsv
export def "export-submissions-reviews-as-csv" [
  class: string
  assignment: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions/csv"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}]
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Excel Grades exports
#
# GET /classes/{class}/assignments/{assignment}/submissions/excel
# Returns: binary
# operationId: exportSubmissionsReviewsAsExcel
export def "export-submissions-reviews-as-excel" [
  class: string
  assignment: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions/excel"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}]
    accept: ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a submission
#
# DELETE /classes/{class}/assignments/{assignment}/submissions/{submission}
# operationId: deleteSubmission
export def "delete-submission" [
  class: string
  assignment: string
  submission: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a student submission
#
# GET /classes/{class}/assignments/{assignment}/submissions/{submission}
# Returns: record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>
# operationId: getSubmission
export def "get-submission" [
  class: string
  assignment: string
  submission: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a submission
#
# PUT /classes/{class}/assignments/{assignment}/submissions/{submission}
# Returns: record<assignment: string, attachments: table<authorName: string, authorUrl: string, description: string, googleDriveFileId: string, html: string, htmlHeight: string, htmlWidth: string, iconUrl: string, lockScoreTemplate: bool, mimeType: string, revision: string, score: string, sharingMode: string, thumbnailHeight: int, thumbnailUrl: string, thumbnailWidth: int, title: string, track: string, type: string, url: string, worksheet: string>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>
# operationId: editSubmission
export def "edit-submission" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # item shape: {googleDriveFileId?: string, lockScoreTemplate?: bool, score?: string, sharingMode?: "read"|"write"|"copy"|"performance", type?: "flat"|"link"|"googleDrive"|"worksheet", url?: string, worksheet?: string}
  --comments: record # shape: {total?: float, unread?: float}
  --draft-grade: float # Optional grade. If unset, no grade was set. This value is only visible by the teacher, and we will be set to `grade` once the teacher returns the submission (nullable)
  --grade: float # Optional grade. If unset, no grade was set. (nullable)
  --return: oneof<nothing, bool> # If `true`, the submission will be marked as done
  --submit: oneof<nothing, bool> # If `true`, the submission will be marked as done
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: comments, var: comments}, {name: draftGrade, var: draft_grade}, {name: grade, var: grade}, {name: return, var: return}, {name: submit, var: submit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission, attachments: $attachments, comments: $comments, draft_grade: $draft_grade, grade: $grade, return: $return, submit: $submit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the feedback comments of a submission
#
# GET /classes/{class}/assignments/{assignment}/submissions/{submission}/comments
# Returns: table<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string>
# operationId: getSubmissionComments
export def "get-submission-comments" [
  class: string
  assignment: string
  submission: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}/comments"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a feedback comment to a submission
#
# POST /classes/{class}/assignments/{assignment}/submissions/{submission}/comments
# Returns: record<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string>
# operationId: postSubmissionComment
export def "post-submission-comment" [
  class: string
  assignment: string
  submission: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  comment: string # The comment text
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}/comments"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a feedback comment to a submission
#
# DELETE /classes/{class}/assignments/{assignment}/submissions/{submission}/comments/{comment}
# operationId: deleteSubmissionComment
export def "delete-submission-comment" [
  class: string
  assignment: string
  submission: string
  comment: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}/comments/{comment}"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}, {name: comment, var: comment}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a feedback comment to a submission
#
# PUT /classes/{class}/assignments/{assignment}/submissions/{submission}/comments/{comment}
# Returns: record<comment: string, date: string, id: string, modificationDate: string, submission: string, unread: bool, user: string>
# operationId: updateSubmissionComment
export def "update-submission-comment" [
  class: string
  assignment: string
  submission: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-comment: string # The comment text (spec name: comment)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}/comments/{comment}"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}, {name: comment, var: comment}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: body_comment, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission, comment: $comment, body_comment: $body_comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the history of the submission
#
# GET /classes/{class}/assignments/{assignment}/submissions/{submission}/history
# Returns: table<attachment: record<revision: string, score: string>, date: string, draftGrade: float, grade: float, maxPoints: float, state: string, users: list<string>>
# operationId: getSubmissionHistory
export def "get-submission-history" [
  class: string
  assignment: string
  submission: string
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
    path: "/classes/{class}/assignments/{assignment}/submissions/{submission}/history"
    path_params: [{name: class, var: class}, {name: assignment, var: assignment}, {name: submission, var: submission}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, assignment: $assignment, submission: $submission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the submissions for a student
#
# GET /classes/{class}/students/{user}/submissions
# Returns: table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>
# operationId: listClassStudentSubmissions
export def "list-class-student-submissions" [
  class: string
  user: string
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
    path: "/classes/{class}/students/{user}/submissions"
    path_params: [{name: class, var: class}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    class: $class, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user from the class
#
# DELETE /classes/{class}/users/{user}
# operationId: deleteClassUser
export def "delete-class-user" [
  class: string
  user: string
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
    path: "/classes/{class}/users/{user}"
    path_params: [{name: class, var: class}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    class: $class, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user to the class
#
# PUT /classes/{class}/users/{user}
# operationId: addClassUser
export def "add-class-user" [
  class: string
  user: string
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
    path: "/classes/{class}/users/{user}"
    path_params: [{name: class, var: class}, {name: user, var: user}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    class: $class, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the collections
#
# GET /collections
# Returns: table<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: list<record>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>
# operationId: listCollections
export def "list-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: string # List the collection contained in this `parent` collection. This option doesn't provide a complete multi-level collection support. When sharing a collection with someone, this one will have as `parent` `sharedWithMe`. (default: root)
  --sort: string@sort-completer # Sort
  --direction: string@direction-completer # Sort direction
  --limit: int # This is the maximum number of objects that may be returned (default: 25)
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/collections"
    query: [{name: parent, var: parent}, {name: sort, var: sort}, {name: direction, var: direction}, {name: limit, var: limit}, {name: next, var: next}, {name: previous, var: previous}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, sort: $sort, direction: $direction, limit: $limit, next: $next, previous: $previous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new collection
#
# POST /collections
# Returns: record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>
# operationId: createCollection
export def "create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  privacy: string@privacy-completer # The collection main privacy mode. - `private`: The collection is private and can be only accessed, modified and administred by specified collaborators users.
  title: string # The title of the collection
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collections"
    body: {content_type: "application/json", kind: json, fields: [{name: privacy, var: privacy}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    privacy: $privacy, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the collection
#
# DELETE /collections/{collection}
# operationId: deleteCollection
export def "delete-collection" [
  collection: string
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
    path: "/collections/{collection}"
    path_params: [{name: collection, var: collection}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection: $collection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get collection details
#
# GET /collections/{collection}
# Returns: record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>
# operationId: getCollection
export def "get-collection" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collections/{collection}"
    path_params: [{name: collection, var: collection}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection: $collection, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a collection's metadata
#
# PUT /collections/{collection}
# Returns: record<app: string, capabilities: record<canAddScores: bool, canDelete: bool, canDeleteScores: bool, canEdit: bool, canShare: bool>, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, creationDate: string, htmlUrl: string, id: string, privacy: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, sharingKey: string, title: string, type: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>>
# operationId: editCollection
export def "edit-collection" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --privacy: string@privacy-completer # The collection main privacy mode. - `private`: The collection is private and can be only accessed, modified and administred by specified collaborators users.
  --title: string # The title of the collection
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/collections/{collection}"
    path_params: [{name: collection, var: collection}]
    body: {content_type: "application/json", kind: json, fields: [{name: privacy, var: privacy}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection: $collection, privacy: $privacy, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the scores contained in a collection
#
# GET /collections/{collection}/scores
# Returns: table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: listCollectionScores
export def "list-collection-scores" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --sort: string@sort-completer-1 # Sort
  --direction: string@direction-completer # Sort direction
  --limit: int # This is the maximum number of objects that may be returned (default: 25)
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/collections/{collection}/scores"
    path_params: [{name: collection, var: collection}]
    query: [{name: sharingKey, var: sharing_key}, {name: sort, var: sort}, {name: direction, var: direction}, {name: limit, var: limit}, {name: next, var: next}, {name: previous, var: previous}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection: $collection, sharing_key: $sharing_key, sort: $sort, direction: $direction, limit: $limit, next: $next, previous: $previous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a score from the collection
#
# DELETE /collections/{collection}/scores/{score}
# operationId: deleteScoreFromCollection
export def "delete-score-from-collection" [
  collection: string
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> any {
  http-request {
    method: delete
    path: "/collections/{collection}/scores/{score}"
    path_params: [{name: collection, var: collection}, {name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection: $collection, score: $score, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a score to the collection
#
# PUT /collections/{collection}/scores/{score}
# Returns: record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: addScoreToCollection
export def "add-score-to-collection" [
  collection: string
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/collections/{collection}/scores/{score}"
    path_params: [{name: collection, var: collection}, {name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection: $collection, score: $score, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untrash a collection
#
# POST /collections/{collection}/untrash
# operationId: untrashCollection
export def "untrash-collection" [
  collection: string
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
    path: "/collections/{collection}/untrash"
    path_params: [{name: collection, var: collection}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collection: $collection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group information
#
# GET /groups/{group}
# Returns: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>
# operationId: getGroupDetails
export def "get-group-details" [
  group: string
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
    path: "/groups/{group}"
    path_params: [{name: group, var: group}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List group's scores
#
# GET /groups/{group}/scores
# Returns: table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: getGroupScores
export def "get-group-scores" [
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: string # Filter the score forked from the score id `parent`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group}/scores"
    path_params: [{name: group, var: group}]
    query: [{name: parent, var: parent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group: $group, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List group's users
#
# GET /groups/{group}/users
# Returns: table<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>
# operationId: listGroupUsers
export def "list-group-users" [
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string@source-completer # Filter the users by their source
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group}/users"
    path_params: [{name: group, var: group}]
    query: [{name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group: $group, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current user profile
#
# GET /me
# Returns: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string, coverPictureFile: string, locale: string, pictureFile: string, privateProfile: bool>
# operationId: getAuthenticatedUser
export def "get-authenticated-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --only-id: oneof<nothing, bool> # Only return the user id (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me"
    query: [{name: onlyId, var: only_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    only_id: $only_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the organization invitations
#
# GET /organizations/invitations
# Returns: table<customCode: string, email: string, id: string, invitedBy: string, organization: string, organizationRole: string, usedBy: string>
# operationId: listOrganizationInvitations
export def "list-organization-invitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # Filter users by role
  --limit: int # This is the maximum number of objects that may be returned (default: 50)
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/invitations"
    query: [{name: role, var: role}, {name: limit, var: limit}, {name: next, var: next}, {name: previous, var: previous}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role: $role, limit: $limit, next: $next, previous: $previous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new invitation to join the organization
#
# POST /organizations/invitations
# Returns: record<customCode: string, email: string, id: string, invitedBy: string, organization: string, organizationRole: string, usedBy: string>
# operationId: createOrganizationInvitation
export def "create-organization-invitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address you want to send the invitation to
  --organization-role: string@organization-role-completer # User's Organization Role (for Edu users only)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/invitations"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: organizationRole, var: organization_role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, organization_role: $organization_role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an organization invitation
#
# DELETE /organizations/invitations/{invitation}
# operationId: removeOrganizationInvitation
export def "remove-organization-invitation" [
  invitation: string
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
    path: "/organizations/invitations/{invitation}"
    path_params: [{name: invitation, var: invitation}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    invitation: $invitation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List LTI 1.x credentials
#
# GET /organizations/lti/credentials
# Returns: table<consumerKey: string, consumerSecret: string, creationDate: string, creator: string, id: string, lastUsage: string, lms: string, name: string, organization: string>
# operationId: listLtiCredentials
export def "list-lti-credentials" [
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
    path: "/organizations/lti/credentials"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new couple of LTI 1.x credentials
#
# POST /organizations/lti/credentials
# Returns: record<consumerKey: string, consumerSecret: string, creationDate: string, creator: string, id: string, lastUsage: string, lms: string, name: string, organization: string>
# operationId: createLtiCredentials
export def "create-lti-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  lms: string@lms-completer # LMS name
  name: string # Name of the couple of credentials
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/lti/credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: lms, var: lms}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lms: $lms, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke LTI 1.x credentials
#
# DELETE /organizations/lti/credentials/{credentials}
# operationId: revokeLtiCredentials
export def "revoke-lti-credentials" [
  credentials: string
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
    path: "/organizations/lti/credentials/{credentials}"
    path_params: [{name: credentials, var: credentials}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the organization users
#
# GET /organizations/users
# Returns: table<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>>
# operationId: listOrganizationUsers
export def "list-organization-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # The order to sort the user list
  --direction: string@direction-completer # Sort direction
  --next: string # An opaque string cursor to fetch the next page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --previous: string # An opaque string cursor to fetch the previous page of data. The paginated API URLs are returned in the `Link` header when requesting the API. These URLs will contain a `next` and `previous` cursor based on the available data.
  --role: list<string> # Filter users by role
  --q: string # The query to search
  --group: list<string> # Filter users by group
  --no-active-license: oneof<nothing, bool> # Filter users who don't have an active license
  --license-expiration-date: list<string> # Filter users by license expiration date or `active` / `notActive`
  --only-ids: oneof<nothing, bool> # Return only user ids
  --limit: int # This is the maximum number of objects that may be returned (default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/users"
    query: [{name: sort, var: sort}, {name: direction, var: direction}, {name: next, var: next}, {name: previous, var: previous}, {name: role, var: role, style: multi}, {name: q, var: q}, {name: group, var: group, style: multi}, {name: noActiveLicense, var: no_active_license}, {name: licenseExpirationDate, var: license_expiration_date, style: multi}, {name: onlyIds, var: only_ids}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, direction: $direction, next: $next, previous: $previous, role: $role, q: $q, group: $group, no_active_license: $no_active_license, license_expiration_date: $license_expiration_date, only_ids: $only_ids, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user account
#
# POST /organizations/users
# Returns: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>>
# operationId: createOrganizationUser
export def "create-organization-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email of the new account (format: email)
  --firstname: string # First name of the user
  --lastname: string # Last name of the user
  --locale: string@locale-completer # The user language (default: en)
  password: string # Password of the new account (format: password)
  username: string # Username of the new account
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: locale, var: locale}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, firstname: $firstname, lastname: $lastname, locale: $locale, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count the organization users using the provided filters
#
# GET /organizations/users/count
# Returns: int
# operationId: countOrgaUsers
export def "count-orga-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: list<string> # Filter users by role
  --q: string # The query to search
  --group: list<string> # Filter users by group
  --no-active-license: oneof<nothing, bool> # Filter users who don't have an active license
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/users/count"
    query: [{name: role, var: role, style: multi}, {name: q, var: q}, {name: group, var: group, style: multi}, {name: noActiveLicense, var: no_active_license}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role: $role, q: $q, group: $group, no_active_license: $no_active_license
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an account from Flat
#
# DELETE /organizations/users/{user}
# operationId: removeOrganizationUser
export def "remove-organization-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --convert-to-individual: oneof<nothing, bool> # If `true`, the account will be only removed from the organization and converted into an individual account on our public website, https://flat.io. This operation will remove the education-related data from the account. Before realizing this operation, you need to be sure that the user is at least 13 years old and that this one has read and agreed to the Individual Terms of Services of Flat available on https://flat.io/legal.
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/users/{user}"
    path_params: [{name: user, var: user}]
    query: [{name: convertToIndividual, var: convert_to_individual}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user: $user, convert_to_individual: $convert_to_individual
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update account information
#
# PUT /organizations/users/{user}
# Returns: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, email: string, lastActivityDate: string, license: record<active: bool, expirationDate: string, id: string, mode: string, source: string>>
# operationId: updateOrganizationUser
export def "update-organization-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email of the account (format: email)
  --firstname: string # First name of the user
  --lastname: string # Last name of the user
  --organization-role: string@organization-role-completer # User's Organization Role (for Edu users only)
  --password: string # Password of the account (format: password)
  --username: string # Username of the account
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/users/{user}"
    path_params: [{name: user, var: user}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: organizationRole, var: organization_role}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, email: $email, firstname: $firstname, lastname: $lastname, organization_role: $organization_role, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new score
#
# POST /scores
# Returns: record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: createScore
export def "create-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection: string # Unique identifier of a collection where the score will be created. If no collection identifier is provided, the score will be stored in the `root` directory.
  --data: string # The data of the score file. It must be a MusicXML 3 file (`vnd.recordare.musicxml` or `vnd.recordare.musicxml+xml`), a MIDI file (`audio/midi`) or a Flat.json (aka Adagio.json) file. Binary payloads (`vnd.recordare.musicxml` and `audio/midi`) can be encoded in Base64, in this case the `dataEncoding` property must match the encoding used for the API request. (e.g. <score-partwise version="3.0"></score-partwise>)
  --data-encoding: string@data-encoding-completer # The optional encoding of the score data. This property must match the encoding used for the `data` property.
  --filename: string # If this is an imported file, its filename
  --google-drive-folder: string # If the user uses Google Drive and this properties is specified, the file will be created in this directory. The currently user creating the file must be granted to write in this directory.
  privacy: string@privacy-completer-1 # The score main privacy mode. - `public`: The score is public on the Internet. This one can be accessible at the url `https://flat.io/score/{score}` and can be modified and administred by specified collaborators users. - `private`: The score is private and can be only accessed, modified and administred by specified collaborators users. - `privateLink`: The score is private but can be accessed using a private link `htmlUrl` or the private key in the property `sharingKey`. - `organizationPublic`: _Available only with [Flat for Education](https://flat.io/edu)._ The score is public in the organization: users of the same organization can access to this one. The score can be modified and administred by specified collaborators users. The score can also be individually shared to a set of users or groups using the different collaborators API methods. When a file is synchronized from an external source (e.g. Google Drive) and the sharing options are changed on the source, Flat will chose the best privacy mode for the file. When using a [Flat for Education](https://flat.io/edu) account, some of the modes may not be available if disabled by an administrator of the organization (e.g. by default the `public` mode is not available).
  --source: record # e.g. {googleDrive: 0B-0000000000000001} — shape: {googleDrive?: string}
  --title: string # The title of the new score. If the title is too long, the API may trim this one. If this title is not specified, the API will try to (in this order): - Use the title contained in the file (e.g. [`movement-title`](https://usermanuals.musicxml.com/MusicXML/Content/EL-MusicXML-movement-title.htm) or [`credit-words`](https://usermanuals.musicxml.com/MusicXML/Content/EL-MusicXML-credit-words.htm) for [MusicXML](http://www.musicxml.com/) files). - Use the name of the file for files from a specified `source` (e.g. Google Drive) or the one in the `filename` property - Set a default title (e.g. "New Music Score")
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scores"
    body: {content_type: "application/json", kind: json, fields: [{name: collection, var: collection}, {name: data, var: data}, {name: dataEncoding, var: data_encoding}, {name: filename, var: filename}, {name: googleDriveFolder, var: google_drive_folder}, {name: privacy, var: privacy}, {name: source, var: source}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection: $collection, data: $data, data_encoding: $data_encoding, filename: $filename, google_drive_folder: $google_drive_folder, privacy: $privacy, source: $source, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a score
#
# DELETE /scores/{score}
# operationId: deleteScore
export def "delete-score" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --now: oneof<nothing, bool> # If `true`, the score deletion will be scheduled to be done ASAP (default: false)
]: nothing -> any {
  http-request {
    method: delete
    path: "/scores/{score}"
    path_params: [{name: score, var: score}]
    query: [{name: now, var: now}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    score: $score, now: $now
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a score's metadata
#
# GET /scores/{score}
# Returns: record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: getScore
export def "get-score" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}"
    path_params: [{name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a score's metadata
#
# PUT /scores/{score}
# Returns: record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: editScore
export def "edit-score" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arranger: string # The arranger of the score
  --composer: string # The composer of the score
  --creation-type: string@creation-type-completer # The type of creation (an orginal, an arrangement)
  --description: string # Description of the creation
  --license: string@license-completer # License of the creation. Read more about the Creative Commons licenses on https://creativecommons.org/licenses/
  --license-text: string # The rights info written on the score
  --lyricist: string # The lyricist of the score
  --privacy: string@privacy-completer-1 # The score main privacy mode. - `public`: The score is public on the Internet. This one can be accessible at the url `https://flat.io/score/{score}` and can be modified and administred by specified collaborators users. - `private`: The score is private and can be only accessed, modified and administred by specified collaborators users. - `privateLink`: The score is private but can be accessed using a private link `htmlUrl` or the private key in the property `sharingKey`. - `organizationPublic`: _Available only with [Flat for Education](https://flat.io/edu)._ The score is public in the organization: users of the same organization can access to this one. The score can be modified and administred by specified collaborators users. The score can also be individually shared to a set of users or groups using the different collaborators API methods. When a file is synchronized from an external source (e.g. Google Drive) and the sharing options are changed on the source, Flat will chose the best privacy mode for the file. When using a [Flat for Education](https://flat.io/edu) account, some of the modes may not be available if disabled by an administrator of the organization (e.g. by default the `public` mode is not available).
  --sharing-key: string # When using the `privacy` mode `privateLink`, this property can be used to set a custom sharing key, otherwise a new key will be generated.
  --subtitle: string # The subtitle of the score
  --tags: list<string> # Tags describing the score
  --title: string # The title of the score
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/scores/{score}"
    path_params: [{name: score, var: score}]
    body: {content_type: "application/json", kind: json, fields: [{name: arranger, var: arranger}, {name: composer, var: composer}, {name: creationType, var: creation_type}, {name: description, var: description}, {name: license, var: license}, {name: licenseText, var: license_text}, {name: lyricist, var: lyricist}, {name: privacy, var: privacy}, {name: sharingKey, var: sharing_key}, {name: subtitle, var: subtitle}, {name: tags, var: tags}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, arranger: $arranger, composer: $composer, creation_type: $creation_type, description: $description, license: $license, license_text: $license_text, lyricist: $lyricist, privacy: $privacy, sharing_key: $sharing_key, subtitle: $subtitle, tags: $tags, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the collaborators
#
# GET /scores/{score}/collaborators
# Returns: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string>
# operationId: getScoreCollaborators
export def "get-score-collaborators" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}/collaborators"
    path_params: [{name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new collaborator
#
# POST /scores/{score}/collaborators
# Returns: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string>
# operationId: addScoreCollaborator
export def "add-score-collaborator" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl-admin: oneof<nothing, bool> # `True` if the related user can can manage the current document, i.e. changing the document permissions and deleting the document (default: false)
  --acl-read: oneof<nothing, bool> # `True` if the related user can read the score. (probably true if the user has a permission on the document). (default: true)
  --acl-write: oneof<nothing, bool> # `True` if the related user can modify the score. (default: false)
  --group: string # The unique identifier of a Flat group
  --user: string # The unique identifier of a Flat user
  --user-email: string # Fill this field to invite an individual user by email.
  --user-token: string # Token received in an invitation to join the score.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scores/{score}/collaborators"
    path_params: [{name: score, var: score}]
    body: {content_type: "application/json", kind: json, fields: [{name: aclAdmin, var: acl_admin}, {name: aclRead, var: acl_read}, {name: aclWrite, var: acl_write}, {name: group, var: group}, {name: user, var: user}, {name: userEmail, var: user_email}, {name: userToken, var: user_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, acl_admin: $acl_admin, acl_read: $acl_read, acl_write: $acl_write, group: $group, user: $user, user_email: $user_email, user_token: $user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a collaborator
#
# DELETE /scores/{score}/collaborators/{collaborator}
# operationId: removeScoreCollaborator
export def "remove-score-collaborator" [
  score: string
  collaborator: string
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
    path: "/scores/{score}/collaborators/{collaborator}"
    path_params: [{name: score, var: score}, {name: collaborator, var: collaborator}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    score: $score, collaborator: $collaborator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a collaborator
#
# GET /scores/{score}/collaborators/{collaborator}
# Returns: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record<creationDate: string, id: string, name: string, organization: string, readOnly: bool, type: string, usersCount: float>, id: string, invited: bool, score: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>, userEmail: string>
# operationId: getScoreCollaborator
export def "get-score-collaborator" [
  score: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}/collaborators/{collaborator}"
    path_params: [{name: score, var: score}, {name: collaborator, var: collaborator}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, collaborator: $collaborator, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List comments
#
# GET /scores/{score}/comments
# Returns: table<comment: string, context: record<measureUuids: list, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string>
# operationId: getScoreComments
export def "get-score-comments" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --type: string@type-completer-1 # Filter the comments by type
  --sort: string@sort-completer-2 # Sort
  --direction: string@direction-completer # Sort direction
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}/comments"
    path_params: [{name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}, {name: type, var: type}, {name: sort, var: sort}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, sharing_key: $sharing_key, type: $type, sort: $sort, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a new comment
#
# POST /scores/{score}/comments
# Returns: record<comment: string, context: record<measureUuids: list<string>, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string>
# operationId: postScoreComment
export def "post-score-comment" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  comment: string # The comment text that can includes mentions using the following format: `@[id:username]`.
  --context: record # The context of the comment (for inline/contextualized comments). A context will include all the information related to the location of the comment (i.e. score parts, range of measure, time position). (e.g. {measureUuids: [e6a6a60b-8710-f819-9a49-e907b19c6f1f, da83d93c-e3a6-3c73-1bbe-15e5131d6437, 056ec5eb-9213-df56-6ae8-d9b99673dc48], partUuid: 91982db7-2e6d-285e-7a19-76b4bd005b8b, staffUuid: 9395d8f3-f42b-47b6-8c5d-6ba704961ec0, startDpq: 1, startTimePos: 2, stopDpq: 1, stopTimePos: 3}) — shape: {measureUuids: list<string>, partUuid: string, staffIdx?: float, staffUuid?: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float}
  --mentions: list<string> # The list of user identifiers mentioned in this comment
  --raw-comment: string # A raw version of the comment, that can be displayed without the mentions. If you use mentions, this property must be set.
  --reply-to: string # When the comment is a reply to another comment, the unique identifier of the parent comment
  --revision: string # The unique indentifier of the revision of the score where the comment was added. If this property is unspecified or contains "last", the API will automatically take the last revision created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scores/{score}/comments"
    path_params: [{name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: context, var: context}, {name: mentions, var: mentions}, {name: rawComment, var: raw_comment}, {name: replyTo, var: reply_to}, {name: revision, var: revision}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, sharing_key: $sharing_key, comment: $comment, context: $context, mentions: $mentions, raw_comment: $raw_comment, reply_to: $reply_to, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment
#
# DELETE /scores/{score}/comments/{comment}
# operationId: deleteScoreComment
export def "delete-score-comment" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> any {
  http-request {
    method: delete
    path: "/scores/{score}/comments/{comment}"
    path_params: [{name: score, var: score}, {name: comment, var: comment}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    score: $score, comment: $comment, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing comment
#
# PUT /scores/{score}/comments/{comment}
# Returns: record<comment: string, context: record<measureUuids: list<string>, partUuid: string, staffIdx: float, staffUuid: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float>, date: string, id: string, mentions: list<string>, modificationDate: string, rawComment: string, replyTo: string, resolved: bool, resolvedBy: string, revision: string, score: string, spam: bool, type: string, user: string>
# operationId: updateScoreComment
export def "update-score-comment" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --body-comment: string # The comment text that can includes mentions using the following format: `@[id:username]`. (spec name: comment)
  --context: record # The context of the comment (for inline/contextualized comments). A context will include all the information related to the location of the comment (i.e. score parts, range of measure, time position). (e.g. {measureUuids: [e6a6a60b-8710-f819-9a49-e907b19c6f1f, da83d93c-e3a6-3c73-1bbe-15e5131d6437, 056ec5eb-9213-df56-6ae8-d9b99673dc48], partUuid: 91982db7-2e6d-285e-7a19-76b4bd005b8b, staffUuid: 9395d8f3-f42b-47b6-8c5d-6ba704961ec0, startDpq: 1, startTimePos: 2, stopDpq: 1, stopTimePos: 3}) — shape: {measureUuids: list<string>, partUuid: string, staffIdx?: float, staffUuid?: string, startDpq: float, startTimePos: float, stopDpq: float, stopTimePos: float}
  --raw-comment: string # A raw version of the comment, that can be displayed without the mentions. If you use mentions, this property must be set.
  --revision: string # The unique indentifier of the revision of the score where the comment was added. If this property is unspecified or contains "last", the API will automatically take the last revision created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/scores/{score}/comments/{comment}"
    path_params: [{name: score, var: score}, {name: comment, var: comment}]
    query: [{name: sharingKey, var: sharing_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: body_comment}, {name: context, var: context}, {name: rawComment, var: raw_comment}, {name: revision, var: revision}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, comment: $comment, sharing_key: $sharing_key, body_comment: $body_comment, context: $context, raw_comment: $raw_comment, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark the comment as unresolved
#
# DELETE /scores/{score}/comments/{comment}/resolved
# operationId: markScoreCommentUnresolved
export def "mark-score-comment-unresolved" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> any {
  http-request {
    method: delete
    path: "/scores/{score}/comments/{comment}/resolved"
    path_params: [{name: score, var: score}, {name: comment, var: comment}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    score: $score, comment: $comment, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark the comment as resolved
#
# PUT /scores/{score}/comments/{comment}/resolved
# operationId: markScoreCommentResolved
export def "mark-score-comment-resolved" [
  score: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> any {
  http-request {
    method: put
    path: "/scores/{score}/comments/{comment}/resolved"
    path_params: [{name: score, var: score}, {name: comment, var: comment}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    score: $score, comment: $comment, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fork a score
#
# POST /scores/{score}/fork
# Returns: record<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: table<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool, collection: string, group: record, id: string, invited: bool, score: string, user: record, userEmail: string>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: forkScore
export def "fork-score" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --collection: string # Unique identifier of a collection where the score will be copied. If no collection identifier is provided, the score will be stored in the `root` directory. (default: root)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scores/{score}/fork"
    path_params: [{name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: collection, var: collection}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, sharing_key: $sharing_key, collection: $collection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the revisions
#
# GET /scores/{score}/revisions
# Returns: table<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string>
# operationId: getScoreRevisions
export def "get-score-revisions" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}/revisions"
    path_params: [{name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new revision
#
# POST /scores/{score}/revisions
# Returns: record<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string>
# operationId: createScoreRevision
export def "create-score-revision" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autosave: oneof<nothing, bool> # Must be set to `true` if the revision was created automatically.
  data: string # The data of the score file. It must be a MusicXML 3 file (`vnd.recordare.musicxml` or `vnd.recordare.musicxml+xml`), a MIDI file (`audio/midi`) or a Flat.json (aka Adagio.json) file. Binary payloads (`vnd.recordare.musicxml` and `audio/midi`) can be encoded in Base64, in this case the `dataEncoding` property must match the encoding used for the API request. (e.g. <score-partwise version="3.0"></score-partwise>)
  --data-encoding: string@data-encoding-completer # The optional encoding of the score data. This property must match the encoding used for the `data` property.
  --description: string # A description associated to the revision
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scores/{score}/revisions"
    path_params: [{name: score, var: score}]
    body: {content_type: "application/json", kind: json, fields: [{name: autosave, var: autosave}, {name: data, var: data}, {name: dataEncoding, var: data_encoding}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, autosave: $autosave, data: $data, data_encoding: $data_encoding, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a score revision
#
# GET /scores/{score}/revisions/{revision}
# Returns: record<autosave: bool, collaborators: list<string>, creationDate: string, description: string, event: string, id: string, statistics: record<additions: float, deletions: float>, user: string>
# operationId: getScoreRevision
export def "get-score-revision" [
  score: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}/revisions/{revision}"
    path_params: [{name: score, var: score}, {name: revision, var: revision}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, revision: $revision, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a score revision data
#
# GET /scores/{score}/revisions/{revision}/{format}
# Returns: binary
# operationId: getScoreRevisionData
export def "get-score-revision-data" [
  score: string
  revision: string
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --parts: string # An optional a set of parts uuid to be exported. This parameter must be composed of parts uuids separated by commas. For example "59df645f-bb1c-f1b4-b573-d2afc4491f94,34ef645f-1aef-f3bc-1564-34cca4492b87".
  --only-cached: oneof<nothing, bool> # Only return files already generated and cached in Flat's production cache. If the file is not availabe, a 404 will be returned
  --url: oneof<nothing, bool> # Returns a json with the `url` in it instead of redirecting
]: nothing -> any {
  http-request {
    method: get
    path: "/scores/{score}/revisions/{revision}/{format}"
    path_params: [{name: score, var: score}, {name: revision, var: revision}, {name: format, var: format}]
    query: [{name: sharingKey, var: sharing_key}, {name: parts, var: parts}, {name: onlyCached, var: only_cached}, {name: url, var: url}]
    accept: ["application/json", "application/vnd.recordare.musicxml", "application/vnd.recordare.musicxml+xml", "audio/midi", "audio/mp3", "audio/wav", "image/png"]
    ok: [200]
    auth: bearer
  } {
    score: $score, revision: $revision, format: $format, sharing_key: $sharing_key, parts: $parts, only_cached: $only_cached, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List submissions related to the score
#
# GET /scores/{score}/submissions
# Returns: table<assignment: string, attachments: list<record>, classroom: string, creationDate: string, creator: string, draftGrade: float, googleClassroom: record<alternateLink: string, id: string, state: string>, grade: float, id: string, maxPoints: float, microsoftGraph: record<alternateLink: string, id: string, state: string>, returnCreator: string, returnDate: string, state: string, submissionDate: string>
# operationId: getScoreSubmissions
export def "get-score-submissions" [
  score: string
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
    path: "/scores/{score}/submissions"
    path_params: [{name: score, var: score}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the audio or video tracks linked to a score
#
# GET /scores/{score}/tracks
# Returns: table<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: list<record>, title: string, type: string, url: string>
# operationId: listScoreTracks
export def "list-score-tracks" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
  --assignment: string # An assignment id with which all the tracks returned will be related to
  --list-auto-track: oneof<nothing, bool> # If true, and if available, return last automatically synchronized Flat's mp3 export as an additional track
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}/tracks"
    path_params: [{name: score, var: score}]
    query: [{name: sharingKey, var: sharing_key}, {name: assignment, var: assignment}, {name: listAutoTrack, var: list_auto_track}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, sharing_key: $sharing_key, assignment: $assignment, list_auto_track: $list_auto_track
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new video or audio track to the score
#
# POST /scores/{score}/tracks
# Returns: record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string>
# operationId: addScoreTrack
export def "add-score-track" [
  score: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool> # True if the track should be used as default audio source
  --state: string@state-completer-2 # State of the track (default: draft)
  --synchronization-points: list # item shape: {measureUuid?: string, time: float, type: "measure"|"end"}
  --title: string # Title of the track
  --url: string # The URL of the track
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scores/{score}/tracks"
    path_params: [{name: score, var: score}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: state, var: state}, {name: synchronizationPoints, var: synchronization_points}, {name: title, var: title}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, default: $default, state: $state, synchronization_points: $synchronization_points, title: $title, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an audio or video track linked to the score
#
# DELETE /scores/{score}/tracks/{track}
# operationId: deleteScoreTrack
export def "delete-score-track" [
  score: string
  track: string
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
    path: "/scores/{score}/tracks/{track}"
    path_params: [{name: score, var: score}, {name: track, var: track}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    score: $score, track: $track
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the details of an audio or video track linked to a score
#
# GET /scores/{score}/tracks/{track}
# Returns: record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string>
# operationId: getScoreTrack
export def "get-score-track" [
  score: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharing-key: string # This sharing key must be specified to access to a score or collection with a `privacy` mode set to `privateLink` and the current user is not a collaborator of the document.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scores/{score}/tracks/{track}"
    path_params: [{name: score, var: score}, {name: track, var: track}]
    query: [{name: sharingKey, var: sharing_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, track: $track, sharing_key: $sharing_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an audio or video track linked to a score
#
# PUT /scores/{score}/tracks/{track}
# Returns: record<creationDate: string, creator: string, default: bool, id: string, mediaId: string, modificationDate: string, score: string, state: string, synchronizationPoints: table<measureUuid: string, time: float, type: string>, title: string, type: string, url: string>
# operationId: updateScoreTrack
export def "update-score-track" [
  score: string
  track: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool> # True if the track should be used as default audio source
  --state: string@state-completer-2 # State of the track (default: draft)
  --synchronization-points: list # item shape: {measureUuid?: string, time: float, type: "measure"|"end"}
  --title: string # Title of the track
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/scores/{score}/tracks/{track}"
    path_params: [{name: score, var: score}, {name: track, var: track}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: state, var: state}, {name: synchronizationPoints, var: synchronization_points}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    score: $score, track: $track, default: $default, state: $state, synchronization_points: $synchronization_points, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untrash a score
#
# POST /scores/{score}/untrash
# operationId: untrashScore
export def "untrash-score" [
  score: string
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
    path: "/scores/{score}/untrash"
    path_params: [{name: score, var: score}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    score: $score
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a public user profile
#
# GET /users/{user}
# Returns: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string, bio: string, coverPicture: string, followersCount: int, followingCount: int, instruments: list<string>, likedScoresCount: int, ownedPublicScoresCount: int, profileTheme: string, registrationDate: string>
# operationId: getUser
export def "get-user" [
  user: string
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
    path: "/users/{user}"
    path_params: [{name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List liked scores
#
# GET /users/{user}/likes
# Returns: table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: gerUserLikes
export def "ger-user-likes" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: oneof<nothing, bool> # Return only the identifiers of the scores
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user}/likes"
    path_params: [{name: user, var: user}]
    query: [{name: ids, var: ids}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user's scores
#
# GET /users/{user}/scores
# Returns: table<htmlUrl: string, id: string, privacy: string, sharingKey: string, title: string, user: record<firstname: string, id: string, isFlatTeam: bool, isPowerUser: bool, lastname: string, name: string, picture: string, printableName: string, type: string, username: string, classRole: string, htmlUrl: string, organization: string, organizationRole: string>, arranger: string, collaborators: list<record>, collections: list<string>, comments: record<monthly: float, total: float, unique: float, weekly: float>, composer: string, creationDate: string, creationType: string, description: string, durationTime: float, googleDriveFileId: string, instruments: list<string>, license: string, licenseText: string, likes: record<monthly: float, total: float, weekly: float>, lyricist: string, mainTempoQpm: float, modificationDate: string, numberMeasures: int, organization: string, parentScore: string, plays: record<monthly: float, total: float, weekly: float>, publicationDate: string, rights: record<aclAdmin: bool, aclRead: bool, aclWrite: bool, isCollaborator: bool>, samples: list<string>, subtitle: string, tags: list<string>, views: record<monthly: float, total: float, weekly: float>>
# operationId: getUserScores
export def "get-user-scores" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: string # Filter the score forked from the score id `parent`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user}/scores"
    path_params: [{name: user, var: user}]
    query: [{name: parent, var: parent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
