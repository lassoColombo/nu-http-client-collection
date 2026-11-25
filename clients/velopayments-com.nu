# Auto-generated client for Velo Payments APIs v2.34.63
# Source: https://api.apis.guru/v2/specs/velopayments.com/2.34.63/openapi.json
# Auth: --token flag or $env.VELO_PAYMENTS_APIS_TOKEN

const CLIENT = {
  base_url: "https://api.sandbox.velopayments.com"
  token_env_var: "VELO_PAYMENTS_APIS_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://api.sandbox.velopayments.com" "https://api.payouts.velopayments.com"] }
def auth-scheme-completer [] { ["bearer" "basic" "none" "basic-credentials"] }

# Completers for enum parameters
def link-type-completer [] { ["PARENT_OF"] }
def type-completer [] { ["FBO" "PRIVATE" "WUBS_DECOUPLED"] }
def type-completer-1 [] { ["BACKOFFICE" "PAYEE" "PAYOR"] }
def status-completer [] { ["DISABLED" "ENABLED" "PENDING"] }
def payee-type-completer [] { ["COMPANY" "INDIVIDUAL"] }
def mfa-type-completer [] { ["SMS" "TOTP" "YUBIKEY"] }
def user-type-completer [] { ["BACKOFFICE" "PAYEE" "PAYOR"] }
def mfa-type-completer-1 [] { ["TOTP" "YUBIKEY"] }
def token-type-completer [] { ["INVITE_MFA_USER" "MFA_REGISTRATION"] }
def payee-type-completer-1 [] { ["Company" "Individual"] }
def status-completer-1 [] { ["ACCEPTED" "ACCEPTED_BY_RAILS" "AWAITING_FUNDS" "BANK_PAYMENT_REQUESTED" "CONFIRMED" "FAILED" "FUNDED" "REJECTED" "RETURNED" "UNFUNDED" "WITHDRAWN"] }
def status-completer-2 [] { ["ACCEPTED" "COMPLETED" "CONFIRMED" "INCOMPLETE" "INSTRUCTED" "QUOTED" "REJECTED" "SUBMITTED" "WITHDRAWN"] }
def status-completer-3 [] { ["ACCEPTED" "REJECTED" "WITHDRAWABLE" "WITHDRAWN"] }
def transmission-type-completer [] { ["ACH" "SAME_DAY_ACH" "WIRE"] }
def transmission-type-completer-1 [] { ["ACH" "GACHO" "LOCAL" "SAME_DAY_ACH" "WIRE"] }
def schedule-status-completer [] { ["ANY" "EXECUTED" "FAILED" "SCHEDULED"] }
def post-instruct-fx-status-completer [] { ["ANY" "CANCELLED" "COMPLETED" "EXECUTED" "INITIATED" "REFUNDED" "RESUBMITTED" "RETURNED"] }
def include-completer [] { ["payorAndDescendants" "payorOnly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    velo-auth: "record<access_token: string, entityIds: list<string>, expires_in: float, refresh_token: string, scope: string, token_type: string>"
    list-funding-audit-deltas: "record<content: table<amount: int, currency: string, fundingId: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    list-payment-changes: "record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-funding-by-id-v1: "record<allocationDate: string, allocationType: string, amount: int, currency: string, detectedFundingRef: string, fundingAccountType: string, fundingId: string, hiddenDate: string, payorId: string, physicalAccountName: string, reason: string, sourceAccountId: string, status: string, text: string>"
    list-payment-channel-rules-v1: "record<bank: table<isoCountryCode: string, rules: list>>"
    get-fundings-v1: "record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payout-stats-v1: "record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int>"
    payor-links-v1: "record<links: table<fromPayorId: string, linkId: string, linkType: string, toPayorId: string>, payors: table<kycState: string, payorId: string, payorName: string, primaryContactEmail: string>>"
    get-payor-by-id-v1: "record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, fundingAccountAccountName: string, fundingAccountAccountNumber: string, fundingAccountRoutingNumber: string, includesReports: bool, kycState: string, language: string, manualLockout: bool, maxMasterPayorAdmins: int, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, payorId: string, payorName: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, reminderEmailsOptOut: bool, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>>"
    payor-create-api-key-v1: "record<apiKey: string, apiSecret: string>"
    payor-get-branding: "record<collectiveAlias: string, dbaName: string, logoUrl: string, payorName: string, supportContact: string>"
    list-supported-countries-v1: "record<countries: table<currencies: list, isoCountryCode: string>>"
    validate-access-token: "record<access_token: string, entityIds: list<string>, expires_in: int, refresh_token: string, scope: string, token_type: string, user_info: record<mfa_details: record<mfa_type: string, verified: bool>, userType: string, user_id: string>>"
    list-webhooks-v1: "record<content: table<authorizationHeader: string, categories: list, enabled: bool, id: string, payorId: string, webhookUrl: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-webhook-v1: "record<authorizationHeader: string, categories: list<string>, enabled: bool, id: string, payorId: string, webhookUrl: string>"
    ping-webhook-v1: "record<id: string, webhookId: string>"
    list-supported-currencies-v2: "record<currencies: table<currency: string, maxPaymentAmount: int>>"
    get-funding-accounts-v2: "record<content: table<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-funding-account-v2: "record<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string>"
    get-payor-by-id-v2: "record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, includesReports: bool, kycState: string, language: string, managingPayees: bool, manualLockout: bool, maxMasterPayorAdmins: int, openBankingEnabled: bool, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, paymentRails: string, payorId: string, payorName: string, payorXid: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, provider: string, reminderEmailsOptOut: bool, remoteSystemIds: list<string>, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>, usdTxnValueReportingThreshold: int, wuCustomerId: string>"
    get-source-accounts-v2: "record<content: table<accountType: string, autoTopUpConfig: record, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-source-account-v2: "record<accountType: string, autoTopUpConfig: record<enabled: bool, minBalance: int, targetBalance: int>, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string>"
    list-supported-countries-v2: "record<countries: table<currencies: list, isoCountryCode: string, regions: list>>"
    list-users: "record<content: table<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: list, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-self: "record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>"
    validate-password-self: "record<score: int, suggestions: list<string>, valid: bool, warning: string>"
    get-user-by-id-v2: "record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>"
    list-payees-v3: "record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>>"
    create-payee-v3: "record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>>"
    query-batch-status-v3: "record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string>"
    list-payee-changes-v3: "record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payees-invitation-status-v3: "record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payee-by-id-v3: "record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>"
    list-payments-audit-v3: "record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payment-details-v3: "record<accountName: string, accountNumber: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>"
    get-payouts-for-payor-v3: "record<content: table<fxSummaries: list, instructedDateTime: string, payorId: string, payoutId: string, payoutMemo: string, sourceAccountSummary: list, status: string, submittedDateTime: string, totalFailedPayments: int, totalIncompletePayments: int, totalPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payments-for-payout-pa-v3: "record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, failedPayments: int, incompletePayments: int, instructedDateTime: string, payoutMemo: string, payoutStatus: string, releasedPayments: int, submittedDateTime: string, totalPayments: int, withdrawnDateTime: string>>"
    export-transactions-csvv3: "record<credit: int, creditCurrency: string, dateFundingRequested: string, debit: int, debitCurrency: string, fundingType: string, fxApplied: float, payeeType: string, paymentAmount: int, paymentCurrency: string, paymentMemo: string, paymentRails: string, paymentStatus: string, payorPaymentId: string, rejectReason: string, remoteId: string, reportTransactionType: string, returnCode: string, returnDescription: string, returnFee: string, returnFeeCurrency: string, returnFeeDescription: string, sourceAccount: string, transactionDate: string, transactionTime: string>"
    get-payout-summary-v3: "record<acceptedPayments: table<amount: int, currencyType: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, accounts: table<currency: string, sourceAccountId: string, sourceAccountName: string, totalPayoutCost: int>, fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>, paymentsAccepted: int, paymentsRejected: int, paymentsSubmitted: int, paymentsWithdrawn: int, payoutId: string, rejectedPayments: table<amount: int, currencyType: string, lineNumber: int, message: string, paymentMetadata: string, payorPaymentId: string, reason: string, reasonCode: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledByPrincipalId: string, scheduledFor: string>, status: string>"
    get-payments-for-payout-v3: "record<content: table<amount: int, autoWithdrawnReasonCode: string, currency: string, payee: record, paymentId: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string, status: string, transmissionType: string, withdrawable: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    create-quote-for-payout-v3: "record<fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>>"
    get-source-accounts-v3: "record<content: table<autoTopUpConfig: record, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-source-account-v3: "record<autoTopUpConfig: record<enabled: bool, fundingAccountId: string, minBalance: int, targetBalance: int>, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool>"
    list-payees-v4: "record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>>"
    v4-create-payee: "record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>>"
    query-batch-status-v4: "record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string>"
    list-payee-changes-v4: "record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payees-invitation-status-v4: "record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payee-by-id-v4: "record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>"
    get-fundings-v4: "record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    list-payments-audit-v4: "record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payment-details-v4: "record<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, scheduledAt: string, scheduledBy: string, scheduledFor: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record<payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutId: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>>, postInstructFxInfo: record<fxMode: string, fxStatus: string, fxStatusUpdatedAt: string, fxTransactionReference: string>, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>"
    get-payout-stats-v4: "record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int>"
    get-payouts-for-payor-v4: "record<content: table<dateTime: string, fxSummaries: list, instructedDateTime: string, payorId: string, payorName: string, payoutId: string, payoutMemo: string, payoutType: string, schedule: record, sourceAccountSummary: list, status: string, submittedDateTime: string, totalIncompletePayments: int, totalPayments: int, totalReturnedPayments: int, totalWithdrawnPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
    get-payments-for-payout-v4: "record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, incompletePayments: int, instructed: record<principal: string, principalId: string>, instructedDateTime: string, payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutMemo: string, payoutStatus: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutType: string, quoted: record<principal: string, principalId: string>, quotedDateTime: string, releasedPayments: int, returnedPayments: int, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, submittedDateTime: string, submitting: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, totalPayments: int, withdrawn: record<principal: string, principalId: string>, withdrawnDateTime: string, withdrawnPayments: int>>"
    export-transactions-csvv4: "record<credit: int, creditCurrency: string, dateFundingRequested: string, debit: int, debitCurrency: string, fundingType: string, fxApplied: float, payeeEmail: string, payeeName: string, payeeType: string, paymentAmount: int, paymentCurrency: string, paymentMemo: string, paymentRails: string, paymentStatus: string, payorPaymentId: string, rejectReason: string, remoteId: string, reportTransactionType: string, returnCode: string, returnDescription: string, returnFee: string, returnFeeCurrency: string, returnFeeDescription: string, sourceAccount: string, transactionDate: string, transactionTime: string>"
    list-payment-changes-v4: "record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["velo-auth" "list-funding-audit-deltas" "list-payment-changes" "get-funding-by-id-v1" "logout" "reset-password" "list-payment-channel-rules-v1" "get-fundings-v1" "get-payout-stats-v1" "withdraw-payment" "payor-links-v1" "create-payor-links" "get-payor-by-id-v1" "payor-create-application-v1" "payor-create-api-key-v1" "payor-get-branding" "payor-add-payor-logo-v1" "payor-email-opt-out" "set-notifications-request" "list-supported-countries-v1" "validate-access-token" "list-webhooks-v1" "create-webhook-v1" "get-webhook-v1" "update-webhook-v1" "ping-webhook-v1" "list-supported-currencies-v2" "get-funding-accounts-v2" "create-funding-account-v2" "get-funding-account-v2" "get-payor-by-id-v2" "get-source-accounts-v2" "get-source-account-v2" "create-funding-request-v2" "transfer-funds-v2" "list-supported-countries-v2" "list-users" "invite-user" "register-sms" "get-self" "unregister-mfa-for-self" "update-password-self" "validate-password-self" "user-details-update-for-self" "delete-user-by-id-v2" "get-user-by-id-v2" "disable-user-v2" "enable-user-v2" "unregister-mfa" "role-update" "resend-token" "unlock-user-v2" "user-details-update" "list-payees-v3" "create-payee-v3" "query-batch-status-v3" "list-payee-changes-v3" "get-payees-invitation-status-v3" "delete-payee-by-id-v3" "get-payee-by-id-v3" "resend-payee-invite-v3" "payee-details-update-v3" "post-v3-payees-payee-id-remote-id-update" "list-payments-audit-v3" "get-payment-details-v3" "get-payouts-for-payor-v3" "get-payments-for-payout-pa-v3" "export-transactions-csvv3" "submit-payout-v3" "withdraw-payout-v3" "get-payout-summary-v3" "instruct-payout-v3" "get-payments-for-payout-v3" "create-quote-for-payout-v3" "deschedule-payout" "schedule-for-payout" "get-source-accounts-v3" "delete-source-account-v3" "get-source-account-v3" "create-funding-request-v3" "set-notifications-request-v3" "transfer-funds-v3" "list-payees-v4" "v4-create-payee" "query-batch-status-v4" "list-payee-changes-v4" "get-payees-invitation-status-v4" "delete-payee-by-id-v4" "get-payee-by-id-v4" "resend-payee-invite-v4" "payee-details-update-v4" "post-v4-payees-payee-id-remote-id-update" "get-fundings-v4" "list-payments-audit-v4" "get-payment-details-v4" "get-payout-stats-v4" "get-payouts-for-payor-v4" "get-payments-for-payout-v4" "export-transactions-csvv4" "list-payment-changes-v4" "commands"] | sort) } | get name | first)
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

# Authentication endpoint
#
# POST /v1/authenticate
# Returns: record<access_token: string, entityIds: list<string>, expires_in: float, refresh_token: string, scope: string, token_type: string>
# operationId: veloAuth
export def "velo-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --grant-type: string # OAuth grant type. Should use 'client_credentials' (default: client_credentials)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/authenticate"
    query: [{name: grant_type, var: grant_type}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    grant_type: $grant_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Funding Audit Delta
#
# GET /v1/deltas/fundings
# Returns: record<content: table<amount: int, currency: string, fundingId: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listFundingAuditDeltas
export def "list-funding-audit-deltas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # required, format: uuid
  --updated-since: string # required, format: date-time
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/deltas/fundings"
    query: [{name: payorId, var: payor_id, required: true}, {name: updatedSince, var: updated_since, required: true}, {name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, updated_since: $updated_since, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V1 List Payment Changes
#
# GET /v1/deltas/payments
# DEPRECATED
# Returns: record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listPaymentChanges
@deprecated
export def "list-payment-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payments (required, format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (required, format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/deltas/payments"
    query: [{name: payorId, var: payor_id, required: true}, {name: updatedSince, var: updated_since, required: true}, {name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, updated_since: $updated_since, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Funding
#
# GET /v1/fundings/{fundingId}
# Returns: record<allocationDate: string, allocationType: string, amount: int, currency: string, detectedFundingRef: string, fundingAccountType: string, fundingId: string, hiddenDate: string, payorId: string, physicalAccountName: string, reason: string, sourceAccountId: string, status: string, text: string>
# operationId: getFundingByIdV1
export def "get-funding-by-id-v1" [
  funding_id: string
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
    path: "/v1/fundings/{fundingId}"
    path_params: [{name: fundingId, var: funding_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    funding_id: $funding_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logout
#
# POST /v1/logout
# operationId: logout
export def "logout" [
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
    path: "/v1/logout"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset password
#
# POST /v1/password/reset
# operationId: resetPassword
export def "reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # the email address of the user requesting the reset password (format: email, e.g. foo@example.com)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/password/reset"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payment Channel Country Rules
#
# GET /v1/paymentChannelRules
# Returns: record<bank: table<isoCountryCode: string, rules: list>>
# operationId: listPaymentChannelRulesV1
export def "list-payment-channel-rules-v1" [
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
    path: "/v1/paymentChannelRules"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V1 Get Fundings for Payor
#
# GET /v1/paymentaudit/fundings
# DEPRECATED
# Returns: record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getFundingsV1
@deprecated
export def "get-fundings-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (required, format: uuid)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields. Example: ```?sort=destinationCurrency:asc,destinationAmount:asc``` Default is no sort. The supported sort fields are: dateTime and amount.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/paymentaudit/fundings"
    query: [{name: payorId, var: payor_id, required: true}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V1 Get Payout Statistics
#
# GET /v1/paymentaudit/payoutStatistics
# DEPRECATED
# Returns: record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int>
# operationId: getPayoutStatsV1
@deprecated
export def "get-payout-stats-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID. Required for external users. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/paymentaudit/payoutStatistics"
    query: [{name: payorId, var: payor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Withdraw a Payment
#
# POST /v1/payments/{paymentId}/withdraw
# operationId: withdrawPayment
export def "withdraw-payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # Reason for withdrawal (e.g. Payment submitted in error)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/payments/{paymentId}/withdraw"
    path_params: [{name: paymentId, var: payment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payment_id: $payment_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payor Links
#
# GET /v1/payorLinks
# Returns: record<links: table<fromPayorId: string, linkId: string, linkType: string, toPayorId: string>, payors: table<kycState: string, payorId: string, payorName: string, primaryContactEmail: string>>
# operationId: payorLinksV1
export def "payor-links-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --descendants-of-payor: string # The Payor ID from which to start the query to show all descendants (format: uuid)
  --parent-of-payor: string # Query for the parent payor details for this payor id (format: uuid)
  --fields: string # List of additional Payor fields to include in the response for each Payor The values of payorId and payorName are always included for each Payor by default You can add fields to the response for each payor by including them in the fields parameter separated by commas The supported fields are any combination of: primaryContactEmail,kycState
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/payorLinks"
    query: [{name: descendantsOfPayor, var: descendants_of_payor}, {name: parentOfPayor, var: parent_of_payor}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    descendants_of_payor: $descendants_of_payor, parent_of_payor: $parent_of_payor, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Payor Link
#
# POST /v1/payorLinks
# operationId: createPayorLinks
export def "create-payor-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  from_payor_id: string # format: uuid
  link_type: string@link-type-completer
  to_payor_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/payorLinks"
    body: {content_type: "application/json", kind: json, fields: [{name: fromPayorId, var: from_payor_id}, {name: linkType, var: link_type}, {name: toPayorId, var: to_payor_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    from_payor_id: $from_payor_id, link_type: $link_type, to_payor_id: $to_payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payor
#
# GET /v1/payors/{payorId}
# DEPRECATED
# Returns: record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, fundingAccountAccountName: string, fundingAccountAccountNumber: string, fundingAccountRoutingNumber: string, includesReports: bool, kycState: string, language: string, manualLockout: bool, maxMasterPayorAdmins: int, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, payorId: string, payorName: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, reminderEmailsOptOut: bool, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>>
# operationId: getPayorByIdV1
@deprecated
export def "get-payor-by-id-v1" [
  payor_id: string
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
    path: "/v1/payors/{payorId}"
    path_params: [{name: payorId, var: payor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Application
#
# POST /v1/payors/{payorId}/applications
# operationId: payorCreateApplicationV1
export def "payor-create-application-v1" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the application. (nullable, e.g. SAP Application integration)
  name: string # The name of the application. (e.g. SAP)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/payors/{payorId}/applications"
    path_params: [{name: payorId, var: payor_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    payor_id: $payor_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create API Key
#
# POST /v1/payors/{payorId}/applications/{applicationId}/keys
# Returns: record<apiKey: string, apiSecret: string>
# operationId: payorCreateApiKeyV1
export def "payor-create-api-key-v1" [
  payor_id: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the key. (nullable, e.g. Key for iOS mobile application)
  name: string # A name for the key. (e.g. iOS Key)
  roles: list<string> # A role to assign to the key. If you want your API key to have write access then assign the role velo.payor.admin A later version will change this property from a list to string (e.g. [velo.payor.admin])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/payors/{payorId}/applications/{applicationId}/keys"
    path_params: [{name: payorId, var: payor_id}, {name: applicationId, var: application_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, application_id: $application_id, description: $description, name: $name, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Branding
#
# GET /v1/payors/{payorId}/branding
# Returns: record<collectiveAlias: string, dbaName: string, logoUrl: string, payorName: string, supportContact: string>
# operationId: payorGetBranding
export def "payor-get-branding" [
  payor_id: string
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
    path: "/v1/payors/{payorId}/branding"
    path_params: [{name: payorId, var: payor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Logo
#
# POST /v1/payors/{payorId}/branding/logos
# operationId: payorAddPayorLogoV1
export def "payor-add-payor-logo-v1" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/payors/{payorId}/branding/logos"
    path_params: [{name: payorId, var: payor_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: logo, var: logo}], files: [logo]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payor_id: $payor_id, logo: $logo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reminder Email Opt-Out
#
# POST /v1/payors/{payorId}/reminderEmailsUpdate
# operationId: payorEmailOptOut
export def "payor-email-opt-out" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reminder-emails-opt-out: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/payors/{payorId}/reminderEmailsUpdate"
    path_params: [{name: payorId, var: payor_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reminderEmailsOptOut, var: reminder_emails_opt_out, required: true}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    payor_id: $payor_id, reminder_emails_opt_out: $reminder_emails_opt_out
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set notifications
#
# POST /v1/sourceAccounts/{sourceAccountId}/notifications
# DEPRECATED
# operationId: setNotificationsRequest
@deprecated
export def "set-notifications-request" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  minimum_balance: int # Amount to set as minimum balance in minor units (format: int64)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/sourceAccounts/{sourceAccountId}/notifications"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: minimumBalance, var: minimum_balance}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_account_id: $source_account_id, minimum_balance: $minimum_balance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Supported Countries
#
# GET /v1/supportedCountries
# DEPRECATED
# Returns: record<countries: table<currencies: list, isoCountryCode: string>>
# operationId: listSupportedCountriesV1
@deprecated
export def "list-supported-countries-v1" [
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
    path: "/v1/supportedCountries"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# validate
#
# POST /v1/validate
# Returns: record<access_token: string, entityIds: list<string>, expires_in: int, refresh_token: string, scope: string, token_type: string, user_info: record<mfa_details: record<mfa_type: string, verified: bool>, userType: string, user_id: string>>
# operationId: validateAccessToken
export def "validate-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer token authorization leg of validate
  otp: string # an OTP either sent via sms or generated by a registered MFA device (e.g. 123456)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/validate"
    header: [{name: Authorization, var: authorization}]
    body: {content_type: "application/json", kind: json, fields: [{name: otp, var: otp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, otp: $otp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the details about the webhooks for the given payor.
#
# GET /v1/webhooks
# Returns: record<content: table<authorizationHeader: string, categories: list, enabled: bool, id: string, payorId: string, webhookUrl: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listWebhooksV1
export def "list-webhooks-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --payor-id: string # The Payor ID (required, format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/webhooks"
    query: [{name: page, var: page}, {name: pageSize, var: page_size}, {name: payorId, var: payor_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Webhook
#
# POST /v1/webhooks
# operationId: createWebhookV1
export def "create-webhook-v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-header: string # the authorization header to include with the notification.
  --categories: list<string> # the categories to enable.
  --enabled: oneof<nothing, bool> # whether the webhook is enabled.
  payor_id: string # format: uuid
  webhook_url: string # the webhook URL to use.
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: authorizationHeader, var: authorization_header}, {name: categories, var: categories}, {name: enabled, var: enabled, required: true}, {name: payorId, var: payor_id}, {name: webhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization_header: $authorization_header, categories: $categories, enabled: $enabled, payor_id: $payor_id, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about the given webhook.
#
# GET /v1/webhooks/{webhookId}
# Returns: record<authorizationHeader: string, categories: list<string>, enabled: bool, id: string, payorId: string, webhookUrl: string>
# operationId: getWebhookV1
export def "get-webhook-v1" [
  webhook_id: string
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
    path: "/v1/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Webhook
#
# POST /v1/webhooks/{webhookId}
# operationId: updateWebhookV1
export def "update-webhook-v1" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-header: string # the authorization header to include with the notification. (nullable)
  --categories: list<string> # The notification categories to enable. (nullable)
  --enabled: oneof<nothing, bool> # whether the webhook is enabled.
  --webhook-url: string # the webhook URL to use.
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizationHeader, var: authorization_header}, {name: categories, var: categories}, {name: enabled, var: enabled}, {name: webhookUrl, var: webhook_url}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webhook_id: $webhook_id, authorization_header: $authorization_header, categories: $categories, enabled: $enabled, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/webhooks/{webhookId}/ping
#
# Returns: record<id: string, webhookId: string>
# operationId: pingWebhookV1
export def "ping-webhook-v1" [
  webhook_id: string
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
    path: "/v1/webhooks/{webhookId}/ping"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Supported Currencies
#
# GET /v2/currencies
# Returns: record<currencies: table<currency: string, maxPaymentAmount: int>>
# operationId: listSupportedCurrenciesV2
export def "list-supported-currencies-v2" [
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
    path: "/v2/currencies"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Funding Accounts
#
# GET /v2/fundingAccounts
# Returns: record<content: table<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getFundingAccountsV2
export def "get-funding-accounts-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # format: uuid
  --name: string # The descriptive funding account name
  --country: string # The 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --currency: string # The ISO 4217 currency code (e.g. USD)
  --type: string # The type of funding account. (e.g. FBO)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=accountName:asc,name:asc) Default is accountName:asc The supported sort fields are - accountName, name. (default: accountName:asc)
  --sensitive: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/fundingAccounts"
    query: [{name: payorId, var: payor_id}, {name: name, var: name}, {name: country, var: country}, {name: currency, var: currency}, {name: type, var: type}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}, {name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, name: $name, country: $country, currency: $currency, type: $type, page: $page, page_size: $page_size, sort: $sort, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Funding Account
#
# POST /v2/fundingAccounts
# operationId: createFundingAccountV2
export def "create-funding-account-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Required if type is either FBO or PRIVATE
  --account-number: string # Required if type is either FBO or PRIVATE
  --currency: string # ISO 4217 currency code, Required if type is either WUBS_DECOUPLED or PRIVATE (e.g. USD)
  name: string
  payor_id: string # format: uuid
  --routing-number: string # Required if type is either FBO or PRIVATE
  type: string@type-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/fundingAccounts"
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: currency, var: currency}, {name: name, var: name}, {name: payorId, var: payor_id}, {name: routingNumber, var: routing_number}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    account_name: $account_name, account_number: $account_number, currency: $currency, name: $name, payor_id: $payor_id, routing_number: $routing_number, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Funding Account
#
# GET /v2/fundingAccounts/{fundingAccountId}
# Returns: record<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string>
# operationId: getFundingAccountV2
export def "get-funding-account-v2" [
  funding_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # default: false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/fundingAccounts/{fundingAccountId}"
    path_params: [{name: fundingAccountId, var: funding_account_id}]
    query: [{name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    funding_account_id: $funding_account_id, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payor
#
# GET /v2/payors/{payorId}
# Returns: record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, includesReports: bool, kycState: string, language: string, managingPayees: bool, manualLockout: bool, maxMasterPayorAdmins: int, openBankingEnabled: bool, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, paymentRails: string, payorId: string, payorName: string, payorXid: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, provider: string, reminderEmailsOptOut: bool, remoteSystemIds: list<string>, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>, usdTxnValueReportingThreshold: int, wuCustomerId: string>
# operationId: getPayorByIdV2
export def "get-payor-by-id-v2" [
  payor_id: string
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
    path: "/v2/payors/{payorId}"
    path_params: [{name: payorId, var: payor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of source accounts
#
# GET /v2/sourceAccounts
# DEPRECATED
# Returns: record<content: table<accountType: string, autoTopUpConfig: record, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getSourceAccountsV2
@deprecated
export def "get-source-accounts-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --physical-account-name: string # Physical Account Name
  --physical-account-id: string # The physical account ID (format: uuid)
  --payor-id: string # The account owner Payor ID (format: uuid)
  --funding-account-id: string # The funding account ID (format: uuid)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields e.g. ?sort=name:asc Default is name:asc The supported sort fields are - fundingRef, name, balance (default: fundingRef:asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/sourceAccounts"
    query: [{name: physicalAccountName, var: physical_account_name}, {name: physicalAccountId, var: physical_account_id}, {name: payorId, var: payor_id}, {name: fundingAccountId, var: funding_account_id}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    physical_account_name: $physical_account_name, physical_account_id: $physical_account_id, payor_id: $payor_id, funding_account_id: $funding_account_id, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Source Account
#
# GET /v2/sourceAccounts/{sourceAccountId}
# DEPRECATED
# Returns: record<accountType: string, autoTopUpConfig: record<enabled: bool, minBalance: int, targetBalance: int>, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string>
# operationId: getSourceAccountV2
@deprecated
export def "get-source-account-v2" [
  source_account_id: string
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
    path: "/v2/sourceAccounts/{sourceAccountId}"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_account_id: $source_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Funding Request
#
# POST /v2/sourceAccounts/{sourceAccountId}/fundingRequest
# DEPRECATED
# operationId: createFundingRequestV2
@deprecated
export def "create-funding-request-v2" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to fund, decimal implied (format: int64)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/sourceAccounts/{sourceAccountId}/fundingRequest"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    source_account_id: $source_account_id, amount: $amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer Funds between source accounts
#
# POST /v2/sourceAccounts/{sourceAccountId}/transfers
# DEPRECATED
# operationId: transferFundsV2
@deprecated
export def "transfer-funds-v2" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to transfer, in minor units (format: int64)
  currency: string # e.g. USD
  to_source_account_id: string # The 'to' source account id, which will be credited (format: uuid)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/sourceAccounts/{sourceAccountId}/transfers"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: currency, var: currency}, {name: toSourceAccountId, var: to_source_account_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_account_id: $source_account_id, amount: $amount, currency: $currency, to_source_account_id: $to_source_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Supported Countries
#
# GET /v2/supportedCountries
# Returns: record<countries: table<currencies: list, isoCountryCode: string, regions: list>>
# operationId: listSupportedCountriesV2
export def "list-supported-countries-v2" [
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
    path: "/v2/supportedCountries"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Users
#
# GET /v2/users
# Returns: record<content: table<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: list, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listUsers
export def "list-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The Type of the User. (e.g. PAYOR)
  --status: string@status-completer # The status of the User. (e.g. ENABLED)
  --entity-id: string # The entityId of the User. (format: uuid)
  --payee-type: string@payee-type-completer # The Type of the Payee entity. Either COMPANY or INDIVIDUAL. (e.g. COMPANY)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=email:asc,lastName:asc) Default is email:asc 'name' The supported sort fields are - email, lastNmae. (default: email:asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/users"
    query: [{name: type, var: type}, {name: status, var: status}, {name: entityId, var: entity_id}, {name: payeeType, var: payee_type}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, status: $status, entity_id: $entity_id, payee_type: $payee_type, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite a User
#
# POST /v2/users/invite
# operationId: inviteUser
export def "invite-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # the email address of the invited user (format: email, e.g. foo@example.com)
  --entity-id: string # The payorId or payeeId or null if the user is a backoffice admin (nullable, format: uuid, e.g. 7fffa261-ac68-49e6-b605-d24a444d9206)
  --first-name: string # e.g. John
  --last-name: string # e.g. Doe
  mfa_type: string@mfa-type-completer # The MFA type that the user will use The type may be conditional on the role(s) the user has (e.g. TOTP)
  primary_contact_number: string # The main contact number for the user (e.g. 11235555555)
  roles: list<string> # The role(s) for the user The role must exist The role can be a custom role or a system role but the invoker must have the permissions to assign the role System roles are: velo.backoffice.admin, velo.payor.master_admin, velo.payor.admin, velo.payor.support, velo.payee.admin, velo.payee.support (e.g. [velo.payor.admin])
  --secondary-contact-number: string # The secondary contact number for the user (nullable, e.g. 11235555550)
  sms_number: string # The phone number of a device that the user can receive sms messages on (e.g. 11235555555)
  --user-type: string@user-type-completer # Will default to PAYOR if not provided but entityId is provided (e.g. PAYEE)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/invite"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: entityId, var: entity_id}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: mfaType, var: mfa_type}, {name: primaryContactNumber, var: primary_contact_number}, {name: roles, var: roles}, {name: secondaryContactNumber, var: secondary_contact_number}, {name: smsNumber, var: sms_number}, {name: userType, var: user_type}, {name: verificationCode, var: verification_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, entity_id: $entity_id, first_name: $first_name, last_name: $last_name, mfa_type: $mfa_type, primary_contact_number: $primary_contact_number, roles: $roles, secondary_contact_number: $secondary_contact_number, sms_number: $sms_number, user_type: $user_type, verification_code: $verification_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register SMS Number
#
# POST /v2/users/registration/sms
# operationId: registerSms
export def "register-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  sms_number: string # The phone number of a device that the user can receive sms messages on (e.g. 11235555555)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/registration/sms"
    body: {content_type: "application/json", kind: json, fields: [{name: smsNumber, var: sms_number}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    sms_number: $sms_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Self
#
# GET /v2/users/self
# Returns: record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>
# operationId: getSelf
export def "get-self" [
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
    path: "/v2/users/self"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregister MFA for Self
#
# POST /v2/users/self/mfa/unregister
# operationId: unregisterMFAForSelf
export def "unregister-mfa-for-self" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer token authorization leg of validate
  mfa_type: string@mfa-type-completer # The type of the MFA device (e.g. TOTP)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/self/mfa/unregister"
    header: [{name: Authorization, var: authorization}]
    body: {content_type: "application/json", kind: json, fields: [{name: mfaType, var: mfa_type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    authorization: $authorization, mfa_type: $mfa_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Password for self
#
# POST /v2/users/self/password
# operationId: updatePasswordSelf
export def "update-password-self" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # The new password (e.g. My_new_password)
  old_password: string # The user's current password (e.g. My_current_password)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/self/password"
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate the proposed password
#
# POST /v2/users/self/password/validate
# Returns: record<score: int, suggestions: list<string>, valid: bool, warning: string>
# operationId: validatePasswordSelf
export def "validate-password-self" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # a password that passes validation (e.g. My_strong_password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/users/self/password/validate"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User Details for self
#
# POST /v2/users/self/userDetailsUpdate
# operationId: userDetailsUpdateForSelf
export def "user-details-update-for-self" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # the email address of the user (nullable, format: email, e.g. foo@example.com)
  --first-name: string # nullable, e.g. John
  --last-name: string # nullable, e.g. Doe
  --primary-contact-number: string # The main contact number for the user (nullable, e.g. 11235555555)
  --secondary-contact-number: string # The secondary contact number for the user (nullable, e.g. 11235555550)
  --sms-number: string # The phone number of a device that the user can receive sms messages on (nullable, e.g. 11235555555)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/self/userDetailsUpdate"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: primaryContactNumber, var: primary_contact_number}, {name: secondaryContactNumber, var: secondary_contact_number}, {name: smsNumber, var: sms_number}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, first_name: $first_name, last_name: $last_name, primary_contact_number: $primary_contact_number, secondary_contact_number: $secondary_contact_number, sms_number: $sms_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a User
#
# DELETE /v2/users/{userId}
# operationId: deleteUserByIdV2
export def "delete-user-by-id-v2" [
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
    path: "/v2/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User
#
# GET /v2/users/{userId}
# Returns: record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>
# operationId: getUserByIdV2
export def "get-user-by-id-v2" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a User
#
# POST /v2/users/{userId}/disable
# operationId: disableUserV2
export def "disable-user-v2" [
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
    method: post
    path: "/v2/users/{userId}/disable"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a User
#
# POST /v2/users/{userId}/enable
# operationId: enableUserV2
export def "enable-user-v2" [
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
    method: post
    path: "/v2/users/{userId}/enable"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregister MFA for the user
#
# POST /v2/users/{userId}/mfa/unregister
# operationId: unregisterMFA
export def "unregister-mfa" [
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
  mfa_type: string@mfa-type-completer-1 # The type of the MFA device (e.g. TOTP)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/{userId}/mfa/unregister"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mfaType, var: mfa_type}, {name: verificationCode, var: verification_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, mfa_type: $mfa_type, verification_code: $verification_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User Role
#
# POST /v2/users/{userId}/roleUpdate
# operationId: roleUpdate
export def "role-update" [
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
  roles: list<string> # The role(s) for the user The role must exist The role can be a custom role or a system role but the invoker must have the permissions to assign the role System roles are: backoffice.admin, payor.master_admin, payor.admin, payor.support (e.g. [payor.admin])
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/{userId}/roleUpdate"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: roles, var: roles}, {name: verificationCode, var: verification_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, roles: $roles, verification_code: $verification_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend a token
#
# POST /v2/users/{userId}/tokens
# operationId: resendToken
export def "resend-token" [
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
  token_type: string@token-type-completer # The type of the token to resend (e.g. INVITE_MFA_USER)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/{userId}/tokens"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tokenType, var: token_type}, {name: verificationCode, var: verification_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, token_type: $token_type, verification_code: $verification_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlock a User
#
# POST /v2/users/{userId}/unlock
# operationId: unlockUserV2
export def "unlock-user-v2" [
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
    method: post
    path: "/v2/users/{userId}/unlock"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User Details
#
# POST /v2/users/{userId}/userDetailsUpdate
# operationId: userDetailsUpdate
export def "user-details-update" [
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
  --email: string # the email address of the user (nullable, format: email, e.g. foo@example.com)
  --first-name: string # nullable, e.g. John
  --last-name: string # nullable, e.g. Doe
  --mfa-type: string@mfa-type-completer # The type of the MFA device (nullable, e.g. TOTP)
  --primary-contact-number: string # The main contact number for the user (nullable, e.g. 11235555555)
  --secondary-contact-number: string # The secondary contact number for the user (nullable, e.g. 11235555550)
  --sms-number: string # The phone number of a device that the user can receive sms messages on (nullable, e.g. 11235555555)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/users/{userId}/userDetailsUpdate"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: mfaType, var: mfa_type}, {name: primaryContactNumber, var: primary_contact_number}, {name: secondaryContactNumber, var: secondary_contact_number}, {name: smsNumber, var: sms_number}, {name: verificationCode, var: verification_code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, email: $email, first_name: $first_name, last_name: $last_name, mfa_type: $mfa_type, primary_contact_number: $primary_contact_number, secondary_contact_number: $secondary_contact_number, sms_number: $sms_number, verification_code: $verification_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payees
#
# GET /v3/payees
# DEPRECATED
# Returns: record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>>
# operationId: listPayeesV3
@deprecated
export def "list-payees-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (required, format: uuid)
  --watchlist-status: string # The watchlistStatus of the payees.
  --disabled: oneof<nothing, bool> # Payee disabled
  --onboarded-status: string # The onboarded status of the payees.
  --email: string # Email address (format: email, e.g. bob@example.com)
  --display-name: string # The display name of the payees. (e.g. Bob Smith)
  --remote-id: string # The remote id of the payees. (e.g. remoteId123)
  --payee-type: string # The onboarded status of the payees.
  --payee-country: string # The country of the payee - 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
  --sort: string # List of sort fields (e.g. ?sort=onboardedStatus:asc,name:asc) Default is name:asc 'name' is treated as company name for companies - last name + ',' + firstName for individuals The supported sort fields are - payeeId, displayName, payoutStatus, onboardedStatus. (default: displayName:asc, e.g. displayName:asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/payees"
    query: [{name: payorId, var: payor_id, required: true}, {name: watchlistStatus, var: watchlist_status}, {name: disabled, var: disabled}, {name: onboardedStatus, var: onboarded_status}, {name: email, var: email}, {name: displayName, var: display_name}, {name: remoteId, var: remote_id}, {name: payeeType, var: payee_type}, {name: payeeCountry, var: payee_country}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, watchlist_status: $watchlist_status, disabled: $disabled, onboarded_status: $onboarded_status, email: $email, display_name: $display_name, remote_id: $remote_id, payee_type: $payee_type, payee_country: $payee_country, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate Payee Creation
#
# POST /v3/payees
# DEPRECATED
# Returns: record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>>
# operationId: createPayeeV3
@deprecated
export def "create-payee-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payees: list # item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: string}
  payor_id: string # e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/payees"
    body: {content_type: "application/json", kind: json, fields: [{name: payees, var: payees}, {name: payorId, var: payor_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    payees: $payees, payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query Batch Status
#
# GET /v3/payees/batch/{batchId}
# DEPRECATED
# Returns: record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string>
# operationId: queryBatchStatusV3
@deprecated
export def "query-batch-status-v3" [
  batch_id: string
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
    path: "/v3/payees/batch/{batchId}"
    path_params: [{name: batchId, var: batch_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_id: $batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payee Changes
#
# GET /v3/payees/deltas
# DEPRECATED
# Returns: record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listPayeeChangesV3
@deprecated
export def "list-payee-changes-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payees (required, format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (required, format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 100. Max allowable is 1000. (format: int32, default: 100, e.g. 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/payees/deltas"
    query: [{name: payorId, var: payor_id, required: true}, {name: updatedSince, var: updated_since, required: true}, {name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, updated_since: $updated_since, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payee Invitation Status
#
# GET /v3/payees/payors/{payorId}/invitationStatus
# DEPRECATED
# Returns: record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getPayeesInvitationStatusV3
@deprecated
export def "get-payees-invitation-status-v3" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid, e.g. 2aa5d7e0-2ecb-403f-8494-1865ed0454e9)
  --invitation-status: string # The invitation status of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/payees/payors/{payorId}/invitationStatus"
    path_params: [{name: payorId, var: payor_id}]
    query: [{name: payeeId, var: payee_id}, {name: invitationStatus, var: invitation_status}, {name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, payee_id: $payee_id, invitation_status: $invitation_status, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Payee by Id
#
# DELETE /v3/payees/{payeeId}
# DEPRECATED
# operationId: deletePayeeByIdV3
@deprecated
export def "delete-payee-by-id-v3" [
  payee_id: string
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
    path: "/v3/payees/{payeeId}"
    path_params: [{name: payeeId, var: payee_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payee_id: $payee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payee by Id
#
# GET /v3/payees/{payeeId}
# DEPRECATED
# Returns: record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>
# operationId: getPayeeByIdV3
@deprecated
export def "get-payee-by-id-v3" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/payees/{payeeId}"
    path_params: [{name: payeeId, var: payee_id}]
    query: [{name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payee_id: $payee_id, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Payee Invite
#
# POST /v3/payees/{payeeId}/invite
# DEPRECATED
# operationId: resendPayeeInviteV3
@deprecated
export def "resend-payee-invite-v3" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/payees/{payeeId}/invite"
    path_params: [{name: payeeId, var: payee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: payorId, var: payor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payee_id: $payee_id, payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Payee Details
#
# POST /v3/payees/{payeeId}/payeeDetailsUpdate
# DEPRECATED
# operationId: payeeDetailsUpdateV3
@deprecated
export def "payee-details-update-v3" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # e.g. {city: Key West, country: US, countyOrProvince: FL, line1: 500 Duval St, line2: line2, line3: line3, line4: line4, zipOrPostcode: 33945} — shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
  --challenge: record # e.g. {description: challenge description, value: challenge test} — shape: {description: string, value: string}
  --company: record # nullable, e.g. {name: ABC Group Plc, operatingName: ABC Co, taxId: 123123123} — shape: {name: string, operatingName?: string, taxId?: string}
  --email: string # nullable, format: email, e.g. bob@example.com
  --individual: record # e.g. {dateOfBirth: 1985-01-01, name: {firstName: Bob, lastName: Smith, otherNames: A, title: Mr}, nationalIdentification: AB123456C} — shape: {name: any}
  --language: string # An IETF BCP 47 language code which has been configured for use within this Velo environment. See the /v1/supportedLanguages endpoint to list the available codes for an environment. (e.g. en-US)
  --payee-type: string@payee-type-completer-1 # The type of the payee
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/payees/{payeeId}/payeeDetailsUpdate"
    path_params: [{name: payeeId, var: payee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: challenge, var: challenge}, {name: company, var: company}, {name: email, var: email}, {name: individual, var: individual}, {name: language, var: language}, {name: payeeType, var: payee_type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payee_id: $payee_id, address: $address, challenge: $challenge, company: $company, email: $email, individual: $individual, language: $language, payee_type: $payee_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Payee Remote Id
#
# POST /v3/payees/{payeeId}/remoteIdUpdate
# DEPRECATED
@deprecated
export def "post-v3-payees-payee-id-remote-id-update" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
  remote_id: string # e.g. remoteId123
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/payees/{payeeId}/remoteIdUpdate"
    path_params: [{name: payeeId, var: payee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: payorId, var: payor_id}, {name: remoteId, var: remote_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payee_id: $payee_id, payor_id: $payor_id, remote_id: $remote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V3 Get List of Payments
#
# GET /v3/paymentaudit/payments
# DEPRECATED
# Returns: record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listPaymentsAuditV3
@deprecated
export def "list-payments-audit-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid)
  --payor-id: string # The account owner Payor Id. Required for external users. (format: uuid)
  --payor-name: string # The payor’s name. This filters via a case insensitive substring match.
  --remote-id: string # The remote id of the payees.
  --status: string@status-completer-1 # Payment Status
  --source-account-name: string # The source account name filter. This filters via a case insensitive substring match.
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --source-currency: string # The source currency filter. Filters based on an exact match on the currency.
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --payment-currency: string # The payment currency filter. Filters based on an exact match on the currency.
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --payment-memo: string # The payment memo filter. This filters via a case insensitive substring match.
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/paymentaudit/payments"
    query: [{name: payeeId, var: payee_id}, {name: payorId, var: payor_id}, {name: payorName, var: payor_name}, {name: remoteId, var: remote_id}, {name: status, var: status}, {name: sourceAccountName, var: source_account_name}, {name: sourceAmountFrom, var: source_amount_from}, {name: sourceAmountTo, var: source_amount_to}, {name: sourceCurrency, var: source_currency}, {name: paymentAmountFrom, var: payment_amount_from}, {name: paymentAmountTo, var: payment_amount_to}, {name: paymentCurrency, var: payment_currency}, {name: submittedDateFrom, var: submitted_date_from}, {name: submittedDateTo, var: submitted_date_to}, {name: paymentMemo, var: payment_memo}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}, {name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payee_id: $payee_id, payor_id: $payor_id, payor_name: $payor_name, remote_id: $remote_id, status: $status, source_account_name: $source_account_name, source_amount_from: $source_amount_from, source_amount_to: $source_amount_to, source_currency: $source_currency, payment_amount_from: $payment_amount_from, payment_amount_to: $payment_amount_to, payment_currency: $payment_currency, submitted_date_from: $submitted_date_from, submitted_date_to: $submitted_date_to, payment_memo: $payment_memo, page: $page, page_size: $page_size, sort: $sort, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V3 Get Payment
#
# GET /v3/paymentaudit/payments/{paymentId}
# DEPRECATED
# Returns: record<accountName: string, accountNumber: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>
# operationId: getPaymentDetailsV3
@deprecated
export def "get-payment-details-v3" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/paymentaudit/payments/{paymentId}"
    path_params: [{name: paymentId, var: payment_id}]
    query: [{name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V3 Get Payouts for Payor
#
# GET /v3/paymentaudit/payouts
# DEPRECATED
# Returns: record<content: table<fxSummaries: list, instructedDateTime: string, payorId: string, payoutId: string, payoutMemo: string, sourceAccountSummary: list, status: string, submittedDateTime: string, totalFailedPayments: int, totalIncompletePayments: int, totalPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getPayoutsForPayorV3
@deprecated
export def "get-payouts-for-payor-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (required, format: uuid)
  --payout-memo: string # Payout Memo filter - case insensitive sub-string match
  --status: string@status-completer-2 # Payout Status
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,instructedDateTime:asc,status:asc) Default is submittedDateTime:asc The supported sort fields are: submittedDateTime, instructedDateTime, status.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/paymentaudit/payouts"
    query: [{name: payorId, var: payor_id, required: true}, {name: payoutMemo, var: payout_memo}, {name: status, var: status}, {name: submittedDateFrom, var: submitted_date_from}, {name: submittedDateTo, var: submitted_date_to}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, payout_memo: $payout_memo, status: $status, submitted_date_from: $submitted_date_from, submitted_date_to: $submitted_date_to, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V3 Get Payments for Payout
#
# GET /v3/paymentaudit/payouts/{payoutId}
# DEPRECATED
# Returns: record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, failedPayments: int, incompletePayments: int, instructedDateTime: string, payoutMemo: string, payoutStatus: string, releasedPayments: int, submittedDateTime: string, totalPayments: int, withdrawnDateTime: string>>
# operationId: getPaymentsForPayout_PA_V3
@deprecated
export def "get-payments-for-payout-pa-v3" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remote-id: string # The remote id of the payees.
  --status: string@status-completer-1 # Payment Status
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/paymentaudit/payouts/{payoutId}"
    path_params: [{name: payoutId, var: payout_id}]
    query: [{name: remoteId, var: remote_id}, {name: status, var: status}, {name: sourceAmountFrom, var: source_amount_from}, {name: sourceAmountTo, var: source_amount_to}, {name: paymentAmountFrom, var: payment_amount_from}, {name: paymentAmountTo, var: payment_amount_to}, {name: submittedDateFrom, var: submitted_date_from}, {name: submittedDateTo, var: submitted_date_to}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}, {name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payout_id: $payout_id, remote_id: $remote_id, status: $status, source_amount_from: $source_amount_from, source_amount_to: $source_amount_to, payment_amount_from: $payment_amount_from, payment_amount_to: $payment_amount_to, submitted_date_from: $submitted_date_from, submitted_date_to: $submitted_date_to, page: $page, page_size: $page_size, sort: $sort, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# V3 Export Transactions
#
# GET /v3/paymentaudit/transactions
# DEPRECATED
# Returns: record<credit: int, creditCurrency: string, dateFundingRequested: string, debit: int, debitCurrency: string, fundingType: string, fxApplied: float, payeeType: string, paymentAmount: int, paymentCurrency: string, paymentMemo: string, paymentRails: string, paymentStatus: string, payorPaymentId: string, rejectReason: string, remoteId: string, reportTransactionType: string, returnCode: string, returnDescription: string, returnFee: string, returnFeeCurrency: string, returnFeeDescription: string, sourceAccount: string, transactionDate: string, transactionTime: string>
# operationId: exportTransactionsCSVV3
@deprecated
export def "export-transactions-csvv3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID for whom you wish to run the report. For a Payor requesting the report, this could be their exact Payor, or it could be a child/descendant Payor. (format: uuid)
  --start-date: string # Start date, inclusive. Format is YYYY-MM-DD (format: date)
  --end-date: string # End date, inclusive. Format is YYYY-MM-DD (format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/paymentaudit/transactions"
    query: [{name: payorId, var: payor_id}, {name: startDate, var: start_date}, {name: endDate, var: end_date}]
    accept: ["application/csv"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit Payout
#
# POST /v3/payouts
# operationId: submitPayoutV3
export def "submit-payout-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payments: list # item shape: {amount: int, currency: string, paymentMemo?: string, paymentMetadata?: string, payorPaymentId?: string, remoteId: string, remoteSystemId?: string, sourceAccountName: string, transmissionType?: "SAME_DAY_ACH"|"WIRE"|"ACH"|"LOCAL"|"SWIFT"}
  --payout-from-payor-id: string # The id of the payor whose source account(s) will be debited payoutFromPayorId and payoutToPayorId must be both supplied or both omitted (format: uuid, e.g. c4261044-13df-4a6c-b1d4-fa8be2b46f5a)
  --payout-memo: string # Text applied to all payment memos unless specified explicitly on a payment This should be the reference field on the statement seen by the payee (but not via ACH) (e.g. Monthly Payment)
  --payout-to-payor-id: string # The id of the payor whose payees will be paid payoutFromPayorId and payoutToPayorId must be both supplied or both omitted (format: uuid, e.g. 9afc6b39-de12-466a-a9ca-07c7a23b312d)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/payouts"
    body: {content_type: "application/json", kind: json, fields: [{name: payments, var: payments}, {name: payoutFromPayorId, var: payout_from_payor_id}, {name: payoutMemo, var: payout_memo}, {name: payoutToPayorId, var: payout_to_payor_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    payments: $payments, payout_from_payor_id: $payout_from_payor_id, payout_memo: $payout_memo, payout_to_payor_id: $payout_to_payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Withdraw Payout
#
# DELETE /v3/payouts/{payoutId}
# operationId: withdrawPayoutV3
export def "withdraw-payout-v3" [
  payout_id: string
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
    path: "/v3/payouts/{payoutId}"
    path_params: [{name: payoutId, var: payout_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    payout_id: $payout_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payout Summary
#
# GET /v3/payouts/{payoutId}
# Returns: record<acceptedPayments: table<amount: int, currencyType: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, accounts: table<currency: string, sourceAccountId: string, sourceAccountName: string, totalPayoutCost: int>, fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>, paymentsAccepted: int, paymentsRejected: int, paymentsSubmitted: int, paymentsWithdrawn: int, payoutId: string, rejectedPayments: table<amount: int, currencyType: string, lineNumber: int, message: string, paymentMetadata: string, payorPaymentId: string, reason: string, reasonCode: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledByPrincipalId: string, scheduledFor: string>, status: string>
# operationId: getPayoutSummaryV3
export def "get-payout-summary-v3" [
  payout_id: string
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
    path: "/v3/payouts/{payoutId}"
    path_params: [{name: payoutId, var: payout_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payout_id: $payout_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Instruct Payout
#
# POST /v3/payouts/{payoutId}
# operationId: instructPayoutV3
export def "instruct-payout-v3" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fx-rate-degredation-threshold-percentage: float # Halt instruction if the FX rates have become worse since the last quote (format: float)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/payouts/{payoutId}"
    path_params: [{name: payoutId, var: payout_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fxRateDegredationThresholdPercentage, var: fx_rate_degredation_threshold_percentage}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    payout_id: $payout_id, fx_rate_degredation_threshold_percentage: $fx_rate_degredation_threshold_percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve payments for a payout
#
# GET /v3/payouts/{payoutId}/payments
# Returns: record<content: table<amount: int, autoWithdrawnReasonCode: string, currency: string, payee: record, paymentId: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string, status: string, transmissionType: string, withdrawable: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getPaymentsForPayoutV3
export def "get-payments-for-payout-v3" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # Payment Status * ACCEPTED: any payment which was accepted at submission time (status may have changed since) * REJECTED: any payment rejected by initial submission processing * WITHDRAWN: any payment which has been withdrawn * WITHDRAWABLE: any payment eligible for withdrawal
  --remote-id: string # The remote id of the payees.
  --payor-payment-id: string # Payor's Id of the Payment
  --source-account-name: string # Physical Account Name
  --transmission-type: string@transmission-type-completer # Transmission Type * ACH * SAME_DAY_ACH * WIRE
  --payment-memo: string # Payment Memo of the Payment
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/payouts/{payoutId}/payments"
    path_params: [{name: payoutId, var: payout_id}]
    query: [{name: status, var: status}, {name: remoteId, var: remote_id}, {name: payorPaymentId, var: payor_payment_id}, {name: sourceAccountName, var: source_account_name}, {name: transmissionType, var: transmission_type}, {name: paymentMemo, var: payment_memo}, {name: pageSize, var: page_size}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payout_id: $payout_id, status: $status, remote_id: $remote_id, payor_payment_id: $payor_payment_id, source_account_name: $source_account_name, transmission_type: $transmission_type, payment_memo: $payment_memo, page_size: $page_size, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a quote for the payout
#
# POST /v3/payouts/{payoutId}/quote
# Returns: record<fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>>
# operationId: createQuoteForPayoutV3
export def "create-quote-for-payout-v3" [
  payout_id: string
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
    path: "/v3/payouts/{payoutId}/quote"
    path_params: [{name: payoutId, var: payout_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payout_id: $payout_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deschedule a payout
#
# DELETE /v3/payouts/{payoutId}/schedule
# operationId: deschedulePayout
export def "deschedule-payout" [
  payout_id: string
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
    path: "/v3/payouts/{payoutId}/schedule"
    path_params: [{name: payoutId, var: payout_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payout_id: $payout_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule a payout
#
# POST /v3/payouts/{payoutId}/schedule
# operationId: scheduleForPayout
export def "schedule-for-payout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notifications-enabled: oneof<nothing, bool> # Flag to indicate whether to receive notifications when scheduled payout is processed
  scheduled_for: string # UTC timestamp for instructing the payout. Format is ISO-8601. (format: date-time, e.g. 2025-01-01T10:00:00Z)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/payouts/{payoutId}/schedule"
    path_params: [{name: payoutId, var: payout_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: notificationsEnabled, var: notifications_enabled, required: true}, {name: scheduledFor, var: scheduled_for}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payout_id: $payout_id, notifications_enabled: $notifications_enabled, scheduled_for: $scheduled_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of source accounts
#
# GET /v3/sourceAccounts
# Returns: record<content: table<autoTopUpConfig: record, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getSourceAccountsV3
export def "get-source-accounts-v3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --physical-account-name: string # Physical Account Name
  --physical-account-id: string # The physical account ID (format: uuid)
  --payor-id: string # The account owner Payor ID (format: uuid)
  --funding-account-id: string # The funding account ID (format: uuid)
  --include-user-deleted: string # A filter for retrieving both active accounts and user deleted ones (format: boolean)
  --type: string # The type of source account.
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields e.g. ?sort=name:asc Default is name:asc The supported sort fields are - fundingRef, name, balance (default: fundingRef:asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/sourceAccounts"
    query: [{name: physicalAccountName, var: physical_account_name}, {name: physicalAccountId, var: physical_account_id}, {name: payorId, var: payor_id}, {name: fundingAccountId, var: funding_account_id}, {name: includeUserDeleted, var: include_user_deleted}, {name: type, var: type}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    physical_account_name: $physical_account_name, physical_account_id: $physical_account_id, payor_id: $payor_id, funding_account_id: $funding_account_id, include_user_deleted: $include_user_deleted, type: $type, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a source account by ID
#
# DELETE /v3/sourceAccounts/{sourceAccountId}
# operationId: deleteSourceAccountV3
export def "delete-source-account-v3" [
  source_account_id: string
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
    path: "/v3/sourceAccounts/{sourceAccountId}"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_account_id: $source_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about given source account.
#
# GET /v3/sourceAccounts/{sourceAccountId}
# Returns: record<autoTopUpConfig: record<enabled: bool, fundingAccountId: string, minBalance: int, targetBalance: int>, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool>
# operationId: getSourceAccountV3
export def "get-source-account-v3" [
  source_account_id: string
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
    path: "/v3/sourceAccounts/{sourceAccountId}"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_account_id: $source_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Funding Request
#
# POST /v3/sourceAccounts/{sourceAccountId}/fundingRequest
# operationId: createFundingRequestV3
export def "create-funding-request-v3" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to fund in minor units (format: int64)
  funding_account_id: string # The funding account id (format: uuid)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/sourceAccounts/{sourceAccountId}/fundingRequest"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: fundingAccountId, var: funding_account_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    source_account_id: $source_account_id, amount: $amount, funding_account_id: $funding_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set notifications
#
# POST /v3/sourceAccounts/{sourceAccountId}/notifications
# operationId: setNotificationsRequestV3
export def "set-notifications-request-v3" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  minimum_balance: int # Amount to set as minimum balance for notifications in minor units (format: int64, e.g. 10000000)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/sourceAccounts/{sourceAccountId}/notifications"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: minimumBalance, var: minimum_balance}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_account_id: $source_account_id, minimum_balance: $minimum_balance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer Funds between source accounts
#
# POST /v3/sourceAccounts/{sourceAccountId}/transfers
# operationId: transferFundsV3
export def "transfer-funds-v3" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to transfer, in minor units (format: int64)
  currency: string # Valid ISO 4217 3 letter currency code. See the ISO specification (https://www.iso.org/iso-4217-currency-codes.html) for details. (e.g. USD)
  to_source_account_id: string # The 'to' source account id, which will be credited (format: uuid)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/sourceAccounts/{sourceAccountId}/transfers"
    path_params: [{name: sourceAccountId, var: source_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: currency, var: currency}, {name: toSourceAccountId, var: to_source_account_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_account_id: $source_account_id, amount: $amount, currency: $currency, to_source_account_id: $to_source_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payees
#
# GET /v4/payees
# Returns: record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>>
# operationId: listPayeesV4
export def "list-payees-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (required, format: uuid)
  --watchlist-status: string # The watchlistStatus of the payees.
  --disabled: oneof<nothing, bool> # Payee disabled
  --onboarded-status: string # The onboarded status of the payees.
  --email: string # Email address (format: email, e.g. bob@example.com)
  --display-name: string # The display name of the payees. (e.g. Bob Smith)
  --remote-id: string # The remote id of the payees. (e.g. remoteId123)
  --payee-type: string # The onboarded status of the payees.
  --payee-country: string # The country of the payee - 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --ofac-status: string # The ofacStatus of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
  --sort: string # List of sort fields (e.g. ?sort=onboardedStatus:asc,name:asc) Default is name:asc 'name' is treated as company name for companies - last name + ',' + firstName for individuals The supported sort fields are - payeeId, displayName, payoutStatus, onboardedStatus. (default: displayName:asc, e.g. displayName:asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/payees"
    query: [{name: payorId, var: payor_id, required: true}, {name: watchlistStatus, var: watchlist_status}, {name: disabled, var: disabled}, {name: onboardedStatus, var: onboarded_status}, {name: email, var: email}, {name: displayName, var: display_name}, {name: remoteId, var: remote_id}, {name: payeeType, var: payee_type}, {name: payeeCountry, var: payee_country}, {name: ofacStatus, var: ofac_status}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, watchlist_status: $watchlist_status, disabled: $disabled, onboarded_status: $onboarded_status, email: $email, display_name: $display_name, remote_id: $remote_id, payee_type: $payee_type, payee_country: $payee_country, ofac_status: $ofac_status, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate Payee Creation
#
# POST /v4/payees
# Returns: record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>>
# operationId: v4CreatePayee
export def "v4-create-payee" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payees: list # item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: "Individual"|"Company"}
  payor_id: string # e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/payees"
    body: {content_type: "application/json", kind: json, fields: [{name: payees, var: payees}, {name: payorId, var: payor_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    payees: $payees, payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query Batch Status
#
# GET /v4/payees/batch/{batchId}
# Returns: record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string>
# operationId: queryBatchStatusV4
export def "query-batch-status-v4" [
  batch_id: string
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
    path: "/v4/payees/batch/{batchId}"
    path_params: [{name: batchId, var: batch_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_id: $batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payee Changes
#
# GET /v4/payees/deltas
# Returns: record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listPayeeChangesV4
export def "list-payee-changes-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payees (required, format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (required, format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 100. Max allowable is 1000. (format: int32, default: 100, e.g. 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/payees/deltas"
    query: [{name: payorId, var: payor_id, required: true}, {name: updatedSince, var: updated_since, required: true}, {name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, updated_since: $updated_since, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payee Invitation Status
#
# GET /v4/payees/payors/{payorId}/invitationStatus
# Returns: record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getPayeesInvitationStatusV4
export def "get-payees-invitation-status-v4" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid, e.g. 2aa5d7e0-2ecb-403f-8494-1865ed0454e9)
  --invitation-status: string # The invitation status of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/payees/payors/{payorId}/invitationStatus"
    path_params: [{name: payorId, var: payor_id}]
    query: [{name: payeeId, var: payee_id}, {name: invitationStatus, var: invitation_status}, {name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, payee_id: $payee_id, invitation_status: $invitation_status, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Payee by Id
#
# DELETE /v4/payees/{payeeId}
# operationId: deletePayeeByIdV4
export def "delete-payee-by-id-v4" [
  payee_id: string
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
    path: "/v4/payees/{payeeId}"
    path_params: [{name: payeeId, var: payee_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payee_id: $payee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payee by Id
#
# GET /v4/payees/{payeeId}
# Returns: record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>
# operationId: getPayeeByIdV4
export def "get-payee-by-id-v4" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/payees/{payeeId}"
    path_params: [{name: payeeId, var: payee_id}]
    query: [{name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payee_id: $payee_id, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Payee Invite
#
# POST /v4/payees/{payeeId}/invite
# operationId: resendPayeeInviteV4
export def "resend-payee-invite-v4" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/payees/{payeeId}/invite"
    path_params: [{name: payeeId, var: payee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: payorId, var: payor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payee_id: $payee_id, payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Payee Details
#
# POST /v4/payees/{payeeId}/payeeDetailsUpdate
# operationId: payeeDetailsUpdateV4
export def "payee-details-update-v4" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # e.g. {city: Key West, country: US, countyOrProvince: FL, line1: 500 Duval St, line2: line2, line3: line3, line4: line4, zipOrPostcode: 33945} — shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
  --challenge: record # Used to override the default challenge presented to the payee when they onboard Not used after the payee has onboarded (e.g. {description: challenge description, value: 11984567}) — shape: {description: string, value: string}
  --company: record # nullable, e.g. {name: ABC Group Plc, operatingName: ABC Co, taxId: 123123123} — shape: {name: string, operatingName?: string, taxId?: string}
  --contact-sms-number: string # The phone number of a device that the payee wishes to receive sms messages on (e.g. 11235555555)
  --email: string # nullable, format: email, e.g. bob@example.com
  --individual: record # e.g. {dateOfBirth: 1985-01-01, name: {firstName: Bob, lastName: Smith, otherNames: A, title: Mr}, nationalIdentification: AB123456C} — shape: {name: any}
  --language: string # An IETF BCP 47 language code which has been configured for use within this Velo environment. See the /v1/supportedLanguages endpoint to list the available codes for an environment. (e.g. en-US)
  --payee-type: string@payee-type-completer-1 # The type of the payee
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/payees/{payeeId}/payeeDetailsUpdate"
    path_params: [{name: payeeId, var: payee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: challenge, var: challenge}, {name: company, var: company}, {name: contactSmsNumber, var: contact_sms_number}, {name: email, var: email}, {name: individual, var: individual}, {name: language, var: language}, {name: payeeType, var: payee_type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payee_id: $payee_id, address: $address, challenge: $challenge, company: $company, contact_sms_number: $contact_sms_number, email: $email, individual: $individual, language: $language, payee_type: $payee_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Payee Remote Id
#
# POST /v4/payees/{payeeId}/remoteIdUpdate
export def "post-v4-payees-payee-id-remote-id-update" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
  remote_id: string # e.g. remoteId123
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/payees/{payeeId}/remoteIdUpdate"
    path_params: [{name: payeeId, var: payee_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: payorId, var: payor_id}, {name: remoteId, var: remote_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payee_id: $payee_id, payor_id: $payor_id, remote_id: $remote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Fundings for Payor
#
# GET /v4/paymentaudit/fundings
# Returns: record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getFundingsV4
export def "get-fundings-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (required, format: uuid)
  --source-account-name: string # The source account name
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields. Example: ```?sort=destinationCurrency:asc,destinationAmount:asc``` Default is no sort. The supported sort fields are: dateTime and amount.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/paymentaudit/fundings"
    query: [{name: payorId, var: payor_id, required: true}, {name: sourceAccountName, var: source_account_name}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, source_account_name: $source_account_name, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Payments
#
# GET /v4/paymentaudit/payments
# Returns: record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listPaymentsAuditV4
export def "list-payments-audit-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid)
  --payor-id: string # The account owner Payor Id. Required for external users. (format: uuid)
  --payor-name: string # The payor’s name. This filters via a case insensitive substring match.
  --remote-id: string # The remote id of the payees.
  --remote-system-id: string # The id of the remote system that is orchestrating payments
  --status: string@status-completer-1 # Payment Status
  --transmission-type: string@transmission-type-completer-1 # Transmission Type * ACH * SAME_DAY_ACH * WIRE * GACHO
  --source-account-name: string # The source account name filter. This filters via a case insensitive substring match.
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --source-currency: string # The source currency filter. Filters based on an exact match on the currency.
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --payment-currency: string # The payment currency filter. Filters based on an exact match on the currency.
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --payment-memo: string # The payment memo filter. This filters via a case insensitive substring match.
  --rails-id: string # Payout Rails ID filter - case insensitive match. Any value is allowed, but you should use one of the supported railsId values. To get this list of values, you should call the 'Get Supported Rails' endpoint.
  --scheduled-for-date-from: string # Filter payouts scheduled to run on or after the given date. Format is yyyy-MM-dd. (format: date)
  --scheduled-for-date-to: string # Filter payouts scheduled to run on or before the given date. Format is yyyy-MM-dd. (format: date)
  --schedule-status: string@schedule-status-completer # Payout Schedule Status
  --post-instruct-fx-status: string@post-instruct-fx-status-completer # The status of the post instruct FX step if one was required for the payment
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by submittedDateTime:desc,paymentId:asc The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime, status and paymentId
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/paymentaudit/payments"
    query: [{name: payeeId, var: payee_id}, {name: payorId, var: payor_id}, {name: payorName, var: payor_name}, {name: remoteId, var: remote_id}, {name: remoteSystemId, var: remote_system_id}, {name: status, var: status}, {name: transmissionType, var: transmission_type}, {name: sourceAccountName, var: source_account_name}, {name: sourceAmountFrom, var: source_amount_from}, {name: sourceAmountTo, var: source_amount_to}, {name: sourceCurrency, var: source_currency}, {name: paymentAmountFrom, var: payment_amount_from}, {name: paymentAmountTo, var: payment_amount_to}, {name: paymentCurrency, var: payment_currency}, {name: submittedDateFrom, var: submitted_date_from}, {name: submittedDateTo, var: submitted_date_to}, {name: paymentMemo, var: payment_memo}, {name: railsId, var: rails_id}, {name: scheduledForDateFrom, var: scheduled_for_date_from}, {name: scheduledForDateTo, var: scheduled_for_date_to}, {name: scheduleStatus, var: schedule_status}, {name: postInstructFxStatus, var: post_instruct_fx_status}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}, {name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payee_id: $payee_id, payor_id: $payor_id, payor_name: $payor_name, remote_id: $remote_id, remote_system_id: $remote_system_id, status: $status, transmission_type: $transmission_type, source_account_name: $source_account_name, source_amount_from: $source_amount_from, source_amount_to: $source_amount_to, source_currency: $source_currency, payment_amount_from: $payment_amount_from, payment_amount_to: $payment_amount_to, payment_currency: $payment_currency, submitted_date_from: $submitted_date_from, submitted_date_to: $submitted_date_to, payment_memo: $payment_memo, rails_id: $rails_id, scheduled_for_date_from: $scheduled_for_date_from, scheduled_for_date_to: $scheduled_for_date_to, schedule_status: $schedule_status, post_instruct_fx_status: $post_instruct_fx_status, page: $page, page_size: $page_size, sort: $sort, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payment
#
# GET /v4/paymentaudit/payments/{paymentId}
# Returns: record<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, scheduledAt: string, scheduledBy: string, scheduledFor: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record<payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutId: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>>, postInstructFxInfo: record<fxMode: string, fxStatus: string, fxStatusUpdatedAt: string, fxTransactionReference: string>, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>
# operationId: getPaymentDetailsV4
export def "get-payment-details-v4" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/paymentaudit/payments/{paymentId}"
    path_params: [{name: paymentId, var: payment_id}]
    query: [{name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payout Statistics
#
# GET /v4/paymentaudit/payoutStatistics
# Returns: record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int>
# operationId: getPayoutStatsV4
export def "get-payout-stats-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID. Required for external users. (format: uuid)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/paymentaudit/payoutStatistics"
    query: [{name: payorId, var: payor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payouts for Payor
#
# GET /v4/paymentaudit/payouts
# Returns: record<content: table<dateTime: string, fxSummaries: list, instructedDateTime: string, payorId: string, payorName: string, payoutId: string, payoutMemo: string, payoutType: string, schedule: record, sourceAccountSummary: list, status: string, submittedDateTime: string, totalIncompletePayments: int, totalPayments: int, totalReturnedPayments: int, totalWithdrawnPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: getPayoutsForPayorV4
export def "get-payouts-for-payor-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The id (UUID) of the payor funding the payout or the payor whose payees are being paid. (format: uuid)
  --payout-memo: string # Payout Memo filter - case insensitive sub-string match
  --status: string@status-completer-2 # Payout Status
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --from-payor-name: string # The name of the payor whose payees are being paid. This filters via a case insensitive substring match.
  --scheduled-for-date-from: string # Filter payouts scheduled to run on or after the given date. Format is yyyy-MM-dd. (format: date)
  --scheduled-for-date-to: string # Filter payouts scheduled to run on or before the given date. Format is yyyy-MM-dd. (format: date)
  --schedule-status: string@schedule-status-completer # Payout Schedule Status
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,instructedDateTime:asc,status:asc) Default is submittedDateTime:asc The supported sort fields are: submittedDateTime, instructedDateTime, status, totalPayments, payoutId, scheduledFor
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/paymentaudit/payouts"
    query: [{name: payorId, var: payor_id}, {name: payoutMemo, var: payout_memo}, {name: status, var: status}, {name: submittedDateFrom, var: submitted_date_from}, {name: submittedDateTo, var: submitted_date_to}, {name: fromPayorName, var: from_payor_name}, {name: scheduledForDateFrom, var: scheduled_for_date_from}, {name: scheduledForDateTo, var: scheduled_for_date_to}, {name: scheduleStatus, var: schedule_status}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, payout_memo: $payout_memo, status: $status, submitted_date_from: $submitted_date_from, submitted_date_to: $submitted_date_to, from_payor_name: $from_payor_name, scheduled_for_date_from: $scheduled_for_date_from, scheduled_for_date_to: $scheduled_for_date_to, schedule_status: $schedule_status, page: $page, page_size: $page_size, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payments for Payout
#
# GET /v4/paymentaudit/payouts/{payoutId}
# Returns: record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, incompletePayments: int, instructed: record<principal: string, principalId: string>, instructedDateTime: string, payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutMemo: string, payoutStatus: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutType: string, quoted: record<principal: string, principalId: string>, quotedDateTime: string, releasedPayments: int, returnedPayments: int, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, submittedDateTime: string, submitting: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, totalPayments: int, withdrawn: record<principal: string, principalId: string>, withdrawnDateTime: string, withdrawnPayments: int>>
# operationId: getPaymentsForPayoutV4
export def "get-payments-for-payout-v4" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remote-id: string # The remote id of the payees.
  --remote-system-id: string # The id of the remote system that is orchestrating payments
  --status: string@status-completer-1 # Payment Status
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --transmission-type: string@transmission-type-completer-1 # Transmission Type * ACH * SAME_DAY_ACH * WIRE * GACHO
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/paymentaudit/payouts/{payoutId}"
    path_params: [{name: payoutId, var: payout_id}]
    query: [{name: remoteId, var: remote_id}, {name: remoteSystemId, var: remote_system_id}, {name: status, var: status}, {name: sourceAmountFrom, var: source_amount_from}, {name: sourceAmountTo, var: source_amount_to}, {name: paymentAmountFrom, var: payment_amount_from}, {name: paymentAmountTo, var: payment_amount_to}, {name: submittedDateFrom, var: submitted_date_from}, {name: submittedDateTo, var: submitted_date_to}, {name: transmissionType, var: transmission_type}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: sort, var: sort}, {name: sensitive, var: sensitive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payout_id: $payout_id, remote_id: $remote_id, remote_system_id: $remote_system_id, status: $status, source_amount_from: $source_amount_from, source_amount_to: $source_amount_to, payment_amount_from: $payment_amount_from, payment_amount_to: $payment_amount_to, submitted_date_from: $submitted_date_from, submitted_date_to: $submitted_date_to, transmission_type: $transmission_type, page: $page, page_size: $page_size, sort: $sort, sensitive: $sensitive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Transactions
#
# GET /v4/paymentaudit/transactions
# Returns: record<credit: int, creditCurrency: string, dateFundingRequested: string, debit: int, debitCurrency: string, fundingType: string, fxApplied: float, payeeEmail: string, payeeName: string, payeeType: string, paymentAmount: int, paymentCurrency: string, paymentMemo: string, paymentRails: string, paymentStatus: string, payorPaymentId: string, rejectReason: string, remoteId: string, reportTransactionType: string, returnCode: string, returnDescription: string, returnFee: string, returnFeeCurrency: string, returnFeeDescription: string, sourceAccount: string, transactionDate: string, transactionTime: string>
# operationId: exportTransactionsCSVV4
export def "export-transactions-csvv4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID for whom you wish to run the report. For a Payor requesting the report, this could be their exact Payor, or it could be a child/descendant Payor. (format: uuid)
  --start-date: string # Start date, inclusive. Format is YYYY-MM-DD (format: date)
  --end-date: string # End date, inclusive. Format is YYYY-MM-DD (format: date)
  --include: string@include-completer # Mode to determine whether to include other Payor's data in the results. May only be used if payorId is specified. Can be omitted or set to 'payorOnly' or 'payorAndDescendants'. payorOnly: Only include results for the specified Payor. This is the default if 'include' is omitted. payorAndDescendants: Aggregate results for all descendant Payors of the specified Payor. Should only be used if the Payor with the specified payorId has at least one child Payor. Note when a Payor requests the report and include=payorAndDescendants is used, the following additional columns are included in the CSV: Payor Name, Payor Id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/paymentaudit/transactions"
    query: [{name: payorId, var: payor_id}, {name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: include, var: include}]
    accept: ["application/csv"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, start_date: $start_date, end_date: $end_date, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payment Changes
#
# GET /v4/payments/deltas
# Returns: record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>>
# operationId: listPaymentChangesV4
export def "list-payment-changes-v4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payments (required, format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (required, format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/payments/deltas"
    query: [{name: payorId, var: payor_id, required: true}, {name: updatedSince, var: updated_since, required: true}, {name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payor_id: $payor_id, updated_since: $updated_since, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
