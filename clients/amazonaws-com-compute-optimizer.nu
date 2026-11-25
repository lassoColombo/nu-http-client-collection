# Auto-generated client for AWS Compute Optimizer v2019-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/compute-optimizer/2019-11-01/openapi.json
# Auth: --token flag or $env.AWS_COMPUTE_OPTIMIZER_TOKEN

const CLIENT = {
  base_url: "http://compute-optimizer.us-east-1.amazonaws.com"
  token_env_var: "AWS_COMPUTE_OPTIMIZER_TOKEN"
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

def base-url-completer [] { ["http://compute-optimizer.us-east-1.amazonaws.com" "http://compute-optimizer.us-east-2.amazonaws.com" "http://compute-optimizer.us-west-1.amazonaws.com" "http://compute-optimizer.us-west-2.amazonaws.com" "http://compute-optimizer.us-gov-west-1.amazonaws.com" "http://compute-optimizer.us-gov-east-1.amazonaws.com" "http://compute-optimizer.ca-central-1.amazonaws.com" "http://compute-optimizer.eu-north-1.amazonaws.com" "http://compute-optimizer.eu-west-1.amazonaws.com" "http://compute-optimizer.eu-west-2.amazonaws.com" "http://compute-optimizer.eu-west-3.amazonaws.com" "http://compute-optimizer.eu-central-1.amazonaws.com" "http://compute-optimizer.eu-south-1.amazonaws.com" "http://compute-optimizer.af-south-1.amazonaws.com" "http://compute-optimizer.ap-northeast-1.amazonaws.com" "http://compute-optimizer.ap-northeast-2.amazonaws.com" "http://compute-optimizer.ap-northeast-3.amazonaws.com" "http://compute-optimizer.ap-southeast-1.amazonaws.com" "http://compute-optimizer.ap-southeast-2.amazonaws.com" "http://compute-optimizer.ap-east-1.amazonaws.com" "http://compute-optimizer.ap-south-1.amazonaws.com" "http://compute-optimizer.sa-east-1.amazonaws.com" "http://compute-optimizer.me-south-1.amazonaws.com" "https://compute-optimizer.us-east-1.amazonaws.com" "https://compute-optimizer.us-east-2.amazonaws.com" "https://compute-optimizer.us-west-1.amazonaws.com" "https://compute-optimizer.us-west-2.amazonaws.com" "https://compute-optimizer.us-gov-west-1.amazonaws.com" "https://compute-optimizer.us-gov-east-1.amazonaws.com" "https://compute-optimizer.ca-central-1.amazonaws.com" "https://compute-optimizer.eu-north-1.amazonaws.com" "https://compute-optimizer.eu-west-1.amazonaws.com" "https://compute-optimizer.eu-west-2.amazonaws.com" "https://compute-optimizer.eu-west-3.amazonaws.com" "https://compute-optimizer.eu-central-1.amazonaws.com" "https://compute-optimizer.eu-south-1.amazonaws.com" "https://compute-optimizer.af-south-1.amazonaws.com" "https://compute-optimizer.ap-northeast-1.amazonaws.com" "https://compute-optimizer.ap-northeast-2.amazonaws.com" "https://compute-optimizer.ap-northeast-3.amazonaws.com" "https://compute-optimizer.ap-southeast-1.amazonaws.com" "https://compute-optimizer.ap-southeast-2.amazonaws.com" "https://compute-optimizer.ap-east-1.amazonaws.com" "https://compute-optimizer.ap-south-1.amazonaws.com" "https://compute-optimizer.sa-east-1.amazonaws.com" "https://compute-optimizer.me-south-1.amazonaws.com" "http://compute-optimizer.cn-north-1.amazonaws.com.cn" "http://compute-optimizer.cn-northwest-1.amazonaws.com.cn" "https://compute-optimizer.cn-north-1.amazonaws.com.cn" "https://compute-optimizer.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-type-completer [] { ["AutoScalingGroup" "EbsVolume" "Ec2Instance" "EcsService" "LambdaFunction" "NotApplicable"] }
def x-amz-target-completer [] { ["ComputeOptimizerService.DeleteRecommendationPreferences"] }
def x-amz-target-completer-1 [] { ["ComputeOptimizerService.DescribeRecommendationExportJobs"] }
def file-format-completer [] { ["Csv"] }
def x-amz-target-completer-2 [] { ["ComputeOptimizerService.ExportAutoScalingGroupRecommendations"] }
def x-amz-target-completer-3 [] { ["ComputeOptimizerService.ExportEBSVolumeRecommendations"] }
def x-amz-target-completer-4 [] { ["ComputeOptimizerService.ExportEC2InstanceRecommendations"] }
def x-amz-target-completer-5 [] { ["ComputeOptimizerService.ExportECSServiceRecommendations"] }
def x-amz-target-completer-6 [] { ["ComputeOptimizerService.ExportLambdaFunctionRecommendations"] }
def x-amz-target-completer-7 [] { ["ComputeOptimizerService.GetAutoScalingGroupRecommendations"] }
def x-amz-target-completer-8 [] { ["ComputeOptimizerService.GetEBSVolumeRecommendations"] }
def x-amz-target-completer-9 [] { ["ComputeOptimizerService.GetEC2InstanceRecommendations"] }
def stat-completer [] { ["Average" "Maximum"] }
def x-amz-target-completer-10 [] { ["ComputeOptimizerService.GetEC2RecommendationProjectedMetrics"] }
def x-amz-target-completer-11 [] { ["ComputeOptimizerService.GetECSServiceRecommendationProjectedMetrics"] }
def x-amz-target-completer-12 [] { ["ComputeOptimizerService.GetECSServiceRecommendations"] }
def x-amz-target-completer-13 [] { ["ComputeOptimizerService.GetEffectiveRecommendationPreferences"] }
def x-amz-target-completer-14 [] { ["ComputeOptimizerService.GetEnrollmentStatus"] }
def x-amz-target-completer-15 [] { ["ComputeOptimizerService.GetEnrollmentStatusesForOrganization"] }
def x-amz-target-completer-16 [] { ["ComputeOptimizerService.GetLambdaFunctionRecommendations"] }
def x-amz-target-completer-17 [] { ["ComputeOptimizerService.GetRecommendationPreferences"] }
def x-amz-target-completer-18 [] { ["ComputeOptimizerService.GetRecommendationSummaries"] }
def enhanced-infrastructure-metrics-completer [] { ["Active" "Inactive"] }
def inferred-workload-types-completer [] { ["Active" "Inactive"] }
def x-amz-target-completer-19 [] { ["ComputeOptimizerService.PutRecommendationPreferences"] }
def status-completer [] { ["Active" "Failed" "Inactive" "Pending"] }
def x-amz-target-completer-20 [] { ["ComputeOptimizerService.UpdateEnrollmentStatus"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    delete-recommendation-preferences: "record"
    describe-recommendation-export-jobs: "record<recommendationExportJobs: table<jobId: string, destination: record, resourceType: string, status: string, creationTimestamp: string, lastUpdatedTimestamp: string, failureReason: string>, nextToken: string>"
    export-auto-scaling-group-recommendations: "record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>"
    export-ebs-volume-recommendations: "record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>"
    export-ec2-instance-recommendations: "record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>"
    export-ecs-service-recommendations: "record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>"
    export-lambda-function-recommendations: "record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>"
    get-auto-scaling-group-recommendations: "record<nextToken: string, autoScalingGroupRecommendations: table<accountId: string, autoScalingGroupArn: string, autoScalingGroupName: string, finding: string, utilizationMetrics: list, lookBackPeriodInDays: float, currentConfiguration: record, recommendationOptions: list, lastRefreshTimestamp: string, currentPerformanceRisk: string, effectiveRecommendationPreferences: record, inferredWorkloadTypes: list>, errors: table<identifier: string, code: string, message: string>>"
    get-ebs-volume-recommendations: "record<nextToken: string, volumeRecommendations: table<volumeArn: string, accountId: string, currentConfiguration: record, finding: string, utilizationMetrics: list, lookBackPeriodInDays: float, volumeRecommendationOptions: list, lastRefreshTimestamp: string, currentPerformanceRisk: string>, errors: table<identifier: string, code: string, message: string>>"
    get-ec2-instance-recommendations: "record<nextToken: string, instanceRecommendations: table<instanceArn: string, accountId: string, instanceName: string, currentInstanceType: string, finding: string, findingReasonCodes: list, utilizationMetrics: list, lookBackPeriodInDays: float, recommendationOptions: list, recommendationSources: list, lastRefreshTimestamp: string, currentPerformanceRisk: string, effectiveRecommendationPreferences: record, inferredWorkloadTypes: list, instanceState: string>, errors: table<identifier: string, code: string, message: string>>"
    get-ec2-recommendation-projected-metrics: "record<recommendedOptionProjectedMetrics: table<recommendedInstanceType: string, rank: int, projectedMetrics: list>>"
    get-ecs-service-recommendation-projected-metrics: "record<recommendedOptionProjectedMetrics: table<recommendedCpuUnits: int, recommendedMemorySize: int, projectedMetrics: list>>"
    get-ecs-service-recommendations: "record<nextToken: string, ecsServiceRecommendations: table<serviceArn: string, accountId: string, currentServiceConfiguration: record, utilizationMetrics: list, lookbackPeriodInDays: float, launchType: string, lastRefreshTimestamp: string, finding: string, findingReasonCodes: list, serviceRecommendationOptions: list, currentPerformanceRisk: string>, errors: table<identifier: string, code: string, message: string>>"
    get-effective-recommendation-preferences: "record<enhancedInfrastructureMetrics: string, externalMetricsPreference: record<source: string>>"
    get-enrollment-status: "record<status: string, statusReason: string, memberAccountsEnrolled: bool, lastUpdatedTimestamp: string, numberOfMemberAccountsOptedIn: int>"
    get-enrollment-statuses-for-organization: "record<accountEnrollmentStatuses: table<accountId: string, status: string, statusReason: string, lastUpdatedTimestamp: string>, nextToken: string>"
    get-lambda-function-recommendations: "record<nextToken: string, lambdaFunctionRecommendations: table<functionArn: string, functionVersion: string, accountId: string, currentMemorySize: int, numberOfInvocations: int, utilizationMetrics: list, lookbackPeriodInDays: float, lastRefreshTimestamp: string, finding: string, findingReasonCodes: list, memorySizeRecommendationOptions: list, currentPerformanceRisk: string>>"
    get-recommendation-preferences: "record<nextToken: string, recommendationPreferencesDetails: table<scope: record, resourceType: string, enhancedInfrastructureMetrics: string, inferredWorkloadTypes: string, externalMetricsPreference: record>>"
    get-recommendation-summaries: "record<nextToken: string, recommendationSummaries: table<summaries: list, recommendationResourceType: string, accountId: string, savingsOpportunity: record, currentPerformanceRiskRatings: record>>"
    put-recommendation-preferences: "record"
    update-enrollment-status: "record<status: string, statusReason: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-recommendation-preferences" "describe-recommendation-export-jobs" "export-auto-scaling-group-recommendations" "export-ebs-volume-recommendations" "export-ec2-instance-recommendations" "export-ecs-service-recommendations" "export-lambda-function-recommendations" "get-auto-scaling-group-recommendations" "get-ebs-volume-recommendations" "get-ec2-instance-recommendations" "get-ec2-recommendation-projected-metrics" "get-ecs-service-recommendation-projected-metrics" "get-ecs-service-recommendations" "get-effective-recommendation-preferences" "get-enrollment-status" "get-enrollment-statuses-for-organization" "get-lambda-function-recommendations" "get-recommendation-preferences" "get-recommendation-summaries" "put-recommendation-preferences" "update-enrollment-status" "commands"] | sort) } | get name | first)
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

# Deletes a recommendation preference, such as enhanced infrastructure metrics. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record
# operationId: DeleteRecommendationPreferences
export def "delete-recommendation-preferences" [
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
  resource_type: string@resource-type-completer # The target resource type of the recommendation preference to delete. The Ec2Instance option encompasses standalone instances and instances that are part of Auto Scaling groups. The AutoScalingGroup option encompasses only instances that are part of an Auto Scaling group. The valid values for this parameter are Ec2Instance and AutoScalingGroup.
  --scope: record # Describes the scope of a recommendation preference. Recommendation preferences can be created at the organization level (for management accounts of an organization only), account level, and resource level. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide. You cannot create recommendation preferences for Auto Scaling groups at the organization and account levels. You can create recommendation preferences for Auto Scaling groups only at the resource level by specifying a scope name of ResourceArn and a scope value of the Auto Scaling group Amazon Resource Name (ARN). This will configure the preference for all instances that are part of the specified Auto Scaling group. You also cannot create recommendation preferences at the resource level for instances that are part of an Auto Scaling group. You can create recommendation preferences at the resource level only for standalone instances. — shape: {name?: "Organization"|"AccountId"|"ResourceArn", value?: string}
  recommendation_preference_names: list<string> # The name of the recommendation preference to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.DeleteRecommendationPreferences"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceType, var: resource_type}, {name: scope, var: scope}, {name: recommendationPreferenceNames, var: recommendation_preference_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_type: $resource_type, scope: $scope, recommendation_preference_names: $recommendation_preference_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes recommendation export jobs created in the last seven days. Use the ExportAutoScalingGroupRecommendations or ExportEC2InstanceRecommendations actions to request an export of your recommendations. Then use the DescribeRecommendationExportJobs action to view your export jobs.
#
# POST /
# Returns: record<recommendationExportJobs: table<jobId: string, destination: record, resourceType: string, status: string, creationTimestamp: string, lastUpdatedTimestamp: string, failureReason: string>, nextToken: string>
# operationId: DescribeRecommendationExportJobs
export def "describe-recommendation-export-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  --job-ids: list<string> # The identification numbers of the export jobs to return. An export job ID is returned when you create an export using the ExportAutoScalingGroupRecommendations or ExportEC2InstanceRecommendations actions. All export jobs created in the last seven days are returned if this parameter is omitted.
  --filters: list # An array of objects to specify a filter that returns a more specific list of export jobs. — item shape: {name?: "ResourceType"|"JobStatus", values?: list<string>}
  --body-next-token: string # The token to advance to the next page of export jobs. (spec name: nextToken)
  --body-max-results: int # The maximum number of export jobs to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.DescribeRecommendationExportJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobIds, var: job_ids}, {name: filters, var: filters}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_ids: $job_ids, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports optimization recommendations for Auto Scaling groups. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Auto Scaling group export job in progress per Amazon Web Services Region.
#
# POST /
# Returns: record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>
# operationId: ExportAutoScalingGroupRecommendations
export def "export-auto-scaling-group-recommendations" [
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
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export Auto Scaling group recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Auto Scaling group recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. This parameter cannot be specified together with the account IDs parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.ExportAutoScalingGroupRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: filters, var: filters}, {name: fieldsToExport, var: fields_to_export}, {name: s3DestinationConfig, var: s3_destination_config}, {name: fileFormat, var: file_format}, {name: includeMemberAccounts, var: include_member_accounts}, {name: recommendationPreferences, var: recommendation_preferences}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_ids: $account_ids, filters: $filters, fields_to_export: $fields_to_export, s3_destination_config: $s3_destination_config, file_format: $file_format, include_member_accounts: $include_member_accounts, recommendation_preferences: $recommendation_preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports optimization recommendations for Amazon EBS volumes. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Amazon EBS volume export job in progress per Amazon Web Services Region.
#
# POST /
# Returns: record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>
# operationId: ExportEBSVolumeRecommendations
export def "export-ebs-volume-recommendations" [
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
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export Amazon EBS volume recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Amazon EBS volume recommendations. — item shape: {name?: "Finding", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. This parameter cannot be specified together with the account IDs parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.ExportEBSVolumeRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: filters, var: filters}, {name: fieldsToExport, var: fields_to_export}, {name: s3DestinationConfig, var: s3_destination_config}, {name: fileFormat, var: file_format}, {name: includeMemberAccounts, var: include_member_accounts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_ids: $account_ids, filters: $filters, fields_to_export: $fields_to_export, s3_destination_config: $s3_destination_config, file_format: $file_format, include_member_accounts: $include_member_accounts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports optimization recommendations for Amazon EC2 instances. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Amazon EC2 instance export job in progress per Amazon Web Services Region.
#
# POST /
# Returns: record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>
# operationId: ExportEC2InstanceRecommendations
export def "export-ec2-instance-recommendations" [
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
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export instance recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of instance recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.ExportEC2InstanceRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: filters, var: filters}, {name: fieldsToExport, var: fields_to_export}, {name: s3DestinationConfig, var: s3_destination_config}, {name: fileFormat, var: file_format}, {name: includeMemberAccounts, var: include_member_accounts}, {name: recommendationPreferences, var: recommendation_preferences}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_ids: $account_ids, filters: $filters, fields_to_export: $fields_to_export, s3_destination_config: $s3_destination_config, file_format: $file_format, include_member_accounts: $include_member_accounts, recommendation_preferences: $recommendation_preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports optimization recommendations for Amazon ECS services on Fargate. Recommendations are exported in a CSV file, and its metadata in a JSON file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can only have one Amazon ECS service export job in progress per Amazon Web Services Region.
#
# POST /
# Returns: record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>
# operationId: ExportECSServiceRecommendations
export def "export-ecs-service-recommendations" [
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
  --account-ids: list<string> # The Amazon Web Services account IDs for the export Amazon ECS service recommendations. If your account is the management account or the delegated administrator of an organization, use this parameter to specify the member account you want to export recommendations to. This parameter can't be specified together with the include member accounts parameter. The parameters are mutually exclusive. If this parameter or the include member accounts parameter is omitted, the recommendations for member accounts aren't included in the export. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Amazon ECS service recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The CSV file is the only export file format currently supported.
  --include-member-accounts: oneof<nothing, bool> # If your account is the management account or the delegated administrator of an organization, this parameter indicates whether to include recommendations for resources in all member accounts of the organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. If this parameter is omitted, recommendations for member accounts of the organization aren't included in the export file. If this parameter or the account ID parameter is omitted, recommendations for member accounts aren't included in the export.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.ExportECSServiceRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: filters, var: filters}, {name: fieldsToExport, var: fields_to_export}, {name: s3DestinationConfig, var: s3_destination_config}, {name: fileFormat, var: file_format}, {name: includeMemberAccounts, var: include_member_accounts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_ids: $account_ids, filters: $filters, fields_to_export: $fields_to_export, s3_destination_config: $s3_destination_config, file_format: $file_format, include_member_accounts: $include_member_accounts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports optimization recommendations for Lambda functions. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Lambda function export job in progress per Amazon Web Services Region.
#
# POST /
# Returns: record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>
# operationId: ExportLambdaFunctionRecommendations
export def "export-lambda-function-recommendations" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export Lambda function recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Lambda function recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. This parameter cannot be specified together with the account IDs parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.ExportLambdaFunctionRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: filters, var: filters}, {name: fieldsToExport, var: fields_to_export}, {name: s3DestinationConfig, var: s3_destination_config}, {name: fileFormat, var: file_format}, {name: includeMemberAccounts, var: include_member_accounts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_ids: $account_ids, filters: $filters, fields_to_export: $fields_to_export, s3_destination_config: $s3_destination_config, file_format: $file_format, include_member_accounts: $include_member_accounts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Auto Scaling group recommendations. Compute Optimizer generates recommendations for Amazon EC2 Auto Scaling groups that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record<nextToken: string, autoScalingGroupRecommendations: table<accountId: string, autoScalingGroupArn: string, autoScalingGroupName: string, finding: string, utilizationMetrics: list, lookBackPeriodInDays: float, currentConfiguration: record, recommendationOptions: list, lastRefreshTimestamp: string, currentPerformanceRisk: string, effectiveRecommendationPreferences: record, inferredWorkloadTypes: list>, errors: table<identifier: string, code: string, message: string>>
# operationId: GetAutoScalingGroupRecommendations
export def "get-auto-scaling-group-recommendations" [
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
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return Auto Scaling group recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return Auto Scaling group recommendations. Only one account ID can be specified per request.
  --auto-scaling-group-arns: list<string> # The Amazon Resource Name (ARN) of the Auto Scaling groups for which to return recommendations.
  --next-token: string # The token to advance to the next page of Auto Scaling group recommendations.
  --max-results: int # The maximum number of Auto Scaling group recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of Auto Scaling group recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetAutoScalingGroupRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: autoScalingGroupArns, var: auto_scaling_group_arns}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: filters, var: filters}, {name: recommendationPreferences, var: recommendation_preferences}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_ids: $account_ids, auto_scaling_group_arns: $auto_scaling_group_arns, next_token: $next_token, max_results: $max_results, filters: $filters, recommendation_preferences: $recommendation_preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Amazon Elastic Block Store (Amazon EBS) volume recommendations. Compute Optimizer generates recommendations for Amazon EBS volumes that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record<nextToken: string, volumeRecommendations: table<volumeArn: string, accountId: string, currentConfiguration: record, finding: string, utilizationMetrics: list, lookBackPeriodInDays: float, volumeRecommendationOptions: list, lastRefreshTimestamp: string, currentPerformanceRisk: string>, errors: table<identifier: string, code: string, message: string>>
# operationId: GetEBSVolumeRecommendations
export def "get-ebs-volume-recommendations" [
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
  --volume-arns: list<string> # The Amazon Resource Name (ARN) of the volumes for which to return recommendations.
  --next-token: string # The token to advance to the next page of volume recommendations.
  --max-results: int # The maximum number of volume recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of volume recommendations. — item shape: {name?: "Finding", values?: list<string>}
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return volume recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return volume recommendations. Only one account ID can be specified per request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetEBSVolumeRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: volumeArns, var: volume_arns}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: filters, var: filters}, {name: accountIds, var: account_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arns: $volume_arns, next_token: $next_token, max_results: $max_results, filters: $filters, account_ids: $account_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Amazon EC2 instance recommendations. Compute Optimizer generates recommendations for Amazon Elastic Compute Cloud (Amazon EC2) instances that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record<nextToken: string, instanceRecommendations: table<instanceArn: string, accountId: string, instanceName: string, currentInstanceType: string, finding: string, findingReasonCodes: list, utilizationMetrics: list, lookBackPeriodInDays: float, recommendationOptions: list, recommendationSources: list, lastRefreshTimestamp: string, currentPerformanceRisk: string, effectiveRecommendationPreferences: record, inferredWorkloadTypes: list, instanceState: string>, errors: table<identifier: string, code: string, message: string>>
# operationId: GetEC2InstanceRecommendations
export def "get-ec2-instance-recommendations" [
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
  --instance-arns: list<string> # The Amazon Resource Name (ARN) of the instances for which to return recommendations.
  --next-token: string # The token to advance to the next page of instance recommendations.
  --max-results: int # The maximum number of instance recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of instance recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return instance recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return instance recommendations. Only one account ID can be specified per request.
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetEC2InstanceRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceArns, var: instance_arns}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: filters, var: filters}, {name: accountIds, var: account_ids}, {name: recommendationPreferences, var: recommendation_preferences}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_arns: $instance_arns, next_token: $next_token, max_results: $max_results, filters: $filters, account_ids: $account_ids, recommendation_preferences: $recommendation_preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the projected utilization metrics of Amazon EC2 instance recommendations. The Cpu and Memory metrics are the only projected utilization metrics returned when you run this action. Additionally, the Memory metric is returned only for resources that have the unified CloudWatch agent installed on them. For more information, see Enabling Memory Utilization with the CloudWatch Agent (https://docs.aws.amazon.com/compute-optimizer/latest/ug/metrics.html#cw-agent).
#
# POST /
# Returns: record<recommendedOptionProjectedMetrics: table<recommendedInstanceType: string, rank: int, projectedMetrics: list>>
# operationId: GetEC2RecommendationProjectedMetrics
export def "get-ec2-recommendation-projected-metrics" [
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
  instance_arn: string # The Amazon Resource Name (ARN) of the instances for which to return recommendation projected metrics.
  stat: string@stat-completer # The statistic of the projected metrics.
  period: int # The granularity, in seconds, of the projected metrics data points.
  start_time: string # The timestamp of the first projected metrics data point to return. (format: date-time)
  end_time: string # The timestamp of the last projected metrics data point to return. (format: date-time)
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetEC2RecommendationProjectedMetrics"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceArn, var: instance_arn}, {name: stat, var: stat}, {name: period, var: period}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: recommendationPreferences, var: recommendation_preferences}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_arn: $instance_arn, stat: $stat, period: $period, start_time: $start_time, end_time: $end_time, recommendation_preferences: $recommendation_preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the projected metrics of Amazon ECS service recommendations.
#
# POST /
# Returns: record<recommendedOptionProjectedMetrics: table<recommendedCpuUnits: int, recommendedMemorySize: int, projectedMetrics: list>>
# operationId: GetECSServiceRecommendationProjectedMetrics
export def "get-ecs-service-recommendation-projected-metrics" [
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
  service_arn: string # The ARN that identifies the Amazon ECS service. The following is the format of the ARN: arn:aws:ecs:region:aws_account_id:service/cluster-name/service-name
  stat: string@stat-completer # The statistic of the projected metrics.
  period: int # The granularity, in seconds, of the projected metrics data points.
  start_time: string # The timestamp of the first projected metrics data point to return. (format: date-time)
  end_time: string # The timestamp of the last projected metrics data point to return. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetECSServiceRecommendationProjectedMetrics"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceArn, var: service_arn}, {name: stat, var: stat}, {name: period, var: period}, {name: startTime, var: start_time}, {name: endTime, var: end_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn, stat: $stat, period: $period, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Amazon ECS service recommendations. Compute Optimizer generates recommendations for Amazon ECS services on Fargate that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record<nextToken: string, ecsServiceRecommendations: table<serviceArn: string, accountId: string, currentServiceConfiguration: record, utilizationMetrics: list, lookbackPeriodInDays: float, launchType: string, lastRefreshTimestamp: string, finding: string, findingReasonCodes: list, serviceRecommendationOptions: list, currentPerformanceRisk: string>, errors: table<identifier: string, code: string, message: string>>
# operationId: GetECSServiceRecommendations
export def "get-ecs-service-recommendations" [
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
  --service-arns: list<string> # The ARN that identifies the Amazon ECS service. The following is the format of the ARN: arn:aws:ecs:region:aws_account_id:service/cluster-name/service-name
  --next-token: string # The token to advance to the next page of Amazon ECS service recommendations.
  --max-results: int # The maximum number of Amazon ECS service recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of Amazon ECS service recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --account-ids: list<string> # Return the Amazon ECS service recommendations to the specified Amazon Web Services account IDs. If your account is the management account or the delegated administrator of an organization, use this parameter to return the Amazon ECS service recommendations to specific member accounts. You can only specify one account ID per request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetECSServiceRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceArns, var: service_arns}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: filters, var: filters}, {name: accountIds, var: account_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arns: $service_arns, next_token: $next_token, max_results: $max_results, filters: $filters, account_ids: $account_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the recommendation preferences that are in effect for a given resource, such as enhanced infrastructure metrics. Considers all applicable preferences that you might have set at the resource, account, and organization level. When you create a recommendation preference, you can set its status to Active or Inactive. Use this action to view the recommendation preferences that are in effect, or Active.
#
# POST /
# Returns: record<enhancedInfrastructureMetrics: string, externalMetricsPreference: record<source: string>>
# operationId: GetEffectiveRecommendationPreferences
export def "get-effective-recommendation-preferences" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource for which to confirm effective recommendation preferences. Only EC2 instance and Auto Scaling group ARNs are currently supported.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetEffectiveRecommendationPreferences"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the enrollment (opt in) status of an account to the Compute Optimizer service. If the account is the management account of an organization, this action also confirms the enrollment status of member accounts of the organization. Use the GetEnrollmentStatusesForOrganization action to get detailed information about the enrollment status of member accounts of an organization.
#
# POST /
# Returns: record<status: string, statusReason: string, memberAccountsEnrolled: bool, lastUpdatedTimestamp: string, numberOfMemberAccountsOptedIn: int>
# operationId: GetEnrollmentStatus
export def "get-enrollment-status" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetEnrollmentStatus"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Compute Optimizer enrollment (opt-in) status of organization member accounts, if your account is an organization management account. To get the enrollment status of standalone accounts, use the GetEnrollmentStatus action.
#
# POST /
# Returns: record<accountEnrollmentStatuses: table<accountId: string, status: string, statusReason: string, lastUpdatedTimestamp: string>, nextToken: string>
# operationId: GetEnrollmentStatusesForOrganization
export def "get-enrollment-statuses-for-organization" [
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
  --filters: list # An array of objects to specify a filter that returns a more specific list of account enrollment statuses. — item shape: {name?: "Status", values?: list<string>}
  --body-next-token: string # The token to advance to the next page of account enrollment statuses. (spec name: nextToken)
  --body-max-results: int # The maximum number of account enrollment statuses to return with a single request. You can specify up to 100 statuses to return with each request. To retrieve the remaining results, make another request with the returned nextToken value. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetEnrollmentStatusesForOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Lambda function recommendations. Compute Optimizer generates recommendations for functions that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record<nextToken: string, lambdaFunctionRecommendations: table<functionArn: string, functionVersion: string, accountId: string, currentMemorySize: int, numberOfInvocations: int, utilizationMetrics: list, lookbackPeriodInDays: float, lastRefreshTimestamp: string, finding: string, findingReasonCodes: list, memorySizeRecommendationOptions: list, currentPerformanceRisk: string>>
# operationId: GetLambdaFunctionRecommendations
export def "get-lambda-function-recommendations" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  --function-arns: list<string> # The Amazon Resource Name (ARN) of the functions for which to return recommendations. You can specify a qualified or unqualified ARN. If you specify an unqualified ARN without a function version suffix, Compute Optimizer will return recommendations for the latest ($LATEST) version of the function. If you specify a qualified ARN with a version suffix, Compute Optimizer will return recommendations for the specified function version. For more information about using function versions, see Using versions (https://docs.aws.amazon.com/lambda/latest/dg/configuration-versions.html#versioning-versions-using) in the Lambda Developer Guide.
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return function recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return function recommendations. Only one account ID can be specified per request.
  --filters: list # An array of objects to specify a filter that returns a more specific list of function recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --body-next-token: string # The token to advance to the next page of function recommendations. (spec name: nextToken)
  --body-max-results: int # The maximum number of function recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetLambdaFunctionRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: functionArns, var: function_arns}, {name: accountIds, var: account_ids}, {name: filters, var: filters}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, function_arns: $function_arns, account_ids: $account_ids, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns existing recommendation preferences, such as enhanced infrastructure metrics. Use the scope parameter to specify which preferences to return. You can specify to return preferences for an organization, a specific account ID, or a specific EC2 instance or Auto Scaling group Amazon Resource Name (ARN). For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record<nextToken: string, recommendationPreferencesDetails: table<scope: record, resourceType: string, enhancedInfrastructureMetrics: string, inferredWorkloadTypes: string, externalMetricsPreference: record>>
# operationId: GetRecommendationPreferences
export def "get-recommendation-preferences" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  resource_type: string@resource-type-completer # The target resource type of the recommendation preference for which to return preferences. The Ec2Instance option encompasses standalone instances and instances that are part of Auto Scaling groups. The AutoScalingGroup option encompasses only instances that are part of an Auto Scaling group. The valid values for this parameter are Ec2Instance and AutoScalingGroup.
  --scope: record # Describes the scope of a recommendation preference. Recommendation preferences can be created at the organization level (for management accounts of an organization only), account level, and resource level. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide. You cannot create recommendation preferences for Auto Scaling groups at the organization and account levels. You can create recommendation preferences for Auto Scaling groups only at the resource level by specifying a scope name of ResourceArn and a scope value of the Auto Scaling group Amazon Resource Name (ARN). This will configure the preference for all instances that are part of the specified Auto Scaling group. You also cannot create recommendation preferences at the resource level for instances that are part of an Auto Scaling group. You can create recommendation preferences at the resource level only for standalone instances. — shape: {name?: "Organization"|"AccountId"|"ResourceArn", value?: string}
  --body-next-token: string # The token to advance to the next page of recommendation preferences. (spec name: nextToken)
  --body-max-results: int # The maximum number of recommendation preferences to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetRecommendationPreferences"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceType, var: resource_type}, {name: scope, var: scope}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_type: $resource_type, scope: $scope, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the optimization findings for an account. It returns the number of: Amazon EC2 instances in an account that are Underprovisioned, Overprovisioned, or Optimized. Auto Scaling groups in an account that are NotOptimized, or Optimized. Amazon EBS volumes in an account that are NotOptimized, or Optimized. Lambda functions in an account that are NotOptimized, or Optimized. Amazon ECS services in an account that are Underprovisioned, Overprovisioned, or Optimized.
#
# POST /
# Returns: record<nextToken: string, recommendationSummaries: table<summaries: list, recommendationResourceType: string, accountId: string, savingsOpportunity: record, currentPerformanceRiskRatings: record>>
# operationId: GetRecommendationSummaries
export def "get-recommendation-summaries" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return recommendation summaries. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return recommendation summaries. Only one account ID can be specified per request.
  --body-next-token: string # The token to advance to the next page of recommendation summaries. (spec name: nextToken)
  --body-max-results: int # The maximum number of recommendation summaries to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.GetRecommendationSummaries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountIds, var: account_ids}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_ids: $account_ids, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new recommendation preference or updates an existing recommendation preference, such as enhanced infrastructure metrics. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record
# operationId: PutRecommendationPreferences
export def "put-recommendation-preferences" [
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
  resource_type: string@resource-type-completer # The target resource type of the recommendation preference to create. The Ec2Instance option encompasses standalone instances and instances that are part of Auto Scaling groups. The AutoScalingGroup option encompasses only instances that are part of an Auto Scaling group. The valid values for this parameter are Ec2Instance and AutoScalingGroup.
  --scope: record # Describes the scope of a recommendation preference. Recommendation preferences can be created at the organization level (for management accounts of an organization only), account level, and resource level. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide. You cannot create recommendation preferences for Auto Scaling groups at the organization and account levels. You can create recommendation preferences for Auto Scaling groups only at the resource level by specifying a scope name of ResourceArn and a scope value of the Auto Scaling group Amazon Resource Name (ARN). This will configure the preference for all instances that are part of the specified Auto Scaling group. You also cannot create recommendation preferences at the resource level for instances that are part of an Auto Scaling group. You can create recommendation preferences at the resource level only for standalone instances. — shape: {name?: "Organization"|"AccountId"|"ResourceArn", value?: string}
  --enhanced-infrastructure-metrics: string@enhanced-infrastructure-metrics-completer # The status of the enhanced infrastructure metrics recommendation preference to create or update. Specify the Active status to activate the preference, or specify Inactive to deactivate the preference. For more information, see Enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
  --inferred-workload-types: string@inferred-workload-types-completer # The status of the inferred workload types recommendation preference to create or update. The inferred workload type feature is active by default. To deactivate it, create a recommendation preference. Specify the Inactive status to deactivate the feature, or specify Active to activate it. For more information, see Inferred workload types (https://docs.aws.amazon.com/compute-optimizer/latest/ug/inferred-workload-types.html) in the Compute Optimizer User Guide.
  --external-metrics-preference: record # Describes the external metrics preferences for EC2 rightsizing recommendations. — shape: {source?: "Datadog"|"Dynatrace"|"NewRelic"|"Instana"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.PutRecommendationPreferences"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceType, var: resource_type}, {name: scope, var: scope}, {name: enhancedInfrastructureMetrics, var: enhanced_infrastructure_metrics}, {name: inferredWorkloadTypes, var: inferred_workload_types}, {name: externalMetricsPreference, var: external_metrics_preference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_type: $resource_type, scope: $scope, enhanced_infrastructure_metrics: $enhanced_infrastructure_metrics, inferred_workload_types: $inferred_workload_types, external_metrics_preference: $external_metrics_preference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the enrollment (opt in and opt out) status of an account to the Compute Optimizer service. If the account is a management account of an organization, this action can also be used to enroll member accounts of the organization. You must have the appropriate permissions to opt in to Compute Optimizer, to view its recommendations, and to opt out. For more information, see Controlling access with Amazon Web Services Identity and Access Management (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html) in the Compute Optimizer User Guide. When you opt in, Compute Optimizer automatically creates a service-linked role in your account to access its data. For more information, see Using Service-Linked Roles for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/using-service-linked-roles.html) in the Compute Optimizer User Guide.
#
# POST /
# Returns: record<status: string, statusReason: string>
# operationId: UpdateEnrollmentStatus
export def "update-enrollment-status" [
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
  status: string@status-completer # The new enrollment status of the account. The following status options are available: Active - Opts in your account to the Compute Optimizer service. Compute Optimizer begins analyzing the configuration and utilization metrics of your Amazon Web Services resources after you opt in. For more information, see Metrics analyzed by Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/metrics.html) in the Compute Optimizer User Guide. Inactive - Opts out your account from the Compute Optimizer service. Your account's recommendations and related metrics data will be deleted from Compute Optimizer after you opt out. The Pending and Failed options cannot be used to update the enrollment status of an account. They are returned in the response of a request to update the enrollment status of an account.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to enroll member accounts of the organization if the account is the management account of an organization.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "ComputeOptimizerService.UpdateEnrollmentStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}, {name: includeMemberAccounts, var: include_member_accounts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, status: $status, include_member_accounts: $include_member_accounts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
