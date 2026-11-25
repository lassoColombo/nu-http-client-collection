# Auto-generated client for Authorized Partner API Specification v1.0.0
# Source: https://api.apis.guru/v2/specs/digitallocker.gov.in/authpartner/1.0.0/openapi.json
# Auth: --token flag or $env.AUTHORIZED_PARTNER_API_SPECIFICATION_TOKEN

const CLIENT = {
  base_url: "https://betaapi.digitallocker.gov.in/public"
  token_env_var: "AUTHORIZED_PARTNER_API_SPECIFICATION_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-2, in: header, header_name: X-2, prefix: ""}
    {name: x1123, in: header, header_name: X1123, prefix: ""}
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

def base-url-completer [] { ["https://betaapi.digitallocker.gov.in/public"] }
def auth-scheme-completer [] { ["x-2" "x1123" "bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/pdf" "image/jpeg" "image/jpg" "image/png"] }
def token-type-hint-completer [] { ["access_token" "refresh_token"] }
def gender-completer [] { ["F" "M" "T"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    verify-account-id: "record<digilockerid: string, registered: string>"
    get-authorization-code-id: "record<details: record<access_token: string, expires_in: int, scope: string, token_type: string>>"
    get-device-code-id: "record<device_code: string, dl_masked_email: string, dl_masked_mobile: int, expires_in: int>"
    upload-file-to-locker-id: "record<details: record<Path: string, size: string>>"
    get-file-from-uri-id: "string"
    get-list-of-self-uploaded-documents: "record<directory: string, items: table<date: string, description: string, id: string, issuer: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>>"
    get-list-of-issued-documents-version1-id: "record<details: record<date: string, description: string, doctype: string, issuer: string, issuerid: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>>"
    get-list-of-self-uploaded-documents-id: "record<details: record<date: string, description: string, id: int, issuer: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>>"
    get-list-of-documents-provided-by-an-issuer-id: "record<documents: table<description: string, doctype: string>>"
    get-list-of-issuers-id: "record<issuers: table<categories: string, description: string, issuerid: string, name: string, orgid: string>>"
    get-search-parameters-for-a-document-id: "table<example: string, label: string, paramname: string, valuelist: any>"
    pull-document-id: "record<details: record<uri: string>>"
    getaccesstoken-id: "record<access_token: string, digilocker_id: string, dob: int, eaadhar: string, expires_in: int, gender: string, name: string, reference_key: string, refresh_token: string, scope: string, token_type: string>"
    account-detail-api-id: "record<details: record<digilockerid: string, dob: string, eaadhar: string, gender: string, name: string>>"
    get-list-of-issued-documents-id: "record<items: table<date: string, description: string, doctype: string, issuer: string, issuerid: string, mime: list, name: string, parent: string, size: string, type: string, uri: string>, resource: string>"
    verify-otp-id: "record<details: record<access_token: string, expires_in: string, refresh_token: string, scope: string, token_type: string>>"
    sign-up-id: "record<details: record<access_token: string, expires_in: string, mobile: int, refresh_token: string, scope: string, token_type: string>>"
    get-statistics-id: "record<authentic_documents: string, count_as_on: string, issuers: string, monthwise_registations: record<count: int, details2: record<count: int, id: int, month: int, year: int>, id: int, month: int, year: int>, requestors: string, users: string, yearwise_authentic_documents: record<count: int, details: record<count: int, id: int, year: int>, details1: record<count: int, id: int, year: int>, details2: record<count: int, id: int, year: int>, id: int, year: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["push-uri-to-account-id" "verify-account-id" "get-authorization-code-id" "get-device-code-id" "upload-file-to-locker-id" "get-file-from-uri-id" "get-list-of-self-uploaded-documents" "get-list-of-issued-documents-version1-id" "get-list-of-self-uploaded-documents-id" "get-list-of-documents-provided-by-an-issuer-id" "get-list-of-issuers-id" "get-search-parameters-for-a-document-id" "pull-document-id" "get-token-revocation-id" "getaccesstoken-id" "account-detail-api-id" "get-certificate-data-in-xml-format-from-uri-id" "get-list-of-issued-documents-id" "get-e-aadhaar-data-in-xml-format-id" "verify-otp-id" "sign-up-id" "get-statistics-id" "commands"] | sort) } | get name | first)
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

# Push URI to Account
#
# POST /account/1/pushuri
# operationId: Push URI to Account id
export def "push-uri-to-account-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # Action that needs to be taken for the Aadhaar number and URI combination. Possible values are A for adding a new URI, U for updating an already added URI details or D for deleting the URI.
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --digilockerid: int # This is the DigiLocker Id of the user that was acquired using Get User Details API.
  --docid: string # A unique number of the document. This id will be unique within the document type issued by the issuer.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --issuedate: string # The issue date of the document in DDMMYYYY format.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
  --uri: string # This is the unique identifier of the document.
  --validfrom: int # The date from which the document is valid in DDMMYYYY format. This may be same as the issue date.
  --validto: string # The expiry date of the document in DDMMYYYY format.
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/1/pushuri"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: action, var: action}, {name: clientid, var: clientid}, {name: digilockerid, var: digilockerid}, {name: docid, var: docid}, {name: hmac, var: hmac}, {name: issuedate, var: issuedate}, {name: ts, var: ts}, {name: uri, var: uri}, {name: validfrom, var: validfrom}, {name: validto, var: validto}], files: [hmac]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, clientid: $clientid, digilockerid: $digilockerid, docid: $docid, hmac: $hmac, issuedate: $issuedate, ts: $ts, uri: $uri, validfrom: $validfrom, validto: $validto
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Account
#
# POST /account/2/verify
# Returns: record<digilockerid: string, registered: string>
# operationId: Verify Account id
export def "verify-account-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --mobile: int # This is the mobile number of the user. DigiLocker will check whether an account exists for this mobile number. Either uid or mobile is required to verify whether an account exists.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
  --uid: int # This is the Aadhaar number of the user. DigiLocker will check whether an account exists for this Aadhaar number. Either uid or mobile is required to verify whether an account exists.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/2/verify"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: clientid, var: clientid}, {name: hmac, var: hmac}, {name: mobile, var: mobile}, {name: ts, var: ts}, {name: uid, var: uid}], files: [hmac]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientid: $clientid, hmac: $hmac, mobile: $mobile, ts: $ts, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Authorization Code
#
# GET /oauth2/1/authorize
# Returns: record<details: record<access_token: string, expires_in: int, scope: string, token_type: string>>
# operationId: Get Authorization Code id
export def "get-authorization-code-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Provide the client id that was created during the application registration process on Partners Portal.
  --response-type: string # Provide the grant type requested, either token or code. (required)
  --redirect-uri: string # The URI to redirect the user after authorization has completed. (required)
  --state: string # This is your application specific data that will be passed back to your application through redirect_uri. (required)
  --code-challenge: string # A unique random string called code verifier (code_verifier) is created by the client application for every authorization request. The code_challenge sent as this parameter is the Base64URL (with no padding) encoded SHA256 hash of the code verifier. Code block: ``` string base64_url_encode_without_padding(string arg) { string s = base64encode(arg); //Regular base64encoder with padding s = s.replace(’=’,’’); //Remove any trailing ’=’ s = s.replace(’+’, ’-’); //Replace ’+’ with ’-’ s = s.replace(’/’, ’_’); //Replace ’/’ with ’_’ return s; } ``` (e.g. base64_url_encode_without_padding(sha256(code_verifier)))
  --code-challenge-method: string # Specifies what method was used to encode a code_verifier to generate code_challenge parameter above. This parameter must be used with the code_challenge parameter. The only supported values for this parameter is S256.
  --dl-flow: string # If this parameter is provided its value will always be signup. This parameter indicates that the user does not have a DigiLocker account and will be directed to the signup flow directly. After the account is created, the user will be directed to the authorization flow. If this parameter is not sent, the user will be redirected to the sign in flow.
  --verified-mobile: int # Verified mobile number of the user. If this parameter is passed, DigiLocker will skip the mobile OTP verification step during sign up. DigiLocker will treat the mobile number passed in this parameter as a verified mobile number by the trusted client application. This parameter will be used only if dl_flow parameter mentioned above is set to signup and will be ignored otherwise.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/oauth2/1/authorize"
    query: [{name: client_id, var: client_id}, {name: response_type, var: response_type, required: true}, {name: redirect_uri, var: redirect_uri, required: true}, {name: state, var: state, required: true}, {name: Code_challenge, var: code_challenge}, {name: Code_challenge_method, var: code_challenge_method}, {name: dl_flow, var: dl_flow}, {name: Verified_mobile, var: verified_mobile}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, response_type: $response_type, redirect_uri: $redirect_uri, state: $state, code_challenge: $code_challenge, code_challenge_method: $code_challenge_method, dl_flow: $dl_flow, verified_mobile: $verified_mobile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Device Code
#
# POST /oauth2/1/code
# Returns: record<device_code: string, dl_masked_email: string, dl_masked_mobile: int, expires_in: int>
# operationId: Get Device Code id
export def "get-device-code-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --dl-mobile: int # Mobile number associated with DigiLocker account of the user. The client device accepts the mobile number on the device from user and sends it in this parameter. Either the username or the mobile number must be provided.
  --dl-username: string # DigiLocker username of the user. The client device accepts the username on the device from user and sends the username in this parameter. Either the username or the mobile number must be provided.
  --response-type: string # The parameter must be set to device_code. (e.g. device_code)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/1/code"
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: client_id}, {name: dl_mobile, var: dl_mobile}, {name: dl_username, var: dl_username}, {name: response_type, var: response_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, dl_mobile: $dl_mobile, dl_username: $dl_username, response_type: $response_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file to locker
#
# POST /oauth2/1/file/upload
# Returns: record<details: record<Path: string, size: string>>
# operationId: Upload File to Locker id
export def "upload-file-to-locker-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The destination path of the file in DigiLocker including filename.
  --hmac: string # This is used to verify the integrity of the file data. The client app calculates the hash message authentication code (HMAC) of the file content using SHA256 hashing algorithm and the client secret as the hashing key. The resulting HMAC is converted to Base64 format and sent in this parameter. Upon upload of file, DigiLocker calculates the HMAC of the file data and compares it with this HMAC..
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/1/file/upload"
    header: [{name: path, var: path}, {name: hmac, var: hmac}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, hmac: $hmac, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get File from URI
#
# GET /oauth2/1/file/{uri}
# Returns: string
# operationId: Get File from URI id
export def "get-file-from-uri-id" [
  uri: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/oauth2/1/file/{uri}"
    path_params: [{name: uri, var: uri}]
    accept: ["application/pdf", "image/jpeg", "image/jpg", "image/png"]
    ok: [200]
    auth: bearer
  } {
    uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get List of Self Uploaded Documents
#
# GET /oauth2/1/files/
# Returns: record<directory: string, items: table<date: string, description: string, id: string, issuer: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>>
# operationId: Get List of Self Uploaded Documents
export def "get-list-of-self-uploaded-documents" [
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
    path: "/oauth2/1/files/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issued Documents
#
# GET /oauth2/1/files/issued
# Returns: record<details: record<date: string, description: string, doctype: string, issuer: string, issuerid: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>>
# operationId: Get List of issued Documents Version1 id
export def "get-list-of-issued-documents-version1-id" [
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
    path: "/oauth2/1/files/issued"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Self Uploaded Documents
#
# GET /oauth2/1/files/{id}
# Returns: record<details: record<date: string, description: string, id: int, issuer: string, mime: string, name: string, parent: string, size: string, type: string, uri: string>>
# operationId: Get List of Self Uploaded Documents id
export def "get-list-of-self-uploaded-documents-id" [
  id: string
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
    path: "/oauth2/1/files/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Documents Provided by an Issuer
#
# POST /oauth2/1/pull/doctype
# Returns: record<documents: table<description: string, doctype: string>>
# operationId: Get List of Documents Provided by an Issuer id
export def "get-list-of-documents-provided-by-an-issuer-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --orgid: string # The organization id for the issuer in DigiLocker. This organization id is returned in Get List of Issuers API mentioned earlier.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/1/pull/doctype"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: clientid, var: clientid}, {name: hmac, var: hmac}, {name: orgid, var: orgid}, {name: ts, var: ts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientid: $clientid, hmac: $hmac, orgid: $orgid, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Issuers
#
# POST /oauth2/1/pull/issuers
# Returns: record<issuers: table<categories: string, description: string, issuerid: string, name: string, orgid: string>>
# operationId: Get List of Issuers id
export def "get-list-of-issuers-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/1/pull/issuers"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: clientid, var: clientid}, {name: hmac, var: hmac}, {name: ts, var: ts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientid: $clientid, hmac: $hmac, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Search Parameters for a Document
#
# POST /oauth2/1/pull/parameters
# Returns: table<example: string, label: string, paramname: string, valuelist: any>
# operationId: Get Search Parameters for a Document id
export def "get-search-parameters-for-a-document-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --doctype: string # A 5 character unique document type provided by DigiLocker.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --orgid: string # The organization id for the issuer in DigiLocker. This organization id is returned in Get List of Issuers API mentioned earlier.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/1/pull/parameters"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: clientid, var: clientid}, {name: doctype, var: doctype}, {name: hmac, var: hmac}, {name: orgid, var: orgid}, {name: ts, var: ts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientid: $clientid, doctype: $doctype, hmac: $hmac, orgid: $orgid, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pull Document
#
# POST /oauth2/1/pull/pulldocument
# Returns: record<details: record<uri: string>>
# operationId: Pull Document id
export def "pull-document-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chasis-no: string # Other parameters required for fetching a document as listed in paramname field of Get Search Parameters API.
  --consent: string # The consent indicator from the user for performing demographic authentication using Aadhaar details. This Partner Application must capture the user consent for performing the Aadhaar demographic authentication. The possible values are ‘Y’ and ‘N’. The sign up request will be processed only when this indicator is ‘Y’.
  --doctype: string # A 5 character unique document type provided by DigiLocker.
  --orgid: string # The organization id for the issuer in DigiLocker. This organization id is returned in Get List of Issuers API mentioned above.
  --reg-no: string # Other parameters required for fetching a document as listed in paramname field of Get Search Parameters API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/1/pull/pulldocument"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: chasis_no, var: chasis_no}, {name: consent, var: consent}, {name: doctype, var: doctype}, {name: orgid, var: orgid}, {name: reg_no, var: reg_no}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    chasis_no: $chasis_no, consent: $consent, doctype: $doctype, orgid: $orgid, reg_no: $reg_no
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke Token.
#
# POST /oauth2/1/revoke
# operationId: get token revocation id
export def "get-token-revocation-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The token that needs to be revoked. (spec name: token)
  --token-type-hint: string@token-type-hint-completer # The type of the above token. The value will be one of access_token or refresh_token. If this parameter is not sent, DigiLocker will look for this token in both access and refresh tokens and then revoke it.
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth2/1/revoke"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token, required: true}, {name: token_type_hint, var: token_type_hint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body_token: $body_token, token_type_hint: $token_type_hint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Access Token
#
# POST /oauth2/1/token
# Returns: record<access_token: string, digilocker_id: string, dob: int, eaadhar: string, expires_in: int, gender: string, name: string, reference_key: string, refresh_token: string, scope: string, token_type: string>
# operationId: getaccesstoken id
export def "getaccesstoken-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --get-access-token-using-authorization-code: record # shape: {client_id: string, client_secret: string, code?: string, code_verifier?: string, grant_type: "authorization_code", redirect_uri?: string}
  --get-access-token-using-device-code-and-otp: any # shape: {client_id?: string, device_code?: string, dl_otp?: string, grant_type?: string}
  --get-access-token-using-refresh-token: record # shape: {client_id: string, client_secret: string, grant_type: "refresh_token", refresh_token: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/1/token"
    body: {content_type: "application/json", kind: json, fields: [{name: "Get access token using authorization code", var: get_access_token_using_authorization_code}, {name: "Get access token using device code and OTP", var: get_access_token_using_device_code_and_otp}, {name: "Get access token using refresh token", var: get_access_token_using_refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-2
  } {
    get_access_token_using_authorization_code: $get_access_token_using_authorization_code, get_access_token_using_device_code_and_otp: $get_access_token_using_device_code_and_otp, get_access_token_using_refresh_token: $get_access_token_using_refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Details
#
# GET /oauth2/1/user
# Returns: record<details: record<digilockerid: string, dob: string, eaadhar: string, gender: string, name: string>>
# operationId: Account Detail API id
export def "account-detail-api-id" [
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
    path: "/oauth2/1/user"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Certificate Data in XML Format from URI
#
# GET /oauth2/1/xml/{uri}
# operationId: Get Certificate Data in XML Format from URI id
export def "get-certificate-data-in-xml-format-from-uri-id" [
  uri: string
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
    path: "/oauth2/1/xml/{uri}"
    path_params: [{name: uri, var: uri}]
    accept: ["application/xml"]
    ok: [200]
    auth: bearer
  } {
    uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issued Documents
#
# GET /oauth2/2/files/issued
# Returns: record<items: table<date: string, description: string, doctype: string, issuer: string, issuerid: string, mime: list, name: string, parent: string, size: string, type: string, uri: string>, resource: string>
# operationId: Get List of issued Documents id
export def "get-list-of-issued-documents-id" [
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
    path: "/oauth2/2/files/issued"
    accept: ["application/json"]
    ok: [200]
    auth: x-2
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get e-Aadhaar Data in XML Format
#
# GET /oauth2/2/xml/eaadhaar
# operationId: Get e-Aadhaar Data in XML Format id
export def "get-e-aadhaar-data-in-xml-format-id" [
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
    path: "/oauth2/2/xml/eaadhaar"
    accept: ["application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify OTP
#
# POST /signup/1/demoauthverify
# Returns: record<details: record<access_token: string, expires_in: string, refresh_token: string, scope: string, token_type: string>>
# operationId: Verify OTP id
export def "verify-otp-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --mobile: int # This is the mobile number of the user. DigiLocker will check whether an account exists for this mobile number. Either uid or mobile is required to verify whether an account exists.
  --otp: int # The OTP provided by the user.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/signup/1/demoauthverify"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: clientid, var: clientid}, {name: hmac, var: hmac}, {name: mobile, var: mobile}, {name: otp, var: otp}, {name: ts, var: ts}], files: [hmac]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientid: $clientid, hmac: $hmac, mobile: $mobile, otp: $otp, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SIGN UP
#
# POST /signup/2/demoauth
# Returns: record<details: record<access_token: string, expires_in: string, mobile: int, refresh_token: string, scope: string, token_type: string>>
# operationId: SIGN UP id
export def "sign-up-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --consent: string # The consent indicator from the user for performing demographic authentication using Aadhaar details. This Partner Application must capture the user consent for performing the Aadhaar demographic authentication. The possible values are ‘Y’ and ‘N’. The sign up request will be processed only when this indicator is ‘Y’.
  --demoauth: string # The parameter indicates whether Aadhaar demographic authentication must be successful for creating DigiLocker account. The possible values are ‘Y’ and ‘N’. The value of ‘Y’ will perform Aadhaar demographic authentication and will return errors if any in response. The value of ‘N’ will also perform Aadhaar demographic authentication but will return any error in case of authentication failure. It will create a basic mobile based account for the user. Value ‘N’ should be used when the user account needs to be created in the absence of the user.
  --dob: int # This is date of birth of the user as mentioned in Aadhaar in DDMMYYYY format.
  --gender: any@gender-completer # This is gender of the user as mentioned in Aadhaar. The possible values are M, F, T for male, female and transgender respectively.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --mobile: int # This is the mobile number of the user. DigiLocker will check whether an account exists for this mobile number. Either uid or mobile is required to verify whether an account exists.
  --name: string # This is name of the user as mentioned in Aadhaar.
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
  --uid: int # This is the Aadhaar number of the user. DigiLocker will check whether an account exists for this Aadhaar number. Either uid or mobile is required to verify whether an account exists.
  --verification: string # The parameter indicates whether the mobile number provided above should be validated by DigiLocker. If this parameter is ‘Y’, the DigiLocker sends an OTP to verify the mobile number. In this case the client application will call the second API to validate the OTP. The user will be signed on only after successful OTP validation. This flow should be used when the user account is created by user himself/herself or the user is present to provide the OTP. If this parameter is ‘N’, the user account will be created without OTP validation. The OTP validation will be performed when the user signs in for the first time in DigiLocker. This flow should be used when the user account needs to be created in the absence of the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/signup/2/demoauth"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: clientid, var: clientid}, {name: consent, var: consent}, {name: demoauth, var: demoauth}, {name: dob, var: dob}, {name: gender, var: gender}, {name: hmac, var: hmac}, {name: mobile, var: mobile}, {name: name, var: name}, {name: ts, var: ts}, {name: uid, var: uid}, {name: verification, var: verification}], files: [hmac]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientid: $clientid, consent: $consent, demoauth: $demoauth, dob: $dob, gender: $gender, hmac: $hmac, mobile: $mobile, name: $name, ts: $ts, uid: $uid, verification: $verification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Statistics
#
# POST /statistics/1/counts
# Returns: record<authentic_documents: string, count_as_on: string, issuers: string, monthwise_registations: record<count: int, details2: record<count: int, id: int, month: int, year: int>, id: int, month: int, year: int>, requestors: string, users: string, yearwise_authentic_documents: record<count: int, details: record<count: int, id: int, year: int>, details1: record<count: int, id: int, year: int>, details2: record<count: int, id: int, year: int>, id: int, year: int>>
# operationId: Get Statistics id
export def "get-statistics-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientid: string # Provide the client id that was created during the application registration process on Partners Portal.
  --hmac: string # Provide SHA-256 encrypted value of the client secret, clientid and ts parameters above concatenated in this sequence (client secret, clientid, ts). The hmac parameter is used by DigiLocker to ensure the data integrity and authentication of the request. Use the Client Secret Key generated during the application registration process on Partners Portal as the client secret. (format: binary)
  --ts: string # Provide a timestamp value in UNIX (or POSIX) format in IST time zone in seconds. This timestamp value must not be older than 30 minutes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/statistics/1/counts"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: clientid, var: clientid}, {name: hmac, var: hmac}, {name: ts, var: ts}], files: [hmac]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    clientid: $clientid, hmac: $hmac, ts: $ts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
