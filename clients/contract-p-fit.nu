# Auto-generated client for Contract.fit API v1.0
# Source: https://api.apis.guru/v2/specs/contract-p.fit/1.0/openapi.json
# Auth: --token flag or $env.CONTRACT_FIT_API_TOKEN

const CLIENT = {
  base_url: "http://localhost//cfportal.contract-p.fit/api"
  token_env_var: "CONTRACT_FIT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["http://localhost//cfportal.contract-p.fit/api"] }
def auth-scheme-completer [] { ["basic" "bearer" "basic-credentials"] }

# Completers for enum parameters
def event-completer [] { ["document_delete" "document_evaluate" "document_predict" "document_split" "document_text"] }
def what-completer [] { ["original" "ready" "reply_to" "submit"] }
def type-completer [] { ["avg-time" "get-finished-me" "get-finished-team" "get-next-uuid" "get-oldest-escalated-todo" "get-oldest-todo" "get-todo-count" "get-todo-escalated-count" "inbox" "next-document" "prev-document"] }
def how-completer [] { ["FULL" "SOURCE_FILES"] }
def reviewer-completer [] { ["Human" "Machine"] }
def what-completer-1 [] { ["ALL" "DONE"] }
def type-completer-1 [] { ["dropbox" "email" "imap" "office365" "service_bus" "sftp" "smtp" "webhook"] }
def delivery-method-completer [] { ["download" "email"] }
def type-completer-2 [] { ["saml"] }
def type-completer-3 [] { ["oauth" "saml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-auth: "record<authentication_token: string>"
    get-api-keys-resource: "table<active: bool, expire_at: string, roles: list<record>, token: string, user: string>"
    post-api-keys-resource: "record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>"
    get-api-keys-inbox-resource: "table<active: bool, expire_at: string, roles: list<record>, token: string, user: string>"
    post-api-keys-inbox-resource: "record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>"
    get-api-key-resource: "record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>"
    patch-api-key-resource: "record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>"
    post-ephemeral-token-resource: "record<authentication_token: string>"
    post-get-jwt-resource: "record<authentication_token: string>"
    post-token-resource: "record<authentication_token: string>"
    get-connections-resource: "table<event: string, integration: string, routing: list<record>, scope: string, what: string, id: string>"
    post-connections-resource: "record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string>"
    get-connection-resource: "record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string>"
    patch-connection-resource: "record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string>"
    get-data-retention-resource: "table<scope: record<id: string, level: string>, settings: list<record>>"
    get-data-retention-settings-level-id: "record<scope: record<id: string, level: string>, settings: table<age: int, how: string, what: string>>"
    patch-data-retention-resource: "record<scope: record<id: string, level: string>, settings: table<age: int, how: string, what: string>>"
    post-reprocess-document-resource: "record<escalate: record<by: string, since: string, value: bool>, feedback: record, files: table<embedded_attachment: bool, filehash: string, filename: string, leaf: bool, page: int, page_count: int>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: table<by: string, since: string, value: bool>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>>"
    post-document-status-data-resource: "record<escalate: record<by: string, since: string, value: bool>, feedback: record, files: table<embedded_attachment: bool, filehash: string, filename: string, leaf: bool, page: int, page_count: int>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: table<by: string, since: string, value: bool>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>>"
    get-document-workflow-resource: "record<graph: record, links: record, nodes: record>"
    get-formats-doc-types-resource: "record<document_types: table<display_name: string, field_name: string>>"
    patch-format-resource: "record<document_types: table<display_name: string, field_name: string>, id: string, labels: table<category: string, count_in_evaluation: bool, description: string, display_name: string, field_name: string, formula: string, initialized: bool, is_library: bool, mandatory: bool, mandatory_if: record, multiple: bool, options: list, scope: string, type: string, visible: bool, visible_if: record>, name: string, separators: table<name: string, page: int>, table_types: table<collapsed: bool, columns: list, contains_line_items: bool, initialized: bool, label: string, scope: string>>"
    get-format-tag-fields-resource: "record<tag_fields: record>"
    get-inboxes-resource: "table<name: string, project: string, id: string>"
    post-inboxes-resource: "record<name: string, project: string, id: string>"
    get-inbox-resource: "record<name: string, project: string, id: string>"
    patch-inbox-resource: "record<name: string, project: string, id: string>"
    get-inbox-document-resource: "table<escalate: record<by: string, since: string, value: bool>, feedback: record, files: list<record>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: list<record>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>>"
    get-inbox-paginated-resource: "table<page: int, per_page: int, results: list<record>, total: int>"
    get-predictor-settings-resource: "table<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record>, whitelist: record, scope: string>"
    get-predictor-setting-resource: "record<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record<\"*\": record>>, whitelist: record, scope: string>"
    patch-predictor-setting-resource: "record<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record<\"*\": record>>, whitelist: record, scope: string>"
    get-reports-resource: "table<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list, fields: record, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string>"
    post-reports-resource: "record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string>"
    get-report-resource: "record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string>"
    patch-report-resource: "record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string>"
    get-roles-resource: "table<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>"
    post-roles-resource: "record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>"
    get-role-resource: "record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>"
    patch-role-resource: "record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>"
    get-rule-configs-resource: "table<rule_config: record, scope: string>"
    get-rule-config-resource: "record<rule_config: record, scope: string>"
    patch-rule-config-resource: "record<rule_config: record, scope: string>"
    get-setting-samplings-resource: "table<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string>"
    get-setting-sampling-resource: "record<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string>"
    patch-setting-sampling-resource: "record<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string>"
    get-dashboard-settings-atomic-resource: "record<autolearning: bool, dashboard_timeout: int, default_date_range: record, default_inbox_size: record, default_inbox_sorting: record, flexible_filters: list<record>, navigation_menu: record, process_unreadable: bool, sequence_columns_of_inbox: record<columns_headers: list<record>, inline_headers: list<record>>, show_digital_annotations: bool, show_filters: record, show_inbox_actions: record, studio_format_options: record, upload_options: record, welcome_counters: bool, welcome_counters_options: record>"
    patch-dashboard-settings-atomic-resource: "record<autolearning: bool, dashboard_timeout: int, default_date_range: record, default_inbox_size: record, default_inbox_sorting: record, flexible_filters: list<record>, navigation_menu: record, process_unreadable: bool, sequence_columns_of_inbox: record<columns_headers: list<record>, inline_headers: list<record>>, show_digital_annotations: bool, show_filters: record, show_inbox_actions: record, studio_format_options: record, upload_options: record, welcome_counters: bool, welcome_counters_options: record>"
    get-review-settings-atomic-resource: "record<default_zoom: record, first_toolbar: record, lock_expiry: record, review_options: record, second_toolbar: record>"
    patch-review-settings-atomic-resource: "record<default_zoom: record, first_toolbar: record, lock_expiry: record, review_options: record, second_toolbar: record>"
    get-sso-config-resources: "record<extra: record<entity_id: string, specification_url: string>, id: string, provider: string, type: string, url: string>"
    patch-activate-tenant-resource: "record<id: string>"
    get-settings-threshold-resource: "table<thresholds: record<annotations: record, lines: record, sections: record>, scope: string>"
    get-setting-threshold-resource: "record<thresholds: record<annotations: record, lines: record, sections: record>, scope: string>"
    patch-setting-threshold-resource: "record<thresholds: record<annotations: record, lines: record, sections: record>, scope: string>"
    get-users-resource: "table<active: bool, confirmed_at: string, id: string, roles: list<record>, username: string>"
    post-users-resource: "record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>"
    get-me: "record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>"
    get-user-resource: "record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>"
    patch-user-resource: "record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-release-notes" "get-version" "post-auth" "get-api-keys-resource" "post-api-keys-resource" "get-api-keys-inbox-resource" "post-api-keys-inbox-resource" "delete-api-key-resource" "get-api-key-resource" "patch-api-key-resource" "post-ephemeral-token-resource" "post-get-jwt-resource" "post-reset-password" "post-token-resource" "get-connections-resource" "post-connections-resource" "delete-connection-resource" "get-connection-resource" "patch-connection-resource" "get-data-retention-resource" "delete-data-retention-resource" "get-data-retention-settings-level-id" "patch-data-retention-resource" "post-simple-documents-resource" "post-document-custom-output-resource" "post-enrichment-resource" "post-document-data-resource" "post-document-query" "delete-document-delete-resource" "get-document-delete-resource" "post-document-compare-versions-resource" "get-document-transform-resource" "post-document-submit-eval-resource" "get-document-last-version-resource" "get-document-original-file-resource" "get-document-page-image-resource" "get-document-page-image-thumbnail-resource" "post-document-process-table-annotation" "post-reprocess-document-resource" "get-document-reverse-resource" "post-document-status-data-resource" "get-document-text-resource" "get-document-workflow-resource" "post-documents-resource" "patch-document-copy-resource" "patch-document-move-resource" "get-formats-resource" "post-formats-resource" "get-formats-doc-types-resource" "delete-format-resource" "get-format-resource" "patch-format-resource" "get-format-tag-fields-resource" "get-inboxes-resource" "post-inboxes-resource" "delete-inbox-resource" "get-inbox-resource" "patch-inbox-resource" "get-inbox-document-versions-resource" "delete-inbox-document-resource" "get-inbox-document-resource" "get-inbox-paginated-resource" "post-inbox-reprocess-resource" "get-integration-resources" "post-integration-resources" "delete-integration-resource" "get-integration-resource" "patch-integration-resource" "get-email-integration-activation-resource" "get-predictor-settings-resource" "delete-predictor-setting-resource" "get-predictor-setting-resource" "patch-predictor-setting-resource" "get-projects-resource" "post-projects-resource" "delete-project-resource" "get-project-resource" "patch-project-resource" "get-reports-resource" "post-reports-resource" "post-generate-report-resource" "delete-report-resource" "get-report-resource" "patch-report-resource" "post-generate-report-id-resource" "get-roles-resource" "post-roles-resource" "delete-role-resource" "get-role-resource" "patch-role-resource" "get-rule-configs-resource" "post-debug-rule-entity-resource" "post-debug-rule-entity-document-resource" "post-debug-where-to-search" "delete-rule-config-resource" "get-rule-config-resource" "patch-rule-config-resource" "get-setting-samplings-resource" "delete-setting-sampling-resource" "get-setting-sampling-resource" "patch-setting-sampling-resource" "get-dashboard-settings-atomic-resource" "patch-dashboard-settings-atomic-resource" "get-review-settings-atomic-resource" "patch-review-settings-atomic-resource" "get-sso-config-resources" "post-sso-config-resources" "delete-sso-config-resources" "post-oauth-login-resource" "get-usage-stats-resource" "get-stats-resource" "get-automation-blockers-stats" "post-blue-dots-resource" "get-evaluated-versions" "get-processing-stats" "get-volume-stats" "get-accuracy-resource" "get-stp-resource" "get-style-sheet-resource" "post-style-sheet-resource" "get-style-logo-resource" "post-style-logo-resource" "delete-tenant-resource" "patch-activate-tenant-resource" "get-settings-threshold-resource" "delete-setting-threshold-resource" "get-setting-threshold-resource" "patch-setting-threshold-resource" "get-users-resource" "post-users-resource" "get-me" "post-change-password" "delete-user-resource" "get-user-resource" "patch-user-resource" "commands"] | sort) } | get name | first)
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

# GET /about/release_notes
#
# operationId: get_release_notes
export def "get-release-notes" [
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
    path: "/about/release_notes"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /about/version
#
# operationId: get_version
export def "get-version" [
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
    path: "/about/version"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login and retrieve a JWT Token
#
# POST /auth
# Returns: record<authentication_token: string>
# operationId: post_auth
export def "post-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  password: string # the user password
  username: string # the user username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all API-Key
#
# GET /auth/api-key
# Returns: table<active: bool, expire_at: string, roles: list<record>, token: string, user: string>
# operationId: get_api_keys_resource
export def "get-api-keys-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/auth/api-key"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new API Key
#
# POST /auth/api-key
# Returns: record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>
# operationId: post_api_keys_resource
export def "post-api-keys-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --active: oneof<nothing, bool> # Is the API Key active or not
  --expire-at: string # Expiration date (format: date-time)
  roles: list # Roles to grant to this token bearer — item shape: {document_id?: string, inbox?: string, role: string}
  user: string # User to give to the bearer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/api-key"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: expire_at, var: expire_at}, {name: roles, var: roles}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, active: $active, expire_at: $expire_at, roles: $roles, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all API-Keys for this inbox
#
# GET /auth/api-key/inbox/{inbox_id}
# Returns: table<active: bool, expire_at: string, roles: list<record>, token: string, user: string>
# operationId: get_api_keys_inbox_resource
export def "get-api-keys-inbox-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/auth/api-key/inbox/{inbox_id}"
    path_params: [{name: inbox_id, var: inbox_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new API Key on inbox level
#
# POST /auth/api-key/inbox/{inbox_id}
# Returns: record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>
# operationId: post_api_keys_inbox_resource
export def "post-api-keys-inbox-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --active: oneof<nothing, bool> # Is the API Key active or not
  --expire-at: string # Expiration date (format: date-time)
  roles: list # Roles to grant to this token bearer — item shape: {document_id?: string, inbox?: string, role: string}
  user: string # User to give to the bearer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/api-key/inbox/{inbox_id}"
    path_params: [{name: inbox_id, var: inbox_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: expire_at, var: expire_at}, {name: roles, var: roles}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    inbox_id: $inbox_id, x_fields: $x_fields, active: $active, expire_at: $expire_at, roles: $roles, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an API Key
#
# DELETE /auth/api-key/{key}
# operationId: delete_api_key_resource
export def "delete-api-key-resource" [
  key: string
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
    path: "/auth/api-key/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of an API-Key
#
# GET /auth/api-key/{key}
# Returns: record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>
# operationId: get_api_key_resource
export def "get-api-key-resource" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/auth/api-key/{key}"
    path_params: [{name: key, var: key}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    key: $key, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an API-Key
#
# PATCH /auth/api-key/{key}
# Returns: record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string>
# operationId: patch_api_key_resource
export def "patch-api-key-resource" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/auth/api-key/{key}"
    path_params: [{name: key, var: key}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    key: $key, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new ephemeral token
#
# POST /auth/ephemeral
# Returns: record<authentication_token: string>
# operationId: post_ephemeral_token_resource
export def "post-ephemeral-token-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/auth/ephemeral"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new JWT Token
#
# POST /auth/get_JWT
# DEPRECATED
# Returns: record<authentication_token: string>
# operationId: post_get_jwt_resource
@deprecated
export def "post-get-jwt-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --roles: list # the user roles — item shape: {document_id?: string, inbox?: string, role: string}
  username: string # the user username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/get_JWT"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: roles, var: roles}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, roles: $roles, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the user password
#
# POST /auth/reset_password
# operationId: post_reset_password
export def "post-reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # the new user's password
  --body-token: string # the token to reset the password (spec name: token)
  --user-name: string # the username
]: any -> any {
  $in | http-request {
    method: post
    path: "/auth/reset_password"
    body: {content_type: "application/json", kind: json, fields: [{name: new_password, var: new_password}, {name: token, var: body_token}, {name: user_name, var: user_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    new_password: $new_password, body_token: $body_token, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new token
#
# POST /auth/token
# Returns: record<authentication_token: string>
# operationId: post_token_resource
export def "post-token-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --roles: list # the user roles — item shape: {document_id?: string, inbox?: string, role: string}
  username: string # the user username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/token"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: roles, var: roles}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, roles: $roles, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Connections
#
# GET /connections
# Returns: table<event: string, integration: string, routing: list<record>, scope: string, what: string, id: string>
# operationId: get_connections_resource
export def "get-connections-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/connections"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create connection
#
# POST /connections
# Returns: record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string>
# operationId: post_connections_resource
export def "post-connections-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  event: string@event-completer # e.g. document_predict
  integration: string # e.g. abcdef123456789abcdef123
  --routing: list # item shape: {and_conditions?: record, target?: string}
  --scope: string # e.g. abcdef123456789abcdef123
  what: string@what-completer # e.g. original
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connections"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}, {name: integration, var: integration}, {name: routing, var: routing}, {name: scope, var: scope}, {name: what, var: what}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, event: $event, integration: $integration, routing: $routing, scope: $scope, what: $what
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a connection
#
# DELETE /connections/{connection_id}
# operationId: delete_connection_resource
export def "delete-connection-resource" [
  connection_id: string
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
    path: "/connections/{connection_id}"
    path_params: [{name: connection_id, var: connection_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection
#
# GET /connections/{connection_id}
# Returns: record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string>
# operationId: get_connection_resource
export def "get-connection-resource" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connections/{connection_id}"
    path_params: [{name: connection_id, var: connection_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    connection_id: $connection_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update connection
#
# PATCH /connections/{connection_id}
# Returns: record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string>
# operationId: patch_connection_resource
export def "patch-connection-resource" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  event: string@event-completer # e.g. document_predict
  integration: string # e.g. abcdef123456789abcdef123
  --routing: list # item shape: {and_conditions?: record, target?: string}
  --scope: string # e.g. abcdef123456789abcdef123
  what: string@what-completer # e.g. original
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/connections/{connection_id}"
    path_params: [{name: connection_id, var: connection_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}, {name: integration, var: integration}, {name: routing, var: routing}, {name: scope, var: scope}, {name: what, var: what}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    connection_id: $connection_id, x_fields: $x_fields, event: $event, integration: $integration, routing: $routing, scope: $scope, what: $what
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all data retention settings
#
# GET /data_retention_settings
# Returns: table<scope: record<id: string, level: string>, settings: list<record>>
# operationId: get_data_retention_resource
export def "get-data-retention-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/data_retention_settings"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete scoped sampling settings
#
# DELETE /data_retention_settings/{level}/{id}
# operationId: delete_data_retention_resource
export def "delete-data-retention-resource" [
  level: string
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
    path: "/data_retention_settings/{level}/{id}"
    path_params: [{name: level, var: level}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    level: $level, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scoped data retention settings
#
# GET /data_retention_settings/{level}/{id}
# Returns: record<scope: record<id: string, level: string>, settings: table<age: int, how: string, what: string>>
export def "get-data-retention-settings-level-id" [
  level: string
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
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/data_retention_settings/{level}/{id}"
    path_params: [{name: level, var: level}, {name: id, var: id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    level: $level, id: $id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update scoped data retention settings
#
# PATCH /data_retention_settings/{level}/{id}
# Returns: record<scope: record<id: string, level: string>, settings: table<age: int, how: string, what: string>>
# operationId: patch_data_retention_resource
export def "patch-data-retention-resource" [
  level: string
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
  --x-fields: string # An optional fields mask (format: mask)
  --settings: list # item shape: {age?: int, how?: "FULL"|"SOURCE_FILES", what?: "ALL"|"DONE"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/data_retention_settings/{level}/{id}"
    path_params: [{name: level, var: level}, {name: id, var: id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: settings, var: settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    level: $level, id: $id, x_fields: $x_fields, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a new document
#
# POST /documents/
# operationId: post_simple_documents_resource
export def "post-simple-documents-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --experimental: oneof<nothing, bool> # Use the experimental processing workflow
  file: string # File to process (format: binary)
  --inbox-id: string # Inbox to use. Default to the **invoice** inbox
  --key-value-flag: oneof<nothing, bool> # If true the result will only contains mapping of prediction = value (default: true)
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: experimental, var: experimental}, {name: file, var: file}, {name: inbox_id, var: inbox_id}, {name: key_value_flag, var: key_value_flag}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    experimental: $experimental, file: $file, inbox_id: $inbox_id, key_value_flag: $key_value_flag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate custom output for documents
#
# POST /documents/custom_output
# operationId: post_document_custom_output_resource
export def "post-document-custom-output-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: record
  --excel: record # shape: {add_automation_blockers?: bool, add_confidence?: bool, add_text?: bool, enable_key_value: bool, multiple_value_separator?: string}
  --filter: record # shape: {end_date?: string, list?: list<string>, start_date?: string, type: "project"|"inbox"|"document"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/custom_output"
    body: {content_type: "application/json", kind: json, fields: [{name: custom, var: custom}, {name: excel, var: excel}, {name: filter, var: filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    custom: $custom, excel: $excel, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /documents/enrich
#
# operationId: post_enrichment_resource
export def "post-enrichment-resource" [
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/enrich"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /documents/file_query/{data_type}
#
# operationId: post_document_data_resource
export def "post-document-data-resource" [
  data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-ids: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/file_query/{data_type}"
    path_params: [{name: data_type, var: data_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: document_ids, var: document_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    data_type: $data_type, document_ids: $document_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /documents/query/{query_type}
#
# operationId: post_document_query
export def "post-document-query" [
  query_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # shape: {_id?: record, inbox?: record, timing_fields?: record, timings?: record}
  --type: string@type-completer # e.g. inbox
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/query/{query_type}"
    path_params: [{name: query_type, var: query_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: filter, var: filter}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    query_type: $query_type, filter: $filter, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the document
#
# DELETE /documents/{document_id}
# operationId: delete_document_delete_resource
export def "delete-document-delete-resource" [
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
  --how: string@how-completer # default: predicted
]: nothing -> any {
  http-request {
    method: delete
    path: "/documents/{document_id}"
    path_params: [{name: document_id, var: document_id}]
    query: [{name: how, var: how}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, how: $how
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the document
#
# GET /documents/{document_id}
# operationId: get_document_delete_resource
export def "get-document-delete-resource" [
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
    method: get
    path: "/documents/{document_id}"
    path_params: [{name: document_id, var: document_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /documents/{document_id}/compare_versions
#
# operationId: post_document_compare_versions_resource
export def "post-document-compare-versions-resource" [
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
  cmp_version_1: string
  cmp_version_2: string
  name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/{document_id}/compare_versions"
    path_params: [{name: document_id, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cmp_version_1, var: cmp_version_1}, {name: cmp_version_2, var: cmp_version_2}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, cmp_version_1: $cmp_version_1, cmp_version_2: $cmp_version_2, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get custom output formatted document
#
# GET /documents/{document_id}/custom_output
# operationId: get_document_transform_resource
export def "get-document-transform-resource" [
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
    method: get
    path: "/documents/{document_id}/custom_output"
    path_params: [{name: document_id, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a feedback
#
# POST /documents/{document_id}/feedback
# operationId: post_document_submit_eval_resource
export def "post-document-submit-eval-resource" [
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
  --annotations: record # shape: {string?: list}
  --cmp-version: string
  --evaluate: oneof<nothing, bool> # default: true
  --lines: record # shape: {string?: list}
  --name: string
  --sections: list # item shape: {confidence?: int, document_type?: string, format?: string, page: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/{document_id}/feedback"
    path_params: [{name: document_id, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: cmp_version, var: cmp_version}, {name: evaluate, var: evaluate}, {name: lines, var: lines}, {name: name, var: name}, {name: sections, var: sections}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, annotations: $annotations, cmp_version: $cmp_version, evaluate: $evaluate, lines: $lines, name: $name, sections: $sections
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get latest version
#
# GET /documents/{document_id}/last_version
# operationId: get_document_last_version_resource
export def "get-document-last-version-resource" [
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
  --name: string # Return a specific named version, default is latest
  --source: string # human or machine (default either)
  --is-evaluated: oneof<nothing, bool> # Do you want to receive unevaluated version (for display, default) or evaluated (for stats) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/documents/{document_id}/last_version"
    path_params: [{name: document_id, var: document_id}]
    query: [{name: name, var: name}, {name: source, var: source}, {name: is_evaluated, var: is_evaluated}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    document_id: $document_id, name: $name, source: $source, is_evaluated: $is_evaluated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get document original file
#
# GET /documents/{document_id}/original_file
# operationId: get_document_original_file_resource
export def "get-document-original-file-resource" [
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
    method: get
    path: "/documents/{document_id}/original_file"
    path_params: [{name: document_id, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /documents/{document_id}/page/{page_range}
#
# operationId: get_document_page_image_resource
export def "get-document-page-image-resource" [
  document_id: string
  page_range: string
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
    path: "/documents/{document_id}/page/{page_range}"
    path_params: [{name: document_id, var: document_id}, {name: page_range, var: page_range}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, page_range: $page_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /documents/{document_id}/page_thumbnail/{page_range}
#
# operationId: get_document_page_image_thumbnail_resource
export def "get-document-page-image-thumbnail-resource" [
  document_id: string
  page_range: string
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
    path: "/documents/{document_id}/page_thumbnail/{page_range}"
    path_params: [{name: document_id, var: document_id}, {name: page_range, var: page_range}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, page_range: $page_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Process a table-level annotation
#
# POST /documents/{document_id}/process_table_annotation
# operationId: post_document_process_table_annotation
export def "post-document-process-table-annotation" [
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
  --bottom-right: list<int>
  --columns: list # item shape: {field_name?: string, x_bounds?: list<int>}
  --first-row-y-bounds: list<int>
  --header-bottom-y: int
  --name: string
  --top-left: list<int>
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/{document_id}/process_table_annotation"
    path_params: [{name: document_id, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bottom_right, var: bottom_right}, {name: columns, var: columns}, {name: first_row_y_bounds, var: first_row_y_bounds}, {name: header_bottom_y, var: header_bottom_y}, {name: name, var: name}, {name: top_left, var: top_left}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, bottom_right: $bottom_right, columns: $columns, first_row_y_bounds: $first_row_y_bounds, header_bottom_y: $header_bottom_y, name: $name, top_left: $top_left
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule document reprocessing
#
# POST /documents/{document_id}/reprocess
# Returns: record<escalate: record<by: string, since: string, value: bool>, feedback: record, files: table<embedded_attachment: bool, filehash: string, filename: string, leaf: bool, page: int, page_count: int>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: table<by: string, since: string, value: bool>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>>
# operationId: post_reprocess_document_resource
export def "post-reprocess-document-resource" [
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
  --name: string # default: reprocessed
  --reviewer: string@reviewer-completer # If human repcrocessing is triggered, the last version will become the passed version. No processing is done. (default: Machine)
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/documents/{document_id}/reprocess"
    path_params: [{name: document_id, var: document_id}]
    query: [{name: name, var: name}, {name: reviewer, var: reviewer}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, name: $name, reviewer: $reviewer, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /documents/{document_id}/reverse/{page_range}
#
# operationId: get_document_reverse_resource
export def "get-document-reverse-resource" [
  document_id: string
  page_range: string
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
    path: "/documents/{document_id}/reverse/{page_range}"
    path_params: [{name: document_id, var: document_id}, {name: page_range, var: page_range}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, page_range: $page_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update document status
#
# POST /documents/{document_id}/status_data
# Returns: record<escalate: record<by: string, since: string, value: bool>, feedback: record, files: table<embedded_attachment: bool, filehash: string, filename: string, leaf: bool, page: int, page_count: int>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: table<by: string, since: string, value: bool>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>>
# operationId: post_document_status_data_resource
export def "post-document-status-data-resource" [
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
  --x-fields: string # An optional fields mask (format: mask)
  --escalate: record # shape: {by?: string, since?: string, value?: bool}
  --last-version: string
  --lock: record # shape: {by?: string, since?: string, value?: bool}
  --opened-by: record # shape: {by?: string, since?: string, value?: bool}
  --reject: record # shape: {by?: string, since?: string, value?: bool}
  --status-data: record # shape: {archived?: bool, data?: bool, escalate?: bool, feedback?: bool, lock?: bool, ready_accepted?: bool, ready_attempts?: int, reject?: bool, reject_accepted?: bool, reject_attempts?: int, sampling?: bool, submit_accepted?: bool, submit_attempts?: int, success?: bool}
  --submitted: record # shape: {by?: string, since?: string, value?: bool}
  --timings: record # shape: {done_time?: string, feedback_time?: string, processing_period?: float, receive_time?: string, start_time?: string, submit_time?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents/{document_id}/status_data"
    path_params: [{name: document_id, var: document_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: escalate, var: escalate}, {name: last_version, var: last_version}, {name: lock, var: lock}, {name: opened_by, var: opened_by}, {name: reject, var: reject}, {name: status_data, var: status_data}, {name: submitted, var: submitted}, {name: timings, var: timings}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, x_fields: $x_fields, escalate: $escalate, last_version: $last_version, lock: $lock, opened_by: $opened_by, reject: $reject, status_data: $status_data, submitted: $submitted, timings: $timings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the document text
#
# GET /documents/{document_id}/text
# operationId: get_document_text_resource
export def "get-document-text-resource" [
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
    method: get
    path: "/documents/{document_id}/text"
    path_params: [{name: document_id, var: document_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the document Workflow
#
# GET /documents/{document_id}/workflow
# Returns: record<graph: record, links: record, nodes: record>
# operationId: get_document_workflow_resource
export def "get-document-workflow-resource" [
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
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents/{document_id}/workflow"
    path_params: [{name: document_id, var: document_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    document_id: $document_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a new doc to the inbox
#
# POST /documents/{inbox_id}
# operationId: post_documents_resource
export def "post-documents-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --experimental: oneof<nothing, bool> # Use the experimental processing workflow
  file: string # File to process (format: binary)
  --key-value-flag: oneof<nothing, bool> # If true the result will only contains mapping of prediction = value (default: false)
  --sync: oneof<nothing, bool> # Flag enable sync or async processing (default: true)
]: any -> any {
  $in | http-request {
    method: post
    path: "/documents/{inbox_id}"
    path_params: [{name: inbox_id, var: inbox_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: experimental, var: experimental}, {name: file, var: file}, {name: key_value_flag, var: key_value_flag}, {name: sync, var: sync}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, experimental: $experimental, file: $file, key_value_flag: $key_value_flag, sync: $sync
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy documents to another inbox
#
# PATCH /documents/{inbox_id}/copy_inbox
# operationId: patch_document_copy_resource
export def "patch-document-copy-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-ids: list<string>
]: any -> any {
  $in | http-request {
    method: patch
    path: "/documents/{inbox_id}/copy_inbox"
    path_params: [{name: inbox_id, var: inbox_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: document_ids, var: document_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, document_ids: $document_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move documents to another inbox
#
# PATCH /documents/{inbox_id}/move_inbox
# operationId: patch_document_move_resource
export def "patch-document-move-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-ids: list<string>
]: any -> any {
  $in | http-request {
    method: patch
    path: "/documents/{inbox_id}/move_inbox"
    path_params: [{name: inbox_id, var: inbox_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: document_ids, var: document_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, document_ids: $document_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lists of format
#
# GET /formats
# operationId: get_formats_resource
export def "get-formats-resource" [
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
    path: "/formats"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create format
#
# POST /formats
# operationId: post_formats_resource
export def "post-formats-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string
  --document-types: list # item shape: {display_name?: string, field_name: string}
  labels: list # item shape: {category?: "annotation"|"tag"|"separator"|"computed", count_in_evaluation?: bool, description?: string, display_name?: string, field_name: string, formula?: string, initialized?: bool, is_library?: bool, mandatory?: bool, mandatory_if?: record, multiple?: bool, options?: list, scope?: "document"|"page"|"section", type?: "string"|"date"|"integer"|"float"|"currency"|"alphanumeric"|"national_identification_number_be"|"boolean"|"datetime"|"address", visible?: bool, visible_if?: record}
  name: string
  --separators: list # default: [] — item shape: {name: string, page: int}
  --table-types: list # item shape: {collapsed?: bool, columns?: list, contains_line_items?: bool, initialized?: bool, label?: string, scope?: "document"|"page"|"section"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/formats"
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: document_types, var: document_types}, {name: labels, var: labels}, {name: name, var: name}, {name: separators, var: separators}, {name: table_types, var: table_types}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    display_name: $display_name, document_types: $document_types, labels: $labels, name: $name, separators: $separators, table_types: $table_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get supported document_types
#
# GET /formats/document_types
# Returns: record<document_types: table<display_name: string, field_name: string>>
# operationId: get_formats_doc_types_resource
export def "get-formats-doc-types-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/formats/document_types"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the format
#
# DELETE /formats/{format_id}
# operationId: delete_format_resource
export def "delete-format-resource" [
  format_id: string
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
    path: "/formats/{format_id}"
    path_params: [{name: format_id, var: format_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    format_id: $format_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get format attributes
#
# GET /formats/{format_id}
# operationId: get_format_resource
export def "get-format-resource" [
  format_id: string
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
    path: "/formats/{format_id}"
    path_params: [{name: format_id, var: format_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    format_id: $format_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the format
#
# PATCH /formats/{format_id}
# Returns: record<document_types: table<display_name: string, field_name: string>, id: string, labels: table<category: string, count_in_evaluation: bool, description: string, display_name: string, field_name: string, formula: string, initialized: bool, is_library: bool, mandatory: bool, mandatory_if: record, multiple: bool, options: list, scope: string, type: string, visible: bool, visible_if: record>, name: string, separators: table<name: string, page: int>, table_types: table<collapsed: bool, columns: list, contains_line_items: bool, initialized: bool, label: string, scope: string>>
# operationId: patch_format_resource
export def "patch-format-resource" [
  format_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --display-name: string
  --document-types: list # item shape: {display_name?: string, field_name: string}
  --labels: list # item shape: {category?: "annotation"|"tag"|"separator"|"computed", count_in_evaluation?: bool, description?: string, display_name?: string, field_name: string, formula?: string, initialized?: bool, is_library?: bool, mandatory?: bool, mandatory_if?: record, multiple?: bool, options?: list, scope?: "document"|"page"|"section", type?: "string"|"date"|"integer"|"float"|"currency"|"alphanumeric"|"national_identification_number_be"|"boolean"|"datetime"|"address", visible?: bool, visible_if?: record}
  --name: string
  --separators: list # default: [] — item shape: {name: string, page: int}
  --table-types: list # item shape: {collapsed?: bool, columns?: list, contains_line_items?: bool, initialized?: bool, label?: string, scope?: "document"|"page"|"section"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/formats/{format_id}"
    path_params: [{name: format_id, var: format_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: document_types, var: document_types}, {name: labels, var: labels}, {name: name, var: name}, {name: separators, var: separators}, {name: table_types, var: table_types}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    format_id: $format_id, x_fields: $x_fields, display_name: $display_name, document_types: $document_types, labels: $labels, name: $name, separators: $separators, table_types: $table_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags values
#
# GET /formats/{scope}/tag_fields
# Returns: record<tag_fields: record>
# operationId: get_format_tag_fields_resource
export def "get-format-tag-fields-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/formats/{scope}/tag_fields"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of inboxes
#
# GET /inboxes
# Returns: table<name: string, project: string, id: string>
# operationId: get_inboxes_resource
export def "get-inboxes-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/inboxes"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an inbox
#
# POST /inboxes
# Returns: record<name: string, project: string, id: string>
# operationId: post_inboxes_resource
export def "post-inboxes-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  name: string
  project: string # e.g. abcdef123456789abcdef123
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inboxes"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: project, var: project}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, name: $name, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an inbox
#
# DELETE /inboxes/{inbox_id}
# operationId: delete_inbox_resource
export def "delete-inbox-resource" [
  inbox_id: string
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
    path: "/inboxes/{inbox_id}"
    path_params: [{name: inbox_id, var: inbox_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    inbox_id: $inbox_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Inbox attributes
#
# GET /inboxes/{inbox_id}
# Returns: record<name: string, project: string, id: string>
# operationId: get_inbox_resource
export def "get-inbox-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/inboxes/{inbox_id}"
    path_params: [{name: inbox_id, var: inbox_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update inbox
#
# PATCH /inboxes/{inbox_id}
# Returns: record<name: string, project: string, id: string>
# operationId: patch_inbox_resource
export def "patch-inbox-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --name: string
  --project: string # e.g. abcdef123456789abcdef123
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/inboxes/{inbox_id}"
    path_params: [{name: inbox_id, var: inbox_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: project, var: project}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, x_fields: $x_fields, name: $name, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /inboxes/{inbox_id}/document_versions
#
# operationId: get_inbox_document_versions_resource
export def "get-inbox-document-versions-resource" [
  inbox_id: string
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
    path: "/inboxes/{inbox_id}/document_versions"
    path_params: [{name: inbox_id, var: inbox_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete documents
#
# DELETE /inboxes/{inbox_id}/documents
# operationId: delete_inbox_document_resource
export def "delete-inbox-document-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --how: string@how-completer # default: FULL
  --what: string@what-completer-1 # default: ALL
  --start-date: string # format: date-time
  --end-date: string # format: date-time
]: nothing -> any {
  http-request {
    method: delete
    path: "/inboxes/{inbox_id}/documents"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: how, var: how}, {name: what, var: what}, {name: start_date, var: start_date}, {name: end_date, var: end_date}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    inbox_id: $inbox_id, how: $how, what: $what, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get documents in the inbox
#
# GET /inboxes/{inbox_id}/documents
# Returns: table<escalate: record<by: string, since: string, value: bool>, feedback: record, files: list<record>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: list<record>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>>
# operationId: get_inbox_document_resource
export def "get-inbox-document-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/inboxes/{inbox_id}/documents"
    path_params: [{name: inbox_id, var: inbox_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get paginated list of documents in the inbox
#
# GET /inboxes/{inbox_id}/paginated
# Returns: table<page: int, per_page: int, results: list<record>, total: int>
# operationId: get_inbox_paginated_resource
export def "get-inbox-paginated-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number to fetch (default: 1)
  --per-page: int # Results per page (default: 20)
  --start-receive-date: string # format: date-time
  --end-receive-date: string # format: date-time
  --order-by: string # comma seperated list of fields to order by
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/inboxes/{inbox_id}/paginated"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: start_receive_date, var: start_receive_date}, {name: end_receive_date, var: end_receive_date}, {name: order_by, var: order_by}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, page: $page, per_page: $per_page, start_receive_date: $start_receive_date, end_receive_date: $end_receive_date, order_by: $order_by, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule inbox reprocessing
#
# POST /inboxes/{inbox_id}/reprocess
# operationId: post_inbox_reprocess_resource
export def "post-inbox-reprocess-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # default: predicted
  --reviewer: string@reviewer-completer # If human repcrocessing is triggered, the last version will become the passed version. No processing is done. (default: Machine)
  --hints: string # Additional hints as a dictionary. Example: {"VAT_number":{"blacklist":"XXXX.XXX.XXX", "whitelist": ["YYYY.YYY.YYY", "ZZZZ.ZZZ.ZZZ"]}}
]: any -> any {
  $in | http-request {
    method: post
    path: "/inboxes/{inbox_id}/reprocess"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: name, var: name}, {name: reviewer, var: reviewer}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: hints, var: hints}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, name: $name, reviewer: $reviewer, hints: $hints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all integrations
#
# GET /integrations/
# operationId: get_integration_resources
export def "get-integration-resources" [
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
    path: "/integrations/"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create integration
#
# POST /integrations/
# operationId: post_integration_resources
export def "post-integration-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # e.g. webhook
]: any -> any {
  $in | http-request {
    method: post
    path: "/integrations/"
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an integration
#
# DELETE /integrations/{integration_id}
# operationId: delete_integration_resource
export def "delete-integration-resource" [
  integration_id: string
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
    path: "/integrations/{integration_id}"
    path_params: [{name: integration_id, var: integration_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get integration attributes
#
# GET /integrations/{integration_id}
# operationId: get_integration_resource
export def "get-integration-resource" [
  integration_id: string
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
    path: "/integrations/{integration_id}"
    path_params: [{name: integration_id, var: integration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update integration
#
# PATCH /integrations/{integration_id}
# operationId: patch_integration_resource
export def "patch-integration-resource" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # e.g. webhook
]: any -> any {
  $in | http-request {
    method: patch
    path: "/integrations/{integration_id}"
    path_params: [{name: integration_id, var: integration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    integration_id: $integration_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /integrations/{integration_id}/activate
#
# operationId: get_email_integration_activation_resource
export def "get-email-integration-activation-resource" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/integrations/{integration_id}/activate"
    path_params: [{name: integration_id, var: integration_id}]
    query: [{name: secret, var: secret, required: true}]
    accept: ["application/json"]
    ok: [302]
    auth: basic
  } {
    integration_id: $integration_id, secret: $secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all predictor settings
#
# GET /predictor_settings
# Returns: table<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record>, whitelist: record, scope: string>
# operationId: get_predictor_settings_resource
export def "get-predictor-settings-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/predictor_settings"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete scoped predictor settings
#
# DELETE /predictor_settings/{scope}
# operationId: delete_predictor_setting_resource
export def "delete-predictor-setting-resource" [
  scope: string
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
    path: "/predictor_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scoped predictor settings
#
# GET /predictor_settings/{scope}
# Returns: record<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record<"*": record>>, whitelist: record, scope: string>
# operationId: get_predictor_setting_resource
export def "get-predictor-setting-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/predictor_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update scoped predictor settings
#
# PATCH /predictor_settings/{scope}
# Returns: record<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record<"*": record>>, whitelist: record, scope: string>
# operationId: patch_predictor_setting_resource
export def "patch-predictor-setting-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --blacklist: record
  --expected-values: record
  --fallback: record
  --key-value-pairs: record # shape: {classification_cutoff?: int, rule_config?: record, splitting_cutoff?: int, uer_pre_config?: record}
  --table-extraction-settings: record # shape: {field_settings?: record}
  --whitelist: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/predictor_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: blacklist, var: blacklist}, {name: expected_values, var: expected_values}, {name: fallback, var: fallback}, {name: key_value_pairs, var: key_value_pairs}, {name: table_extraction_settings, var: table_extraction_settings}, {name: whitelist, var: whitelist}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields, blacklist: $blacklist, expected_values: $expected_values, fallback: $fallback, key_value_pairs: $key_value_pairs, table_extraction_settings: $table_extraction_settings, whitelist: $whitelist
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of projects
#
# GET /projects
# operationId: get_projects_resource
export def "get-projects-resource" [
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
    path: "/projects"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project
#
# POST /projects
# operationId: post_projects_resource
export def "post-projects-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-document-type: string # This format is chosen as fallback
  --default-format: string # This format is chosen as fallback
  formats: list<string>
  name: string
  --split-into-sections: oneof<nothing, bool> # default: true
  --sub-page-splitting: oneof<nothing, bool> # default: false
  --timeout: int # e.g. 10
]: any -> any {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: default_document_type, var: default_document_type}, {name: default_format, var: default_format}, {name: formats, var: formats}, {name: name, var: name}, {name: split_into_sections, var: split_into_sections, required: true}, {name: sub_page_splitting, var: sub_page_splitting, required: true}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    default_document_type: $default_document_type, default_format: $default_format, formats: $formats, name: $name, split_into_sections: $split_into_sections, sub_page_splitting: $sub_page_splitting, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project
#
# DELETE /projects/{project_id}
# operationId: delete_project_resource
export def "delete-project-resource" [
  project_id: string
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
    path: "/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project attributes
#
# GET /projects/{project_id}
# operationId: get_project_resource
export def "get-project-resource" [
  project_id: string
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
    path: "/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project
#
# PATCH /projects/{project_id}
# operationId: patch_project_resource
export def "patch-project-resource" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-document-type: string # This format is chosen as fallback
  --default-format: string # This format is chosen as fallback
  --formats: list<string>
  --name: string
  --split-into-sections: oneof<nothing, bool>
  --sub-page-splitting: oneof<nothing, bool>
  --timeout: int # e.g. 10
]: any -> any {
  $in | http-request {
    method: patch
    path: "/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: default_document_type, var: default_document_type}, {name: default_format, var: default_format}, {name: formats, var: formats}, {name: name, var: name}, {name: split_into_sections, var: split_into_sections}, {name: sub_page_splitting, var: sub_page_splitting}, {name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    project_id: $project_id, default_document_type: $default_document_type, default_format: $default_format, formats: $formats, name: $name, split_into_sections: $split_into_sections, sub_page_splitting: $sub_page_splitting, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all reports
#
# GET /reports
# Returns: table<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list, fields: record, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string>
# operationId: get_reports_resource
export def "get-reports-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/reports"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create report
#
# POST /reports
# Returns: record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string>
# operationId: post_reports_resource
export def "post-reports-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --annotations: record # shape: {add_text?: bool, include?: bool}
  --automation-blockers: record # shape: {include?: bool}
  --automation-score: record # shape: {include?: bool}
  --automation-what-if: record # shape: {include?: bool}
  --cover: record # shape: {include?: bool}
  --documents: list<string>
  --elapse-time: record # shape: {include?: bool}
  --evaluations: record # shape: {additional_column?: string, include?: bool}
  --field-automation: record # shape: {include?: bool}
  --inboxes: list<string>
  --lines: record # shape: {include?: bool}
  --metadata: record # shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
  --name: string
  --page-classification: record # shape: {include?: bool}
  --projects: list<string>
  --sections: record # shape: {include?: bool}
  --separator: string # default: |
  --sources: list<string> # default: [human, machine]
  --text: record # shape: {include?: bool}
  --version-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: automation_blockers, var: automation_blockers}, {name: automation_score, var: automation_score}, {name: automation_what_if, var: automation_what_if}, {name: cover, var: cover}, {name: documents, var: documents}, {name: elapse_time, var: elapse_time}, {name: evaluations, var: evaluations}, {name: field_automation, var: field_automation}, {name: inboxes, var: inboxes}, {name: lines, var: lines}, {name: metadata, var: metadata}, {name: name, var: name}, {name: page_classification, var: page_classification}, {name: projects, var: projects}, {name: sections, var: sections}, {name: separator, var: separator}, {name: sources, var: sources}, {name: text, var: text}, {name: version_name, var: version_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, annotations: $annotations, automation_blockers: $automation_blockers, automation_score: $automation_score, automation_what_if: $automation_what_if, cover: $cover, documents: $documents, elapse_time: $elapse_time, evaluations: $evaluations, field_automation: $field_automation, inboxes: $inboxes, lines: $lines, metadata: $metadata, name: $name, page_classification: $page_classification, projects: $projects, sections: $sections, separator: $separator, sources: $sources, text: $text, version_name: $version_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate report based on input
#
# POST /reports/generate
# operationId: post_generate_report_resource
export def "post-generate-report-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # shape: {add_text?: bool, include?: bool}
  --automation-blockers: record # shape: {include?: bool}
  --automation-score: record # shape: {include?: bool}
  --automation-what-if: record # shape: {include?: bool}
  --cover: record # shape: {include?: bool}
  --documents: list<string>
  --elapse-time: record # shape: {include?: bool}
  --evaluations: record # shape: {additional_column?: string, include?: bool}
  --field-automation: record # shape: {include?: bool}
  --inboxes: list<string>
  --lines: record # shape: {include?: bool}
  --metadata: record # shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
  --name: string
  --page-classification: record # shape: {include?: bool}
  --projects: list<string>
  --sections: record # shape: {include?: bool}
  --separator: string # default: |
  --sources: list<string> # default: [human, machine]
  --text: record # shape: {include?: bool}
  --version-name: string
  --delivery-method: string@delivery-method-completer # default: download, e.g. email
  --email: string
  --end-date: string # format: date-time
  --start-date: string # format: date-time
]: any -> any {
  $in | http-request {
    method: post
    path: "/reports/generate"
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: automation_blockers, var: automation_blockers}, {name: automation_score, var: automation_score}, {name: automation_what_if, var: automation_what_if}, {name: cover, var: cover}, {name: documents, var: documents}, {name: elapse_time, var: elapse_time}, {name: evaluations, var: evaluations}, {name: field_automation, var: field_automation}, {name: inboxes, var: inboxes}, {name: lines, var: lines}, {name: metadata, var: metadata}, {name: name, var: name}, {name: page_classification, var: page_classification}, {name: projects, var: projects}, {name: sections, var: sections}, {name: separator, var: separator}, {name: sources, var: sources}, {name: text, var: text}, {name: version_name, var: version_name}, {name: delivery_method, var: delivery_method}, {name: email, var: email}, {name: end_date, var: end_date}, {name: start_date, var: start_date}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    annotations: $annotations, automation_blockers: $automation_blockers, automation_score: $automation_score, automation_what_if: $automation_what_if, cover: $cover, documents: $documents, elapse_time: $elapse_time, evaluations: $evaluations, field_automation: $field_automation, inboxes: $inboxes, lines: $lines, metadata: $metadata, name: $name, page_classification: $page_classification, projects: $projects, sections: $sections, separator: $separator, sources: $sources, text: $text, version_name: $version_name, delivery_method: $delivery_method, email: $email, end_date: $end_date, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a report
#
# DELETE /reports/{report_id}
# operationId: delete_report_resource
export def "delete-report-resource" [
  report_id: string
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
    path: "/reports/{report_id}"
    path_params: [{name: report_id, var: report_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get report
#
# GET /reports/{report_id}
# Returns: record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string>
# operationId: get_report_resource
export def "get-report-resource" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/{report_id}"
    path_params: [{name: report_id, var: report_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    report_id: $report_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update report
#
# PATCH /reports/{report_id}
# Returns: record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string>
# operationId: patch_report_resource
export def "patch-report-resource" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --annotations: record # shape: {add_text?: bool, include?: bool}
  --automation-blockers: record # shape: {include?: bool}
  --automation-score: record # shape: {include?: bool}
  --automation-what-if: record # shape: {include?: bool}
  --cover: record # shape: {include?: bool}
  --documents: list<string>
  --elapse-time: record # shape: {include?: bool}
  --evaluations: record # shape: {additional_column?: string, include?: bool}
  --field-automation: record # shape: {include?: bool}
  --inboxes: list<string>
  --lines: record # shape: {include?: bool}
  --metadata: record # shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
  --name: string
  --page-classification: record # shape: {include?: bool}
  --projects: list<string>
  --sections: record # shape: {include?: bool}
  --separator: string # default: |
  --sources: list<string> # default: [human, machine]
  --text: record # shape: {include?: bool}
  --version-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/reports/{report_id}"
    path_params: [{name: report_id, var: report_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: automation_blockers, var: automation_blockers}, {name: automation_score, var: automation_score}, {name: automation_what_if, var: automation_what_if}, {name: cover, var: cover}, {name: documents, var: documents}, {name: elapse_time, var: elapse_time}, {name: evaluations, var: evaluations}, {name: field_automation, var: field_automation}, {name: inboxes, var: inboxes}, {name: lines, var: lines}, {name: metadata, var: metadata}, {name: name, var: name}, {name: page_classification, var: page_classification}, {name: projects, var: projects}, {name: sections, var: sections}, {name: separator, var: separator}, {name: sources, var: sources}, {name: text, var: text}, {name: version_name, var: version_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    report_id: $report_id, x_fields: $x_fields, annotations: $annotations, automation_blockers: $automation_blockers, automation_score: $automation_score, automation_what_if: $automation_what_if, cover: $cover, documents: $documents, elapse_time: $elapse_time, evaluations: $evaluations, field_automation: $field_automation, inboxes: $inboxes, lines: $lines, metadata: $metadata, name: $name, page_classification: $page_classification, projects: $projects, sections: $sections, separator: $separator, sources: $sources, text: $text, version_name: $version_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate report based on report id
#
# POST /reports/{report_id}/generate
# operationId: post_generate_report_id_resource
export def "post-generate-report-id-resource" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delivery-method: string@delivery-method-completer # required
  --email: string
  --start-date: string # format: date-time
  --end-date: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/reports/{report_id}/generate"
    path_params: [{name: report_id, var: report_id}]
    query: [{name: delivery_method, var: delivery_method, required: true}, {name: email, var: email}, {name: start_date, var: start_date}, {name: end_date, var: end_date}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    report_id: $report_id, delivery_method: $delivery_method, email: $email, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all roles
#
# GET /roles
# Returns: table<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>
# operationId: get_roles_resource
export def "get-roles-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/roles"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create role
#
# POST /roles
# Returns: record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>
# operationId: post_roles_resource
export def "post-roles-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  name: string
  permissions: record # shape: {create_dropbox_user?: bool, create_inbox?: bool, create_webhook?: bool, de_escalate_document?: bool, delete_tenant?: bool, delete_webhook?: bool, edit_backend_settings?: bool, edit_beats?: bool, edit_dashboard_settings?: bool, edit_data_retention_settings?: bool, edit_flow_settings?: bool, edit_format_settings?: bool, edit_integration_settings?: bool, edit_integrations?: bool, edit_predictor_settings?: bool, edit_reports?: bool, edit_retention_settings?: bool, edit_review_settings?: bool, ... (32 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/roles"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, name: $name, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role
#
# DELETE /roles/{role_id}
# operationId: delete_role_resource
export def "delete-role-resource" [
  role_id: string
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
    path: "/roles/{role_id}"
    path_params: [{name: role_id, var: role_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get role
#
# GET /roles/{role_id}
# Returns: record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>
# operationId: get_role_resource
export def "get-role-resource" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/roles/{role_id}"
    path_params: [{name: role_id, var: role_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    role_id: $role_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update role
#
# PATCH /roles/{role_id}
# Returns: record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string>
# operationId: patch_role_resource
export def "patch-role-resource" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --name: string
  --permissions: record # shape: {create_dropbox_user?: bool, create_inbox?: bool, create_webhook?: bool, de_escalate_document?: bool, delete_tenant?: bool, delete_webhook?: bool, edit_backend_settings?: bool, edit_beats?: bool, edit_dashboard_settings?: bool, edit_data_retention_settings?: bool, edit_flow_settings?: bool, edit_format_settings?: bool, edit_integration_settings?: bool, edit_integrations?: bool, edit_predictor_settings?: bool, edit_reports?: bool, edit_retention_settings?: bool, edit_review_settings?: bool, ... (32 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/roles/{role_id}"
    path_params: [{name: role_id, var: role_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    role_id: $role_id, x_fields: $x_fields, name: $name, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all rule configs
#
# GET /rule_config
# Returns: table<rule_config: record, scope: string>
# operationId: get_rule_configs_resource
export def "get-rule-configs-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/rule_config"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the regexes that are generated by the rule
#
# POST /rule_config/rule_entity/
# operationId: post_debug_rule_entity_resource
export def "post-debug-rule-entity-resource" [
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/rule_config/rule_entity/"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluate a rule on a document
#
# POST /rule_config/rule_entity/{document_id}
# operationId: post_debug_rule_entity_document_resource
export def "post-debug-rule-entity-document-resource" [
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/rule_config/rule_entity/{document_id}"
    path_params: [{name: document_id, var: document_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    document_id: $document_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text a where_to_search specification will generate
#
# POST /rule_config/where_to_search/{document_id}
# operationId: post_debug_where_to_search
export def "post-debug-where-to-search" [
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/rule_config/where_to_search/{document_id}"
    path_params: [{name: document_id, var: document_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    document_id: $document_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete scoped rule config
#
# DELETE /rule_config/{scope}
# operationId: delete_rule_config_resource
export def "delete-rule-config-resource" [
  scope: string
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
    path: "/rule_config/{scope}"
    path_params: [{name: scope, var: scope}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scoped rule config
#
# GET /rule_config/{scope}
# Returns: record<rule_config: record, scope: string>
# operationId: get_rule_config_resource
export def "get-rule-config-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rule_config/{scope}"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update scoped rule config
#
# PATCH /rule_config/{scope}
# Returns: record<rule_config: record, scope: string>
# operationId: patch_rule_config_resource
export def "patch-rule-config-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --rule-config: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/rule_config/{scope}"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: rule_config, var: rule_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields, rule_config: $rule_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all sampling settings
#
# GET /sampling_settings
# Returns: table<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string>
# operationId: get_setting_samplings_resource
export def "get-setting-samplings-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sampling_settings"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete scoped sampling settings
#
# DELETE /sampling_settings/{scope}
# operationId: delete_setting_sampling_resource
export def "delete-setting-sampling-resource" [
  scope: string
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
    path: "/sampling_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scoped sampling settings
#
# GET /sampling_settings/{scope}
# Returns: record<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string>
# operationId: get_setting_sampling_resource
export def "get-setting-sampling-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sampling_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update scoped sampling settings
#
# PATCH /sampling_settings/{scope}
# Returns: record<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string>
# operationId: patch_setting_sampling_resource
export def "patch-setting-sampling-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --auto-reject-ffr: int
  --auto-submit-ffr: int
  --second-pass-ffr: int
  --second-pass-stp: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sampling_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: auto_reject_FFR, var: auto_reject_ffr}, {name: auto_submit_FFR, var: auto_submit_ffr}, {name: second_pass_FFR, var: second_pass_ffr}, {name: second_pass_STP, var: second_pass_stp}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields, auto_reject_ffr: $auto_reject_ffr, auto_submit_ffr: $auto_submit_ffr, second_pass_ffr: $second_pass_ffr, second_pass_stp: $second_pass_stp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scoped dashboard setting
#
# GET /settings/dashboard
# Returns: record<autolearning: bool, dashboard_timeout: int, default_date_range: record, default_inbox_size: record, default_inbox_sorting: record, flexible_filters: list<record>, navigation_menu: record, process_unreadable: bool, sequence_columns_of_inbox: record<columns_headers: list<record>, inline_headers: list<record>>, show_digital_annotations: bool, show_filters: record, show_inbox_actions: record, studio_format_options: record, upload_options: record, welcome_counters: bool, welcome_counters_options: record>
# operationId: get_dashboard_settings_atomic_resource
export def "get-dashboard-settings-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
  --qp-full: oneof<nothing, bool> # default: false (spec name: full)
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/settings/dashboard"
    query: [{name: scope, var: scope}, {name: full, var: qp_full}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, qp_full: $qp_full, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update scoped dashboard setting
#
# PATCH /settings/dashboard
# Returns: record<autolearning: bool, dashboard_timeout: int, default_date_range: record, default_inbox_size: record, default_inbox_sorting: record, flexible_filters: list<record>, navigation_menu: record, process_unreadable: bool, sequence_columns_of_inbox: record<columns_headers: list<record>, inline_headers: list<record>>, show_digital_annotations: bool, show_filters: record, show_inbox_actions: record, studio_format_options: record, upload_options: record, welcome_counters: bool, welcome_counters_options: record>
# operationId: patch_dashboard_settings_atomic_resource
export def "patch-dashboard-settings-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --scope: string
  --settings: record # shape: {autolearning?: bool, dashboard_timeout?: int, default_date_range?: record, default_inbox_size?: record, default_inbox_sorting?: record, flexible_filters?: list, navigation_menu?: record, process_unreadable?: bool, sequence_columns_of_inbox?: record, show_digital_annotations?: bool, show_filters?: record, show_inbox_actions?: record, studio_format_options?: record, upload_options?: record, welcome_counters?: bool, welcome_counters_options?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/settings/dashboard"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: scope, var: scope}, {name: settings, var: settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields, scope: $scope, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scoped review setting
#
# GET /settings/review
# Returns: record<default_zoom: record, first_toolbar: record, lock_expiry: record, review_options: record, second_toolbar: record>
# operationId: get_review_settings_atomic_resource
export def "get-review-settings-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
  --qp-full: oneof<nothing, bool> # default: false (spec name: full)
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/settings/review"
    query: [{name: scope, var: scope}, {name: full, var: qp_full}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, qp_full: $qp_full, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update scoped review setting
#
# PATCH /settings/review
# Returns: record<default_zoom: record, first_toolbar: record, lock_expiry: record, review_options: record, second_toolbar: record>
# operationId: patch_review_settings_atomic_resource
export def "patch-review-settings-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --scope: string
  --settings: record # shape: {default_zoom?: record, first_toolbar?: record, lock_expiry?: record, review_options?: record, second_toolbar?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/settings/review"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: scope, var: scope}, {name: settings, var: settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields, scope: $scope, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sso/config
#
# Returns: record<extra: record<entity_id: string, specification_url: string>, id: string, provider: string, type: string, url: string>
# operationId: get_sso_config_resources
export def "get-sso-config-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sso/config"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sso/config
#
# operationId: post_sso_config_resources
export def "post-sso-config-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --extra: record # shape: {entity_id?: string, specification_url?: string}
  provider: string # usually your company name, only used for visualisation: log in as employee
  --type: string@type-completer-2 # Type of SSO integration, for now only SAML is supported (default: saml, e.g. saml)
  --url: string # SAML-P sign-on endpoint (e.g. https://login.microsoftonline.com/e8656a10-4ec3-4cea-aa49-cbe9424c312d/saml2)
]: any -> any {
  $in | http-request {
    method: post
    path: "/sso/config"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: extra, var: extra}, {name: provider, var: provider}, {name: type, var: type}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields, extra: $extra, provider: $provider, type: $type, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get integration attributes
#
# DELETE /sso/config/{sso_config_id}
# operationId: delete_sso_config_resources
export def "delete-sso-config-resources" [
  sso_config_id: string
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
    path: "/sso/config/{sso_config_id}"
    path_params: [{name: sso_config_id, var: sso_config_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    sso_config_id: $sso_config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sso/login
#
# operationId: post_oauth_login_resource
export def "post-oauth-login-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # the access token (JWT for oauth or SAML response) (spec name: token)
  --type: string@type-completer-3 # the type of SSO token (e.g. oauth)
]: any -> any {
  $in | http-request {
    method: post
    path: "/sso/login"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /stats/usage
#
# operationId: get_usage_stats_resource
export def "get-usage-stats-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inbox-id: string
  --start-date: string # required, default: 2023-01-31T13:36:39
  --end-date: string # required, default: 2023-03-02T13:36:39
  --excel-output: oneof<nothing, bool> # Set to 'true' to get data in an excel. (Default output format: JSON) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/usage"
    query: [{name: inbox_id, var: inbox_id}, {name: start_date, var: start_date, required: true, default: "2023-01-31T13:36:39"}, {name: end_date, var: end_date, required: true, default: "2023-03-02T13:36:39"}, {name: excel_output, var: excel_output}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, start_date: $start_date, end_date: $end_date, excel_output: $excel_output
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get inbox statistics
#
# GET /stats/{inbox_id}
# operationId: get_stats_resource
export def "get-stats-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-name: string # The field names to include in the stats. If left empty, all fields are included.Additionally, `__all_fields__` field name is also added, and aggregates the stats for all fields
  --start-date: string # The minimum upload time of the file. If left empty, no filter is applied. (format: date-time)
  --end-date: string # The maximum upload time of the file. If left empty, no filter is applied. (format: date-time)
  --version-name: string # The name of the version to evaluate. If left empty, latest evaluated version is chosen.
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/{inbox_id}"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: field_name, var: field_name}, {name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: version_name, var: version_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, field_name: $field_name, start_date: $start_date, end_date: $end_date, version_name: $version_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get summary or details of automation blockers
#
# GET /stats/{inbox_id}/automation_blockers
# operationId: get_automation_blockers_stats
export def "get-automation-blockers-stats" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.252495
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.252527
  --version-name: string # provide the version name to evaluate (default: predicted)
  --include-detail: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/{inbox_id}/automation_blockers"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: version_name, var: version_name}, {name: include_detail, var: include_detail}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    inbox_id: $inbox_id, start_date: $start_date, end_date: $end_date, version_name: $version_name, include_detail: $include_detail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Blue Dots statistics for the inbox
#
# POST /stats/{inbox_id}/blue_dots
# operationId: post_blue_dots_resource
export def "post-blue-dots-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.250962
  --fields-to-exclude: string # gross_amount,due_date (default: "")
  --level: string # possible values: file, field (default: file)
  --option-level-fields: string # invoice,receipt (default: "")
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.250933
  --version-name: string # provide the version name to evaluate (default: submitted)
]: any -> any {
  $in | http-request {
    method: post
    path: "/stats/{inbox_id}/blue_dots"
    path_params: [{name: inbox_id, var: inbox_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: end_date, var: end_date}, {name: fields_to_exclude, var: fields_to_exclude}, {name: level, var: level}, {name: option_level_fields, var: option_level_fields}, {name: start_date, var: start_date}, {name: version_name, var: version_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, end_date: $end_date, fields_to_exclude: $fields_to_exclude, level: $level, option_level_fields: $option_level_fields, start_date: $start_date, version_name: $version_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the documents with evaluated versions
#
# GET /stats/{inbox_id}/evaluated_versions
# operationId: get_evaluated_versions
export def "get-evaluated-versions" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.251355
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.251385
  --filter-versions: oneof<nothing, bool> # default: false
  --last-one-only: oneof<nothing, bool> # default: true
  --version-name: string # filter the version by name. If not specified, all version names are considered
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/{inbox_id}/evaluated_versions"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: filter_versions, var: filter_versions}, {name: last_one_only, var: last_one_only}, {name: version_name, var: version_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbox_id: $inbox_id, start_date: $start_date, end_date: $end_date, filter_versions: $filter_versions, last_one_only: $last_one_only, version_name: $version_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get processing runtime stats
#
# GET /stats/{inbox_id}/processing
# operationId: get_processing_stats
export def "get-processing-stats" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.251761
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.251794
  --group-by: string # Group stats per this given attribute. Only **pages** is supported (default: pages)
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/{inbox_id}/processing"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: group_by, var: group_by}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    inbox_id: $inbox_id, start_date: $start_date, end_date: $end_date, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Permission required:** view_statistics
#
# GET /stats/{inbox_id}/volume
# operationId: get_volume_stats
export def "get-volume-stats" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.252098
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.252127
  --status: string # default: to_review
  --user: string
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/{inbox_id}/volume"
    path_params: [{name: inbox_id, var: inbox_id}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: status, var: status}, {name: user, var: user}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    inbox_id: $inbox_id, start_date: $start_date, end_date: $end_date, status: $status, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Accuracy counts on documents, sections and fields in the given inbox
#
# GET /stats/{scope}/accuracy
# operationId: get_accuracy_resource
export def "get-accuracy-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.250494
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.250527
  --stp-files-only: oneof<nothing, bool> # default: false
  --stp-fields-only: oneof<nothing, bool> # default: false
  --version-name: string # provide the version name to evaluate
  --filter-by: string # Choose to filter the results by doctype, process label, ...
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/{scope}/accuracy"
    path_params: [{name: scope, var: scope}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: stp_files_only, var: stp_files_only}, {name: stp_fields_only, var: stp_fields_only}, {name: version_name, var: version_name}, {name: filter_by, var: filter_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, start_date: $start_date, end_date: $end_date, stp_files_only: $stp_files_only, stp_fields_only: $stp_fields_only, version_name: $version_name, filter_by: $filter_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the STP counts on documents, sections and fields in the given inbox
#
# GET /stats/{scope}/stp
# operationId: get_stp_resource
export def "get-stp-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.250021
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.250091
  --version-name: string # Provide the evaluated version name to inspect automation (of the predictions) for (default: predicted)
  --filter-by: string # Choose to filter the results by doctype, process label, ...
]: nothing -> any {
  http-request {
    method: get
    path: "/stats/{scope}/stp"
    path_params: [{name: scope, var: scope}]
    query: [{name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: version_name, var: version_name}, {name: filter_by, var: filter_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, start_date: $start_date, end_date: $end_date, version_name: $version_name, filter_by: $filter_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the custom CSS file
#
# GET /style/custom.css
# operationId: get_style_sheet_resource
export def "get-style-sheet-resource" [
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
    path: "/style/custom.css"
    accept: ["application/json"]
    ok: [200, 204]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload the custom logo
#
# POST /style/custom.css
# operationId: post_style_sheet_resource
export def "post-style-sheet-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # File to handle (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/style/custom.css"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the custom logo
#
# GET /style/logo.png
# operationId: get_style_logo_resource
export def "get-style-logo-resource" [
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
    path: "/style/logo.png"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload the custom logo
#
# POST /style/logo.png
# operationId: post_style_logo_resource
export def "post-style-logo-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # File to handle (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/style/logo.png"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /tenant
#
# operationId: delete_tenant_resource
export def "delete-tenant-resource" [
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
    path: "/tenant"
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /tenant/activate
#
# Returns: record<id: string>
# operationId: patch_activate_tenant_resource
export def "patch-activate-tenant-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --code: int
  --email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tenant/activate"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields, code: $code, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all thresholds settings
#
# GET /threshold_settings
# Returns: table<thresholds: record<annotations: record, lines: record, sections: record>, scope: string>
# operationId: get_settings_threshold_resource
export def "get-settings-threshold-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/threshold_settings"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the thresholds settings
#
# DELETE /threshold_settings/{scope}
# operationId: delete_setting_threshold_resource
export def "delete-setting-threshold-resource" [
  scope: string
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
    path: "/threshold_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the scoped thresholds settings
#
# GET /threshold_settings/{scope}
# Returns: record<thresholds: record<annotations: record, lines: record, sections: record>, scope: string>
# operationId: get_setting_threshold_resource
export def "get-setting-threshold-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool> # default: false
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/threshold_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    query: [{name: default, var: default}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, default: $default, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the scoped thresholds settings
#
# PATCH /threshold_settings/{scope}
# Returns: record<thresholds: record<annotations: record, lines: record, sections: record>, scope: string>
# operationId: patch_setting_threshold_resource
export def "patch-setting-threshold-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --thresholds: record # shape: {annotations?: record, lines?: record, sections?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/threshold_settings/{scope}"
    path_params: [{name: scope, var: scope}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: thresholds, var: thresholds}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    scope: $scope, x_fields: $x_fields, thresholds: $thresholds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users
#
# GET /users
# Returns: table<active: bool, confirmed_at: string, id: string, roles: list<record>, username: string>
# operationId: get_users_resource
export def "get-users-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user
#
# POST /users
# Returns: record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>
# operationId: post_users_resource
export def "post-users-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
  --active: oneof<nothing, bool> # Inactive users have to reset their password first
  --password: string # the user password
  roles: list # the user roles — item shape: {document_id?: string, inbox?: string, role: string}
  username: string # the user username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active, required: true}, {name: password, var: password}, {name: roles, var: roles}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    x_fields: $x_fields, active: $active, password: $password, roles: $roles, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return info on the current user
#
# GET /users/me
# Returns: record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>
# operationId: get_me
export def "get-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/me"
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the current user password
#
# POST /users/me/change_password
# operationId: post_change_password
export def "post-change-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # the new user's password
  --old-password: string # the old user's password
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/me/change_password"
    body: {content_type: "application/json", kind: json, fields: [{name: new_password, var: new_password}, {name: old_password, var: old_password}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user
#
# DELETE /users/{user_id}
# operationId: delete_user_resource
export def "delete-user-resource" [
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
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user
#
# GET /users/{user_id}
# Returns: record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>
# operationId: get_user_resource
export def "get-user-resource" [
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
  --x-fields: string # An optional fields mask (format: mask)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Fields, var: x_fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user_id: $user_id, x_fields: $x_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user
#
# PATCH /users/{user_id}
# Returns: record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string>
# operationId: patch_user_resource
export def "patch-user-resource" [
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
  --x-fields: string # An optional fields mask (format: mask)
  --roles: list # the user roles — item shape: {inbox?: string, role?: string}
  --username: string # the user username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Fields, var: x_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: roles, var: roles}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    user_id: $user_id, x_fields: $x_fields, roles: $roles, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
