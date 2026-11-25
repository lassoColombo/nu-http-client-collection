# Auto-generated client for AWS App Runner v2020-05-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/apprunner/2020-05-15/openapi.json
# Auth: --token flag or $env.AWS_APP_RUNNER_TOKEN

const CLIENT = {
  base_url: "http://apprunner.us-east-1.amazonaws.com"
  token_env_var: "AWS_APP_RUNNER_TOKEN"
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

def base-url-completer [] { ["http://apprunner.us-east-1.amazonaws.com" "http://apprunner.us-east-2.amazonaws.com" "http://apprunner.us-west-1.amazonaws.com" "http://apprunner.us-west-2.amazonaws.com" "http://apprunner.us-gov-west-1.amazonaws.com" "http://apprunner.us-gov-east-1.amazonaws.com" "http://apprunner.ca-central-1.amazonaws.com" "http://apprunner.eu-north-1.amazonaws.com" "http://apprunner.eu-west-1.amazonaws.com" "http://apprunner.eu-west-2.amazonaws.com" "http://apprunner.eu-west-3.amazonaws.com" "http://apprunner.eu-central-1.amazonaws.com" "http://apprunner.eu-south-1.amazonaws.com" "http://apprunner.af-south-1.amazonaws.com" "http://apprunner.ap-northeast-1.amazonaws.com" "http://apprunner.ap-northeast-2.amazonaws.com" "http://apprunner.ap-northeast-3.amazonaws.com" "http://apprunner.ap-southeast-1.amazonaws.com" "http://apprunner.ap-southeast-2.amazonaws.com" "http://apprunner.ap-east-1.amazonaws.com" "http://apprunner.ap-south-1.amazonaws.com" "http://apprunner.sa-east-1.amazonaws.com" "http://apprunner.me-south-1.amazonaws.com" "https://apprunner.us-east-1.amazonaws.com" "https://apprunner.us-east-2.amazonaws.com" "https://apprunner.us-west-1.amazonaws.com" "https://apprunner.us-west-2.amazonaws.com" "https://apprunner.us-gov-west-1.amazonaws.com" "https://apprunner.us-gov-east-1.amazonaws.com" "https://apprunner.ca-central-1.amazonaws.com" "https://apprunner.eu-north-1.amazonaws.com" "https://apprunner.eu-west-1.amazonaws.com" "https://apprunner.eu-west-2.amazonaws.com" "https://apprunner.eu-west-3.amazonaws.com" "https://apprunner.eu-central-1.amazonaws.com" "https://apprunner.eu-south-1.amazonaws.com" "https://apprunner.af-south-1.amazonaws.com" "https://apprunner.ap-northeast-1.amazonaws.com" "https://apprunner.ap-northeast-2.amazonaws.com" "https://apprunner.ap-northeast-3.amazonaws.com" "https://apprunner.ap-southeast-1.amazonaws.com" "https://apprunner.ap-southeast-2.amazonaws.com" "https://apprunner.ap-east-1.amazonaws.com" "https://apprunner.ap-south-1.amazonaws.com" "https://apprunner.sa-east-1.amazonaws.com" "https://apprunner.me-south-1.amazonaws.com" "http://apprunner.cn-north-1.amazonaws.com.cn" "http://apprunner.cn-northwest-1.amazonaws.com.cn" "https://apprunner.cn-north-1.amazonaws.com.cn" "https://apprunner.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AppRunner.AssociateCustomDomain"] }
def x-amz-target-completer-1 [] { ["AppRunner.CreateAutoScalingConfiguration"] }
def provider-type-completer [] { ["GITHUB"] }
def x-amz-target-completer-2 [] { ["AppRunner.CreateConnection"] }
def x-amz-target-completer-3 [] { ["AppRunner.CreateObservabilityConfiguration"] }
def x-amz-target-completer-4 [] { ["AppRunner.CreateService"] }
def x-amz-target-completer-5 [] { ["AppRunner.CreateVpcConnector"] }
def x-amz-target-completer-6 [] { ["AppRunner.CreateVpcIngressConnection"] }
def x-amz-target-completer-7 [] { ["AppRunner.DeleteAutoScalingConfiguration"] }
def x-amz-target-completer-8 [] { ["AppRunner.DeleteConnection"] }
def x-amz-target-completer-9 [] { ["AppRunner.DeleteObservabilityConfiguration"] }
def x-amz-target-completer-10 [] { ["AppRunner.DeleteService"] }
def x-amz-target-completer-11 [] { ["AppRunner.DeleteVpcConnector"] }
def x-amz-target-completer-12 [] { ["AppRunner.DeleteVpcIngressConnection"] }
def x-amz-target-completer-13 [] { ["AppRunner.DescribeAutoScalingConfiguration"] }
def x-amz-target-completer-14 [] { ["AppRunner.DescribeCustomDomains"] }
def x-amz-target-completer-15 [] { ["AppRunner.DescribeObservabilityConfiguration"] }
def x-amz-target-completer-16 [] { ["AppRunner.DescribeService"] }
def x-amz-target-completer-17 [] { ["AppRunner.DescribeVpcConnector"] }
def x-amz-target-completer-18 [] { ["AppRunner.DescribeVpcIngressConnection"] }
def x-amz-target-completer-19 [] { ["AppRunner.DisassociateCustomDomain"] }
def x-amz-target-completer-20 [] { ["AppRunner.ListAutoScalingConfigurations"] }
def x-amz-target-completer-21 [] { ["AppRunner.ListConnections"] }
def x-amz-target-completer-22 [] { ["AppRunner.ListObservabilityConfigurations"] }
def x-amz-target-completer-23 [] { ["AppRunner.ListOperations"] }
def x-amz-target-completer-24 [] { ["AppRunner.ListServices"] }
def x-amz-target-completer-25 [] { ["AppRunner.ListTagsForResource"] }
def x-amz-target-completer-26 [] { ["AppRunner.ListVpcConnectors"] }
def x-amz-target-completer-27 [] { ["AppRunner.ListVpcIngressConnections"] }
def x-amz-target-completer-28 [] { ["AppRunner.PauseService"] }
def x-amz-target-completer-29 [] { ["AppRunner.ResumeService"] }
def x-amz-target-completer-30 [] { ["AppRunner.StartDeployment"] }
def x-amz-target-completer-31 [] { ["AppRunner.TagResource"] }
def x-amz-target-completer-32 [] { ["AppRunner.UntagResource"] }
def x-amz-target-completer-33 [] { ["AppRunner.UpdateService"] }
def x-amz-target-completer-34 [] { ["AppRunner.UpdateVpcIngressConnection"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-custom-domain: "record<DNSTarget: string, ServiceArn: string, CustomDomain: record<DomainName: string, EnableWWWSubdomain: bool, CertificateValidationRecords: list<record>, Status: string>, VpcDNSTargets: table<VpcIngressConnectionArn: string, VpcId: string, DomainName: string>>"
    create-auto-scaling-configuration: "record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int, Latest: bool, Status: string, MaxConcurrency: int, MinSize: int, MaxSize: int, CreatedAt: string, DeletedAt: string>>"
    create-connection: "record<Connection: record<ConnectionName: string, ConnectionArn: string, ProviderType: string, Status: string, CreatedAt: string>>"
    create-observability-configuration: "record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, TraceConfiguration: record<Vendor: string>, ObservabilityConfigurationRevision: int, Latest: bool, Status: string, CreatedAt: string, DeletedAt: string>>"
    create-service: "record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>"
    create-vpc-connector: "record<VpcConnector: record<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list<string>, SecurityGroups: list<string>, Status: string, CreatedAt: string, DeletedAt: string>>"
    create-vpc-ingress-connection: "record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>"
    delete-auto-scaling-configuration: "record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int, Latest: bool, Status: string, MaxConcurrency: int, MinSize: int, MaxSize: int, CreatedAt: string, DeletedAt: string>>"
    delete-connection: "record<Connection: record<ConnectionName: string, ConnectionArn: string, ProviderType: string, Status: string, CreatedAt: string>>"
    delete-observability-configuration: "record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, TraceConfiguration: record<Vendor: string>, ObservabilityConfigurationRevision: int, Latest: bool, Status: string, CreatedAt: string, DeletedAt: string>>"
    delete-service: "record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>"
    delete-vpc-connector: "record<VpcConnector: record<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list<string>, SecurityGroups: list<string>, Status: string, CreatedAt: string, DeletedAt: string>>"
    delete-vpc-ingress-connection: "record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>"
    describe-auto-scaling-configuration: "record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int, Latest: bool, Status: string, MaxConcurrency: int, MinSize: int, MaxSize: int, CreatedAt: string, DeletedAt: string>>"
    describe-custom-domains: "record<DNSTarget: string, ServiceArn: string, CustomDomains: table<DomainName: string, EnableWWWSubdomain: bool, CertificateValidationRecords: list, Status: string>, VpcDNSTargets: table<VpcIngressConnectionArn: string, VpcId: string, DomainName: string>, NextToken: string>"
    describe-observability-configuration: "record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, TraceConfiguration: record<Vendor: string>, ObservabilityConfigurationRevision: int, Latest: bool, Status: string, CreatedAt: string, DeletedAt: string>>"
    describe-service: "record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>>"
    describe-vpc-connector: "record<VpcConnector: record<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list<string>, SecurityGroups: list<string>, Status: string, CreatedAt: string, DeletedAt: string>>"
    describe-vpc-ingress-connection: "record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>"
    disassociate-custom-domain: "record<DNSTarget: string, ServiceArn: string, CustomDomain: record<DomainName: string, EnableWWWSubdomain: bool, CertificateValidationRecords: list<record>, Status: string>, VpcDNSTargets: table<VpcIngressConnectionArn: string, VpcId: string, DomainName: string>>"
    list-auto-scaling-configurations: "record<AutoScalingConfigurationSummaryList: table<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NextToken: string>"
    list-connections: "record<ConnectionSummaryList: table<ConnectionName: string, ConnectionArn: string, ProviderType: string, Status: string, CreatedAt: string>, NextToken: string>"
    list-observability-configurations: "record<ObservabilityConfigurationSummaryList: table<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, ObservabilityConfigurationRevision: int>, NextToken: string>"
    list-operations: "record<OperationSummaryList: table<Id: string, Type: string, Status: string, TargetArn: string, StartedAt: string, EndedAt: string, UpdatedAt: string>, NextToken: string>"
    list-services: "record<ServiceSummaryList: table<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, Status: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    list-vpc-connectors: "record<VpcConnectors: table<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list, SecurityGroups: list, Status: string, CreatedAt: string, DeletedAt: string>, NextToken: string>"
    list-vpc-ingress-connections: "record<VpcIngressConnectionSummaryList: table<VpcIngressConnectionArn: string, ServiceArn: string>, NextToken: string>"
    pause-service: "record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>"
    resume-service: "record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>"
    start-deployment: "record<OperationId: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-service: "record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>"
    update-vpc-ingress-connection: "record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-custom-domain" "create-auto-scaling-configuration" "create-connection" "create-observability-configuration" "create-service" "create-vpc-connector" "create-vpc-ingress-connection" "delete-auto-scaling-configuration" "delete-connection" "delete-observability-configuration" "delete-service" "delete-vpc-connector" "delete-vpc-ingress-connection" "describe-auto-scaling-configuration" "describe-custom-domains" "describe-observability-configuration" "describe-service" "describe-vpc-connector" "describe-vpc-ingress-connection" "disassociate-custom-domain" "list-auto-scaling-configurations" "list-connections" "list-observability-configurations" "list-operations" "list-services" "list-tags-for-resource" "list-vpc-connectors" "list-vpc-ingress-connections" "pause-service" "resume-service" "start-deployment" "tag-resource" "untag-resource" "update-service" "update-vpc-ingress-connection" "commands"] | sort) } | get name | first)
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

# Associate your own domain name with the App Runner subdomain URL of your App Runner service. After you call AssociateCustomDomain and receive a successful response, use the information in the CustomDomain record that's returned to add CNAME records to your Domain Name System (DNS). For each mapped domain name, add a mapping to the target App Runner subdomain and one or more certificate validation records. App Runner then performs DNS validation to verify that you own or control the domain name that you associated. App Runner tracks domain validity in a certificate stored in AWS Certificate Manager (ACM) (https://docs.aws.amazon.com/acm/latest/userguide).
#
# POST /
# Returns: record<DNSTarget: string, ServiceArn: string, CustomDomain: record<DomainName: string, EnableWWWSubdomain: bool, CertificateValidationRecords: list<record>, Status: string>, VpcDNSTargets: table<VpcIngressConnectionArn: string, VpcId: string, DomainName: string>>
# operationId: AssociateCustomDomain
export def "associate-custom-domain" [
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
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want to associate a custom domain name with.
  domain_name: string # A custom domain endpoint to associate. Specify a root domain (for example, example.com), a subdomain (for example, login.example.com or admin.login.example.com), or a wildcard (for example, *.example.com).
  --enable-www-subdomain: oneof<nothing, bool> # Set to true to associate the subdomain www.DomainName with the App Runner service in addition to the base domain. Default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.AssociateCustomDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}, {name: DomainName, var: domain_name}, {name: EnableWWWSubdomain, var: enable_www_subdomain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn, domain_name: $domain_name, enable_www_subdomain: $enable_www_subdomain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an App Runner automatic scaling configuration resource. App Runner requires this resource when you create or update App Runner services and you require non-default auto scaling settings. You can share an auto scaling configuration across multiple services. Create multiple revisions of a configuration by calling this action multiple times using the same AutoScalingConfigurationName. The call returns incremental AutoScalingConfigurationRevision values. When you create a service and configure an auto scaling configuration resource, the service uses the latest active revision of the auto scaling configuration by default. You can optionally configure the service to use a specific revision. Configure a higher MinSize to increase the spread of your App Runner service over more Availability Zones in the Amazon Web Services Region. The tradeoff is a higher minimal cost. Configure a lower MaxSize to control your cost. The tradeoff is lower responsiveness during peak demand.
#
# POST /
# Returns: record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int, Latest: bool, Status: string, MaxConcurrency: int, MinSize: int, MaxSize: int, CreatedAt: string, DeletedAt: string>>
# operationId: CreateAutoScalingConfiguration
export def "create-auto-scaling-configuration" [
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
  auto_scaling_configuration_name: string # A name for the auto scaling configuration. When you use it for the first time in an Amazon Web Services Region, App Runner creates revision number 1 of this name. When you use the same name in subsequent calls, App Runner creates incremental revisions of the configuration. The name DefaultConfiguration is reserved (it's the configuration that App Runner uses if you don't provide a custome one). You can't use it to create a new auto scaling configuration, and you can't create a revision of it. When you want to use your own auto scaling configuration for your App Runner service, create a configuration with a different name, and then provide it when you create or update your service.
  --max-concurrency: int # The maximum number of concurrent requests that you want an instance to process. If the number of concurrent requests exceeds this limit, App Runner scales up your service. Default: 100
  --min-size: int # The minimum number of instances that App Runner provisions for your service. The service always has at least MinSize provisioned instances. Some of them actively serve traffic. The rest of them (provisioned and inactive instances) are a cost-effective compute capacity reserve and are ready to be quickly activated. You pay for memory usage of all the provisioned instances. You pay for CPU usage of only the active subset. App Runner temporarily doubles the number of provisioned instances during deployments, to maintain the same capacity for both old and new code. Default: 1
  --max-size: int # The maximum number of instances that your service scales up to. At most MaxSize instances actively serve traffic for your service. Default: 25
  --tags: list # A list of metadata items that you can associate with your auto scaling configuration resource. A tag is a key-value pair. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.CreateAutoScalingConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutoScalingConfigurationName, var: auto_scaling_configuration_name}, {name: MaxConcurrency, var: max_concurrency}, {name: MinSize, var: min_size}, {name: MaxSize, var: max_size}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, auto_scaling_configuration_name: $auto_scaling_configuration_name, max_concurrency: $max_concurrency, min_size: $min_size, max_size: $max_size, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an App Runner connection resource. App Runner requires a connection resource when you create App Runner services that access private repositories from certain third-party providers. You can share a connection across multiple services. A connection resource is needed to access GitHub repositories. GitHub requires a user interface approval process through the App Runner console before you can use the connection.
#
# POST /
# Returns: record<Connection: record<ConnectionName: string, ConnectionArn: string, ProviderType: string, Status: string, CreatedAt: string>>
# operationId: CreateConnection
export def "create-connection" [
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
  connection_name: string # A name for the new connection. It must be unique across all App Runner connections for the Amazon Web Services account in the Amazon Web Services Region.
  provider_type: string@provider-type-completer # The source repository provider.
  --tags: list # A list of metadata items that you can associate with your connection resource. A tag is a key-value pair. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.CreateConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConnectionName, var: connection_name}, {name: ProviderType, var: provider_type}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_name: $connection_name, provider_type: $provider_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an App Runner observability configuration resource. App Runner requires this resource when you create or update App Runner services and you want to enable non-default observability features. You can share an observability configuration across multiple services. Create multiple revisions of a configuration by calling this action multiple times using the same ObservabilityConfigurationName. The call returns incremental ObservabilityConfigurationRevision values. When you create a service and configure an observability configuration resource, the service uses the latest active revision of the observability configuration by default. You can optionally configure the service to use a specific revision. The observability configuration resource is designed to configure multiple features (currently one feature, tracing). This action takes optional parameters that describe the configuration of these features (currently one parameter, TraceConfiguration). If you don't specify a feature parameter, App Runner doesn't enable the feature.
#
# POST /
# Returns: record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, TraceConfiguration: record<Vendor: string>, ObservabilityConfigurationRevision: int, Latest: bool, Status: string, CreatedAt: string, DeletedAt: string>>
# operationId: CreateObservabilityConfiguration
export def "create-observability-configuration" [
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
  observability_configuration_name: string # A name for the observability configuration. When you use it for the first time in an Amazon Web Services Region, App Runner creates revision number 1 of this name. When you use the same name in subsequent calls, App Runner creates incremental revisions of the configuration. The name DefaultConfiguration is reserved. You can't use it to create a new observability configuration, and you can't create a revision of it. When you want to use your own observability configuration for your App Runner service, create a configuration with a different name, and then provide it when you create or update your service.
  --trace-configuration: record # Describes the configuration of the tracing feature within an App Runner observability configuration. — shape: {Vendor: "AWSXRAY"}
  --tags: list # A list of metadata items that you can associate with your observability configuration resource. A tag is a key-value pair. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.CreateObservabilityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObservabilityConfigurationName, var: observability_configuration_name}, {name: TraceConfiguration, var: trace_configuration}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, observability_configuration_name: $observability_configuration_name, trace_configuration: $trace_configuration, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an App Runner service. After the service is created, the action also automatically starts a deployment. This is an asynchronous operation. On a successful call, you can use the returned OperationId and the ListOperations (https://docs.aws.amazon.com/apprunner/latest/api/API_ListOperations.html) call to track the operation's progress.
#
# POST /
# Returns: record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>
# operationId: CreateService
export def "create-service" [
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
  service_name: string # A name for the App Runner service. It must be unique across all the running App Runner services in your Amazon Web Services account in the Amazon Web Services Region.
  source_configuration: record # Describes the source deployed to an App Runner service. It can be a code or an image repository. — shape: {CodeRepository?: record, ImageRepository?: record, AutoDeploymentsEnabled?: bool, AuthenticationConfiguration?: record}
  --instance-configuration: record # Describes the runtime configuration of an App Runner service instance (scaling unit). — shape: {Cpu?: string, Memory?: string, InstanceRoleArn?: string}
  --tags: list # An optional list of metadata items that you can associate with the App Runner service resource. A tag is a key-value pair. — item shape: {Key?: string, Value?: string}
  --encryption-configuration: record # Describes a custom encryption key that App Runner uses to encrypt copies of the source repository and service logs. — shape: {KmsKey: string}
  --health-check-configuration: record # Describes the settings for the health check that App Runner performs to monitor the health of a service. — shape: {Protocol?: "TCP"|"HTTP", Path?: string, Interval?: int, Timeout?: int, HealthyThreshold?: int, UnhealthyThreshold?: int}
  --auto-scaling-configuration-arn: string # The Amazon Resource Name (ARN) of an App Runner automatic scaling configuration resource that you want to associate with your service. If not provided, App Runner associates the latest revision of a default auto scaling configuration. Specify an ARN with a name and a revision number to associate that revision. For example: arn:aws:apprunner:us-east-1:123456789012:autoscalingconfiguration/high-availability/3 Specify just the name to associate the latest revision. For example: arn:aws:apprunner:us-east-1:123456789012:autoscalingconfiguration/high-availability
  --network-configuration: record # Describes configuration settings related to network traffic of an App Runner service. Consists of embedded objects for each configurable network feature. — shape: {EgressConfiguration?: record, IngressConfiguration?: record}
  --observability-configuration: record # Describes the observability configuration of an App Runner service. These are additional observability features, like tracing, that you choose to enable. They're configured in a separate resource that you associate with your service. — shape: {ObservabilityEnabled: bool, ObservabilityConfigurationArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.CreateService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceName, var: service_name}, {name: SourceConfiguration, var: source_configuration}, {name: InstanceConfiguration, var: instance_configuration}, {name: Tags, var: tags}, {name: EncryptionConfiguration, var: encryption_configuration}, {name: HealthCheckConfiguration, var: health_check_configuration}, {name: AutoScalingConfigurationArn, var: auto_scaling_configuration_arn}, {name: NetworkConfiguration, var: network_configuration}, {name: ObservabilityConfiguration, var: observability_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, source_configuration: $source_configuration, instance_configuration: $instance_configuration, tags: $tags, encryption_configuration: $encryption_configuration, health_check_configuration: $health_check_configuration, auto_scaling_configuration_arn: $auto_scaling_configuration_arn, network_configuration: $network_configuration, observability_configuration: $observability_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an App Runner VPC connector resource. App Runner requires this resource when you want to associate your App Runner service to a custom Amazon Virtual Private Cloud (Amazon VPC).
#
# POST /
# Returns: record<VpcConnector: record<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list<string>, SecurityGroups: list<string>, Status: string, CreatedAt: string, DeletedAt: string>>
# operationId: CreateVpcConnector
export def "create-vpc-connector" [
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
  vpc_connector_name: string # A name for the VPC connector.
  subnets: list<string> # A list of IDs of subnets that App Runner should use when it associates your service with a custom Amazon VPC. Specify IDs of subnets of a single Amazon VPC. App Runner determines the Amazon VPC from the subnets you specify. App Runner currently only provides support for IPv4.
  --security-groups: list<string> # A list of IDs of security groups that App Runner should use for access to Amazon Web Services resources under the specified subnets. If not specified, App Runner uses the default security group of the Amazon VPC. The default security group allows all outbound traffic.
  --tags: list # A list of metadata items that you can associate with your VPC connector resource. A tag is a key-value pair. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.CreateVpcConnector"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcConnectorName, var: vpc_connector_name}, {name: Subnets, var: subnets}, {name: SecurityGroups, var: security_groups}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpc_connector_name: $vpc_connector_name, subnets: $subnets, security_groups: $security_groups, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an App Runner VPC Ingress Connection resource. App Runner requires this resource when you want to associate your App Runner service with an Amazon VPC endpoint.
#
# POST /
# Returns: record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>
# operationId: CreateVpcIngressConnection
export def "create-vpc-ingress-connection" [
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
  service_arn: string # The Amazon Resource Name (ARN) for this App Runner service that is used to create the VPC Ingress Connection resource.
  vpc_ingress_connection_name: string # A name for the VPC Ingress Connection resource. It must be unique across all the active VPC Ingress Connections in your Amazon Web Services account in the Amazon Web Services Region.
  ingress_vpc_configuration: record # The configuration of your VPC and the associated VPC endpoint. The VPC endpoint is an Amazon Web Services PrivateLink resource that allows access to your App Runner services from within an Amazon VPC. — shape: {VpcId?: string, VpcEndpointId?: string}
  --tags: list # An optional list of metadata items that you can associate with the VPC Ingress Connection resource. A tag is a key-value pair. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.CreateVpcIngressConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}, {name: VpcIngressConnectionName, var: vpc_ingress_connection_name}, {name: IngressVpcConfiguration, var: ingress_vpc_configuration}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn, vpc_ingress_connection_name: $vpc_ingress_connection_name, ingress_vpc_configuration: $ingress_vpc_configuration, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an App Runner automatic scaling configuration resource. You can delete a specific revision or the latest active revision. You can't delete a configuration that's used by one or more App Runner services.
#
# POST /
# Returns: record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int, Latest: bool, Status: string, MaxConcurrency: int, MinSize: int, MaxSize: int, CreatedAt: string, DeletedAt: string>>
# operationId: DeleteAutoScalingConfiguration
export def "delete-auto-scaling-configuration" [
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
  auto_scaling_configuration_arn: string # The Amazon Resource Name (ARN) of the App Runner auto scaling configuration that you want to delete. The ARN can be a full auto scaling configuration ARN, or a partial ARN ending with either .../name or .../name/revision . If a revision isn't specified, the latest active revision is deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DeleteAutoScalingConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutoScalingConfigurationArn, var: auto_scaling_configuration_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, auto_scaling_configuration_arn: $auto_scaling_configuration_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an App Runner connection. You must first ensure that there are no running App Runner services that use this connection. If there are any, the DeleteConnection action fails.
#
# POST /
# Returns: record<Connection: record<ConnectionName: string, ConnectionArn: string, ProviderType: string, Status: string, CreatedAt: string>>
# operationId: DeleteConnection
export def "delete-connection" [
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
  connection_arn: string # The Amazon Resource Name (ARN) of the App Runner connection that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DeleteConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConnectionArn, var: connection_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_arn: $connection_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an App Runner observability configuration resource. You can delete a specific revision or the latest active revision. You can't delete a configuration that's used by one or more App Runner services.
#
# POST /
# Returns: record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, TraceConfiguration: record<Vendor: string>, ObservabilityConfigurationRevision: int, Latest: bool, Status: string, CreatedAt: string, DeletedAt: string>>
# operationId: DeleteObservabilityConfiguration
export def "delete-observability-configuration" [
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
  observability_configuration_arn: string # The Amazon Resource Name (ARN) of the App Runner observability configuration that you want to delete. The ARN can be a full observability configuration ARN, or a partial ARN ending with either .../name or .../name/revision . If a revision isn't specified, the latest active revision is deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DeleteObservabilityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObservabilityConfigurationArn, var: observability_configuration_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, observability_configuration_arn: $observability_configuration_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an App Runner service. This is an asynchronous operation. On a successful call, you can use the returned OperationId and the ListOperations call to track the operation's progress. Make sure that you don't have any active VPCIngressConnections associated with the service you want to delete.
#
# POST /
# Returns: record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>
# operationId: DeleteService
export def "delete-service" [
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
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DeleteService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an App Runner VPC connector resource. You can't delete a connector that's used by one or more App Runner services.
#
# POST /
# Returns: record<VpcConnector: record<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list<string>, SecurityGroups: list<string>, Status: string, CreatedAt: string, DeletedAt: string>>
# operationId: DeleteVpcConnector
export def "delete-vpc-connector" [
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
  vpc_connector_arn: string # The Amazon Resource Name (ARN) of the App Runner VPC connector that you want to delete. The ARN must be a full VPC connector ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DeleteVpcConnector"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcConnectorArn, var: vpc_connector_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpc_connector_arn: $vpc_connector_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an App Runner VPC Ingress Connection resource that's associated with an App Runner service. The VPC Ingress Connection must be in one of the following states to be deleted: AVAILABLE FAILED_CREATION FAILED_UPDATE FAILED_DELETION
#
# POST /
# Returns: record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>
# operationId: DeleteVpcIngressConnection
export def "delete-vpc-ingress-connection" [
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
  vpc_ingress_connection_arn: string # The Amazon Resource Name (ARN) of the App Runner VPC Ingress Connection that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DeleteVpcIngressConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcIngressConnectionArn, var: vpc_ingress_connection_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpc_ingress_connection_arn: $vpc_ingress_connection_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a full description of an App Runner automatic scaling configuration resource.
#
# POST /
# Returns: record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int, Latest: bool, Status: string, MaxConcurrency: int, MinSize: int, MaxSize: int, CreatedAt: string, DeletedAt: string>>
# operationId: DescribeAutoScalingConfiguration
export def "describe-auto-scaling-configuration" [
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
  auto_scaling_configuration_arn: string # The Amazon Resource Name (ARN) of the App Runner auto scaling configuration that you want a description for. The ARN can be a full auto scaling configuration ARN, or a partial ARN ending with either .../name or .../name/revision . If a revision isn't specified, the latest active revision is described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DescribeAutoScalingConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutoScalingConfigurationArn, var: auto_scaling_configuration_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, auto_scaling_configuration_arn: $auto_scaling_configuration_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a description of custom domain names that are associated with an App Runner service.
#
# POST /
# Returns: record<DNSTarget: string, ServiceArn: string, CustomDomains: table<DomainName: string, EnableWWWSubdomain: bool, CertificateValidationRecords: list, Status: string>, VpcDNSTargets: table<VpcIngressConnectionArn: string, VpcId: string, DomainName: string>, NextToken: string>
# operationId: DescribeCustomDomains
export def "describe-custom-domains" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want associated custom domain names to be described for.
  --body-next-token: string # A token from a previous result page. It's used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones that are specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
  --body-max-results: int # The maximum number of results that each response (result page) can include. It's used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DescribeCustomDomains"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a full description of an App Runner observability configuration resource.
#
# POST /
# Returns: record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, TraceConfiguration: record<Vendor: string>, ObservabilityConfigurationRevision: int, Latest: bool, Status: string, CreatedAt: string, DeletedAt: string>>
# operationId: DescribeObservabilityConfiguration
export def "describe-observability-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  observability_configuration_arn: string # The Amazon Resource Name (ARN) of the App Runner observability configuration that you want a description for. The ARN can be a full observability configuration ARN, or a partial ARN ending with either .../name or .../name/revision . If a revision isn't specified, the latest active revision is described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DescribeObservabilityConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObservabilityConfigurationArn, var: observability_configuration_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, observability_configuration_arn: $observability_configuration_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a full description of an App Runner service.
#
# POST /
# Returns: record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>>
# operationId: DescribeService
export def "describe-service" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want a description for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DescribeService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a description of an App Runner VPC connector resource.
#
# POST /
# Returns: record<VpcConnector: record<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list<string>, SecurityGroups: list<string>, Status: string, CreatedAt: string, DeletedAt: string>>
# operationId: DescribeVpcConnector
export def "describe-vpc-connector" [
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
  vpc_connector_arn: string # The Amazon Resource Name (ARN) of the App Runner VPC connector that you want a description for. The ARN must be a full VPC connector ARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DescribeVpcConnector"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcConnectorArn, var: vpc_connector_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpc_connector_arn: $vpc_connector_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a full description of an App Runner VPC Ingress Connection resource.
#
# POST /
# Returns: record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>
# operationId: DescribeVpcIngressConnection
export def "describe-vpc-ingress-connection" [
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
  vpc_ingress_connection_arn: string # The Amazon Resource Name (ARN) of the App Runner VPC Ingress Connection that you want a description for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DescribeVpcIngressConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcIngressConnectionArn, var: vpc_ingress_connection_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpc_ingress_connection_arn: $vpc_ingress_connection_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociate a custom domain name from an App Runner service. Certificates tracking domain validity are associated with a custom domain and are stored in AWS Certificate Manager (ACM) (https://docs.aws.amazon.com/acm/latest/userguide). These certificates aren't deleted as part of this action. App Runner delays certificate deletion for 30 days after a domain is disassociated from your service.
#
# POST /
# Returns: record<DNSTarget: string, ServiceArn: string, CustomDomain: record<DomainName: string, EnableWWWSubdomain: bool, CertificateValidationRecords: list<record>, Status: string>, VpcDNSTargets: table<VpcIngressConnectionArn: string, VpcId: string, DomainName: string>>
# operationId: DisassociateCustomDomain
export def "disassociate-custom-domain" [
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
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want to disassociate a custom domain name from.
  domain_name: string # The domain name that you want to disassociate from the App Runner service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.DisassociateCustomDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}, {name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of active App Runner automatic scaling configurations in your Amazon Web Services account. You can query the revisions for a specific configuration name or the revisions for all active configurations in your account. You can optionally query only the latest revision of each requested name. To retrieve a full description of a particular configuration revision, call and provide one of the ARNs returned by ListAutoScalingConfigurations.
#
# POST /
# Returns: record<AutoScalingConfigurationSummaryList: table<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NextToken: string>
# operationId: ListAutoScalingConfigurations
export def "list-auto-scaling-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  --auto-scaling-configuration-name: string # The name of the App Runner auto scaling configuration that you want to list. If specified, App Runner lists revisions that share this name. If not specified, App Runner returns revisions of all active configurations.
  --latest-only: oneof<nothing, bool> # Set to true to list only the latest revision for each requested configuration name. Set to false to list all revisions for each requested configuration name. Default: true
  --body-max-results: int # The maximum number of results to include in each response (result page). It's used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
  --body-next-token: string # A token from a previous result page. It's used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones that are specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListAutoScalingConfigurations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutoScalingConfigurationName, var: auto_scaling_configuration_name}, {name: LatestOnly, var: latest_only}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, auto_scaling_configuration_name: $auto_scaling_configuration_name, latest_only: $latest_only, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of App Runner connections that are associated with your Amazon Web Services account.
#
# POST /
# Returns: record<ConnectionSummaryList: table<ConnectionName: string, ConnectionArn: string, ProviderType: string, Status: string, CreatedAt: string>, NextToken: string>
# operationId: ListConnections
export def "list-connections" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  --connection-name: string # If specified, only this connection is returned. If not specified, the result isn't filtered by name.
  --body-max-results: int # The maximum number of results to include in each response (result page). Used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
  --body-next-token: string # A token from a previous result page. Used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListConnections"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConnectionName, var: connection_name}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_name: $connection_name, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of active App Runner observability configurations in your Amazon Web Services account. You can query the revisions for a specific configuration name or the revisions for all active configurations in your account. You can optionally query only the latest revision of each requested name. To retrieve a full description of a particular configuration revision, call and provide one of the ARNs returned by ListObservabilityConfigurations.
#
# POST /
# Returns: record<ObservabilityConfigurationSummaryList: table<ObservabilityConfigurationArn: string, ObservabilityConfigurationName: string, ObservabilityConfigurationRevision: int>, NextToken: string>
# operationId: ListObservabilityConfigurations
export def "list-observability-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  --observability-configuration-name: string # The name of the App Runner observability configuration that you want to list. If specified, App Runner lists revisions that share this name. If not specified, App Runner returns revisions of all active configurations.
  --latest-only: oneof<nothing, bool> # Set to true to list only the latest revision for each requested configuration name. Set to false to list all revisions for each requested configuration name. Default: true
  --body-max-results: int # The maximum number of results to include in each response (result page). It's used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
  --body-next-token: string # A token from a previous result page. It's used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones that are specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListObservabilityConfigurations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObservabilityConfigurationName, var: observability_configuration_name}, {name: LatestOnly, var: latest_only}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, observability_configuration_name: $observability_configuration_name, latest_only: $latest_only, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of operations that occurred on an App Runner service. The resulting list of OperationSummary objects is sorted in reverse chronological order. The first object on the list represents the last started operation.
#
# POST /
# Returns: record<OperationSummaryList: table<Id: string, Type: string, Status: string, TargetArn: string, StartedAt: string, EndedAt: string, UpdatedAt: string>, NextToken: string>
# operationId: ListOperations
export def "list-operations" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want a list of operations for.
  --body-next-token: string # A token from a previous result page. It's used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to include in each response (result page). It's used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListOperations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of running App Runner services in your Amazon Web Services account.
#
# POST /
# Returns: record<ServiceSummaryList: table<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, Status: string>, NextToken: string>
# operationId: ListServices
export def "list-services" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  --body-next-token: string # A token from a previous result page. Used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to include in each response (result page). It's used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListServices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tags that are associated with for an App Runner resource. The response contains a list of tag key-value pairs.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource that a tag list is requested for. It must be the ARN of an App Runner resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of App Runner VPC connectors in your Amazon Web Services account.
#
# POST /
# Returns: record<VpcConnectors: table<VpcConnectorName: string, VpcConnectorArn: string, VpcConnectorRevision: int, Subnets: list, SecurityGroups: list, Status: string, CreatedAt: string, DeletedAt: string>, NextToken: string>
# operationId: ListVpcConnectors
export def "list-vpc-connectors" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  --body-max-results: int # The maximum number of results to include in each response (result page). It's used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
  --body-next-token: string # A token from a previous result page. It's used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones that are specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListVpcConnectors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of App Runner VPC Ingress Connections in your Amazon Web Services account.
#
# POST /
# Returns: record<VpcIngressConnectionSummaryList: table<VpcIngressConnectionArn: string, ServiceArn: string>, NextToken: string>
# operationId: ListVpcIngressConnections
export def "list-vpc-ingress-connections" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  --filter: record # Returns a list of VPC Ingress Connections based on the filter provided. It can return either ServiceArn or VpcEndpointId, or both. — shape: {ServiceArn?: string, VpcEndpointId?: string}
  --body-max-results: int # The maximum number of results to include in each response (result page). It's used for a paginated request. If you don't specify MaxResults, the request retrieves all available results in a single response. (spec name: MaxResults)
  --body-next-token: string # A token from a previous result page. It's used for a paginated request. The request retrieves the next result page. All other parameter values must be identical to the ones that are specified in the initial request. If you don't specify NextToken, the request retrieves the first result page. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ListVpcIngressConnections"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause an active App Runner service. App Runner reduces compute capacity for the service to zero and loses state (for example, ephemeral storage is removed). This is an asynchronous operation. On a successful call, you can use the returned OperationId and the ListOperations call to track the operation's progress.
#
# POST /
# Returns: record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>
# operationId: PauseService
export def "pause-service" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want to pause.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.PauseService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resume an active App Runner service. App Runner provisions compute capacity for the service. This is an asynchronous operation. On a successful call, you can use the returned OperationId and the ListOperations call to track the operation's progress.
#
# POST /
# Returns: record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>
# operationId: ResumeService
export def "resume-service" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want to resume.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.ResumeService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate a manual deployment of the latest commit in a source code repository or the latest image in a source image repository to an App Runner service. For a source code repository, App Runner retrieves the commit and builds a Docker image. For a source image repository, App Runner retrieves the latest Docker image. In both cases, App Runner then deploys the new image to your service and starts a new container instance. This is an asynchronous operation. On a successful call, you can use the returned OperationId and the ListOperations call to track the operation's progress.
#
# POST /
# Returns: record<OperationId: string>
# operationId: StartDeployment
export def "start-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want to manually deploy to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.StartDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add tags to, or update the tag values of, an App Runner resource. A tag is a key-value pair.
#
# POST /
# Returns: record
# operationId: TagResource
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource that you want to update tags for. It must be the ARN of an App Runner resource.
  tags: list # A list of tag key-value pairs to add or update. If a key is new to the resource, the tag is added with the provided value. If a key is already associated with the resource, the value of the tag is updated. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove tags from an App Runner resource.
#
# POST /
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource that you want to remove tags from. It must be the ARN of an App Runner resource.
  tag_keys: list<string> # A list of tag keys that you want to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an App Runner service. You can update the source configuration and instance configuration of the service. You can also update the ARN of the auto scaling configuration resource that's associated with the service. However, you can't change the name or the encryption configuration of the service. These can be set only when you create the service. To update the tags applied to your service, use the separate actions TagResource and UntagResource. This is an asynchronous operation. On a successful call, you can use the returned OperationId and the ListOperations call to track the operation's progress.
#
# POST /
# Returns: record<Service: record<ServiceName: string, ServiceId: string, ServiceArn: string, ServiceUrl: string, CreatedAt: string, UpdatedAt: string, DeletedAt: string, Status: string, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: bool, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: string, Memory: string, InstanceRoleArn: string>, EncryptionConfiguration: record<KmsKey: string>, HealthCheckConfiguration: record<Protocol: string, Path: string, Interval: int, Timeout: int, HealthyThreshold: int, UnhealthyThreshold: int>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: string, AutoScalingConfigurationName: string, AutoScalingConfigurationRevision: int>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: bool, ObservabilityConfigurationArn: string>>, OperationId: string>
# operationId: UpdateService
export def "update-service" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  service_arn: string # The Amazon Resource Name (ARN) of the App Runner service that you want to update.
  --source-configuration: record # Describes the source deployed to an App Runner service. It can be a code or an image repository. — shape: {CodeRepository?: record, ImageRepository?: record, AutoDeploymentsEnabled?: bool, AuthenticationConfiguration?: record}
  --instance-configuration: record # Describes the runtime configuration of an App Runner service instance (scaling unit). — shape: {Cpu?: string, Memory?: string, InstanceRoleArn?: string}
  --auto-scaling-configuration-arn: string # The Amazon Resource Name (ARN) of an App Runner automatic scaling configuration resource that you want to associate with the App Runner service.
  --health-check-configuration: record # Describes the settings for the health check that App Runner performs to monitor the health of a service. — shape: {Protocol?: "TCP"|"HTTP", Path?: string, Interval?: int, Timeout?: int, HealthyThreshold?: int, UnhealthyThreshold?: int}
  --network-configuration: record # Describes configuration settings related to network traffic of an App Runner service. Consists of embedded objects for each configurable network feature. — shape: {EgressConfiguration?: record, IngressConfiguration?: record}
  --observability-configuration: record # Describes the observability configuration of an App Runner service. These are additional observability features, like tracing, that you choose to enable. They're configured in a separate resource that you associate with your service. — shape: {ObservabilityEnabled: bool, ObservabilityConfigurationArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.UpdateService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceArn, var: service_arn}, {name: SourceConfiguration, var: source_configuration}, {name: InstanceConfiguration, var: instance_configuration}, {name: AutoScalingConfigurationArn, var: auto_scaling_configuration_arn}, {name: HealthCheckConfiguration, var: health_check_configuration}, {name: NetworkConfiguration, var: network_configuration}, {name: ObservabilityConfiguration, var: observability_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_arn: $service_arn, source_configuration: $source_configuration, instance_configuration: $instance_configuration, auto_scaling_configuration_arn: $auto_scaling_configuration_arn, health_check_configuration: $health_check_configuration, network_configuration: $network_configuration, observability_configuration: $observability_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing App Runner VPC Ingress Connection resource. The VPC Ingress Connection must be in one of the following states to be updated: AVAILABLE FAILED_CREATION FAILED_UPDATE
#
# POST /
# Returns: record<VpcIngressConnection: record<VpcIngressConnectionArn: string, VpcIngressConnectionName: string, ServiceArn: string, Status: string, AccountId: string, DomainName: string, IngressVpcConfiguration: record<VpcId: string, VpcEndpointId: string>, CreatedAt: string, DeletedAt: string>>
# operationId: UpdateVpcIngressConnection
export def "update-vpc-ingress-connection" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  vpc_ingress_connection_arn: string # The Amazon Resource Name (Arn) for the App Runner VPC Ingress Connection resource that you want to update.
  ingress_vpc_configuration: record # The configuration of your VPC and the associated VPC endpoint. The VPC endpoint is an Amazon Web Services PrivateLink resource that allows access to your App Runner services from within an Amazon VPC. — shape: {VpcId?: string, VpcEndpointId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AppRunner.UpdateVpcIngressConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcIngressConnectionArn, var: vpc_ingress_connection_arn}, {name: IngressVpcConfiguration, var: ingress_vpc_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpc_ingress_connection_arn: $vpc_ingress_connection_arn, ingress_vpc_configuration: $ingress_vpc_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
