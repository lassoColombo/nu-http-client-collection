# Auto-generated client for elmah.io API v3
# Source: https://api.apis.guru/v2/specs/elmah.io/v3/openapi.json
# Auth: --token flag or $env.ELMAH_IO_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "ELMAH_IO_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-api_key, in: query, header_name: api_key, prefix: ""}
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    deployments-get-all: "table<created: string, createdBy: string, description: string, id: string, logId: string, userEmail: string, userName: string, version: string>"
    deployments-create: "record<location: string>"
    deployments-get: "record<created: string, createdBy: string, description: string, id: string, logId: string, userEmail: string, userName: string, version: string>"
    logs-get-all: "table<color: string, disabled: bool, environmentName: string, id: string, name: string>"
    logs-create: "record<location: string>"
    logs-get: "record<color: string, disabled: bool, environmentName: string, id: string, name: string>"
    logs-diagnose: "list<string>"
    messages-get-all: "record<messages: table<application: string, breadcrumbs: list, category: string, code: string, cookies: list, correlationId: string, data: list, dateTime: string, detail: string, form: list, hostname: string, id: string, method: string, queryString: list, serverVariables: list, severity: string, source: string, statusCode: int, title: string, titleTemplate: string, type: string, url: string, user: string, version: string>, total: int>"
    messages-create: "record<location: string>"
    messages-create-bulk: "table<location: string, statusCode: int>"
    messages-get: "record<application: string, breadcrumbs: table<action: string, dateTime: string, message: string, severity: string>, category: string, code: string, cookies: table<key: string, value: string>, correlationId: string, data: table<key: string, value: string>, dateTime: string, detail: string, form: table<key: string, value: string>, hostname: string, id: string, method: string, queryString: table<key: string, value: string>, serverVariables: table<key: string, value: string>, severity: string, source: string, statusCode: int, title: string, titleTemplate: string, type: string, url: string, user: string, version: string>"
    uptime-checks-get-all: "table<id: string, name: string, status: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["deployments-get-all" "deployments-create" "deployments-delete" "deployments-get" "heartbeats-create" "logs-get-all" "logs-create" "logs-get" "logs-diagnose" "logs-disable" "logs-enable" "messages-delete-all" "messages-get-all" "messages-create" "messages-create-bulk" "messages-fix-all" "messages-delete" "messages-get" "messages-fix" "messages-hide" "source-maps-create-or-update" "uptime-checks-get-all" "commands"] | sort) } | get name | first)
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

# Fetch a list of deployments.
#
# GET /v3/deployments
# Returns: table<created: string, createdBy: string, description: string, id: string, logId: string, userEmail: string, userName: string, version: string>
# operationId: Deployments_GetAll
export def "deployments-get-all" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/deployments"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new deployment.
#
# POST /v3/deployments
# Returns: record<location: string>
# operationId: Deployments_Create
export def "deployments-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --created: string # When was this deployment created in UTC. Defaults to current time if not specified. (format: date-time)
  --description: string # Optional description of this deployment. Can be markdown or clear text.
  --log-id: string # As default, deployments are attached all logs of the organization. If you want a deployment to attach to a single log only, set this to the ID of that log.
  --user-email: string # The email of the person responsible for creating this deployment. This can be the email taken from your deployment server (like Azure DevOps or Octopus). (format: email)
  --user-name: string # The name of the person responsible for creating this deployment. This can be the name taken from your deployment server (like Azure DevOps or Octopus).
  version: string # The version number of this deployment. The value of version can be a SemVer compliant string or any other syntax that you are using as your version numbering scheme.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/deployments"
    body: {content_type: "application/json", kind: json, fields: [{name: created, var: created}, {name: description, var: description}, {name: logId, var: log_id}, {name: userEmail, var: user_email}, {name: userName, var: user_name}, {name: version, var: version}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201]
    auth: query-api_key
  } {
    created: $created, description: $description, log_id: $log_id, user_email: $user_email, user_name: $user_name, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a deployment by its ID.
#
# DELETE /v3/deployments/{id}
# operationId: Deployments_Delete
export def "deployments-delete" [
  id: string
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
    path: "/v3/deployments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: query-api_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a deployment by its ID.
#
# GET /v3/deployments/{id}
# Returns: record<created: string, createdBy: string, description: string, id: string, logId: string, userEmail: string, userName: string, version: string>
# operationId: Deployments_Get
export def "deployments-get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/deployments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new heartbeat.
#
# POST /v3/heartbeats/{logId}/{id}
# operationId: Heartbeats_Create
export def "heartbeats-create" [
  log_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --application: string # Optional string to identify which application logged this message. You can use this if you have multiple applications and services logging to the same log. If not set, the application name "Heartbeats" will be set on all log messages generated from this heartbeat.
  --reason: string # If result is "Degraded" or "Unhealthy" you can use this property to specify why.
  --result: string # The result of this heartbeat. Can be "Healthy, "Degraded", or "Unhealthy". Defaults to "Healthy"
  --took: int # Optional long for specifying how many milliseconds it took to execute the task resulting in this heartbeat. This can be used to get a better overview of how long a scheduled task or service is running or to figure out if the grace period should be increased. (format: int64)
  --version: string # Optional string to identify which version of your application logged this message. If not specified, any errors, warnings, or information messages will get the newest version number created through deployment tracking as with normal log messages.
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/heartbeats/{logId}/{id}"
    path_params: [{name: logId, var: log_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: application, var: application}, {name: reason, var: reason}, {name: result, var: result}, {name: took, var: took}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, id: $id, application: $application, reason: $reason, result: $result, took: $took, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of logs.
#
# GET /v3/logs
# Returns: table<color: string, disabled: bool, environmentName: string, id: string, name: string>
# operationId: Logs_GetAll
export def "logs-get-all" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/logs"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new log.
#
# POST /v3/logs
# Returns: record<location: string>
# operationId: Logs_Create
export def "logs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # Name of the new log.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/logs"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201]
    auth: query-api_key
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch a log by its ID.
#
# GET /v3/logs/{id}
# Returns: record<color: string, disabled: bool, environmentName: string, id: string, name: string>
# operationId: Logs_Get
export def "logs-get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/logs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Help diagnose logging problems.
#
# GET /v3/logs/{id}/_diagnose
# Returns: list<string>
# operationId: Logs_Diagnose
export def "logs-diagnose" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/logs/{id}/_diagnose"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Disable a log by its ID.
#
# POST /v3/logs/{id}/_disable
# operationId: Logs_Disable
export def "logs-disable" [
  id: string
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
    path: "/v3/logs/{id}/_disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a log by its ID.
#
# POST /v3/logs/{id}/_enable
# operationId: Logs_Enable
export def "logs-enable" [
  id: string
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
    path: "/v3/logs/{id}/_enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a list of messages by logid and query.
#
# DELETE /v3/messages/{logId}
# operationId: Messages_DeleteAll
export def "messages-delete-all" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # Search from this date. (format: date-time)
  --query: string # Lucene query.
  --to: string # Search to this date. (format: date-time)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v3/messages/{logId}"
    path_params: [{name: logId, var: log_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: from, var: from}, {name: query, var: query}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, from: $from, query: $query, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch messages from a log.
#
# GET /v3/messages/{logId}
# Returns: record<messages: table<application: string, breadcrumbs: list, category: string, code: string, cookies: list, correlationId: string, data: list, dateTime: string, detail: string, form: list, hostname: string, id: string, method: string, queryString: list, serverVariables: list, severity: string, source: string, statusCode: int, title: string, titleTemplate: string, type: string, url: string, user: string, version: string>, total: int>
# operationId: Messages_GetAll
export def "messages-get-all" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-index: int # The page number of the result. (format: int32, default: 0)
  --page-size: int # The number of messages to load (max 100) or 15 if not set. (format: int32, default: 15)
  --query: string # A full-text or Lucene query to limit the messages by.
  --from: string # A start date and time to search from (not included). (format: date-time)
  --to: string # An end date and time to search to (not included). (format: date-time)
  --include-headers: oneof<nothing, bool> # Include headers like server variables and cookies in the result (slower). (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/messages/{logId}"
    path_params: [{name: logId, var: log_id}]
    query: [{name: pageIndex, var: page_index}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: from, var: from}, {name: to, var: to}, {name: includeHeaders, var: include_headers}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, page_index: $page_index, page_size: $page_size, query: $query, from: $from, to: $to, include_headers: $include_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new message.
#
# POST /v3/messages/{logId}
# Returns: record<location: string>
# operationId: Messages_Create
export def "messages-create" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --application: string # Used to identify which application logged this message. You can use this if you have multiple applications and services logging to the same log
  --breadcrumbs: list # A list of breadcrumbs preceding this log message. — item shape: {action?: string, dateTime?: string, message?: string, severity?: string}
  --category: string # The log message category. Category can be a string of choice but typically contain a logging category set by a logging framework like NLog or Serilog. When logging through a logging framework, this field will be provided by the framework and not something that needs to be set manually.
  --code: string # Code can be used to include source code related to the log message. The code will typically span from a few lines before the line causing the log message to a few lines after. For now, all lines above 21 will be removed. This makes room for showing 10 lines before the logging line, the logging line, and 10 lines after the logging line. Don't include a very large string in this property since that will quickly make the entire messages exceed the max limit of 256 kb.
  --cookies: list # A key/value pair of cookies. This property only makes sense for logging messages related to web requests. — item shape: {key?: string, value?: string}
  --correlation-id: string # CorrelationId can be used to group similar log messages together into a single discoverable batch. A correlation ID could be a session ID from ASP.NET Core, a unique string spanning multiple microsservices handling the same request, or similar.
  --data: list # A key/value pair of user-defined fields and their values. When logging an exception, the Data dictionary of the exception is copied to this property. You can add additional key/value pairs, by modifying the Data dictionary on the exception or by supplying additional key/values to this API. — item shape: {key?: string, value?: string}
  --date-time: string # The date and time in UTC of the message. If you don't provide us with a value in dateTime, we will set the current date and time in UTC. (format: date-time)
  --detail: string # A longer description of the message. For errors this could be a stacktrace, but it's really up to you what to log in there.
  --form: list # A key/value pair of form fields and their values. This property makes sense if logging message related to users inputting data in a form. — item shape: {key?: string, value?: string}
  --hostname: string # The hostname of the server logging the message.
  --method: string # If message relates to a HTTP request, you may send the HTTP method of that request. If you don't provide us with a method, we will try to find a key named REQUEST_METHOD in serverVariables.
  --query-string: list # A key/value pair of query string parameters. This property makes sense if logging message related to a HTTP request. — item shape: {key?: string, value?: string}
  --server-variables: list # A key/value pair of server values. Server variables are typically related to handling requests in a webserver but could be used for other types of information as well. — item shape: {key?: string, value?: string}
  --severity: string # An enum value representing the severity of this message. The following values are allowed: Verbose, Debug, Information, Warning, Error, Fatal
  --source: string # The source of the code logging the message. This could be the assembly name.
  --status-code: int # If the message logged relates to a HTTP status code, you can put the code in this property. This would probably only be relevant for errors, but could be used for logging successful status codes as well. (format: int32)
  --title: string # The textual title or headline of the message to log.
  --title-template: string # The title template of the message to log. This property can be used from logging frameworks that supports structured logging like: "{user} says {quote}". In the example, titleTemplate will be this string and title will be "Gilfoyle says It's not magic. It's talent and sweat".
  --type: string # The type of message. If logging an error, the type of the exception would go into type but you can put anything in there, that makes sense for your domain.
  --url: string # If message relates to a HTTP request, you may send the URL of that request. If you don't provide us with an URL, we will try to find a key named URL in serverVariables.
  --user: string # An identification of the user triggering this message. You can put the users email address or your user key into this property.
  --version: string # Versions can be used to distinguish messages from different versions of your software. The value of version can be a SemVer compliant string or any other syntax that you are using as your version numbering scheme.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/messages/{logId}"
    path_params: [{name: logId, var: log_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: application, var: application}, {name: breadcrumbs, var: breadcrumbs}, {name: category, var: category}, {name: code, var: code}, {name: cookies, var: cookies}, {name: correlationId, var: correlation_id}, {name: data, var: data}, {name: dateTime, var: date_time}, {name: detail, var: detail}, {name: form, var: form}, {name: hostname, var: hostname}, {name: method, var: method}, {name: queryString, var: query_string}, {name: serverVariables, var: server_variables}, {name: severity, var: severity}, {name: source, var: source}, {name: statusCode, var: status_code}, {name: title, var: title}, {name: titleTemplate, var: title_template}, {name: type, var: type}, {name: url, var: url}, {name: user, var: user}, {name: version, var: version}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 201]
    auth: query-api_key
  } {
    log_id: $log_id, application: $application, breadcrumbs: $breadcrumbs, category: $category, code: $code, cookies: $cookies, correlation_id: $correlation_id, data: $data, date_time: $date_time, detail: $detail, form: $form, hostname: $hostname, method: $method, query_string: $query_string, server_variables: $server_variables, severity: $severity, source: $source, status_code: $status_code, title: $title, title_template: $title_template, type: $type, url: $url, user: $user, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create one or more new messages.
#
# POST /v3/messages/{logId}/_bulk
# Returns: table<location: string, statusCode: int>
# operationId: Messages_CreateBulk
export def "messages-create-bulk" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/messages/{logId}/_bulk"
    path_params: [{name: logId, var: log_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Mark a list of messages as fixed by logid and query.
#
# POST /v3/messages/{logId}/_fix
# operationId: Messages_FixAll
export def "messages-fix-all" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # Search from this date. (format: date-time)
  --query: string # Lucene query.
  --to: string # Search to this date. (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/messages/{logId}/_fix"
    path_params: [{name: logId, var: log_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: from, var: from}, {name: query, var: query}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, from: $from, query: $query, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a message by its ID.
#
# DELETE /v3/messages/{logId}/{id}
# operationId: Messages_Delete
export def "messages-delete" [
  log_id: string
  id: string
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
    path: "/v3/messages/{logId}/{id}"
    path_params: [{name: logId, var: log_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a message by its ID.
#
# GET /v3/messages/{logId}/{id}
# Returns: record<application: string, breadcrumbs: table<action: string, dateTime: string, message: string, severity: string>, category: string, code: string, cookies: table<key: string, value: string>, correlationId: string, data: table<key: string, value: string>, dateTime: string, detail: string, form: table<key: string, value: string>, hostname: string, id: string, method: string, queryString: table<key: string, value: string>, serverVariables: table<key: string, value: string>, severity: string, source: string, statusCode: int, title: string, titleTemplate: string, type: string, url: string, user: string, version: string>
# operationId: Messages_Get
export def "messages-get" [
  log_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/messages/{logId}/{id}"
    path_params: [{name: logId, var: log_id}, {name: id, var: id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fix a message by its ID.
#
# POST /v3/messages/{logId}/{id}/_fix
# operationId: Messages_Fix
export def "messages-fix" [
  log_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mark-all-as-fixed: oneof<nothing, bool> # If set to true, all instances of the log message are set to fixed. (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/v3/messages/{logId}/{id}/_fix"
    path_params: [{name: logId, var: log_id}, {name: id, var: id}]
    query: [{name: markAllAsFixed, var: mark_all_as_fixed}]
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, id: $id, mark_all_as_fixed: $mark_all_as_fixed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hide a message by its ID.
#
# POST /v3/messages/{logId}/{id}/_hide
# operationId: Messages_Hide
export def "messages-hide" [
  log_id: string
  id: string
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
    path: "/v3/messages/{logId}/{id}/_hide"
    path_params: [{name: logId, var: log_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a translation between a minified JavaScript path to the minified JavaScript and source map files.
#
# POST /v3/sourcemaps/{logId}
# operationId: SourceMaps_CreateOrUpdate
export def "source-maps-create-or-update" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  minified_java_script: string # The minified JavaScript file. Only files with an extension of .js and content type of text/javascript will be accepted. (format: binary)
  path: string # An URL to the online minified JavaScript file. The URL can be absolute or relative but will always be converted to a relative path (no protocol, domain, and query parameters). elmah.io uses this path to lookup any lines in a JS stack trace that will need de-minification. (format: uri)
  source_map: string # The source map file. Only files with an extension of .map and content type of application/json will be accepted. (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/sourcemaps/{logId}"
    path_params: [{name: logId, var: log_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: MinifiedJavaScript, var: minified_java_script}, {name: Path, var: path}, {name: SourceMap, var: source_map}], files: [MinifiedJavaScript, SourceMap]}
    accept: ["application/json"]
    ok: [200]
    auth: query-api_key
  } {
    log_id: $log_id, minified_java_script: $minified_java_script, path: $path, source_map: $source_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of uptime checks. Currently in closed beta. Get in contact to get access to this endpoint.
#
# GET /v3/uptimechecks
# Returns: table<id: string, name: string, status: string, url: string>
# operationId: UptimeChecks_GetAll
export def "uptime-checks-get-all" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/v3/uptimechecks"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: query-api_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
