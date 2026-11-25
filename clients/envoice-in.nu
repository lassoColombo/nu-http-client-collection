# Auto-generated client for API v1.0.0 v1
# Source: https://api.apis.guru/v2/specs/envoice.in/v1/openapi.json
# Auth: --token flag or $env.API_V1_0_0_TOKEN

const CLIENT = {
  base_url: "https://www.envoice.in"
  token_env_var: "API_V1_0_0_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-auth-key, in: header, header_name: x-auth-key, prefix: ""}
    {name: x-auth-secret, in: header, header_name: x-auth-secret, prefix: ""}
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

def base-url-completer [] { ["https://www.envoice.in"] }
def auth-scheme-completer [] { ["x-auth-key" "x-auth-secret"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/html" "text/json" "text/xml"] }
def status-completer [] { ["Accepted" "Draft" "Rejected"] }
def status-completer-1 [] { ["Draft" "Overdue" "Paid" "Unpaid" "Void"] }
def status-completer-2 [] { ["Cancelled" "Completed" "Failed" "OnHold" "PendingPayment" "Processing" "Refunded" "Shipped"] }
def status-completer-3 [] { ["Active" "Inactive" "NotAvailable"] }
def query-options-order-completer [] { ["Asc" "Desc" "None"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    client-api-all: "table<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>"
    client-api-can-delete: "bool"
    client-api-delete: "int"
    client-api-details: "record<AdditionalEmails: table<Email: string>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>"
    client-api-new: "int"
    estimation-api-all: "record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int>"
    estimation-api-change-status: "bool"
    estimation-api-convert: "record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>"
    estimation-api-delete: "int"
    estimation-api-details: "record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>"
    estimation-api-new: "record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>"
    estimation-api-send-to-client: "int"
    estimation-api-status: "string"
    estimation-api-update: "record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>"
    estimation-api-uri: "record<Link: string>"
    general-api-countries: "table<Id: int, Name: string, Value: string>"
    general-api-currencies: "table<Code: string, Id: int, Name: string, Symbol: string, Value: string>"
    general-api-date-formats: "list<string>"
    general-api-ui-languages: "table<Id: int, Name: string, UiCulture: string>"
    invoice-api-all: "record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, RecurringProfile: record, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int>"
    get-api-invoice-allcategories: "record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<Id: int, Name: string>, TotalCount: int>"
    invoice-api-change-status: "bool"
    invoice-api-delete: "int"
    post-api-invoice-deletecategory: "int"
    invoice-api-details: "record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>"
    invoice-api-new: "record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>"
    post-api-invoice-newcategory: "record<Id: int, Name: string>"
    invoice-api-pdf: "record<Link: string>"
    invoice-api-send-to-accountant: "int"
    invoice-api-send-to-client: "int"
    invoice-api-status: "string"
    invoice-api-update: "record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>"
    post-api-invoice-updatecategory: "record<Id: int, Name: string>"
    invoice-api-uri: "record<Link: string>"
    order-api-all: "record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, CouponCode: string, Currency: record, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Name: string, Note: string, OrderBillingDetails: record, OrderShippingDetails: record, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int>"
    order-api-delete: "int"
    order-api-details: "record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, CouponCode: string, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Items: table<Cost: float, Description: string, ProductItemId: int, Quantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, Note: string, OrderBillingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, OrderShippingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>"
    order-api-new: "int"
    payment-api-supported: "table<Name: string, SupportedCurrencies: list<record>>"
    payment-link-api-all: "record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClientId: int, Currency: record, CurrencyId: int, DiscountAmount: float, Id: int, Invoice: record, Items: list, Number: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, User: record, UserId: int>, TotalCount: int>"
    payment-link-api-delete: "int"
    payment-link-api-new: "int"
    payment-link-api-uri: "record<Link: string>"
    product-api-all: "record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, ButtonCallToAction: string, Currency: record, CurrencyId: int, Description: string, Id: int, IsFeatured: bool, Name: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int>"
    product-api-delete: "int"
    product-api-details: "record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, ButtonCallToAction: string, Coupons: table<Code: string, DiscountAmount: float, DiscountPercentage: float, Id: int, ValidUntil: string>, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, Discounts: table<DiscountAmount: float, DiscountPercentage: float, Id: int, Name: string, ValidFrom: string, ValidTo: string>, Id: int, IsFeatured: bool, Items: table<Cost: float, Description: string, Id: int, MinimumQuantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, PaymentGateways: table<Name: string>, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>"
    product-api-new: "int"
    tax-api-all: "table<CreatedOn: string, Id: int, Name: string, Percentage: float>"
    tax-api-delete: "int"
    tax-api-new: "int"
    work-type-api-all: "table<CreatedOn: string, Id: int, Title: string>"
    work-type-api-delete: "int"
    work-type-api-details: "record<CreatedOn: string, Id: int, Title: string>"
    work-type-api-new: "int"
    work-type-api-search: "table<CreatedOn: string, Id: int, Title: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["client-api-all" "client-api-can-delete" "client-api-delete" "client-api-details" "client-api-new" "client-api-update" "estimation-api-all" "estimation-api-change-status" "estimation-api-convert" "estimation-api-delete" "estimation-api-details" "estimation-api-new" "estimation-api-send-to-client" "estimation-api-status" "estimation-api-update" "estimation-api-uri" "general-api-countries" "general-api-currencies" "general-api-date-formats" "general-api-ui-languages" "invoice-api-all" "get-api-invoice-allcategories" "invoice-api-change-status" "invoice-api-delete" "post-api-invoice-deletecategory" "invoice-api-details" "invoice-api-new" "post-api-invoice-newcategory" "invoice-api-pdf" "invoice-api-send-to-accountant" "invoice-api-send-to-client" "invoice-api-status" "invoice-api-update" "post-api-invoice-updatecategory" "invoice-api-uri" "order-api-all" "order-api-change-shipping-details" "order-api-change-status" "order-api-delete" "order-api-details" "order-api-new" "payment-api-supported" "payment-link-api-all" "payment-link-api-delete" "payment-link-api-new" "payment-link-api-uri" "product-api-all" "product-api-delete" "product-api-details" "product-api-new" "product-api-update" "tax-api-all" "tax-api-delete" "tax-api-new" "tax-api-update" "work-type-api-all" "work-type-api-delete" "work-type-api-details" "work-type-api-new" "work-type-api-search" "work-type-api-update" "commands"] | sort) } | get name | first)
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

# Return all clients for the account
#
# GET /api/client/all
# Returns: table<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>
# operationId: ClientApi_All
export def "client-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/client/all"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check if the provided client can be deleted
#
# GET /api/client/candelete
# Returns: bool
# operationId: ClientApi_CanDelete
export def "client-api-can-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> any {
  http-request {
    method: get
    path: "/api/client/candelete"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing client
#
# POST /api/client/delete
# Returns: int
# operationId: ClientApi_Delete
export def "client-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of client to be deleted (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/client/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return client details. Activities and invoices included.
#
# GET /api/client/details
# Returns: record<AdditionalEmails: table<Email: string>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>
# operationId: ClientApi_Details
export def "client-api-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/client/details"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a client
#
# POST /api/client/new
# Returns: int
# operationId: ClientApi_New
export def "client-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --additional-emails: list # Client additional emails contact for CC — item shape: {Email?: string}
  --address: string # Client business address
  --client-country-id: int # Indicates the country where the clients is from (format: int32)
  --client-currency-id: int # Indicates the default system currency used by the user for the client (format: int32)
  --company-registration-number: string # Client's Company Registration Number
  --default-due-date-in-days: int # Client custom payment terms (format: int32)
  --email: string # Client email
  --name: string # Name of the client
  --phone-number: string # Client phone numer
  --ui-language-id: int # Hold a value of the language in which the invoice will be sent (format: int32)
  --vat: string # Client's VAT number
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/client/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AdditionalEmails, var: additional_emails}, {name: Address, var: address}, {name: ClientCountryId, var: client_country_id}, {name: ClientCurrencyId, var: client_currency_id}, {name: CompanyRegistrationNumber, var: company_registration_number}, {name: DefaultDueDateInDays, var: default_due_date_in_days}, {name: Email, var: email}, {name: Name, var: name}, {name: PhoneNumber, var: phone_number}, {name: UiLanguageId, var: ui_language_id}, {name: Vat, var: vat}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, additional_emails: $additional_emails, address: $address, client_country_id: $client_country_id, client_currency_id: $client_currency_id, company_registration_number: $company_registration_number, default_due_date_in_days: $default_due_date_in_days, email: $email, name: $name, phone_number: $phone_number, ui_language_id: $ui_language_id, vat: $vat
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing client
#
# POST /api/client/update
# operationId: ClientApi_Update
export def "client-api-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --additional-emails: list # Client additional emails contact for CC — item shape: {Email?: string}
  --address: string # Client business address
  --client-country-id: int # Indicates the country where the clients is from (format: int32)
  --client-currency-id: int # Indicates the default system currency used by the user for the client (format: int32)
  --company-registration-number: string # Client's Company Registration Number
  --default-due-date-in-days: int # Client custom payment terms (format: int32)
  --email: string # Client email
  --id: int # Entity id (format: int32)
  --name: string # Name of the client
  --phone-number: string # Client phone numer
  --ui-language-id: int # Hold a value of the language in which the invoice will be sent (format: int32)
  --vat: string # Client's VAT number
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/client/update"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AdditionalEmails, var: additional_emails}, {name: Address, var: address}, {name: ClientCountryId, var: client_country_id}, {name: ClientCurrencyId, var: client_currency_id}, {name: CompanyRegistrationNumber, var: company_registration_number}, {name: DefaultDueDateInDays, var: default_due_date_in_days}, {name: Email, var: email}, {name: Id, var: id}, {name: Name, var: name}, {name: PhoneNumber, var: phone_number}, {name: UiLanguageId, var: ui_language_id}, {name: Vat, var: vat}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, additional_emails: $additional_emails, address: $address, client_country_id: $client_country_id, client_currency_id: $client_currency_id, company_registration_number: $company_registration_number, default_due_date_in_days: $default_due_date_in_days, email: $email, id: $id, name: $name, phone_number: $phone_number, ui_language_id: $ui_language_id, vat: $vat
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all estimation for the account
#
# GET /api/estimation/all
# Returns: record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int>
# operationId: EstimationApi_All
export def "estimation-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/estimation/all"
    query: [{name: "queryOptions.page", var: query_options_page}, {name: "queryOptions.pageSize", var: query_options_page_size}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    query_options_page: $query_options_page, query_options_page_size: $query_options_page_size, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change estimation status
#
# POST /api/estimation/changestatus
# Returns: bool
# operationId: EstimationApi_ChangeStatus
export def "estimation-api-change-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Estimation Id (format: int32)
  --status: string@status-completer # New status of the estimation
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/estimation/changestatus"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Status, var: status}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Convert the estimation to an invoice
#
# POST /api/estimation/convert
# Returns: record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>
# operationId: EstimationApi_Convert
export def "estimation-api-convert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --body: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/estimation/convert"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing estimation
#
# POST /api/estimation/delete
# Returns: int
# operationId: EstimationApi_Delete
export def "estimation-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of estimation to be deleted (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/estimation/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return estimation data
#
# GET /api/estimation/details
# Returns: record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>
# operationId: EstimationApi_Details
export def "estimation-api-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/estimation/details"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an estimation
#
# POST /api/estimation/new
# Returns: record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>
# operationId: EstimationApi_New
export def "estimation-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --attachments: list # List of estimation attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this estimation is assigned (format: int32)
  --cloned-from-id: int # Indicate from which estimation this estimation has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the estimation amounts (format: int32)
  --expires-on: string # Indicates when the estimation will be proclamed as due (format: date-time)
  --issued-on: string # Indicates when the estimation was issued (format: date-time)
  --items: list # List of estimation items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the estimation
  --number: string # Unique estimation number
  --payment-gateways: list # List of enabled payment gateways for this estimation — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --status: string@status-completer # Indicate the status of the estimation (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/estimation/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attachments, var: attachments}, {name: ClientId, var: client_id}, {name: ClonedFromId, var: cloned_from_id}, {name: CurrencyId, var: currency_id}, {name: ExpiresOn, var: expires_on}, {name: IssuedOn, var: issued_on}, {name: Items, var: items}, {name: Notes, var: notes}, {name: Number, var: number}, {name: PaymentGateways, var: payment_gateways}, {name: PoNumber, var: po_number}, {name: Status, var: status}, {name: Terms, var: terms}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, attachments: $attachments, client_id: $client_id, cloned_from_id: $cloned_from_id, currency_id: $currency_id, expires_on: $expires_on, issued_on: $issued_on, items: $items, notes: $notes, number: $number, payment_gateways: $payment_gateways, po_number: $po_number, status: $status, terms: $terms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send the provided estimation to the client
#
# POST /api/estimation/sendtoclient
# Returns: int
# operationId: EstimationApi_SendToClient
export def "estimation-api-send-to-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --attach-pdf: oneof<nothing, bool> # Should attach pdf file
  --estimation-id: int # Id of the estimation (format: int32)
  --id: int # Id of the estimation (format: int32)
  --message: string # Message to be embedded in the email
  --send-to-self: oneof<nothing, bool> # Should email copy be send to self
  --subject: string # Subject for the email
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/estimation/sendtoclient"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AttachPdf, var: attach_pdf}, {name: EstimationId, var: estimation_id}, {name: Id, var: id}, {name: Message, var: message}, {name: SendToSelf, var: send_to_self}, {name: Subject, var: subject}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, attach_pdf: $attach_pdf, estimation_id: $estimation_id, id: $id, message: $message, send_to_self: $send_to_self, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the status of the estimation
#
# GET /api/estimation/status
# Returns: string
# operationId: EstimationApi_Status
export def "estimation-api-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> any {
  http-request {
    method: get
    path: "/api/estimation/status"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing estimation
#
# POST /api/estimation/update
# Returns: record<AccessToken: string, Activities: table<EstimationNumber: string, Id: int, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, ExpiresOn: string, Id: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, PoNumber: string, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>
# operationId: EstimationApi_Update
export def "estimation-api-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --attachments: list # List of estimation attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this estimation is assigned (format: int32)
  --cloned-from-id: int # Indicate from which estimation this estimation has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the estimation amounts (format: int32)
  --expires-on: string # Indicates when the estimation will be proclamed as due (format: date-time)
  --id: int # estimation id (format: int32)
  --issued-on: string # Indicates when the estimation was issued (format: date-time)
  --items: list # List of estimation items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the estimation
  --number: string # Unique estimation number
  --payment-gateways: list # List of enabled payment gateways for this estimation — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --status: string@status-completer # Indicate the status of the estimation (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/estimation/update"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attachments, var: attachments}, {name: ClientId, var: client_id}, {name: ClonedFromId, var: cloned_from_id}, {name: CurrencyId, var: currency_id}, {name: ExpiresOn, var: expires_on}, {name: Id, var: id}, {name: IssuedOn, var: issued_on}, {name: Items, var: items}, {name: Notes, var: notes}, {name: Number, var: number}, {name: PaymentGateways, var: payment_gateways}, {name: PoNumber, var: po_number}, {name: Status, var: status}, {name: Terms, var: terms}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, attachments: $attachments, client_id: $client_id, cloned_from_id: $cloned_from_id, currency_id: $currency_id, expires_on: $expires_on, id: $id, issued_on: $issued_on, items: $items, notes: $notes, number: $number, payment_gateways: $payment_gateways, po_number: $po_number, status: $status, terms: $terms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the unique url to the client's invoice
#
# GET /api/estimation/uri
# Returns: record<Link: string>
# operationId: EstimationApi_Uri
export def "estimation-api-uri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/estimation/uri"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all of the platform supported countries
#
# GET /api/general/countries
# Returns: table<Id: int, Name: string, Value: string>
# operationId: GeneralApi_Countries
export def "general-api-countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/general/countries"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all of the platform supported currencies
#
# GET /api/general/currencies
# Returns: table<Code: string, Id: int, Name: string, Symbol: string, Value: string>
# operationId: GeneralApi_Currencies
export def "general-api-currencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/general/currencies"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all of the platform supported Date Formats
#
# GET /api/general/dateformats
# Returns: list<string>
# operationId: GeneralApi_DateFormats
export def "general-api-date-formats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/general/dateformats"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all of the platform supported UI languages
#
# GET /api/general/uilanguages
# Returns: table<Id: int, Name: string, UiCulture: string>
# operationId: GeneralApi_UiLanguages
export def "general-api-ui-languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/general/uilanguages"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all invoices for the account
#
# GET /api/invoice/all
# Returns: record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClonedFromId: int, Currency: record, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Notes: string, Number: string, PoNumber: string, RecurringProfile: record, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>, TotalCount: int>
# operationId: InvoiceApi_All
export def "invoice-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/invoice/all"
    query: [{name: "queryOptions.page", var: query_options_page}, {name: "queryOptions.pageSize", var: query_options_page_size}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    query_options_page: $query_options_page, query_options_page_size: $query_options_page_size, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all invoice categories for the account
#
# GET /api/invoice/allcategories
# Returns: record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<Id: int, Name: string>, TotalCount: int>
export def "get-api-invoice-allcategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/invoice/allcategories"
    query: [{name: query, var: query}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    query: $query, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change invoice status
#
# POST /api/invoice/changestatus
# Returns: bool
# operationId: InvoiceApi_ChangeStatus
export def "invoice-api-change-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Invoice Id (format: int32)
  --status: string@status-completer-1 # New status of the invoice
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/invoice/changestatus"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Status, var: status}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing invoice
#
# POST /api/invoice/delete
# Returns: int
# operationId: InvoiceApi_Delete
export def "invoice-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of invoice to be deleted (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/invoice/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing invoice category
#
# POST /api/invoice/deletecategory
# Returns: int
export def "post-api-invoice-deletecategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/invoice/deletecategory"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return invoice data
#
# GET /api/invoice/details
# Returns: record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>
# operationId: InvoiceApi_Details
export def "invoice-api-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/invoice/details"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an invoice
#
# POST /api/invoice/new
# Returns: record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>
# operationId: InvoiceApi_New
export def "invoice-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --attachments: list # List of invoice attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this invoice is assigned (format: int32)
  --cloned-from-id: int # Indicate from which invoice this invoice has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the invoice amounts (format: int32)
  --duedate: string # Indicates when the invoice will be proclamed as due (format: date-time)
  --invoice-category-id: int # Hold the id of the invoice category (format: int32)
  --issued-on: string # Indicates when the invoice was issued (format: date-time)
  --items: list # List of invoice items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the invoice
  --number: string # Unique invoice number
  --payment-gateways: list # List of enabled payment gateways for this invoice — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --recurring-profile: record # Definition of invoice recurring profile — shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
  --recurring-profile-id: int # Hold the id of the recurring profile (format: int32)
  --should-send-reminders: oneof<nothing, bool> # Should send email reminders to client?
  --status: string@status-completer-1 # Indicate the status of the invoice (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/invoice/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attachments, var: attachments}, {name: ClientId, var: client_id}, {name: ClonedFromId, var: cloned_from_id}, {name: CurrencyId, var: currency_id}, {name: Duedate, var: duedate}, {name: InvoiceCategoryId, var: invoice_category_id}, {name: IssuedOn, var: issued_on}, {name: Items, var: items}, {name: Notes, var: notes}, {name: Number, var: number}, {name: PaymentGateways, var: payment_gateways}, {name: PoNumber, var: po_number}, {name: RecurringProfile, var: recurring_profile}, {name: RecurringProfileId, var: recurring_profile_id}, {name: ShouldSendReminders, var: should_send_reminders}, {name: Status, var: status}, {name: Terms, var: terms}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, attachments: $attachments, client_id: $client_id, cloned_from_id: $cloned_from_id, currency_id: $currency_id, duedate: $duedate, invoice_category_id: $invoice_category_id, issued_on: $issued_on, items: $items, notes: $notes, number: $number, payment_gateways: $payment_gateways, po_number: $po_number, recurring_profile: $recurring_profile, recurring_profile_id: $recurring_profile_id, should_send_reminders: $should_send_reminders, status: $status, terms: $terms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an invoice category
#
# POST /api/invoice/newcategory
# Returns: record<Id: int, Name: string>
export def "post-api-invoice-newcategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --name: string # Category name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/invoice/newcategory"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the PDF for the invoice
#
# GET /api/invoice/pdf
# Returns: record<Link: string>
# operationId: InvoiceApi_Pdf
export def "invoice-api-pdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --signed-version: oneof<nothing, bool>
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/invoice/pdf"
    query: [{name: id, var: id, required: true}, {name: signedVersion, var: signed_version}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, signed_version: $signed_version, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send the provided invoice to the accountant
#
# POST /api/invoice/sendtoaccountant
# Returns: int
# operationId: InvoiceApi_SendToAccountant
export def "invoice-api-send-to-accountant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of the invoice (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/invoice/sendtoaccountant"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send the provided invoice to the client
#
# POST /api/invoice/sendtoclient
# Returns: int
# operationId: InvoiceApi_SendToClient
export def "invoice-api-send-to-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --attach-pdf: oneof<nothing, bool> # Should attach pdf file
  --id: int # Id of the invoice (format: int32)
  --invoice-id: int # Id of the invoice (format: int32)
  --message: string # Message to be embedded in the email
  --send-to-self: oneof<nothing, bool> # Should email copy be send to self
  --subject: string # Subject for the email
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/invoice/sendtoclient"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AttachPdf, var: attach_pdf}, {name: Id, var: id}, {name: InvoiceId, var: invoice_id}, {name: Message, var: message}, {name: SendToSelf, var: send_to_self}, {name: Subject, var: subject}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, attach_pdf: $attach_pdf, id: $id, invoice_id: $invoice_id, message: $message, send_to_self: $send_to_self, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the status of the invoice
#
# GET /api/invoice/status
# Returns: string
# operationId: InvoiceApi_Status
export def "invoice-api-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> any {
  http-request {
    method: get
    path: "/api/invoice/status"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing invoice
#
# POST /api/invoice/update
# Returns: record<AccessToken: string, Activities: table<Id: int, InvoiceNumber: string, Link: string, Message: string, Type: string>, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, Client: record<AdditionalEmails: list<record>, Address: string, ClientCountryId: int, ClientCurrencyId: int, CompanyRegistrationNumber: string, CreatedOn: string, DefaultDueDateInDays: int, Email: string, Id: int, Name: string, PhoneNumber: string, UiLanguageId: int, Vat: string>, ClonedFromId: int, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, DiscountAmount: float, Duedate: string, EnablePartialPayments: bool, Id: int, InvoiceCategoryId: int, IssuedOn: string, Items: table<Cost: float, Description: string, DiscountAmount: float, DiscountPercentage: float, Id: int, Quantity: float, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Notes: string, Number: string, PaymentGateways: table<Name: string>, Payments: table<Amount: float, Id: int, IsAutomatic: bool, Note: string, PaidOn: string, ReferenceId: string, Type: string>, PoNumber: string, RecurringProfile: record<DayOfMonth: int, DayOfWeek: string, DueDateInDays: int, EndOfRecurrance: string, Month: int, RecurrancePattern: string, RecurranceValue: int, StartOfRecurrance: string, Status: string, Title: string>, RecurringProfileId: int, ShouldSendReminders: bool, Status: string, SubTotalAmount: float, TaxAmount: float, Terms: string, TotalAmount: float>
# operationId: InvoiceApi_Update
export def "invoice-api-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --attachments: list # List of invoice attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --client-id: int # The client to whom this invoice is assigned (format: int32)
  --cloned-from-id: int # Indicate from which invoice this invoice has been cloned from (format: int32)
  --currency-id: int # Id of the currency for the invoice amounts (format: int32)
  --duedate: string # Indicates when the invoice will be proclamed as due (format: date-time)
  --id: int # Invoice id (format: int32)
  --invoice-category-id: int # Hold the id of the invoice category (format: int32)
  --issued-on: string # Indicates when the invoice was issued (format: date-time)
  --items: list # List of invoice items — item shape: {Cost?: float, Description?: string, DiscountPercentage?: float, Id?: int, Quantity?: float, TaxId?: int, TaxPercentage?: float, WorkTypeId?: int}
  --notes: string # Internal note regarding the invoice
  --number: string # Unique invoice number
  --payment-gateways: list # List of enabled payment gateways for this invoice — item shape: {Name?: string}
  --po-number: string # Unique number generated by the buyer
  --recurring-profile: record # Definition of invoice recurring profile — shape: {DayOfMonth?: int, DayOfWeek?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", DueDateInDays?: int, EndOfRecurrance?: string, Month?: int, RecurrancePattern?: "Daily"|"Weekly"|"Monthly"|"Yearly", RecurranceValue?: int, StartOfRecurrance?: string, Status?: "Pending"|"Active"|"Cancelled"|"Finished", Title?: string}
  --recurring-profile-id: int # Hold the id of the recurring profile (format: int32)
  --should-send-reminders: oneof<nothing, bool> # Should send email reminders to client?
  --status: string@status-completer-1 # Indicate the status of the invoice (paid/unpaid/overdue)
  --terms: string # Terms of agreement
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/invoice/update"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Attachments, var: attachments}, {name: ClientId, var: client_id}, {name: ClonedFromId, var: cloned_from_id}, {name: CurrencyId, var: currency_id}, {name: Duedate, var: duedate}, {name: Id, var: id}, {name: InvoiceCategoryId, var: invoice_category_id}, {name: IssuedOn, var: issued_on}, {name: Items, var: items}, {name: Notes, var: notes}, {name: Number, var: number}, {name: PaymentGateways, var: payment_gateways}, {name: PoNumber, var: po_number}, {name: RecurringProfile, var: recurring_profile}, {name: RecurringProfileId, var: recurring_profile_id}, {name: ShouldSendReminders, var: should_send_reminders}, {name: Status, var: status}, {name: Terms, var: terms}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, attachments: $attachments, client_id: $client_id, cloned_from_id: $cloned_from_id, currency_id: $currency_id, duedate: $duedate, id: $id, invoice_category_id: $invoice_category_id, issued_on: $issued_on, items: $items, notes: $notes, number: $number, payment_gateways: $payment_gateways, po_number: $po_number, recurring_profile: $recurring_profile, recurring_profile_id: $recurring_profile_id, should_send_reminders: $should_send_reminders, status: $status, terms: $terms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing invoice category
#
# POST /api/invoice/updatecategory
# Returns: record<Id: int, Name: string>
export def "post-api-invoice-updatecategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Entity id (format: int32)
  --name: string # Category name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/invoice/updatecategory"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the unique url to the client's invoice
#
# GET /api/invoice/uri
# Returns: record<Link: string>
# operationId: InvoiceApi_Uri
export def "invoice-api-uri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/invoice/uri"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all orders for the account
#
# GET /api/order/all
# Returns: record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, CouponCode: string, Currency: record, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Name: string, Note: string, OrderBillingDetails: record, OrderShippingDetails: record, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int>
# operationId: OrderApi_All
export def "order-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/order/all"
    query: [{name: "queryOptions.page", var: query_options_page}, {name: "queryOptions.pageSize", var: query_options_page_size}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    query_options_page: $query_options_page, query_options_page_size: $query_options_page_size, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change order shipping details
#
# POST /api/order/changeshippingdetails
# operationId: OrderApi_ChangeShippingDetails
export def "order-api-change-shipping-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --address: string # Client street and number
  --country-id: int # Client country id (format: int32)
  --email: string # Client email
  --name: string # Client name
  --phone-number: string # Client phone number
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/order/changeshippingdetails"
    query: [{name: orderId, var: order_id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}, {name: CountryId, var: country_id}, {name: Email, var: email}, {name: Name, var: name}, {name: PhoneNumber, var: phone_number}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-key
  } {
    order_id: $order_id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, address: $address, country_id: $country_id, email: $email, name: $name, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change order status
#
# POST /api/order/changestatus
# operationId: OrderApi_ChangeStatus
export def "order-api-change-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Order Id (format: int32)
  --reason: string # Reason for status change
  --status: string@status-completer-2 # New status of the order
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/order/changestatus"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Reason, var: reason}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id, reason: $reason, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing order
#
# POST /api/order/delete
# Returns: int
# operationId: OrderApi_Delete
export def "order-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of order to be deleted (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/order/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return order details
#
# GET /api/order/details
# Returns: record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, CouponCode: string, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, DiscountAmount: float, Id: int, Items: table<Cost: float, Description: string, ProductItemId: int, Quantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, Note: string, OrderBillingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, OrderShippingDetails: record<Address: string, CountryId: int, Email: string, Name: string, PhoneNumber: string>, ProductId: int, Referral: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>
# operationId: OrderApi_Details
export def "order-api-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/order/details"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an order
#
# POST /api/order/new
# Returns: int
# operationId: OrderApi_New
export def "order-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --after-payment-description: string # After payment description
  --attachments: list # List of Order attachments — item shape: {Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --coupon-code: string # Coupon to apply in order to get the discount
  --currency-id: int # Foreign key Currency (format: int32)
  --description: string # Product description
  --discount-amount: float # Discount amount (format: double)
  --items: list # List of Order items — item shape: {Cost?: float, Description?: string, ProductItemId?: int, Quantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --name: string # Product alias
  --note: string # Customer note to seller
  --order-billing-details: record # shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
  --order-shipping-details: record # shape: {Address?: string, CountryId?: int, Email?: string, Name?: string, PhoneNumber?: string}
  --product-id: int # Product id (format: int32)
  --referral: string # Represent the referral for this order
  --shipping-amount: float # Cost for shipping the product (format: double)
  --shipping-description: string # Client instructions for shipping
  --status: string@status-completer-2 # Order status
  --sub-total-amount: float # Sub total amount (format: double)
  --tax-amount: float # Tax amount (format: double)
  --total-amount: float # Total amount (format: double)
  --what-happens-next-description: string # What happens next description
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/order/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AfterPaymentDescription, var: after_payment_description}, {name: Attachments, var: attachments}, {name: CouponCode, var: coupon_code}, {name: CurrencyId, var: currency_id}, {name: Description, var: description}, {name: DiscountAmount, var: discount_amount}, {name: Items, var: items}, {name: Name, var: name}, {name: Note, var: note}, {name: OrderBillingDetails, var: order_billing_details}, {name: OrderShippingDetails, var: order_shipping_details}, {name: ProductId, var: product_id}, {name: Referral, var: referral}, {name: ShippingAmount, var: shipping_amount}, {name: ShippingDescription, var: shipping_description}, {name: Status, var: status}, {name: SubTotalAmount, var: sub_total_amount}, {name: TaxAmount, var: tax_amount}, {name: TotalAmount, var: total_amount}, {name: WhatHappensNextDescription, var: what_happens_next_description}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, after_payment_description: $after_payment_description, attachments: $attachments, coupon_code: $coupon_code, currency_id: $currency_id, description: $description, discount_amount: $discount_amount, items: $items, name: $name, note: $note, order_billing_details: $order_billing_details, order_shipping_details: $order_shipping_details, product_id: $product_id, referral: $referral, shipping_amount: $shipping_amount, shipping_description: $shipping_description, status: $status, sub_total_amount: $sub_total_amount, tax_amount: $tax_amount, total_amount: $total_amount, what_happens_next_description: $what_happens_next_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all supported payment gateways (no currencies means all are supported)
#
# GET /api/payment/supported
# Returns: table<Name: string, SupportedCurrencies: list<record>>
# operationId: PaymentApi_Supported
export def "payment-api-supported" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/payment/supported"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a payment link
#
# GET /api/paymentlink/all
# Returns: record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, Client: record, ClientId: int, Currency: record, CurrencyId: int, DiscountAmount: float, Id: int, Invoice: record, Items: list, Number: string, SubTotalAmount: float, TaxAmount: float, TotalAmount: float, User: record, UserId: int>, TotalCount: int>
# operationId: PaymentLinkApi_All
export def "payment-link-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/paymentlink/all"
    query: [{name: "queryOptions.page", var: query_options_page}, {name: "queryOptions.pageSize", var: query_options_page_size}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    query_options_page: $query_options_page, query_options_page_size: $query_options_page_size, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing payment link
#
# POST /api/paymentlink/delete
# Returns: int
# operationId: PaymentLinkApi_Delete
export def "payment-link-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --access-token: string
  --client: record # shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
  --client-id: int # format: int32
  --currency: record # shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
  --currency-id: int # format: int32
  --discount-amount: float # format: double
  --id: int # format: int32
  --invoice: record # shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, ... (6 more fields)}
  --items: list # item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
  --number: string
  --sub-total-amount: float # format: double
  --tax-amount: float # format: double
  --total-amount: float # format: double
  --user: record # shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", ... (3 more fields)}
  --user-id: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/paymentlink/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccessToken, var: access_token}, {name: Client, var: client}, {name: ClientId, var: client_id}, {name: Currency, var: currency}, {name: CurrencyId, var: currency_id}, {name: DiscountAmount, var: discount_amount}, {name: Id, var: id}, {name: Invoice, var: invoice}, {name: Items, var: items}, {name: Number, var: number}, {name: SubTotalAmount, var: sub_total_amount}, {name: TaxAmount, var: tax_amount}, {name: TotalAmount, var: total_amount}, {name: User, var: user}, {name: UserId, var: user_id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, access_token: $access_token, client: $client, client_id: $client_id, currency: $currency, currency_id: $currency_id, discount_amount: $discount_amount, id: $id, invoice: $invoice, items: $items, number: $number, sub_total_amount: $sub_total_amount, tax_amount: $tax_amount, total_amount: $total_amount, user: $user, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a payment link
#
# POST /api/paymentlink/new
# Returns: int
# operationId: PaymentLinkApi_New
export def "payment-link-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --access-token: string
  --client: record # shape: {Address?: string, ClientCountryId?: int, ClientCurrencyId?: int, CompanyRegistrationNumber?: string, DefaultDueDateInDays?: int, Email?: string, Id?: int, Name?: string, PhoneNumber?: string, UiLanguageId?: int, UserId?: int, Vat?: string}
  --client-id: int # format: int32
  --currency: record # shape: {Code?: string, Id?: int, Name?: string, Symbol?: string, Value?: string}
  --currency-id: int # format: int32
  --discount-amount: float # format: double
  --id: int # format: int32
  --invoice: record # shape: {AccessToken?: string, Activities?: list, Attachments?: list, ClientId?: int, ClonedFromId?: int, CurrencyId?: int, DiscountAmount?: float, Duedate?: string, EnablePartialPayments?: bool, EstimationId?: int, Id?: int, InvoiceCategoryId?: int, IsDigitallySigned?: bool, IssuedOn?: string, Items?: list, Notes?: string, Number?: string, OrderId?: int, PaymentGateways?: list, PaymentLinkId?: int, Payments?: list, PoNumber?: string, RecurringProfileId?: int, ShouldSendReminders?: bool, ... (6 more fields)}
  --items: list # item shape: {Cost?: float, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, PaymentLinkId?: int, Quantity?: float, SubTotalAmount?: float, Tax?: record, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkType?: record, WorkTypeId?: int}
  --number: string
  --sub-total-amount: float # format: double
  --tax-amount: float # format: double
  --total-amount: float # format: double
  --user: record # shape: {ActionNotificationsLastReadOn?: string, Email?: string, ExternalConnections?: list, HasBeenOnboarded?: bool, Id?: int, IsLocked?: bool, IsVerified?: bool, KnowledgeNotificationsLastReadOn?: string, LastSeenOn?: string, Name?: string, Password?: string, PasswordSalt?: string, ReferralPath?: string, ReferredUsers?: int, ReferrerKey?: string, Settings?: record, Status?: "Normal"|"Fraudlent"|"Locked", SubscriptionPlan?: record, Type?: "Anonymous"|"Customer"|"SystemAdministrator"|"Collaborator", ... (3 more fields)}
  --user-id: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/paymentlink/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccessToken, var: access_token}, {name: Client, var: client}, {name: ClientId, var: client_id}, {name: Currency, var: currency}, {name: CurrencyId, var: currency_id}, {name: DiscountAmount, var: discount_amount}, {name: Id, var: id}, {name: Invoice, var: invoice}, {name: Items, var: items}, {name: Number, var: number}, {name: SubTotalAmount, var: sub_total_amount}, {name: TaxAmount, var: tax_amount}, {name: TotalAmount, var: total_amount}, {name: User, var: user}, {name: UserId, var: user_id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, access_token: $access_token, client: $client, client_id: $client_id, currency: $currency, currency_id: $currency_id, discount_amount: $discount_amount, id: $id, invoice: $invoice, items: $items, number: $number, sub_total_amount: $sub_total_amount, tax_amount: $tax_amount, total_amount: $total_amount, user: $user, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return the unique url to the client's payment link
#
# GET /api/paymentlink/uri
# Returns: record<Link: string>
# operationId: PaymentLinkApi_Uri
export def "payment-link-api-uri" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/paymentlink/uri"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all products for the account
#
# GET /api/product/all
# Returns: record<Count: int, ErrorMessages: table<Code: string, FaultMessage: string, Group: string, UserVisibleMessage: string>, IsFaulted: bool, Result: table<AccessToken: string, AfterPaymentDescription: string, ButtonCallToAction: string, Currency: record, CurrencyId: int, Description: string, Id: int, IsFeatured: bool, Name: string, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>, TotalCount: int>
# operationId: ProductApi_All
export def "product-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/product/all"
    query: [{name: "queryOptions.page", var: query_options_page}, {name: "queryOptions.pageSize", var: query_options_page_size}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    query_options_page: $query_options_page, query_options_page_size: $query_options_page_size, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing product
#
# POST /api/product/delete
# Returns: int
# operationId: ProductApi_Delete
export def "product-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of product to be deleted (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/product/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return product details
#
# GET /api/product/details
# Returns: record<AccessToken: string, AfterPaymentDescription: string, Attachments: table<Id: int, Link: string, ObfuscatedFileName: string, OriginalFileName: string, Size: int, Type: string>, ButtonCallToAction: string, Coupons: table<Code: string, DiscountAmount: float, DiscountPercentage: float, Id: int, ValidUntil: string>, Currency: record<Code: string, Id: int, Name: string, Symbol: string, Value: string>, CurrencyId: int, Description: string, Discounts: table<DiscountAmount: float, DiscountPercentage: float, Id: int, Name: string, ValidFrom: string, ValidTo: string>, Id: int, IsFeatured: bool, Items: table<Cost: float, Description: string, Id: int, MinimumQuantity: float, ReferenceId: string, SubTotalAmount: float, TaxAmount: float, TaxId: int, TaxPercentage: float, TotalAmount: float, WorkTypeId: int>, Name: string, PaymentGateways: table<Name: string>, ShippingAmount: float, ShippingDescription: string, Status: string, SubTotalAmount: float, TotalAmount: float, TotalWithShipping: float, WhatHappensNextDescription: string>
# operationId: ProductApi_Details
export def "product-api-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/product/details"
    query: [{name: id, var: id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    id: $id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a product
#
# POST /api/product/new
# Returns: int
# operationId: ProductApi_New
export def "product-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --after-payment-description: string # After payment description
  --attachments: list # List of product attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --button-call-to-action: string # Default button call to action Ex: Buy now, subscribe, ...
  --coupons: list # List of product coupons — item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
  --currency-id: int # Foreign key Currency (format: int32)
  --description: string # Product description
  --discounts: list # List of product discounts — item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
  --is-featured: oneof<nothing, bool> # Indicate that the product is set as featured
  --items: list # List of product items — item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --name: string # Product alias
  --payment-gateways: list # List of enabled payment gateways for this product — item shape: {Name?: string}
  --shipping-amount: float # Cost for shipping the product (format: double)
  --shipping-description: string # Client instructions for shipping
  --status: string@status-completer-3 # Product availability status
  --what-happens-next-description: string # What happens next description
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/product/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AfterPaymentDescription, var: after_payment_description}, {name: Attachments, var: attachments}, {name: ButtonCallToAction, var: button_call_to_action}, {name: Coupons, var: coupons}, {name: CurrencyId, var: currency_id}, {name: Description, var: description}, {name: Discounts, var: discounts}, {name: IsFeatured, var: is_featured}, {name: Items, var: items}, {name: Name, var: name}, {name: PaymentGateways, var: payment_gateways}, {name: ShippingAmount, var: shipping_amount}, {name: ShippingDescription, var: shipping_description}, {name: Status, var: status}, {name: WhatHappensNextDescription, var: what_happens_next_description}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, after_payment_description: $after_payment_description, attachments: $attachments, button_call_to_action: $button_call_to_action, coupons: $coupons, currency_id: $currency_id, description: $description, discounts: $discounts, is_featured: $is_featured, items: $items, name: $name, payment_gateways: $payment_gateways, shipping_amount: $shipping_amount, shipping_description: $shipping_description, status: $status, what_happens_next_description: $what_happens_next_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing product
#
# POST /api/product/update
# operationId: ProductApi_Update
export def "product-api-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --after-payment-description: string # After payment description
  --attachments: list # List of product attachments — item shape: {Id?: int, Link?: string, ObfuscatedFileName?: string, OriginalFileName?: string, Size?: int, Type?: "External"|"Uploaded"}
  --button-call-to-action: string # Default button call to action Ex: Buy now, subscribe, ...
  --coupons: list # List of product coupons — item shape: {Code?: string, DiscountAmount?: float, DiscountPercentage?: float, Id?: int, ValidUntil?: string}
  --currency-id: int # Foreign key Currency (format: int32)
  --description: string # Product description
  --discounts: list # List of product discounts — item shape: {DiscountAmount?: float, DiscountPercentage?: float, Id?: int, Name?: string, ValidFrom?: string, ValidTo?: string}
  --id: int # Product id (format: int32)
  --is-featured: oneof<nothing, bool> # Indicate that the product is set as featured
  --items: list # List of product items — item shape: {Cost?: float, Description?: string, Id?: int, MinimumQuantity?: float, ReferenceId?: string, SubTotalAmount?: float, TaxAmount?: float, TaxId?: int, TaxPercentage?: float, TotalAmount?: float, WorkTypeId?: int}
  --name: string # Product alias
  --payment-gateways: list # List of enabled payment gateways for this product — item shape: {Name?: string}
  --shipping-amount: float # Cost for shipping the product (format: double)
  --shipping-description: string # Client instructions for shipping
  --status: string@status-completer-3 # Product availability status
  --what-happens-next-description: string # What happens next description
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/product/update"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AfterPaymentDescription, var: after_payment_description}, {name: Attachments, var: attachments}, {name: ButtonCallToAction, var: button_call_to_action}, {name: Coupons, var: coupons}, {name: CurrencyId, var: currency_id}, {name: Description, var: description}, {name: Discounts, var: discounts}, {name: Id, var: id}, {name: IsFeatured, var: is_featured}, {name: Items, var: items}, {name: Name, var: name}, {name: PaymentGateways, var: payment_gateways}, {name: ShippingAmount, var: shipping_amount}, {name: ShippingDescription, var: shipping_description}, {name: Status, var: status}, {name: WhatHappensNextDescription, var: what_happens_next_description}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, after_payment_description: $after_payment_description, attachments: $attachments, button_call_to_action: $button_call_to_action, coupons: $coupons, currency_id: $currency_id, description: $description, discounts: $discounts, id: $id, is_featured: $is_featured, items: $items, name: $name, payment_gateways: $payment_gateways, shipping_amount: $shipping_amount, shipping_description: $shipping_description, status: $status, what_happens_next_description: $what_happens_next_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all taxes for the account
#
# GET /api/tax/all
# Returns: table<CreatedOn: string, Id: int, Name: string, Percentage: float>
# operationId: TaxApi_All
export def "tax-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/tax/all"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing tax
#
# POST /api/tax/delete
# Returns: int
# operationId: TaxApi_Delete
export def "tax-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of tax to be deleted (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/tax/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a tax
#
# POST /api/tax/new
# Returns: int
# operationId: TaxApi_New
export def "tax-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --name: string # Name of the task
  --percentage: float # Task percentage. Ex: 18% (format: double)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/tax/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Percentage, var: percentage}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, name: $name, percentage: $percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing tax
#
# POST /api/tax/update
# operationId: TaxApi_Update
export def "tax-api-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Entity id (format: int32)
  --name: string # Name of the task
  --percentage: float # Task percentage. Ex: 18% (format: double)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/tax/update"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: Percentage, var: percentage}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id, name: $name, percentage: $percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all work types for the account
#
# GET /api/worktype/all
# Returns: table<CreatedOn: string, Id: int, Title: string>
# operationId: WorkTypeApi_All
export def "work-type-api-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/worktype/all"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing work type
#
# POST /api/worktype/delete
# Returns: int
# operationId: WorkTypeApi_Delete
export def "work-type-api-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Id of work type to be deleted (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/worktype/delete"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return work type details
#
# GET /api/worktype/details
# Returns: record<CreatedOn: string, Id: int, Title: string>
# operationId: WorkTypeApi_Details
export def "work-type-api-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --work-type-id: int # required, format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/worktype/details"
    query: [{name: workTypeId, var: work_type_id, required: true}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    work_type_id: $work_type_id, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a work type
#
# POST /api/worktype/new
# Returns: int
# operationId: WorkTypeApi_New
export def "work-type-api-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --title: string # Indicates the title of of the work type (Logo design, development...)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/worktype/new"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Title, var: title}]}
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return all work types for the account that match the query param
#
# GET /api/worktype/search
# Returns: table<CreatedOn: string, Id: int, Title: string>
# operationId: WorkTypeApi_Search
export def "work-type-api-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-options-query: string
  --query-options-order-by: string
  --query-options-order: string@query-options-order-completer
  --query-options-page: int # format: int32
  --query-options-page-size: int # format: int32
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/worktype/search"
    query: [{name: "queryOptions.query", var: query_options_query}, {name: "queryOptions.orderBy", var: query_options_order_by}, {name: "queryOptions.order", var: query_options_order}, {name: "queryOptions.page", var: query_options_page}, {name: "queryOptions.pageSize", var: query_options_page_size}]
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    accept: ["application/json", "application/xml", "text/html", "text/json", "text/xml"]
    ok: [200]
    auth: x-auth-key
  } {
    query_options_query: $query_options_query, query_options_order_by: $query_options_order_by, query_options_order: $query_options_order, query_options_page: $query_options_page, query_options_page_size: $query_options_page_size, x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing work type
#
# POST /api/worktype/update
# operationId: WorkTypeApi_Update
export def "work-type-api-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-key: string # required, default: [authentication key]
  --x-auth-secret: string # required, default: [authentication secret]
  --id: int # Entity id (format: int32)
  --title: string # Indicates the title of of the work type (Logo design, development...)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/worktype/update"
    header: [{name: x-auth-key, var: x_auth_key, required: true, default: "[authentication key]"}, {name: x-auth-secret, var: x_auth_secret, required: true, default: "[authentication secret]"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-key
  } {
    x_auth_key: $x_auth_key, x_auth_secret: $x_auth_secret, id: $id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
