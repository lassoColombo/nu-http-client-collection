# Auto-generated client for Forem API V1 v1.0.0
# Source: https://api.apis.guru/v2/specs/dev.to/1.0.0/openapi.json
# Auth: --token flag or $env.FOREM_API_V1_TOKEN

const CLIENT = {
  base_url: "https://dev.to/api"
  token_env_var: "FOREM_API_V1_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: api-key, in: header, header_name: api-key, prefix: ""}
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

def base-url-completer [] { ["https://dev.to/api"] }
def auth-scheme-completer [] { ["api-key" "none"] }

# Completers for enum parameters
def state-completer [] { ["all" "fresh" "rising"] }
def display-to-completer [] { ["all" "logged_in" "logged_out"] }
def placement-area-completer [] { ["post_comments" "post_sidebar" "sidebar_left" "sidebar_left_2" "sidebar_right"] }
def type-of-completer [] { ["community" "external" "in_house"] }
def template-completer [] { ["contained" "full_within_layout" "json" "nav_bar_included"] }
def category-completer [] { ["exploding_head" "fire" "like" "raised_hands" "unicorn"] }
def reactable-type-completer [] { ["Article" "Comment" "User"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-articles: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-latest-articles: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-user-articles: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-user-all-articles: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-user-published-articles: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-user-unpublished-articles: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-article-by-id: "record"
    get-article-by-path: "record"
    get-comments-by-article-id: "table<created_at: string, id_code: string, image_url: string, type_of: string>"
    get-followers: "table<id: int, name: string, path: string, profile_image: string, type_of: string, user_id: int>"
    get-followed-tags: "table<id: int, name: string, points: float>"
    get-organization: "record"
    get-org-articles: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-org-users: "table<github_username: string, id: int, joined_at: string, location: string, name: string, profile_image: string, summary: string, twitter_username: string, type_of: string, username: string, website_url: string>"
    get-api-pages: "table<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>"
    delete-api-pages-id: "record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>"
    get-api-pages-id: "record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>"
    put-api-pages-id: "record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>"
    get-podcast-episodes: "table<class_name: string, id: int, image_url: string, path: string, podcast: record<image_url: string, slug: string, title: string>, title: string, type_of: string>"
    get-profile-image: "record"
    get-readinglist: "table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>"
    get-tags: "table<bg_color_hex: string, id: int, name: string, text_color_hex: string>"
    get-user-me: "record"
    get-user: "record"
    videos: "table<cloudinary_video_url: string, id: int, path: string, title: string, type_of: string, user: record<name: string>, user_id: int, video_duration_in_minutes: string, video_source_url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-admin-users-create" "get-articles" "create-article" "get-latest-articles" "get-user-articles" "get-user-all-articles" "get-user-published-articles" "get-user-unpublished-articles" "get-article-by-id" "update-article" "unpublish-article" "get-article-by-path" "get-comments-by-article-id" "get-comment-by-id" "get-api-display-ads" "post-api-display-ads" "get-api-display-ads-id" "put-api-display-ads-id" "put-api-display-ads-id-unpublish" "get-followers" "get-followed-tags" "get-organization" "get-org-articles" "get-org-users" "get-api-pages" "post-api-pages" "delete-api-pages-id" "get-api-pages-id" "put-api-pages-id" "get-podcast-episodes" "get-profile-image" "post-api-reactions" "post-api-reactions-toggle" "get-readinglist" "get-tags" "get-user-me" "get-user" "suspend-user" "unpublish-user" "videos" "commands"] | sort) } | get name | first)
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

# Invite a User
#
# POST /api/admin/users
# operationId: postAdminUsersCreate
export def "post-admin-users-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --name: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/admin/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    email: $email, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Published articles
#
# GET /api/articles
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getArticles
export def "get-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --tag: string # Using this parameter will retrieve articles that contain the requested tag. Articles will be ordered by descending popularity.This parameter can be used in conjuction with `top`. (e.g. discuss)
  --tags: string # Using this parameter will retrieve articles with any of the comma-separated tags. Articles will be ordered by descending popularity. (e.g. javascript, css)
  --tags-exclude: string # Using this parameter will retrieve articles that do _not_ contain _any_ of comma-separated tags. Articles will be ordered by descending popularity. (e.g. node, java)
  --username: string # Using this parameter will retrieve articles belonging to a User or Organization ordered by descending publication date. If `state=all` the number of items returned will be `1000` instead of the default `30`. This parameter can be used in conjuction with `state`. (e.g. ben)
  --state: string@state-completer # Using this parameter will allow the client to check which articles are fresh or rising. If `state=fresh` the server will return fresh articles. If `state=rising` the server will return rising articles. This param can be used in conjuction with `username`, only if set to `all`. (e.g. fresh)
  --top: int # Using this parameter will allow the client to return the most popular articles in the last `N` days. `top` indicates the number of days since publication of the articles returned. This param can be used in conjuction with `tag`. (format: int32, e.g. 2)
  --collection-id: int # Adding this will allow the client to return the list of articles belonging to the requested collection, ordered by ascending publication date. (format: int32, e.g. 99)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/articles"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: tag, var: tag}, {name: tags, var: tags}, {name: tags_exclude, var: tags_exclude}, {name: username, var: username}, {name: state, var: state}, {name: top, var: top}, {name: collection_id, var: collection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, per_page: $per_page, tag: $tag, tags: $tags, tags_exclude: $tags_exclude, username: $username, state: $state, top: $top, collection_id: $collection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish article
#
# POST /api/articles
# operationId: createArticle
export def "create-article" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article: record # shape: {body_markdown?: string, canonical_url?: string, description?: string, main_image?: string, organization_id?: int, published?: bool, series?: string, tags?: string, title?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/articles"
    body: {content_type: "application/json", kind: json, fields: [{name: article, var: article}]}
    accept: ["application/json"]
    ok: [201]
    auth: api-key
  } {
    article: $article
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Published articles sorted by published date
#
# GET /api/articles/latest
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getLatestArticles
export def "get-latest-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/articles/latest"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User's articles
#
# GET /api/articles/me
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getUserArticles
export def "get-user-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/articles/me"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User's all articles
#
# GET /api/articles/me/all
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getUserAllArticles
export def "get-user-all-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/articles/me/all"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User's published articles
#
# GET /api/articles/me/published
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getUserPublishedArticles
export def "get-user-published-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/articles/me/published"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User's unpublished articles
#
# GET /api/articles/me/unpublished
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getUserUnpublishedArticles
export def "get-user-unpublished-articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/articles/me/unpublished"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Published article by id
#
# GET /api/articles/{id}
# Returns: record
# operationId: getArticleById
export def "get-article-by-id" [
  id: int
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
    path: "/api/articles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an article by id
#
# PUT /api/articles/{id}
# operationId: updateArticle
export def "update-article" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --article: record # shape: {body_markdown?: string, canonical_url?: string, description?: string, main_image?: string, organization_id?: int, published?: bool, series?: string, tags?: string, title?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/articles/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: article, var: article}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, article: $article
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unpublish an article
#
# PUT /api/articles/{id}/unpublish
# operationId: unpublishArticle
export def "unpublish-article" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --note: string # Content for the note that's created along with unpublishing (e.g. Admin requested unpublishing all articles via API)
]: nothing -> any {
  http-request {
    method: put
    path: "/api/articles/{id}/unpublish"
    path_params: [{name: id, var: id}]
    query: [{name: note, var: note}]
    accept: ["application/json"]
    ok: [204]
    auth: api-key
  } {
    id: $id, note: $note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Published article by path
#
# GET /api/articles/{username}/{slug}
# Returns: record
# operationId: getArticleByPath
export def "get-article-by-path" [
  username: string
  slug: string
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
    path: "/api/articles/{username}/{slug}"
    path_params: [{name: username, var: username}, {name: slug, var: slug}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    username: $username, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Comments
#
# GET /api/comments
# Returns: table<created_at: string, id_code: string, image_url: string, type_of: string>
# operationId: getCommentsByArticleId
export def "get-comments-by-article-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --a-id: string # Article identifier. (e.g. 321)
  --p-id: string # Podcast Episode identifier. (e.g. 321)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/comments"
    query: [{name: a_id, var: a_id}, {name: p_id, var: p_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    a_id: $a_id, p_id: $p_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Comment by id
#
# GET /api/comments/{id}
# operationId: getCommentById
export def "get-comment-by-id" [
  id: int
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
    path: "/api/comments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# display ads
#
# GET /api/display_ads
export def "get-api-display-ads" [
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
    path: "/api/display_ads"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# display ads
#
# POST /api/display_ads
export def "post-api-display-ads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --approved: oneof<nothing, bool> # Ad must be both published and approved to be in rotation
  body_markdown: string # The text (in markdown) of the ad (required)
  --creator-id: int # Identifies the user who created the ad.
  --display-to: string@display-to-completer # Potentially limits visitors to whom the ad is visible (default: all)
  name: string # For internal use, helps distinguish ads from one another
  --organization-id: int # Identifies the organization to which the ad belongs
  placement_area: string@placement-area-completer # Identifies which area of site layout the ad can appear in
  --published: oneof<nothing, bool> # Ad must be both published and approved to be in rotation
  --tag-list: string # Tags on which this ad can be displayed (blank is all/any tags)
  --type-of: string@type-of-completer # Types of the billboards: in_house (created by admins), community (created by an entity, appears on entity's content), external ( created by an entity, or a non-entity, can appear everywhere) (default: in_house)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/display_ads"
    body: {content_type: "application/json", kind: json, fields: [{name: approved, var: approved}, {name: body_markdown, var: body_markdown}, {name: creator_id, var: creator_id}, {name: display_to, var: display_to}, {name: name, var: name}, {name: organization_id, var: organization_id}, {name: placement_area, var: placement_area}, {name: published, var: published}, {name: tag_list, var: tag_list}, {name: type_of, var: type_of}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    approved: $approved, body_markdown: $body_markdown, creator_id: $creator_id, display_to: $display_to, name: $name, organization_id: $organization_id, placement_area: $placement_area, published: $published, tag_list: $tag_list, type_of: $type_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# display ad
#
# GET /api/display_ads/{id}
export def "get-api-display-ads-id" [
  id: int
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
    path: "/api/display_ads/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# display ads
#
# PUT /api/display_ads/{id}
export def "put-api-display-ads-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --approved: oneof<nothing, bool> # Ad must be both published and approved to be in rotation
  body_markdown: string # The text (in markdown) of the ad (required)
  --creator-id: int # Identifies the user who created the ad.
  --display-to: string@display-to-completer # Potentially limits visitors to whom the ad is visible (default: all)
  name: string # For internal use, helps distinguish ads from one another
  --organization-id: int # Identifies the organization to which the ad belongs, required for 'community' type ads
  placement_area: string@placement-area-completer # Identifies which area of site layout the ad can appear in
  --published: oneof<nothing, bool> # Ad must be both published and approved to be in rotation
  --tag-list: string # Tags on which this ad can be displayed (blank is all/any tags)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/display_ads/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: approved, var: approved}, {name: body_markdown, var: body_markdown}, {name: creator_id, var: creator_id}, {name: display_to, var: display_to}, {name: name, var: name}, {name: organization_id, var: organization_id}, {name: placement_area, var: placement_area}, {name: published, var: published}, {name: tag_list, var: tag_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, approved: $approved, body_markdown: $body_markdown, creator_id: $creator_id, display_to: $display_to, name: $name, organization_id: $organization_id, placement_area: $placement_area, published: $published, tag_list: $tag_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# unpublish
#
# PUT /api/display_ads/{id}/unpublish
export def "put-api-display-ads-id-unpublish" [
  id: int
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
    path: "/api/display_ads/{id}/unpublish"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followers
#
# GET /api/followers/users
# Returns: table<id: int, name: string, path: string, profile_image: string, type_of: string, user_id: int>
# operationId: getFollowers
export def "get-followers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --sort: string # Default is 'created_at'. Specifies the sort order for the created_at param of the follow relationship. To sort by newest followers first (descending order) specify ?sort=-created_at. (e.g. created_at)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/followers/users"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    page: $page, per_page: $per_page, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Followed Tags
#
# GET /api/follows/tags
# Returns: table<id: int, name: string, points: float>
# operationId: getFollowedTags
export def "get-followed-tags" [
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
    path: "/api/follows/tags"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An organization
#
# GET /api/organizations/{username}
# Returns: record
# operationId: getOrganization
export def "get-organization" [
  username: string
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
    path: "/api/organizations/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Organization's Articles
#
# GET /api/organizations/{username}/articles
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getOrgArticles
export def "get-org-articles" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/organizations/{username}/articles"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    username: $username, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Organization's users
#
# GET /api/organizations/{username}/users
# Returns: table<github_username: string, id: int, joined_at: string, location: string, name: string, profile_image: string, summary: string, twitter_username: string, type_of: string, username: string, website_url: string>
# operationId: getOrgUsers
export def "get-org-users" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/organizations/{username}/users"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    username: $username, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# show details for all pages
#
# GET /api/pages
# Returns: table<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>
export def "get-api-pages" [
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
    path: "/api/pages"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# pages
#
# POST /api/pages
export def "post-api-pages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-json: string # For JSON pages, the JSON body
  --body-markdown: string # The text (in markdown) of the ad (required)
  --description: string # For internal use, helps similar pages from one another
  --is-top-level-path: oneof<nothing, bool> # If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution
  --slug: string # Used to link to this page in URLs, must be unique and URL-safe
  --template: string@template-completer # Controls what kind of layout the page is rendered in (default: contained)
  --title: string # Title of the page
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/pages"
    body: {content_type: "application/json", kind: json, fields: [{name: body_json, var: body_json}, {name: body_markdown, var: body_markdown}, {name: description, var: description}, {name: is_top_level_path, var: is_top_level_path}, {name: slug, var: slug}, {name: template, var: template}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    body_json: $body_json, body_markdown: $body_markdown, description: $description, is_top_level_path: $is_top_level_path, slug: $slug, template: $template, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# remove a page
#
# DELETE /api/pages/{id}
# Returns: record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>
export def "delete-api-pages-id" [
  id: int
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
    path: "/api/pages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# show details for a page
#
# GET /api/pages/{id}
# Returns: record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>
export def "get-api-pages-id" [
  id: int
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
    path: "/api/pages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# update details for a page
#
# PUT /api/pages/{id}
# Returns: record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string>
export def "put-api-pages-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-json: string # For JSON pages, the JSON body (nullable)
  --body-markdown: string # The text (in markdown) of the ad (required) (nullable)
  description: string # For internal use, helps similar pages from one another
  --is-top-level-path: oneof<nothing, bool> # If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution
  slug: string # Used to link to this page in URLs, must be unique and URL-safe
  --social-image: record # nullable
  template: string@template-completer # Controls what kind of layout the page is rendered in (default: contained)
  title: string # Title of the page
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/pages/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body_json, var: body_json}, {name: body_markdown, var: body_markdown}, {name: description, var: description}, {name: is_top_level_path, var: is_top_level_path}, {name: slug, var: slug}, {name: social_image, var: social_image}, {name: template, var: template}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id, body_json: $body_json, body_markdown: $body_markdown, description: $description, is_top_level_path: $is_top_level_path, slug: $slug, social_image: $social_image, template: $template, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Podcast Episodes
#
# GET /api/podcast_episodes
# Returns: table<class_name: string, id: int, image_url: string, path: string, podcast: record<image_url: string, slug: string, title: string>, title: string, type_of: string>
# operationId: getPodcastEpisodes
export def "get-podcast-episodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --username: string # Using this parameter will retrieve episodes belonging to a specific podcast. (e.g. codenewbie)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/podcast_episodes"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, per_page: $per_page, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A Users or organizations profile image
#
# GET /api/profile_images/{username}
# Returns: record
# operationId: getProfileImage
export def "get-profile-image" [
  username: string
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
    path: "/api/profile_images/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create reaction
#
# POST /api/reactions
export def "post-api-reactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # required
  --reactable-id: int # required, format: int32
  --reactable-type: string@reactable-type-completer # required
]: nothing -> any {
  http-request {
    method: post
    path: "/api/reactions"
    query: [{name: category, var: category, required: true}, {name: reactable_id, var: reactable_id, required: true}, {name: reactable_type, var: reactable_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    category: $category, reactable_id: $reactable_id, reactable_type: $reactable_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# toggle reaction
#
# POST /api/reactions/toggle
export def "post-api-reactions-toggle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # required
  --reactable-id: int # required, format: int32
  --reactable-type: string@reactable-type-completer # required
]: nothing -> any {
  http-request {
    method: post
    path: "/api/reactions/toggle"
    query: [{name: category, var: category, required: true}, {name: reactable_id, var: reactable_id, required: true}, {name: reactable_type, var: reactable_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    category: $category, reactable_id: $reactable_id, reactable_type: $reactable_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Readinglist
#
# GET /api/readinglist
# Returns: table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>>
# operationId: getReadinglist
export def "get-readinglist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/readinglist"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tags
#
# GET /api/tags
# Returns: table<bg_color_hex: string, id: int, name: string, text_color_hex: string>
# operationId: getTags
export def "get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/tags"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The authenticated user
#
# GET /api/users/me
# Returns: record
# operationId: getUserMe
export def "get-user-me" [
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
    path: "/api/users/me"
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A User
#
# GET /api/users/{id}
# Returns: record
# operationId: getUser
export def "get-user" [
  id: string
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
    path: "/api/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspend a User
#
# PUT /api/users/{id}/suspend
# operationId: suspendUser
export def "suspend-user" [
  id: int
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
    path: "/api/users/{id}/suspend"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unpublish a User's Articles and Comments
#
# PUT /api/users/{id}/unpublish
# operationId: unpublishUser
export def "unpublish-user" [
  id: int
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
    path: "/api/users/{id}/unpublish"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Articles with a video
#
# GET /api/videos
# Returns: table<cloudinary_video_url: string, id: int, path: string, title: string, type_of: string, user: record<name: string>, user_id: int, video_duration_in_minutes: string, video_source_url: string>
# operationId: videos
export def "videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 24)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/videos"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
