# Auto-generated client for GererMesAffaires {REST:API} v1.0.6
# Source: https://api.apis.guru/v2/specs/gerermesaffaires.com/1.0.6/openapi.json
# Auth: --token flag or $env.GERERMESAFFAIRES_REST_API_TOKEN

const CLIENT = {
  base_url: "https://sandbox.gerermesaffaires.com/api/v1"
  token_env_var: "GERERMESAFFAIRES_REST_API_TOKEN"
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

def base-url-completer [] { ["https://sandbox.gerermesaffaires.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["association" "company" "enterprise" "private"] }
def groups-completer [] { ["legal" "tax" "wealth management"] }
def role-completer [] { ["collaborator" "manager"] }
def type-completer-1 [] { ["association" "company" "enterprise"] }
def sex-completer [] { ["female" "male"] }
def accept-completer [] { ["application/json" "multipart/form-data"] }
def level-completer [] { ["confidential" "public" "regular"] }
def has-company-registration-certificate-completer [] { ["false" "true"] }
def has-status-completer [] { ["false" "true"] }
def has-sirene-register-completer [] { ["false" "true"] }
def has-minutes-completer [] { ["false" "true"] }
def event-completer [] { ["Board" "CGM" "ConstituentAssembly" "Consulting" "EGM" "ExecutiveCommittee" "OGM" "Office" "Other" "OtherEvent" "PartnersMeeting" "SolePartner"] }
def groups-completer-1 [] { ["accounting" "legal" "purchases" "sales" "social" "social manager" "tax" "wealth management"] }
def role-completer-1 [] { ["assistant" "collaborator" "empty"] }
def right-completer [] { ["read" "write"] }
def validated-completer [] { ["false" "true"] }
def client-management-completer [] { ["adn" "manager" "no"] }
def player-completer [] { ["assistant" "collaborator" "guest" "manager" "owner"] }
def accept-completer-1 [] { ["*/*" "application/json" "multipart/form-data"] }
def root-folders-completer [] { ["all"] }
def type-completer-2 [] { ["amendment" "contract" "delivery-order" "engagement-letter" "other" "purchase-order" "quotation"] }
def order-completer [] { ["1st advance" "2nd advance" "3rd advance" "4th advance" "regularization"] }
def account-completer [] { ["CAB" "DIV" "FHR" "IKM" "PRK" "PTT" "RES" "TXI" "VOY"] }
def status-completer [] { ["R" "V" "W"] }
def type-completer-3 [] { ["amending-invoice" "commercial-invoice" "credit-note" "credit-self-billing" "down-payment-invoice" "informations-invoice" "self-billing"] }
def with-extend-completer [] { ["false" "true"] }
def sort-order-completer [] { ["asc" "desc"] }
def sort-name-completer [] { ["ExpenseDate" "InclVAT" "Title"] }
def sort-name-completer-1 [] { ["Contracting" "DueDate" "InclVAT" "InvoiceDate" "PaymentDate" "Title"] }
def category-completer [] { ["bank loan" "current account" "debt spreading" "leasing" "obligation" "overdraft agreement"] }
def level-completer-1 [] { ["confidential" "regular"] }
def status-completer-1 [] { ["ended" "validated" "waiting"] }
def periodicity-completer [] { ["annual" "half-yearly" "monthly" "null" "quarterly"] }
def type-completer-4 [] { ["mandatory" "null" "optional"] }
def right-completer-1 [] { ["none" "read" "write"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-box-menus: "record<Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>"
    get-business-groups: "table<Id: string, ModificationDate: string, Name: string>"
    post-business-groups: "record<Id: string>"
    get-business-groups-all: "table<Id: string, ModificationDate: string, Name: string>"
    get-business-groups-id: "record<Id: string, ModificationDate: string, Name: string>"
    get-business-groups-id-spaces: "table<Id: string, ModificationDate: string, Name: string, RegistrationNumber: string, Type: string>"
    post-business-groups-id-spaces-space-id-legal-entities-person-id-customers-folder-id-guest-in-space: "record<Id: string>"
    post-business-groups-id-spaces-space-id-legal-entities-person-id-customers-folder-id-spaces: "record<Id: string>"
    get-hub-business-groups-id-menus: "record<Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>"
    post-hub-documents: "record<Id: string>"
    get-hub-menus: "record<Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>"
    get-hub-menus-all: "record<BusinessGroup: record<Id: string, Name: string>, Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>"
    post-hub-payslips: "record<Id: string>"
    post-hub-spaces-space-id-documents: "record<Id: string>"
    get-hub-spaces-space-id-menus: "record<Folders: table<Id: string, Name: string>, Workbooks: list<string>>"
    post-hub-spaces-space-id-payslips: "record<Id: string>"
    get-menus: "record<Label: string, MenuId: string, Pictogram: string, SubMenus: table<Label: string, MenuId: string, Pictogram: string>>"
    post-menus-menu-id-documents: "record<Report: record>"
    get-profile: "record<Birth: record<City: string, Country: string, Date: string, ZipCode: string>, BirthName: string, FirstName: string, Name: string, PrivateSpaceId: string, Sex: string, Status: string>"
    get-profile-id-file: "record<Birth: record<City: string, Country: string, Date: string, ZipCode: string>, BirthName: string, FirstName: string, IDFile: record<Content64Encoded: string>, Name: string, PrivateSpaceId: string, Sex: string, Status: string>"
    post-registration: "record<Private: record<FolderId: string, SpaceId: string>>"
    get-session: "record<MemberId: string, Scope: string>"
    get-spaces: "table<Id: string, ModificationDate: string, Name: string, RegistrationNumber: string, Type: string>"
    post-spaces: "record<Id: string>"
    get-spaces-all: "table<Id: string, ModificationDate: string, Name: string, RegistrationNumber: string, Type: string>"
    get-spaces-id: "record<Id: string, ModificationDate: string, Name: string, Type: string>"
    get-spaces-id-accounting-year: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, NetIncome: float, NetPosition: float, Start: string, Tax: float, TaxableIncome: float, Turnover: float>"
    post-spaces-id-accounting-year: "record<Id: string>"
    get-spaces-id-collective-decision: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, Date: string, DividendDistributions: float, DividendDistributionsDate: string, Event: string>"
    post-spaces-id-collective-decision: "record<Id: string>"
    get-spaces-id-company-entities: "table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, ApeCode: string, LegalName: string, LegalStatut: string, RegistrationNumber: string, Type: string, VatNumber: string>"
    post-spaces-id-company-entities: "record<Id: string>"
    get-spaces-id-company-entities-all: "table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, ApeCode: string, LegalName: string, LegalStatut: string, RegistrationNumber: string, Type: string, VatNumber: string>"
    get-spaces-id-company-entities-company-id: "record<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, ApeCode: string, LegalName: string, LegalStatut: string, RegistrationNumber: string, Type: string, VatNumber: string>"
    get-spaces-id-company-entities-person-id-details: "table<Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Designation: string, Email: list<string>, Phone: list<string>>"
    post-spaces-id-documents-download: "record<ZipFile: string>"
    get-spaces-id-folders-folder-id-persons-member-id: "table<Active: string, IsAdmin: string, MemberId: string, Name: string, Role: string>"
    get-spaces-id-groups: "table<EndDate: string, Id: string, Name: string>"
    post-spaces-id-groups: "record<Id: string>"
    get-spaces-id-groups-all: "table<EndDate: string, Id: string, Name: string>"
    get-spaces-id-groups-group-id: "record<EndDate: string, Id: string, Name: string, Accesses: record<Id: string, Name: string, Right: string>, Persons: record<MemberId: string>>"
    get-spaces-id-legal: "record<IdentificationNumber: string, RegistrationDate: string, RegistrationNumber: string, VATNumber: string>"
    get-spaces-id-logo: "record<Id: string, Logo: record<Content64Encoded: string, Extension: string>, ModificationDate: string, Name: string, Type: string>"
    get-spaces-id-persons: "table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Birth: record<Date: int, Place: string>, Email: string, FirstName: string, Function: list<string>, MemberId: string, Mobile: string, Sex: string, Validated: string>"
    post-spaces-id-persons: "record<Id: string>"
    get-spaces-id-persons-all: "table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Birth: record<Date: int, Place: string>, Email: string, FirstName: string, Function: list<string>, MemberId: string, Mobile: string, Sex: string, Validated: string>"
    get-spaces-id-persons-person-id: "record<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Birth: record<Date: int, Place: string>, Email: string, FirstName: string, Function: list<string>, MemberId: string, Mobile: string, Sex: string, Validated: string>"
    get-spaces-id-persons-person-id-details: "table<Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Designation: string, Email: list<string>, Phone: list<string>>"
    get-spaces-id-persons-person-id-folders: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-id-persons-person-id-groups: "table<EndDate: string, Id: string, Name: string>"
    get-spaces-id-persons-person-id-portfolios: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Designation: string>"
    post-spaces-id-persons-person-id-portfolios: "record<Id: string>"
    get-spaces-id-professional-vehicles: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, DateIn: string, DateOut: string, Designation: string, Value: float, Brand: string, CompanyTax: bool, Model: string, RegistrationDate: string, RegistrationNumber: string, Type: string>"
    post-spaces-id-professional-vehicles: "record<Id: string>"
    get-spaces-id-settings-nf203-logs: "record<Enabled: bool>"
    get-spaces-id-status: "table<Code: string, Comment: string, Label: string>"
    get-spaces-id-tax-contracts: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, Designation: string, End: string, Start: string>"
    post-spaces-id-tax-contracts: "record<Id: string>"
    get-spaces-id-triggers: "table<Date: string, Event: string>"
    get-spaces-space-id-company-entities-id-follow-ups: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-space-id-customers: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>"
    get-spaces-space-id-customers-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>"
    get-spaces-space-id-documents: "table<Author: string, Code: string, Comment: string, Date: string, Extension: string, Folders: list<record>, Id: string, Title: string>"
    get-spaces-space-id-documents-document-id-extend: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Extend: record>"
    post-spaces-space-id-documents-document-id-extend: "record<Id: string>"
    get-spaces-space-id-documents-document-id-folders: "record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Folders: table<Id: string, Name: string>, Id: string, Title: string>"
    post-spaces-space-id-documents-document-id-mailing: "record<PageNb: float, Price: string>"
    get-spaces-space-id-documents-document-id-mailingprice: "record<PageNb: float, Price: string>"
    get-spaces-space-id-documents-document-id-versions: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string>"
    post-spaces-space-id-documents-document-id-versions: "record<Id: string>"
    get-spaces-space-id-documents-document-id-versions-current: "record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, Id: string, Title: string>"
    get-spaces-space-id-documents-id-access: "record<Access: table<DownloadedOn: string, FirstName: string, Name: string, SeenOn: string>, Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, Id: string, Title: string>"
    get-spaces-space-id-documents-id-accounting: "record<Accounting: record<AccountedOn: string, Workbook: string, YearMonth: string>, Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, Id: string, Title: string>"
    get-spaces-space-id-documents-id-download: "record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, File: record<Content64Encoded: string>, Id: string, Title: string>"
    get-spaces-space-id-employees: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>"
    get-spaces-space-id-employees-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>"
    get-spaces-space-id-employers: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>"
    get-spaces-space-id-employers-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>"
    get-spaces-space-id-extend: "record<Extend: record, Id: string, ModificationDate: string, Name: string, Type: string>"
    post-spaces-space-id-extend: "record<Id: string>"
    get-spaces-space-id-folders: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-space-id-folders-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-space-id-folders-folder-id-nominative-social-declarations-document-id: "record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, NetAmount: float, TotalGrossAmount: float, PayrollId: string>"
    post-spaces-space-id-folders-folder-id-payrolls-document-id-refresh: "record<Id: string>"
    get-spaces-space-id-folders-id: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-space-id-folders-id-accountings: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Accounting: record<AccountedOn: string, Workbook: string, YearMonth: string>>"
    get-spaces-space-id-folders-id-accountings-journal: "table<AccountingDate: string, AccountingDocumentId: string, Class: string, Code: string, DeliveryDate: string, Id: string, Number: int, TargetFolder: record<Id: string, Name: string>, Workbook: string, YearMonth: string>"
    get-spaces-space-id-folders-id-bank: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>"
    get-spaces-space-id-folders-id-bank-statements: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, AccountedOn: string, Balance: float, Number: float, StatementDate: string>"
    post-spaces-space-id-folders-id-bank-statements: "record<Id: string>"
    get-spaces-space-id-folders-id-common-folders: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    post-spaces-space-id-folders-id-common-folders: "record<Id: string>"
    get-spaces-space-id-folders-id-common-folders-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-space-id-folders-id-contracting-partner: "table<Class: string, Id: string, Role: string>"
    get-spaces-space-id-folders-id-contracting-partner-space: "table<Class: string, Id: string, Role: string>"
    get-spaces-space-id-folders-id-contractual-documents: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: string, Designation: string, Reference: string, StartDate: string, Type: string>"
    post-spaces-space-id-folders-id-contractual-documents: "record<Id: string>"
    get-spaces-space-id-folders-id-contractual-relationship: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>"
    get-spaces-space-id-folders-id-coporate-tax-declarations: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: float, DeclarationDate: string, Order: string, Rate: float, TaxBase: float>"
    post-spaces-space-id-folders-id-coporate-tax-declarations: "record<Id: string>"
    get-spaces-space-id-folders-id-customer: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, Actors: table<Active: string, IsAdmin: string, MemberId: string, Name: string, Role: string>, ClientSpaceId: string, PortfolioId: string, SecondaryPortfolioIds: list<string>>"
    get-spaces-space-id-folders-id-deliveries-journal: "table<Author: string, Class: string, DeleteDate: string, DeliveryDate: string, Id: string, Number: int, TargetFolder: record<Id: string, Name: string>>"
    get-spaces-space-id-folders-id-documents: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string>"
    post-spaces-space-id-folders-id-documents: "record<Id: string>"
    get-spaces-space-id-folders-id-employee: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>"
    get-spaces-space-id-folders-id-expense-proofs: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Account: string, ArchivalDate: string, ExpenseDate: string, InclVAT: float, Provider: string, Reason: string, Status: string, VAT: float>"
    post-spaces-space-id-folders-id-expense-proofs: "record<Id: string>"
    get-spaces-space-id-folders-id-expense-reports: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, BeforeVAT: float, ExpenseDate: string, InclVAT: float, ProcessingDate: string, VAT: float>"
    post-spaces-space-id-folders-id-expense-reports: "record<Id: string>"
    get-spaces-space-id-folders-id-expense-reports-expense-report-id-expense-proofs: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Account: string, ArchivalDate: string, ExpenseDate: string, InclVAT: float, Provider: string, Reason: string, Status: string, VAT: float>"
    get-spaces-space-id-folders-id-insurance: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, PolicyNumber: string>"
    get-spaces-space-id-folders-id-invoices: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, AccountedOn: string, BeforeVAT: float, DueDate: string, InclVAT: float, InvoiceDate: string, Number: string, PaymentDate: string, Type: string, VAT: float>"
    post-spaces-space-id-folders-id-invoices: "record<Id: string>"
    get-spaces-space-id-folders-id-legal-entity: "record<Class: string, Id: string>"
    get-spaces-space-id-folders-id-loan: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>"
    get-spaces-space-id-folders-id-messages: "table<Author: string, Id: string, Level: string, MessageDate: string, ModificationAuthor: string, ModificationDate: string, Text: string>"
    get-spaces-space-id-folders-id-messages-message-id: "record<Author: string, Id: string, Level: string, MessageDate: string, ModificationAuthor: string, ModificationDate: string, Text: string>"
    get-spaces-space-id-folders-id-nominative-social-declarations: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, NetAmount: float, TotalGrossAmount: float, PayrollId: string>"
    get-spaces-space-id-folders-id-other-taxes: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: float, DeclarationDate: string, Reference: string>"
    post-spaces-space-id-folders-id-other-taxes: "record<Id: string>"
    get-spaces-space-id-folders-id-passwords: "table<Comment: string, Designation: string, Ident: string, Link: string, Password: string, Id: string>"
    get-spaces-space-id-folders-id-passwords-password-id: "record<Comment: string, Designation: string, Ident: string, Link: string, Password: string, Id: string>"
    get-spaces-space-id-folders-id-payrolls: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, NetAmount: float, TotalGrossAmount: float>"
    post-spaces-space-id-folders-id-payrolls: "record<Id: string>"
    post-spaces-space-id-folders-id-payrolls-payroll-id-nominative-social-declaration: "record<Id: string>"
    get-spaces-space-id-folders-id-payslips: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, FixedGrossAmount: float, NetAmount: float, TotalGrossAmount: float, Vacation: float, VariableGrossAmount: float>"
    post-spaces-space-id-folders-id-payslips: "record<Id: string>"
    get-spaces-space-id-folders-id-provider: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>"
    get-spaces-space-id-folders-id-required-documents: "table<Comment: string, Date: string, DocIds: list<string>, Id: string, Name: string, Status: string>"
    post-spaces-space-id-folders-id-required-documents-requireddocumentid: "record<Id: string>"
    get-spaces-space-id-folders-id-sections: "table<Keywords: list<string>, Name: string, State: string, Type: string>"
    get-spaces-space-id-folders-id-social-contracts: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, ContractDate: string, ContractDuration: string, ContractualChange: string, Position: string, WageDevelopments: float>"
    post-spaces-space-id-folders-id-social-contracts: "record<Id: string>"
    get-spaces-space-id-folders-id-social-declarations: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: float, DeclarationDate: string>"
    post-spaces-space-id-folders-id-social-declarations: "record<Id: string>"
    get-spaces-space-id-folders-id-social-regimes: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>"
    get-spaces-space-id-folders-id-sum-invoices: "record<BeforeVAT: float, InclVAT: float, VAT: float>"
    get-spaces-space-id-folders-id-vat-declarations: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, CollectedVAT: float, CreditVAT: float, DeductibleVAT: float, End: string, ExemptTurnover: float, Number: string, PayableVAT: float, TaxableTurnover: float>"
    post-spaces-space-id-folders-id-vat-declarations: "record<Id: string>"
    get-spaces-space-id-folders-id-document-class: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string>"
    post-spaces-space-id-folders-id-document-class: "record<Id: string>"
    get-spaces-space-id-legal-entities-id-banks: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>"
    post-spaces-space-id-legal-entities-id-banks: "record<Id: string>"
    get-spaces-space-id-legal-entities-id-banks-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>"
    get-spaces-space-id-legal-entities-id-contracts: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string>"
    get-spaces-space-id-legal-entities-id-contractual-relationships: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>"
    get-spaces-space-id-legal-entities-id-contractual-relationships-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>"
    get-spaces-space-id-legal-entities-id-customers: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>"
    post-spaces-space-id-legal-entities-id-customers: "record<Id: string>"
    get-spaces-space-id-legal-entities-id-customers-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>"
    get-spaces-space-id-legal-entities-id-insurances: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, PolicyNumber: string>"
    post-spaces-space-id-legal-entities-id-insurances: "record<Id: string>"
    get-spaces-space-id-legal-entities-id-insurances-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, PolicyNumber: string>"
    get-spaces-space-id-legal-entities-id-loans: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>"
    post-spaces-space-id-legal-entities-id-loans: "record<Id: string>"
    get-spaces-space-id-legal-entities-id-loans-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>"
    get-spaces-space-id-legal-entities-id-providers: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>"
    post-spaces-space-id-legal-entities-id-providers: "record<Id: string>"
    get-spaces-space-id-legal-entities-id-providers-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>"
    get-spaces-space-id-legal-entities-id-social-regimes: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>"
    post-spaces-space-id-legal-entities-id-social-regimes: "record<Id: string>"
    get-spaces-space-id-legal-entities-id-social-regimes-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>"
    get-spaces-space-id-loans: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>"
    get-spaces-space-id-loans-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>"
    post-spaces-space-id-persons-id-call-for-document: "record<Id: string>"
    get-spaces-space-id-persons-id-employees: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>"
    post-spaces-space-id-persons-id-employees: "record<Id: string>"
    get-spaces-space-id-persons-id-employees-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>"
    get-spaces-space-id-persons-id-exchange: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-space-id-persons-id-follow-ups: "record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, ClientManagement: string, Invitation: record<Comment: string, PlayerEnd: string, Status: string>, Player: string>"
    get-spaces-space-id-persons-id-invitation: "record<ClientManagement: string, CodeMethod: any, EmployeeAccess: bool, Folders: table<Id: string, Name: string, Right: string>, GroupIds: list<string>, Groups: table<EndDate: string, Id: string, Name: string>, IsAdmin: bool, LinkMethod: record<Type: string>, Player: string, PlayerEnd: string, Status: string>"
    post-spaces-space-id-persons-id-invitation: "record<Id: string>"
    post-spaces-space-id-persons-id-invitation-invitation-id-send: "record<Id: string>"
    get-spaces-space-id-persons-member-id-folders-id: "record<Id: string, Right: string, About: string, ArchivalDate: string, Class: string, Home: bool, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>"
    get-spaces-space-id-providers: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>"
    get-spaces-space-id-providers-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>"
    get-spaces-space-id-search: "record<Count: table<Class: string, Count: int>, Results: table<Class: string, Extract: record, Id: string, Label: string, Location: list, Score: float, Specific: record>, TotalCount: int>"
    get-spaces-space-id-social-regimes: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>"
    get-spaces-space-id-social-regimes-all: "table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>"
    get-spaces-space-id-spaces-invoicings: "table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, InvoiceNumber: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-box-menus" "get-business-groups" "patch-business-groups" "post-business-groups" "get-business-groups-all" "get-business-groups-id" "get-business-groups-id-spaces" "delete-business-groups-id-spaces-space-id" "post-business-groups-id-spaces-space-id-legal-entities-person-id-customers-folder-id-guest-in-space" "post-business-groups-id-spaces-space-id-legal-entities-person-id-customers-folder-id-spaces" "get-hub-business-groups-id-menus" "post-hub-documents" "get-hub-menus" "get-hub-menus-all" "post-hub-payslips" "post-hub-spaces-space-id-documents" "get-hub-spaces-space-id-menus" "post-hub-spaces-space-id-payslips" "get-menus" "post-menus-menu-id-documents" "get-profile" "patch-profile" "post-profile" "patch-profile-email" "get-profile-id-file" "patch-profile-mobile" "get-registration" "post-registration" "get-session" "get-spaces" "post-spaces" "get-spaces-all" "delete-spaces-id" "get-spaces-id" "patch-spaces-id" "get-spaces-id-accounting-year" "post-spaces-id-accounting-year" "get-spaces-id-collective-decision" "post-spaces-id-collective-decision" "get-spaces-id-company-entities" "post-spaces-id-company-entities" "get-spaces-id-company-entities-all" "get-spaces-id-company-entities-company-id" "patch-spaces-id-company-entities-company-id" "get-spaces-id-company-entities-person-id-details" "post-spaces-id-company-entities-person-id-details" "delete-spaces-id-company-entities-person-id-details-designation" "post-spaces-id-documents-download" "get-spaces-id-folders-folder-id-persons-member-id" "patch-spaces-id-folders-folder-id-persons-member-id" "patch-spaces-id-folders-folder-id-persons-member-id-activeaccess" "patch-spaces-id-folders-folder-id-persons-member-id-unactiveaccess" "post-spaces-id-folders-folder-id-persons-person-id-guest-in-space" "get-spaces-id-groups" "post-spaces-id-groups" "get-spaces-id-groups-all" "get-spaces-id-groups-group-id" "patch-spaces-id-groups-group-id" "delete-spaces-id-groups-group-id-folders-folder-id" "patch-spaces-id-groups-group-id-folders-folder-id" "delete-spaces-id-groups-group-id-persons-member-id" "patch-spaces-id-groups-group-id-persons-member-id" "get-spaces-id-legal" "patch-spaces-id-legal" "get-spaces-id-logo" "get-spaces-id-persons" "post-spaces-id-persons" "get-spaces-id-persons-all" "patch-spaces-id-persons-member-id-player" "delete-spaces-id-persons-person-id" "get-spaces-id-persons-person-id" "patch-spaces-id-persons-person-id" "get-spaces-id-persons-person-id-details" "post-spaces-id-persons-person-id-details" "delete-spaces-id-persons-person-id-details-designation" "get-spaces-id-persons-person-id-folders" "get-spaces-id-persons-person-id-groups" "get-spaces-id-persons-person-id-portfolios" "post-spaces-id-persons-person-id-portfolios" "patch-spaces-id-portfolios-portfolio-id-persons-member-id" "get-spaces-id-professional-vehicles" "post-spaces-id-professional-vehicles" "get-spaces-id-settings-nf203-logs" "post-spaces-id-settings-nf203-logs" "get-spaces-id-status" "post-spaces-id-status" "delete-spaces-id-status-code" "get-spaces-id-tax-contracts" "post-spaces-id-tax-contracts" "get-spaces-id-triggers" "delete-spaces-id-triggers-name" "post-spaces-id-triggers-name" "delete-spaces-space-id-common-folders-id" "patch-spaces-space-id-common-folders-id" "get-spaces-space-id-company-entities-id-follow-ups" "get-spaces-space-id-customers" "get-spaces-space-id-customers-all" "get-spaces-space-id-documents" "patch-spaces-space-id-documents-document-id" "get-spaces-space-id-documents-document-id-extend" "post-spaces-space-id-documents-document-id-extend" "get-spaces-space-id-documents-document-id-folders" "post-spaces-space-id-documents-document-id-mailing" "get-spaces-space-id-documents-document-id-mailingprice" "get-spaces-space-id-documents-document-id-versions" "post-spaces-space-id-documents-document-id-versions" "get-spaces-space-id-documents-document-id-versions-current" "get-spaces-space-id-documents-id-access" "get-spaces-space-id-documents-id-accounting" "get-spaces-space-id-documents-id-download" "get-spaces-space-id-employees" "get-spaces-space-id-employees-all" "get-spaces-space-id-employers" "get-spaces-space-id-employers-all" "get-spaces-space-id-extend" "post-spaces-space-id-extend" "get-spaces-space-id-folders" "get-spaces-space-id-folders-all" "delete-spaces-space-id-folders-folder-id-bank-statements-document-id" "patch-spaces-space-id-folders-folder-id-bank-statements-document-id" "delete-spaces-space-id-folders-folder-id-contractual-documents-document-id" "patch-spaces-space-id-folders-folder-id-contractual-documents-document-id" "delete-spaces-space-id-folders-folder-id-corporate-tax-declarations-document-id" "patch-spaces-space-id-folders-folder-id-corporate-tax-declarations-document-id" "delete-spaces-space-id-folders-folder-id-expense-proofs-document-id" "patch-spaces-space-id-folders-folder-id-expense-proofs-document-id" "delete-spaces-space-id-folders-folder-id-expense-reports-document-id" "patch-spaces-space-id-folders-folder-id-expense-reports-document-id" "delete-spaces-space-id-folders-folder-id-invoices-document-id" "patch-spaces-space-id-folders-folder-id-invoices-document-id" "get-spaces-space-id-folders-folder-id-nominative-social-declarations-document-id" "delete-spaces-space-id-folders-folder-id-other-taxes-document-id" "patch-spaces-space-id-folders-folder-id-other-taxes-document-id" "delete-spaces-space-id-folders-folder-id-payrolls-document-id" "patch-spaces-space-id-folders-folder-id-payrolls-document-id" "post-spaces-space-id-folders-folder-id-payrolls-document-id-refresh" "delete-spaces-space-id-folders-folder-id-payslips-document-id" "patch-spaces-space-id-folders-folder-id-payslips-document-id" "delete-spaces-space-id-folders-folder-id-social-contracts-document-id" "patch-spaces-space-id-folders-folder-id-social-contracts-document-id" "delete-spaces-space-id-folders-folder-id-social-declarations-document-id" "patch-spaces-space-id-folders-folder-id-social-declarations-document-id" "delete-spaces-space-id-folders-folder-id-vat-declarations-document-id" "patch-spaces-space-id-folders-folder-id-vat-declarations-document-id" "get-spaces-space-id-folders-id" "patch-spaces-space-id-folders-id" "delete-spaces-space-id-folders-id-accounting-year" "patch-spaces-space-id-folders-id-accounting-year" "get-spaces-space-id-folders-id-accountings" "get-spaces-space-id-folders-id-accountings-journal" "delete-spaces-space-id-folders-id-bank" "get-spaces-space-id-folders-id-bank" "patch-spaces-space-id-folders-id-bank" "get-spaces-space-id-folders-id-bank-statements" "post-spaces-space-id-folders-id-bank-statements" "patch-spaces-space-id-folders-id-collective-decision" "get-spaces-space-id-folders-id-common-folders" "post-spaces-space-id-folders-id-common-folders" "get-spaces-space-id-folders-id-common-folders-all" "get-spaces-space-id-folders-id-contracting-partner" "get-spaces-space-id-folders-id-contracting-partner-space" "get-spaces-space-id-folders-id-contractual-documents" "post-spaces-space-id-folders-id-contractual-documents" "get-spaces-space-id-folders-id-contractual-relationship" "get-spaces-space-id-folders-id-coporate-tax-declarations" "post-spaces-space-id-folders-id-coporate-tax-declarations" "delete-spaces-space-id-folders-id-customer" "get-spaces-space-id-folders-id-customer" "patch-spaces-space-id-folders-id-customer" "get-spaces-space-id-folders-id-deliveries-journal" "get-spaces-space-id-folders-id-documents" "post-spaces-space-id-folders-id-documents" "patch-spaces-space-id-folders-id-documents-document-id-detach" "delete-spaces-space-id-folders-id-employee" "get-spaces-space-id-folders-id-employee" "patch-spaces-space-id-folders-id-employee" "get-spaces-space-id-folders-id-expense-proofs" "post-spaces-space-id-folders-id-expense-proofs" "get-spaces-space-id-folders-id-expense-reports" "post-spaces-space-id-folders-id-expense-reports" "get-spaces-space-id-folders-id-expense-reports-expense-report-id-expense-proofs" "delete-spaces-space-id-folders-id-insurance" "get-spaces-space-id-folders-id-insurance" "patch-spaces-space-id-folders-id-insurance" "get-spaces-space-id-folders-id-invoices" "post-spaces-space-id-folders-id-invoices" "get-spaces-space-id-folders-id-legal-entity" "delete-spaces-space-id-folders-id-loan" "get-spaces-space-id-folders-id-loan" "patch-spaces-space-id-folders-id-loan" "get-spaces-space-id-folders-id-messages" "post-spaces-space-id-folders-id-messages" "get-spaces-space-id-folders-id-messages-message-id" "patch-spaces-space-id-folders-id-messages-message-id" "get-spaces-space-id-folders-id-nominative-social-declarations" "get-spaces-space-id-folders-id-other-taxes" "post-spaces-space-id-folders-id-other-taxes" "get-spaces-space-id-folders-id-passwords" "post-spaces-space-id-folders-id-passwords" "delete-spaces-space-id-folders-id-passwords-password-id" "get-spaces-space-id-folders-id-passwords-password-id" "patch-spaces-space-id-folders-id-passwords-password-id" "get-spaces-space-id-folders-id-payrolls" "post-spaces-space-id-folders-id-payrolls" "delete-spaces-space-id-folders-id-payrolls-payroll-id-nominative-social-declaration" "post-spaces-space-id-folders-id-payrolls-payroll-id-nominative-social-declaration" "get-spaces-space-id-folders-id-payslips" "post-spaces-space-id-folders-id-payslips" "delete-spaces-space-id-folders-id-portfolio-portfolio-id" "delete-spaces-space-id-folders-id-professional-vehicle" "patch-spaces-space-id-folders-id-professional-vehicle" "delete-spaces-space-id-folders-id-provider" "get-spaces-space-id-folders-id-provider" "patch-spaces-space-id-folders-id-provider" "get-spaces-space-id-folders-id-required-documents" "patch-spaces-space-id-folders-id-required-documents-requireddocumentid" "post-spaces-space-id-folders-id-required-documents-requireddocumentid" "delete-spaces-space-id-folders-id-required-documents-requireddocumentid-documents-document-id" "get-spaces-space-id-folders-id-sections" "get-spaces-space-id-folders-id-social-contracts" "post-spaces-space-id-folders-id-social-contracts" "get-spaces-space-id-folders-id-social-declarations" "post-spaces-space-id-folders-id-social-declarations" "delete-spaces-space-id-folders-id-social-regimes" "get-spaces-space-id-folders-id-social-regimes" "patch-spaces-space-id-folders-id-social-regimes" "get-spaces-space-id-folders-id-sum-invoices" "delete-spaces-space-id-folders-id-tax-contract" "patch-spaces-space-id-folders-id-tax-contract" "get-spaces-space-id-folders-id-vat-declarations" "post-spaces-space-id-folders-id-vat-declarations" "delete-spaces-space-id-folders-id-document-class" "get-spaces-space-id-folders-id-document-class" "post-spaces-space-id-folders-id-document-class" "get-spaces-space-id-legal-entities-id-banks" "post-spaces-space-id-legal-entities-id-banks" "get-spaces-space-id-legal-entities-id-banks-all" "get-spaces-space-id-legal-entities-id-contracts" "get-spaces-space-id-legal-entities-id-contractual-relationships" "get-spaces-space-id-legal-entities-id-contractual-relationships-all" "get-spaces-space-id-legal-entities-id-customers" "post-spaces-space-id-legal-entities-id-customers" "get-spaces-space-id-legal-entities-id-customers-all" "get-spaces-space-id-legal-entities-id-insurances" "post-spaces-space-id-legal-entities-id-insurances" "get-spaces-space-id-legal-entities-id-insurances-all" "get-spaces-space-id-legal-entities-id-loans" "post-spaces-space-id-legal-entities-id-loans" "get-spaces-space-id-legal-entities-id-loans-all" "get-spaces-space-id-legal-entities-id-providers" "post-spaces-space-id-legal-entities-id-providers" "get-spaces-space-id-legal-entities-id-providers-all" "get-spaces-space-id-legal-entities-id-social-regimes" "post-spaces-space-id-legal-entities-id-social-regimes" "get-spaces-space-id-legal-entities-id-social-regimes-all" "get-spaces-space-id-loans" "get-spaces-space-id-loans-all" "patch-spaces-space-id-persons-id-call-for-document" "post-spaces-space-id-persons-id-call-for-document" "get-spaces-space-id-persons-id-employees" "post-spaces-space-id-persons-id-employees" "get-spaces-space-id-persons-id-employees-all" "get-spaces-space-id-persons-id-exchange" "get-spaces-space-id-persons-id-follow-ups" "delete-spaces-space-id-persons-id-guest-in-space" "patch-spaces-space-id-persons-id-guest-in-space" "post-spaces-space-id-persons-id-guest-in-space" "delete-spaces-space-id-persons-id-invitation" "get-spaces-space-id-persons-id-invitation" "patch-spaces-space-id-persons-id-invitation" "post-spaces-space-id-persons-id-invitation" "post-spaces-space-id-persons-id-invitation-invitation-id-send" "get-spaces-space-id-persons-member-id-folders-id" "patch-spaces-space-id-persons-member-id-folders-id" "get-spaces-space-id-providers" "get-spaces-space-id-providers-all" "get-spaces-space-id-search" "get-spaces-space-id-social-regimes" "get-spaces-space-id-social-regimes-all" "get-spaces-space-id-spaces-invoicings" "commands"] | sort) } | get name | first)
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

# Returns predefined folders and workbooks of the Box for all the spaces
#
# GET /box/menus
# Returns: record<Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>
export def "get-box-menus" [
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
    path: "/box/menus"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of groups custom ordered by name
#
# GET /business-groups
# Returns: table<Id: string, ModificationDate: string, Name: string>
export def "get-business-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the group (e.g. Dupond)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/business-groups"
    query: [{name: Name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an object
#
# PATCH /business-groups
export def "patch-business-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # e.g. Client Durand
]: any -> any {
  $in | http-request {
    method: patch
    path: "/business-groups"
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a group (only for managers and ADN collaborators)
#
# POST /business-groups
# Returns: record<Id: string>
export def "post-business-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # e.g. Client Durand
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/business-groups"
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of groups custom for managers
#
# GET /business-groups/all
# Returns: table<Id: string, ModificationDate: string, Name: string>
export def "get-business-groups-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the group
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/business-groups/all"
    query: [{name: Name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a group
#
# GET /business-groups/{id}
# Returns: record<Id: string, ModificationDate: string, Name: string>
export def "get-business-groups-id" [
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
    path: "/business-groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns spaces of the business group with id
#
# GET /business-groups/{id}/spaces
# Returns: table<Id: string, ModificationDate: string, Name: string, RegistrationNumber: string, Type: string>
export def "get-business-groups-id-spaces" [
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
  --name: string # Name of the space (e.g. Mon Entreprise)
  --type: string@type-completer # Type of the space (e.g. private)
  --registration-number: string # registration number of the space (e.g. 12345)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/business-groups/{id}/spaces"
    path_params: [{name: id, var: id}]
    query: [{name: Name, var: name}, {name: Type, var: type}, {name: RegistrationNumber, var: registration_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, type: $type, registration_number: $registration_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a customer space from partner
#
# DELETE /business-groups/{id}/spaces/{spaceId}
export def "delete-business-groups-id-spaces-space-id" [
  id: string
  space_id: string
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
    path: "/business-groups/{id}/spaces/{spaceId}"
    path_params: [{name: id, var: id}, {name: spaceId, var: space_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, space_id: $space_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# send an invitation to manager the private space of personId
#
# POST /business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/guest-in-space
# Returns: record<Id: string>
export def "post-business-groups-id-spaces-space-id-legal-entities-person-id-customers-folder-id-guest-in-space" [
  id: string
  space_id: string
  person_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>@groups-completer # e.g. [tax, legal]
  role: string@role-completer # e.g. collaborator
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/guest-in-space"
    path_params: [{name: id, var: id}, {name: spaceId, var: space_id}, {name: personId, var: person_id}, {name: folderId, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Groups, var: groups}, {name: Role, var: role}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, space_id: $space_id, person_id: $person_id, folder_id: $folder_id, groups: $groups, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Space in a group
#
# POST /business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/spaces
# Returns: record<Id: string>
export def "post-business-groups-id-spaces-space-id-legal-entities-person-id-customers-folder-id-spaces" [
  id: string
  space_id: string
  person_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: record # shape: {Content64Encoded?: string, Name?: string}
  --name: string # e.g. Mon Entreprise
  --template-space-id: string # e.g. PKOJOFOFKAOKF
  type: string@type-completer-1 # e.g. company
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/spaces"
    path_params: [{name: id, var: id}, {name: spaceId, var: space_id}, {name: personId, var: person_id}, {name: folderId, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Logo, var: logo}, {name: Name, var: name}, {name: TemplateSpaceId, var: template_space_id}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, space_id: $space_id, person_id: $person_id, folder_id: $folder_id, logo: $logo, name: $name, template_space_id: $template_space_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns predefined folders and workbooks of the Hub for all the spaces of the business group
#
# GET /hub/business-groups/{Id}/menus
# Returns: record<Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>
export def "get-hub-business-groups-id-menus" [
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
    path: "/hub/business-groups/{Id}/menus"
    path_params: [{name: Id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a document (this document is analyzed to be saved in the correct folder and correct space)
#
# POST /hub/documents
# Returns: record<Id: string>
export def "post-hub-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --add-contract-allowed: oneof<nothing, bool> # e.g. true
  --author: string # e.g. Antoine Dupond
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/hub/documents"
    body: {content_type: "application/json", kind: json, fields: [{name: Accounting, var: accounting}, {name: AddContractAllowed, var: add_contract_allowed}, {name: Author, var: author}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    accounting: $accounting, add_contract_allowed: $add_contract_allowed, author: $author, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns predefined folders and workbooks of the Hub for all the spaces
#
# GET /hub/menus
# Returns: record<Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>
export def "get-hub-menus" [
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
    path: "/hub/menus"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns predefined folders and workbooks of the Hub for all the spaces and customer spaces
#
# GET /hub/menus/all
# Returns: record<BusinessGroup: record<Id: string, Name: string>, Menus: table<Class: string, Id: string, Name: string>, SpaceId: string, SpaceName: string>
export def "get-hub-menus-all" [
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
    path: "/hub/menus/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a payslip (this document is analyzed to be saved in the correct folder and correct space)
#
# POST /hub/payslips
# Returns: record<Id: string>
export def "post-hub-payslips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --add-contract-allowed: oneof<nothing, bool> # e.g. true
  --author: string # e.g. Antoine Dupond
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/hub/payslips"
    body: {content_type: "application/json", kind: json, fields: [{name: Accounting, var: accounting}, {name: AddContractAllowed, var: add_contract_allowed}, {name: Author, var: author}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    accounting: $accounting, add_contract_allowed: $add_contract_allowed, author: $author, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a document in a space (this document is analyzed to be saved in the correct folder)
#
# POST /hub/spaces/{spaceId}/documents
# Returns: record<Id: string>
export def "post-hub-spaces-space-id-documents" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/hub/spaces/{spaceId}/documents"
    path_params: [{name: spaceId, var: space_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns predefined folders and workbooks of the Hub for the space
#
# GET /hub/spaces/{spaceId}/menus
# Returns: record<Folders: table<Id: string, Name: string>, Workbooks: list<string>>
export def "get-hub-spaces-space-id-menus" [
  space_id: string
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
    path: "/hub/spaces/{spaceId}/menus"
    path_params: [{name: spaceId, var: space_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a payslip in a space (this document is analyzed to be saved in the correct folder)
#
# POST /hub/spaces/{spaceId}/payslips
# Returns: record<Id: string>
export def "post-hub-spaces-space-id-payslips" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/hub/spaces/{spaceId}/payslips"
    path_params: [{name: spaceId, var: space_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns predefined entries
#
# GET /menus
# Returns: record<Label: string, MenuId: string, Pictogram: string, SubMenus: table<Label: string, MenuId: string, Pictogram: string>>
export def "get-menus" [
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
    path: "/menus"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# add a document to the target menuId
#
# POST /menus/{menuId}/documents
# Returns: record<Report: record>
export def "post-menus-menu-id-documents" [
  menu_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: string # e.g. Antoine Dupond
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/menus/{menuId}/documents"
    path_params: [{name: menuId, var: menu_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Author, var: author}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    menu_id: $menu_id, author: $author, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns status of member
#
# GET /profile
# Returns: record<Birth: record<City: string, Country: string, Date: string, ZipCode: string>, BirthName: string, FirstName: string, Name: string, PrivateSpaceId: string, Sex: string, Status: string>
export def "get-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract: string # to get a contract (if not signed error 404 + html contract) (e.g. member)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/profile"
    query: [{name: Contract, var: contract}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contract: $contract
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify infos of profile
#
# PATCH /profile
export def "patch-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --birth: record # shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
  --birth-name: string # e.g. Dupond
  --email: string # e.g. paule@durand.fr
  --first-name: string # e.g. Paule
  --id-file: record # shape: {Content64Encoded?: string, Name?: string}
  --name: string # e.g. Durand
  --sex: string@sex-completer
]: any -> any {
  $in | http-request {
    method: patch
    path: "/profile"
    body: {content_type: "application/json", kind: json, fields: [{name: Birth, var: birth}, {name: BirthName, var: birth_name}, {name: Email, var: email}, {name: FirstName, var: first_name}, {name: IDFile, var: id_file}, {name: Name, var: name}, {name: Sex, var: sex}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    birth: $birth, birth_name: $birth_name, email: $email, first_name: $first_name, id_file: $id_file, name: $name, sex: $sex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create infos of profile
#
# POST /profile
export def "post-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  birth: record # shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
  birth_name: string # e.g. Dupond
  email: string # e.g. paule@durand.fr
  first_name: string # e.g. Paule
  --id-file: record # shape: {Content64Encoded?: string, Name?: string}
  name: string # e.g. Durand
  sex: string@sex-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/profile"
    body: {content_type: "application/json", kind: json, fields: [{name: Birth, var: birth}, {name: BirthName, var: birth_name}, {name: Email, var: email}, {name: FirstName, var: first_name}, {name: IDFile, var: id_file}, {name: Name, var: name}, {name: Sex, var: sex}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    birth: $birth, birth_name: $birth_name, email: $email, first_name: $first_name, id_file: $id_file, name: $name, sex: $sex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify email of profile
#
# PATCH /profile/email
export def "patch-profile-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # e.g. paule@durand.fr
  --email-code: string # e.g. 1256
  --sms-code: string # e.g. FAHF
]: any -> any {
  $in | http-request {
    method: patch
    path: "/profile/email"
    body: {content_type: "application/json", kind: json, fields: [{name: Email, var: email}, {name: EmailCode, var: email_code}, {name: SMSCode, var: sms_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, email_code: $email_code, sms_code: $sms_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns status of member
#
# GET /profile/id-file
# Returns: record<Birth: record<City: string, Country: string, Date: string, ZipCode: string>, BirthName: string, FirstName: string, IDFile: record<Content64Encoded: string>, Name: string, PrivateSpaceId: string, Sex: string, Status: string>
export def "get-profile-id-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --contract: string # to get a contract (if not signed error 404 + html contract) (e.g. member)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/profile/id-file"
    query: [{name: Contract, var: contract}]
    accept: ["application/json", "multipart/form-data"]
    ok: [200]
    auth: bearer
  } {
    contract: $contract
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# modify mobile of profile
#
# PATCH /profile/mobile
export def "patch-profile-mobile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mobile: string # e.g. 33606060606
  --password: string # e.g. azerty
  --sms-code: string # e.g. FAHF
]: any -> any {
  $in | http-request {
    method: patch
    path: "/profile/mobile"
    body: {content_type: "application/json", kind: json, fields: [{name: Mobile, var: mobile}, {name: Password, var: password}, {name: SMSCode, var: sms_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mobile: $mobile, password: $password, sms_code: $sms_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the method to get the validation code or the link to register after invitation
#
# GET /registration
export def "get-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # Code of the invitation (required, e.g. HFIHA)
]: nothing -> any {
  http-request {
    method: get
    path: "/registration"
    query: [{name: Code, var: code, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# complete the invitation
#
# POST /registration
# Returns: record<Private: record<FolderId: string, SpaceId: string>>
export def "post-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # e.g. OJFOA
  --secret: string # e.g. 123456
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/registration"
    body: {content_type: "application/json", kind: json, fields: [{name: Code, var: code}, {name: Secret, var: secret}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    code: $code, secret: $secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns member id of user logged
#
# GET /session
# Returns: record<MemberId: string, Scope: string>
export def "get-session" [
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
    path: "/session"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns spaces of my group
#
# GET /spaces
# Returns: table<Id: string, ModificationDate: string, Name: string, RegistrationNumber: string, Type: string>
export def "get-spaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the space (e.g. Mon Entreprise)
  --type: string@type-completer # Type of the space (e.g. private)
  --registration-number: string # registration number of the space (e.g. 12345)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces"
    query: [{name: Name, var: name}, {name: Type, var: type}, {name: RegistrationNumber, var: registration_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, type: $type, registration_number: $registration_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Space in my group
#
# POST /spaces
# Returns: record<Id: string>
export def "post-spaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --legal-statut: string # e.g. SA
  --logo: record # shape: {Content64Encoded?: string, Name?: string}
  name: string # e.g. Mon Entreprise
  --registration-number: string # e.g. 5146486846
  --template-space-id: string # e.g. PKOJOFOFKAOKF
  type: string@type-completer-1 # e.g. company
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces"
    body: {content_type: "application/json", kind: json, fields: [{name: LegalStatut, var: legal_statut}, {name: Logo, var: logo}, {name: Name, var: name}, {name: RegistrationNumber, var: registration_number}, {name: TemplateSpaceId, var: template_space_id}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    legal_statut: $legal_statut, logo: $logo, name: $name, registration_number: $registration_number, template_space_id: $template_space_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all spaces
#
# GET /spaces/all
# Returns: table<Id: string, ModificationDate: string, Name: string, RegistrationNumber: string, Type: string>
export def "get-spaces-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the space (e.g. Mon Entreprise)
  --type: string@type-completer # Type of the space (e.g. private)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/all"
    query: [{name: Name, var: name}, {name: Type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Space (only space not delivered to customer)
#
# DELETE /spaces/{id}
export def "delete-spaces-id" [
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
    path: "/spaces/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a space
#
# GET /spaces/{id}
# Returns: record<Id: string, ModificationDate: string, Name: string, Type: string>
export def "get-spaces-id" [
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
    path: "/spaces/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Space (except private)
#
# PATCH /spaces/{id}
export def "patch-spaces-id" [
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
  --logo: record # shape: {Content64Encoded?: string, Name?: string}
  --name: string # e.g. Mon Entreprise
  --template-space-id: string # e.g. PHAOH8486
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Logo, var: logo}, {name: Name, var: name}, {name: TemplateSpaceId, var: template_space_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, logo: $logo, name: $name, template_space_id: $template_space_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of accounting years for the space {id}
#
# GET /spaces/{id}/accounting-year
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, NetIncome: float, NetPosition: float, Start: string, Tax: float, TaxableIncome: float, Turnover: float>
export def "get-spaces-id-accounting-year" [
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
  --end: string # End date of the accounting year (YYYYMM or YYYYMMDD) (range not available) (e.g. 201603)
  --effective-date: string # Effective date inside the accounting year (range not available) (e.g. 20160301)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/accounting-year"
    path_params: [{name: id, var: id}]
    query: [{name: End, var: end}, {name: EffectiveDate, var: effective_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, end: $end, effective_date: $effective_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a accounting year for the space id
#
# POST /spaces/{id}/accounting-year
# Returns: record<Id: string>
export def "post-spaces-id-accounting-year" [
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  end: string # e.g. 20181231
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --net-income: float # e.g. 52634.36
  --net-position: float # e.g. 14580.36
  --start: string # e.g. 20180101
  --tax: float # e.g. 45698.36
  --taxable-income: float # e.g. 869523.36
  --turnover: float # e.g. 1025.36
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/accounting-year"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: NetIncome, var: net_income}, {name: NetPosition, var: net_position}, {name: Start, var: start}, {name: Tax, var: tax}, {name: TaxableIncome, var: taxable_income}, {name: Turnover, var: turnover}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, about: $about, comment: $comment, end: $end, home: $home, keywords: $keywords, level: $level, net_income: $net_income, net_position: $net_position, start: $start, tax: $tax, taxable_income: $taxable_income, turnover: $turnover
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of collective decisions for the space {id}
#
# GET /spaces/{id}/collective-decision
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, Date: string, DividendDistributions: float, DividendDistributionsDate: string, Event: string>
export def "get-spaces-id-collective-decision" [
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
  --date: string # Date of the collective decision YYYMMDD (e.g. 20160302,null)
  --event: string # Event of the collective decision (see post for the list of events) (e.g. OGM)
  --range: string # index range of the results (e.g. 10-19)
  --has-company-registration-certificate: string@has-company-registration-certificate-completer # If true returns only invoices with a CompanyRegistrationCertificate (e.g. true)
  --has-status: string@has-status-completer # If true returns only invoices with a Status (e.g. true)
  --has-sirene-register: string@has-sirene-register-completer # If true returns only invoices with a SireneRegister (e.g. true)
  --has-minutes: string@has-minutes-completer # If true returns only invoices with Minutes (e.g. true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/collective-decision"
    path_params: [{name: id, var: id}]
    query: [{name: Date, var: date}, {name: Event, var: event}, {name: Range, var: range}, {name: HasCompanyRegistrationCertificate, var: has_company_registration_certificate}, {name: HasStatus, var: has_status}, {name: HasSireneRegister, var: has_sirene_register}, {name: HasMinutes, var: has_minutes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, date: $date, event: $event, range: $range, has_company_registration_certificate: $has_company_registration_certificate, has_status: $has_status, has_sirene_register: $has_sirene_register, has_minutes: $has_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a colletive decision for the space id
#
# POST /spaces/{id}/collective-decision
# Returns: record<Id: string>
export def "post-spaces-id-collective-decision" [
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  date: string # e.g. 20180202
  --dividend-distributions: float # e.g. 1025.36
  --dividend-distributions-date: string # e.g. 20180203
  event: string@event-completer # for space type 'company' enums allowed are 'EGM','CGM','OGM','ConstituentAssembly','SolePartner','OtherEvent','Office','ExecutiveCommittee','Consulting','Board','PartnersMeeting' and for space type 'association' enums allowed are 'EGM','CGM','OGM','Other','Office','ExecutiveCommittee' (e.g. EGM)
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/collective-decision"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: Date, var: date}, {name: DividendDistributions, var: dividend_distributions}, {name: DividendDistributionsDate, var: dividend_distributions_date}, {name: Event, var: event}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, about: $about, comment: $comment, date: $date, dividend_distributions: $dividend_distributions, dividend_distributions_date: $dividend_distributions_date, event: $event, home: $home, keywords: $keywords, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of company entities
#
# GET /spaces/{id}/company-entities
# Returns: table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, ApeCode: string, LegalName: string, LegalStatut: string, RegistrationNumber: string, Type: string, VatNumber: string>
export def "get-spaces-id-company-entities" [
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
  --name: string # Name of the company entity (e.g. Source de France)
  --legal-name: string # Legal name of the company entity (e.g. Source de France SAS)
  --registration-number: string # registration number of the company entity (e.g. 12356213854)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/company-entities"
    path_params: [{name: id, var: id}]
    query: [{name: Name, var: name}, {name: LegalName, var: legal_name}, {name: RegistrationNumber, var: registration_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, legal_name: $legal_name, registration_number: $registration_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Company Entity in a Space
#
# POST /spaces/{id}/company-entities
# Returns: record<Id: string>
export def "post-spaces-id-company-entities" [
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
  --ape-code: string # e.g. 420F
  --archival-date: string # e.g. 20160203
  --comment: string # e.g. my brother
  legal_name: string # e.g. Mon entreprise Dupond
  --legal-statut: string # e.g. SAS
  name: string # e.g. Dupond
  --registration-number: string # e.g. 236542158
  --type: string # e.g. EPT
  --vat-number: string # e.g. 46546847864
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/company-entities"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApeCode, var: ape_code}, {name: ArchivalDate, var: archival_date}, {name: Comment, var: comment}, {name: LegalName, var: legal_name}, {name: LegalStatut, var: legal_statut}, {name: Name, var: name}, {name: RegistrationNumber, var: registration_number}, {name: Type, var: type}, {name: VatNumber, var: vat_number}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ape_code: $ape_code, archival_date: $archival_date, comment: $comment, legal_name: $legal_name, legal_statut: $legal_statut, name: $name, registration_number: $registration_number, type: $type, vat_number: $vat_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of company entities even company entities archived
#
# GET /spaces/{id}/company-entities/all
# Returns: table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, ApeCode: string, LegalName: string, LegalStatut: string, RegistrationNumber: string, Type: string, VatNumber: string>
export def "get-spaces-id-company-entities-all" [
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
  --name: string # Name of the company entity (e.g. Source de France)
  --registration-number: string # registration number of the company entity (e.g. 12356213854)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/company-entities/all"
    path_params: [{name: id, var: id}]
    query: [{name: Name, var: name}, {name: RegistrationNumber, var: registration_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, registration_number: $registration_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a compay entity
#
# GET /spaces/{id}/company-entities/{companyId}
# Returns: record<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, ApeCode: string, LegalName: string, LegalStatut: string, RegistrationNumber: string, Type: string, VatNumber: string>
export def "get-spaces-id-company-entities-company-id" [
  id: string
  company_id: string
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
    path: "/spaces/{id}/company-entities/{companyId}"
    path_params: [{name: id, var: id}, {name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a company entity
#
# PATCH /spaces/{id}/company-entities/{companyId}
export def "patch-spaces-id-company-entities-company-id" [
  id: string
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ape-code: string # e.g. 420F
  --archival-date: string # e.g. 20160203
  --comment: string # e.g. my brother
  --legal-name: string # e.g. Mon entreprise Dupond
  --legal-statut: string # e.g. SAS
  --name: string # e.g. Dupond
  --registration-number: string # e.g. 236542158
  --type: string # e.g. EPT
  --vat-number: string # e.g. 46546847864
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/company-entities/{companyId}"
    path_params: [{name: id, var: id}, {name: companyId, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ApeCode, var: ape_code}, {name: ArchivalDate, var: archival_date}, {name: Comment, var: comment}, {name: LegalName, var: legal_name}, {name: LegalStatut, var: legal_statut}, {name: Name, var: name}, {name: RegistrationNumber, var: registration_number}, {name: Type, var: type}, {name: VatNumber, var: vat_number}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, company_id: $company_id, ape_code: $ape_code, archival_date: $archival_date, comment: $comment, legal_name: $legal_name, legal_statut: $legal_statut, name: $name, registration_number: $registration_number, type: $type, vat_number: $vat_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all details of a company entity
#
# GET /spaces/{id}/company-entities/{personId}/details
# Returns: table<Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Designation: string, Email: list<string>, Phone: list<string>>
export def "get-spaces-id-company-entities-person-id-details" [
  id: string
  person_id: string
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
    path: "/spaces/{id}/company-entities/{personId}/details"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace or Add a contact detail for a person
#
# POST /spaces/{id}/company-entities/{personId}/details
export def "post-spaces-id-company-entities-person-id-details" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  designation: string # e.g. Office
  --email: list<string>
  --phone: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{id}/company-entities/{personId}/details"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}, {name: Designation, var: designation}, {name: Email, var: email}, {name: Phone, var: phone}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, person_id: $person_id, address: $address, designation: $designation, email: $email, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a contact detail for a company entity
#
# DELETE /spaces/{id}/company-entities/{personId}/details/{designation}
export def "delete-spaces-id-company-entities-person-id-details-designation" [
  id: string
  person_id: string
  designation: string
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
    path: "/spaces/{id}/company-entities/{personId}/details/{designation}"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}, {name: designation, var: designation}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, person_id: $person_id, designation: $designation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create an archive with documents
#
# POST /spaces/{id}/documents/download
# Returns: record<ZipFile: string>
export def "post-spaces-id-documents-download" [
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
  document_id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/documents/download"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentId, var: document_id}]}
    accept: ["application/json", "multipart/form-data"]
    ok: [201]
    auth: bearer
  } {
    id: $id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# return the access of a person in a customer contract
#
# GET /spaces/{id}/folders/{folderId}/persons/{memberId}
# Returns: table<Active: string, IsAdmin: string, MemberId: string, Name: string, Role: string>
export def "get-spaces-id-folders-folder-id-persons-member-id" [
  id: string
  folder_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/folders/{folderId}/persons/{memberId}"
    path_params: [{name: id, var: id}, {name: folderId, var: folder_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, folder_id: $folder_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/Modify/Delete a person in a customer contract (except manager)
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}
export def "patch-spaces-id-folders-folder-id-persons-member-id" [
  id: string
  folder_id: string
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
  --groups: list<string>@groups-completer-1 # e.g. [social, legal]
  --is-admin: oneof<nothing, bool> # e.g. false
  --role: string@role-completer-1 # e.g. collaborator
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/folders/{folderId}/persons/{memberId}"
    path_params: [{name: id, var: id}, {name: folderId, var: folder_id}, {name: memberId, var: member_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Groups, var: groups}, {name: IsAdmin, var: is_admin}, {name: Role, var: role}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, folder_id: $folder_id, member_id: $member_id, groups: $groups, is_admin: $is_admin, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# open an access
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}/activeaccess
export def "patch-spaces-id-folders-folder-id-persons-member-id-activeaccess" [
  id: string
  folder_id: string
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
    method: patch
    path: "/spaces/{id}/folders/{folderId}/persons/{memberId}/activeaccess"
    path_params: [{name: id, var: id}, {name: folderId, var: folder_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, folder_id: $folder_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# close an access
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}/unactiveaccess
export def "patch-spaces-id-folders-folder-id-persons-member-id-unactiveaccess" [
  id: string
  folder_id: string
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
    method: patch
    path: "/spaces/{id}/folders/{folderId}/persons/{memberId}/unactiveaccess"
    path_params: [{name: id, var: id}, {name: folderId, var: folder_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, folder_id: $folder_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# invite a owner in a space
#
# POST /spaces/{id}/folders/{folderId}/persons/{personId}/guest-in-space
export def "post-spaces-id-folders-folder-id-persons-person-id-guest-in-space" [
  id: string
  folder_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-person-id: string # e.g. PAIHIHFA79TFA (spec name: PersonId)
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{id}/folders/{folderId}/persons/{personId}/guest-in-space"
    path_params: [{name: id, var: id}, {name: folderId, var: folder_id}, {name: personId, var: person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: PersonId, var: body_person_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, folder_id: $folder_id, person_id: $person_id, body_person_id: $body_person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of groups
#
# GET /spaces/{id}/groups
# Returns: table<EndDate: string, Id: string, Name: string>
export def "get-spaces-id-groups" [
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
  --name: string # Name of the groups (e.g. RH)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/groups"
    path_params: [{name: id, var: id}]
    query: [{name: Name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a group in a Space
#
# POST /spaces/{id}/groups
# Returns: record<Id: string>
export def "post-spaces-id-groups" [
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
  --end-date: string # e.g. 20160203
  name: string # e.g. RH
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/groups"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndDate, var: end_date}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, end_date: $end_date, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of groups even archived of the space
#
# GET /spaces/{id}/groups/all
# Returns: table<EndDate: string, Id: string, Name: string>
export def "get-spaces-id-groups-all" [
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
  --name: string # Name of the group (e.g. RH)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/groups/all"
    path_params: [{name: id, var: id}]
    query: [{name: Name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a group
#
# GET /spaces/{id}/groups/{groupId}
# Returns: record<EndDate: string, Id: string, Name: string, Accesses: record<Id: string, Name: string, Right: string>, Persons: record<MemberId: string>>
export def "get-spaces-id-groups-group-id" [
  id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/groups/{groupId}"
    path_params: [{name: id, var: id}, {name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a group
#
# PATCH /spaces/{id}/groups/{groupId}
export def "patch-spaces-id-groups-group-id" [
  id: string
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
  --end-date: string # e.g. 20160203
  --name: string # e.g. RH
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/groups/{groupId}"
    path_params: [{name: id, var: id}, {name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndDate, var: end_date}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, group_id: $group_id, end_date: $end_date, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete access to a folder for a group
#
# DELETE /spaces/{id}/groups/{groupId}/folders/{folderId}
export def "delete-spaces-id-groups-group-id-folders-folder-id" [
  id: string
  group_id: string
  folder_id: string
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
    path: "/spaces/{id}/groups/{groupId}/folders/{folderId}"
    path_params: [{name: id, var: id}, {name: groupId, var: group_id}, {name: folderId, var: folder_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, group_id: $group_id, folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add access to a folder for a group
#
# PATCH /spaces/{id}/groups/{groupId}/folders/{folderId}
export def "patch-spaces-id-groups-group-id-folders-folder-id" [
  id: string
  group_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  right: string@right-completer # e.g. read
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/groups/{groupId}/folders/{folderId}"
    path_params: [{name: id, var: id}, {name: groupId, var: group_id}, {name: folderId, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Right, var: right}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, group_id: $group_id, folder_id: $folder_id, right: $right
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a person of a group
#
# DELETE /spaces/{id}/groups/{groupId}/persons/{memberId}
export def "delete-spaces-id-groups-group-id-persons-member-id" [
  id: string
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
    path: "/spaces/{id}/groups/{groupId}/persons/{memberId}"
    path_params: [{name: id, var: id}, {name: groupId, var: group_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, group_id: $group_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a person to a group
#
# PATCH /spaces/{id}/groups/{groupId}/persons/{memberId}
export def "patch-spaces-id-groups-group-id-persons-member-id" [
  id: string
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
    method: patch
    path: "/spaces/{id}/groups/{groupId}/persons/{memberId}"
    path_params: [{name: id, var: id}, {name: groupId, var: group_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, group_id: $group_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns legal information of a space (except private)
#
# GET /spaces/{id}/legal
# Returns: record<IdentificationNumber: string, RegistrationDate: string, RegistrationNumber: string, VATNumber: string>
export def "get-spaces-id-legal" [
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
    path: "/spaces/{id}/legal"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify legal information of a Space (except private)
#
# PATCH /spaces/{id}/legal
export def "patch-spaces-id-legal" [
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
  --identification-number: string # e.g. 548
  --registration-date: string # e.g. 20190325
  --registration-number: string # e.g. 123456
  --vat-number: string # e.g. 123
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/legal"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: IdentificationNumber, var: identification_number}, {name: RegistrationDate, var: registration_date}, {name: RegistrationNumber, var: registration_number}, {name: VATNumber, var: vat_number}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, identification_number: $identification_number, registration_date: $registration_date, registration_number: $registration_number, vat_number: $vat_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a space with the logo
#
# GET /spaces/{id}/logo
# Returns: record<Id: string, Logo: record<Content64Encoded: string, Extension: string>, ModificationDate: string, Name: string, Type: string>
export def "get-spaces-id-logo" [
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
    path: "/spaces/{id}/logo"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "multipart/form-data"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns list of persons
#
# GET /spaces/{id}/persons
# Returns: table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Birth: record<Date: int, Place: string>, Email: string, FirstName: string, Function: list<string>, MemberId: string, Mobile: string, Sex: string, Validated: string>
export def "get-spaces-id-persons" [
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
  --function: string # Function of the person (e.g. employee)
  --range: string # index range of the results (e.g. 10-19)
  --name: string # Name of the person (e.g. Germain)
  --validated: string@validated-completer # Status of the person (e.g. true)
  --email: string # Email of the person (e.g. maxgermain@maxgermain.com)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/persons"
    path_params: [{name: id, var: id}]
    query: [{name: Function, var: function}, {name: Range, var: range}, {name: Name, var: name}, {name: Validated, var: validated}, {name: Email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, function: $function, range: $range, name: $name, validated: $validated, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Person in a Space
#
# POST /spaces/{id}/persons
# Returns: record<Id: string>
export def "post-spaces-id-persons" [
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
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --archival-date: string # e.g. 20160203
  --birth: record # shape: {Date?: int, Place?: string}
  --comment: string # e.g. my brother
  --email: string # e.g. bertrand@monmail.com
  first_name: string # e.g. Bertrand
  --mobile: string # e.g. +33606060606
  name: string # e.g. Dupond
  sex: string@sex-completer # e.g. male
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/persons"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}, {name: ArchivalDate, var: archival_date}, {name: Birth, var: birth}, {name: Comment, var: comment}, {name: Email, var: email}, {name: FirstName, var: first_name}, {name: Mobile, var: mobile}, {name: Name, var: name}, {name: Sex, var: sex}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, address: $address, archival_date: $archival_date, birth: $birth, comment: $comment, email: $email, first_name: $first_name, mobile: $mobile, name: $name, sex: $sex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of persons even persons archived
#
# GET /spaces/{id}/persons/all
# Returns: table<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Birth: record<Date: int, Place: string>, Email: string, FirstName: string, Function: list<string>, MemberId: string, Mobile: string, Sex: string, Validated: string>
export def "get-spaces-id-persons-all" [
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
  --name: string # Name of the person (e.g. Germain)
  --function: string # Function of the person (e.g. employee)
  --range: string # index range of the results (e.g. 10-19)
  --validated: string@validated-completer # Status of the person (e.g. true)
  --email: string # Email of the person (e.g. maxgermain@maxgermain.com)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/persons/all"
    path_params: [{name: id, var: id}]
    query: [{name: Name, var: name}, {name: Function, var: function}, {name: Range, var: range}, {name: Validated, var: validated}, {name: Email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, function: $function, range: $range, validated: $validated, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the role of a person
#
# PATCH /spaces/{id}/persons/{memberId}/player
export def "patch-spaces-id-persons-member-id-player" [
  id: string
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
  --client-management: string@client-management-completer
  --is-admin: oneof<nothing, bool> # e.g. true
  player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20210203
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/persons/{memberId}/player"
    path_params: [{name: id, var: id}, {name: memberId, var: member_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientManagement, var: client_management}, {name: IsAdmin, var: is_admin}, {name: Player, var: player}, {name: PlayerEnd, var: player_end}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, member_id: $member_id, client_management: $client_management, is_admin: $is_admin, player: $player, player_end: $player_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a person
#
# DELETE /spaces/{id}/persons/{personId}
export def "delete-spaces-id-persons-person-id" [
  id: string
  person_id: string
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
    path: "/spaces/{id}/persons/{personId}"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a person
#
# GET /spaces/{id}/persons/{personId}
# Returns: record<ArchivalDate: string, Comment: string, Id: string, ModificationDate: string, Name: string, Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Birth: record<Date: int, Place: string>, Email: string, FirstName: string, Function: list<string>, MemberId: string, Mobile: string, Sex: string, Validated: string>
export def "get-spaces-id-persons-person-id" [
  id: string
  person_id: string
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
    path: "/spaces/{id}/persons/{personId}"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a person
#
# PATCH /spaces/{id}/persons/{personId}
export def "patch-spaces-id-persons-person-id" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --archival-date: string # e.g. 20160203
  --birth: record # shape: {Date?: int, Place?: string}
  --comment: string # e.g. my brother
  --email: string # e.g. bertrand@monmail.com
  --first-name: string # e.g. Bertrand
  --mobile: string # e.g. +33606060606
  --name: string # e.g. Dupond
  --sex: string@sex-completer # e.g. male
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/persons/{personId}"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}, {name: ArchivalDate, var: archival_date}, {name: Birth, var: birth}, {name: Comment, var: comment}, {name: Email, var: email}, {name: FirstName, var: first_name}, {name: Mobile, var: mobile}, {name: Name, var: name}, {name: Sex, var: sex}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, person_id: $person_id, address: $address, archival_date: $archival_date, birth: $birth, comment: $comment, email: $email, first_name: $first_name, mobile: $mobile, name: $name, sex: $sex
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all details of a person
#
# GET /spaces/{id}/persons/{personId}/details
# Returns: table<Address: record<City: string, Complement: string, Country: string, Street: string, ZipCode: string>, Designation: string, Email: list<string>, Phone: list<string>>
export def "get-spaces-id-persons-person-id-details" [
  id: string
  person_id: string
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
    path: "/spaces/{id}/persons/{personId}/details"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace or Add a contact detail for a person
#
# POST /spaces/{id}/persons/{personId}/details
export def "post-spaces-id-persons-person-id-details" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  designation: string # e.g. Office
  --email: list<string>
  --phone: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{id}/persons/{personId}/details"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}, {name: Designation, var: designation}, {name: Email, var: email}, {name: Phone, var: phone}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, person_id: $person_id, address: $address, designation: $designation, email: $email, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a contact detail for a person
#
# DELETE /spaces/{id}/persons/{personId}/details/{designation}
export def "delete-spaces-id-persons-person-id-details-designation" [
  id: string
  person_id: string
  designation: string
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
    path: "/spaces/{id}/persons/{personId}/details/{designation}"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}, {name: designation, var: designation}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, person_id: $person_id, designation: $designation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of folders with exceptionnal access of the person personId
#
# GET /spaces/{id}/persons/{personId}/folders
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-id-persons-person-id-folders" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/persons/{personId}/folders"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    query: [{name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, person_id: $person_id, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of groups of the person personId
#
# GET /spaces/{id}/persons/{personId}/groups
# Returns: table<EndDate: string, Id: string, Name: string>
export def "get-spaces-id-persons-person-id-groups" [
  id: string
  person_id: string
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
    path: "/spaces/{id}/persons/{personId}/groups"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of portfolios of the person personId
#
# GET /spaces/{id}/persons/{personId}/portfolios
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Designation: string>
export def "get-spaces-id-persons-person-id-portfolios" [
  id: string
  person_id: string
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
    path: "/spaces/{id}/persons/{personId}/portfolios"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a portfolio for the person personId
#
# POST /spaces/{id}/persons/{personId}/portfolios
# Returns: record<Id: string>
export def "post-spaces-id-persons-person-id-portfolios" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --designation: string # e.g. My Portfolio
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --name: string # e.g. Dupond
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/persons/{personId}/portfolios"
    path_params: [{name: id, var: id}, {name: personId, var: person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: ArchivalDate, var: archival_date}, {name: Designation, var: designation}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, person_id: $person_id, about: $about, archival_date: $archival_date, designation: $designation, home: $home, keywords: $keywords, level: $level, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add/Modify/Delete a person in a portfolio (except manager)
#
# PATCH /spaces/{id}/portfolios/{portfolioId}/persons/{memberId}
export def "patch-spaces-id-portfolios-portfolio-id-persons-member-id" [
  id: string
  portfolio_id: string
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
  --apply: oneof<nothing, bool> # e.g. true
  --groups: list<string>@groups-completer-1 # e.g. [social, legal]
  --is-admin: oneof<nothing, bool> # e.g. false
  --role: string@role-completer-1 # e.g. collaborator
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{id}/portfolios/{portfolioId}/persons/{memberId}"
    path_params: [{name: id, var: id}, {name: portfolioId, var: portfolio_id}, {name: memberId, var: member_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Apply, var: apply}, {name: Groups, var: groups}, {name: IsAdmin, var: is_admin}, {name: Role, var: role}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, portfolio_id: $portfolio_id, member_id: $member_id, apply: $apply, groups: $groups, is_admin: $is_admin, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of professionalvehicles for the space {id}
#
# GET /spaces/{id}/professional-vehicles
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, DateIn: string, DateOut: string, Designation: string, Value: float, Brand: string, CompanyTax: bool, Model: string, RegistrationDate: string, RegistrationNumber: string, Type: string>
export def "get-spaces-id-professional-vehicles" [
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
  --designation: string # designation of the vehicle (e.g. peugeot)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/professional-vehicles"
    path_params: [{name: id, var: id}]
    query: [{name: Designation, var: designation}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, designation: $designation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a professional vehicle for the space
#
# POST /spaces/{id}/professional-vehicles
# Returns: record<Id: string>
export def "post-spaces-id-professional-vehicles" [
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --brand: string # e.g. Renault
  --comment: string # e.g. Peugeot Lyon
  --company-tax: oneof<nothing, bool> # e.g. true
  --date-in: string # e.g. 20201802
  --date-out: string # e.g. 20201802
  designation: string # e.g. peugeot siège
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, clio]
  --level: string@level-completer # e.g. confidential
  --model: string # e.g. Clio
  --registration-date: string # e.g. 20181231
  --registration-number: string # e.g. AA001AA
  --type: string # e.g. car
  --value: float # e.g. 1500.23
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/professional-vehicles"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Brand, var: brand}, {name: Comment, var: comment}, {name: CompanyTax, var: company_tax}, {name: DateIn, var: date_in}, {name: DateOut, var: date_out}, {name: Designation, var: designation}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Model, var: model}, {name: RegistrationDate, var: registration_date}, {name: RegistrationNumber, var: registration_number}, {name: Type, var: type}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, about: $about, brand: $brand, comment: $comment, company_tax: $company_tax, date_in: $date_in, date_out: $date_out, designation: $designation, home: $home, keywords: $keywords, level: $level, model: $model, registration_date: $registration_date, registration_number: $registration_number, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns state of activation of logs
#
# GET /spaces/{id}/settings/nf203/logs
# Returns: record<Enabled: bool>
export def "get-spaces-id-settings-nf203-logs" [
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
    path: "/spaces/{id}/settings/nf203/logs"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/Disable logs
#
# POST /spaces/{id}/settings/nf203/logs
export def "post-spaces-id-settings-nf203-logs" [
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
  --enabled: oneof<nothing, bool> # e.g. true
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{id}/settings/nf203/logs"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all status of the space
#
# GET /spaces/{id}/status
# Returns: table<Code: string, Comment: string, Label: string>
export def "get-spaces-id-status" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/status"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace or Add a status
#
# POST /spaces/{id}/status
export def "post-spaces-id-status" [
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
  code: string # e.g. COD
  --comment: string # e.g. my first code
  label: string # e.g. code 1
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{id}/status"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Code, var: code}, {name: Comment, var: comment}, {name: Label, var: label}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, code: $code, comment: $comment, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a status of the space
#
# DELETE /spaces/{id}/status/{code}
export def "delete-spaces-id-status-code" [
  id: string
  code: string
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
    path: "/spaces/{id}/status/{code}"
    path_params: [{name: id, var: id}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of tax contracts for the space {id}
#
# GET /spaces/{id}/tax-contracts
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, Designation: string, End: string, Start: string>
export def "get-spaces-id-tax-contracts" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/tax-contracts"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a tax contract for the space
#
# POST /spaces/{id}/tax-contracts
# Returns: record<Id: string>
export def "post-spaces-id-tax-contracts" [
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  designation: string # e.g. année 2019
  --end: string # e.g. 20181231
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180101
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/tax-contracts"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, about: $about, comment: $comment, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of triggers for the space {id}
#
# GET /spaces/{id}/triggers
# Returns: table<Date: string, Event: string>
export def "get-spaces-id-triggers" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/triggers"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a trigger for the space id
#
# DELETE /spaces/{id}/triggers/{name}
export def "delete-spaces-id-triggers-name" [
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
    method: delete
    path: "/spaces/{id}/triggers/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a trigger for the space id
#
# POST /spaces/{id}/triggers/{name}
export def "post-spaces-id-triggers-name" [
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
    path: "/spaces/{id}/triggers/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a common folder
#
# DELETE /spaces/{spaceId}/common-folders/{id}
export def "delete-spaces-space-id-common-folders-id" [
  space_id: string
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
    path: "/spaces/{spaceId}/common-folders/{id}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a common folder
#
# PATCH /spaces/{spaceId}/common-folders/{id}
export def "patch-spaces-space-id-common-folders-id" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --name: string # e.g. Dupond
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/common-folders/{id}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: ArchivalDate, var: archival_date}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, archival_date: $archival_date, home: $home, keywords: $keywords, level: $level, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the company entity
#
# GET /spaces/{spaceId}/company-entities/{id}/follow-ups
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-company-entities-id-follow-ups" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/company-entities/{id}/follow-ups"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and customer data
#
# GET /spaces/{spaceId}/customers
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>
export def "get-spaces-space-id-customers" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-number: string # CustomerNumber of the customer
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/customers"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: CustomerNumber, var: customer_number}, {name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, customer_number: $customer_number, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and customer data (even archived)
#
# GET /spaces/{spaceId}/customers/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>
export def "get-spaces-space-id-customers-all" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-number: string # CustomerNumber of the employee
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/customers/all"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: CustomerNumber, var: customer_number}, {name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, customer_number: $customer_number, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/documents
# Returns: table<Author: string, Code: string, Comment: string, Date: string, Extension: string, Folders: list<record>, Id: string, Title: string>
export def "get-spaces-space-id-documents" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --full-text: string # Text to find (e.g. durand)
  --range: string # index range of the results (e.g. 10-19)
  --class: string # class of the document to find (e.g. payslip)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/documents"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: FullText, var: full_text}, {name: Range, var: range}, {name: Class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, full_text: $full_text, range: $range, class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a doc
#
# PATCH /spaces/{spaceId}/documents/{documentId}
export def "patch-spaces-space-id-documents-document-id" [
  space_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  --title: string # e.g. Facture décembre
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/documents/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# read the data of a document
#
# GET /spaces/{spaceId}/documents/{documentId}/extend
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Extend: record>
export def "get-spaces-space-id-documents-document-id-extend" [
  space_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/documents/{documentId}/extend"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a data to a document
#
# POST /spaces/{spaceId}/documents/{documentId}/extend
# Returns: record<Id: string>
export def "post-spaces-space-id-documents-document-id-extend" [
  space_id: string
  document_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/documents/{documentId}/extend"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns versions of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/folders
# Returns: record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Folders: table<Id: string, Name: string>, Id: string, Title: string>
export def "get-spaces-space-id-documents-document-id-folders" [
  space_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/documents/{documentId}/folders"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# send by mail a document
#
# POST /spaces/{spaceId}/documents/{documentId}/mailing
# Returns: record<PageNb: float, Price: string>
export def "post-spaces-space-id-documents-document-id-mailing" [
  space_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --name: string # e.g. Société Dupond
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/documents/{documentId}/mailing"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id, address: $address, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the number of pages and the price of the pdf to send by mail
#
# GET /spaces/{spaceId}/documents/{documentId}/mailingprice
# Returns: record<PageNb: float, Price: string>
export def "get-spaces-space-id-documents-document-id-mailingprice" [
  space_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/documents/{documentId}/mailingprice"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns versions of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/versions
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string>
export def "get-spaces-space-id-documents-document-id-versions" [
  space_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/documents/{documentId}/versions"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a version to a document and set it as current
#
# POST /spaces/{spaceId}/documents/{documentId}/versions
# Returns: record<Id: string>
export def "post-spaces-space-id-documents-document-id-versions" [
  space_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/documents/{documentId}/versions"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current version of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/versions/current
# Returns: record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, Id: string, Title: string>
export def "get-spaces-space-id-documents-document-id-versions-current" [
  space_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/documents/{documentId}/versions/current"
    path_params: [{name: spaceId, var: space_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns accesses of one document
#
# GET /spaces/{spaceId}/documents/{id}/access
# Returns: record<Access: table<DownloadedOn: string, FirstName: string, Name: string, SeenOn: string>, Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, Id: string, Title: string>
export def "get-spaces-space-id-documents-id-access" [
  space_id: string
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
    path: "/spaces/{spaceId}/documents/{id}/access"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the document with the accounting property
#
# GET /spaces/{spaceId}/documents/{id}/accounting
# Returns: record<Accounting: record<AccountedOn: string, Workbook: string, YearMonth: string>, Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, Id: string, Title: string>
export def "get-spaces-space-id-documents-id-accounting" [
  space_id: string
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
    path: "/spaces/{spaceId}/documents/{id}/accounting"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns content of one document
#
# GET /spaces/{spaceId}/documents/{id}/download
# Returns: record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, File: record<Content64Encoded: string>, Id: string, Title: string>
export def "get-spaces-space-id-documents-id-download" [
  space_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/documents/{id}/download"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["*/*", "application/json", "multipart/form-data"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns folders with Id and employee data
#
# GET /spaces/{spaceId}/employees
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>
export def "get-spaces-space-id-employees" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ss-number: string # SSNumber of the employee
  --employee-number: string # EmployeeNumber of the employee
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/employees"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: SSNumber, var: ss_number}, {name: EmployeeNumber, var: employee_number}, {name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, ss_number: $ss_number, employee_number: $employee_number, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folders with Id and employee data (even archived)
#
# GET /spaces/{spaceId}/employees/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>
export def "get-spaces-space-id-employees-all" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ss-number: string # SSNumber of the employee
  --employee-number: string # EmployeeNumber of the employee
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/employees/all"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: SSNumber, var: ss_number}, {name: EmployeeNumber, var: employee_number}, {name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, ss_number: $ss_number, employee_number: $employee_number, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folders with Id and employer data
#
# GET /spaces/{spaceId}/employers
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>
export def "get-spaces-space-id-employers" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employee-number: string # EmployeeNumber of the employer contract
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/employers"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: EmployeeNumber, var: employee_number}, {name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, employee_number: $employee_number, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folders with Id and employer data (even archived)
#
# GET /spaces/{spaceId}/employers/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>
export def "get-spaces-space-id-employers-all" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employee-number: string # EmployeeNumber of the employer contract
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/employers/all"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: EmployeeNumber, var: employee_number}, {name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, employee_number: $employee_number, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# read the data of a space
#
# GET /spaces/{spaceId}/extend
# Returns: record<Extend: record, Id: string, ModificationDate: string, Name: string, Type: string>
export def "get-spaces-space-id-extend" [
  space_id: string
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
    path: "/spaces/{spaceId}/extend"
    path_params: [{name: spaceId, var: space_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a data to a space
#
# POST /spaces/{spaceId}/extend
# Returns: record<Id: string>
export def "post-spaces-space-id-extend" [
  space_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/extend"
    path_params: [{name: spaceId, var: space_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folders of the space
#
# GET /spaces/{spaceId}/folders
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-folders" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Secrétariat juridique)
  --keywords: string # keywords attached to the folder (e.g. juridique)
  --root-folders: string@root-folders-completer # only root folders (e.g. all)
  --range: string # index range of the results (e.g. 10-19)
  --class: string # class of the folder (e.g. social)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: Name, var: name}, {name: Keywords, var: keywords}, {name: RootFolders, var: root_folders}, {name: Range, var: range}, {name: Class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, name: $name, keywords: $keywords, root_folders: $root_folders, range: $range, class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folders of the space (even archived)
#
# GET /spaces/{spaceId}/folders/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-folders-all" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Secrétariat juridique)
  --range: string # index range of the results (e.g. 10-19)
  --keywords: string # keywords attached to the folder (e.g. juridique)
  --class: string # class of the folder (e.g. social)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/all"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: Name, var: name}, {name: Range, var: range}, {name: Keywords, var: keywords}, {name: Class, var: class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, name: $name, range: $range, keywords: $keywords, class: $class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a bank statement
#
# DELETE /spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}
export def "delete-spaces-space-id-folders-folder-id-bank-statements-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a bank statement
#
# PATCH /spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}
export def "patch-spaces-space-id-folders-folder-id-bank-statements-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance: float # format: number, e.g. 1352.63
  --number: float # format: string, e.g. 10015848
  --statement-date: string # e.g. 20160801
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Balance, var: balance}, {name: Number, var: number}, {name: StatementDate, var: statement_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, balance: $balance, number: $number, statement_date: $statement_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a contractual document
#
# DELETE /spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}
export def "delete-spaces-space-id-folders-folder-id-contractual-documents-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a contractual document
#
# PATCH /spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}
export def "patch-spaces-space-id-folders-folder-id-contractual-documents-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # e.g. 1001.36
  --designation: string # e.g. contrat client
  --reference: string # e.g. 151465AFHIA
  --start-date: string # e.g. 20181128
  --type: string@type-completer-2 # e.g. quotation
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: Designation, var: designation}, {name: Reference, var: reference}, {name: StartDate, var: start_date}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, amount: $amount, designation: $designation, reference: $reference, start_date: $start_date, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a corporate tax declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}
export def "delete-spaces-space-id-folders-folder-id-corporate-tax-declarations-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a coporate tax declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}
export def "patch-spaces-space-id-folders-folder-id-corporate-tax-declarations-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  --order: string@order-completer # e.g. 1st advance
  --rate: float # format: float, e.g. 10.63
  --tax-base: float # format: float, e.g. 123.36
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: DeclarationDate, var: declaration_date}, {name: Order, var: order}, {name: Rate, var: rate}, {name: TaxBase, var: tax_base}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, amount: $amount, declaration_date: $declaration_date, order: $order, rate: $rate, tax_base: $tax_base
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete an expense proof
#
# DELETE /spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}
export def "delete-spaces-space-id-folders-folder-id-expense-proofs-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify an expense report
#
# PATCH /spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}
export def "patch-spaces-space-id-folders-folder-id-expense-proofs-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string@account-completer # e.g. CAB
  --archival-date: string # e.g. 20211231
  --before-vat: float # e.g. 1000
  --expense-date: string # e.g. 20200202
  --expense-report-id: string # e.g. PFOIAHF874984
  --provider: string # e.g. G7
  --reason: string # e.g. taxi
  --status: string@status-completer # e.g. R
  --vat: float # e.g. 19.5
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Account, var: account}, {name: ArchivalDate, var: archival_date}, {name: BeforeVAT, var: before_vat}, {name: ExpenseDate, var: expense_date}, {name: ExpenseReportId, var: expense_report_id}, {name: Provider, var: provider}, {name: Reason, var: reason}, {name: Status, var: status}, {name: VAT, var: vat}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, account: $account, archival_date: $archival_date, before_vat: $before_vat, expense_date: $expense_date, expense_report_id: $expense_report_id, provider: $provider, reason: $reason, status: $status, vat: $vat
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete an expense report
#
# DELETE /spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}
export def "delete-spaces-space-id-folders-folder-id-expense-reports-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify an expense report
#
# PATCH /spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}
export def "patch-spaces-space-id-folders-folder-id-expense-reports-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-vat: float # e.g. 1000
  --expense-date: string # e.g. 20200202
  --incl-vat: float # e.g. 1200
  --processing-date: string # e.g. 20200203
  --vat: float # e.g. 19.5
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: BeforeVAT, var: before_vat}, {name: ExpenseDate, var: expense_date}, {name: InclVAT, var: incl_vat}, {name: ProcessingDate, var: processing_date}, {name: VAT, var: vat}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, before_vat: $before_vat, expense_date: $expense_date, incl_vat: $incl_vat, processing_date: $processing_date, vat: $vat
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete an invoice document
#
# DELETE /spaces/{spaceId}/folders/{folderId}/invoices/{documentId}
export def "delete-spaces-space-id-folders-folder-id-invoices-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/invoices/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a invoice
#
# PATCH /spaces/{spaceId}/folders/{folderId}/invoices/{documentId}
export def "patch-spaces-space-id-folders-folder-id-invoices-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-vat: float # e.g. 1000
  --due-date: string # e.g. 20190130
  --incl-vat: float # e.g. 1200
  --invoice-date: string # e.g. 20200202
  --number: string # e.g. 036459879874
  --payment-date: string # e.g. 20190131
  --type: string@type-completer-3 # e.g. commercial-invoice
  --vat: float # e.g. 19.5
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/invoices/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: BeforeVAT, var: before_vat}, {name: DueDate, var: due_date}, {name: InclVAT, var: incl_vat}, {name: InvoiceDate, var: invoice_date}, {name: Number, var: number}, {name: PaymentDate, var: payment_date}, {name: Type, var: type}, {name: VAT, var: vat}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, before_vat: $before_vat, due_date: $due_date, incl_vat: $incl_vat, invoice_date: $invoice_date, number: $number, payment_date: $payment_date, type: $type, vat: $vat
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get a nominative social declaration
#
# GET /spaces/{spaceId}/folders/{folderId}/nominative-social-declarations/{documentId}
# Returns: record<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, NetAmount: float, TotalGrossAmount: float, PayrollId: string>
export def "get-spaces-space-id-folders-folder-id-nominative-social-declarations-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/nominative-social-declarations/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a tax declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}
export def "delete-spaces-space-id-folders-folder-id-other-taxes-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify an other tax declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}
export def "patch-spaces-space-id-folders-folder-id-other-taxes-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  --reference: string # e.g. décla CFE
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: DeclarationDate, var: declaration_date}, {name: Reference, var: reference}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, amount: $amount, declaration_date: $declaration_date, reference: $reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a payroll
#
# DELETE /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}
export def "delete-spaces-space-id-folders-folder-id-payrolls-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a payroll
#
# PATCH /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}
export def "patch-spaces-space-id-folders-folder-id-payrolls-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  --employee-contributions: float # format: float, e.g. 1352.63
  --employer-contributions: float # format: float, e.g. 132.63
  --end: string # e.g. 20160831
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Begin, var: begin}, {name: EmployeeContributions, var: employee_contributions}, {name: EmployerContributions, var: employer_contributions}, {name: End, var: end}, {name: NetAmount, var: net_amount}, {name: TotalGrossAmount, var: total_gross_amount}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, begin: $begin, employee_contributions: $employee_contributions, employer_contributions: $employer_contributions, end: $end, net_amount: $net_amount, total_gross_amount: $total_gross_amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# recalculate a payroll
#
# POST /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}/refresh
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-folder-id-payrolls-document-id-refresh" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}/refresh"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a payslip
#
# DELETE /spaces/{spaceId}/folders/{folderId}/payslips/{documentId}
export def "delete-spaces-space-id-folders-folder-id-payslips-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/payslips/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a payslip
#
# PATCH /spaces/{spaceId}/folders/{folderId}/payslips/{documentId}
export def "patch-spaces-space-id-folders-folder-id-payslips-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  --employee-contributions: float # format: float, e.g. 2000.5
  --employer-contributions: float # format: float, e.g. 400.5
  --end: string # e.g. 20160831
  --fixed-gross-amount: float # format: float, e.g. 1352.63
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
  --vacation: float # format: float, e.g. 20.5
  --variable-gross-amount: float # format: float, e.g. 132.63
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/payslips/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Begin, var: begin}, {name: EmployeeContributions, var: employee_contributions}, {name: EmployerContributions, var: employer_contributions}, {name: End, var: end}, {name: FixedGrossAmount, var: fixed_gross_amount}, {name: NetAmount, var: net_amount}, {name: TotalGrossAmount, var: total_gross_amount}, {name: Vacation, var: vacation}, {name: VariableGrossAmount, var: variable_gross_amount}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, begin: $begin, employee_contributions: $employee_contributions, employer_contributions: $employer_contributions, end: $end, fixed_gross_amount: $fixed_gross_amount, net_amount: $net_amount, total_gross_amount: $total_gross_amount, vacation: $vacation, variable_gross_amount: $variable_gross_amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a social contract
#
# DELETE /spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}
export def "delete-spaces-space-id-folders-folder-id-social-contracts-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a social contract
#
# PATCH /spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}
export def "patch-spaces-space-id-folders-folder-id-social-contracts-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract-date: string # e.g. 20190202
  --contract-duration: string # e.g. 6 mois
  --contractual-change: string # e.g. augmentation
  --position: string # e.g. cadre
  --wage-developments: float # format: float, e.g. 1548.63
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContractDate, var: contract_date}, {name: ContractDuration, var: contract_duration}, {name: ContractualChange, var: contractual_change}, {name: Position, var: position}, {name: WageDevelopments, var: wage_developments}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, contract_date: $contract_date, contract_duration: $contract_duration, contractual_change: $contractual_change, position: $position, wage_developments: $wage_developments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a social declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}
export def "delete-spaces-space-id-folders-folder-id-social-declarations-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a social declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}
export def "patch-spaces-space-id-folders-folder-id-social-declarations-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: DeclarationDate, var: declaration_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, amount: $amount, declaration_date: $declaration_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a VAT declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}
export def "delete-spaces-space-id-folders-folder-id-vat-declarations-document-id" [
  space_id: string
  folder_id: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify a vat declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}
export def "patch-spaces-space-id-folders-folder-id-vat-declarations-document-id" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  --collected-vat: float # format: float, e.g. 1548.63
  --credit-vat: float # format: float, e.g. 400.5
  --deductible-vat: float # format: float, e.g. 20.5
  --end: string # e.g. 20160831
  --exempt-turnover: float # format: float, e.g. 132.63
  --number: string # e.g. 153126
  --payable-vat: float # format: float, e.g. 2000.5
  --taxable-turnover: float # format: float, e.g. 1352.63
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: folderId, var: folder_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Begin, var: begin}, {name: CollectedVAT, var: collected_vat}, {name: CreditVAT, var: credit_vat}, {name: DeductibleVAT, var: deductible_vat}, {name: End, var: end}, {name: ExemptTurnover, var: exempt_turnover}, {name: Number, var: number}, {name: PayableVAT, var: payable_vat}, {name: TaxableTurnover, var: taxable_turnover}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, folder_id: $folder_id, document_id: $document_id, begin: $begin, collected_vat: $collected_vat, credit_vat: $credit_vat, deductible_vat: $deductible_vat, end: $end, exempt_turnover: $exempt_turnover, number: $number, payable_vat: $payable_vat, taxable_turnover: $taxable_turnover
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id
#
# GET /spaces/{spaceId}/folders/{id}
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-folders-id" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate)
#
# PATCH /spaces/{spaceId}/folders/{id}
export def "patch-spaces-space-id-folders-id" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, home: $home, keywords: $keywords, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete an AccountingYear
#
# DELETE /spaces/{spaceId}/folders/{id}/accounting-year
export def "delete-spaces-space-id-folders-id-accounting-year" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/accounting-year"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and AccountingYear data
#
# PATCH /spaces/{spaceId}/folders/{id}/accounting-year
export def "patch-spaces-space-id-folders-id-accounting-year" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  --end: string # e.g. 20181231
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --net-income: float # e.g. 52634.36
  --net-position: float # e.g. 14580.36
  --start: string # e.g. 20180101
  --tax: float # e.g. 45698.36
  --taxable-income: float # e.g. 869523.36
  --turnover: float # e.g. 1025.36
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/accounting-year"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: NetIncome, var: net_income}, {name: NetPosition, var: net_position}, {name: Start, var: start}, {name: Tax, var: tax}, {name: TaxableIncome, var: taxable_income}, {name: Turnover, var: turnover}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, end: $end, home: $home, keywords: $keywords, level: $level, net_income: $net_income, net_position: $net_position, start: $start, tax: $tax, taxable_income: $taxable_income, turnover: $turnover
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns accountings documents of the folder (results and taxation or accountingyear)
#
# GET /spaces/{spaceId}/folders/{id}/accountings
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Accounting: record<AccountedOn: string, Workbook: string, YearMonth: string>>
export def "get-spaces-space-id-folders-id-accountings" [
  space_id: string
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
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --title: string # Title of the accounting document (e.g. Accounting)
  --workbook: string # workbook of the accounting (e.g. Accounting)
  --class: string # class of the accounting (e.g. Invoice)
  --accounted-on: string # accountedon of the accounting (boolean available) (e.g. 20180201,null)
  --with-folders: string # if present, the folders containing the documents are returned (e.g. yes)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/accountings"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: FolderDate, var: folder_date}, {name: Title, var: title}, {name: Workbook, var: workbook}, {name: Class, var: class}, {name: AccountedOn, var: accounted_on}, {name: WithFolders, var: with_folders}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, folder_date: $folder_date, title: $title, workbook: $workbook, class: $class, accounted_on: $accounted_on, with_folders: $with_folders, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# journal of accountings document delivered to a customer
#
# GET /spaces/{spaceId}/folders/{id}/accountings-journal
# Returns: table<AccountingDate: string, AccountingDocumentId: string, Class: string, Code: string, DeliveryDate: string, Id: string, Number: int, TargetFolder: record<Id: string, Name: string>, Workbook: string, YearMonth: string>
export def "get-spaces-space-id-folders-id-accountings-journal" [
  space_id: string
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
  --delivery-date: string # delivery dates of the document (e.g. 20191123082536,null)
  --accounting-date: string # accounting dates of the document (e.g. 20170215,null)
  --number: int # numbers of the document (e.g. 12,17)
  --workbook: string # workbook of the document (e.g. cashwoucher)
  --year-month: string # yearmonth of the document (e.g. 201802)
  --class: string # class of the document (e.g. invoice)
  --code: string # code of the document (e.g. delivered)
  --target-folder-name: string # Name of the target folder of the document (e.g. Exercice*)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/accountings-journal"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: DeliveryDate, var: delivery_date}, {name: AccountingDate, var: accounting_date}, {name: Number, var: number}, {name: Workbook, var: workbook}, {name: YearMonth, var: year_month}, {name: Class, var: class}, {name: Code, var: code}, {name: TargetFolderName, var: target_folder_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, delivery_date: $delivery_date, accounting_date: $accounting_date, number: $number, workbook: $workbook, year_month: $year_month, class: $class, code: $code, target_folder_name: $target_folder_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Bank data
#
# DELETE /spaces/{spaceId}/folders/{id}/bank
export def "delete-spaces-space-id-folders-id-bank" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/bank"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and bank data
#
# GET /spaces/{spaceId}/folders/{id}/bank
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>
export def "get-spaces-space-id-folders-id-bank" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/bank"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Bank data
#
# PATCH /spaces/{spaceId}/folders/{id}/bank
export def "patch-spaces-space-id-folders-id-bank" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-reference: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180630
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/bank"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: ContractReference, var: contract_reference}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, contract_reference: $contract_reference, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns bank statements of the folder bank
#
# GET /spaces/{spaceId}/folders/{id}/bank-statements
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, AccountedOn: string, Balance: float, Number: float, StatementDate: string>
export def "get-spaces-space-id-folders-id-bank-statements" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --number: string # Number of the bank statement (e.g. 201603)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/bank-statements"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Number, var: number}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, number: $number, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a bank statement in a folder bank
#
# POST /spaces/{spaceId}/folders/{id}/bank-statements
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-bank-statements" [
  space_id: string
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
  --balance: float # format: number, e.g. 1352.63
  document_id: string # e.g. PBUFBAUBF1531
  --number: float # format: string, e.g. 10015848
  statement_date: string # e.g. 20160801
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/bank-statements"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Balance, var: balance}, {name: DocumentId, var: document_id}, {name: Number, var: number}, {name: StatementDate, var: statement_date}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, balance: $balance, document_id: $document_id, number: $number, statement_date: $statement_date, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Collective Decision data
#
# PATCH /spaces/{spaceId}/folders/{id}/collective-decision
export def "patch-spaces-space-id-folders-id-collective-decision" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  --date: string # e.g. 20180202
  --dividend-distributions: float # e.g. 1025.36
  --dividend-distributions-date: string # e.g. 20180203
  --event: string@event-completer # for space type 'company' enums allowed are 'EGM','CGM','OGM','ConstituentAssembly','SolePartner','OtherEvent','Office','ExecutiveCommittee','Consulting','Board','PartnersMeeting' and for space type 'association' enums allowed are 'EGM','CGM','OGM','Other','Office','ExecutiveCommittee' (e.g. EGM)
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/collective-decision"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: Date, var: date}, {name: DividendDistributions, var: dividend_distributions}, {name: DividendDistributionsDate, var: dividend_distributions_date}, {name: Event, var: event}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, date: $date, dividend_distributions: $dividend_distributions, dividend_distributions_date: $dividend_distributions_date, event: $event, home: $home, keywords: $keywords, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns common folders of a folder
#
# GET /spaces/{spaceId}/folders/{id}/common-folders
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-folders-id-common-folders" [
  space_id: string
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
  --name: string # Name of the folder (e.g. Folder one)
  --keywords: string # keywords attached to the folder (e.g. juridique)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/common-folders"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Name, var: name}, {name: Keywords, var: keywords}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, name: $name, keywords: $keywords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a common folder in another folder
#
# POST /spaces/{spaceId}/folders/{id}/common-folders
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-common-folders" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  name: string # e.g. Dupond
  --rights: oneof<nothing, bool> # e.g. true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/common-folders"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: ArchivalDate, var: archival_date}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Name, var: name}, {name: Rights, var: rights}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, archival_date: $archival_date, home: $home, keywords: $keywords, level: $level, name: $name, rights: $rights
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns common folders (even archived) of a folder
#
# GET /spaces/{spaceId}/folders/{id}/common-folders/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-folders-id-common-folders-all" [
  space_id: string
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
  --name: string # Name of the folder (e.g. Folder one)
  --keywords: string # keywords attached to the folder (e.g. juridique)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/common-folders/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Name, var: name}, {name: Keywords, var: keywords}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, name: $name, keywords: $keywords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all contracting partners of a contract
#
# GET /spaces/{spaceId}/folders/{id}/contracting-partner
# Returns: table<Class: string, Id: string, Role: string>
export def "get-spaces-space-id-folders-id-contracting-partner" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/contracting-partner"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns collector space of a contract
#
# GET /spaces/{spaceId}/folders/{id}/contracting-partner/space
# Returns: table<Class: string, Id: string, Role: string>
export def "get-spaces-space-id-folders-id-contracting-partner-space" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/contracting-partner/space"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/folders/{id}/contractual-documents
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: string, Designation: string, Reference: string, StartDate: string, Type: string>
export def "get-spaces-space-id-folders-id-contractual-documents" [
  space_id: string
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
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --type: string@type-completer-2 # Type of the document (e.g. amendment)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/contractual-documents"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: FolderDate, var: folder_date}, {name: Type, var: type}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, folder_date: $folder_date, type: $type, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/contractual-documents
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-contractual-documents" [
  space_id: string
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
  --amount: string # e.g. 1001.36
  --designation: string # e.g. contrat client
  document_id: string # e.g. PBUFBAUBF1531
  --reference: string # e.g. 151465AFHIA
  --start-date: string # e.g. 20181128
  --type: string@type-completer-2 # e.g. quotation
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: any # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/contractual-documents"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: Designation, var: designation}, {name: DocumentId, var: document_id}, {name: Reference, var: reference}, {name: StartDate, var: start_date}, {name: Type, var: type}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, amount: $amount, designation: $designation, document_id: $document_id, reference: $reference, start_date: $start_date, type: $type, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and contractual-relationship data
#
# GET /spaces/{spaceId}/folders/{id}/contractual-relationship
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>
export def "get-spaces-space-id-folders-id-contractual-relationship" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/contractual-relationship"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns corporate tax declarations
#
# GET /spaces/{spaceId}/folders/{id}/coporate-tax-declarations
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: float, DeclarationDate: string, Order: string, Rate: float, TaxBase: float>
export def "get-spaces-space-id-folders-id-coporate-tax-declarations" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/coporate-tax-declarations"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a corporate tax declaration
#
# POST /spaces/{spaceId}/folders/{id}/coporate-tax-declarations
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-coporate-tax-declarations" [
  space_id: string
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
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --order: string@order-completer # e.g. 1st advance
  --rate: float # format: float, e.g. 10.63
  --tax-base: float # format: float, e.g. 123.36
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/coporate-tax-declarations"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: DeclarationDate, var: declaration_date}, {name: DocumentId, var: document_id}, {name: Order, var: order}, {name: Rate, var: rate}, {name: TaxBase, var: tax_base}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, amount: $amount, declaration_date: $declaration_date, document_id: $document_id, order: $order, rate: $rate, tax_base: $tax_base, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a customer
#
# DELETE /spaces/{spaceId}/folders/{id}/customer
export def "delete-spaces-space-id-folders-id-customer" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/customer"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and customer data
#
# GET /spaces/{spaceId}/folders/{id}/customer
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, Actors: table<Active: string, IsAdmin: string, MemberId: string, Name: string, Role: string>, ClientSpaceId: string, PortfolioId: string, SecondaryPortfolioIds: list<string>>
export def "get-spaces-space-id-folders-id-customer" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/customer"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Customer data
#
# PATCH /spaces/{spaceId}/folders/{id}/customer
export def "patch-spaces-space-id-folders-id-customer" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keep-old: oneof<nothing, bool> # e.g. true
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --portfolio-id: string # e.g. T1OJFOAZ7449420F
  --secondary-portfolio-id: string # e.g. T1OJFOAZ7449420F
  --start: string # e.g. 20180630
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/customer"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: CustomerNumber, var: customer_number}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: KeepOld, var: keep_old}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: PortfolioId, var: portfolio_id}, {name: SecondaryPortfolioId, var: secondary_portfolio_id}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, customer_number: $customer_number, designation: $designation, end: $end, home: $home, keep_old: $keep_old, keywords: $keywords, level: $level, portfolio_id: $portfolio_id, secondary_portfolio_id: $secondary_portfolio_id, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# journal of documents delivered to a customer
#
# GET /spaces/{spaceId}/folders/{id}/deliveries-journal
# Returns: table<Author: string, Class: string, DeleteDate: string, DeliveryDate: string, Id: string, Number: int, TargetFolder: record<Id: string, Name: string>>
export def "get-spaces-space-id-folders-id-deliveries-journal" [
  space_id: string
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
  --delivery-date: string # delivery dates of the document (e.g. 20191123082536,null)
  --accounting-date: string # accounting dates of the document (e.g. 20170215,null)
  --number: int # numbers of the document (e.g. 12,17)
  --class: string # class of the document (e.g. invoice)
  --target-folder-name: string # Name of the target folder of the document (e.g. Exercice*)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/deliveries-journal"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: DeliveryDate, var: delivery_date}, {name: AccountingDate, var: accounting_date}, {name: Number, var: number}, {name: Class, var: class}, {name: TargetFolderName, var: target_folder_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, delivery_date: $delivery_date, accounting_date: $accounting_date, number: $number, class: $class, target_folder_name: $target_folder_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/folders/{id}/documents
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string>
export def "get-spaces-space-id-folders-id-documents" [
  space_id: string
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
  --date: string # date range of the documents (e.g. 20160321,null)
  --title: string # Title of the document (e.g. Facture EDF)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --class: string # Class of document (e.g. Contract)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/documents"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Title, var: title}, {name: FolderDate, var: folder_date}, {name: Class, var: class}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, title: $title, folder_date: $folder_date, class: $class, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/documents
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-documents" [
  space_id: string
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
  --document-id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/documents"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentId, var: document_id}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, document_id: $document_id, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a doc of a folder
#
# PATCH /spaces/{spaceId}/folders/{id}/documents/{documentId}/detach
export def "patch-spaces-space-id-folders-id-documents-document-id-detach" [
  space_id: string
  id: string
  document_id: string
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
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/documents/{documentId}/detach"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Employee data
#
# DELETE /spaces/{spaceId}/folders/{id}/employee
export def "delete-spaces-space-id-folders-id-employee" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/employee"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and employee data
#
# GET /spaces/{spaceId}/folders/{id}/employee
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>
export def "get-spaces-space-id-folders-id-employee" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/employee"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Employee data
#
# PATCH /spaces/{spaceId}/folders/{id}/employee
export def "patch-spaces-space-id-folders-id-employee" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-type: string # e.g. 01
  --employee-number: string # e.g. 13587FAZCD420F
  --end: string # e.g. 20190101
  --function: string # e.g. commercial
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --postal-mail: oneof<nothing, bool> # e.g. true
  --ss-number: string # e.g. 1542012365985215
  --start: string # e.g. 20180630
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/employee"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: ContractType, var: contract_type}, {name: EmployeeNumber, var: employee_number}, {name: End, var: end}, {name: Function, var: function}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: PostalMail, var: postal_mail}, {name: SSNumber, var: ss_number}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, contract_type: $contract_type, employee_number: $employee_number, end: $end, function: $function, home: $home, keywords: $keywords, level: $level, postal_mail: $postal_mail, ss_number: $ss_number, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns expense proofs of the folder (social, followup or exchange)
#
# GET /spaces/{spaceId}/folders/{id}/expense-proofs
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Account: string, ArchivalDate: string, ExpenseDate: string, InclVAT: float, Provider: string, Reason: string, Status: string, VAT: float>
export def "get-spaces-space-id-folders-id-expense-proofs" [
  space_id: string
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
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --status: string@status-completer # Status of the expense proof (e.g. R)
  --no-expense-report: oneof<nothing, bool> # To return expense proofs not attached to an expense report (e.g. 1)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/expense-proofs"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: FolderDate, var: folder_date}, {name: Status, var: status}, {name: NoExpenseReport, var: no_expense_report}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, folder_date: $folder_date, status: $status, no_expense_report: $no_expense_report, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a expense proof in a folder followup or exchange
#
# POST /spaces/{spaceId}/folders/{id}/expense-proofs
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-expense-proofs" [
  space_id: string
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
  --account: string@account-completer # e.g. CAB
  --archival-date: string # e.g. 20211231
  --before-vat: float # e.g. 1000
  document_id: string # e.g. PBUFBAUBF1531
  --expense-date: string # e.g. 20200202
  --expense-report-id: string # e.g. PFOIAHF874984
  --provider: string # e.g. G7
  --reason: string # e.g. taxi
  --status: string@status-completer # e.g. R
  --vat: float # e.g. 19.5
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/expense-proofs"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Account, var: account}, {name: ArchivalDate, var: archival_date}, {name: BeforeVAT, var: before_vat}, {name: DocumentId, var: document_id}, {name: ExpenseDate, var: expense_date}, {name: ExpenseReportId, var: expense_report_id}, {name: Provider, var: provider}, {name: Reason, var: reason}, {name: Status, var: status}, {name: VAT, var: vat}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, account: $account, archival_date: $archival_date, before_vat: $before_vat, document_id: $document_id, expense_date: $expense_date, expense_report_id: $expense_report_id, provider: $provider, reason: $reason, status: $status, vat: $vat, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns expense reports of the folder (social or followup)
#
# GET /spaces/{spaceId}/folders/{id}/expense-reports
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, BeforeVAT: float, ExpenseDate: string, InclVAT: float, ProcessingDate: string, VAT: float>
export def "get-spaces-space-id-folders-id-expense-reports" [
  space_id: string
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
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --with-extend: string@with-extend-completer # If present returns also the data extend (e.g. true)
  --range: string # index range of the results (e.g. 10-19)
  --processing-date: string # range of processing date (boolean available) (e.g. 20180526,null)
  --expense-date: string # range of ExpenseDate (valid available) (e.g. 20180526,null)
  --sort-order: string@sort-order-completer # order of sort (if absent default is asc) (e.g. asc)
  --sort-name: string@sort-name-completer # name of value for sort (e.g. ExpenseDate)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/expense-reports"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: FolderDate, var: folder_date}, {name: WithExtend, var: with_extend}, {name: Range, var: range}, {name: ProcessingDate, var: processing_date}, {name: ExpenseDate, var: expense_date}, {name: SortOrder, var: sort_order}, {name: SortName, var: sort_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, folder_date: $folder_date, with_extend: $with_extend, range: $range, processing_date: $processing_date, expense_date: $expense_date, sort_order: $sort_order, sort_name: $sort_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a expense report in a folder followup
#
# POST /spaces/{spaceId}/folders/{id}/expense-reports
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-expense-reports" [
  space_id: string
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
  --before-vat: float # e.g. 1000
  --date: string # e.g. 20161203
  document_id: string # e.g. PBUFBAUBF1531
  --expense-date: string # e.g. 20200202
  --incl-vat: float # e.g. 1200
  --processing-date: string # e.g. 20200203
  --vat: float # e.g. 19.5
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/expense-reports"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: BeforeVAT, var: before_vat}, {name: Date, var: date}, {name: DocumentId, var: document_id}, {name: ExpenseDate, var: expense_date}, {name: InclVAT, var: incl_vat}, {name: ProcessingDate, var: processing_date}, {name: VAT, var: vat}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, before_vat: $before_vat, date: $date, document_id: $document_id, expense_date: $expense_date, incl_vat: $incl_vat, processing_date: $processing_date, vat: $vat, accounting: $accounting, author: $author, code: $code, comment: $comment, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns expense proofs linked to the expenseReportId
#
# GET /spaces/{spaceId}/folders/{id}/expense-reports/{expenseReportId}/expense-proofs
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Account: string, ArchivalDate: string, ExpenseDate: string, InclVAT: float, Provider: string, Reason: string, Status: string, VAT: float>
export def "get-spaces-space-id-folders-id-expense-reports-expense-report-id-expense-proofs" [
  space_id: string
  id: string
  expense_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of the documents (YYYY or YYYYMM or YYYYMMDD) (e.g. 20160321)
  --status: string@status-completer # Status of the expense proof (e.g. R)
  --folder-date: string # Date of upload of the document (YYYY or YYYYMM or YYYYMMDD) (e.g. 20180202000000)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/expense-reports/{expenseReportId}/expense-proofs"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: expenseReportId, var: expense_report_id}]
    query: [{name: Date, var: date}, {name: Status, var: status}, {name: FolderDate, var: folder_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, expense_report_id: $expense_report_id, date: $date, status: $status, folder_date: $folder_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Insurance data
#
# DELETE /spaces/{spaceId}/folders/{id}/insurance
export def "delete-spaces-space-id-folders-id-insurance" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/insurance"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and insurance data
#
# GET /spaces/{spaceId}/folders/{id}/insurance
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, PolicyNumber: string>
export def "get-spaces-space-id-folders-id-insurance" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/insurance"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Insurance data
#
# PATCH /spaces/{spaceId}/folders/{id}/insurance
export def "patch-spaces-space-id-folders-id-insurance" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --policy-number: string # e.g. 1358
  --start: string # e.g. 20180630
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/insurance"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: CustomerNumber, var: customer_number}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: PolicyNumber, var: policy_number}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, customer_number: $customer_number, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, policy_number: $policy_number, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns invoices of the folder (customer, provider, accountingyear or root folders customers or providers)
#
# GET /spaces/{spaceId}/folders/{id}/invoices
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, AccountedOn: string, BeforeVAT: float, DueDate: string, InclVAT: float, InvoiceDate: string, Number: string, PaymentDate: string, Type: string, VAT: float>
export def "get-spaces-space-id-folders-id-invoices" [
  space_id: string
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
  --title: string # Title of the documents (e.g. factrure)
  --date: string # date range of the documents (e.g. 20160321,null)
  --number: string # Number of the invoice (e.g. 23585)
  --incl-vat: float # amount incl. VAT (e.g. 100.50,123.69)
  --before-vat: float # amount before VAT (e.g. 102.50,123.69)
  --due-date: string # date due payment (e.g. 20201231,20211231)
  --payment-date: string # date of payment (boolean and valid available) (e.g. 20201201,20211201)
  --invoice-date: string # range date of invoice (e.g. 20201201)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --accounted-on: string # value of AccountedOn (boolean available but not range) (e.g. 20220101)
  --with-extend: string # If present returns also the data extend (e.g. 202102,null)
  --extend: string # json object to filter extend data (e.g. [{"Name":"field1","Equals":"test"},{"Name":"field2","Start":"20180101"},{"Name":"field3","End":"20190101"}])
  --range: string # index range of the results (e.g. 10-19)
  --sort-order: string@sort-order-completer # order of sort (if absent default is asc) (e.g. asc)
  --sort-name: string@sort-name-completer-1 # name of value for sort (e.g. PaymentDate)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/invoices"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Title, var: title}, {name: Date, var: date}, {name: Number, var: number}, {name: InclVAT, var: incl_vat}, {name: BeforeVAT, var: before_vat}, {name: DueDate, var: due_date}, {name: PaymentDate, var: payment_date}, {name: InvoiceDate, var: invoice_date}, {name: FolderDate, var: folder_date}, {name: AccountedOn, var: accounted_on}, {name: WithExtend, var: with_extend}, {name: Extend, var: extend}, {name: Range, var: range}, {name: SortOrder, var: sort_order}, {name: SortName, var: sort_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, title: $title, date: $date, number: $number, incl_vat: $incl_vat, before_vat: $before_vat, due_date: $due_date, payment_date: $payment_date, invoice_date: $invoice_date, folder_date: $folder_date, accounted_on: $accounted_on, with_extend: $with_extend, extend: $extend, range: $range, sort_order: $sort_order, sort_name: $sort_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a invoice in a folder of a customer or a provider
#
# POST /spaces/{spaceId}/folders/{id}/invoices
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-invoices" [
  space_id: string
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
  --before-vat: float # e.g. 1000
  --date: string # e.g. 20161203
  document_id: string # e.g. PBUFBAUBF1531
  --due-date: string # e.g. 20190130
  --incl-vat: float # e.g. 1200
  --invoice-date: string # e.g. 20200202
  --number: string # e.g. 036459879874
  --payment-date: string # e.g. 20190131
  --type: string@type-completer-3 # e.g. commercial-invoice
  --vat: float # e.g. 19.5
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/invoices"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: BeforeVAT, var: before_vat}, {name: Date, var: date}, {name: DocumentId, var: document_id}, {name: DueDate, var: due_date}, {name: InclVAT, var: incl_vat}, {name: InvoiceDate, var: invoice_date}, {name: Number, var: number}, {name: PaymentDate, var: payment_date}, {name: Type, var: type}, {name: VAT, var: vat}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, before_vat: $before_vat, date: $date, document_id: $document_id, due_date: $due_date, incl_vat: $incl_vat, invoice_date: $invoice_date, number: $number, payment_date: $payment_date, type: $type, vat: $vat, accounting: $accounting, author: $author, code: $code, comment: $comment, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns legal entity of a follow up folder
#
# GET /spaces/{spaceId}/folders/{id}/legal-entity
# Returns: record<Class: string, Id: string>
export def "get-spaces-space-id-folders-id-legal-entity" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/legal-entity"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Loan data
#
# DELETE /spaces/{spaceId}/folders/{id}/loan
export def "delete-spaces-space-id-folders-id-loan" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/loan"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and loan data
#
# GET /spaces/{spaceId}/folders/{id}/loan
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>
export def "get-spaces-space-id-folders-id-loan" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/loan"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Loan data
#
# PATCH /spaces/{spaceId}/folders/{id}/loan
export def "patch-spaces-space-id-folders-id-loan" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --amount: float # format: float, e.g. 1000
  --category: string@category-completer # e.g. debt spreading
  --comment: string # e.g. pieces company
  --designation: string # e.g. emprunt entreprise
  --due-amount: float # format: float, e.g. 1000.6
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --months-number: float # e.g. 12
  --rate: float # format: float, e.g. 2.5
  --start: string # e.g. 20180630
  --total-cost: float # format: float, e.g. 10200
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/loan"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Amount, var: amount}, {name: Category, var: category}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: DueAmount, var: due_amount}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: MonthsNumber, var: months_number}, {name: Rate, var: rate}, {name: Start, var: start}, {name: TotalCost, var: total_cost}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, amount: $amount, category: $category, comment: $comment, designation: $designation, due_amount: $due_amount, end: $end, home: $home, keywords: $keywords, level: $level, months_number: $months_number, rate: $rate, start: $start, total_cost: $total_cost
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns messages of the folder
#
# GET /spaces/{spaceId}/folders/{id}/messages
# Returns: table<Author: string, Id: string, Level: string, MessageDate: string, ModificationAuthor: string, ModificationDate: string, Text: string>
export def "get-spaces-space-id-folders-id-messages" [
  space_id: string
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
  --text: string # Name of the message (e.g. *welcom*)
  --range: string # index range of the results (e.g. 10-19)
  --message-date: string # date of the message (e.g. 20190202)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/messages"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Text, var: text}, {name: Range, var: range}, {name: MessageDate, var: message_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, text: $text, range: $range, message_date: $message_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Write a message in the journal of a folder
#
# POST /spaces/{spaceId}/folders/{id}/messages
export def "post-spaces-space-id-folders-id-messages" [
  space_id: string
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
  --level: string@level-completer-1 # e.g. confidential
  --message-date: string # e.g. 20160203
  --notify: record # shape: {How?: "std"|"mail"|"sms", MemberIds?: list<string>}
  text: string # e.g. <p> hello world </p>
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/messages"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Level, var: level}, {name: MessageDate, var: message_date}, {name: Notify, var: notify}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, level: $level, message_date: $message_date, notify: $notify, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns message with Id
#
# GET /spaces/{spaceId}/folders/{id}/messages/{messageId}
# Returns: record<Author: string, Id: string, Level: string, MessageDate: string, ModificationAuthor: string, ModificationDate: string, Text: string>
export def "get-spaces-space-id-folders-id-messages-message-id" [
  space_id: string
  id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/messages/{messageId}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: messageId, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Message
#
# PATCH /spaces/{spaceId}/folders/{id}/messages/{messageId}
export def "patch-spaces-space-id-folders-id-messages-message-id" [
  space_id: string
  id: string
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
  --level: string@level-completer-1 # e.g. confidential
  --message-date: string # e.g. 20160203
  --notify: record # shape: {How?: "std"|"mail"|"sms", MemberIds?: list<string>}
  --text: string # e.g. <p> hello world </p>
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/messages/{messageId}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: messageId, var: message_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Level, var: level}, {name: MessageDate, var: message_date}, {name: Notify, var: notify}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, message_id: $message_id, level: $level, message_date: $message_date, notify: $notify, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns nominative social declarations of the folder social
#
# GET /spaces/{spaceId}/folders/{id}/nominative-social-declarations
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, NetAmount: float, TotalGrossAmount: float, PayrollId: string>
export def "get-spaces-space-id-folders-id-nominative-social-declarations" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/nominative-social-declarations"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns other taxes declarations
#
# GET /spaces/{spaceId}/folders/{id}/other-taxes
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: float, DeclarationDate: string, Reference: string>
export def "get-spaces-space-id-folders-id-other-taxes" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/other-taxes"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a tax declaration
#
# POST /spaces/{spaceId}/folders/{id}/other-taxes
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-other-taxes" [
  space_id: string
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
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --reference: string # e.g. décla CFE
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/other-taxes"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: DeclarationDate, var: declaration_date}, {name: DocumentId, var: document_id}, {name: Reference, var: reference}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, amount: $amount, declaration_date: $declaration_date, document_id: $document_id, reference: $reference, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns identifiers/passwords of the folder
#
# GET /spaces/{spaceId}/folders/{id}/passwords
# Returns: table<Comment: string, Designation: string, Ident: string, Link: string, Password: string, Id: string>
export def "get-spaces-space-id-folders-id-passwords" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/passwords"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Write a identifier/password in aa folder
#
# POST /spaces/{spaceId}/folders/{id}/passwords
export def "post-spaces-space-id-folders-id-passwords" [
  space_id: string
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
  --comment: string # e.g. mon compte google
  designation: string # e.g. compte google
  --ident: string # e.g. test
  --link: string # e.g. www.google.fr
  --password: string # e.g. azerty
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/passwords"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Comment, var: comment}, {name: Designation, var: designation}, {name: Ident, var: ident}, {name: Link, var: link}, {name: Password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, comment: $comment, designation: $designation, ident: $ident, link: $link, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a password
#
# DELETE /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "delete-spaces-space-id-folders-id-passwords-password-id" [
  space_id: string
  id: string
  password_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/passwords/{passwordId}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: passwordId, var: password_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, password_id: $password_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns password with Id
#
# GET /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
# Returns: record<Comment: string, Designation: string, Ident: string, Link: string, Password: string, Id: string>
export def "get-spaces-space-id-folders-id-passwords-password-id" [
  space_id: string
  id: string
  password_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/passwords/{passwordId}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: passwordId, var: password_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, password_id: $password_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Password
#
# PATCH /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "patch-spaces-space-id-folders-id-passwords-password-id" [
  space_id: string
  id: string
  password_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # e.g. mon compte google
  --designation: string # e.g. compte google
  --ident: string # e.g. test
  --link: string # e.g. www.google.fr
  --password: string # e.g. azerty
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/passwords/{passwordId}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: passwordId, var: password_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Comment, var: comment}, {name: Designation, var: designation}, {name: Ident, var: ident}, {name: Link, var: link}, {name: Password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, password_id: $password_id, comment: $comment, designation: $designation, ident: $ident, link: $link, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns payrolls of the folder social
#
# GET /spaces/{spaceId}/folders/{id}/payrolls
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, NetAmount: float, TotalGrossAmount: float>
export def "get-spaces-space-id-folders-id-payrolls" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --begin: string # begin date of the payrolls (e.g. 20160321,null)
  --end: string # end date of the payrolls (e.g. 20160321,null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/payrolls"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Begin, var: begin}, {name: End, var: end}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, begin: $begin, end: $end, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a payroll in a folder social
#
# POST /spaces/{spaceId}/folders/{id}/payrolls
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-payrolls" [
  space_id: string
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
  --begin: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --employee-contributions: float # format: float, e.g. 1352.63
  --employer-contributions: float # format: float, e.g. 132.63
  --end: string # e.g. 20160831
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/payrolls"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Begin, var: begin}, {name: DocumentId, var: document_id}, {name: EmployeeContributions, var: employee_contributions}, {name: EmployerContributions, var: employer_contributions}, {name: End, var: end}, {name: NetAmount, var: net_amount}, {name: TotalGrossAmount, var: total_gross_amount}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, begin: $begin, document_id: $document_id, employee_contributions: $employee_contributions, employer_contributions: $employer_contributions, end: $end, net_amount: $net_amount, total_gross_amount: $total_gross_amount, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a nominative social declaration in a folder social
#
# DELETE /spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration
export def "delete-spaces-space-id-folders-id-payrolls-payroll-id-nominative-social-declaration" [
  space_id: string
  id: string
  payroll_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: payrollId, var: payroll_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, payroll_id: $payroll_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a nominative social declaration in a folder social
#
# POST /spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-payrolls-payroll-id-nominative-social-declaration" [
  space_id: string
  id: string
  payroll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: payrollId, var: payroll_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentId, var: document_id}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, payroll_id: $payroll_id, document_id: $document_id, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns payslips of the folder employee
#
# GET /spaces/{spaceId}/folders/{id}/payslips
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, EmployeeContributions: float, EmployerContributions: float, End: string, FixedGrossAmount: float, NetAmount: float, TotalGrossAmount: float, Vacation: float, VariableGrossAmount: float>
export def "get-spaces-space-id-folders-id-payslips" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/payslips"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a payslip in a folder employee
#
# POST /spaces/{spaceId}/folders/{id}/payslips
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-payslips" [
  space_id: string
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
  --begin: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --employee-contributions: float # format: float, e.g. 2000.5
  --employer-contributions: float # format: float, e.g. 400.5
  --end: string # e.g. 20160831
  --fixed-gross-amount: float # format: float, e.g. 1352.63
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
  --vacation: float # format: float, e.g. 20.5
  --variable-gross-amount: float # format: float, e.g. 132.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/payslips"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Begin, var: begin}, {name: DocumentId, var: document_id}, {name: EmployeeContributions, var: employee_contributions}, {name: EmployerContributions, var: employer_contributions}, {name: End, var: end}, {name: FixedGrossAmount, var: fixed_gross_amount}, {name: NetAmount, var: net_amount}, {name: TotalGrossAmount, var: total_gross_amount}, {name: Vacation, var: vacation}, {name: VariableGrossAmount, var: variable_gross_amount}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, begin: $begin, document_id: $document_id, employee_contributions: $employee_contributions, employer_contributions: $employer_contributions, end: $end, fixed_gross_amount: $fixed_gross_amount, net_amount: $net_amount, total_gross_amount: $total_gross_amount, vacation: $vacation, variable_gross_amount: $variable_gross_amount, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a secondary portfolio of a customer contract
#
# DELETE /spaces/{spaceId}/folders/{id}/portfolio/{portfolioId}
export def "delete-spaces-space-id-folders-id-portfolio-portfolio-id" [
  space_id: string
  id: string
  portfolio_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/portfolio/{portfolioId}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: portfolioId, var: portfolio_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, portfolio_id: $portfolio_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a Professional Vehicle
#
# DELETE /spaces/{spaceId}/folders/{id}/professional-vehicle
export def "delete-spaces-space-id-folders-id-professional-vehicle" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/professional-vehicle"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Professional Vehicle data
#
# PATCH /spaces/{spaceId}/folders/{id}/professional-vehicle
export def "patch-spaces-space-id-folders-id-professional-vehicle" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --brand: string # e.g. Renault
  --comment: string # e.g. Peugeot Lyon
  --company-tax: oneof<nothing, bool> # e.g. true
  --date-in: string # e.g. 20201802
  --date-out: string # e.g. 20201802
  --designation: string # e.g. peugeot siège
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, clio]
  --level: string@level-completer # e.g. confidential
  --model: string # e.g. Clio
  --registration-date: string # e.g. 20181231
  --registration-number: string # e.g. AA001AA
  --type: string # e.g. car
  --value: float # e.g. 1500.23
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/professional-vehicle"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Brand, var: brand}, {name: Comment, var: comment}, {name: CompanyTax, var: company_tax}, {name: DateIn, var: date_in}, {name: DateOut, var: date_out}, {name: Designation, var: designation}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Model, var: model}, {name: RegistrationDate, var: registration_date}, {name: RegistrationNumber, var: registration_number}, {name: Type, var: type}, {name: Value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, brand: $brand, comment: $comment, company_tax: $company_tax, date_in: $date_in, date_out: $date_out, designation: $designation, home: $home, keywords: $keywords, level: $level, model: $model, registration_date: $registration_date, registration_number: $registration_number, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a provider
#
# DELETE /spaces/{spaceId}/folders/{id}/provider
export def "delete-spaces-space-id-folders-id-provider" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/provider"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and provider data
#
# GET /spaces/{spaceId}/folders/{id}/provider
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>
export def "get-spaces-space-id-folders-id-provider" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/provider"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Provider data
#
# PATCH /spaces/{spaceId}/folders/{id}/provider
export def "patch-spaces-space-id-folders-id-provider" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --provider-number: string # e.g. 13587449420F
  --start: string # e.g. 20180630
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/provider"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: ProviderNumber, var: provider_number}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, provider_number: $provider_number, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list of the required documents for a person
#
# GET /spaces/{spaceId}/folders/{id}/required-documents
# Returns: table<Comment: string, Date: string, DocIds: list<string>, Id: string, Name: string, Status: string>
export def "get-spaces-space-id-folders-id-required-documents" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/required-documents"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the status of a requireddocument
#
# PATCH /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}
export def "patch-spaces-space-id-folders-id-required-documents-requireddocumentid" [
  space_id: string
  id: string
  requireddocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # e.g. waiting
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: requireddocumentid, var: requireddocumentid}]
    body: {content_type: "application/json", kind: json, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, requireddocumentid: $requireddocumentid, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a required document to a line
#
# POST /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-required-documents-requireddocumentid" [
  space_id: string
  id: string
  requireddocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: record # shape: {Content64Encoded?: string, Name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: requireddocumentid, var: requireddocumentid}]
    body: {content_type: "application/json", kind: json, fields: [{name: File, var: file}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, requireddocumentid: $requireddocumentid, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a document from a required document
#
# DELETE /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}/documents/{documentId}
export def "delete-spaces-space-id-folders-id-required-documents-requireddocumentid-documents-document-id" [
  space_id: string
  id: string
  requireddocumentid: string
  document_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}/documents/{documentId}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: requireddocumentid, var: requireddocumentid}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, requireddocumentid: $requireddocumentid, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns sections of the folder
#
# GET /spaces/{spaceId}/folders/{id}/sections
# Returns: table<Keywords: list<string>, Name: string, State: string, Type: string>
export def "get-spaces-space-id-folders-id-sections" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/sections"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns social contracts of the folder employee
#
# GET /spaces/{spaceId}/folders/{id}/social-contracts
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, ContractDate: string, ContractDuration: string, ContractualChange: string, Position: string, WageDevelopments: float>
export def "get-spaces-space-id-folders-id-social-contracts" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/social-contracts"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a social contract in a folder employee
#
# POST /spaces/{spaceId}/folders/{id}/social-contracts
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-social-contracts" [
  space_id: string
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
  --contract-date: string # e.g. 20190202
  --contract-duration: string # e.g. 6 mois
  --contractual-change: string # e.g. augmentation
  document_id: string # e.g. PBUFBAUBF1531
  --position: string # e.g. cadre
  --wage-developments: float # format: float, e.g. 1548.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/social-contracts"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContractDate, var: contract_date}, {name: ContractDuration, var: contract_duration}, {name: ContractualChange, var: contractual_change}, {name: DocumentId, var: document_id}, {name: Position, var: position}, {name: WageDevelopments, var: wage_developments}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, contract_date: $contract_date, contract_duration: $contract_duration, contractual_change: $contractual_change, document_id: $document_id, position: $position, wage_developments: $wage_developments, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns social declarations
#
# GET /spaces/{spaceId}/folders/{id}/social-declarations
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Amount: float, DeclarationDate: string>
export def "get-spaces-space-id-folders-id-social-declarations" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/social-declarations"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a social declaration
#
# POST /spaces/{spaceId}/folders/{id}/social-declarations
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-social-declarations" [
  space_id: string
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
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/social-declarations"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: DeclarationDate, var: declaration_date}, {name: DocumentId, var: document_id}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, amount: $amount, declaration_date: $declaration_date, document_id: $document_id, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a social regime
#
# DELETE /spaces/{spaceId}/folders/{id}/social-regimes
export def "delete-spaces-space-id-folders-id-social-regimes" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/social-regimes"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and social regime data
#
# GET /spaces/{spaceId}/folders/{id}/social-regimes
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>
export def "get-spaces-space-id-folders-id-social-regimes" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/social-regimes"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Social Regime data
#
# PATCH /spaces/{spaceId}/folders/{id}/social-regimes
export def "patch-spaces-space-id-folders-id-social-regimes" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --periodicity: string@periodicity-completer # e.g. monthly
  --start: string # e.g. 20180630
  --type: string@type-completer-4 # e.g. mandatory
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/social-regimes"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Periodicity, var: periodicity}, {name: Start, var: start}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, periodicity: $periodicity, start: $start, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns sum of invoices of the folder (customer, provider, accountingyear or root folders customers or providers)
#
# GET /spaces/{spaceId}/folders/{id}/sum-invoices
# Returns: record<BeforeVAT: float, InclVAT: float, VAT: float>
export def "get-spaces-space-id-folders-id-sum-invoices" [
  space_id: string
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
  --number: string # Number of the invoice (e.g. 23585)
  --incl-vat: float # amount incl. VAT (e.g. 100.50,101.50)
  --before-vat: float # amount before VAT (e.g. 102.50,101.50)
  --due-date: string # range date due payment (e.g. 20201231)
  --payment-date: string # range date of payment (e.g. 20201201,null)
  --invoice-date: string # range date of invoice (e.g. 20201201,null)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/sum-invoices"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Number, var: number}, {name: InclVat, var: incl_vat}, {name: BeforeVAT, var: before_vat}, {name: DueDate, var: due_date}, {name: PaymentDate, var: payment_date}, {name: InvoiceDate, var: invoice_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, number: $number, incl_vat: $incl_vat, before_vat: $before_vat, due_date: $due_date, payment_date: $payment_date, invoice_date: $invoice_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and tax contract data
#
# DELETE /spaces/{spaceId}/folders/{id}/tax-contract
export def "delete-spaces-space-id-folders-id-tax-contract" [
  space_id: string
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
    path: "/spaces/{spaceId}/folders/{id}/tax-contract"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Tax Contract data
#
# PATCH /spaces/{spaceId}/folders/{id}/tax-contract
export def "patch-spaces-space-id-folders-id-tax-contract" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --comment: string # e.g. pieces company
  --designation: string # e.g. taxes foncières
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180630
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/folders/{id}/tax-contract"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: ArchivalDate, var: archival_date}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, archival_date: $archival_date, comment: $comment, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns vat declarations
#
# GET /spaces/{spaceId}/folders/{id}/vat-declarations
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, Begin: string, CollectedVAT: float, CreditVAT: float, DeductibleVAT: float, End: string, ExemptTurnover: float, Number: string, PayableVAT: float, TaxableTurnover: float>
export def "get-spaces-space-id-folders-id-vat-declarations" [
  space_id: string
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
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/folders/{id}/vat-declarations"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    query: [{name: Date, var: date}, {name: Range, var: range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, date: $date, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a vat declaration
#
# POST /spaces/{spaceId}/folders/{id}/vat-declarations
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-vat-declarations" [
  space_id: string
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
  --begin: string # e.g. 20160801
  --collected-vat: float # format: float, e.g. 1548.63
  --credit-vat: float # format: float, e.g. 400.5
  --deductible-vat: float # format: float, e.g. 20.5
  document_id: string # e.g. PBUFBAUBF1531
  end: string # e.g. 20160831
  --exempt-turnover: float # format: float, e.g. 132.63
  --number: string # e.g. 153126
  --payable-vat: float # format: float, e.g. 2000.5
  --taxable-turnover: float # format: float, e.g. 1352.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/vat-declarations"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Begin, var: begin}, {name: CollectedVAT, var: collected_vat}, {name: CreditVAT, var: credit_vat}, {name: DeductibleVAT, var: deductible_vat}, {name: DocumentId, var: document_id}, {name: End, var: end}, {name: ExemptTurnover, var: exempt_turnover}, {name: Number, var: number}, {name: PayableVAT, var: payable_vat}, {name: TaxableTurnover, var: taxable_turnover}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, begin: $begin, collected_vat: $collected_vat, credit_vat: $credit_vat, deductible_vat: $deductible_vat, document_id: $document_id, end: $end, exempt_turnover: $exempt_turnover, number: $number, payable_vat: $payable_vat, taxable_turnover: $taxable_turnover, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a class document
#
# DELETE /spaces/{spaceId}/folders/{id}/{documentClass}
export def "delete-spaces-space-id-folders-id-document-class" [
  space_id: string
  id: string
  document_class: string
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
    path: "/spaces/{spaceId}/folders/{id}/{documentClass}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: documentClass, var: document_class}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, document_class: $document_class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns document of documentClass (without specific data) of the folder
#
# GET /spaces/{spaceId}/folders/{id}/{documentClass}
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string>
export def "get-spaces-space-id-folders-id-document-class" [
  space_id: string
  id: string
  document_class: string
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
    path: "/spaces/{spaceId}/folders/{id}/{documentClass}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: documentClass, var: document_class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id, document_class: $document_class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/{documentClass}
# Returns: record<Id: string>
export def "post-spaces-space-id-folders-id-document-class" [
  space_id: string
  id: string
  document_class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/folders/{id}/{documentClass}"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: documentClass, var: document_class}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentId, var: document_id}, {name: Accounting, var: accounting}, {name: Author, var: author}, {name: Code, var: code}, {name: Comment, var: comment}, {name: Date, var: date}, {name: File, var: file}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, document_class: $document_class, document_id: $document_id, accounting: $accounting, author: $author, code: $code, comment: $comment, date: $date, file: $file, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of bank folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/banks
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>
export def "get-spaces-space-id-legal-entities-id-banks" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/banks"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a folder for a bank
#
# POST /spaces/{spaceId}/legal-entities/{id}/banks
# Returns: record<Id: string>
export def "post-spaces-space-id-legal-entities-id-banks" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-reference: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180630
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/legal-entities/{id}/banks"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: ContractReference, var: contract_reference}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, contract_reference: $contract_reference, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the banks even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/banks/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>
export def "get-spaces-space-id-legal-entities-id-banks-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/banks/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all contract folders of the legal entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/contracts
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string>
export def "get-spaces-space-id-legal-entities-id-contracts" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/contracts"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the others contract with legal entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/contractual-relationships
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>
export def "get-spaces-space-id-legal-entities-id-contractual-relationships" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/contractual-relationships"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the others contract with legal entity (even archived)
#
# GET /spaces/{spaceId}/legal-entities/{id}/contractual-relationships/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractReference: string, Designation: string>
export def "get-spaces-space-id-legal-entities-id-contractual-relationships-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/contractual-relationships/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the customer
#
# GET /spaces/{spaceId}/legal-entities/{id}/customers
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>
export def "get-spaces-space-id-legal-entities-id-customers" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/customers"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a folder for a customer
#
# POST /spaces/{spaceId}/legal-entities/{id}/customers
# Returns: record<Id: string>
export def "post-spaces-space-id-legal-entities-id-customers" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --portfolio-id: string # e.g. T1OJFOAZ7449420F
  --start: string # e.g. 20180630
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/legal-entities/{id}/customers"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: CustomerNumber, var: customer_number}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: PortfolioId, var: portfolio_id}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, customer_number: $customer_number, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, portfolio_id: $portfolio_id, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the customers (even archived)
#
# GET /spaces/{spaceId}/legal-entities/{id}/customers/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string>
export def "get-spaces-space-id-legal-entities-id-customers-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/customers/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of insurance folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/insurances
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, PolicyNumber: string>
export def "get-spaces-space-id-legal-entities-id-insurances" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/insurances"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a folder for a insurance
#
# POST /spaces/{spaceId}/legal-entities/{id}/insurances
# Returns: record<Id: string>
export def "post-spaces-space-id-legal-entities-id-insurances" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --policy-number: string # e.g. 1358
  --start: string # e.g. 20180630
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/legal-entities/{id}/insurances"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: CustomerNumber, var: customer_number}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: PolicyNumber, var: policy_number}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, customer_number: $customer_number, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, policy_number: $policy_number, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the insurances even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/insurances/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, CustomerNumber: string, Designation: string, PolicyNumber: string>
export def "get-spaces-space-id-legal-entities-id-insurances-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/insurances/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the loan
#
# GET /spaces/{spaceId}/legal-entities/{id}/loans
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>
export def "get-spaces-space-id-legal-entities-id-loans" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/loans"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a folder for a loan
#
# POST /spaces/{spaceId}/legal-entities/{id}/loans
# Returns: record<Id: string>
export def "post-spaces-space-id-legal-entities-id-loans" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --amount: float # format: float, e.g. 1000
  --category: string@category-completer # e.g. debt spreading
  --comment: string # e.g. pieces company
  --designation: string # e.g. emprunt entreprise
  --due-amount: float # format: float, e.g. 1000.6
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --months-number: float # e.g. 12
  --rate: float # format: float, e.g. 2.5
  --start: string # e.g. 20180630
  --total-cost: float # format: float, e.g. 10200
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/legal-entities/{id}/loans"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Amount, var: amount}, {name: Category, var: category}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: DueAmount, var: due_amount}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: MonthsNumber, var: months_number}, {name: Rate, var: rate}, {name: Start, var: start}, {name: TotalCost, var: total_cost}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, amount: $amount, category: $category, comment: $comment, designation: $designation, due_amount: $due_amount, end: $end, home: $home, keywords: $keywords, level: $level, months_number: $months_number, rate: $rate, start: $start, total_cost: $total_cost
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the loans even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/loans/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>
export def "get-spaces-space-id-legal-entities-id-loans-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/loans/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of providers folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/providers
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>
export def "get-spaces-space-id-legal-entities-id-providers" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/providers"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a folder for a provider
#
# POST /spaces/{spaceId}/legal-entities/{id}/providers
# Returns: record<Id: string>
export def "post-spaces-space-id-legal-entities-id-providers" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --provider-number: string # e.g. 13587449420F
  --start: string # e.g. 20180630
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/legal-entities/{id}/providers"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: ProviderNumber, var: provider_number}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, provider_number: $provider_number, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the providers even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/providers/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>
export def "get-spaces-space-id-legal-entities-id-providers-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/providers/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of social regimes folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/social-regimes
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>
export def "get-spaces-space-id-legal-entities-id-social-regimes" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/social-regimes"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a folder for a social regime
#
# POST /spaces/{spaceId}/legal-entities/{id}/social-regimes
# Returns: record<Id: string>
export def "post-spaces-space-id-legal-entities-id-social-regimes" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --periodicity: string@periodicity-completer # e.g. monthly
  --start: string # e.g. 20180630
  --type: string@type-completer-4 # e.g. mandatory
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/legal-entities/{id}/social-regimes"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: Designation, var: designation}, {name: End, var: end}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: Periodicity, var: periodicity}, {name: Start, var: start}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, designation: $designation, end: $end, home: $home, keywords: $keywords, level: $level, periodicity: $periodicity, start: $start, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the social regimes even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/social-regimes/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>
export def "get-spaces-space-id-legal-entities-id-social-regimes-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/legal-entities/{id}/social-regimes/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all loan folders of the space
#
# GET /spaces/{spaceId}/loans
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>
export def "get-spaces-space-id-loans" [
  space_id: string
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
    path: "/spaces/{spaceId}/loans"
    path_params: [{name: spaceId, var: space_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all loan folders even archived of the space
#
# GET /spaces/{spaceId}/loans/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Amount: float, Category: string, Designation: string, DueAmount: float, MonthsNumber: float, Rate: float, TotalCost: float>
export def "get-spaces-space-id-loans-all" [
  space_id: string
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
    path: "/spaces/{spaceId}/loans/all"
    path_params: [{name: spaceId, var: space_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify the invitation of a person to collect documents
#
# PATCH /spaces/{spaceId}/persons/{id}/call-for-document
export def "patch-spaces-space-id-persons-id-call-for-document" [
  space_id: string
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
  --categories: list<string>
  --client-management: string@client-management-completer
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/persons/{id}/call-for-document"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Categories, var: categories}, {name: ClientManagement, var: client_management}, {name: IsAdmin, var: is_admin}, {name: Player, var: player}, {name: PlayerEnd, var: player_end}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, categories: $categories, client_management: $client_management, is_admin: $is_admin, player: $player, player_end: $player_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# invite a person to collect documents
#
# POST /spaces/{spaceId}/persons/{id}/call-for-document
# Returns: record<Id: string>
export def "post-spaces-space-id-persons-id-call-for-document" [
  space_id: string
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
  --categories: list<string> # e.g. [ID, Invoices]
  --client-management: string@client-management-completer
  --comment: string # e.g. first invitation
  --contact: string # e.g. Dupond
  --is-admin: oneof<nothing, bool> # e.g. true
  --message: string # e.g. <p> Bienvenue dans l'espace de l'entreprise SOCIETE </p>
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
  --signature: string # e.g. cordialement
  --subject: string # e.g. invitation sur le coffre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/persons/{id}/call-for-document"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Categories, var: categories}, {name: ClientManagement, var: client_management}, {name: Comment, var: comment}, {name: Contact, var: contact}, {name: IsAdmin, var: is_admin}, {name: Message, var: message}, {name: Player, var: player}, {name: PlayerEnd, var: player_end}, {name: Signature, var: signature}, {name: Subject, var: subject}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, categories: $categories, client_management: $client_management, comment: $comment, contact: $contact, is_admin: $is_admin, message: $message, player: $player, player_end: $player_end, signature: $signature, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the employee
#
# GET /spaces/{spaceId}/persons/{id}/employees
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>
export def "get-spaces-space-id-persons-id-employees" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/persons/{id}/employees"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a folder for a employee
#
# POST /spaces/{spaceId}/persons/{id}/employees
# Returns: record<Id: string>
export def "post-spaces-space-id-persons-id-employees" [
  space_id: string
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
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-type: string # e.g. 01
  --employee-number: string # e.g. 13587FAZCD420F
  --end: string # e.g. 20190101
  --function: string # e.g. commercial
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --postal-mail: oneof<nothing, bool> # e.g. true
  --ss-number: string # e.g. 1542012365985215
  --start: string # e.g. 20180630
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/persons/{id}/employees"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: About, var: about}, {name: Comment, var: comment}, {name: ContractType, var: contract_type}, {name: EmployeeNumber, var: employee_number}, {name: End, var: end}, {name: Function, var: function}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}, {name: PostalMail, var: postal_mail}, {name: SSNumber, var: ss_number}, {name: Start, var: start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, about: $about, comment: $comment, contract_type: $contract_type, employee_number: $employee_number, end: $end, function: $function, home: $home, keywords: $keywords, level: $level, postal_mail: $postal_mail, ss_number: $ss_number, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of all employees (even archived)
#
# GET /spaces/{spaceId}/persons/{id}/employees/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, ContractType: string, EmployeeNumber: string, Function: string, PostalMail: bool, SSNumber: string>
export def "get-spaces-space-id-persons-id-employees-all" [
  space_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/persons/{id}/employees/all"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder exchange of the person
#
# GET /spaces/{spaceId}/persons/{id}/exchange
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-persons-id-exchange" [
  space_id: string
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
    path: "/spaces/{spaceId}/persons/{id}/exchange"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder of the person
#
# GET /spaces/{spaceId}/persons/{id}/follow-ups
# Returns: record<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, ClientManagement: string, Invitation: record<Comment: string, PlayerEnd: string, Status: string>, Player: string>
export def "get-spaces-space-id-persons-id-follow-ups" [
  space_id: string
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
    path: "/spaces/{spaceId}/persons/{id}/follow-ups"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete the invitation of a person in a space
#
# DELETE /spaces/{spaceId}/persons/{id}/guest-in-space
export def "delete-spaces-space-id-persons-id-guest-in-space" [
  space_id: string
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
    path: "/spaces/{spaceId}/persons/{id}/guest-in-space"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# invite a person in a space
#
# PATCH /spaces/{spaceId}/persons/{id}/guest-in-space
export def "patch-spaces-space-id-persons-id-guest-in-space" [
  space_id: string
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
  --client-management: string@client-management-completer
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/persons/{id}/guest-in-space"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientManagement, var: client_management}, {name: Folders, var: folders}, {name: GroupIds, var: group_ids}, {name: IsAdmin, var: is_admin}, {name: Player, var: player}, {name: PlayerEnd, var: player_end}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, client_management: $client_management, folders: $folders, group_ids: $group_ids, is_admin: $is_admin, player: $player, player_end: $player_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# invite a person in a space
#
# POST /spaces/{spaceId}/persons/{id}/guest-in-space
export def "post-spaces-space-id-persons-id-guest-in-space" [
  space_id: string
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
  --client-management: string@client-management-completer
  --comment: string # e.g. first invitation
  --contact: string # e.g. Dupond
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --member-id: string # e.g. PAIHIHFA79TFA
  --message: string # e.g. <p> Bienvenue dans l'espace de l'entreprise SOCIETE </p>
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
  --signature: string # e.g. cordialement
  --subject: string # e.g. invitation sur le coffre
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/persons/{id}/guest-in-space"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientManagement, var: client_management}, {name: Comment, var: comment}, {name: Contact, var: contact}, {name: Folders, var: folders}, {name: GroupIds, var: group_ids}, {name: IsAdmin, var: is_admin}, {name: MemberId, var: member_id}, {name: Message, var: message}, {name: Player, var: player}, {name: PlayerEnd, var: player_end}, {name: Signature, var: signature}, {name: Subject, var: subject}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, client_management: $client_management, comment: $comment, contact: $contact, folders: $folders, group_ids: $group_ids, is_admin: $is_admin, member_id: $member_id, message: $message, player: $player, player_end: $player_end, signature: $signature, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete the invitation of a person in a space
#
# DELETE /spaces/{spaceId}/persons/{id}/invitation
export def "delete-spaces-space-id-persons-id-invitation" [
  space_id: string
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
    path: "/spaces/{spaceId}/persons/{id}/invitation"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns invitation of a person
#
# GET /spaces/{spaceId}/persons/{id}/invitation
# Returns: record<ClientManagement: string, CodeMethod: any, EmployeeAccess: bool, Folders: table<Id: string, Name: string, Right: string>, GroupIds: list<string>, Groups: table<EndDate: string, Id: string, Name: string>, IsAdmin: bool, LinkMethod: record<Type: string>, Player: string, PlayerEnd: string, Status: string>
export def "get-spaces-space-id-persons-id-invitation" [
  space_id: string
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
    path: "/spaces/{spaceId}/persons/{id}/invitation"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# modify an invitation
#
# PATCH /spaces/{spaceId}/persons/{id}/invitation
export def "patch-spaces-space-id-persons-id-invitation" [
  space_id: string
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
  --client-management: string@client-management-completer
  --employee-access: oneof<nothing, bool> # e.g. true
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/persons/{id}/invitation"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientManagement, var: client_management}, {name: EmployeeAccess, var: employee_access}, {name: Folders, var: folders}, {name: GroupIds, var: group_ids}, {name: IsAdmin, var: is_admin}, {name: Player, var: player}, {name: PlayerEnd, var: player_end}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, id: $id, client_management: $client_management, employee_access: $employee_access, folders: $folders, group_ids: $group_ids, is_admin: $is_admin, player: $player, player_end: $player_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create an invitation in a space for a person
#
# POST /spaces/{spaceId}/persons/{id}/invitation
# Returns: record<Id: string>
export def "post-spaces-space-id-persons-id-invitation" [
  space_id: string
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
  --client-management: string@client-management-completer
  --employee-access: oneof<nothing, bool> # e.g. true
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/persons/{id}/invitation"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientManagement, var: client_management}, {name: EmployeeAccess, var: employee_access}, {name: Folders, var: folders}, {name: GroupIds, var: group_ids}, {name: IsAdmin, var: is_admin}, {name: Player, var: player}, {name: PlayerEnd, var: player_end}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, client_management: $client_management, employee_access: $employee_access, folders: $folders, group_ids: $group_ids, is_admin: $is_admin, player: $player, player_end: $player_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# send the invitation of a person in a space
#
# POST /spaces/{spaceId}/persons/{id}/invitation/{invitationId}/send
# Returns: record<Id: string>
export def "post-spaces-space-id-persons-id-invitation-invitation-id-send" [
  space_id: string
  id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact: string # e.g. Dupond
  --message: string # e.g. <p> Bienvenue dans l'espace de l'envtreprise SOCIETE </p>
  --signature: string # e.g. cordialement
  --subject: string # e.g. invitation sur le coffre
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/persons/{id}/invitation/{invitationId}/send"
    path_params: [{name: spaceId, var: space_id}, {name: id, var: id}, {name: invitationId, var: invitation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Contact, var: contact}, {name: Message, var: message}, {name: Signature, var: signature}, {name: Subject, var: subject}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    space_id: $space_id, id: $id, invitation_id: $invitation_id, contact: $contact, message: $message, signature: $signature, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folderId with the access of the person
#
# GET /spaces/{spaceId}/persons/{memberId}/folders/{id}
# Returns: record<Id: string, Right: string, About: string, ArchivalDate: string, Class: string, Home: bool, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string>
export def "get-spaces-space-id-persons-member-id-folders-id" [
  space_id: string
  member_id: string
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
    path: "/spaces/{spaceId}/persons/{memberId}/folders/{id}"
    path_params: [{name: spaceId, var: space_id}, {name: memberId, var: member_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, member_id: $member_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an access
#
# PATCH /spaces/{spaceId}/persons/{memberId}/folders/{id}
export def "patch-spaces-space-id-persons-member-id-folders-id" [
  space_id: string
  member_id: string
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
  --right: string@right-completer-1 # e.g. write
  --about: string # e.g. <b> Mon premier dossier </b>
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> any {
  $in | http-request {
    method: patch
    path: "/spaces/{spaceId}/persons/{memberId}/folders/{id}"
    path_params: [{name: spaceId, var: space_id}, {name: memberId, var: member_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Right, var: right}, {name: About, var: about}, {name: Home, var: home}, {name: Keywords, var: keywords}, {name: Level, var: level}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    space_id: $space_id, member_id: $member_id, id: $id, right: $right, about: $about, home: $home, keywords: $keywords, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and provider data
#
# GET /spaces/{spaceId}/providers
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>
export def "get-spaces-space-id-providers" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/providers"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and provider data (even archived)
#
# GET /spaces/{spaceId}/providers/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, ProviderNumber: string>
export def "get-spaces-space-id-providers-all" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/providers/all"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Research text inside documents, folders or messages
#
# GET /spaces/{spaceId}/search
# Returns: record<Count: table<Class: string, Count: int>, Results: table<Class: string, Extract: record, Id: string, Label: string, Location: list, Score: float, Specific: record>, TotalCount: int>
export def "get-spaces-space-id-search" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Text to find (e.g. durand)
  --range: string # index range of the results (e.g. 10-19)
  --query-context: record # context of research
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/search"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: Query, var: query}, {name: Range, var: range}, {name: QueryContext, var: query_context, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, query: $query, range: $range, query_context: $query_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and social regime data
#
# GET /spaces/{spaceId}/social-regimes
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>
export def "get-spaces-space-id-social-regimes" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/social-regimes"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns folder with Id and social regime data (even archived)
#
# GET /spaces/{spaceId}/social-regimes/all
# Returns: table<About: string, ArchivalDate: string, Class: string, Home: bool, Id: string, Keywords: list<string>, Level: string, ModificationDate: string, Name: string, Parent: string, Comment: string, End: string, Start: string, Designation: string, Periodicity: string, Type: string>
export def "get-spaces-space-id-social-regimes-all" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/social-regimes/all"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: WithContractingPartner, var: with_contracting_partner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, with_contracting_partner: $with_contracting_partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns CSV Invoicings of the spaces for the account of the spaceId
#
# GET /spaces/{spaceId}/spaces-invoicings
# Returns: table<Author: string, Class: list<string>, Code: string, Comment: string, Date: string, Extension: string, FolderDate: string, Id: string, Title: string, InvoiceNumber: string>
export def "get-spaces-space-id-spaces-invoicings" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # date range of the documents (e.g. 20160321,null)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/spaces-invoicings"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: Date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
