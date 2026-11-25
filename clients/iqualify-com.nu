# Auto-generated client for iQualify Management API v1
# Source: https://api.apis.guru/v2/specs/iqualify.com/v1/openapi.json
# Auth: --token flag or $env.IQUALIFY_MANAGEMENT_API_TOKEN

const CLIENT = {
  base_url: "https://api.iqualify.com/v1"
  token_env_var: "IQUALIFY_MANAGEMENT_API_TOKEN"
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

def base-url-completer [] { ["https://api.iqualify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def pulse-type-completer [] { ["MCQ" "spatial_linear" "spatial_planar" "spatial_triangular" "submit_text"] }
def facilitators-completer [] { ["false" "true"] }
def learners-completer [] { ["false" "true"] }
def markers-completer [] { ["false" "true"] }
def permission-name-completer [] { ["builder" "manager"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-op: "record"
    get-course-mappings: "record"
    get-course-mappings-externalcourse-external-course-id: "list<string>"
    get-course-mappings-offering-id: "list<string>"
    delete-course-mappings-offering-id-external-course-id: "list<string>"
    put-course-mappings-offering-id-external-course-id: "list<string>"
    get-courses: "table<coverImageUrl: string, createdAt: string, id: string, metadata: record<learning_outcomes: list>, name: string>"
    get-courses-content-id: "record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>"
    get-courses-content-id-activations: "record<end: string, id: string, info: string, learnersCount: string, metadata: record<rootContentId: string>, name: string, start: string>"
    put-courses-content-id-metadata-category: "record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>"
    put-courses-content-id-metadata-level: "record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>"
    put-courses-content-id-metadata-tags: "record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>"
    put-courses-content-id-metadata-topic: "record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>"
    get-courses-content-id-permissions: "record<email: string, isBuilder: bool, isReviewer: bool, name: string>"
    post-courses-root-content-id-permissions-user-email: "record<contentId: string>"
    get-offerings: "table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    post-offerings: "record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    get-offerings-current: "table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    get-offerings-future: "table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    get-offerings-info-text-pattern: "table<contentId: string, end: string, id: string, info: string, learnersCount: float, metadata: record<rootContentId: string>, name: string, start: string>"
    get-offerings-past: "table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    get-offerings-summary: "table<contentId: string, end: string, id: string, info: string, learnersCount: float, metadata: record<rootContentId: string>, name: string, start: string>"
    get-offerings-offering-id: "record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    patch-offerings-offering-id: "record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    get-offerings-offering-id-activities-openresponse: "table<activityId: string, time: float, title: string>"
    get-offerings-offering-id-analytics-activities-responses: "table<activityId: string, activityType: string, feedback: record<facilitatorEmail: string, text: string>, learnerEmail: string, offeringId: string, responseText: string, uploadedFiles: record<filename: string, mimetype: string, size: string, url: string>>"
    get-offerings-offering-id-analytics-channels-channel-id-comments: "table<content: string, createdAt: string, email: string, id: string, isFacilitatorPost: bool, moderation: record<isMuted: bool, moderator: record, reason: string>, parentCommentId: string, postId: string>"
    get-offerings-offering-id-analytics-channels-channel-id-posts: "table<attachments: list<record>, content: string, createdAt: string, email: string, id: string, isFacilitatorPost: bool, moderation: record<isMuted: bool, moderator: record, reason: string>, title: string>"
    get-offerings-offering-id-analytics-channels-channel-id-replies: "table<content: string, createdAt: string, email: string, id: string, isFacilitatorPost: bool, moderation: record<isMuted: bool, moderator: record, reason: string>, parentCommentId: string, postId: string>"
    get-offerings-offering-id-analytics-learners-progress: "table<completion: string, courseId: string, email: string, firstName: string, lastLoggedInAt: string, lastName: string, personId: string>"
    get-offerings-offering-id-analytics-marks-assignments: "table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, mark: string, markFeedback: string, markedBy: string, markedByEvaluator: bool, markedByFacilitator: bool, markedByMarker: bool, markedDateTime: string, submissionDateTime: string>"
    get-offerings-offering-id-analytics-marks-quizzes: "table<attempts: int, lastAttemptAt: string, learnerEmail: string, learnerFullname: string, learnerPersonId: string, mark: string, quizId: string, quizTitle: string>"
    get-offerings-offering-id-analytics-pulses: "list<string>"
    get-offerings-offering-id-analytics-pulses-responses: "table<learnerFirstName: string, learnerId: string, learnerLastName: string, pulseBaseId: string, pulseInstanceId: string, pulseQuestion: string, pulseRunDurationMinutes: int, pulseRunStart: string, pulseType: string, response: record<multiChoiceAnswer: list, spatialAnswer: list, textAnswer: string>, responseTime: string>"
    get-offerings-offering-id-analytics-pulses-pulse-id-responses: "table<learnerFirstName: string, learnerId: string, learnerLastName: string, pulseBaseId: string, pulseInstanceId: string, pulseQuestion: string, pulseRunDurationMinutes: int, pulseRunStart: string, pulseType: string, response: record<multiChoiceAnswer: list, spatialAnswer: list, textAnswer: string>, responseTime: string>"
    get-offerings-offering-id-analytics-social-notes: "table<email: string, firstName: string, lastName: string, pageId: string, personId: string, social-note-content: string, social-note-paragraphId: string, userId: string>"
    get-offerings-offering-id-analytics-submissions-assignments: "table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, mark: string, markFeedback: string, markedBy: string, markedByEvaluator: bool, markedByFacilitator: bool, markedByMarker: bool, markedDateTime: string, submissionDateTime: string>"
    get-offerings-offering-id-analytics-submissions-open-response-assessment-id: "table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, files: list<record>, html: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, marks: list<record>, status: string, submissionDateTime: string>"
    get-offerings-offering-id-analytics-submissions-user-email-assignments-assessment-id: "table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, files: list<record>, html: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, marks: list<record>, status: string, submissionDateTime: string>"
    get-offerings-offering-id-analytics-unit-reactions: "table<feedback: record<thumbs-down: float, thumbs-up: float>, pageId: bool>"
    get-offerings-offering-id-assessments: "table<content: string, documents: list<record>, dueDate: string, durationMinutes: int, filename: string, hidden: bool, id: string, markNumber: string, markType: string, maxAttempts: int, openDate: string, pid: string, points: string, themes: list<record>, title: string, totalQuestions: int, totalThemes: int, type: string>"
    patch-offerings-offering-id-assessments-assessment-id: "record<content: string, documents: table<createdAt: string, filename: string, id: string, mimetype: string, size: int, url: string>, dueDate: string, durationMinutes: int, filename: string, hidden: bool, id: string, markNumber: string, markType: string, maxAttempts: int, openDate: string, pid: string, points: string, themes: table<filter: string, numberOfQuestions: string>, title: string, totalQuestions: int, totalThemes: int, type: string>"
    get-offerings-offering-id-badges: "record<badgeExpiry: record<expirationDate: string, expires: bool, expiryType: string, timeframeAmount: float, timeframeUnit: string>, badgeUrl: string, criterias: record<hasCompletedCourse: bool, hasPassedMandatoryAssessedQuizzes: bool>, description: string, openBadge: record<criteria: record<narrative: string>, description: string, id: string, image: string, issuer: string, name: string, type: string>, title: string>"
    get-offerings-offering-id-channels: "table<id: string, isBroadcastOnly: bool, title: string>"
    post-offerings-offering-id-channels: "record<id: string, isBroadcastOnly: bool, title: string>"
    patch-offerings-offering-id-channels-channel-id: "record<id: string, isBroadcastOnly: bool, title: string>"
    get-offerings-offering-id-channels-channel-id-learners: "record<id: string, isBroadcastOnly: bool, title: string>"
    get-offerings-offering-id-groups: "table<createdAt: string, id: string, title: string>"
    post-offerings-offering-id-groups: "record<createdAt: string, id: string, title: string>"
    get-offerings-offering-id-groups-group-id-learners: "table<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string, mobile: string>>"
    post-offerings-offering-id-groups-group-id-learners: "record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>"
    get-offerings-offering-id-learners-pending-submission: "table<content: string, documents: list<record>, dueDate: string, durationMinutes: int, filename: string, hidden: bool, id: string, markNumber: string, markType: string, maxAttempts: int, offeringId: string, offeringName: string, openDate: string, pid: string, points: string, themes: list<record>, title: string, totalQuestions: int, totalThemes: int, type: string, users: list<record>>"
    put-offerings-offering-id-metadata-category: "record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    put-offerings-offering-id-metadata-level: "record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    put-offerings-offering-id-metadata-tags: "record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    put-offerings-offering-id-metadata-topic: "record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    get-offerings-offering-id-users: "table<avatarUrl: string, email: string, evaluatedBy: list<string>, evaluates: list<string>, firstName: string, id: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, markedBy: list<string>, marks: list<string>, personId: string, profile: record<displayName: string, mobile: string>>"
    post-offerings-offering-id-users: "table<email: string, firstName: string, invite: record<url: string>, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>"
    delete-offerings-offering-id-users-marker-email-marks: "table<email: string, firstName: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>"
    get-offerings-offering-id-users-marker-email-marks: "table<email: string, firstName: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>"
    post-offerings-offering-id-users-marker-email-marks: "table<email: string, firstName: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>"
    post-offerings-offering-id-users-user-email-badges-award: "record<awarded: bool, badgeId: string, badgeUrl: string>"
    get-offerings-offering-id-users-user-email-submissions-open-response: "table<files: list<record>, marks: list<record>, status: string, submittedAt: string, updatedAt: string>"
    get-org: "record<id: string, name: string>"
    post-users: "record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>"
    get-users-all-progress: "record<data: record<progress: list<record>>, top: int>"
    get-users-user-email: "record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>"
    patch-users-user-email: "record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>"
    get-users-user-email-badges: "table<awardedAt: string, badgeExpiry: record<expirationDate: string, expires: bool>, badgeUrl: string, criterias: record<hasCompletedCourse: bool, hasPassedMandatoryAssessedQuizzes: bool>, description: string, offeringId: string, openBadge: record<criteria: record, description: string, id: string, image: string, issuer: string, name: string, type: string>, title: string>"
    get-users-user-email-offerings: "table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    post-users-user-email-offerings: "table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>"
    get-users-user-email-offerings-offering-id-progress: "record<completion: string, email: string, firstName: string, id: string, lastName: string>"
    post-users-user-email-permissions-permission-name: "record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>"
    get-users-user-email-progress: "record<email: string, firstName: string, id: string, lastName: string, offerings: table<completion: string, id: string>, personId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-op" "get-course-mappings" "get-course-mappings-externalcourse-external-course-id" "get-course-mappings-offering-id" "delete-course-mappings-offering-id-external-course-id" "put-course-mappings-offering-id-external-course-id" "get-courses" "get-courses-content-id" "get-courses-content-id-activations" "put-courses-content-id-metadata-category" "put-courses-content-id-metadata-level" "put-courses-content-id-metadata-tags" "put-courses-content-id-metadata-topic" "get-courses-content-id-permissions" "post-courses-root-content-id-permissions-user-email" "get-offerings" "post-offerings" "get-offerings-current" "get-offerings-future" "get-offerings-info-text-pattern" "get-offerings-past" "get-offerings-summary" "get-offerings-offering-id" "patch-offerings-offering-id" "get-offerings-offering-id-activities-openresponse" "get-offerings-offering-id-analytics-activities-responses" "get-offerings-offering-id-analytics-channels-channel-id-comments" "get-offerings-offering-id-analytics-channels-channel-id-posts" "get-offerings-offering-id-analytics-channels-channel-id-replies" "get-offerings-offering-id-analytics-learners-progress" "get-offerings-offering-id-analytics-marks-assignments" "get-offerings-offering-id-analytics-marks-quizzes" "get-offerings-offering-id-analytics-pulses" "get-offerings-offering-id-analytics-pulses-responses" "get-offerings-offering-id-analytics-pulses-pulse-id-responses" "get-offerings-offering-id-analytics-social-notes" "get-offerings-offering-id-analytics-submissions-assignments" "get-offerings-offering-id-analytics-submissions-open-response-assessment-id" "get-offerings-offering-id-analytics-submissions-user-email-assignments-assessment-id" "get-offerings-offering-id-analytics-unit-reactions" "get-offerings-offering-id-assessments" "patch-offerings-offering-id-assessments-assessment-id" "delete-offerings-offering-id-assessments-assessment-id-documents-document-id" "patch-offerings-offering-id-assessments-assessment-id-user-email" "get-offerings-offering-id-badges" "get-offerings-offering-id-channels" "post-offerings-offering-id-channels" "patch-offerings-offering-id-channels-channel-id" "delete-offerings-offering-id-channels-channel-id-learners" "get-offerings-offering-id-channels-channel-id-learners" "post-offerings-offering-id-channels-channel-id-learners" "get-offerings-offering-id-groups" "post-offerings-offering-id-groups" "get-offerings-offering-id-groups-group-id-learners" "post-offerings-offering-id-groups-group-id-learners" "delete-offerings-offering-id-groups-group-id-learners-user-email" "get-offerings-offering-id-learners-pending-submission" "put-offerings-offering-id-metadata-category" "put-offerings-offering-id-metadata-level" "put-offerings-offering-id-metadata-tags" "put-offerings-offering-id-metadata-topic" "get-offerings-offering-id-users" "post-offerings-offering-id-users" "delete-offerings-offering-id-users-marker-email-marks" "get-offerings-offering-id-users-marker-email-marks" "post-offerings-offering-id-users-marker-email-marks" "delete-offerings-offering-id-users-user-email" "delete-offerings-offering-id-users-user-email-assessments-assessment-id" "post-offerings-offering-id-users-user-email-badges-award" "get-offerings-offering-id-users-user-email-submissions-open-response" "get-org" "post-users" "get-users-all-progress" "get-users-user-email" "patch-users-user-email" "get-users-user-email-badges" "post-users-user-email-invite-email" "get-users-user-email-offerings" "post-users-user-email-offerings" "get-users-user-email-offerings-offering-id-progress" "post-users-user-email-permissions-permission-name" "get-users-user-email-progress" "put-users-user-email-suspend" "patch-users-user-email-transfer" "commands"] | sort) } | get name | first)
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

# List supported endpoints URLs
#
# GET /
# Returns: record
export def "get-op" [
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
    path: "/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find course mappings
#
# GET /course-mappings
# Returns: record
export def "get-course-mappings" [
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
    path: "/course-mappings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find course mappings by externalCourseId
#
# GET /course-mappings/externalcourse/{externalCourseId}
# Returns: list<string>
export def "get-course-mappings-externalcourse-external-course-id" [
  external_course_id: string
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
    path: "/course-mappings/externalcourse/{externalCourseId}"
    path_params: [{name: externalCourseId, var: external_course_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_course_id: $external_course_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find course mappings by offeringId
#
# GET /course-mappings/{offeringId}
# Returns: list<string>
export def "get-course-mappings-offering-id" [
  offering_id: string
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
    path: "/course-mappings/{offeringId}"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove course mapping
#
# DELETE /course-mappings/{offeringId}/{externalCourseId}
# Returns: list<string>
export def "delete-course-mappings-offering-id-external-course-id" [
  offering_id: string
  external_course_id: string
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
    method: delete
    path: "/course-mappings/{offeringId}/{externalCourseId}"
    path_params: [{name: offeringId, var: offering_id}, {name: externalCourseId, var: external_course_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, external_course_id: $external_course_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add course mapping
#
# PUT /course-mappings/{offeringId}/{externalCourseId}
# Returns: list<string>
export def "put-course-mappings-offering-id-external-course-id" [
  offering_id: string
  external_course_id: string
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
    method: put
    path: "/course-mappings/{offeringId}/{externalCourseId}"
    path_params: [{name: offeringId, var: offering_id}, {name: externalCourseId, var: external_course_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, external_course_id: $external_course_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find courses
#
# GET /courses
# Returns: table<coverImageUrl: string, createdAt: string, id: string, metadata: record<learning_outcomes: list>, name: string>
export def "get-courses" [
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
    path: "/courses"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find course by contentId
#
# GET /courses/{contentId}
# Returns: record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>
export def "get-courses-content-id" [
  content_id: string
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
    path: "/courses/{contentId}"
    path_params: [{name: contentId, var: content_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find activations for a contentId
#
# GET /courses/{contentId}/activations
# Returns: record<end: string, id: string, info: string, learnersCount: string, metadata: record<rootContentId: string>, name: string, start: string>
export def "get-courses-content-id-activations" [
  content_id: string
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
    path: "/courses/{contentId}/activations"
    path_params: [{name: contentId, var: content_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update course category
#
# PUT /courses/{contentId}/metadata/category
# Returns: record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>
export def "put-courses-content-id-metadata-category" [
  content_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/courses/{contentId}/metadata/category"
    path_params: [{name: contentId, var: content_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update course level
#
# PUT /courses/{contentId}/metadata/level
# Returns: record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>
export def "put-courses-content-id-metadata-level" [
  content_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/courses/{contentId}/metadata/level"
    path_params: [{name: contentId, var: content_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: level, var: level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update course tags
#
# PUT /courses/{contentId}/metadata/tags
# Returns: record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>
export def "put-courses-content-id-metadata-tags" [
  content_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/courses/{contentId}/metadata/tags"
    path_params: [{name: contentId, var: content_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update course topic
#
# PUT /courses/{contentId}/metadata/topic
# Returns: record<coverImageUrl: string, createdAt: string, id: string, metadata: record<category: string, learning_outcomes: list<record>, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, tasksEnabled: bool>
export def "put-courses-content-id-metadata-topic" [
  content_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/courses/{contentId}/metadata/topic"
    path_params: [{name: contentId, var: content_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: topic, var: topic}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find users who have access to the contentId provided
#
# GET /courses/{contentId}/permissions
# Returns: record<email: string, isBuilder: bool, isReviewer: bool, name: string>
export def "get-courses-content-id-permissions" [
  content_id: string
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
    path: "/courses/{contentId}/permissions"
    path_params: [{name: contentId, var: content_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_id: $content_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update course access
#
# POST /courses/{rootContentId}/permissions/{userEmail}
# Returns: record<contentId: string>
export def "post-courses-root-content-id-permissions-user-email" [
  root_content_id: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-builder: oneof<nothing, bool> # default: true
  --is-reviewer: oneof<nothing, bool> # default: false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/courses/{rootContentId}/permissions/{userEmail}"
    path_params: [{name: rootContentId, var: root_content_id}, {name: userEmail, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: isBuilder, var: is_builder}, {name: isReviewer, var: is_reviewer}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    root_content_id: $root_content_id, user_email: $user_email, is_builder: $is_builder, is_reviewer: $is_reviewer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find current, past and future offerings
#
# GET /offerings
# Returns: table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "get-offerings" [
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
    path: "/offerings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create offering
#
# POST /offerings
# Returns: record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "post-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --badge: record # shape: {badgeExpiry?: record, description?: string, requiresApproval?: bool, title?: string}
  --content-id: string # The identifier for a specific version of a course
  --create-default-channels: oneof<nothing, bool> # default: false
  --description: string
  --early-close-off-date: string # format: date-time
  --end: string # format: date-time
  --has-early-close-off: oneof<nothing, bool>
  --identifier: string
  --is-readonly: oneof<nothing, bool>
  --metadata: record # shape: {category?: string, level?: string, tags?: list<string>, topic?: string}
  --name: string
  --root-content-id: string # Every time a course is republished it's assigned a new contentId. rootContentId is the first original contentId associated with a course.
  start: string # format: date-time
  --trailer-video-url: string
  --use-relative-dates: oneof<nothing, bool> # default: false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offerings"
    body: {content_type: "application/json", kind: json, fields: [{name: badge, var: badge}, {name: contentId, var: content_id}, {name: createDefaultChannels, var: create_default_channels}, {name: description, var: description}, {name: earlyCloseOffDate, var: early_close_off_date}, {name: end, var: end}, {name: hasEarlyCloseOff, var: has_early_close_off}, {name: identifier, var: identifier}, {name: isReadonly, var: is_readonly}, {name: metadata, var: metadata}, {name: name, var: name}, {name: rootContentId, var: root_content_id}, {name: start, var: start}, {name: trailerVideoUrl, var: trailer_video_url}, {name: useRelativeDates, var: use_relative_dates}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    badge: $badge, content_id: $content_id, create_default_channels: $create_default_channels, description: $description, early_close_off_date: $early_close_off_date, end: $end, has_early_close_off: $has_early_close_off, identifier: $identifier, is_readonly: $is_readonly, metadata: $metadata, name: $name, root_content_id: $root_content_id, start: $start, trailer_video_url: $trailer_video_url, use_relative_dates: $use_relative_dates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find active offerings
#
# GET /offerings/current
# Returns: table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "get-offerings-current" [
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
    path: "/offerings/current"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find scheduled offerings
#
# GET /offerings/future
# Returns: table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "get-offerings-future" [
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
    path: "/offerings/future"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find offerings where info field matches the specified textPattern
#
# GET /offerings/info/{textPattern}
# Returns: table<contentId: string, end: string, id: string, info: string, learnersCount: float, metadata: record<rootContentId: string>, name: string, start: string>
export def "get-offerings-info-text-pattern" [
  text_pattern: string
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
    path: "/offerings/info/{textPattern}"
    path_params: [{name: textPattern, var: text_pattern}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    text_pattern: $text_pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find past offerings
#
# GET /offerings/past
# Returns: table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "get-offerings-past" [
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
    path: "/offerings/past"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Offerings summary
#
# GET /offerings/summary
# Returns: table<contentId: string, end: string, id: string, info: string, learnersCount: float, metadata: record<rootContentId: string>, name: string, start: string>
export def "get-offerings-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: string # Returns only the first n results. (default: 50)
  --orderby: string # Sorts the results.
  --filter: string # Filters the results, based on a Boolean condition.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/offerings/summary"
    query: [{name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    top: $top, orderby: $orderby, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find offering by ID
#
# GET /offerings/{offeringId}
# Returns: record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "get-offerings-offering-id" [
  offering_id: string
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
    path: "/offerings/{offeringId}"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update offering
#
# PATCH /offerings/{offeringId}
# Returns: record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "patch-offerings-offering-id" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --badge: record # shape: {badgeExpiry?: record, description?: string, requiresApproval?: bool, title?: string}
  --content-id: string # The identifier for a specific version of a course
  --description: string
  --early-close-off-date: string # format: date-time
  --end: string # format: date-time
  --has-early-close-off: oneof<nothing, bool>
  --identifier: string
  --is-readonly: oneof<nothing, bool>
  --metadata: record # shape: {category?: string, level?: string, tags?: list<string>, topic?: string}
  --name: string
  --overview: string
  --root-content-id: string # Every time a course is republished it is assigned a new contentId. rootContentId is the first original contentId associated with a course.
  --start: string # format: date-time
  --trailer-video-url: string
  --use-relative-dates: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/offerings/{offeringId}"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: badge, var: badge}, {name: contentId, var: content_id}, {name: description, var: description}, {name: earlyCloseOffDate, var: early_close_off_date}, {name: end, var: end}, {name: hasEarlyCloseOff, var: has_early_close_off}, {name: identifier, var: identifier}, {name: isReadonly, var: is_readonly}, {name: metadata, var: metadata}, {name: name, var: name}, {name: overview, var: overview}, {name: rootContentId, var: root_content_id}, {name: start, var: start}, {name: trailerVideoUrl, var: trailer_video_url}, {name: useRelativeDates, var: use_relative_dates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, badge: $badge, content_id: $content_id, description: $description, early_close_off_date: $early_close_off_date, end: $end, has_early_close_off: $has_early_close_off, identifier: $identifier, is_readonly: $is_readonly, metadata: $metadata, name: $name, overview: $overview, root_content_id: $root_content_id, start: $start, trailer_video_url: $trailer_video_url, use_relative_dates: $use_relative_dates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find offering's activities
#
# GET /offerings/{offeringId}/activities/openresponse
# Returns: table<activityId: string, time: float, title: string>
export def "get-offerings-offering-id-activities-openresponse" [
  offering_id: string
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
    path: "/offerings/{offeringId}/activities/openresponse"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find open response activity attempts
#
# GET /offerings/{offeringId}/analytics/activities/responses
# Returns: table<activityId: string, activityType: string, feedback: record<facilitatorEmail: string, text: string>, learnerEmail: string, offeringId: string, responseText: string, uploadedFiles: record<filename: string, mimetype: string, size: string, url: string>>
export def "get-offerings-offering-id-analytics-activities-responses" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/activities/responses"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find comments
#
# GET /offerings/{offeringId}/analytics/channels/{channelId}/comments
# Returns: table<content: string, createdAt: string, email: string, id: string, isFacilitatorPost: bool, moderation: record<isMuted: bool, moderator: record, reason: string>, parentCommentId: string, postId: string>
export def "get-offerings-offering-id-analytics-channels-channel-id-comments" [
  offering_id: string
  channel_id: string
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
    path: "/offerings/{offeringId}/analytics/channels/{channelId}/comments"
    path_params: [{name: offeringId, var: offering_id}, {name: channelId, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find posts
#
# GET /offerings/{offeringId}/analytics/channels/{channelId}/posts
# Returns: table<attachments: list<record>, content: string, createdAt: string, email: string, id: string, isFacilitatorPost: bool, moderation: record<isMuted: bool, moderator: record, reason: string>, title: string>
export def "get-offerings-offering-id-analytics-channels-channel-id-posts" [
  offering_id: string
  channel_id: string
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
    path: "/offerings/{offeringId}/analytics/channels/{channelId}/posts"
    path_params: [{name: offeringId, var: offering_id}, {name: channelId, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find replies
#
# GET /offerings/{offeringId}/analytics/channels/{channelId}/replies
# Returns: table<content: string, createdAt: string, email: string, id: string, isFacilitatorPost: bool, moderation: record<isMuted: bool, moderator: record, reason: string>, parentCommentId: string, postId: string>
export def "get-offerings-offering-id-analytics-channels-channel-id-replies" [
  offering_id: string
  channel_id: string
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
    path: "/offerings/{offeringId}/analytics/channels/{channelId}/replies"
    path_params: [{name: offeringId, var: offering_id}, {name: channelId, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learner progress in a specified offering
#
# GET /offerings/{offeringId}/analytics/learners-progress
# Returns: table<completion: string, courseId: string, email: string, firstName: string, lastLoggedInAt: string, lastName: string, personId: string>
export def "get-offerings-offering-id-analytics-learners-progress" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/learners-progress"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find assessment marks
#
# GET /offerings/{offeringId}/analytics/marks/assignments
# Returns: table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, mark: string, markFeedback: string, markedBy: string, markedByEvaluator: bool, markedByFacilitator: bool, markedByMarker: bool, markedDateTime: string, submissionDateTime: string>
export def "get-offerings-offering-id-analytics-marks-assignments" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/marks/assignments"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find quiz marks
#
# GET /offerings/{offeringId}/analytics/marks/quizzes
# Returns: table<attempts: int, lastAttemptAt: string, learnerEmail: string, learnerFullname: string, learnerPersonId: string, mark: string, quizId: string, quizTitle: string>
export def "get-offerings-offering-id-analytics-marks-quizzes" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/marks/quizzes"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find all pulse IDs in the specified offering
#
# GET /offerings/{offeringId}/analytics/pulses
# Returns: list<string>
export def "get-offerings-offering-id-analytics-pulses" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/pulses"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find pulses by offeringId
#
# GET /offerings/{offeringId}/analytics/pulses/responses
# Returns: table<learnerFirstName: string, learnerId: string, learnerLastName: string, pulseBaseId: string, pulseInstanceId: string, pulseQuestion: string, pulseRunDurationMinutes: int, pulseRunStart: string, pulseType: string, response: record<multiChoiceAnswer: list, spatialAnswer: list, textAnswer: string>, responseTime: string>
export def "get-offerings-offering-id-analytics-pulses-responses" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pulse-type: string@pulse-type-completer # Filter pulse responses by type.
  --response-time: string # Filter pulse responses by responseTime. Lower then (`lt`), lower then or equal (`lte`), greater then (`gt`) and greater then or equal (`gte`) operators are available. Example of filtering by time range __gte__2017-03-14T07:30:00Z__
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/offerings/{offeringId}/analytics/pulses/responses"
    path_params: [{name: offeringId, var: offering_id}]
    query: [{name: pulseType, var: pulse_type}, {name: responseTime, var: response_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, pulse_type: $pulse_type, response_time: $response_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find pulses by offeringId and pulseId
#
# GET /offerings/{offeringId}/analytics/pulses/{pulseId}/responses
# Returns: table<learnerFirstName: string, learnerId: string, learnerLastName: string, pulseBaseId: string, pulseInstanceId: string, pulseQuestion: string, pulseRunDurationMinutes: int, pulseRunStart: string, pulseType: string, response: record<multiChoiceAnswer: list, spatialAnswer: list, textAnswer: string>, responseTime: string>
export def "get-offerings-offering-id-analytics-pulses-pulse-id-responses" [
  offering_id: string
  pulse_id: string
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
    path: "/offerings/{offeringId}/analytics/pulses/{pulseId}/responses"
    path_params: [{name: offeringId, var: offering_id}, {name: pulseId, var: pulse_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, pulse_id: $pulse_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find shared social notes in an offering
#
# GET /offerings/{offeringId}/analytics/social-notes
# Returns: table<email: string, firstName: string, lastName: string, pageId: string, personId: string, social-note-content: string, social-note-paragraphId: string, userId: string>
export def "get-offerings-offering-id-analytics-social-notes" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/social-notes"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find submissions to assessments, including marks if any
#
# GET /offerings/{offeringId}/analytics/submissions/assignments
# Returns: table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, mark: string, markFeedback: string, markedBy: string, markedByEvaluator: bool, markedByFacilitator: bool, markedByMarker: bool, markedDateTime: string, submissionDateTime: string>
export def "get-offerings-offering-id-analytics-submissions-assignments" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/submissions/assignments"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find submissions to a specified open response assessment, including marks if any
#
# GET /offerings/{offeringId}/analytics/submissions/open-response/{assessmentId}
# Returns: table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, files: list<record>, html: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, marks: list<record>, status: string, submissionDateTime: string>
export def "get-offerings-offering-id-analytics-submissions-open-response-assessment-id" [
  offering_id: string
  assessment_id: string
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
    path: "/offerings/{offeringId}/analytics/submissions/open-response/{assessmentId}"
    path_params: [{name: offeringId, var: offering_id}, {name: assessmentId, var: assessment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, assessment_id: $assessment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a learner's submission to a specified assessment, including marks if any
#
# GET /offerings/{offeringId}/analytics/submissions/{userEmail}/assignments/{assessmentId}
# Returns: table<assessmentId: string, assessmentItemDetails: string, assessmentItemName: string, courseName: string, files: list<record>, html: string, learnerEmail: string, learnerFirstName: string, learnerLastName: string, learnerPersonId: string, marks: list<record>, status: string, submissionDateTime: string>
export def "get-offerings-offering-id-analytics-submissions-user-email-assignments-assessment-id" [
  offering_id: string
  user_email: string
  assessment_id: string
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
    path: "/offerings/{offeringId}/analytics/submissions/{userEmail}/assignments/{assessmentId}"
    path_params: [{name: offeringId, var: offering_id}, {name: userEmail, var: user_email}, {name: assessmentId, var: assessment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, user_email: $user_email, assessment_id: $assessment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find unit reactions
#
# GET /offerings/{offeringId}/analytics/unit-reactions
# Returns: table<feedback: record<thumbs-down: float, thumbs-up: float>, pageId: bool>
export def "get-offerings-offering-id-analytics-unit-reactions" [
  offering_id: string
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
    path: "/offerings/{offeringId}/analytics/unit-reactions"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find offering's assessments
#
# GET /offerings/{offeringId}/assessments
# Returns: table<content: string, documents: list<record>, dueDate: string, durationMinutes: int, filename: string, hidden: bool, id: string, markNumber: string, markType: string, maxAttempts: int, openDate: string, pid: string, points: string, themes: list<record>, title: string, totalQuestions: int, totalThemes: int, type: string>
export def "get-offerings-offering-id-assessments" [
  offering_id: string
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
    path: "/offerings/{offeringId}/assessments"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update assessment details
#
# PATCH /offerings/{offeringId}/assessments/{assessmentId}
# Returns: record<content: string, documents: table<createdAt: string, filename: string, id: string, mimetype: string, size: int, url: string>, dueDate: string, durationMinutes: int, filename: string, hidden: bool, id: string, markNumber: string, markType: string, maxAttempts: int, openDate: string, pid: string, points: string, themes: table<filter: string, numberOfQuestions: string>, title: string, totalQuestions: int, totalThemes: int, type: string>
export def "patch-offerings-offering-id-assessments-assessment-id" [
  offering_id: string
  assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string
  --due-date: string # format: date-time
  --mark-number: string
  --mark-type: string
  --open-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/offerings/{offeringId}/assessments/{assessmentId}"
    path_params: [{name: offeringId, var: offering_id}, {name: assessmentId, var: assessment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: dueDate, var: due_date}, {name: markNumber, var: mark_number}, {name: markType, var: mark_type}, {name: openDate, var: open_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, assessment_id: $assessment_id, content: $content, due_date: $due_date, mark_number: $mark_number, mark_type: $mark_type, open_date: $open_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove assessment document
#
# DELETE /offerings/{offeringId}/assessments/{assessmentId}/documents/{documentId}
export def "delete-offerings-offering-id-assessments-assessment-id-documents-document-id" [
  offering_id: string
  assessment_id: string
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
    path: "/offerings/{offeringId}/assessments/{assessmentId}/documents/{documentId}"
    path_params: [{name: offeringId, var: offering_id}, {name: assessmentId, var: assessment_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    offering_id: $offering_id, assessment_id: $assessment_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the due dates for a learner's quiz attempt
#
# PATCH /offerings/{offeringId}/assessments/{assessmentId}/{userEmail}
export def "patch-offerings-offering-id-assessments-assessment-id-user-email" [
  offering_id: string
  assessment_id: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --due-date: string # format: date-time
]: any -> any {
  $in | http-request {
    method: patch
    path: "/offerings/{offeringId}/assessments/{assessmentId}/{userEmail}"
    path_params: [{name: offeringId, var: offering_id}, {name: assessmentId, var: assessment_id}, {name: userEmail, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: dueDate, var: due_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    offering_id: $offering_id, assessment_id: $assessment_id, user_email: $user_email, due_date: $due_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find offering badges
#
# GET /offerings/{offeringId}/badges
# Returns: record<badgeExpiry: record<expirationDate: string, expires: bool, expiryType: string, timeframeAmount: float, timeframeUnit: string>, badgeUrl: string, criterias: record<hasCompletedCourse: bool, hasPassedMandatoryAssessedQuizzes: bool>, description: string, openBadge: record<criteria: record<narrative: string>, description: string, id: string, image: string, issuer: string, name: string, type: string>, title: string>
export def "get-offerings-offering-id-badges" [
  offering_id: string
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
    path: "/offerings/{offeringId}/badges"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find channels
#
# GET /offerings/{offeringId}/channels
# Returns: table<id: string, isBroadcastOnly: bool, title: string>
export def "get-offerings-offering-id-channels" [
  offering_id: string
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
    path: "/offerings/{offeringId}/channels"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add channel
#
# POST /offerings/{offeringId}/channels
# Returns: record<id: string, isBroadcastOnly: bool, title: string>
export def "post-offerings-offering-id-channels" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-broadcast-only: oneof<nothing, bool> # default: false
  title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offerings/{offeringId}/channels"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: isBroadcastOnly, var: is_broadcast_only}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    offering_id: $offering_id, is_broadcast_only: $is_broadcast_only, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update channel
#
# PATCH /offerings/{offeringId}/channels/{channelId}
# Returns: record<id: string, isBroadcastOnly: bool, title: string>
export def "patch-offerings-offering-id-channels-channel-id" [
  offering_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: record # shape: {autoAssign?: bool}
  --group-discussion: oneof<nothing, bool>
  --is-broadcast-only: oneof<nothing, bool>
  --private-support: oneof<nothing, bool>
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/offerings/{offeringId}/channels/{channelId}"
    path_params: [{name: offeringId, var: offering_id}, {name: channelId, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: group, var: group}, {name: groupDiscussion, var: group_discussion}, {name: isBroadcastOnly, var: is_broadcast_only}, {name: privateSupport, var: private_support}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, channel_id: $channel_id, group: $group, group_discussion: $group_discussion, is_broadcast_only: $is_broadcast_only, private_support: $private_support, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove learners from a group channel
#
# DELETE /offerings/{offeringId}/channels/{channelId}/learners
export def "delete-offerings-offering-id-channels-channel-id-learners" [
  offering_id: string
  channel_id: string
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
]: any -> any {
  $in | http-request {
    method: delete
    path: "/offerings/{offeringId}/channels/{channelId}/learners"
    path_params: [{name: offeringId, var: offering_id}, {name: channelId, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    offering_id: $offering_id, channel_id: $channel_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learners in a group channel
#
# GET /offerings/{offeringId}/channels/{channelId}/learners
# Returns: record<id: string, isBroadcastOnly: bool, title: string>
export def "get-offerings-offering-id-channels-channel-id-learners" [
  offering_id: string
  channel_id: string
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
    path: "/offerings/{offeringId}/channels/{channelId}/learners"
    path_params: [{name: offeringId, var: offering_id}, {name: channelId, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add learners to a group channel
#
# POST /offerings/{offeringId}/channels/{channelId}/learners
export def "post-offerings-offering-id-channels-channel-id-learners" [
  offering_id: string
  channel_id: string
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/offerings/{offeringId}/channels/{channelId}/learners"
    path_params: [{name: offeringId, var: offering_id}, {name: channelId, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    offering_id: $offering_id, channel_id: $channel_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find assessment groups
#
# GET /offerings/{offeringId}/groups
# Returns: table<createdAt: string, id: string, title: string>
export def "get-offerings-offering-id-groups" [
  offering_id: string
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
    path: "/offerings/{offeringId}/groups"
    path_params: [{name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an assessment group
#
# POST /offerings/{offeringId}/groups
# Returns: record<createdAt: string, id: string, title: string>
export def "post-offerings-offering-id-groups" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offerings/{offeringId}/groups"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    offering_id: $offering_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learners in an assessment group
#
# GET /offerings/{offeringId}/groups/{groupId}/learners
# Returns: table<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string, mobile: string>>
export def "get-offerings-offering-id-groups-group-id-learners" [
  offering_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/offerings/{offeringId}/groups/{groupId}/learners"
    path_params: [{name: offeringId, var: offering_id}, {name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a learner to an assessment group
#
# POST /offerings/{offeringId}/groups/{groupId}/learners
# Returns: record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>
export def "post-offerings-offering-id-groups-group-id-learners" [
  offering_id: string
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
  --email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offerings/{offeringId}/groups/{groupId}/learners"
    path_params: [{name: offeringId, var: offering_id}, {name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    offering_id: $offering_id, group_id: $group_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a learner from an assessment group
#
# DELETE /offerings/{offeringId}/groups/{groupId}/learners/{userEmail}
export def "delete-offerings-offering-id-groups-group-id-learners-user-email" [
  offering_id: string
  group_id: string
  user_email: string
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
    path: "/offerings/{offeringId}/groups/{groupId}/learners/{userEmail}"
    path_params: [{name: offeringId, var: offering_id}, {name: groupId, var: group_id}, {name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    offering_id: $offering_id, group_id: $group_id, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learners with assessments pending x days before due date within the specified offeringId
#
# GET /offerings/{offeringId}/learners/pending-submission
# Returns: table<content: string, documents: list<record>, dueDate: string, durationMinutes: int, filename: string, hidden: bool, id: string, markNumber: string, markType: string, maxAttempts: int, offeringId: string, offeringName: string, openDate: string, pid: string, points: string, themes: list<record>, title: string, totalQuestions: int, totalThemes: int, type: string, users: list<record>>
export def "get-offerings-offering-id-learners-pending-submission" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days: string # days to assessment due date. Default is 3 days
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/offerings/{offeringId}/learners/pending-submission"
    path_params: [{name: offeringId, var: offering_id}]
    query: [{name: days, var: days}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, days: $days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update offering category metadata
#
# PUT /offerings/{offeringId}/metadata/category
# Returns: record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "put-offerings-offering-id-metadata-category" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/offerings/{offeringId}/metadata/category"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update offering level metadata
#
# PUT /offerings/{offeringId}/metadata/level
# Returns: record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "put-offerings-offering-id-metadata-level" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/offerings/{offeringId}/metadata/level"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: level, var: level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update offering tags metadata
#
# PUT /offerings/{offeringId}/metadata/tags
# Returns: record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "put-offerings-offering-id-metadata-tags" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/offerings/{offeringId}/metadata/tags"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update offering topic metadata
#
# PUT /offerings/{offeringId}/metadata/topic
# Returns: record<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list<string>, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "put-offerings-offering-id-metadata-topic" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/offerings/{offeringId}/metadata/topic"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: topic, var: topic}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find offering's users
#
# GET /offerings/{offeringId}/users
# Returns: table<avatarUrl: string, email: string, evaluatedBy: list<string>, evaluates: list<string>, firstName: string, id: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, markedBy: list<string>, marks: list<string>, personId: string, profile: record<displayName: string, mobile: string>>
export def "get-offerings-offering-id-users" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --facilitators: string@facilitators-completer # If true, facilitators are included in the results. (default: true)
  --learners: string@learners-completer # If true, learners are included in the results. (default: true)
  --markers: string@markers-completer # If true, markers are included in the results. (default: true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/offerings/{offeringId}/users"
    path_params: [{name: offeringId, var: offering_id}]
    query: [{name: facilitators, var: facilitators}, {name: learners, var: learners}, {name: markers, var: markers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, facilitators: $facilitators, learners: $learners, markers: $markers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds user to the offering
#
# POST /offerings/{offeringId}/users
# Returns: table<email: string, firstName: string, invite: record<url: string>, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>
export def "post-offerings-offering-id-users" [
  offering_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offerings/{offeringId}/users"
    path_params: [{name: offeringId, var: offering_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201, 207]
    auth: bearer
  } {
    offering_id: $offering_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove learners from coach's marking list
#
# DELETE /offerings/{offeringId}/users/{markerEmail}/marks
# Returns: table<email: string, firstName: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>
export def "delete-offerings-offering-id-users-marker-email-marks" [
  offering_id: string
  marker_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/offerings/{offeringId}/users/{markerEmail}/marks"
    path_params: [{name: offeringId, var: offering_id}, {name: markerEmail, var: marker_email}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, marker_email: $marker_email, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find Learners marked by a coach
#
# GET /offerings/{offeringId}/users/{markerEmail}/marks
# Returns: table<email: string, firstName: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>
export def "get-offerings-offering-id-users-marker-email-marks" [
  offering_id: string
  marker_email: string
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
    path: "/offerings/{offeringId}/users/{markerEmail}/marks"
    path_params: [{name: offeringId, var: offering_id}, {name: markerEmail, var: marker_email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, marker_email: $marker_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add learners to be marked by a coach
#
# POST /offerings/{offeringId}/users/{markerEmail}/marks
# Returns: table<email: string, firstName: string, isFacilitator: bool, isMarker: bool, isReadonly: bool, lastName: string, metadata: record<tags: list>, personId: string, profile: record<displayName: string>, sendInvite: bool, sendNotificationEmail: bool>
export def "post-offerings-offering-id-users-marker-email-marks" [
  offering_id: string
  marker_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offerings/{offeringId}/users/{markerEmail}/marks"
    path_params: [{name: offeringId, var: offering_id}, {name: markerEmail, var: marker_email}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, marker_email: $marker_email, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes user from the offering
#
# DELETE /offerings/{offeringId}/users/{userEmail}
export def "delete-offerings-offering-id-users-user-email" [
  offering_id: string
  user_email: string
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
    path: "/offerings/{offeringId}/users/{userEmail}"
    path_params: [{name: offeringId, var: offering_id}, {name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    offering_id: $offering_id, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset user's assessment to draft state
#
# DELETE /offerings/{offeringId}/users/{userEmail}/assessments/{assessmentId}
export def "delete-offerings-offering-id-users-user-email-assessments-assessment-id" [
  offering_id: string
  user_email: string
  assessment_id: string
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
    path: "/offerings/{offeringId}/users/{userEmail}/assessments/{assessmentId}"
    path_params: [{name: offeringId, var: offering_id}, {name: userEmail, var: user_email}, {name: assessmentId, var: assessment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    offering_id: $offering_id, user_email: $user_email, assessment_id: $assessment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Award badge
#
# POST /offerings/{offeringId}/users/{userEmail}/badges/award
# Returns: record<awarded: bool, badgeId: string, badgeUrl: string>
export def "post-offerings-offering-id-users-user-email-badges-award" [
  offering_id: string
  user_email: string
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
    path: "/offerings/{offeringId}/users/{userEmail}/badges/award"
    path_params: [{name: offeringId, var: offering_id}, {name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    offering_id: $offering_id, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learner's open response assessment submissions
#
# GET /offerings/{offeringId}/users/{userEmail}/submissions/open-response
# Returns: table<files: list<record>, marks: list<record>, status: string, submittedAt: string, updatedAt: string>
export def "get-offerings-offering-id-users-user-email-submissions-open-response" [
  offering_id: string
  user_email: string
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
    path: "/offerings/{offeringId}/users/{userEmail}/submissions/open-response"
    path_params: [{name: offeringId, var: offering_id}, {name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the current organisation
#
# GET /org
# Returns: record<id: string, name: string>
export def "get-org" [
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
    path: "/org"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new user
#
# POST /users
# Returns: record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # format: email
  --first-name: string
  --last-name: string
  --metadata: record # shape: {tags?: list<string>}
  --person-id: string
  --profile: record # shape: {displayName?: string}
  --send-invite: oneof<nothing, bool> # default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: metadata, var: metadata}, {name: personId, var: person_id}, {name: profile, var: profile}, {name: sendInvite, var: send_invite}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    email: $email, first_name: $first_name, last_name: $last_name, metadata: $metadata, person_id: $person_id, profile: $profile, send_invite: $send_invite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learner progress in all offerings
#
# GET /users/all/progress
# Returns: record<data: record<progress: list<record>>, top: int>
export def "get-users-all-progress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: string # Returns only the first n results. (default: 50)
  --orderby: string # Sorts the results.
  --filter: string # Filters the results, based on a Boolean condition.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/all/progress"
    query: [{name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    top: $top, orderby: $orderby, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find user by email
#
# GET /users/{userEmail}
# Returns: record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>
export def "get-users-user-email" [
  user_email: string
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
    path: "/users/{userEmail}"
    path_params: [{name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user
#
# PATCH /users/{userEmail}
# Returns: record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>
export def "patch-users-user-email" [
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # format: email
  --first-name: string
  --last-name: string
  --metadata: record # shape: {tags?: list<string>}
  --person-id: string
  --profile: record # shape: {displayName?: string}
  --send-invite: oneof<nothing, bool> # default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{userEmail}"
    path_params: [{name: userEmail, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: metadata, var: metadata}, {name: personId, var: person_id}, {name: profile, var: profile}, {name: sendInvite, var: send_invite}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email, email: $email, first_name: $first_name, last_name: $last_name, metadata: $metadata, person_id: $person_id, profile: $profile, send_invite: $send_invite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find user's badges
#
# GET /users/{userEmail}/badges
# Returns: table<awardedAt: string, badgeExpiry: record<expirationDate: string, expires: bool>, badgeUrl: string, criterias: record<hasCompletedCourse: bool, hasPassedMandatoryAssessedQuizzes: bool>, description: string, offeringId: string, openBadge: record<criteria: record, description: string, id: string, image: string, issuer: string, name: string, type: string>, title: string>
export def "get-users-user-email-badges" [
  user_email: string
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
    path: "/users/{userEmail}/badges"
    path_params: [{name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend invitation email
#
# POST /users/{userEmail}/invite-email
export def "post-users-user-email-invite-email" [
  user_email: string
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
    path: "/users/{userEmail}/invite-email"
    path_params: [{name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find user's offerings
#
# GET /users/{userEmail}/offerings
# Returns: table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "get-users-user-email-offerings" [
  user_email: string
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
    path: "/users/{userEmail}/offerings"
    path_params: [{name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the user to the specified offerings as a learner
#
# POST /users/{userEmail}/offerings
# Returns: table<contentId: string, coverImageUrl: string, currency: string, description: string, earlyCloseOffDate: string, end: string, enrollmentLimit: float, hasEarlyCloseOff: bool, id: string, identifier: string, isReadonly: bool, metadata: record<category: string, level: string, rootContentId: string, tags: list, topic: string>, name: string, overview: string, price: float, start: string, tasksEnabled: bool, trailerVideoUrl: string, useRelativeDates: bool>
export def "post-users-user-email-offerings" [
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{userEmail}/offerings"
    path_params: [{name: userEmail, var: user_email}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learner's progress in a specified offering
#
# GET /users/{userEmail}/offerings/{offeringId}/progress
# Returns: record<completion: string, email: string, firstName: string, id: string, lastName: string>
export def "get-users-user-email-offerings-offering-id-progress" [
  user_email: string
  offering_id: string
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
    path: "/users/{userEmail}/offerings/{offeringId}/progress"
    path_params: [{name: userEmail, var: user_email}, {name: offeringId, var: offering_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email, offering_id: $offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add permission to user
#
# POST /users/{userEmail}/permissions/{permissionName}
# Returns: record<avatarUrl: string, email: string, firstAccessAt: string, firstName: string, id: string, invite: record<url: string>, lastAccessAt: string, lastName: string, metadata: record<tags: list<string>>, personId: string, profile: record<displayName: string, mobile: string>>
export def "post-users-user-email-permissions-permission-name" [
  user_email: string
  permission_name: string@permission-name-completer
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
    path: "/users/{userEmail}/permissions/{permissionName}"
    path_params: [{name: userEmail, var: user_email}, {name: permissionName, var: permission_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email, permission_name: $permission_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find learner's progress in offerings
#
# GET /users/{userEmail}/progress
# Returns: record<email: string, firstName: string, id: string, lastName: string, offerings: table<completion: string, id: string>, personId: string>
export def "get-users-user-email-progress" [
  user_email: string
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
    path: "/users/{userEmail}/progress"
    path_params: [{name: userEmail, var: user_email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspend user
#
# PUT /users/{userEmail}/suspend
export def "put-users-user-email-suspend" [
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --suspended: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{userEmail}/suspend"
    path_params: [{name: userEmail, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: suspended, var: suspended}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_email: $user_email, suspended: $suspended
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer a user between offerings
#
# PATCH /users/{userEmail}/transfer
export def "patch-users-user-email-transfer" [
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-offering-id: string
  --send-invite: oneof<nothing, bool>
  --to-offering-id: string
]: any -> any {
  $in | http-request {
    method: patch
    path: "/users/{userEmail}/transfer"
    path_params: [{name: userEmail, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: fromOfferingId, var: from_offering_id}, {name: sendInvite, var: send_invite}, {name: toOfferingId, var: to_offering_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_email: $user_email, from_offering_id: $from_offering_id, send_invite: $send_invite, to_offering_id: $to_offering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
