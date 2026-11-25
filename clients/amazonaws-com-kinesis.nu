# Auto-generated client for Amazon Kinesis v2013-12-02
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kinesis/2013-12-02/openapi.json
# Auth: --token flag or $env.AMAZON_KINESIS_TOKEN

const CLIENT = {
  base_url: "http://kinesis.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_KINESIS_TOKEN"
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

def base-url-completer [] { ["http://kinesis.us-east-1.amazonaws.com" "http://kinesis.us-east-2.amazonaws.com" "http://kinesis.us-west-1.amazonaws.com" "http://kinesis.us-west-2.amazonaws.com" "http://kinesis.us-gov-west-1.amazonaws.com" "http://kinesis.us-gov-east-1.amazonaws.com" "http://kinesis.ca-central-1.amazonaws.com" "http://kinesis.eu-north-1.amazonaws.com" "http://kinesis.eu-west-1.amazonaws.com" "http://kinesis.eu-west-2.amazonaws.com" "http://kinesis.eu-west-3.amazonaws.com" "http://kinesis.eu-central-1.amazonaws.com" "http://kinesis.eu-south-1.amazonaws.com" "http://kinesis.af-south-1.amazonaws.com" "http://kinesis.ap-northeast-1.amazonaws.com" "http://kinesis.ap-northeast-2.amazonaws.com" "http://kinesis.ap-northeast-3.amazonaws.com" "http://kinesis.ap-southeast-1.amazonaws.com" "http://kinesis.ap-southeast-2.amazonaws.com" "http://kinesis.ap-east-1.amazonaws.com" "http://kinesis.ap-south-1.amazonaws.com" "http://kinesis.sa-east-1.amazonaws.com" "http://kinesis.me-south-1.amazonaws.com" "https://kinesis.us-east-1.amazonaws.com" "https://kinesis.us-east-2.amazonaws.com" "https://kinesis.us-west-1.amazonaws.com" "https://kinesis.us-west-2.amazonaws.com" "https://kinesis.us-gov-west-1.amazonaws.com" "https://kinesis.us-gov-east-1.amazonaws.com" "https://kinesis.ca-central-1.amazonaws.com" "https://kinesis.eu-north-1.amazonaws.com" "https://kinesis.eu-west-1.amazonaws.com" "https://kinesis.eu-west-2.amazonaws.com" "https://kinesis.eu-west-3.amazonaws.com" "https://kinesis.eu-central-1.amazonaws.com" "https://kinesis.eu-south-1.amazonaws.com" "https://kinesis.af-south-1.amazonaws.com" "https://kinesis.ap-northeast-1.amazonaws.com" "https://kinesis.ap-northeast-2.amazonaws.com" "https://kinesis.ap-northeast-3.amazonaws.com" "https://kinesis.ap-southeast-1.amazonaws.com" "https://kinesis.ap-southeast-2.amazonaws.com" "https://kinesis.ap-east-1.amazonaws.com" "https://kinesis.ap-south-1.amazonaws.com" "https://kinesis.sa-east-1.amazonaws.com" "https://kinesis.me-south-1.amazonaws.com" "http://kinesis.cn-north-1.amazonaws.com.cn" "http://kinesis.cn-northwest-1.amazonaws.com.cn" "https://kinesis.cn-north-1.amazonaws.com.cn" "https://kinesis.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Kinesis_20131202.AddTagsToStream"] }
def x-amz-target-completer-1 [] { ["Kinesis_20131202.CreateStream"] }
def x-amz-target-completer-2 [] { ["Kinesis_20131202.DecreaseStreamRetentionPeriod"] }
def x-amz-target-completer-3 [] { ["Kinesis_20131202.DeleteStream"] }
def x-amz-target-completer-4 [] { ["Kinesis_20131202.DeregisterStreamConsumer"] }
def x-amz-target-completer-5 [] { ["Kinesis_20131202.DescribeLimits"] }
def x-amz-target-completer-6 [] { ["Kinesis_20131202.DescribeStream"] }
def x-amz-target-completer-7 [] { ["Kinesis_20131202.DescribeStreamConsumer"] }
def x-amz-target-completer-8 [] { ["Kinesis_20131202.DescribeStreamSummary"] }
def x-amz-target-completer-9 [] { ["Kinesis_20131202.DisableEnhancedMonitoring"] }
def x-amz-target-completer-10 [] { ["Kinesis_20131202.EnableEnhancedMonitoring"] }
def x-amz-target-completer-11 [] { ["Kinesis_20131202.GetRecords"] }
def shard-iterator-type-completer [] { ["AFTER_SEQUENCE_NUMBER" "AT_SEQUENCE_NUMBER" "AT_TIMESTAMP" "LATEST" "TRIM_HORIZON"] }
def x-amz-target-completer-12 [] { ["Kinesis_20131202.GetShardIterator"] }
def x-amz-target-completer-13 [] { ["Kinesis_20131202.IncreaseStreamRetentionPeriod"] }
def x-amz-target-completer-14 [] { ["Kinesis_20131202.ListShards"] }
def x-amz-target-completer-15 [] { ["Kinesis_20131202.ListStreamConsumers"] }
def x-amz-target-completer-16 [] { ["Kinesis_20131202.ListStreams"] }
def x-amz-target-completer-17 [] { ["Kinesis_20131202.ListTagsForStream"] }
def x-amz-target-completer-18 [] { ["Kinesis_20131202.MergeShards"] }
def x-amz-target-completer-19 [] { ["Kinesis_20131202.PutRecord"] }
def x-amz-target-completer-20 [] { ["Kinesis_20131202.PutRecords"] }
def x-amz-target-completer-21 [] { ["Kinesis_20131202.RegisterStreamConsumer"] }
def x-amz-target-completer-22 [] { ["Kinesis_20131202.RemoveTagsFromStream"] }
def x-amz-target-completer-23 [] { ["Kinesis_20131202.SplitShard"] }
def encryption-type-completer [] { ["KMS" "NONE"] }
def x-amz-target-completer-24 [] { ["Kinesis_20131202.StartStreamEncryption"] }
def x-amz-target-completer-25 [] { ["Kinesis_20131202.StopStreamEncryption"] }
def scaling-type-completer [] { ["UNIFORM_SCALING"] }
def x-amz-target-completer-26 [] { ["Kinesis_20131202.UpdateShardCount"] }
def x-amz-target-completer-27 [] { ["Kinesis_20131202.UpdateStreamMode"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    describe-limits: "record<ShardLimit: int, OpenShardCount: int, OnDemandStreamCount: int, OnDemandStreamCountLimit: int>"
    describe-stream: "record<StreamDescription: record<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record<StreamMode: string>, Shards: list<record>, HasMoreShards: bool, RetentionPeriodHours: int, StreamCreationTimestamp: string, EnhancedMonitoring: list<record>, EncryptionType: string, KeyId: string>>"
    describe-stream-consumer: "record<ConsumerDescription: record<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string, StreamARN: string>>"
    describe-stream-summary: "record<StreamDescriptionSummary: record<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record<StreamMode: string>, RetentionPeriodHours: int, StreamCreationTimestamp: string, EnhancedMonitoring: list<record>, EncryptionType: string, KeyId: string, OpenShardCount: int, ConsumerCount: int>>"
    disable-enhanced-monitoring: "record<StreamName: string, CurrentShardLevelMetrics: list<string>, DesiredShardLevelMetrics: list<string>, StreamARN: string>"
    enable-enhanced-monitoring: "record<StreamName: string, CurrentShardLevelMetrics: list<string>, DesiredShardLevelMetrics: list<string>, StreamARN: string>"
    get-records: "record<Records: table<SequenceNumber: string, ApproximateArrivalTimestamp: string, Data: string, PartitionKey: string, EncryptionType: string>, NextShardIterator: string, MillisBehindLatest: int, ChildShards: table<ShardId: string, ParentShards: list, HashKeyRange: record>>"
    get-shard-iterator: "record<ShardIterator: string>"
    list-shards: "record<Shards: table<ShardId: string, ParentShardId: string, AdjacentParentShardId: string, HashKeyRange: record, SequenceNumberRange: record>, NextToken: string>"
    list-stream-consumers: "record<Consumers: table<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string>, NextToken: string>"
    list-streams: "record<StreamNames: list<string>, HasMoreStreams: bool, NextToken: string, StreamSummaries: table<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record, StreamCreationTimestamp: string>>"
    list-tags-for-stream: "record<Tags: table<Key: string, Value: string>, HasMoreTags: bool>"
    put-record: "record<ShardId: string, SequenceNumber: string, EncryptionType: string>"
    put-records: "record<FailedRecordCount: int, Records: table<SequenceNumber: string, ShardId: string, ErrorCode: string, ErrorMessage: string>, EncryptionType: string>"
    register-stream-consumer: "record<Consumer: record<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string>>"
    update-shard-count: "record<StreamName: string, CurrentShardCount: int, TargetShardCount: int, StreamARN: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags-to-stream" "create-stream" "decrease-stream-retention-period" "delete-stream" "deregister-stream-consumer" "describe-limits" "describe-stream" "describe-stream-consumer" "describe-stream-summary" "disable-enhanced-monitoring" "enable-enhanced-monitoring" "get-records" "get-shard-iterator" "increase-stream-retention-period" "list-shards" "list-stream-consumers" "list-streams" "list-tags-for-stream" "merge-shards" "put-record" "put-records" "register-stream-consumer" "remove-tags-from-stream" "split-shard" "start-stream-encryption" "stop-stream-encryption" "update-shard-count" "update-stream-mode" "commands"] | sort) } | get name | first)
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

# Adds or updates tags for the specified Kinesis data stream. You can assign up to 50 tags to a data stream. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If tags have already been assigned to the stream, AddTagsToStream overwrites any existing tags that correspond to the specified tag keys. AddTagsToStream has a limit of five transactions per second per account.
#
# POST /
# operationId: AddTagsToStream
export def "add-tags-to-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  --stream-name: string # The name of the stream.
  tags: record # A set of up to 10 key-value pairs to use to create the tags.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.AddTagsToStream"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: Tags, var: tags}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, tags: $tags, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Kinesis data stream. A stream captures and transports data records that are continuously emitted from different data sources or producers. Scale-out within a stream is explicitly supported by means of shards, which are uniquely identified groups of data records in a stream. You can create your data stream using either on-demand or provisioned capacity mode. Data streams with an on-demand mode require no capacity planning and automatically scale to handle gigabytes of write and read throughput per minute. With the on-demand mode, Kinesis Data Streams automatically manages the shards in order to provide the necessary throughput. For the data streams with a provisioned mode, you must specify the number of shards for the data stream. Each shard can support reads up to five transactions per second, up to a maximum data read total of 2 MiB per second. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MiB per second. If the amount of data input increases or decreases, you can add or remove shards. The stream name identifies the stream. The name is scoped to the Amazon Web Services account used by the application. It is also scoped by Amazon Web Services Region. That is, two streams in two different accounts can have the same name, and two streams in the same account, but in two different Regions, can have the same name. CreateStream is an asynchronous operation. Upon receiving a CreateStream request, Kinesis Data Streams immediately returns and sets the stream status to CREATING. After the stream is created, Kinesis Data Streams sets the stream status to ACTIVE. You should perform read and write operations only on an ACTIVE stream. You receive a LimitExceededException when making a CreateStream request when you try to do one of the following: Have more than five streams in the CREATING state at any point in time. Create more shards than are authorized for your account. For the default shard limit for an Amazon Web Services account, see Amazon Kinesis Data Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. To increase this limit, contact Amazon Web Services Support (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html). You can use DescribeStreamSummary to check the stream status, which is returned in StreamStatus. CreateStream has a limit of five transactions per second per account.
#
# POST /
# operationId: CreateStream
export def "create-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  stream_name: string # A name to identify the stream. The stream name is scoped to the Amazon Web Services account used by the application that creates the stream. It is also scoped by Amazon Web Services Region. That is, two streams in two different Amazon Web Services accounts can have the same name. Two streams in the same Amazon Web Services account but in two different Regions can also have the same name.
  --shard-count: int # The number of shards that the stream will use. The throughput of the stream is a function of the number of shards; more shards are required for greater provisioned throughput.
  --stream-mode-details: record # Specifies the capacity mode to which you want to set your data stream. Currently, in Kinesis Data Streams, you can choose between an on-demand capacity mode and a provisioned capacity mode for your data streams. — shape: {StreamMode: "PROVISIONED"|"ON_DEMAND"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.CreateStream"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: ShardCount, var: shard_count}, {name: StreamModeDetails, var: stream_mode_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, shard_count: $shard_count, stream_mode_details: $stream_mode_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decreases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The minimum value of a stream's retention period is 24 hours. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. This operation may result in lost data. For example, if the stream's retention period is 48 hours and is decreased to 24 hours, any data already in the stream that is older than 24 hours is inaccessible.
#
# POST /
# operationId: DecreaseStreamRetentionPeriod
export def "decrease-stream-retention-period" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2 # required
  --stream-name: string # The name of the stream to modify.
  retention_period_hours: int # The new retention period of the stream, in hours. Must be less than the current retention period.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DecreaseStreamRetentionPeriod"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: RetentionPeriodHours, var: retention_period_hours}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, retention_period_hours: $retention_period_hours, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Kinesis data stream and all its shards and data. You must shut down any applications that are operating on the stream before you delete the stream. If an application attempts to operate on a deleted stream, it receives the exception ResourceNotFoundException. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If the stream is in the ACTIVE state, you can delete it. After a DeleteStream request, the specified stream is in the DELETING state until Kinesis Data Streams completes the deletion. Note: Kinesis Data Streams might continue to accept data read and write operations, such as PutRecord, PutRecords, and GetRecords, on a stream in the DELETING state until the stream deletion is complete. When you delete a stream, any shards in that stream are also deleted, and any tags are dissociated from the stream. You can use the DescribeStreamSummary operation to check the state of the stream, which is returned in StreamStatus. DeleteStream has a limit of five transactions per second per account.
#
# POST /
# operationId: DeleteStream
export def "delete-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  --stream-name: string # The name of the stream to delete.
  --enforce-consumer-deletion: oneof<nothing, bool> # If this parameter is unset (null) or if you set it to false, and the stream has registered consumers, the call to DeleteStream fails with a ResourceInUseException.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DeleteStream"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: EnforceConsumerDeletion, var: enforce_consumer_deletion}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, enforce_consumer_deletion: $enforce_consumer_deletion, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To deregister a consumer, provide its ARN. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to deregister, you can use the ListStreamConsumers operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. The description of a consumer contains its name and ARN. This operation has a limit of five transactions per second per stream.
#
# POST /
# operationId: DeregisterStreamConsumer
export def "deregister-stream-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  --stream-arn: string # The ARN of the Kinesis data stream that the consumer is registered with. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  --consumer-name: string # The name that you gave to the consumer.
  --consumer-arn: string # The ARN returned by Kinesis Data Streams when you registered the consumer. If you don't know the ARN of the consumer that you want to deregister, you can use the ListStreamConsumers operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. The description of a consumer contains its ARN.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DeregisterStreamConsumer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamARN, var: stream_arn}, {name: ConsumerName, var: consumer_name}, {name: ConsumerARN, var: consumer_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_arn: $stream_arn, consumer_name: $consumer_name, consumer_arn: $consumer_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the shard limits and usage for the account. If you update your account limits, the old limits might be returned for a few minutes. This operation has a limit of one transaction per second per account.
#
# POST /
# Returns: record<ShardLimit: int, OpenShardCount: int, OnDemandStreamCount: int, OnDemandStreamCountLimit: int>
# operationId: DescribeLimits
export def "describe-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DescribeLimits"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified Kinesis data stream. This API has been revised. It's highly recommended that you use the DescribeStreamSummary API to get a summarized description of the specified Kinesis data stream and the ListShards API to list the shards in a specified data stream and obtain information about each shard. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. The information returned includes the stream name, Amazon Resource Name (ARN), creation time, enhanced metric configuration, and shard map. The shard map is an array of shard objects. For each shard object, there is the hash key and sequence number ranges that the shard spans, and the IDs of any earlier shards that played in a role in creating the shard. Every record ingested in the stream is identified by a sequence number, which is assigned when the record is put into the stream. You can limit the number of shards returned by each call. For more information, see Retrieving Shards from a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-retrieve-shards.html) in the Amazon Kinesis Data Streams Developer Guide. There are no guarantees about the chronological order shards returned. To process shards in chronological order, use the ID of the parent shard to track the lineage to the oldest shard. This operation has a limit of 10 transactions per second per account.
#
# POST /
# Returns: record<StreamDescription: record<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record<StreamMode: string>, Shards: list<record>, HasMoreShards: bool, RetentionPeriodHours: int, StreamCreationTimestamp: string, EnhancedMonitoring: list<record>, EncryptionType: string, KeyId: string>>
# operationId: DescribeStream
export def "describe-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --exclusive-start-shard-id: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  --stream-name: string # The name of the stream to describe.
  --body-limit: int # The maximum number of shards to return in a single call. The default value is 100. If you specify a value greater than 100, at most 100 results are returned. (spec name: Limit)
  --body-exclusive-start-shard-id: string # The shard ID of the shard to start with. Specify this parameter to indicate that you want to describe the stream starting with the shard whose ID immediately follows ExclusiveStartShardId. If you don't specify this parameter, the default behavior for DescribeStream is to describe the stream starting with the first shard in the stream. (spec name: ExclusiveStartShardId)
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: ExclusiveStartShardId, var: exclusive_start_shard_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DescribeStream"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: Limit, var: body_limit}, {name: ExclusiveStartShardId, var: body_exclusive_start_shard_id}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, exclusive_start_shard_id: $exclusive_start_shard_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, body_limit: $body_limit, body_exclusive_start_shard_id: $body_exclusive_start_shard_id, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# To get the description of a registered consumer, provide the ARN of the consumer. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to describe, you can use the ListStreamConsumers operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. This operation has a limit of 20 transactions per second per stream.
#
# POST /
# Returns: record<ConsumerDescription: record<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string, StreamARN: string>>
# operationId: DescribeStreamConsumer
export def "describe-stream-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7 # required
  --stream-arn: string # The ARN of the Kinesis data stream that the consumer is registered with. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  --consumer-name: string # The name that you gave to the consumer.
  --consumer-arn: string # The ARN returned by Kinesis Data Streams when you registered the consumer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DescribeStreamConsumer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamARN, var: stream_arn}, {name: ConsumerName, var: consumer_name}, {name: ConsumerARN, var: consumer_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_arn: $stream_arn, consumer_name: $consumer_name, consumer_arn: $consumer_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a summarized description of the specified Kinesis data stream without the shard list. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. The information returned includes the stream name, Amazon Resource Name (ARN), status, record retention period, approximate creation time, monitoring, encryption details, and open shard count. DescribeStreamSummary has a limit of 20 transactions per second per account.
#
# POST /
# Returns: record<StreamDescriptionSummary: record<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record<StreamMode: string>, RetentionPeriodHours: int, StreamCreationTimestamp: string, EnhancedMonitoring: list<record>, EncryptionType: string, KeyId: string, OpenShardCount: int, ConsumerCount: int>>
# operationId: DescribeStreamSummary
export def "describe-stream-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  --stream-name: string # The name of the stream to describe.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DescribeStreamSummary"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables enhanced monitoring. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# Returns: record<StreamName: string, CurrentShardLevelMetrics: list<string>, DesiredShardLevelMetrics: list<string>, StreamARN: string>
# operationId: DisableEnhancedMonitoring
export def "disable-enhanced-monitoring" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  --stream-name: string # The name of the Kinesis data stream for which to disable enhanced monitoring.
  shard_level_metrics: list<string> # List of shard-level metrics to disable. The following are the valid shard-level metrics. The value "ALL" disables every metric. IncomingBytes IncomingRecords OutgoingBytes OutgoingRecords WriteProvisionedThroughputExceeded ReadProvisionedThroughputExceeded IteratorAgeMilliseconds ALL For more information, see Monitoring the Amazon Kinesis Data Streams Service with Amazon CloudWatch (https://docs.aws.amazon.com/kinesis/latest/dev/monitoring-with-cloudwatch.html) in the Amazon Kinesis Data Streams Developer Guide.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.DisableEnhancedMonitoring"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: ShardLevelMetrics, var: shard_level_metrics}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, shard_level_metrics: $shard_level_metrics, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables enhanced Kinesis data stream monitoring for shard-level metrics. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# Returns: record<StreamName: string, CurrentShardLevelMetrics: list<string>, DesiredShardLevelMetrics: list<string>, StreamARN: string>
# operationId: EnableEnhancedMonitoring
export def "enable-enhanced-monitoring" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10 # required
  --stream-name: string # The name of the stream for which to enable enhanced monitoring.
  shard_level_metrics: list<string> # List of shard-level metrics to enable. The following are the valid shard-level metrics. The value "ALL" enables every metric. IncomingBytes IncomingRecords OutgoingBytes OutgoingRecords WriteProvisionedThroughputExceeded ReadProvisionedThroughputExceeded IteratorAgeMilliseconds ALL For more information, see Monitoring the Amazon Kinesis Data Streams Service with Amazon CloudWatch (https://docs.aws.amazon.com/kinesis/latest/dev/monitoring-with-cloudwatch.html) in the Amazon Kinesis Data Streams Developer Guide.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.EnableEnhancedMonitoring"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: ShardLevelMetrics, var: shard_level_metrics}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, shard_level_metrics: $shard_level_metrics, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets data records from a Kinesis data stream's shard. When invoking this API, it is recommended you use the StreamARN input parameter in addition to the ShardIterator parameter. Specify a shard iterator using the ShardIterator parameter. The shard iterator specifies the position in the shard from which you want to start reading data records sequentially. If there are no records available in the portion of the shard that the iterator points to, GetRecords returns an empty list. It might take multiple calls to get to a portion of the shard that contains records. You can scale by provisioning multiple shards per stream while considering service limits (for more information, see Amazon Kinesis Data Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide). Your application should have one thread per shard, each reading continuously from its stream. To read from a stream continually, call GetRecords in a loop. Use GetShardIterator to get the shard iterator to specify in the first GetRecords call. GetRecords returns a new shard iterator in NextShardIterator. Specify the shard iterator returned in NextShardIterator in subsequent calls to GetRecords. If the shard has been closed, the shard iterator can't return more data and GetRecords returns null in NextShardIterator. You can terminate the loop when the shard is closed, or when the shard iterator reaches the record with the sequence number or other attribute that marks it as the last record to process. Each data record can be up to 1 MiB in size, and each shard can read up to 2 MiB per second. You can ensure that your calls don't exceed the maximum supported size or throughput by using the Limit parameter to specify the maximum number of records that GetRecords can return. Consider your average record size when determining this limit. The maximum number of records that can be returned per call is 10,000. The size of the data returned by GetRecords varies depending on the utilization of the shard. It is recommended that consumer applications retrieve records via the GetRecords command using the 5 TPS limit to remain caught up. Retrieving records less frequently can lead to consumer applications falling behind. The maximum size of data that GetRecords can return is 10 MiB. If a call returns this amount of data, subsequent calls made within the next 5 seconds throw ProvisionedThroughputExceededException. If there is insufficient provisioned throughput on the stream, subsequent calls made within the next 1 second throw ProvisionedThroughputExceededException. GetRecords doesn't return any data when it throws an exception. For this reason, we recommend that you wait 1 second between calls to GetRecords. However, it's possible that the application will get exceptions for longer than 1 second. To detect whether the application is falling behind in processing, you can use the MillisBehindLatest response attribute. You can also monitor the stream using CloudWatch metrics and other mechanisms (see Monitoring (https://docs.aws.amazon.com/kinesis/latest/dev/monitoring.html) in the Amazon Kinesis Data Streams Developer Guide). Each Amazon Kinesis record includes a value, ApproximateArrivalTimestamp, that is set when a stream successfully receives and stores a record. This is commonly referred to as a server-side time stamp, whereas a client-side time stamp is set when a data producer creates or sends the record to a stream (a data producer is any data source putting data records into a stream, for example with PutRecords). The time stamp has millisecond precision. There are no guarantees about the time stamp accuracy, or that the time stamp is always increasing. For example, records in a shard or across a stream might have time stamps that are out of order. This operation has a limit of five transactions per second per shard.
#
# POST /
# Returns: record<Records: table<SequenceNumber: string, ApproximateArrivalTimestamp: string, Data: string, PartitionKey: string, EncryptionType: string>, NextShardIterator: string, MillisBehindLatest: int, ChildShards: table<ShardId: string, ParentShards: list, HashKeyRange: record>>
# operationId: GetRecords
export def "get-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  shard_iterator: string # The position in the shard from which you want to start sequentially reading data records. A shard iterator specifies this position using the sequence number of a data record in the shard.
  --limit: int # The maximum number of records to return. Specify a value of up to 10,000. If you specify a value that is greater than 10,000, GetRecords throws InvalidArgumentException. The default value is 10,000.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.GetRecords"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ShardIterator, var: shard_iterator}, {name: Limit, var: limit}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, shard_iterator: $shard_iterator, limit: $limit, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Amazon Kinesis shard iterator. A shard iterator expires 5 minutes after it is returned to the requester. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. A shard iterator specifies the shard position from which to start reading data records sequentially. The position is specified using the sequence number of a data record in a shard. A sequence number is the identifier associated with every record ingested in the stream, and is assigned when a record is put into the stream. Each stream has one or more shards. You must specify the shard iterator type. For example, you can set the ShardIteratorType parameter to read exactly from the position denoted by a specific sequence number by using the AT_SEQUENCE_NUMBER shard iterator type. Alternatively, the parameter can read right after the sequence number by using the AFTER_SEQUENCE_NUMBER shard iterator type, using sequence numbers returned by earlier calls to PutRecord, PutRecords, GetRecords, or DescribeStream. In the request, you can specify the shard iterator type AT_TIMESTAMP to read records from an arbitrary point in time, TRIM_HORIZON to cause ShardIterator to point to the last untrimmed record in the shard in the system (the oldest data record in the shard), or LATEST so that you always read the most recent data in the shard. When you read repeatedly from a stream, use a GetShardIterator request to get the first shard iterator for use in your first GetRecords request and for subsequent reads use the shard iterator returned by the GetRecords request in NextShardIterator. A new shard iterator is returned by every GetRecords request in NextShardIterator, which you use in the ShardIterator parameter of the next GetRecords request. If a GetShardIterator request is made too often, you receive a ProvisionedThroughputExceededException. For more information about throughput limits, see GetRecords, and Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. If the shard is closed, GetShardIterator returns a valid iterator for the last sequence number of the shard. A shard can be closed as a result of using SplitShard or MergeShards. GetShardIterator has a limit of five transactions per second per account per open shard.
#
# POST /
# Returns: record<ShardIterator: string>
# operationId: GetShardIterator
export def "get-shard-iterator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  --stream-name: string # The name of the Amazon Kinesis data stream.
  shard_id: string # The shard ID of the Kinesis Data Streams shard to get the iterator for.
  shard_iterator_type: string@shard-iterator-type-completer # Determines how the shard iterator is used to start reading data records from the shard. The following are the valid Amazon Kinesis shard iterator types: AT_SEQUENCE_NUMBER - Start reading from the position denoted by a specific sequence number, provided in the value StartingSequenceNumber. AFTER_SEQUENCE_NUMBER - Start reading right after the position denoted by a specific sequence number, provided in the value StartingSequenceNumber. AT_TIMESTAMP - Start reading from the position denoted by a specific time stamp, provided in the value Timestamp. TRIM_HORIZON - Start reading at the last untrimmed record in the shard in the system, which is the oldest data record in the shard. LATEST - Start reading just after the most recent record in the shard, so that you always read the most recent data in the shard.
  --starting-sequence-number: string # The sequence number of the data record in the shard from which to start reading. Used with shard iterator type AT_SEQUENCE_NUMBER and AFTER_SEQUENCE_NUMBER.
  --timestamp: string # The time stamp of the data record from which to start reading. Used with shard iterator type AT_TIMESTAMP. A time stamp is the Unix epoch date with precision in milliseconds. For example, 2016-04-04T19:58:46.480-00:00 or 1459799926.480. If a record with this exact time stamp does not exist, the iterator returned is for the next (later) record. If the time stamp is older than the current trim horizon, the iterator returned is for the oldest untrimmed data record (TRIM_HORIZON). (format: date-time)
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.GetShardIterator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: ShardId, var: shard_id}, {name: ShardIteratorType, var: shard_iterator_type}, {name: StartingSequenceNumber, var: starting_sequence_number}, {name: Timestamp, var: timestamp}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, shard_id: $shard_id, shard_iterator_type: $shard_iterator_type, starting_sequence_number: $starting_sequence_number, timestamp: $timestamp, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Increases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 8760 hours (365 days). When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If you choose a longer stream retention period, this operation increases the time period during which records that have not yet expired are accessible. However, it does not make previous, expired data (older than the stream's previous retention period) accessible after the operation has been called. For example, if a stream's retention period is set to 24 hours and is increased to 168 hours, any data that is older than 24 hours remains inaccessible to consumer applications.
#
# POST /
# operationId: IncreaseStreamRetentionPeriod
export def "increase-stream-retention-period" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
  --stream-name: string # The name of the stream to modify.
  retention_period_hours: int # The new retention period of the stream, in hours. Must be more than the current retention period.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.IncreaseStreamRetentionPeriod"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: RetentionPeriodHours, var: retention_period_hours}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, retention_period_hours: $retention_period_hours, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the shards in a stream and provides information about each shard. This operation has a limit of 1000 transactions per second per data stream. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. This action does not list expired shards. For information about expired shards, see Data Routing, Data Persistence, and Shard State after a Reshard (https://docs.aws.amazon.com/streams/latest/dev/kinesis-using-sdk-java-after-resharding.html#kinesis-using-sdk-java-resharding-data-routing). This API is a new operation that is used by the Amazon Kinesis Client Library (KCL). If you have a fine-grained IAM policy that only allows specific operations, you must update your policy to allow calls to this API. For more information, see Controlling Access to Amazon Kinesis Data Streams Resources Using IAM (https://docs.aws.amazon.com/streams/latest/dev/controlling-access.html).
#
# POST /
# Returns: record<Shards: table<ShardId: string, ParentShardId: string, AdjacentParentShardId: string, HashKeyRange: record, SequenceNumberRange: record>, NextToken: string>
# operationId: ListShards
export def "list-shards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  --stream-name: string # The name of the data stream whose shards you want to list. You cannot specify this parameter if you specify the NextToken parameter.
  --next-token: string # When the number of shards in the data stream is greater than the default value for the MaxResults parameter, or if you explicitly specify a value for MaxResults that is less than the number of shards in the data stream, the response includes a pagination token named NextToken. You can specify this NextToken value in a subsequent call to ListShards to list the next set of shards. Don't specify StreamName or StreamCreationTimestamp if you specify NextToken because the latter unambiguously identifies the stream. You can optionally specify a value for the MaxResults parameter when you specify NextToken. If you specify a MaxResults value that is less than the number of shards that the operation returns if you don't specify MaxResults, the response will contain a new NextToken value. You can use the new NextToken value in a subsequent call to the ListShards operation. Tokens expire after 300 seconds. When you obtain a value for NextToken in the response to a call to ListShards, you have 300 seconds to use that value. If you specify an expired token in a call to ListShards, you get ExpiredNextTokenException.
  --exclusive-start-shard-id: string # Specify this parameter to indicate that you want to list the shards starting with the shard whose ID immediately follows ExclusiveStartShardId. If you don't specify this parameter, the default behavior is for ListShards to list the shards starting with the first one in the stream. You cannot specify this parameter if you specify NextToken.
  --max-results: int # The maximum number of shards to return in a single call to ListShards. The maximum number of shards to return in a single call. The default value is 1000. If you specify a value greater than 1000, at most 1000 results are returned. When the number of shards to be listed is greater than the value of MaxResults, the response contains a NextToken value that you can use in a subsequent call to ListShards to list the next set of shards.
  --stream-creation-timestamp: string # Specify this input parameter to distinguish data streams that have the same name. For example, if you create a data stream and then delete it, and you later create another data stream with the same name, you can use this input parameter to specify which of the two streams you want to list the shards for. You cannot specify this parameter if you specify the NextToken parameter. (format: date-time)
  --shard-filter: record # The request parameter used to filter out the response of the ListShards API. — shape: {Type: "AFTER_SHARD_ID"|"AT_TRIM_HORIZON"|"FROM_TRIM_HORIZON"|"AT_LATEST"|"AT_TIMESTAMP"|"FROM_TIMESTAMP", ShardId?: string, Timestamp?: string}
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.ListShards"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: NextToken, var: next_token}, {name: ExclusiveStartShardId, var: exclusive_start_shard_id}, {name: MaxResults, var: max_results}, {name: StreamCreationTimestamp, var: stream_creation_timestamp}, {name: ShardFilter, var: shard_filter}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, next_token: $next_token, exclusive_start_shard_id: $exclusive_start_shard_id, max_results: $max_results, stream_creation_timestamp: $stream_creation_timestamp, shard_filter: $shard_filter, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the consumers registered to receive data from a stream using enhanced fan-out, and provides information about each consumer. This operation has a limit of 5 transactions per second per stream.
#
# POST /
# Returns: record<Consumers: table<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string>, NextToken: string>
# operationId: ListStreamConsumers
export def "list-stream-consumers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  stream_arn: string # The ARN of the Kinesis data stream for which you want to list the registered consumers. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  --body-next-token: string # When the number of consumers that are registered with the data stream is greater than the default value for the MaxResults parameter, or if you explicitly specify a value for MaxResults that is less than the number of consumers that are registered with the data stream, the response includes a pagination token named NextToken. You can specify this NextToken value in a subsequent call to ListStreamConsumers to list the next set of registered consumers. Don't specify StreamName or StreamCreationTimestamp if you specify NextToken because the latter unambiguously identifies the stream. You can optionally specify a value for the MaxResults parameter when you specify NextToken. If you specify a MaxResults value that is less than the number of consumers that the operation returns if you don't specify MaxResults, the response will contain a new NextToken value. You can use the new NextToken value in a subsequent call to the ListStreamConsumers operation to list the next set of consumers. Tokens expire after 300 seconds. When you obtain a value for NextToken in the response to a call to ListStreamConsumers, you have 300 seconds to use that value. If you specify an expired token in a call to ListStreamConsumers, you get ExpiredNextTokenException. (spec name: NextToken)
  --body-max-results: int # The maximum number of consumers that you want a single call of ListStreamConsumers to return. The default value is 100. If you specify a value greater than 100, at most 100 results are returned. (spec name: MaxResults)
  --stream-creation-timestamp: string # Specify this input parameter to distinguish data streams that have the same name. For example, if you create a data stream and then delete it, and you later create another data stream with the same name, you can use this input parameter to specify which of the two streams you want to list the consumers for. You can't specify this parameter if you specify the NextToken parameter. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.ListStreamConsumers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamARN, var: stream_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: StreamCreationTimestamp, var: stream_creation_timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_arn: $stream_arn, body_next_token: $body_next_token, body_max_results: $body_max_results, stream_creation_timestamp: $stream_creation_timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your Kinesis data streams. The number of streams may be too large to return from a single call to ListStreams. You can limit the number of returned streams using the Limit parameter. If you do not specify a value for the Limit parameter, Kinesis Data Streams uses the default limit, which is currently 100. You can detect if there are more streams available to list by using the HasMoreStreams flag from the returned output. If there are more streams available, you can request more streams by using the name of the last stream returned by the ListStreams request in the ExclusiveStartStreamName parameter in a subsequent request to ListStreams. The group of stream names returned by the subsequent request is then added to the list. You can continue this process until all the stream names have been collected in the list. ListStreams has a limit of five transactions per second per account.
#
# POST /
# Returns: record<StreamNames: list<string>, HasMoreStreams: bool, NextToken: string, StreamSummaries: table<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record, StreamCreationTimestamp: string>>
# operationId: ListStreams
export def "list-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  --body-limit: int # The maximum number of streams to list. The default value is 100. If you specify a value greater than 100, at most 100 results are returned. (spec name: Limit)
  --exclusive-start-stream-name: string # The name of the stream to start the list with.
  --body-next-token: string # (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.ListStreams"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Limit, var: body_limit}, {name: ExclusiveStartStreamName, var: exclusive_start_stream_name}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_limit: $body_limit, exclusive_start_stream_name: $exclusive_start_stream_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for the specified Kinesis data stream. This operation has a limit of five transactions per second per account. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>, HasMoreTags: bool>
# operationId: ListTagsForStream
export def "list-tags-for-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  --stream-name: string # The name of the stream.
  --exclusive-start-tag-key: string # The key to use as the starting point for the list of tags. If this parameter is set, ListTagsForStream gets all tags that occur after ExclusiveStartTagKey.
  --limit: int # The number of tags to return. If this number is less than the total number of tags associated with the stream, HasMoreTags is set to true. To list additional tags, set ExclusiveStartTagKey to the last key in the response.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.ListTagsForStream"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: ExclusiveStartTagKey, var: exclusive_start_tag_key}, {name: Limit, var: limit}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, exclusive_start_tag_key: $exclusive_start_tag_key, limit: $limit, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merges two adjacent shards in a Kinesis data stream and combines them into a single shard to reduce the stream's capacity to ingest and transport data. This API is only supported for the data streams with the provisioned capacity mode. Two shards are considered adjacent if the union of the hash key ranges for the two shards form a contiguous set with no gaps. For example, if you have two shards, one with a hash key range of 276...381 and the other with a hash key range of 382...454, then you could merge these two shards into a single shard that would have a hash key range of 276...454. After the merge, the single child shard receives data for all hash key values covered by the two parent shards. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. MergeShards is called when there is a need to reduce the overall capacity of a stream because of excess capacity that is not being used. You must specify the shard to be merged and the adjacent shard for a stream. For more information about merging shards, see Merge Two Shards (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-merge.html) in the Amazon Kinesis Data Streams Developer Guide. If the stream is in the ACTIVE state, you can call MergeShards. If a stream is in the CREATING, UPDATING, or DELETING state, MergeShards returns a ResourceInUseException. If the specified stream does not exist, MergeShards returns a ResourceNotFoundException. You can use DescribeStreamSummary to check the state of the stream, which is returned in StreamStatus. MergeShards is an asynchronous operation. Upon receiving a MergeShards request, Amazon Kinesis Data Streams immediately returns a response and sets the StreamStatus to UPDATING. After the operation is completed, Kinesis Data Streams sets the StreamStatus to ACTIVE. Read and write operations continue to work while the stream is in the UPDATING state. You use DescribeStreamSummary and the ListShards APIs to determine the shard IDs that are specified in the MergeShards request. If you try to operate on too many streams in parallel using CreateStream, DeleteStream, MergeShards, or SplitShard, you receive a LimitExceededException. MergeShards has a limit of five transactions per second per account.
#
# POST /
# operationId: MergeShards
export def "merge-shards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  --stream-name: string # The name of the stream for the merge.
  shard_to_merge: string # The shard ID of the shard to combine with the adjacent shard for the merge.
  adjacent_shard_to_merge: string # The shard ID of the adjacent shard for the merge.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.MergeShards"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: ShardToMerge, var: shard_to_merge}, {name: AdjacentShardToMerge, var: adjacent_shard_to_merge}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, shard_to_merge: $shard_to_merge, adjacent_shard_to_merge: $adjacent_shard_to_merge, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Writes a single data record into an Amazon Kinesis data stream. Call PutRecord to send data into the stream for real-time ingestion and subsequent processing, one record at a time. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MiB per second. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. You must specify the name of the stream that captures, stores, and transports the data; a partition key; and the data blob itself. The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on. The partition key is used by Kinesis Data Streams to distribute data across shards. Kinesis Data Streams segregates the data records that belong to a stream into multiple shards, using the partition key associated with each data record to determine the shard to which a given data record belongs. Partition keys are Unicode strings, with a maximum length limit of 256 characters for each key. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards using the hash key ranges of the shards. You can override hashing the partition key to determine the shard by explicitly specifying a hash value using the ExplicitHashKey parameter. For more information, see Adding Data to a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream) in the Amazon Kinesis Data Streams Developer Guide. PutRecord returns the shard ID of where the data record was placed and the sequence number that was assigned to the data record. Sequence numbers increase over time and are specific to a shard within a stream, not across all shards within a stream. To guarantee strictly increasing ordering, write serially to a shard and use the SequenceNumberForOrdering parameter. For more information, see Adding Data to a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream) in the Amazon Kinesis Data Streams Developer Guide. After you write a record to a stream, you cannot modify that record or its order within the stream. If a PutRecord request cannot be processed because of insufficient provisioned throughput on the shard involved in the request, PutRecord throws ProvisionedThroughputExceededException. By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use IncreaseStreamRetentionPeriod or DecreaseStreamRetentionPeriod to modify this retention period.
#
# POST /
# Returns: record<ShardId: string, SequenceNumber: string, EncryptionType: string>
# operationId: PutRecord
export def "put-record" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  --stream-name: string # The name of the stream to put the data record into.
  data: string # The data blob to put into the record, which is base64-encoded when the blob is serialized. When the data blob (the payload before base64-encoding) is added to the partition key size, the total size must not exceed the maximum record size (1 MiB).
  partition_key: string # Determines which shard in the stream the data record is assigned to. Partition keys are Unicode strings with a maximum length limit of 256 characters for each key. Amazon Kinesis Data Streams uses the partition key as input to a hash function that maps the partition key and associated data to a specific shard. Specifically, an MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards. As a result of this hashing mechanism, all data records with the same partition key map to the same shard within the stream.
  --explicit-hash-key: string # The hash value used to explicitly determine the shard the data record is assigned to by overriding the partition key hash.
  --sequence-number-for-ordering: string # Guarantees strictly increasing sequence numbers, for puts from the same client and to the same partition key. Usage: set the SequenceNumberForOrdering of record n to the sequence number of record n-1 (as returned in the result when putting record n-1). If this parameter is not set, records are coarsely ordered based on arrival time.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.PutRecord"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: Data, var: data}, {name: PartitionKey, var: partition_key}, {name: ExplicitHashKey, var: explicit_hash_key}, {name: SequenceNumberForOrdering, var: sequence_number_for_ordering}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, data: $data, partition_key: $partition_key, explicit_hash_key: $explicit_hash_key, sequence_number_for_ordering: $sequence_number_for_ordering, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Writes multiple data records into a Kinesis data stream in a single call (also referred to as a PutRecords request). Use this operation to send data into the stream for data ingestion and processing. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. Each PutRecords request can support up to 500 records. Each record in the request can be as large as 1 MiB, up to a limit of 5 MiB for the entire request, including partition keys. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MiB per second. You must specify the name of the stream that captures, stores, and transports the data; and an array of request Records, with each record in the array requiring a partition key and data blob. The record size limit applies to the total size of the partition key and data blob. The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on. The partition key is used by Kinesis Data Streams as input to a hash function that maps the partition key and associated data to a specific shard. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards. As a result of this hashing mechanism, all data records with the same partition key map to the same shard within the stream. For more information, see Adding Data to a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream) in the Amazon Kinesis Data Streams Developer Guide. Each record in the Records array may include an optional parameter, ExplicitHashKey, which overrides the partition key to shard mapping. This parameter allows a data producer to determine explicitly the shard where the record is stored. For more information, see Adding Multiple Records with PutRecords (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-putrecords) in the Amazon Kinesis Data Streams Developer Guide. The PutRecords response includes an array of response Records. Each record in the response array directly correlates with a record in the request array using natural ordering, from the top to the bottom of the request and response. The response Records array always includes the same number of records as the request array. The response Records array includes both successfully and unsuccessfully processed records. Kinesis Data Streams attempts to process all records in each PutRecords request. A single record failure does not stop the processing of subsequent records. As a result, PutRecords doesn't guarantee the ordering of records. If you need to read records in the same order they are written to the stream, use PutRecord instead of PutRecords, and write to the same shard. A successfully processed record includes ShardId and SequenceNumber values. The ShardId parameter identifies the shard in the stream where the record is stored. The SequenceNumber parameter is an identifier assigned to the put record, unique to all records in the stream. An unsuccessfully processed record includes ErrorCode and ErrorMessage values. ErrorCode reflects the type of error and can be one of the following values: ProvisionedThroughputExceededException or InternalFailure. ErrorMessage provides more detailed information about the ProvisionedThroughputExceededException exception including the account ID, stream name, and shard ID of the record that was throttled. For more information about partially successful responses, see Adding Multiple Records with PutRecords (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-add-data-to-stream.html#kinesis-using-sdk-java-putrecords) in the Amazon Kinesis Data Streams Developer Guide. After you write a record to a stream, you cannot modify that record or its order within the stream. By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use IncreaseStreamRetentionPeriod or DecreaseStreamRetentionPeriod to modify this retention period.
#
# POST /
# Returns: record<FailedRecordCount: int, Records: table<SequenceNumber: string, ShardId: string, ErrorCode: string, ErrorMessage: string>, EncryptionType: string>
# operationId: PutRecords
export def "put-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  records: list # The records associated with the request. — item shape: {Data: string, ExplicitHashKey?: string, PartitionKey: string}
  --stream-name: string # The stream name associated with the request.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.PutRecords"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Records, var: records}, {name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, records: $records, stream_name: $stream_name, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a consumer with a Kinesis data stream. When you use this operation, the consumer you register can then call SubscribeToShard to receive data from the stream using enhanced fan-out, at a rate of up to 2 MiB per second for every shard you subscribe to. This rate is unaffected by the total number of consumers that read from the same stream. You can register up to 20 consumers per stream. A given consumer can only be registered with one stream at a time. For an example of how to use this operations, see Enhanced Fan-Out Using the Kinesis Data Streams API (/streams/latest/dev/building-enhanced-consumers-api.html). The use of this operation has a limit of five transactions per second per account. Also, only 5 consumers can be created simultaneously. In other words, you cannot have more than 5 consumers in a CREATING status at the same time. Registering a 6th consumer while there are 5 in a CREATING status results in a LimitExceededException.
#
# POST /
# Returns: record<Consumer: record<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string>>
# operationId: RegisterStreamConsumer
export def "register-stream-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  stream_arn: string # The ARN of the Kinesis data stream that you want to register the consumer with. For more info, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  consumer_name: string # For a given Kinesis data stream, each consumer must have a unique name. However, consumer names don't have to be unique across data streams.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.RegisterStreamConsumer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamARN, var: stream_arn}, {name: ConsumerName, var: consumer_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_arn: $stream_arn, consumer_name: $consumer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from the specified Kinesis data stream. Removed tags are deleted and cannot be recovered after this operation successfully completes. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If you specify a tag that does not exist, it is ignored. RemoveTagsFromStream has a limit of five transactions per second per account.
#
# POST /
# operationId: RemoveTagsFromStream
export def "remove-tags-from-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  --stream-name: string # The name of the stream.
  tag_keys: list<string> # A list of tag keys. Each corresponding tag is removed from the stream.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.RemoveTagsFromStream"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: TagKeys, var: tag_keys}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, tag_keys: $tag_keys, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Splits a shard into two new shards in the Kinesis data stream, to increase the stream's capacity to ingest and transport data. SplitShard is called when there is a need to increase the overall capacity of a stream because of an expected increase in the volume of data records being ingested. This API is only supported for the data streams with the provisioned capacity mode. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. You can also use SplitShard when a shard appears to be approaching its maximum utilization; for example, the producers sending data into the specific shard are suddenly sending more than previously anticipated. You can also call SplitShard to increase stream capacity, so that more Kinesis Data Streams applications can simultaneously read data from the stream for real-time processing. You must specify the shard to be split and the new hash key, which is the position in the shard where the shard gets split in two. In many cases, the new hash key might be the average of the beginning and ending hash key, but it can be any hash key value in the range being mapped into the shard. For more information, see Split a Shard (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-split.html) in the Amazon Kinesis Data Streams Developer Guide. You can use DescribeStreamSummary and the ListShards APIs to determine the shard ID and hash key values for the ShardToSplit and NewStartingHashKey parameters that are specified in the SplitShard request. SplitShard is an asynchronous operation. Upon receiving a SplitShard request, Kinesis Data Streams immediately returns a response and sets the stream status to UPDATING. After the operation is completed, Kinesis Data Streams sets the stream status to ACTIVE. Read and write operations continue to work while the stream is in the UPDATING state. You can use DescribeStreamSummary to check the status of the stream, which is returned in StreamStatus. If the stream is in the ACTIVE state, you can call SplitShard. If the specified stream does not exist, DescribeStreamSummary returns a ResourceNotFoundException. If you try to create more shards than are authorized for your account, you receive a LimitExceededException. For the default shard limit for an Amazon Web Services account, see Kinesis Data Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. To increase this limit, contact Amazon Web Services Support (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html). If you try to operate on too many streams simultaneously using CreateStream, DeleteStream, MergeShards, and/or SplitShard, you receive a LimitExceededException. SplitShard has a limit of five transactions per second per account.
#
# POST /
# operationId: SplitShard
export def "split-shard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  --stream-name: string # The name of the stream for the shard split.
  shard_to_split: string # The shard ID of the shard to split.
  new_starting_hash_key: string # A hash key value for the starting hash key of one of the child shards created by the split. The hash key range for a given shard constitutes a set of ordered contiguous positive integers. The value for NewStartingHashKey must be in the range of hash keys being mapped into the shard. The NewStartingHashKey hash key value and all higher hash key values in hash key range are distributed to one of the child shards. All the lower hash key values in the range are distributed to the other child shard.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.SplitShard"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: ShardToSplit, var: shard_to_split}, {name: NewStartingHashKey, var: new_starting_hash_key}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, shard_to_split: $shard_to_split, new_starting_hash_key: $new_starting_hash_key, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or updates server-side encryption using an Amazon Web Services KMS key for a specified stream. Starting encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to UPDATING. After the update is complete, Kinesis Data Streams sets the status of the stream back to ACTIVE. Updating or applying encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is UPDATING. Once the status of the stream is ACTIVE, encryption begins for records written to the stream. API Limits: You can successfully apply a new Amazon Web Services KMS key for server-side encryption 25 times in a rolling 24-hour period. Note: It can take up to 5 seconds after the stream is in an ACTIVE status before all records written to the stream are encrypted. After you enable encryption, you can verify that encryption is applied by inspecting the API response from PutRecord or PutRecords. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# operationId: StartStreamEncryption
export def "start-stream-encryption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  --stream-name: string # The name of the stream for which to start encrypting records.
  encryption_type: string@encryption-type-completer # The encryption type to use. The only valid value is KMS.
  key_id: string # The GUID for the customer-managed Amazon Web Services KMS key to use for encryption. This value can be a globally unique identifier, a fully specified Amazon Resource Name (ARN) to either an alias or a key, or an alias name prefixed by "alias/".You can also use a master key owned by Kinesis Data Streams by specifying the alias aws/kinesis. Key ARN example: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012 Alias ARN example: arn:aws:kms:us-east-1:123456789012:alias/MyAliasName Globally unique key ID example: 12345678-1234-1234-1234-123456789012 Alias name example: alias/MyAliasName Master key owned by Kinesis Data Streams: alias/aws/kinesis
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.StartStreamEncryption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: EncryptionType, var: encryption_type}, {name: KeyId, var: key_id}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, encryption_type: $encryption_type, key_id: $key_id, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables server-side encryption for a specified stream. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. Stopping encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to UPDATING. After the update is complete, Kinesis Data Streams sets the status of the stream back to ACTIVE. Stopping encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is UPDATING. Once the status of the stream is ACTIVE, records written to the stream are no longer encrypted by Kinesis Data Streams. API Limits: You can successfully disable server-side encryption 25 times in a rolling 24-hour period. Note: It can take up to 5 seconds after the stream is in an ACTIVE status before all records written to the stream are no longer subject to encryption. After you disabled encryption, you can verify that encryption is not applied by inspecting the API response from PutRecord or PutRecords.
#
# POST /
# operationId: StopStreamEncryption
export def "stop-stream-encryption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  --stream-name: string # The name of the stream on which to stop encrypting records.
  encryption_type: string@encryption-type-completer # The encryption type. The only valid value is KMS.
  key_id: string # The GUID for the customer-managed Amazon Web Services KMS key to use for encryption. This value can be a globally unique identifier, a fully specified Amazon Resource Name (ARN) to either an alias or a key, or an alias name prefixed by "alias/".You can also use a master key owned by Kinesis Data Streams by specifying the alias aws/kinesis. Key ARN example: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012 Alias ARN example: arn:aws:kms:us-east-1:123456789012:alias/MyAliasName Globally unique key ID example: 12345678-1234-1234-1234-123456789012 Alias name example: alias/MyAliasName Master key owned by Kinesis Data Streams: alias/aws/kinesis
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.StopStreamEncryption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: EncryptionType, var: encryption_type}, {name: KeyId, var: key_id}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, encryption_type: $encryption_type, key_id: $key_id, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the shard count of the specified stream to the specified number of shards. This API is only supported for the data streams with the provisioned capacity mode. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. Updating the shard count is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to UPDATING. After the update is complete, Kinesis Data Streams sets the status of the stream back to ACTIVE. Depending on the size of the stream, the scaling action could take a few minutes to complete. You can continue to read and write data to your stream while its status is UPDATING. To update the shard count, Kinesis Data Streams performs splits or merges on individual shards. This can cause short-lived shards to be created, in addition to the final shards. These short-lived shards count towards your total shard limit for your account in the Region. When using this operation, we recommend that you specify a target shard count that is a multiple of 25% (25%, 50%, 75%, 100%). You can specify any target value within your shard limit. However, if you specify a target that isn't a multiple of 25%, the scaling action might take longer to complete. This operation has the following default limits. By default, you cannot do the following: Scale more than ten times per rolling 24-hour period per stream Scale up to more than double your current shard count for a stream Scale down below half your current shard count for a stream Scale up to more than 10000 shards in a stream Scale a stream with more than 10000 shards down unless the result is less than 10000 shards Scale up to more than the shard limit for your account For the default limits for an Amazon Web Services account, see Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. To request an increase in the call rate limit, the shard limit for this API, or your overall shard limit, use the limits form (https://console.aws.amazon.com/support/v1#/case/create?issueType=service-limit-increase&limitType=service-code-kinesis).
#
# POST /
# Returns: record<StreamName: string, CurrentShardCount: int, TargetShardCount: int, StreamARN: string>
# operationId: UpdateShardCount
export def "update-shard-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  --stream-name: string # The name of the stream.
  target_shard_count: int # The new number of shards. This value has the following default limits. By default, you cannot do the following: Set this value to more than double your current shard count for a stream. Set this value below half your current shard count for a stream. Set this value to more than 10000 shards in a stream (the default limit for shard count per stream is 10000 per account per region), unless you request a limit increase. Scale a stream with more than 10000 shards down unless you set this value to less than 10000 shards.
  scaling_type: string@scaling-type-completer # The scaling type. Uniform scaling creates shards of equal size.
  --stream-arn: string # The ARN of the stream.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.UpdateShardCount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: TargetShardCount, var: target_shard_count}, {name: ScalingType, var: scaling_type}, {name: StreamARN, var: stream_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_name: $stream_name, target_shard_count: $target_shard_count, scaling_type: $scaling_type, stream_arn: $stream_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the capacity mode of the data stream. Currently, in Kinesis Data Streams, you can choose between an on-demand capacity mode and a provisioned capacity mode for your data stream.
#
# POST /
# operationId: UpdateStreamMode
export def "update-stream-mode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  stream_arn: string # Specifies the ARN of the data stream whose capacity mode you want to update.
  stream_mode_details: record # Specifies the capacity mode to which you want to set your data stream. Currently, in Kinesis Data Streams, you can choose between an on-demand capacity mode and a provisioned capacity mode for your data streams. — shape: {StreamMode: "PROVISIONED"|"ON_DEMAND"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Kinesis_20131202.UpdateStreamMode"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamARN, var: stream_arn}, {name: StreamModeDetails, var: stream_mode_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stream_arn: $stream_arn, stream_mode_details: $stream_mode_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
