# Auto-generated client for AWS Lambda v2015-03-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/lambda/2015-03-31/openapi.json
# Auth: --token flag or $env.AWS_LAMBDA_TOKEN

const CLIENT = {
  base_url: "http://lambda.us-east-1.amazonaws.com"
  token_env_var: "AWS_LAMBDA_TOKEN"
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

def base-url-completer [] { ["http://lambda.us-east-1.amazonaws.com" "http://lambda.us-east-2.amazonaws.com" "http://lambda.us-west-1.amazonaws.com" "http://lambda.us-west-2.amazonaws.com" "http://lambda.us-gov-west-1.amazonaws.com" "http://lambda.us-gov-east-1.amazonaws.com" "http://lambda.ca-central-1.amazonaws.com" "http://lambda.eu-north-1.amazonaws.com" "http://lambda.eu-west-1.amazonaws.com" "http://lambda.eu-west-2.amazonaws.com" "http://lambda.eu-west-3.amazonaws.com" "http://lambda.eu-central-1.amazonaws.com" "http://lambda.eu-south-1.amazonaws.com" "http://lambda.af-south-1.amazonaws.com" "http://lambda.ap-northeast-1.amazonaws.com" "http://lambda.ap-northeast-2.amazonaws.com" "http://lambda.ap-northeast-3.amazonaws.com" "http://lambda.ap-southeast-1.amazonaws.com" "http://lambda.ap-southeast-2.amazonaws.com" "http://lambda.ap-east-1.amazonaws.com" "http://lambda.ap-south-1.amazonaws.com" "http://lambda.sa-east-1.amazonaws.com" "http://lambda.me-south-1.amazonaws.com" "https://lambda.us-east-1.amazonaws.com" "https://lambda.us-east-2.amazonaws.com" "https://lambda.us-west-1.amazonaws.com" "https://lambda.us-west-2.amazonaws.com" "https://lambda.us-gov-west-1.amazonaws.com" "https://lambda.us-gov-east-1.amazonaws.com" "https://lambda.ca-central-1.amazonaws.com" "https://lambda.eu-north-1.amazonaws.com" "https://lambda.eu-west-1.amazonaws.com" "https://lambda.eu-west-2.amazonaws.com" "https://lambda.eu-west-3.amazonaws.com" "https://lambda.eu-central-1.amazonaws.com" "https://lambda.eu-south-1.amazonaws.com" "https://lambda.af-south-1.amazonaws.com" "https://lambda.ap-northeast-1.amazonaws.com" "https://lambda.ap-northeast-2.amazonaws.com" "https://lambda.ap-northeast-3.amazonaws.com" "https://lambda.ap-southeast-1.amazonaws.com" "https://lambda.ap-southeast-2.amazonaws.com" "https://lambda.ap-east-1.amazonaws.com" "https://lambda.ap-south-1.amazonaws.com" "https://lambda.sa-east-1.amazonaws.com" "https://lambda.me-south-1.amazonaws.com" "http://lambda.cn-north-1.amazonaws.com.cn" "http://lambda.cn-northwest-1.amazonaws.com.cn" "https://lambda.cn-north-1.amazonaws.com.cn" "https://lambda.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def function-url-auth-type-completer [] { ["AWS_IAM" "NONE"] }
def starting-position-completer [] { ["AT_TIMESTAMP" "LATEST" "TRIM_HORIZON"] }
def runtime-completer [] { ["dotnet6" "dotnetcore1.0" "dotnetcore2.0" "dotnetcore2.1" "dotnetcore3.1" "go1.x" "java11" "java8" "java8.al2" "nodejs" "nodejs10.x" "nodejs12.x" "nodejs14.x" "nodejs16.x" "nodejs18.x" "nodejs4.3" "nodejs4.3-edge" "nodejs6.10" "nodejs8.10" "provided" "provided.al2" "python2.7" "python3.10" "python3.6" "python3.7" "python3.8" "python3.9" "ruby2.5" "ruby2.7"] }
def package-type-completer [] { ["Image" "Zip"] }
def auth-type-completer [] { ["AWS_IAM" "NONE"] }
def invoke-mode-completer [] { ["BUFFERED" "RESPONSE_STREAM"] }
def find-completer [] { ["LayerVersion"] }
def update-runtime-on-completer [] { ["Auto" "FunctionUpdate" "Manual"] }
def x-amz-invocation-type-completer [] { ["DryRun" "Event" "RequestResponse"] }
def x-amz-log-type-completer [] { ["None" "Tail"] }
def x-amz-invocation-type-completer-1 [] { ["DryRun" "RequestResponse"] }
def function-version-completer [] { ["ALL"] }
def compatible-runtime-completer [] { ["dotnet6" "dotnetcore1.0" "dotnetcore2.0" "dotnetcore2.1" "dotnetcore3.1" "go1.x" "java11" "java8" "java8.al2" "nodejs" "nodejs10.x" "nodejs12.x" "nodejs14.x" "nodejs16.x" "nodejs18.x" "nodejs4.3" "nodejs4.3-edge" "nodejs6.10" "nodejs8.10" "provided" "provided.al2" "python2.7" "python3.10" "python3.6" "python3.7" "python3.8" "python3.9" "ruby2.5" "ruby2.7"] }
def compatible-architecture-completer [] { ["arm64" "x86_64"] }
def list-completer [] { ["ALL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-layer-version-permission: "record<Statement: string, RevisionId: string>"
    get-layer-version-policy: "record<Policy: string, RevisionId: string>"
    add-permission: "record<Statement: string>"
    get-policy: "record<Policy: string, RevisionId: string>"
    create-alias: "record<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: string>"
    list-aliases: "record<NextMarker: string, Aliases: table<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record, RevisionId: string>>"
    create-code-signing-config: "record<CodeSigningConfig: record<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record<SigningProfileVersionArns: list>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: string>, LastModified: string>>"
    list-code-signing-configs: "record<NextMarker: string, CodeSigningConfigs: table<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record, CodeSigningPolicies: record, LastModified: string>>"
    create-event-source-mapping: "record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>"
    list-event-source-mappings: "record<NextMarker: string, EventSourceMappings: table<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record, Topics: list, Queues: list, SourceAccessConfigurations: list, SelfManagedEventSource: record, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list, AmazonManagedKafkaEventSourceConfig: record, SelfManagedKafkaEventSourceConfig: record, ScalingConfig: record, DocumentDBEventSourceConfig: record>>"
    create-function: "record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>"
    create-function-url-config: "record<FunctionUrl: string, FunctionArn: string, AuthType: string, Cors: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreationTime: string, InvokeMode: string>"
    get-function-url-config: "record<FunctionUrl: string, FunctionArn: string, AuthType: string, Cors: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreationTime: string, LastModifiedTime: string, InvokeMode: string>"
    update-function-url-config: "record<FunctionUrl: string, FunctionArn: string, AuthType: string, Cors: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreationTime: string, LastModifiedTime: string, InvokeMode: string>"
    get-alias: "record<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: string>"
    update-alias: "record<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: string>"
    delete-code-signing-config: "record"
    get-code-signing-config: "record<CodeSigningConfig: record<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record<SigningProfileVersionArns: list>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: string>, LastModified: string>>"
    update-code-signing-config: "record<CodeSigningConfig: record<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record<SigningProfileVersionArns: list>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: string>, LastModified: string>>"
    delete-event-source-mapping: "record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>"
    get-event-source-mapping: "record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>"
    update-event-source-mapping: "record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>"
    get-function: "record<Configuration: record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: list<record>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: list<record>, PackageType: string, ImageConfigResponse: record<ImageConfig: record, Error: record>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record>>, Code: record<RepositoryType: string, Location: string, ImageUri: string, ResolvedImageUri: string>, Tags: record, Concurrency: record<ReservedConcurrentExecutions: int>>"
    get-function-code-signing-config: "record<CodeSigningConfigArn: string, FunctionName: string>"
    put-function-code-signing-config: "record<CodeSigningConfigArn: string, FunctionName: string>"
    put-function-concurrency: "record<ReservedConcurrentExecutions: int>"
    get-function-event-invoke-config: "record<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>>"
    put-function-event-invoke-config: "record<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>>"
    update-function-event-invoke-config: "record<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>>"
    get-layer-version: "record<Content: record<Location: string, CodeSha256: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, LayerArn: string, LayerVersionArn: string, Description: string, CreatedDate: string, Version: int, CompatibleRuntimes: list<string>, LicenseInfo: string, CompatibleArchitectures: list<string>>"
    get-provisioned-concurrency-config: "record<RequestedProvisionedConcurrentExecutions: int, AvailableProvisionedConcurrentExecutions: int, AllocatedProvisionedConcurrentExecutions: int, Status: string, StatusReason: string, LastModified: string>"
    put-provisioned-concurrency-config: "record<RequestedProvisionedConcurrentExecutions: int, AvailableProvisionedConcurrentExecutions: int, AllocatedProvisionedConcurrentExecutions: int, Status: string, StatusReason: string, LastModified: string>"
    get-account-settings: "record<AccountLimit: record<TotalCodeSize: int, CodeSizeUnzipped: int, CodeSizeZipped: int, ConcurrentExecutions: int, UnreservedConcurrentExecutions: int>, AccountUsage: record<TotalCodeSize: int, FunctionCount: int>>"
    get-function-concurrency: "record<ReservedConcurrentExecutions: int>"
    get-function-configuration: "record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>"
    update-function-configuration: "record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>"
    get-layer-version-by-arn: "record<Content: record<Location: string, CodeSha256: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, LayerArn: string, LayerVersionArn: string, Description: string, CreatedDate: string, Version: int, CompatibleRuntimes: list<string>, LicenseInfo: string, CompatibleArchitectures: list<string>>"
    get-runtime-management-config: "record<UpdateRuntimeOn: string, RuntimeVersionArn: string, FunctionArn: string>"
    put-runtime-management-config: "record<UpdateRuntimeOn: string, FunctionArn: string, RuntimeVersionArn: string>"
    invoke: "record<StatusCode: int, Payload: string>"
    invoke-async: "record<Status: int>"
    invoke-with-response-stream: "record<StatusCode: int, EventStream: record<PayloadChunk: record<Payload: string>, InvokeComplete: record<ErrorCode: string, ErrorDetails: string, LogResult: string>>>"
    list-function-event-invoke-configs: "record<FunctionEventInvokeConfigs: table<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record>, NextMarker: string>"
    list-function-url-configs: "record<FunctionUrlConfigs: table<FunctionUrl: string, FunctionArn: string, CreationTime: string, LastModifiedTime: string, Cors: record, AuthType: string, InvokeMode: string>, NextMarker: string>"
    list-functions: "record<NextMarker: string, Functions: table<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record, DeadLetterConfig: record, Environment: record, KMSKeyArn: string, TracingConfig: record, MasterArn: string, RevisionId: string, Layers: list, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: list, PackageType: string, ImageConfigResponse: record, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list, EphemeralStorage: record, SnapStart: record, RuntimeVersionConfig: record>>"
    list-functions-by-code-signing-config: "record<NextMarker: string, FunctionArns: list<string>>"
    list-layer-versions: "record<NextMarker: string, LayerVersions: table<LayerVersionArn: string, Version: int, Description: string, CreatedDate: string, CompatibleRuntimes: list, LicenseInfo: string, CompatibleArchitectures: list>>"
    publish-layer-version: "record<Content: record<Location: string, CodeSha256: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, LayerArn: string, LayerVersionArn: string, Description: string, CreatedDate: string, Version: int, CompatibleRuntimes: list<string>, LicenseInfo: string, CompatibleArchitectures: list<string>>"
    list-layers: "record<NextMarker: string, Layers: table<LayerName: string, LayerArn: string, LatestMatchingVersion: record>>"
    list-provisioned-concurrency-configs: "record<ProvisionedConcurrencyConfigs: table<FunctionArn: string, RequestedProvisionedConcurrentExecutions: int, AvailableProvisionedConcurrentExecutions: int, AllocatedProvisionedConcurrentExecutions: int, Status: string, StatusReason: string, LastModified: string>, NextMarker: string>"
    list-tags: "record<Tags: record>"
    list-versions-by-function: "record<NextMarker: string, Versions: table<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record, DeadLetterConfig: record, Environment: record, KMSKeyArn: string, TracingConfig: record, MasterArn: string, RevisionId: string, Layers: list, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: list, PackageType: string, ImageConfigResponse: record, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list, EphemeralStorage: record, SnapStart: record, RuntimeVersionConfig: record>>"
    publish-version: "record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>"
    update-function-code: "record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-layer-version-permission" "get-layer-version-policy" "add-permission" "get-policy" "create-alias" "list-aliases" "create-code-signing-config" "list-code-signing-configs" "create-event-source-mapping" "list-event-source-mappings" "create-function" "create-function-url-config" "delete-function-url-config" "get-function-url-config" "update-function-url-config" "delete-alias" "get-alias" "update-alias" "delete-code-signing-config" "get-code-signing-config" "update-code-signing-config" "delete-event-source-mapping" "get-event-source-mapping" "update-event-source-mapping" "delete-function" "get-function" "delete-function-code-signing-config" "get-function-code-signing-config" "put-function-code-signing-config" "delete-function-concurrency" "put-function-concurrency" "delete-function-event-invoke-config" "get-function-event-invoke-config" "put-function-event-invoke-config" "update-function-event-invoke-config" "delete-layer-version" "get-layer-version" "delete-provisioned-concurrency-config" "get-provisioned-concurrency-config" "put-provisioned-concurrency-config" "get-account-settings" "get-function-concurrency" "get-function-configuration" "update-function-configuration" "get-layer-version-by-arn" "get-runtime-management-config" "put-runtime-management-config" "invoke" "invoke-async" "invoke-with-response-stream" "list-function-event-invoke-configs" "list-function-url-configs" "list-functions" "list-functions-by-code-signing-config" "list-layer-versions" "publish-layer-version" "list-layers" "list-provisioned-concurrency-configs" "list-tags" "tag-resource" "list-versions-by-function" "publish-version" "remove-layer-version-permission" "remove-permission" "untag-resource" "update-function-code" "commands"] | sort) } | get name | first)
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

# Adds permissions to the resource-based policy of a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all accounts in an organization, or all Amazon Web Services accounts. To revoke permission, call RemoveLayerVersionPermission with the statement ID that you specified when you added it.
#
# POST /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy
# Returns: record<Statement: string, RevisionId: string>
# operationId: AddLayerVersionPermission
export def "add-layer-version-permission" [
  layer_name: string
  version_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision-id: string # Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  statement_id: string # An identifier that distinguishes the policy from others on the same layer version.
  action: string # The API action that grants access to the layer. For example, lambda:GetLayerVersion.
  principal: string # An account ID, or * to grant layer usage permission to all accounts in an organization, or all Amazon Web Services accounts (if organizationId is not specified). For the last case, make sure that you really do want all Amazon Web Services accounts to have usage permission to this layer.
  --organization-id: string # With the principal set to *, grant permission to all accounts in the specified organization.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy"
    path_params: [{name: LayerName, var: layer_name}, {name: VersionNumber, var: version_number}]
    query: [{name: RevisionId, var: revision_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StatementId, var: statement_id}, {name: Action, var: action}, {name: Principal, var: principal}, {name: OrganizationId, var: organization_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    layer_name: $layer_name, version_number: $version_number, revision_id: $revision_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, statement_id: $statement_id, action: $action, principal: $principal, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the permission policy for a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). For more information, see AddLayerVersionPermission.
#
# GET /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy
# Returns: record<Policy: string, RevisionId: string>
# operationId: GetLayerVersionPolicy
export def "get-layer-version-policy" [
  layer_name: string
  version_number: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy"
    path_params: [{name: LayerName, var: layer_name}, {name: VersionNumber, var: version_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    layer_name: $layer_name, version_number: $version_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Grants an Amazon Web Service, Amazon Web Services account, or Amazon Web Services organization permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function. Note: Lambda does not support adding policies to version $LATEST. To grant permission to another account, specify the account ID as the Principal. To grant permission to an organization defined in Organizations, specify the organization ID as the PrincipalOrgID. For Amazon Web Services, the principal is a domain-style identifier that the service defines, such as s3.amazonaws.com or sns.amazonaws.com. For Amazon Web Services, you can also specify the ARN of the associated resource as the SourceArn. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function. This operation adds a statement to a resource-based permissions policy for the function. For more information about function policies, see Using resource-based policies for Lambda (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html).
#
# POST /2015-03-31/functions/{FunctionName}/policy
# Returns: record<Statement: string>
# operationId: AddPermission
export def "add-permission" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to add permissions to a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  statement_id: string # A statement identifier that differentiates the statement from others in the same policy.
  action: string # The action that the principal can use on the function. For example, lambda:InvokeFunction or lambda:GetFunction.
  principal: string # The Amazon Web Service or Amazon Web Services account that invokes the function. If you specify a service, use SourceArn or SourceAccount to limit who can invoke the function through that service.
  --source-arn: string # For Amazon Web Services, the ARN of the Amazon Web Services resource that invokes the function. For example, an Amazon S3 bucket or Amazon SNS topic. Note that Lambda configures the comparison using the StringLike operator.
  --source-account: string # For Amazon Web Service, the ID of the Amazon Web Services account that owns the resource. Use this together with SourceArn to ensure that the specified account owns the resource. It is possible for an Amazon S3 bucket to be deleted by its owner and recreated by another account.
  --event-source-token: string # For Alexa Smart Home functions, a token that the invoker must supply.
  --revision-id: string # Update the policy only if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --principal-org-id: string # The identifier for your organization in Organizations. Use this to grant permissions to all the Amazon Web Services accounts under this organization.
  --function-url-auth-type: string@function-url-auth-type-completer # The type of authentication that your function URL uses. Set to AWS_IAM if you want to restrict access to authenticated users only. Set to NONE if you want to bypass IAM authentication to create a public endpoint. For more information, see Security and auth model for Lambda function URLs (https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-03-31/functions/{FunctionName}/policy"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StatementId, var: statement_id}, {name: Action, var: action}, {name: Principal, var: principal}, {name: SourceArn, var: source_arn}, {name: SourceAccount, var: source_account}, {name: EventSourceToken, var: event_source_token}, {name: RevisionId, var: revision_id}, {name: PrincipalOrgID, var: principal_org_id}, {name: FunctionUrlAuthType, var: function_url_auth_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, statement_id: $statement_id, action: $action, principal: $principal, source_arn: $source_arn, source_account: $source_account, event_source_token: $event_source_token, revision_id: $revision_id, principal_org_id: $principal_org_id, function_url_auth_type: $function_url_auth_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the resource-based IAM policy (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html) for a function, version, or alias.
#
# GET /2015-03-31/functions/{FunctionName}/policy
# Returns: record<Policy: string, RevisionId: string>
# operationId: GetPolicy
export def "get-policy" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to get the policy for that resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/functions/{FunctionName}/policy"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version. You can also map an alias to split invocation requests between two versions. Use the RoutingConfig parameter to specify a second version and the percentage of invocation requests that it receives.
#
# POST /2015-03-31/functions/{FunctionName}/aliases
# Returns: record<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: string>
# operationId: CreateAlias
export def "create-alias" [
  function_name: string
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
  name: string # The name of the alias.
  function_version: string # The function version that the alias invokes.
  --description: string # A description of the alias.
  --routing-config: record # The traffic-shifting (https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html) configuration of a Lambda function alias. — shape: {AdditionalVersionWeights?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-03-31/functions/{FunctionName}/aliases"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: FunctionVersion, var: function_version}, {name: Description, var: description}, {name: RoutingConfig, var: routing_config}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, function_version: $function_version, description: $description, routing_config: $routing_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of aliases (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) for a Lambda function.
#
# GET /2015-03-31/functions/{FunctionName}/aliases
# Returns: record<NextMarker: string, Aliases: table<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record, RevisionId: string>>
# operationId: ListAliases
export def "list-aliases" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --function-version: string # Specify a function version to only list aliases that invoke that version.
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Limit the number of aliases returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/functions/{FunctionName}/aliases"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: FunctionVersion, var: function_version}, {name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, function_version: $function_version, marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a code signing configuration. A code signing configuration (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html) defines a list of allowed signing profiles and defines the code-signing validation policy (action to be taken if deployment validation checks fail).
#
# POST /2020-04-22/code-signing-configs/
# Returns: record<CodeSigningConfig: record<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record<SigningProfileVersionArns: list>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: string>, LastModified: string>>
# operationId: CreateCodeSigningConfig
export def "create-code-signing-config" [
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
  --description: string # Descriptive name for this code signing configuration.
  allowed_publishers: record # List of signing profiles that can sign a code package. — shape: {SigningProfileVersionArns?: list<string>}
  --code-signing-policies: record # Code signing configuration policies (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html#config-codesigning-policies) specify the validation failure action for signature mismatch or expiry. — shape: {UntrustedArtifactOnDeployment?: "Warn"|"Enforce"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2020-04-22/code-signing-configs/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: AllowedPublishers, var: allowed_publishers}, {name: CodeSigningPolicies, var: code_signing_policies}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, allowed_publishers: $allowed_publishers, code_signing_policies: $code_signing_policies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of code signing configurations (https://docs.aws.amazon.com/lambda/latest/dg/configuring-codesigning.html). A request returns up to 10,000 configurations per call. You can use the MaxItems parameter to return fewer configurations per call.
#
# GET /2020-04-22/code-signing-configs/
# Returns: record<NextMarker: string, CodeSigningConfigs: table<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record, CodeSigningPolicies: record, LastModified: string>>
# operationId: ListCodeSigningConfigs
export def "list-code-signing-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Maximum number of items to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-04-22/code-signing-configs/"
    query: [{name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a mapping between an event source and an Lambda function. Lambda reads items from the event source and invokes the function. For details about how to configure different event sources, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-dynamodb-eventsourcemapping) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-eventsourcemapping) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-eventsource) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-eventsourcemapping) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/kafka-smaa.html) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html) The following error handling options are available only for stream sources (DynamoDB and Kinesis): BisectBatchOnFunctionError – If the function returns an error, split the batch in two and retry. DestinationConfig – Send discarded records to an Amazon SQS queue or Amazon SNS topic. MaximumRecordAgeInSeconds – Discard records older than the specified age. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires MaximumRetryAttempts – Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires. ParallelizationFactor – Process multiple batches from each shard concurrently. For information about which configuration parameters apply to each event source, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-ddb-params) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-params) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#services-sqs-params) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-params) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html#services-msk-parms) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/with-kafka.html#services-kafka-parms) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html#docdb-configuration)
#
# POST /2015-03-31/event-source-mappings/
# Returns: record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>
# operationId: CreateEventSourceMapping
export def "create-event-source-mapping" [
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
  --event-source-arn: string # The Amazon Resource Name (ARN) of the event source. Amazon Kinesis – The ARN of the data stream or a stream consumer. Amazon DynamoDB Streams – The ARN of the stream. Amazon Simple Queue Service – The ARN of the queue. Amazon Managed Streaming for Apache Kafka – The ARN of the cluster. Amazon MQ – The ARN of the broker. Amazon DocumentDB – The ARN of the DocumentDB change stream.
  function_name: string # The name of the Lambda function. Name formats Function name – MyFunction. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction. Version or Alias ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD. Partial ARN – 123456789012:function:MyFunction. The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.
  --enabled: oneof<nothing, bool> # When true, the event source mapping is active. When false, Lambda pauses polling and invocation. Default: True
  --batch-size: int # The maximum number of records in each batch that Lambda pulls from your stream or queue and sends to your function. Lambda passes all of the records in the batch to the function in a single call, up to the payload limit for synchronous invocation (6 MB). Amazon Kinesis – Default 100. Max 10,000. Amazon DynamoDB Streams – Default 100. Max 10,000. Amazon Simple Queue Service – Default 10. For standard queues the max is 10,000. For FIFO queues the max is 10. Amazon Managed Streaming for Apache Kafka – Default 100. Max 10,000. Self-managed Apache Kafka – Default 100. Max 10,000. Amazon MQ (ActiveMQ and RabbitMQ) – Default 100. Max 10,000. DocumentDB – Default 100. Max 10,000.
  --filter-criteria: record # An object that contains the filters for an event source. — shape: {Filters?: list}
  --maximum-batching-window-in-seconds: int # The maximum amount of time, in seconds, that Lambda spends gathering records before invoking the function. You can configure MaximumBatchingWindowInSeconds to any value from 0 seconds to 300 seconds in increments of seconds. For streams and Amazon SQS event sources, the default batching window is 0 seconds. For Amazon MSK, Self-managed Apache Kafka, Amazon MQ, and DocumentDB event sources, the default batching window is 500 ms. Note that because you can only change MaximumBatchingWindowInSeconds in increments of seconds, you cannot revert back to the 500 ms default batching window after you have changed it. To restore the default batching window, you must create a new event source mapping. Related setting: For streams and Amazon SQS event sources, when you set BatchSize to a value greater than 10, you must set MaximumBatchingWindowInSeconds to at least 1.
  --parallelization-factor: int # (Kinesis and DynamoDB Streams only) The number of batches to process from each shard concurrently.
  --starting-position: string@starting-position-completer # The position in a stream from which to start reading. Required for Amazon Kinesis, Amazon DynamoDB, and Amazon MSK Streams sources. AT_TIMESTAMP is supported only for Amazon Kinesis streams and Amazon DocumentDB.
  --starting-position-timestamp: string # With StartingPosition set to AT_TIMESTAMP, the time from which to start reading. (format: date-time)
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: record, OnFailure?: record}
  --maximum-record-age-in-seconds: int # (Kinesis and DynamoDB Streams only) Discard records older than the specified age. The default value is infinite (-1).
  --bisect-batch-on-function-error: oneof<nothing, bool> # (Kinesis and DynamoDB Streams only) If the function returns an error, split the batch in two and retry.
  --maximum-retry-attempts: int # (Kinesis and DynamoDB Streams only) Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.
  --tumbling-window-in-seconds: int # (Kinesis and DynamoDB Streams only) The duration in seconds of a processing window for DynamoDB and Kinesis Streams event sources. A value of 0 seconds indicates no tumbling window.
  --topics: list<string> # The name of the Kafka topic.
  --queues: list<string> # (MQ) The name of the Amazon MQ broker destination queue to consume.
  --source-access-configurations: list # An array of authentication protocols or VPC components required to secure your event source. — item shape: {Type?: "BASIC_AUTH"|"VPC_SUBNET"|"VPC_SECURITY_GROUP"|"SASL_SCRAM_512_AUTH"|"SASL_SCRAM_256_AUTH"|"VIRTUAL_HOST"|"CLIENT_CERTIFICATE_TLS_AUTH"|"SERVER_ROOT_CA_CERTIFICATE", URI?: string}
  --self-managed-event-source: record # The self-managed Apache Kafka cluster for your event source. — shape: {Endpoints?: record}
  --function-response-types: list<string> # (Kinesis, DynamoDB Streams, and Amazon SQS) A list of current response type enums applied to the event source mapping.
  --amazon-managed-kafka-event-source-config: record # Specific configuration settings for an Amazon Managed Streaming for Apache Kafka (Amazon MSK) event source. — shape: {ConsumerGroupId?: string}
  --self-managed-kafka-event-source-config: record # Specific configuration settings for a self-managed Apache Kafka event source. — shape: {ConsumerGroupId?: string}
  --scaling-config: record # (Amazon SQS only) The scaling configuration for the event source. To remove the configuration, pass an empty value. — shape: {MaximumConcurrency?: int}
  --document-db-event-source-config: record # Specific configuration settings for a DocumentDB event source. — shape: {DatabaseName?: string, CollectionName?: string, FullDocument?: "UpdateLookup"|"Default"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-03-31/event-source-mappings/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventSourceArn, var: event_source_arn}, {name: FunctionName, var: function_name}, {name: Enabled, var: enabled}, {name: BatchSize, var: batch_size}, {name: FilterCriteria, var: filter_criteria}, {name: MaximumBatchingWindowInSeconds, var: maximum_batching_window_in_seconds}, {name: ParallelizationFactor, var: parallelization_factor}, {name: StartingPosition, var: starting_position}, {name: StartingPositionTimestamp, var: starting_position_timestamp}, {name: DestinationConfig, var: destination_config}, {name: MaximumRecordAgeInSeconds, var: maximum_record_age_in_seconds}, {name: BisectBatchOnFunctionError, var: bisect_batch_on_function_error}, {name: MaximumRetryAttempts, var: maximum_retry_attempts}, {name: TumblingWindowInSeconds, var: tumbling_window_in_seconds}, {name: Topics, var: topics}, {name: Queues, var: queues}, {name: SourceAccessConfigurations, var: source_access_configurations}, {name: SelfManagedEventSource, var: self_managed_event_source}, {name: FunctionResponseTypes, var: function_response_types}, {name: AmazonManagedKafkaEventSourceConfig, var: amazon_managed_kafka_event_source_config}, {name: SelfManagedKafkaEventSourceConfig, var: self_managed_kafka_event_source_config}, {name: ScalingConfig, var: scaling_config}, {name: DocumentDBEventSourceConfig, var: document_db_event_source_config}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, event_source_arn: $event_source_arn, function_name: $function_name, enabled: $enabled, batch_size: $batch_size, filter_criteria: $filter_criteria, maximum_batching_window_in_seconds: $maximum_batching_window_in_seconds, parallelization_factor: $parallelization_factor, starting_position: $starting_position, starting_position_timestamp: $starting_position_timestamp, destination_config: $destination_config, maximum_record_age_in_seconds: $maximum_record_age_in_seconds, bisect_batch_on_function_error: $bisect_batch_on_function_error, maximum_retry_attempts: $maximum_retry_attempts, tumbling_window_in_seconds: $tumbling_window_in_seconds, topics: $topics, queues: $queues, source_access_configurations: $source_access_configurations, self_managed_event_source: $self_managed_event_source, function_response_types: $function_response_types, amazon_managed_kafka_event_source_config: $amazon_managed_kafka_event_source_config, self_managed_kafka_event_source_config: $self_managed_kafka_event_source_config, scaling_config: $scaling_config, document_db_event_source_config: $document_db_event_source_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists event source mappings. Specify an EventSourceArn to show only event source mappings for a single event source.
#
# GET /2015-03-31/event-source-mappings/
# Returns: record<NextMarker: string, EventSourceMappings: table<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record, Topics: list, Queues: list, SourceAccessConfigurations: list, SelfManagedEventSource: record, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list, AmazonManagedKafkaEventSourceConfig: record, SelfManagedKafkaEventSourceConfig: record, ScalingConfig: record, DocumentDBEventSourceConfig: record>>
# operationId: ListEventSourceMappings
export def "list-event-source-mappings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-source-arn: string # The Amazon Resource Name (ARN) of the event source. Amazon Kinesis – The ARN of the data stream or a stream consumer. Amazon DynamoDB Streams – The ARN of the stream. Amazon Simple Queue Service – The ARN of the queue. Amazon Managed Streaming for Apache Kafka – The ARN of the cluster. Amazon MQ – The ARN of the broker. Amazon DocumentDB – The ARN of the DocumentDB change stream.
  --function-name: string # The name of the Lambda function. Name formats Function name – MyFunction. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction. Version or Alias ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD. Partial ARN – 123456789012:function:MyFunction. The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.
  --marker: string # A pagination token returned by a previous call.
  --max-items: int # The maximum number of event source mappings to return. Note that ListEventSourceMappings returns a maximum of 100 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/event-source-mappings/"
    query: [{name: EventSourceArn, var: event_source_arn}, {name: FunctionName, var: function_name}, {name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_source_arn: $event_source_arn, function_name: $function_name, marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Lambda function. To create a function, you need a deployment package (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html) and an execution role (https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role). The deployment package is a .zip file archive or container image that contains your function code. The execution role grants the function permission to use Amazon Web Services, such as Amazon CloudWatch Logs for log streaming and X-Ray for request tracing. If the deployment package is a container image (https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html), then you set the package type to Image. For a container image, the code property must include the URI of a container image in the Amazon ECR registry. You do not need to specify the handler and runtime properties. If the deployment package is a .zip file archive (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html#gettingstarted-package-zip), then you set the package type to Zip. For a .zip file archive, the code property specifies the location of the .zip file. You must also specify the handler and runtime properties. The code in the deployment package must be compatible with the target instruction set architecture of the function (x86-64 or arm64). If you do not specify the architecture, then the default value is x86-64. When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The State, StateReason, and StateReasonCode fields in the response from GetFunctionConfiguration indicate when the function is ready to invoke. For more information, see Lambda function states (https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html). A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the Publish parameter to create version 1 of your function from its initial configuration. The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with UpdateFunctionConfiguration. Function-level settings apply to both the unpublished and published versions of the function, and include tags (TagResource) and per-function concurrency limits (PutFunctionConcurrency). You can use code signing if your deployment package is a .zip file archive. To enable code signing for this function, specify the ARN of a code-signing configuration. When a user attempts to deploy a code package with UpdateFunctionCode, Lambda checks that the code package has a valid signature from a trusted publisher. The code-signing configuration includes set of signing profiles, which define the trusted publishers for this function. If another Amazon Web Services account or an Amazon Web Service invokes your function, use AddPermission to grant permission by creating a resource-based Identity and Access Management (IAM) policy. You can grant permissions at the function level, on a version, or on an alias. To invoke your function directly, use Invoke. To invoke your function in response to events in other Amazon Web Services, create an event source mapping (CreateEventSourceMapping), or configure a function trigger in the other service. For more information, see Invoking Lambda functions (https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html).
#
# POST /2015-03-31/functions
# Returns: record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>
# operationId: CreateFunction
export def "create-function" [
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
  function_name: string # The name of the Lambda function. Name formats Function name – my-function. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:my-function. Partial ARN – 123456789012:function:my-function. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.
  --runtime: string@runtime-completer # The identifier of the function's runtime (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html). Runtime is required if the deployment package is a .zip file archive. The following list includes deprecated runtimes. For more information, see Runtime deprecation policy (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html#runtime-support-policy).
  role: string # The Amazon Resource Name (ARN) of the function's execution role.
  --handler: string # The name of the method within your code that Lambda calls to run your function. Handler is required if the deployment package is a .zip file archive. The format includes the file name. It can also include namespaces and other qualifiers, depending on the runtime. For more information, see Lambda programming model (https://docs.aws.amazon.com/lambda/latest/dg/foundation-progmodel.html).
  code: record # The code for the Lambda function. You can either specify an object in Amazon S3, upload a .zip file archive deployment package directly, or specify the URI of a container image. — shape: {ZipFile?: string, S3Bucket?: string, S3Key?: string, S3ObjectVersion?: string, ImageUri?: string}
  --description: string # A description of the function.
  --timeout: int # The amount of time (in seconds) that Lambda allows a function to run before stopping it. The default is 3 seconds. The maximum allowed value is 900 seconds. For more information, see Lambda execution environment (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html).
  --memory-size: int # The amount of memory available to the function (https://docs.aws.amazon.com/lambda/latest/dg/configuration-function-common.html#configuration-memory-console) at runtime. Increasing the function memory also increases its CPU allocation. The default value is 128 MB. The value can be any multiple of 1 MB.
  --publish: oneof<nothing, bool> # Set to true to publish the first version of the function during creation.
  --vpc-config: record # The VPC security groups and subnets that are attached to a Lambda function. For more information, see Configuring a Lambda function to access resources in a VPC (https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --package-type: string@package-type-completer # The type of deployment package. Set to Image for container image and set to Zip for .zip file archive.
  --dead-letter-config: record # The dead-letter queue (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq) for failed asynchronous invocations. — shape: {TargetArn?: string}
  --environment: record # A function's environment variable settings. You can use environment variables to adjust your function's behavior without updating code. An environment variable is a pair of strings that are stored in a function's version-specific configuration. — shape: {Variables?: record}
  --kms-key-arn: string # The ARN of the Key Management Service (KMS) customer managed key that's used to encrypt your function's environment variables (https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-encryption). When Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart-security.html) is activated, this key is also used to encrypt your function's snapshot. If you don't provide a customer managed key, Lambda uses a default service key.
  --tracing-config: record # The function's X-Ray (https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html) tracing configuration. To sample and record incoming requests, set Mode to Active. — shape: {Mode?: "Active"|"PassThrough"}
  --tags: record # A list of tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) to apply to the function.
  --layers: list<string> # A list of function layers (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html) to add to the function's execution environment. Specify each layer by its ARN, including the version.
  --file-system-configs: list # Connection settings for an Amazon EFS file system. — item shape: {Arn: string, LocalMountPath: string}
  --image-config: record # Configuration values that override the container image Dockerfile settings. For more information, see Container image settings (https://docs.aws.amazon.com/lambda/latest/dg/images-create.html#images-parms). — shape: {EntryPoint?: list<string>, Command?: list<string>, WorkingDirectory?: string}
  --code-signing-config-arn: string # To enable code signing for this function, specify the ARN of a code-signing configuration. A code-signing configuration includes a set of signing profiles, which define the trusted publishers for this function.
  --architectures: list<string> # The instruction set architecture that the function supports. Enter a string array with one of the valid values (arm64 or x86_64). The default value is x86_64.
  --ephemeral-storage: record # The size of the function's /tmp directory in MB. The default value is 512, but it can be any whole number between 512 and 10,240 MB. — shape: {Size?: int}
  --snap-start: record # The function's Lambda SnapStart setting. Set ApplyOn to PublishedVersions to create a snapshot of the initialized execution environment when you publish a function version. SnapStart is supported with the java11 runtime. For more information, see Improving startup performance with Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html). — shape: {ApplyOn?: "PublishedVersions"|"None"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-03-31/functions"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FunctionName, var: function_name}, {name: Runtime, var: runtime}, {name: Role, var: role}, {name: Handler, var: handler}, {name: Code, var: code}, {name: Description, var: description}, {name: Timeout, var: timeout}, {name: MemorySize, var: memory_size}, {name: Publish, var: publish}, {name: VpcConfig, var: vpc_config}, {name: PackageType, var: package_type}, {name: DeadLetterConfig, var: dead_letter_config}, {name: Environment, var: environment}, {name: KMSKeyArn, var: kms_key_arn}, {name: TracingConfig, var: tracing_config}, {name: Tags, var: tags}, {name: Layers, var: layers}, {name: FileSystemConfigs, var: file_system_configs}, {name: ImageConfig, var: image_config}, {name: CodeSigningConfigArn, var: code_signing_config_arn}, {name: Architectures, var: architectures}, {name: EphemeralStorage, var: ephemeral_storage}, {name: SnapStart, var: snap_start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, function_name: $function_name, runtime: $runtime, role: $role, handler: $handler, code: $code, description: $description, timeout: $timeout, memory_size: $memory_size, publish: $publish, vpc_config: $vpc_config, package_type: $package_type, dead_letter_config: $dead_letter_config, environment: $environment, kms_key_arn: $kms_key_arn, tracing_config: $tracing_config, tags: $tags, layers: $layers, file_system_configs: $file_system_configs, image_config: $image_config, code_signing_config_arn: $code_signing_config_arn, architectures: $architectures, ephemeral_storage: $ephemeral_storage, snap_start: $snap_start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Lambda function URL with the specified configuration parameters. A function URL is a dedicated HTTP(S) endpoint that you can use to invoke your function.
#
# POST /2021-10-31/functions/{FunctionName}/url
# Returns: record<FunctionUrl: string, FunctionArn: string, AuthType: string, Cors: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreationTime: string, InvokeMode: string>
# operationId: CreateFunctionUrlConfig
export def "create-function-url-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  auth_type: string@auth-type-completer # The type of authentication that your function URL uses. Set to AWS_IAM if you want to restrict access to authenticated users only. Set to NONE if you want to bypass IAM authentication to create a public endpoint. For more information, see Security and auth model for Lambda function URLs (https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html).
  --cors: record # The cross-origin resource sharing (CORS) (https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) settings for your Lambda function URL. Use CORS to grant access to your function URL from any origin. You can also use CORS to control access for specific HTTP headers and methods in requests to your function URL. — shape: {AllowCredentials?: bool, AllowHeaders?: list<string>, AllowMethods?: list<string>, AllowOrigins?: list<string>, ExposeHeaders?: list<string>, MaxAge?: int}
  --invoke-mode: string@invoke-mode-completer # Use one of the following options: BUFFERED – This is the default option. Lambda invokes your function using the Invoke API operation. Invocation results are available when the payload is complete. The maximum payload size is 6 MB. RESPONSE_STREAM – Your function streams payload results as they become available. Lambda invokes your function using the InvokeWithResponseStream API operation. The maximum response payload size is 20 MB, however, you can request a quota increase (https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2021-10-31/functions/{FunctionName}/url"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AuthType, var: auth_type}, {name: Cors, var: cors}, {name: InvokeMode, var: invoke_mode}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, auth_type: $auth_type, cors: $cors, invoke_mode: $invoke_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Lambda function URL. When you delete a function URL, you can't recover it. Creating a new function URL results in a different URL address.
#
# DELETE /2021-10-31/functions/{FunctionName}/url
# operationId: DeleteFunctionUrlConfig
export def "delete-function-url-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2021-10-31/functions/{FunctionName}/url"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details about a Lambda function URL.
#
# GET /2021-10-31/functions/{FunctionName}/url
# Returns: record<FunctionUrl: string, FunctionArn: string, AuthType: string, Cors: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreationTime: string, LastModifiedTime: string, InvokeMode: string>
# operationId: GetFunctionUrlConfig
export def "get-function-url-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2021-10-31/functions/{FunctionName}/url"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration for a Lambda function URL.
#
# PUT /2021-10-31/functions/{FunctionName}/url
# Returns: record<FunctionUrl: string, FunctionArn: string, AuthType: string, Cors: record<AllowCredentials: bool, AllowHeaders: list<string>, AllowMethods: list<string>, AllowOrigins: list<string>, ExposeHeaders: list<string>, MaxAge: int>, CreationTime: string, LastModifiedTime: string, InvokeMode: string>
# operationId: UpdateFunctionUrlConfig
export def "update-function-url-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --auth-type: string@auth-type-completer # The type of authentication that your function URL uses. Set to AWS_IAM if you want to restrict access to authenticated users only. Set to NONE if you want to bypass IAM authentication to create a public endpoint. For more information, see Security and auth model for Lambda function URLs (https://docs.aws.amazon.com/lambda/latest/dg/urls-auth.html).
  --cors: record # The cross-origin resource sharing (CORS) (https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) settings for your Lambda function URL. Use CORS to grant access to your function URL from any origin. You can also use CORS to control access for specific HTTP headers and methods in requests to your function URL. — shape: {AllowCredentials?: bool, AllowHeaders?: list<string>, AllowMethods?: list<string>, AllowOrigins?: list<string>, ExposeHeaders?: list<string>, MaxAge?: int}
  --invoke-mode: string@invoke-mode-completer # Use one of the following options: BUFFERED – This is the default option. Lambda invokes your function using the Invoke API operation. Invocation results are available when the payload is complete. The maximum payload size is 6 MB. RESPONSE_STREAM – Your function streams payload results as they become available. Lambda invokes your function using the InvokeWithResponseStream API operation. The maximum response payload size is 20 MB, however, you can request a quota increase (https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2021-10-31/functions/{FunctionName}/url"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AuthType, var: auth_type}, {name: Cors, var: cors}, {name: InvokeMode, var: invoke_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, auth_type: $auth_type, cors: $cors, invoke_mode: $invoke_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Lambda function alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).
#
# DELETE /2015-03-31/functions/{FunctionName}/aliases/{Name}
# operationId: DeleteAlias
export def "delete-alias" [
  function_name: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2015-03-31/functions/{FunctionName}/aliases/{Name}"
    path_params: [{name: FunctionName, var: function_name}, {name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details about a Lambda function alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).
#
# GET /2015-03-31/functions/{FunctionName}/aliases/{Name}
# Returns: record<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: string>
# operationId: GetAlias
export def "get-alias" [
  function_name: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/functions/{FunctionName}/aliases/{Name}"
    path_params: [{name: FunctionName, var: function_name}, {name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of a Lambda function alias (https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html).
#
# PUT /2015-03-31/functions/{FunctionName}/aliases/{Name}
# Returns: record<AliasArn: string, Name: string, FunctionVersion: string, Description: string, RoutingConfig: record<AdditionalVersionWeights: record>, RevisionId: string>
# operationId: UpdateAlias
export def "update-alias" [
  function_name: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --function-version: string # The function version that the alias invokes.
  --description: string # A description of the alias.
  --routing-config: record # The traffic-shifting (https://docs.aws.amazon.com/lambda/latest/dg/lambda-traffic-shifting-using-aliases.html) configuration of a Lambda function alias. — shape: {AdditionalVersionWeights?: record}
  --revision-id: string # Only update the alias if the revision ID matches the ID that's specified. Use this option to avoid modifying an alias that has changed since you last read it.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2015-03-31/functions/{FunctionName}/aliases/{Name}"
    path_params: [{name: FunctionName, var: function_name}, {name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FunctionVersion, var: function_version}, {name: Description, var: description}, {name: RoutingConfig, var: routing_config}, {name: RevisionId, var: revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, function_version: $function_version, description: $description, routing_config: $routing_config, revision_id: $revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the code signing configuration. You can delete the code signing configuration only if no function is using it.
#
# DELETE /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# Returns: record
# operationId: DeleteCodeSigningConfig
export def "delete-code-signing-config" [
  code_signing_config_arn: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2020-04-22/code-signing-configs/{CodeSigningConfigArn}"
    path_params: [{name: CodeSigningConfigArn, var: code_signing_config_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    code_signing_config_arn: $code_signing_config_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the specified code signing configuration.
#
# GET /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# Returns: record<CodeSigningConfig: record<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record<SigningProfileVersionArns: list>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: string>, LastModified: string>>
# operationId: GetCodeSigningConfig
export def "get-code-signing-config" [
  code_signing_config_arn: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-04-22/code-signing-configs/{CodeSigningConfigArn}"
    path_params: [{name: CodeSigningConfigArn, var: code_signing_config_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code_signing_config_arn: $code_signing_config_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the code signing configuration. Changes to the code signing configuration take effect the next time a user tries to deploy a code package to the function.
#
# PUT /2020-04-22/code-signing-configs/{CodeSigningConfigArn}
# Returns: record<CodeSigningConfig: record<CodeSigningConfigId: string, CodeSigningConfigArn: string, Description: string, AllowedPublishers: record<SigningProfileVersionArns: list>, CodeSigningPolicies: record<UntrustedArtifactOnDeployment: string>, LastModified: string>>
# operationId: UpdateCodeSigningConfig
export def "update-code-signing-config" [
  code_signing_config_arn: string
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
  --description: string # Descriptive name for this code signing configuration.
  --allowed-publishers: record # List of signing profiles that can sign a code package. — shape: {SigningProfileVersionArns?: list<string>}
  --code-signing-policies: record # Code signing configuration policies (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html#config-codesigning-policies) specify the validation failure action for signature mismatch or expiry. — shape: {UntrustedArtifactOnDeployment?: "Warn"|"Enforce"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2020-04-22/code-signing-configs/{CodeSigningConfigArn}"
    path_params: [{name: CodeSigningConfigArn, var: code_signing_config_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: AllowedPublishers, var: allowed_publishers}, {name: CodeSigningPolicies, var: code_signing_policies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code_signing_config_arn: $code_signing_config_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, allowed_publishers: $allowed_publishers, code_signing_policies: $code_signing_policies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an event source mapping (https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html). You can get the identifier of a mapping from the output of ListEventSourceMappings. When you delete an event source mapping, it enters a Deleting state and might not be completely deleted for several seconds.
#
# DELETE /2015-03-31/event-source-mappings/{UUID}
# Returns: record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>
# operationId: DeleteEventSourceMapping
export def "delete-event-source-mapping" [
  uuid: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2015-03-31/event-source-mappings/{UUID}"
    path_params: [{name: UUID, var: uuid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    uuid: $uuid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details about an event source mapping. You can get the identifier of a mapping from the output of ListEventSourceMappings.
#
# GET /2015-03-31/event-source-mappings/{UUID}
# Returns: record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>
# operationId: GetEventSourceMapping
export def "get-event-source-mapping" [
  uuid: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/event-source-mappings/{UUID}"
    path_params: [{name: UUID, var: uuid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uuid: $uuid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an event source mapping. You can change the function that Lambda invokes, or pause invocation and resume later from the same location. For details about how to configure different event sources, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-dynamodb-eventsourcemapping) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-eventsourcemapping) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-eventsource) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-eventsourcemapping) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/kafka-smaa.html) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html) The following error handling options are available only for stream sources (DynamoDB and Kinesis): BisectBatchOnFunctionError – If the function returns an error, split the batch in two and retry. DestinationConfig – Send discarded records to an Amazon SQS queue or Amazon SNS topic. MaximumRecordAgeInSeconds – Discard records older than the specified age. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires MaximumRetryAttempts – Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires. ParallelizationFactor – Process multiple batches from each shard concurrently. For information about which configuration parameters apply to each event source, see the following topics. Amazon DynamoDB Streams (https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html#services-ddb-params) Amazon Kinesis (https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-params) Amazon SQS (https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#services-sqs-params) Amazon MQ and RabbitMQ (https://docs.aws.amazon.com/lambda/latest/dg/with-mq.html#services-mq-params) Amazon MSK (https://docs.aws.amazon.com/lambda/latest/dg/with-msk.html#services-msk-parms) Apache Kafka (https://docs.aws.amazon.com/lambda/latest/dg/with-kafka.html#services-kafka-parms) Amazon DocumentDB (https://docs.aws.amazon.com/lambda/latest/dg/with-documentdb.html#docdb-configuration)
#
# PUT /2015-03-31/event-source-mappings/{UUID}
# Returns: record<UUID: string, StartingPosition: string, StartingPositionTimestamp: string, BatchSize: int, MaximumBatchingWindowInSeconds: int, ParallelizationFactor: int, EventSourceArn: string, FilterCriteria: record<Filters: list<record>>, FunctionArn: string, LastModified: string, LastProcessingResult: string, State: string, StateTransitionReason: string, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>, Topics: list<string>, Queues: list<string>, SourceAccessConfigurations: table<Type: string, URI: string>, SelfManagedEventSource: record<Endpoints: record>, MaximumRecordAgeInSeconds: int, BisectBatchOnFunctionError: bool, MaximumRetryAttempts: int, TumblingWindowInSeconds: int, FunctionResponseTypes: list<string>, AmazonManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, SelfManagedKafkaEventSourceConfig: record<ConsumerGroupId: string>, ScalingConfig: record<MaximumConcurrency: int>, DocumentDBEventSourceConfig: record<DatabaseName: string, CollectionName: string, FullDocument: string>>
# operationId: UpdateEventSourceMapping
export def "update-event-source-mapping" [
  uuid: string
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
  --function-name: string # The name of the Lambda function. Name formats Function name – MyFunction. Function ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction. Version or Alias ARN – arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD. Partial ARN – 123456789012:function:MyFunction. The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.
  --enabled: oneof<nothing, bool> # When true, the event source mapping is active. When false, Lambda pauses polling and invocation. Default: True
  --batch-size: int # The maximum number of records in each batch that Lambda pulls from your stream or queue and sends to your function. Lambda passes all of the records in the batch to the function in a single call, up to the payload limit for synchronous invocation (6 MB). Amazon Kinesis – Default 100. Max 10,000. Amazon DynamoDB Streams – Default 100. Max 10,000. Amazon Simple Queue Service – Default 10. For standard queues the max is 10,000. For FIFO queues the max is 10. Amazon Managed Streaming for Apache Kafka – Default 100. Max 10,000. Self-managed Apache Kafka – Default 100. Max 10,000. Amazon MQ (ActiveMQ and RabbitMQ) – Default 100. Max 10,000. DocumentDB – Default 100. Max 10,000.
  --filter-criteria: record # An object that contains the filters for an event source. — shape: {Filters?: list}
  --maximum-batching-window-in-seconds: int # The maximum amount of time, in seconds, that Lambda spends gathering records before invoking the function. You can configure MaximumBatchingWindowInSeconds to any value from 0 seconds to 300 seconds in increments of seconds. For streams and Amazon SQS event sources, the default batching window is 0 seconds. For Amazon MSK, Self-managed Apache Kafka, Amazon MQ, and DocumentDB event sources, the default batching window is 500 ms. Note that because you can only change MaximumBatchingWindowInSeconds in increments of seconds, you cannot revert back to the 500 ms default batching window after you have changed it. To restore the default batching window, you must create a new event source mapping. Related setting: For streams and Amazon SQS event sources, when you set BatchSize to a value greater than 10, you must set MaximumBatchingWindowInSeconds to at least 1.
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: record, OnFailure?: record}
  --maximum-record-age-in-seconds: int # (Kinesis and DynamoDB Streams only) Discard records older than the specified age. The default value is infinite (-1).
  --bisect-batch-on-function-error: oneof<nothing, bool> # (Kinesis and DynamoDB Streams only) If the function returns an error, split the batch in two and retry.
  --maximum-retry-attempts: int # (Kinesis and DynamoDB Streams only) Discard records after the specified number of retries. The default value is infinite (-1). When set to infinite (-1), failed records are retried until the record expires.
  --parallelization-factor: int # (Kinesis and DynamoDB Streams only) The number of batches to process from each shard concurrently.
  --source-access-configurations: list # An array of authentication protocols or VPC components required to secure your event source. — item shape: {Type?: "BASIC_AUTH"|"VPC_SUBNET"|"VPC_SECURITY_GROUP"|"SASL_SCRAM_512_AUTH"|"SASL_SCRAM_256_AUTH"|"VIRTUAL_HOST"|"CLIENT_CERTIFICATE_TLS_AUTH"|"SERVER_ROOT_CA_CERTIFICATE", URI?: string}
  --tumbling-window-in-seconds: int # (Kinesis and DynamoDB Streams only) The duration in seconds of a processing window for DynamoDB and Kinesis Streams event sources. A value of 0 seconds indicates no tumbling window.
  --function-response-types: list<string> # (Kinesis, DynamoDB Streams, and Amazon SQS) A list of current response type enums applied to the event source mapping.
  --scaling-config: record # (Amazon SQS only) The scaling configuration for the event source. To remove the configuration, pass an empty value. — shape: {MaximumConcurrency?: int}
  --document-db-event-source-config: record # Specific configuration settings for a DocumentDB event source. — shape: {DatabaseName?: string, CollectionName?: string, FullDocument?: "UpdateLookup"|"Default"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2015-03-31/event-source-mappings/{UUID}"
    path_params: [{name: UUID, var: uuid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FunctionName, var: function_name}, {name: Enabled, var: enabled}, {name: BatchSize, var: batch_size}, {name: FilterCriteria, var: filter_criteria}, {name: MaximumBatchingWindowInSeconds, var: maximum_batching_window_in_seconds}, {name: DestinationConfig, var: destination_config}, {name: MaximumRecordAgeInSeconds, var: maximum_record_age_in_seconds}, {name: BisectBatchOnFunctionError, var: bisect_batch_on_function_error}, {name: MaximumRetryAttempts, var: maximum_retry_attempts}, {name: ParallelizationFactor, var: parallelization_factor}, {name: SourceAccessConfigurations, var: source_access_configurations}, {name: TumblingWindowInSeconds, var: tumbling_window_in_seconds}, {name: FunctionResponseTypes, var: function_response_types}, {name: ScalingConfig, var: scaling_config}, {name: DocumentDBEventSourceConfig, var: document_db_event_source_config}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    uuid: $uuid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, function_name: $function_name, enabled: $enabled, batch_size: $batch_size, filter_criteria: $filter_criteria, maximum_batching_window_in_seconds: $maximum_batching_window_in_seconds, destination_config: $destination_config, maximum_record_age_in_seconds: $maximum_record_age_in_seconds, bisect_batch_on_function_error: $bisect_batch_on_function_error, maximum_retry_attempts: $maximum_retry_attempts, parallelization_factor: $parallelization_factor, source_access_configurations: $source_access_configurations, tumbling_window_in_seconds: $tumbling_window_in_seconds, function_response_types: $function_response_types, scaling_config: $scaling_config, document_db_event_source_config: $document_db_event_source_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Lambda function. To delete a specific function version, use the Qualifier parameter. Otherwise, all versions and aliases are deleted. To delete Lambda event source mappings that invoke a function, use DeleteEventSourceMapping. For Amazon Web Services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.
#
# DELETE /2015-03-31/functions/{FunctionName}
# operationId: DeleteFunction
export def "delete-function" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version to delete. You can't delete a version that an alias references.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2015-03-31/functions/{FunctionName}"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
#
# GET /2015-03-31/functions/{FunctionName}
# Returns: record<Configuration: record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list, SecurityGroupIds: list, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: list<record>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: list<record>, PackageType: string, ImageConfigResponse: record<ImageConfig: record, Error: record>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record>>, Code: record<RepositoryType: string, Location: string, ImageUri: string, ResolvedImageUri: string>, Tags: record, Concurrency: record<ReservedConcurrentExecutions: int>>
# operationId: GetFunction
export def "get-function" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to get details about a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/functions/{FunctionName}"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the code signing configuration from the function.
#
# DELETE /2020-06-30/functions/{FunctionName}/code-signing-config
# operationId: DeleteFunctionCodeSigningConfig
export def "delete-function-code-signing-config" [
  function_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/2020-06-30/functions/{FunctionName}/code-signing-config"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the code signing configuration for the specified function.
#
# GET /2020-06-30/functions/{FunctionName}/code-signing-config
# Returns: record<CodeSigningConfigArn: string, FunctionName: string>
# operationId: GetFunctionCodeSigningConfig
export def "get-function-code-signing-config" [
  function_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-06-30/functions/{FunctionName}/code-signing-config"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the code signing configuration for the function. Changes to the code signing configuration take effect the next time a user tries to deploy a code package to the function.
#
# PUT /2020-06-30/functions/{FunctionName}/code-signing-config
# Returns: record<CodeSigningConfigArn: string, FunctionName: string>
# operationId: PutFunctionCodeSigningConfig
export def "put-function-code-signing-config" [
  function_name: string
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
  code_signing_config_arn: string # The The Amazon Resource Name (ARN) of the code signing configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2020-06-30/functions/{FunctionName}/code-signing-config"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CodeSigningConfigArn, var: code_signing_config_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, code_signing_config_arn: $code_signing_config_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a concurrent execution limit from a function.
#
# DELETE /2017-10-31/functions/{FunctionName}/concurrency
# operationId: DeleteFunctionConcurrency
export def "delete-function-concurrency" [
  function_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/2017-10-31/functions/{FunctionName}/concurrency"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level. Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use GetFunction to see the current setting for a function. Use GetAccountSettings to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see Lambda function scaling (https://docs.aws.amazon.com/lambda/latest/dg/invocation-scaling.html).
#
# PUT /2017-10-31/functions/{FunctionName}/concurrency
# Returns: record<ReservedConcurrentExecutions: int>
# operationId: PutFunctionConcurrency
export def "put-function-concurrency" [
  function_name: string
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
  reserved_concurrent_executions: int # The number of simultaneous executions to reserve for the function.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2017-10-31/functions/{FunctionName}/concurrency"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReservedConcurrentExecutions, var: reserved_concurrent_executions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, reserved_concurrent_executions: $reserved_concurrent_executions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the configuration for asynchronous invocation for a function, version, or alias. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# DELETE /2019-09-25/functions/{FunctionName}/event-invoke-config
# operationId: DeleteFunctionEventInvokeConfig
export def "delete-function-event-invoke-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2019-09-25/functions/{FunctionName}/event-invoke-config"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the configuration for asynchronous invocation for a function, version, or alias. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# GET /2019-09-25/functions/{FunctionName}/event-invoke-config
# Returns: record<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>>
# operationId: GetFunctionEventInvokeConfig
export def "get-function-event-invoke-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2019-09-25/functions/{FunctionName}/event-invoke-config"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures options for asynchronous invocation (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html) on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use UpdateFunctionEventInvokeConfig. By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with UpdateFunctionConfiguration. To send an invocation record to a queue, topic, function, or event bus, specify a destination (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations). You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.
#
# PUT /2019-09-25/functions/{FunctionName}/event-invoke-config
# Returns: record<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>>
# operationId: PutFunctionEventInvokeConfig
export def "put-function-event-invoke-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --maximum-retry-attempts: int # The maximum number of times to retry when the function returns an error.
  --maximum-event-age-in-seconds: int # The maximum age of a request that Lambda sends to a function for processing.
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: record, OnFailure?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2019-09-25/functions/{FunctionName}/event-invoke-config"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaximumRetryAttempts, var: maximum_retry_attempts}, {name: MaximumEventAgeInSeconds, var: maximum_event_age_in_seconds}, {name: DestinationConfig, var: destination_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, maximum_retry_attempts: $maximum_retry_attempts, maximum_event_age_in_seconds: $maximum_event_age_in_seconds, destination_config: $destination_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration for asynchronous invocation for a function, version, or alias. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# POST /2019-09-25/functions/{FunctionName}/event-invoke-config
# Returns: record<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record<OnSuccess: record<Destination: string>, OnFailure: record<Destination: string>>>
# operationId: UpdateFunctionEventInvokeConfig
export def "update-function-event-invoke-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # A version number or alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --maximum-retry-attempts: int # The maximum number of times to retry when the function returns an error.
  --maximum-event-age-in-seconds: int # The maximum age of a request that Lambda sends to a function for processing.
  --destination-config: record # A configuration object that specifies the destination of an event after Lambda processes it. — shape: {OnSuccess?: record, OnFailure?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2019-09-25/functions/{FunctionName}/event-invoke-config"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaximumRetryAttempts, var: maximum_retry_attempts}, {name: MaximumEventAgeInSeconds, var: maximum_event_age_in_seconds}, {name: DestinationConfig, var: destination_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, maximum_retry_attempts: $maximum_retry_attempts, maximum_event_age_in_seconds: $maximum_event_age_in_seconds, destination_config: $destination_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
#
# DELETE /2018-10-31/layers/{LayerName}/versions/{VersionNumber}
# operationId: DeleteLayerVersion
export def "delete-layer-version" [
  layer_name: string
  version_number: int
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}"
    path_params: [{name: LayerName, var: layer_name}, {name: VersionNumber, var: version_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    layer_name: $layer_name, version_number: $version_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html), with a link to download the layer archive that's valid for 10 minutes.
#
# GET /2018-10-31/layers/{LayerName}/versions/{VersionNumber}
# Returns: record<Content: record<Location: string, CodeSha256: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, LayerArn: string, LayerVersionArn: string, Description: string, CreatedDate: string, Version: int, CompatibleRuntimes: list<string>, LicenseInfo: string, CompatibleArchitectures: list<string>>
# operationId: GetLayerVersion
export def "get-layer-version" [
  layer_name: string
  version_number: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}"
    path_params: [{name: LayerName, var: layer_name}, {name: VersionNumber, var: version_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    layer_name: $layer_name, version_number: $version_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the provisioned concurrency configuration for a function.
#
# DELETE /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# operationId: DeleteProvisionedConcurrencyConfig
export def "delete-provisioned-concurrency-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The version number or alias name. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the provisioned concurrency configuration for a function's alias or version.
#
# GET /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# Returns: record<RequestedProvisionedConcurrentExecutions: int, AvailableProvisionedConcurrentExecutions: int, AllocatedProvisionedConcurrentExecutions: int, Status: string, StatusReason: string, LastModified: string>
# operationId: GetProvisionedConcurrencyConfig
export def "get-provisioned-concurrency-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The version number or alias name. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a provisioned concurrency configuration to a function's alias or version.
#
# PUT /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# Returns: record<RequestedProvisionedConcurrentExecutions: int, AvailableProvisionedConcurrentExecutions: int, AllocatedProvisionedConcurrentExecutions: int, Status: string, StatusReason: string, LastModified: string>
# operationId: PutProvisionedConcurrencyConfig
export def "put-provisioned-concurrency-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The version number or alias name. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  provisioned_concurrent_executions: int # The amount of provisioned concurrency to allocate for the version or alias.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProvisionedConcurrentExecutions, var: provisioned_concurrent_executions}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, provisioned_concurrent_executions: $provisioned_concurrent_executions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details about your account's limits (https://docs.aws.amazon.com/lambda/latest/dg/limits.html) and usage in an Amazon Web Services Region.
#
# GET /2016-08-19/account-settings/
# Returns: record<AccountLimit: record<TotalCodeSize: int, CodeSizeUnzipped: int, CodeSizeZipped: int, ConcurrentExecutions: int, UnreservedConcurrentExecutions: int>, AccountUsage: record<TotalCodeSize: int, FunctionCount: int>>
# operationId: GetAccountSettings
export def "get-account-settings" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2016-08-19/account-settings/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use PutFunctionConcurrency.
#
# GET /2019-09-30/functions/{FunctionName}/concurrency
# Returns: record<ReservedConcurrentExecutions: int>
# operationId: GetFunctionConcurrency
export def "get-function-concurrency" [
  function_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2019-09-30/functions/{FunctionName}/concurrency"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use UpdateFunctionConfiguration. To get all of a function's details, including function-level settings, use GetFunction.
#
# GET /2015-03-31/functions/{FunctionName}/configuration
# Returns: record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>
# operationId: GetFunctionConfiguration
export def "get-function-configuration" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to get details about a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/functions/{FunctionName}/configuration"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the version-specific settings of a Lambda function. When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The LastUpdateStatus, LastUpdateStatusReason, and LastUpdateStatusReasonCode fields in the response from GetFunctionConfiguration indicate when the update is complete and the function is processing events with the new configuration. For more information, see Lambda function states (https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html). These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version. To configure function concurrency, use PutFunctionConcurrency. To grant invoke permissions to an Amazon Web Services account or Amazon Web Service, use AddPermission.
#
# PUT /2015-03-31/functions/{FunctionName}/configuration
# Returns: record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>
# operationId: UpdateFunctionConfiguration
export def "update-function-configuration" [
  function_name: string
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
  --role: string # The Amazon Resource Name (ARN) of the function's execution role.
  --handler: string # The name of the method within your code that Lambda calls to run your function. Handler is required if the deployment package is a .zip file archive. The format includes the file name. It can also include namespaces and other qualifiers, depending on the runtime. For more information, see Lambda programming model (https://docs.aws.amazon.com/lambda/latest/dg/foundation-progmodel.html).
  --description: string # A description of the function.
  --timeout: int # The amount of time (in seconds) that Lambda allows a function to run before stopping it. The default is 3 seconds. The maximum allowed value is 900 seconds. For more information, see Lambda execution environment (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html).
  --memory-size: int # The amount of memory available to the function (https://docs.aws.amazon.com/lambda/latest/dg/configuration-function-common.html#configuration-memory-console) at runtime. Increasing the function memory also increases its CPU allocation. The default value is 128 MB. The value can be any multiple of 1 MB.
  --vpc-config: record # The VPC security groups and subnets that are attached to a Lambda function. For more information, see Configuring a Lambda function to access resources in a VPC (https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --environment: record # A function's environment variable settings. You can use environment variables to adjust your function's behavior without updating code. An environment variable is a pair of strings that are stored in a function's version-specific configuration. — shape: {Variables?: record}
  --runtime: string@runtime-completer # The identifier of the function's runtime (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html). Runtime is required if the deployment package is a .zip file archive. The following list includes deprecated runtimes. For more information, see Runtime deprecation policy (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html#runtime-support-policy).
  --dead-letter-config: record # The dead-letter queue (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq) for failed asynchronous invocations. — shape: {TargetArn?: string}
  --kms-key-arn: string # The ARN of the Key Management Service (KMS) customer managed key that's used to encrypt your function's environment variables (https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html#configuration-envvars-encryption). When Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart-security.html) is activated, this key is also used to encrypt your function's snapshot. If you don't provide a customer managed key, Lambda uses a default service key.
  --tracing-config: record # The function's X-Ray (https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html) tracing configuration. To sample and record incoming requests, set Mode to Active. — shape: {Mode?: "Active"|"PassThrough"}
  --revision-id: string # Update the function only if the revision ID matches the ID that's specified. Use this option to avoid modifying a function that has changed since you last read it.
  --layers: list<string> # A list of function layers (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html) to add to the function's execution environment. Specify each layer by its ARN, including the version.
  --file-system-configs: list # Connection settings for an Amazon EFS file system. — item shape: {Arn: string, LocalMountPath: string}
  --image-config: record # Configuration values that override the container image Dockerfile settings. For more information, see Container image settings (https://docs.aws.amazon.com/lambda/latest/dg/images-create.html#images-parms). — shape: {EntryPoint?: list<string>, Command?: list<string>, WorkingDirectory?: string}
  --ephemeral-storage: record # The size of the function's /tmp directory in MB. The default value is 512, but it can be any whole number between 512 and 10,240 MB. — shape: {Size?: int}
  --snap-start: record # The function's Lambda SnapStart setting. Set ApplyOn to PublishedVersions to create a snapshot of the initialized execution environment when you publish a function version. SnapStart is supported with the java11 runtime. For more information, see Improving startup performance with Lambda SnapStart (https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html). — shape: {ApplyOn?: "PublishedVersions"|"None"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2015-03-31/functions/{FunctionName}/configuration"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Role, var: role}, {name: Handler, var: handler}, {name: Description, var: description}, {name: Timeout, var: timeout}, {name: MemorySize, var: memory_size}, {name: VpcConfig, var: vpc_config}, {name: Environment, var: environment}, {name: Runtime, var: runtime}, {name: DeadLetterConfig, var: dead_letter_config}, {name: KMSKeyArn, var: kms_key_arn}, {name: TracingConfig, var: tracing_config}, {name: RevisionId, var: revision_id}, {name: Layers, var: layers}, {name: FileSystemConfigs, var: file_system_configs}, {name: ImageConfig, var: image_config}, {name: EphemeralStorage, var: ephemeral_storage}, {name: SnapStart, var: snap_start}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role: $role, handler: $handler, description: $description, timeout: $timeout, memory_size: $memory_size, vpc_config: $vpc_config, environment: $environment, runtime: $runtime, dead_letter_config: $dead_letter_config, kms_key_arn: $kms_key_arn, tracing_config: $tracing_config, revision_id: $revision_id, layers: $layers, file_system_configs: $file_system_configs, image_config: $image_config, ephemeral_storage: $ephemeral_storage, snap_start: $snap_start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html), with a link to download the layer archive that's valid for 10 minutes.
#
# GET /2018-10-31/layers
# Returns: record<Content: record<Location: string, CodeSha256: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, LayerArn: string, LayerVersionArn: string, Description: string, CreatedDate: string, Version: int, CompatibleRuntimes: list<string>, LicenseInfo: string, CompatibleArchitectures: list<string>>
# operationId: GetLayerVersionByArn
export def "get-layer-version-by-arn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string # The ARN of the layer version. (required)
  --find: string@find-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2018-10-31/layers"
    query: [{name: Arn, var: arn, required: true}, {name: find, var: find, required: true, default: LayerVersion}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, find: $find, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the runtime management configuration for a function's version. If the runtime update mode is Manual, this includes the ARN of the runtime version and the runtime update mode. If the runtime update mode is Auto or Function update, this includes the runtime update mode and null is returned for the ARN. For more information, see Runtime updates (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html).
#
# GET /2021-07-20/functions/{FunctionName}/runtime-management-config
# Returns: record<UpdateRuntimeOn: string, RuntimeVersionArn: string, FunctionArn: string>
# operationId: GetRuntimeManagementConfig
export def "get-runtime-management-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version of the function. This can be $LATEST or a published version number. If no value is specified, the configuration for the $LATEST version is returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2021-07-20/functions/{FunctionName}/runtime-management-config"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the runtime management configuration for a function's version. For more information, see Runtime updates (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html).
#
# PUT /2021-07-20/functions/{FunctionName}/runtime-management-config
# Returns: record<UpdateRuntimeOn: string, FunctionArn: string, RuntimeVersionArn: string>
# operationId: PutRuntimeManagementConfig
export def "put-runtime-management-config" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version of the function. This can be $LATEST or a published version number. If no value is specified, the configuration for the $LATEST version is returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  update_runtime_on: string@update-runtime-on-completer # Specify the runtime update mode. Auto (default) - Automatically update to the most recent and secure runtime version using a Two-phase runtime version rollout (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html#runtime-management-two-phase). This is the best choice for most customers to ensure they always benefit from runtime updates. Function update - Lambda updates the runtime of your function to the most recent and secure runtime version when you update your function. This approach synchronizes runtime updates with function deployments, giving you control over when runtime updates are applied and allowing you to detect and mitigate rare runtime update incompatibilities early. When using this setting, you need to regularly update your functions to keep their runtime up-to-date. Manual - You specify a runtime version in your function configuration. The function will use this runtime version indefinitely. In the rare case where a new runtime version is incompatible with an existing function, this allows you to roll back your function to an earlier runtime version. For more information, see Roll back a runtime version (https://docs.aws.amazon.com/lambda/latest/dg/runtimes-update.html#runtime-management-rollback).
  --runtime-version-arn: string # The ARN of the runtime version you want the function to use. This is only required if you're using the Manual runtime update mode.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2021-07-20/functions/{FunctionName}/runtime-management-config"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UpdateRuntimeOn, var: update_runtime_on}, {name: RuntimeVersionArn, var: runtime_version_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, update_runtime_on: $update_runtime_on, runtime_version_arn: $runtime_version_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set InvocationType to Event. For synchronous invocation (https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html), details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the execution log (https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html) and trace (https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html). When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see Error handling and automatic retries in Lambda (https://docs.aws.amazon.com/lambda/latest/dg/invocation-retries.html). For asynchronous invocation (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html), Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a dead-letter queue (https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-dlq). The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, quota (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html) errors, or issues with your function's code and configuration. For example, Lambda returns TooManyRequestsException if running the function would cause you to exceed a concurrency limit at either the account level (ConcurrentInvocationLimitExceeded) or function level (ReservedFunctionConcurrentInvocationLimitExceeded). For functions with a long timeout, your client might disconnect during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings. This operation requires permission for the lambda:InvokeFunction (https://docs.aws.amazon.com/IAM/latest/UserGuide/list_awslambda.html) action. For details on how to set up permissions for cross-account invocations, see Granting function access to other accounts (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html#permissions-resource-xaccountinvoke).
#
# POST /2015-03-31/functions/{FunctionName}/invocations
# Returns: record<StatusCode: int, Payload: string>
# operationId: Invoke
export def "invoke" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to invoke a published version of the function.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-invocation-type: string@x-amz-invocation-type-completer # Choose from the following options. RequestResponse (default) – Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API response includes the function response and additional data. Event – Invoke the function asynchronously. Send events that fail multiple times to the function's dead-letter queue (if one is configured). The API response only includes a status code. DryRun – Validate parameter values and verify that the user or role has permission to invoke the function.
  --x-amz-log-type: string@x-amz-log-type-completer # Set to Tail to include the execution log in the response. Applies to synchronously invoked functions only.
  --x-amz-client-context: string # Up to 3,583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  --payload: string # The JSON that you want to provide to your Lambda function as input. You can enter the JSON directly. For example, --payload '{ "key": "value" }'. You can also specify a file path. For example, --payload file://payload.json. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-03-31/functions/{FunctionName}/invocations"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Invocation-Type, var: x_amz_invocation_type}, {name: X-Amz-Log-Type, var: x_amz_log_type}, {name: X-Amz-Client-Context, var: x_amz_client_context}]
    body: {content_type: "application/json", kind: json, fields: [{name: Payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_invocation_type: $x_amz_invocation_type, x_amz_log_type: $x_amz_log_type, x_amz_client_context: $x_amz_client_context, payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For asynchronous function invocation, use Invoke. Invokes a function asynchronously.
#
# POST /2014-11-13/functions/{FunctionName}/invoke-async/
# DEPRECATED
# Returns: record<Status: int>
# operationId: InvokeAsync
@deprecated
export def "invoke-async" [
  function_name: string
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
  invoke_args: string # The JSON that you want to provide to your Lambda function as input.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2014-11-13/functions/{FunctionName}/invoke-async/"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InvokeArgs, var: invoke_args}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, invoke_args: $invoke_args
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure your Lambda functions to stream response payloads back to clients. For more information, see Configuring a Lambda function to stream responses (https://docs.aws.amazon.com/lambda/latest/dg/configuration-response-streaming.html). This operation requires permission for the lambda:InvokeFunction (https://docs.aws.amazon.com/IAM/latest/UserGuide/list_awslambda.html) action. For details on how to set up permissions for cross-account invocations, see Granting function access to other accounts (https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html#permissions-resource-xaccountinvoke).
#
# POST /2021-11-15/functions/{FunctionName}/response-streaming-invocations
# Returns: record<StatusCode: int, EventStream: record<PayloadChunk: record<Payload: string>, InvokeComplete: record<ErrorCode: string, ErrorDetails: string, LogResult: string>>>
# operationId: InvokeWithResponseStream
export def "invoke-with-response-stream" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-invocation-type: string@x-amz-invocation-type-completer-1 # Use one of the following options: RequestResponse (default) – Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API operation response includes the function response and additional data. DryRun – Validate parameter values and verify that the IAM user or role has permission to invoke the function.
  --x-amz-log-type: string@x-amz-log-type-completer # Set to Tail to include the execution log in the response. Applies to synchronously invoked functions only.
  --x-amz-client-context: string # Up to 3,583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  --payload: string # The JSON that you want to provide to your Lambda function as input. You can enter the JSON directly. For example, --payload '{ "key": "value" }'. You can also specify a file path. For example, --payload file://payload.json. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2021-11-15/functions/{FunctionName}/response-streaming-invocations"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Qualifier, var: qualifier}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Invocation-Type, var: x_amz_invocation_type}, {name: X-Amz-Log-Type, var: x_amz_log_type}, {name: X-Amz-Client-Context, var: x_amz_client_context}]
    body: {content_type: "application/json", kind: json, fields: [{name: Payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, qualifier: $qualifier, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_invocation_type: $x_amz_invocation_type, x_amz_log_type: $x_amz_log_type, x_amz_client_context: $x_amz_client_context, payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of configurations for asynchronous invocation for a function. To configure options for asynchronous invocation, use PutFunctionEventInvokeConfig.
#
# GET /2019-09-25/functions/{FunctionName}/event-invoke-config/list
# Returns: record<FunctionEventInvokeConfigs: table<LastModified: string, FunctionArn: string, MaximumRetryAttempts: int, MaximumEventAgeInSeconds: int, DestinationConfig: record>, NextMarker: string>
# operationId: ListFunctionEventInvokeConfigs
export def "list-function-event-invoke-configs" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of configurations to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2019-09-25/functions/{FunctionName}/event-invoke-config/list"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Lambda function URLs for the specified function.
#
# GET /2021-10-31/functions/{FunctionName}/urls
# Returns: record<FunctionUrlConfigs: table<FunctionUrl: string, FunctionArn: string, CreationTime: string, LastModifiedTime: string, Cors: record, AuthType: string, InvokeMode: string>, NextMarker: string>
# operationId: ListFunctionUrlConfigs
export def "list-function-url-configs" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of function URLs to return in the response. Note that ListFunctionUrlConfigs returns a maximum of 50 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2021-10-31/functions/{FunctionName}/urls"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Lambda functions, with the version-specific configuration of each. Lambda returns up to 50 functions per call. Set FunctionVersion to ALL to include all published versions of each function in addition to the unpublished version. The ListFunctions operation returns a subset of the FunctionConfiguration fields. To get the additional fields (State, StateReasonCode, StateReason, LastUpdateStatus, LastUpdateStatusReason, LastUpdateStatusReasonCode, RuntimeVersionConfig) for a function or version, use GetFunction.
#
# GET /2015-03-31/functions/
# Returns: record<NextMarker: string, Functions: table<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record, DeadLetterConfig: record, Environment: record, KMSKeyArn: string, TracingConfig: record, MasterArn: string, RevisionId: string, Layers: list, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: list, PackageType: string, ImageConfigResponse: record, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list, EphemeralStorage: record, SnapStart: record, RuntimeVersionConfig: record>>
# operationId: ListFunctions
export def "list-functions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --master-region: string # For Lambda@Edge functions, the Amazon Web Services Region of the master function. For example, us-east-1 filters the list of functions to include only Lambda@Edge functions replicated from a master function in US East (N. Virginia). If specified, you must set FunctionVersion to ALL.
  --function-version: string@function-version-completer # Set to ALL to include entries for all published versions of each function.
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of functions to return in the response. Note that ListFunctions returns a maximum of 50 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/functions/"
    query: [{name: MasterRegion, var: master_region}, {name: FunctionVersion, var: function_version}, {name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    master_region: $master_region, function_version: $function_version, marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the functions that use the specified code signing configuration. You can use this method prior to deleting a code signing configuration, to verify that no functions are using it.
#
# GET /2020-04-22/code-signing-configs/{CodeSigningConfigArn}/functions
# Returns: record<NextMarker: string, FunctionArns: list<string>>
# operationId: ListFunctionsByCodeSigningConfig
export def "list-functions-by-code-signing-config" [
  code_signing_config_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Maximum number of items to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2020-04-22/code-signing-configs/{CodeSigningConfigArn}/functions"
    path_params: [{name: CodeSigningConfigArn, var: code_signing_config_arn}]
    query: [{name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code_signing_config_arn: $code_signing_config_arn, marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the versions of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). Versions that have been deleted aren't listed. Specify a runtime identifier (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) to list only versions that indicate that they're compatible with that runtime. Specify a compatible architecture to include only layer versions that are compatible with that architecture.
#
# GET /2018-10-31/layers/{LayerName}/versions
# Returns: record<NextMarker: string, LayerVersions: table<LayerVersionArn: string, Version: int, Description: string, CreatedDate: string, CompatibleRuntimes: list, LicenseInfo: string, CompatibleArchitectures: list>>
# operationId: ListLayerVersions
export def "list-layer-versions" [
  layer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compatible-runtime: string@compatible-runtime-completer # A runtime identifier. For example, go1.x.
  --marker: string # A pagination token returned by a previous call.
  --max-items: int # The maximum number of versions to return.
  --compatible-architecture: string@compatible-architecture-completer # The compatible instruction set architecture (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2018-10-31/layers/{LayerName}/versions"
    path_params: [{name: LayerName, var: layer_name}]
    query: [{name: CompatibleRuntime, var: compatible_runtime}, {name: Marker, var: marker}, {name: MaxItems, var: max_items}, {name: CompatibleArchitecture, var: compatible_architecture}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    layer_name: $layer_name, compatible_runtime: $compatible_runtime, marker: $marker, max_items: $max_items, compatible_architecture: $compatible_architecture, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html) from a ZIP archive. Each time you call PublishLayerVersion with the same layer name, a new version is created. Add layers to your function with CreateFunction or UpdateFunctionConfiguration.
#
# POST /2018-10-31/layers/{LayerName}/versions
# Returns: record<Content: record<Location: string, CodeSha256: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, LayerArn: string, LayerVersionArn: string, Description: string, CreatedDate: string, Version: int, CompatibleRuntimes: list<string>, LicenseInfo: string, CompatibleArchitectures: list<string>>
# operationId: PublishLayerVersion
export def "publish-layer-version" [
  layer_name: string
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
  --description: string # The description of the version.
  content: record # A ZIP archive that contains the contents of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). You can specify either an Amazon S3 location, or upload a layer archive directly. — shape: {S3Bucket?: string, S3Key?: string, S3ObjectVersion?: string, ZipFile?: string}
  --compatible-runtimes: list<string> # A list of compatible function runtimes (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html). Used for filtering with ListLayers and ListLayerVersions.
  --license-info: string # The layer's software license. It can be any of the following: An SPDX license identifier (https://spdx.org/licenses/). For example, MIT. The URL of a license hosted on the internet. For example, https://opensource.org/licenses/MIT. The full text of the license.
  --compatible-architectures: list<string> # A list of compatible instruction set architectures (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2018-10-31/layers/{LayerName}/versions"
    path_params: [{name: LayerName, var: layer_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Content, var: content}, {name: CompatibleRuntimes, var: compatible_runtimes}, {name: LicenseInfo, var: license_info}, {name: CompatibleArchitectures, var: compatible_architectures}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    layer_name: $layer_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, content: $content, compatible_runtimes: $compatible_runtimes, license_info: $license_info, compatible_architectures: $compatible_architectures
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Lambda layers (https://docs.aws.amazon.com/lambda/latest/dg/invocation-layers.html) and shows information about the latest version of each. Specify a runtime identifier (https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) to list only layers that indicate that they're compatible with that runtime. Specify a compatible architecture to include only layers that are compatible with that instruction set architecture (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
#
# GET /2018-10-31/layers
# Returns: record<NextMarker: string, Layers: table<LayerName: string, LayerArn: string, LatestMatchingVersion: record>>
# operationId: ListLayers
export def "list-layers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compatible-runtime: string@compatible-runtime-completer # A runtime identifier. For example, go1.x.
  --marker: string # A pagination token returned by a previous call.
  --max-items: int # The maximum number of layers to return.
  --compatible-architecture: string@compatible-architecture-completer # The compatible instruction set architecture (https://docs.aws.amazon.com/lambda/latest/dg/foundation-arch.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2018-10-31/layers"
    query: [{name: CompatibleRuntime, var: compatible_runtime}, {name: Marker, var: marker}, {name: MaxItems, var: max_items}, {name: CompatibleArchitecture, var: compatible_architecture}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    compatible_runtime: $compatible_runtime, marker: $marker, max_items: $max_items, compatible_architecture: $compatible_architecture, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of provisioned concurrency configurations for a function.
#
# GET /2019-09-30/functions/{FunctionName}/provisioned-concurrency
# Returns: record<ProvisionedConcurrencyConfigs: table<FunctionArn: string, RequestedProvisionedConcurrentExecutions: int, AvailableProvisionedConcurrentExecutions: int, AllocatedProvisionedConcurrentExecutions: int, Status: string, StatusReason: string, LastModified: string>, NextMarker: string>
# operationId: ListProvisionedConcurrencyConfigs
export def "list-provisioned-concurrency-configs" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # Specify a number to limit the number of configurations returned.
  --list: string@list-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Marker, var: marker}, {name: MaxItems, var: max_items}, {name: List, var: list, required: true, default: ALL}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, marker: $marker, max_items: $max_items, list: $list, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a function's tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html). You can also view tags with GetFunction.
#
# GET /2017-03-31/tags/{ARN}
# Returns: record<Tags: record>
# operationId: ListTags
export def "list-tags" [
  arn: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2017-03-31/tags/{ARN}"
    path_params: [{name: ARN, var: arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) to a function.
#
# POST /2017-03-31/tags/{ARN}
# operationId: TagResource
export def "tag-resource" [
  arn: string
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
  tags: record # A list of tags to apply to the function.
]: any -> any {
  $in | http-request {
    method: post
    path: "/2017-03-31/tags/{ARN}"
    path_params: [{name: ARN, var: arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of versions (https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html), with the version-specific configuration of each. Lambda returns up to 50 versions per call.
#
# GET /2015-03-31/functions/{FunctionName}/versions
# Returns: record<NextMarker: string, Versions: table<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record, DeadLetterConfig: record, Environment: record, KMSKeyArn: string, TracingConfig: record, MasterArn: string, RevisionId: string, Layers: list, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: list, PackageType: string, ImageConfigResponse: record, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list, EphemeralStorage: record, SnapStart: record, RuntimeVersionConfig: record>>
# operationId: ListVersionsByFunction
export def "list-versions-by-function" [
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  --max-items: int # The maximum number of versions to return. Note that ListVersionsByFunction returns a maximum of 50 items in each response, even if you set the number higher.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-03-31/functions/{FunctionName}/versions"
    path_params: [{name: FunctionName, var: function_name}]
    query: [{name: Marker, var: marker}, {name: MaxItems, var: max_items}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, marker: $marker, max_items: $max_items, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a version (https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html) from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change. Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use UpdateFunctionCode or UpdateFunctionConfiguration to update the function before publishing a version. Clients can invoke versions directly or with an alias. To create an alias, use CreateAlias.
#
# POST /2015-03-31/functions/{FunctionName}/versions
# Returns: record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>
# operationId: PublishVersion
export def "publish-version" [
  function_name: string
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
  --code-sha256: string # Only publish a version if the hash value matches the value that's specified. Use this option to avoid publishing a version if the function code has changed since you last updated it. You can get the hash for the version that you uploaded from the output of UpdateFunctionCode.
  --description: string # A description for the version to override the description in the function configuration.
  --revision-id: string # Only update the function if the revision ID matches the ID that's specified. Use this option to avoid publishing a version if the function configuration has changed since you last updated it.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-03-31/functions/{FunctionName}/versions"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CodeSha256, var: code_sha256}, {name: Description, var: description}, {name: RevisionId, var: revision_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, code_sha256: $code_sha256, description: $description, revision_id: $revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a statement from the permissions policy for a version of an Lambda layer (https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html). For more information, see AddLayerVersionPermission.
#
# DELETE /2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}
# operationId: RemoveLayerVersionPermission
export def "remove-layer-version-permission" [
  layer_name: string
  version_number: int
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision-id: string # Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}"
    path_params: [{name: LayerName, var: layer_name}, {name: VersionNumber, var: version_number}, {name: StatementId, var: statement_id}]
    query: [{name: RevisionId, var: revision_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    layer_name: $layer_name, version_number: $version_number, statement_id: $statement_id, revision_id: $revision_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes function-use permission from an Amazon Web Service or another Amazon Web Services account. You can get the ID of the statement from the output of GetPolicy.
#
# DELETE /2015-03-31/functions/{FunctionName}/policy/{StatementId}
# operationId: RemovePermission
export def "remove-permission" [
  function_name: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qualifier: string # Specify a version or alias to remove permissions from a published version of the function.
  --revision-id: string # Update the policy only if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}"
    path_params: [{name: FunctionName, var: function_name}, {name: StatementId, var: statement_id}]
    query: [{name: Qualifier, var: qualifier}, {name: RevisionId, var: revision_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    function_name: $function_name, statement_id: $statement_id, qualifier: $qualifier, revision_id: $revision_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags (https://docs.aws.amazon.com/lambda/latest/dg/tagging.html) from a function.
#
# DELETE /2017-03-31/tags/{ARN}
# operationId: UntagResource
export def "untag-resource" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # A list of tag keys to remove from the function. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2017-03-31/tags/{ARN}"
    path_params: [{name: ARN, var: arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    arn: $arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Lambda function's code. If code signing is enabled for the function, the code package must be signed by a trusted publisher. For more information, see Configuring code signing for Lambda (https://docs.aws.amazon.com/lambda/latest/dg/configuration-codesigning.html). If the function's package type is Image, then you must specify the code package in ImageUri as the URI of a container image (https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html) in the Amazon ECR registry. If the function's package type is Zip, then you must specify the deployment package as a .zip file archive (https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html#gettingstarted-package-zip). Enter the Amazon S3 bucket and key of the code .zip file location. You can also provide the function code inline using the ZipFile field. The code in the deployment package must be compatible with the target instruction set architecture of the function (x86-64 or arm64). The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version. For a function defined as a container image, Lambda resolves the image tag to an image digest. In Amazon ECR, if you update the image tag to a new image, Lambda does not automatically update the function.
#
# PUT /2015-03-31/functions/{FunctionName}/code
# Returns: record<FunctionName: string, FunctionArn: string, Runtime: string, Role: string, Handler: string, CodeSize: int, Description: string, Timeout: int, MemorySize: int, LastModified: string, CodeSha256: string, Version: string, VpcConfig: record<SubnetIds: list<string>, SecurityGroupIds: list<string>, VpcId: string>, DeadLetterConfig: record<TargetArn: string>, Environment: record<Variables: record, Error: record<ErrorCode: string, Message: string>>, KMSKeyArn: string, TracingConfig: record<Mode: string>, MasterArn: string, RevisionId: string, Layers: table<Arn: string, CodeSize: int, SigningProfileVersionArn: string, SigningJobArn: string>, State: string, StateReason: string, StateReasonCode: string, LastUpdateStatus: string, LastUpdateStatusReason: string, LastUpdateStatusReasonCode: string, FileSystemConfigs: table<Arn: string, LocalMountPath: string>, PackageType: string, ImageConfigResponse: record<ImageConfig: record<EntryPoint: list, Command: list, WorkingDirectory: string>, Error: record<ErrorCode: string, Message: string>>, SigningProfileVersionArn: string, SigningJobArn: string, Architectures: list<string>, EphemeralStorage: record<Size: int>, SnapStart: record<ApplyOn: string, OptimizationStatus: string>, RuntimeVersionConfig: record<RuntimeVersionArn: string, Error: record<ErrorCode: string, Message: string>>>
# operationId: UpdateFunctionCode
export def "update-function-code" [
  function_name: string
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
  --zip-file: string # The base64-encoded contents of the deployment package. Amazon Web Services SDK and CLI clients handle the encoding for you. Use only with a function defined with a .zip file archive deployment package. (format: password)
  --s3-bucket: string # An Amazon S3 bucket in the same Amazon Web Services Region as your function. The bucket can be in a different Amazon Web Services account. Use only with a function defined with a .zip file archive deployment package.
  --s3-key: string # The Amazon S3 key of the deployment package. Use only with a function defined with a .zip file archive deployment package.
  --s3-object-version: string # For versioned objects, the version of the deployment package object to use.
  --image-uri: string # URI of a container image in the Amazon ECR registry. Do not use for a function defined with a .zip file archive.
  --publish: oneof<nothing, bool> # Set to true to publish a new version of the function after updating the code. This has the same effect as calling PublishVersion separately.
  --body-dry-run: oneof<nothing, bool> # Set to true to validate the request parameters and access permissions without modifying the function code. (spec name: DryRun)
  --revision-id: string # Update the function only if the revision ID matches the ID that's specified. Use this option to avoid modifying a function that has changed since you last read it.
  --architectures: list<string> # The instruction set architecture that the function supports. Enter a string array with one of the valid values (arm64 or x86_64). The default value is x86_64.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2015-03-31/functions/{FunctionName}/code"
    path_params: [{name: FunctionName, var: function_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ZipFile, var: zip_file}, {name: S3Bucket, var: s3_bucket}, {name: S3Key, var: s3_key}, {name: S3ObjectVersion, var: s3_object_version}, {name: ImageUri, var: image_uri}, {name: Publish, var: publish}, {name: DryRun, var: body_dry_run}, {name: RevisionId, var: revision_id}, {name: Architectures, var: architectures}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    function_name: $function_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, zip_file: $zip_file, s3_bucket: $s3_bucket, s3_key: $s3_key, s3_object_version: $s3_object_version, image_uri: $image_uri, publish: $publish, body_dry_run: $body_dry_run, revision_id: $revision_id, architectures: $architectures
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
