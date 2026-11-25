# Auto-generated client for Amazon Forecast Service v2018-06-26
# Source: https://api.apis.guru/v2/specs/amazonaws.com/forecast/2018-06-26/openapi.json
# Auth: --token flag or $env.AMAZON_FORECAST_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://forecast.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_FORECAST_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://forecast.us-east-1.amazonaws.com" "http://forecast.us-east-2.amazonaws.com" "http://forecast.us-west-1.amazonaws.com" "http://forecast.us-west-2.amazonaws.com" "http://forecast.us-gov-west-1.amazonaws.com" "http://forecast.us-gov-east-1.amazonaws.com" "http://forecast.ca-central-1.amazonaws.com" "http://forecast.eu-north-1.amazonaws.com" "http://forecast.eu-west-1.amazonaws.com" "http://forecast.eu-west-2.amazonaws.com" "http://forecast.eu-west-3.amazonaws.com" "http://forecast.eu-central-1.amazonaws.com" "http://forecast.eu-south-1.amazonaws.com" "http://forecast.af-south-1.amazonaws.com" "http://forecast.ap-northeast-1.amazonaws.com" "http://forecast.ap-northeast-2.amazonaws.com" "http://forecast.ap-northeast-3.amazonaws.com" "http://forecast.ap-southeast-1.amazonaws.com" "http://forecast.ap-southeast-2.amazonaws.com" "http://forecast.ap-east-1.amazonaws.com" "http://forecast.ap-south-1.amazonaws.com" "http://forecast.sa-east-1.amazonaws.com" "http://forecast.me-south-1.amazonaws.com" "https://forecast.us-east-1.amazonaws.com" "https://forecast.us-east-2.amazonaws.com" "https://forecast.us-west-1.amazonaws.com" "https://forecast.us-west-2.amazonaws.com" "https://forecast.us-gov-west-1.amazonaws.com" "https://forecast.us-gov-east-1.amazonaws.com" "https://forecast.ca-central-1.amazonaws.com" "https://forecast.eu-north-1.amazonaws.com" "https://forecast.eu-west-1.amazonaws.com" "https://forecast.eu-west-2.amazonaws.com" "https://forecast.eu-west-3.amazonaws.com" "https://forecast.eu-central-1.amazonaws.com" "https://forecast.eu-south-1.amazonaws.com" "https://forecast.af-south-1.amazonaws.com" "https://forecast.ap-northeast-1.amazonaws.com" "https://forecast.ap-northeast-2.amazonaws.com" "https://forecast.ap-northeast-3.amazonaws.com" "https://forecast.ap-southeast-1.amazonaws.com" "https://forecast.ap-southeast-2.amazonaws.com" "https://forecast.ap-east-1.amazonaws.com" "https://forecast.ap-south-1.amazonaws.com" "https://forecast.sa-east-1.amazonaws.com" "https://forecast.me-south-1.amazonaws.com" "http://forecast.cn-north-1.amazonaws.com.cn" "http://forecast.cn-northwest-1.amazonaws.com.cn" "https://forecast.cn-north-1.amazonaws.com.cn" "https://forecast.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def optimization-metric-completer [] { ["AverageWeightedQuantileLoss" "MAPE" "MASE" "RMSE" "WAPE"] }
def x-amz-target-completer [] { ["AmazonForecast.CreateAutoPredictor"] }
def domain-completer [] { ["CUSTOM" "EC2_CAPACITY" "INVENTORY_PLANNING" "METRICS" "RETAIL" "WEB_TRAFFIC" "WORK_FORCE"] }
def dataset-type-completer [] { ["ITEM_METADATA" "RELATED_TIME_SERIES" "TARGET_TIME_SERIES"] }
def x-amz-target-completer-1 [] { ["AmazonForecast.CreateDataset"] }
def x-amz-target-completer-2 [] { ["AmazonForecast.CreateDatasetGroup"] }
def import-mode-completer [] { ["FULL" "INCREMENTAL"] }
def x-amz-target-completer-3 [] { ["AmazonForecast.CreateDatasetImportJob"] }
def x-amz-target-completer-4 [] { ["AmazonForecast.CreateExplainability"] }
def x-amz-target-completer-5 [] { ["AmazonForecast.CreateExplainabilityExport"] }
def x-amz-target-completer-6 [] { ["AmazonForecast.CreateForecast"] }
def x-amz-target-completer-7 [] { ["AmazonForecast.CreateForecastExportJob"] }
def x-amz-target-completer-8 [] { ["AmazonForecast.CreateMonitor"] }
def auto-ml-override-strategy-completer [] { ["AccuracyOptimized" "LatencyOptimized"] }
def x-amz-target-completer-9 [] { ["AmazonForecast.CreatePredictor"] }
def x-amz-target-completer-10 [] { ["AmazonForecast.CreatePredictorBacktestExportJob"] }
def x-amz-target-completer-11 [] { ["AmazonForecast.CreateWhatIfAnalysis"] }
def x-amz-target-completer-12 [] { ["AmazonForecast.CreateWhatIfForecast"] }
def x-amz-target-completer-13 [] { ["AmazonForecast.CreateWhatIfForecastExport"] }
def x-amz-target-completer-14 [] { ["AmazonForecast.DeleteDataset"] }
def x-amz-target-completer-15 [] { ["AmazonForecast.DeleteDatasetGroup"] }
def x-amz-target-completer-16 [] { ["AmazonForecast.DeleteDatasetImportJob"] }
def x-amz-target-completer-17 [] { ["AmazonForecast.DeleteExplainability"] }
def x-amz-target-completer-18 [] { ["AmazonForecast.DeleteExplainabilityExport"] }
def x-amz-target-completer-19 [] { ["AmazonForecast.DeleteForecast"] }
def x-amz-target-completer-20 [] { ["AmazonForecast.DeleteForecastExportJob"] }
def x-amz-target-completer-21 [] { ["AmazonForecast.DeleteMonitor"] }
def x-amz-target-completer-22 [] { ["AmazonForecast.DeletePredictor"] }
def x-amz-target-completer-23 [] { ["AmazonForecast.DeletePredictorBacktestExportJob"] }
def x-amz-target-completer-24 [] { ["AmazonForecast.DeleteResourceTree"] }
def x-amz-target-completer-25 [] { ["AmazonForecast.DeleteWhatIfAnalysis"] }
def x-amz-target-completer-26 [] { ["AmazonForecast.DeleteWhatIfForecast"] }
def x-amz-target-completer-27 [] { ["AmazonForecast.DeleteWhatIfForecastExport"] }
def x-amz-target-completer-28 [] { ["AmazonForecast.DescribeAutoPredictor"] }
def x-amz-target-completer-29 [] { ["AmazonForecast.DescribeDataset"] }
def x-amz-target-completer-30 [] { ["AmazonForecast.DescribeDatasetGroup"] }
def x-amz-target-completer-31 [] { ["AmazonForecast.DescribeDatasetImportJob"] }
def x-amz-target-completer-32 [] { ["AmazonForecast.DescribeExplainability"] }
def x-amz-target-completer-33 [] { ["AmazonForecast.DescribeExplainabilityExport"] }
def x-amz-target-completer-34 [] { ["AmazonForecast.DescribeForecast"] }
def x-amz-target-completer-35 [] { ["AmazonForecast.DescribeForecastExportJob"] }
def x-amz-target-completer-36 [] { ["AmazonForecast.DescribeMonitor"] }
def x-amz-target-completer-37 [] { ["AmazonForecast.DescribePredictor"] }
def x-amz-target-completer-38 [] { ["AmazonForecast.DescribePredictorBacktestExportJob"] }
def x-amz-target-completer-39 [] { ["AmazonForecast.DescribeWhatIfAnalysis"] }
def x-amz-target-completer-40 [] { ["AmazonForecast.DescribeWhatIfForecast"] }
def x-amz-target-completer-41 [] { ["AmazonForecast.DescribeWhatIfForecastExport"] }
def x-amz-target-completer-42 [] { ["AmazonForecast.GetAccuracyMetrics"] }
def x-amz-target-completer-43 [] { ["AmazonForecast.ListDatasetGroups"] }
def x-amz-target-completer-44 [] { ["AmazonForecast.ListDatasetImportJobs"] }
def x-amz-target-completer-45 [] { ["AmazonForecast.ListDatasets"] }
def x-amz-target-completer-46 [] { ["AmazonForecast.ListExplainabilities"] }
def x-amz-target-completer-47 [] { ["AmazonForecast.ListExplainabilityExports"] }
def x-amz-target-completer-48 [] { ["AmazonForecast.ListForecastExportJobs"] }
def x-amz-target-completer-49 [] { ["AmazonForecast.ListForecasts"] }
def x-amz-target-completer-50 [] { ["AmazonForecast.ListMonitorEvaluations"] }
def x-amz-target-completer-51 [] { ["AmazonForecast.ListMonitors"] }
def x-amz-target-completer-52 [] { ["AmazonForecast.ListPredictorBacktestExportJobs"] }
def x-amz-target-completer-53 [] { ["AmazonForecast.ListPredictors"] }
def x-amz-target-completer-54 [] { ["AmazonForecast.ListTagsForResource"] }
def x-amz-target-completer-55 [] { ["AmazonForecast.ListWhatIfAnalyses"] }
def x-amz-target-completer-56 [] { ["AmazonForecast.ListWhatIfForecastExports"] }
def x-amz-target-completer-57 [] { ["AmazonForecast.ListWhatIfForecasts"] }
def x-amz-target-completer-58 [] { ["AmazonForecast.ResumeResource"] }
def x-amz-target-completer-59 [] { ["AmazonForecast.StopResource"] }
def x-amz-target-completer-60 [] { ["AmazonForecast.TagResource"] }
def x-amz-target-completer-61 [] { ["AmazonForecast.UntagResource"] }
def x-amz-target-completer-62 [] { ["AmazonForecast.UpdateDatasetGroup"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-auto-predictor: "record<PredictorArn: string>"
    create-dataset: "record<DatasetArn: string>"
    create-dataset-group: "record<DatasetGroupArn: string>"
    create-dataset-import-job: "record<DatasetImportJobArn: string>"
    create-explainability: "record<ExplainabilityArn: string>"
    create-explainability-export: "record<ExplainabilityExportArn: string>"
    create-forecast: "record<ForecastArn: string>"
    create-forecast-export-job: "record<ForecastExportJobArn: string>"
    create-monitor: "record<MonitorArn: string>"
    create-predictor: "record<PredictorArn: string>"
    create-predictor-backtest-export-job: "record<PredictorBacktestExportJobArn: string>"
    create-what-if-analysis: "record<WhatIfAnalysisArn: string>"
    create-what-if-forecast: "record<WhatIfForecastArn: string>"
    create-what-if-forecast-export: "record<WhatIfForecastExportArn: string>"
    describe-auto-predictor: "record<PredictorArn: string, PredictorName: string, ForecastHorizon: int, ForecastTypes: list<string>, ForecastFrequency: string, ForecastDimensions: list<string>, DatasetImportJobArns: list<string>, DataConfig: record<DatasetGroupArn: string, AttributeConfigs: list<record>, AdditionalDatasets: list<record>>, EncryptionConfig: record<RoleArn: string, KMSKeyArn: string>, ReferencePredictorSummary: record<Arn: string, State: string>, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, OptimizationMetric: string, ExplainabilityInfo: record<ExplainabilityArn: string, Status: string>, MonitorInfo: record<MonitorArn: string, Status: string>, TimeAlignmentBoundary: record<Month: string, DayOfMonth: int, DayOfWeek: string, Hour: int>>"
    describe-dataset: "record<DatasetArn: string, DatasetName: string, Domain: string, DatasetType: string, DataFrequency: string, Schema: record<Attributes: list<record>>, EncryptionConfig: record<RoleArn: string, KMSKeyArn: string>, Status: string, CreationTime: string, LastModificationTime: string>"
    describe-dataset-group: "record<DatasetGroupName: string, DatasetGroupArn: string, DatasetArns: list<string>, Domain: string, Status: string, CreationTime: string, LastModificationTime: string>"
    describe-dataset-import-job: "record<DatasetImportJobName: string, DatasetImportJobArn: string, DatasetArn: string, TimestampFormat: string, TimeZone: string, UseGeolocationForTimeZone: bool, GeolocationFormat: string, DataSource: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, EstimatedTimeRemainingInMinutes: int, FieldStatistics: record, DataSize: float, Status: string, Message: string, CreationTime: string, LastModificationTime: string, Format: string, ImportMode: string>"
    describe-explainability: "record<ExplainabilityArn: string, ExplainabilityName: string, ResourceArn: string, ExplainabilityConfig: record<TimeSeriesGranularity: string, TimePointGranularity: string>, EnableVisualization: bool, DataSource: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Schema: record<Attributes: list<record>>, StartDateTime: string, EndDateTime: string, EstimatedTimeRemainingInMinutes: int, Message: string, Status: string, CreationTime: string, LastModificationTime: string>"
    describe-explainability-export: "record<ExplainabilityExportArn: string, ExplainabilityExportName: string, ExplainabilityArn: string, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, LastModificationTime: string, Format: string>"
    describe-forecast: "record<ForecastArn: string, ForecastName: string, ForecastTypes: list<string>, PredictorArn: string, DatasetGroupArn: string, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, TimeSeriesSelector: record<TimeSeriesIdentifiers: record<DataSource: record, Schema: record, Format: string>>>"
    describe-forecast-export-job: "record<ForecastExportJobArn: string, ForecastExportJobName: string, ForecastArn: string, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, LastModificationTime: string, Format: string>"
    describe-monitor: "record<MonitorName: string, MonitorArn: string, ResourceArn: string, Status: string, LastEvaluationTime: string, LastEvaluationState: string, Baseline: record<PredictorBaseline: record<BaselineMetrics: list>>, Message: string, CreationTime: string, LastModificationTime: string, EstimatedEvaluationTimeRemainingInMinutes: int>"
    describe-predictor: "record<PredictorArn: string, PredictorName: string, AlgorithmArn: string, AutoMLAlgorithmArns: list<string>, ForecastHorizon: int, ForecastTypes: list<string>, PerformAutoML: bool, AutoMLOverrideStrategy: string, PerformHPO: bool, TrainingParameters: record, EvaluationParameters: record<NumberOfBacktestWindows: int, BackTestWindowOffset: int>, HPOConfig: record<ParameterRanges: record<CategoricalParameterRanges: list, ContinuousParameterRanges: list, IntegerParameterRanges: list>>, InputDataConfig: record<DatasetGroupArn: string, SupplementaryFeatures: list<record>>, FeaturizationConfig: record<ForecastFrequency: string, ForecastDimensions: list<string>, Featurizations: list<record>>, EncryptionConfig: record<RoleArn: string, KMSKeyArn: string>, PredictorExecutionDetails: record<PredictorExecutions: list<record>>, EstimatedTimeRemainingInMinutes: int, IsAutoPredictor: bool, DatasetImportJobArns: list<string>, Status: string, Message: string, CreationTime: string, LastModificationTime: string, OptimizationMetric: string>"
    describe-predictor-backtest-export-job: "record<PredictorBacktestExportJobArn: string, PredictorBacktestExportJobName: string, PredictorArn: string, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, LastModificationTime: string, Format: string>"
    describe-what-if-analysis: "record<WhatIfAnalysisName: string, WhatIfAnalysisArn: string, ForecastArn: string, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, TimeSeriesSelector: record<TimeSeriesIdentifiers: record<DataSource: record, Schema: record, Format: string>>>"
    describe-what-if-forecast: "record<WhatIfForecastName: string, WhatIfForecastArn: string, WhatIfAnalysisArn: string, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, TimeSeriesTransformations: table<Action: record, TimeSeriesConditions: list>, TimeSeriesReplacementsDataSource: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>, Schema: record<Attributes: list>, Format: string, TimestampFormat: string>, ForecastTypes: list<string>>"
    describe-what-if-forecast-export: "record<WhatIfForecastExportArn: string, WhatIfForecastExportName: string, WhatIfForecastArns: list<string>, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, EstimatedTimeRemainingInMinutes: int, LastModificationTime: string, Format: string>"
    get-accuracy-metrics: "record<PredictorEvaluationResults: table<AlgorithmArn: string, TestWindows: list>, IsAutoPredictor: bool, AutoMLOverrideStrategy: string, OptimizationMetric: string>"
    list-dataset-groups: "record<DatasetGroups: table<DatasetGroupArn: string, DatasetGroupName: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-dataset-import-jobs: "record<DatasetImportJobs: table<DatasetImportJobArn: string, DatasetImportJobName: string, DataSource: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string, ImportMode: string>, NextToken: string>"
    list-datasets: "record<Datasets: table<DatasetArn: string, DatasetName: string, DatasetType: string, Domain: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-explainabilities: "record<Explainabilities: table<ExplainabilityArn: string, ExplainabilityName: string, ResourceArn: string, ExplainabilityConfig: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-explainability-exports: "record<ExplainabilityExports: table<ExplainabilityExportArn: string, ExplainabilityExportName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-forecast-export-jobs: "record<ForecastExportJobs: table<ForecastExportJobArn: string, ForecastExportJobName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-forecasts: "record<Forecasts: table<ForecastArn: string, ForecastName: string, PredictorArn: string, CreatedUsingAutoPredictor: bool, DatasetGroupArn: string, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-monitor-evaluations: "record<NextToken: string, PredictorMonitorEvaluations: table<ResourceArn: string, MonitorArn: string, EvaluationTime: string, EvaluationState: string, WindowStartDatetime: string, WindowEndDatetime: string, PredictorEvent: record, MonitorDataSource: record, MetricResults: list, NumItemsEvaluated: int, Message: string>>"
    list-monitors: "record<Monitors: table<MonitorArn: string, MonitorName: string, ResourceArn: string, Status: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-predictor-backtest-export-jobs: "record<PredictorBacktestExportJobs: table<PredictorBacktestExportJobArn: string, PredictorBacktestExportJobName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-predictors: "record<Predictors: table<PredictorArn: string, PredictorName: string, DatasetGroupArn: string, IsAutoPredictor: bool, ReferencePredictorSummary: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    list-what-if-analyses: "record<WhatIfAnalyses: table<WhatIfAnalysisArn: string, WhatIfAnalysisName: string, ForecastArn: string, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-what-if-forecast-exports: "record<WhatIfForecastExports: table<WhatIfForecastExportArn: string, WhatIfForecastArns: list, WhatIfForecastExportName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    list-what-if-forecasts: "record<WhatIfForecasts: table<WhatIfForecastArn: string, WhatIfForecastName: string, WhatIfAnalysisArn: string, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-dataset-group: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-auto-predictor" "create-dataset" "create-dataset-group" "create-dataset-import-job" "create-explainability" "create-explainability-export" "create-forecast" "create-forecast-export-job" "create-monitor" "create-predictor" "create-predictor-backtest-export-job" "create-what-if-analysis" "create-what-if-forecast" "create-what-if-forecast-export" "delete-dataset" "delete-dataset-group" "delete-dataset-import-job" "delete-explainability" "delete-explainability-export" "delete-forecast" "delete-forecast-export-job" "delete-monitor" "delete-predictor" "delete-predictor-backtest-export-job" "delete-resource-tree" "delete-what-if-analysis" "delete-what-if-forecast" "delete-what-if-forecast-export" "describe-auto-predictor" "describe-dataset" "describe-dataset-group" "describe-dataset-import-job" "describe-explainability" "describe-explainability-export" "describe-forecast" "describe-forecast-export-job" "describe-monitor" "describe-predictor" "describe-predictor-backtest-export-job" "describe-what-if-analysis" "describe-what-if-forecast" "describe-what-if-forecast-export" "get-accuracy-metrics" "list-dataset-groups" "list-dataset-import-jobs" "list-datasets" "list-explainabilities" "list-explainability-exports" "list-forecast-export-jobs" "list-forecasts" "list-monitor-evaluations" "list-monitors" "list-predictor-backtest-export-jobs" "list-predictors" "list-tags-for-resource" "list-what-if-analyses" "list-what-if-forecast-exports" "list-what-if-forecasts" "resume-resource" "stop-resource" "tag-resource" "untag-resource" "update-dataset-group" "commands"] | sort) } | get name | first)
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

# Creates an Amazon Forecast predictor. Amazon Forecast creates predictors with AutoPredictor, which involves applying the optimal combination of algorithms to each time series in your datasets. You can use CreateAutoPredictor to create new predictors or upgrade/retrain existing predictors. Creating new predictors The following parameters are required when creating a new predictor: PredictorName - A unique name for the predictor. DatasetGroupArn - The ARN of the dataset group used to train the predictor. ForecastFrequency - The granularity of your forecasts (hourly, daily, weekly, etc). ForecastHorizon - The number of time-steps that the model predicts. The forecast horizon is also called the prediction length. When creating a new predictor, do not specify a value for ReferencePredictorArn. Upgrading and retraining predictors The following parameters are required when retraining or upgrading a predictor: PredictorName - A unique name for the predictor. ReferencePredictorArn - The ARN of the predictor to retrain or upgrade. When upgrading or retraining a predictor, only specify values for the ReferencePredictorArn and PredictorName.
#
# POST /
# Returns: record<PredictorArn: string>
# operationId: CreateAutoPredictor
export def "create-auto-predictor" [
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
  predictor_name: string # A unique name for the predictor
  --forecast-horizon: int # The number of time-steps that the model predicts. The forecast horizon is also called the prediction length. The maximum forecast horizon is the lesser of 500 time-steps or 1/4 of the TARGET_TIME_SERIES dataset length. If you are retraining an existing AutoPredictor, then the maximum forecast horizon is the lesser of 500 time-steps or 1/3 of the TARGET_TIME_SERIES dataset length. If you are upgrading to an AutoPredictor or retraining an existing AutoPredictor, you cannot update the forecast horizon parameter. You can meet this requirement by providing longer time-series in the dataset.
  --forecast-types: list<string> # The forecast types used to train a predictor. You can specify up to five forecast types. Forecast types can be quantiles from 0.01 to 0.99, by increments of 0.01 or higher. You can also specify the mean forecast with mean.
  --forecast-dimensions: list<string> # An array of dimension (field) names that specify how to group the generated forecast. For example, if you are generating forecasts for item sales across all your stores, and your dataset contains a store_id field, you would specify store_id as a dimension to group sales forecasts for each store.
  --forecast-frequency: string # The frequency of predictions in a forecast. Valid intervals are an integer followed by Y (Year), M (Month), W (Week), D (Day), H (Hour), and min (Minute). For example, "1D" indicates every day and "15min" indicates every 15 minutes. You cannot specify a value that would overlap with the next larger frequency. That means, for example, you cannot specify a frequency of 60 minutes, because that is equivalent to 1 hour. The valid values for each frequency are the following: Minute - 1-59 Hour - 1-23 Day - 1-6 Week - 1-4 Month - 1-11 Year - 1 Thus, if you want every other week forecasts, specify "2W". Or, if you want quarterly forecasts, you specify "3M". The frequency must be greater than or equal to the TARGET_TIME_SERIES dataset frequency. When a RELATED_TIME_SERIES dataset is provided, the frequency must be equal to the RELATED_TIME_SERIES dataset frequency.
  --data-config: record # The data configuration for your dataset group and any additional datasets. — shape: {DatasetGroupArn: string, AttributeConfigs?: list, AdditionalDatasets?: list}
  --encryption-config: record # An Key Management Service (KMS) key and an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the key. You can specify this optional object in the CreateDataset and CreatePredictor requests. — shape: {RoleArn: string, KMSKeyArn: string}
  --reference-predictor-arn: string # The ARN of the predictor to retrain or upgrade. This parameter is only used when retraining or upgrading a predictor. When creating a new predictor, do not specify a value for this parameter. When upgrading or retraining a predictor, only specify values for the ReferencePredictorArn and PredictorName. The value for PredictorName must be a unique predictor name.
  --optimization-metric: string@optimization-metric-completer # The accuracy metric used to optimize the predictor.
  --explain-predictor: oneof<nothing, bool> # Create an Explainability resource for the predictor.
  --tags: list # Optional metadata to help you categorize and organize your predictors. Each tag consists of a key and an optional value, both of which you define. Tag keys and values are case sensitive. The following restrictions apply to tags: For each resource, each tag key must be unique and each tag key must have one value. Maximum number of tags per resource: 50. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Accepted characters: all letters and numbers, spaces representable in UTF-8, and + - = . _ : / @. If your tagging schema is used across other services and resources, the character restrictions of those services also apply. Key prefixes cannot include any upper or lowercase combination of aws: or AWS:. Values can have this prefix. If a tag value has aws as its prefix but the key does not, Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. You cannot edit or delete tag keys with this prefix. — item shape: {Key: string, Value: string}
  --monitor-config: record # The configuration details for the predictor monitor. — shape: {MonitorName: string}
  --time-alignment-boundary: record # The time boundary Forecast uses to align and aggregate your data to match your forecast frequency. Provide the unit of time and the time boundary as a key value pair. If you don't provide a time boundary, Forecast uses a set of Default Time Boundaries (https://docs.aws.amazon.com/forecast/latest/dg/data-aggregation.html#default-time-boundaries). For more information about aggregation, see Data Aggregation for Different Forecast Frequencies (https://docs.aws.amazon.com/forecast/latest/dg/data-aggregation.html). For more information setting a custom time boundary, see Specifying a Time Boundary (https://docs.aws.amazon.com/forecast/latest/dg/data-aggregation.html#specifying-time-boundary). — shape: {Month?: "JANUARY"|"FEBRUARY"|"MARCH"|"APRIL"|"MAY"|"JUNE"|"JULY"|"AUGUST"|"SEPTEMBER"|"OCTOBER"|"NOVEMBER"|"DECEMBER", DayOfMonth?: int, DayOfWeek?: "MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", Hour?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateAutoPredictor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorName, var: predictor_name}, {name: ForecastHorizon, var: forecast_horizon}, {name: ForecastTypes, var: forecast_types}, {name: ForecastDimensions, var: forecast_dimensions}, {name: ForecastFrequency, var: forecast_frequency}, {name: DataConfig, var: data_config}, {name: EncryptionConfig, var: encryption_config}, {name: ReferencePredictorArn, var: reference_predictor_arn}, {name: OptimizationMetric, var: optimization_metric}, {name: ExplainPredictor, var: explain_predictor}, {name: Tags, var: tags}, {name: MonitorConfig, var: monitor_config}, {name: TimeAlignmentBoundary, var: time_alignment_boundary}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_name: $predictor_name, forecast_horizon: $forecast_horizon, forecast_types: $forecast_types, forecast_dimensions: $forecast_dimensions, forecast_frequency: $forecast_frequency, data_config: $data_config, encryption_config: $encryption_config, reference_predictor_arn: $reference_predictor_arn, optimization_metric: $optimization_metric, explain_predictor: $explain_predictor, tags: $tags, monitor_config: $monitor_config, time_alignment_boundary: $time_alignment_boundary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Forecast dataset. The information about the dataset that you provide helps Forecast understand how to consume the data for model training. This includes the following: DataFrequency - How frequently your historical time-series data is collected. Domain and DatasetType - Each dataset has an associated dataset domain and a type within the domain. Amazon Forecast provides a list of predefined domains and types within each domain. For each unique dataset domain and type within the domain, Amazon Forecast requires your data to include a minimum set of predefined fields. Schema - A schema specifies the fields in the dataset, including the field name and data type. After creating a dataset, you import your training data into it and add the dataset to a dataset group. You use the dataset group to create a predictor. For more information, see Importing datasets (https://docs.aws.amazon.com/forecast/latest/dg/howitworks-datasets-groups.html). To get a list of all your datasets, use the ListDatasets (https://docs.aws.amazon.com/forecast/latest/dg/API_ListDatasets.html) operation. For example Forecast datasets, see the Amazon Forecast Sample GitHub repository (https://github.com/aws-samples/amazon-forecast-samples). The Status of a dataset must be ACTIVE before you can import training data. Use the DescribeDataset (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDataset.html) operation to get the status.
#
# POST /
# Returns: record<DatasetArn: string>
# operationId: CreateDataset
export def "create-dataset" [
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
  dataset_name: string # A name for the dataset.
  domain: string@domain-completer # The domain associated with the dataset. When you add a dataset to a dataset group, this value and the value specified for the Domain parameter of the CreateDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDatasetGroup.html) operation must match. The Domain and DatasetType that you choose determine the fields that must be present in the training data that you import to the dataset. For example, if you choose the RETAIL domain and TARGET_TIME_SERIES as the DatasetType, Amazon Forecast requires item_id, timestamp, and demand fields to be present in your data. For more information, see Importing datasets (https://docs.aws.amazon.com/forecast/latest/dg/howitworks-datasets-groups.html).
  dataset_type: string@dataset-type-completer # The dataset type. Valid values depend on the chosen Domain.
  --data-frequency: string # The frequency of data collection. This parameter is required for RELATED_TIME_SERIES datasets. Valid intervals are an integer followed by Y (Year), M (Month), W (Week), D (Day), H (Hour), and min (Minute). For example, "1D" indicates every day and "15min" indicates every 15 minutes. You cannot specify a value that would overlap with the next larger frequency. That means, for example, you cannot specify a frequency of 60 minutes, because that is equivalent to 1 hour. The valid values for each frequency are the following: Minute - 1-59 Hour - 1-23 Day - 1-6 Week - 1-4 Month - 1-11 Year - 1 Thus, if you want every other week forecasts, specify "2W". Or, if you want quarterly forecasts, you specify "3M".
  schema: record # Defines the fields of a dataset. — shape: {Attributes?: list}
  --encryption-config: record # An Key Management Service (KMS) key and an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the key. You can specify this optional object in the CreateDataset and CreatePredictor requests. — shape: {RoleArn: string, KMSKeyArn: string}
  --tags: list # The optional metadata that you apply to the dataset to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50. For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8. Maximum value length - 256 Unicode characters in UTF-8. If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for keys as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys with this prefix. Values can have this prefix. If a tag value has aws as its prefix but the key does not, then Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetName, var: dataset_name}, {name: Domain, var: domain}, {name: DatasetType, var: dataset_type}, {name: DataFrequency, var: data_frequency}, {name: Schema, var: schema}, {name: EncryptionConfig, var: encryption_config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_name: $dataset_name, domain: $domain, dataset_type: $dataset_type, data_frequency: $data_frequency, schema: $schema, encryption_config: $encryption_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a dataset group, which holds a collection of related datasets. You can add datasets to the dataset group when you create the dataset group, or later by using the UpdateDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_UpdateDatasetGroup.html) operation. After creating a dataset group and adding datasets, you use the dataset group when you create a predictor. For more information, see Dataset groups (https://docs.aws.amazon.com/forecast/latest/dg/howitworks-datasets-groups.html). To get a list of all your datasets groups, use the ListDatasetGroups (https://docs.aws.amazon.com/forecast/latest/dg/API_ListDatasetGroups.html) operation. The Status of a dataset group must be ACTIVE before you can use the dataset group to create a predictor. To get the status, use the DescribeDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDatasetGroup.html) operation.
#
# POST /
# Returns: record<DatasetGroupArn: string>
# operationId: CreateDatasetGroup
export def "create-dataset-group" [
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
  dataset_group_name: string # A name for the dataset group.
  domain: string@domain-completer # The domain associated with the dataset group. When you add a dataset to a dataset group, this value and the value specified for the Domain parameter of the CreateDataset (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDataset.html) operation must match. The Domain and DatasetType that you choose determine the fields that must be present in training data that you import to a dataset. For example, if you choose the RETAIL domain and TARGET_TIME_SERIES as the DatasetType, Amazon Forecast requires that item_id, timestamp, and demand fields are present in your data. For more information, see Dataset groups (https://docs.aws.amazon.com/forecast/latest/dg/howitworks-datasets-groups.html).
  --dataset-arns: list<string> # An array of Amazon Resource Names (ARNs) of the datasets that you want to include in the dataset group.
  --tags: list # The optional metadata that you apply to the dataset group to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50. For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8. Maximum value length - 256 Unicode characters in UTF-8. If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for keys as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys with this prefix. Values can have this prefix. If a tag value has aws as its prefix but the key does not, then Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateDatasetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetGroupName, var: dataset_group_name}, {name: Domain, var: domain}, {name: DatasetArns, var: dataset_arns}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_name: $dataset_group_name, domain: $domain, dataset_arns: $dataset_arns, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports your training data to an Amazon Forecast dataset. You provide the location of your training data in an Amazon Simple Storage Service (Amazon S3) bucket and the Amazon Resource Name (ARN) of the dataset that you want to import the data to. You must specify a DataSource (https://docs.aws.amazon.com/forecast/latest/dg/API_DataSource.html) object that includes an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the data, as Amazon Forecast makes a copy of your data and processes it in an internal Amazon Web Services system. For more information, see Set up permissions (https://docs.aws.amazon.com/forecast/latest/dg/aws-forecast-iam-roles.html). The training data must be in CSV or Parquet format. The delimiter must be a comma (,). You can specify the path to a specific file, the S3 bucket, or to a folder in the S3 bucket. For the latter two cases, Amazon Forecast imports all files up to the limit of 10,000 files. Because dataset imports are not aggregated, your most recent dataset import is the one that is used when training a predictor or generating a forecast. Make sure that your most recent dataset import contains all of the data you want to model off of, and not just the new data collected since the previous import. To get a list of all your dataset import jobs, filtered by specified criteria, use the ListDatasetImportJobs (https://docs.aws.amazon.com/forecast/latest/dg/API_ListDatasetImportJobs.html) operation.
#
# POST /
# Returns: record<DatasetImportJobArn: string>
# operationId: CreateDatasetImportJob
export def "create-dataset-import-job" [
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
  dataset_import_job_name: string # The name for the dataset import job. We recommend including the current timestamp in the name, for example, 20190721DatasetImport. This can help you avoid getting a ResourceAlreadyExistsException exception.
  dataset_arn: string # The Amazon Resource Name (ARN) of the Amazon Forecast dataset that you want to import data to.
  data_source: record # The source of your data, an Identity and Access Management (IAM) role that allows Amazon Forecast to access the data and, optionally, an Key Management Service (KMS) key. — shape: {S3Config: record}
  --timestamp-format: string # The format of timestamps in the dataset. The format that you specify depends on the DataFrequency specified when the dataset was created. The following formats are supported "yyyy-MM-dd" For the following data frequencies: Y, M, W, and D "yyyy-MM-dd HH:mm:ss" For the following data frequencies: H, 30min, 15min, and 1min; and optionally, for: Y, M, W, and D If the format isn't specified, Amazon Forecast expects the format to be "yyyy-MM-dd HH:mm:ss".
  --time-zone: string # A single time zone for every item in your dataset. This option is ideal for datasets with all timestamps within a single time zone, or if all timestamps are normalized to a single time zone. Refer to the Joda-Time API (http://joda-time.sourceforge.net/timezones.html) for a complete list of valid time zone names.
  --use-geolocation-for-time-zone: oneof<nothing, bool> # Automatically derive time zone information from the geolocation attribute. This option is ideal for datasets that contain timestamps in multiple time zones and those timestamps are expressed in local time.
  --geolocation-format: string # The format of the geolocation attribute. The geolocation attribute can be formatted in one of two ways: LAT_LONG - the latitude and longitude in decimal format (Example: 47.61_-122.33). CC_POSTALCODE (US Only) - the country code (US), followed by the 5-digit ZIP code (Example: US_98121).
  --tags: list # The optional metadata that you apply to the dataset import job to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50. For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8. Maximum value length - 256 Unicode characters in UTF-8. If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for keys as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys with this prefix. Values can have this prefix. If a tag value has aws as its prefix but the key does not, then Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. — item shape: {Key: string, Value: string}
  --format: string # The format of the imported data, CSV or PARQUET. The default value is CSV.
  --import-mode: string@import-mode-completer # Specifies whether the dataset import job is a FULL or INCREMENTAL import. A FULL dataset import replaces all of the existing data with the newly imported data. An INCREMENTAL import appends the imported data to the existing data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateDatasetImportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetImportJobName, var: dataset_import_job_name}, {name: DatasetArn, var: dataset_arn}, {name: DataSource, var: data_source}, {name: TimestampFormat, var: timestamp_format}, {name: TimeZone, var: time_zone}, {name: UseGeolocationForTimeZone, var: use_geolocation_for_time_zone}, {name: GeolocationFormat, var: geolocation_format}, {name: Tags, var: tags}, {name: Format, var: format}, {name: ImportMode, var: import_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_import_job_name: $dataset_import_job_name, dataset_arn: $dataset_arn, data_source: $data_source, timestamp_format: $timestamp_format, time_zone: $time_zone, use_geolocation_for_time_zone: $use_geolocation_for_time_zone, geolocation_format: $geolocation_format, tags: $tags, format: $format, import_mode: $import_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Explainability is only available for Forecasts and Predictors generated from an AutoPredictor (CreateAutoPredictor) Creates an Amazon Forecast Explainability. Explainability helps you better understand how the attributes in your datasets impact forecast. Amazon Forecast uses a metric called Impact scores to quantify the relative impact of each attribute and determine whether they increase or decrease forecast values. To enable Forecast Explainability, your predictor must include at least one of the following: related time series, item metadata, or additional datasets like Holidays and the Weather Index. CreateExplainability accepts either a Predictor ARN or Forecast ARN. To receive aggregated Impact scores for all time series and time points in your datasets, provide a Predictor ARN. To receive Impact scores for specific time series and time points, provide a Forecast ARN. CreateExplainability with a Predictor ARN You can only have one Explainability resource per predictor. If you already enabled ExplainPredictor in CreateAutoPredictor, that predictor already has an Explainability resource. The following parameters are required when providing a Predictor ARN: ExplainabilityName - A unique name for the Explainability. ResourceArn - The Arn of the predictor. TimePointGranularity - Must be set to “ALL”. TimeSeriesGranularity - Must be set to “ALL”. Do not specify a value for the following parameters: DataSource - Only valid when TimeSeriesGranularity is “SPECIFIC”. Schema - Only valid when TimeSeriesGranularity is “SPECIFIC”. StartDateTime - Only valid when TimePointGranularity is “SPECIFIC”. EndDateTime - Only valid when TimePointGranularity is “SPECIFIC”. CreateExplainability with a Forecast ARN You can specify a maximum of 50 time series and 500 time points. The following parameters are required when providing a Predictor ARN: ExplainabilityName - A unique name for the Explainability. ResourceArn - The Arn of the forecast. TimePointGranularity - Either “ALL” or “SPECIFIC”. TimeSeriesGranularity - Either “ALL” or “SPECIFIC”. If you set TimeSeriesGranularity to “SPECIFIC”, you must also provide the following: DataSource - The S3 location of the CSV file specifying your time series. Schema - The Schema defines the attributes and attribute types listed in the Data Source. If you set TimePointGranularity to “SPECIFIC”, you must also provide the following: StartDateTime - The first timestamp in the range of time points. EndDateTime - The last timestamp in the range of time points.
#
# POST /
# Returns: record<ExplainabilityArn: string>
# operationId: CreateExplainability
export def "create-explainability" [
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
  explainability_name: string # A unique name for the Explainability.
  resource_arn: string # The Amazon Resource Name (ARN) of the Predictor or Forecast used to create the Explainability.
  explainability_config: record # The ExplainabilityConfig data type defines the number of time series and time points included in CreateExplainability. If you provide a predictor ARN for ResourceArn, you must set both TimePointGranularity and TimeSeriesGranularity to “ALL”. When creating Predictor Explainability, Amazon Forecast considers all time series and time points. If you provide a forecast ARN for ResourceArn, you can set TimePointGranularity and TimeSeriesGranularity to either “ALL” or “Specific”. — shape: {TimeSeriesGranularity: "ALL"|"SPECIFIC", TimePointGranularity: "ALL"|"SPECIFIC"}
  --data-source: record # The source of your data, an Identity and Access Management (IAM) role that allows Amazon Forecast to access the data and, optionally, an Key Management Service (KMS) key. — shape: {S3Config: record}
  --schema: record # Defines the fields of a dataset. — shape: {Attributes?: list}
  --enable-visualization: oneof<nothing, bool> # Create an Explainability visualization that is viewable within the Amazon Web Services console.
  --start-date-time: string # If TimePointGranularity is set to SPECIFIC, define the first point for the Explainability. Use the following timestamp format: yyyy-MM-ddTHH:mm:ss (example: 2015-01-01T20:00:00)
  --end-date-time: string # If TimePointGranularity is set to SPECIFIC, define the last time point for the Explainability. Use the following timestamp format: yyyy-MM-ddTHH:mm:ss (example: 2015-01-01T20:00:00)
  --tags: list # Optional metadata to help you categorize and organize your resources. Each tag consists of a key and an optional value, both of which you define. Tag keys and values are case sensitive. The following restrictions apply to tags: For each resource, each tag key must be unique and each tag key must have one value. Maximum number of tags per resource: 50. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Accepted characters: all letters and numbers, spaces representable in UTF-8, and + - = . _ : / @. If your tagging schema is used across other services and resources, the character restrictions of those services also apply. Key prefixes cannot include any upper or lowercase combination of aws: or AWS:. Values can have this prefix. If a tag value has aws as its prefix but the key does not, Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. You cannot edit or delete tag keys with this prefix. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateExplainability"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExplainabilityName, var: explainability_name}, {name: ResourceArn, var: resource_arn}, {name: ExplainabilityConfig, var: explainability_config}, {name: DataSource, var: data_source}, {name: Schema, var: schema}, {name: EnableVisualization, var: enable_visualization}, {name: StartDateTime, var: start_date_time}, {name: EndDateTime, var: end_date_time}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, explainability_name: $explainability_name, resource_arn: $resource_arn, explainability_config: $explainability_config, data_source: $data_source, schema: $schema, enable_visualization: $enable_visualization, start_date_time: $start_date_time, end_date_time: $end_date_time, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports an Explainability resource created by the CreateExplainability operation. Exported files are exported to an Amazon Simple Storage Service (Amazon S3) bucket. You must specify a DataDestination object that includes an Amazon S3 bucket and an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see aws-forecast-iam-roles. The Status of the export job must be ACTIVE before you can access the export in your Amazon S3 bucket. To get the status, use the DescribeExplainabilityExport operation.
#
# POST /
# Returns: record<ExplainabilityExportArn: string>
# operationId: CreateExplainabilityExport
export def "create-explainability-export" [
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
  explainability_export_name: string # A unique name for the Explainability export.
  explainability_arn: string # The Amazon Resource Name (ARN) of the Explainability to export.
  destination: record # The destination for an export job. Provide an S3 path, an Identity and Access Management (IAM) role that allows Amazon Forecast to access the location, and an Key Management Service (KMS) key (optional). — shape: {S3Config: record}
  --tags: list # Optional metadata to help you categorize and organize your resources. Each tag consists of a key and an optional value, both of which you define. Tag keys and values are case sensitive. The following restrictions apply to tags: For each resource, each tag key must be unique and each tag key must have one value. Maximum number of tags per resource: 50. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Accepted characters: all letters and numbers, spaces representable in UTF-8, and + - = . _ : / @. If your tagging schema is used across other services and resources, the character restrictions of those services also apply. Key prefixes cannot include any upper or lowercase combination of aws: or AWS:. Values can have this prefix. If a tag value has aws as its prefix but the key does not, Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. You cannot edit or delete tag keys with this prefix. — item shape: {Key: string, Value: string}
  --format: string # The format of the exported data, CSV or PARQUET.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateExplainabilityExport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExplainabilityExportName, var: explainability_export_name}, {name: ExplainabilityArn, var: explainability_arn}, {name: Destination, var: destination}, {name: Tags, var: tags}, {name: Format, var: format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, explainability_export_name: $explainability_export_name, explainability_arn: $explainability_arn, destination: $destination, tags: $tags, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a forecast for each item in the TARGET_TIME_SERIES dataset that was used to train the predictor. This is known as inference. To retrieve the forecast for a single item at low latency, use the operation. To export the complete forecast into your Amazon Simple Storage Service (Amazon S3) bucket, use the CreateForecastExportJob operation. The range of the forecast is determined by the ForecastHorizon value, which you specify in the CreatePredictor request. When you query a forecast, you can request a specific date range within the forecast. To get a list of all your forecasts, use the ListForecasts operation. The forecasts generated by Amazon Forecast are in the same time zone as the dataset that was used to create the predictor. For more information, see howitworks-forecast. The Status of the forecast must be ACTIVE before you can query or export the forecast. Use the DescribeForecast operation to get the status. By default, a forecast includes predictions for every item (item_id) in the dataset group that was used to train the predictor. However, you can use the TimeSeriesSelector object to generate a forecast on a subset of time series. Forecast creation is skipped for any time series that you specify that are not in the input dataset. The forecast export file will not contain these time series or their forecasted values.
#
# POST /
# Returns: record<ForecastArn: string>
# operationId: CreateForecast
export def "create-forecast" [
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
  forecast_name: string # A name for the forecast.
  predictor_arn: string # The Amazon Resource Name (ARN) of the predictor to use to generate the forecast.
  --forecast-types: list<string> # The quantiles at which probabilistic forecasts are generated. You can currently specify up to 5 quantiles per forecast. Accepted values include 0.01 to 0.99 (increments of .01 only) and mean. The mean forecast is different from the median (0.50) when the distribution is not symmetric (for example, Beta and Negative Binomial). The default quantiles are the quantiles you specified during predictor creation. If you didn't specify quantiles, the default values are ["0.1", "0.5", "0.9"].
  --tags: list # The optional metadata that you apply to the forecast to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50. For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8. Maximum value length - 256 Unicode characters in UTF-8. If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for keys as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys with this prefix. Values can have this prefix. If a tag value has aws as its prefix but the key does not, then Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. — item shape: {Key: string, Value: string}
  --time-series-selector: record # Defines the set of time series that are used to create the forecasts in a TimeSeriesIdentifiers object. The TimeSeriesIdentifiers object needs the following information: DataSource Format Schema — shape: {TimeSeriesIdentifiers?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ForecastName, var: forecast_name}, {name: PredictorArn, var: predictor_arn}, {name: ForecastTypes, var: forecast_types}, {name: Tags, var: tags}, {name: TimeSeriesSelector, var: time_series_selector}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, forecast_name: $forecast_name, predictor_arn: $predictor_arn, forecast_types: $forecast_types, tags: $tags, time_series_selector: $time_series_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports a forecast created by the CreateForecast operation to your Amazon Simple Storage Service (Amazon S3) bucket. The forecast file name will match the following conventions: <ForecastExportJobName>_<ExportTimestamp>_<PartNumber> where the <ExportTimestamp> component is in Java SimpleDateFormat (yyyy-MM-ddTHH-mm-ssZ). You must specify a DataDestination object that includes an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see aws-forecast-iam-roles. For more information, see howitworks-forecast. To get a list of all your forecast export jobs, use the ListForecastExportJobs operation. The Status of the forecast export job must be ACTIVE before you can access the forecast in your Amazon S3 bucket. To get the status, use the DescribeForecastExportJob operation.
#
# POST /
# Returns: record<ForecastExportJobArn: string>
# operationId: CreateForecastExportJob
export def "create-forecast-export-job" [
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
  forecast_export_job_name: string # The name for the forecast export job.
  forecast_arn: string # The Amazon Resource Name (ARN) of the forecast that you want to export.
  destination: record # The destination for an export job. Provide an S3 path, an Identity and Access Management (IAM) role that allows Amazon Forecast to access the location, and an Key Management Service (KMS) key (optional). — shape: {S3Config: record}
  --tags: list # The optional metadata that you apply to the forecast export job to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50. For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8. Maximum value length - 256 Unicode characters in UTF-8. If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for keys as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys with this prefix. Values can have this prefix. If a tag value has aws as its prefix but the key does not, then Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. — item shape: {Key: string, Value: string}
  --format: string # The format of the exported data, CSV or PARQUET. The default value is CSV.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateForecastExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ForecastExportJobName, var: forecast_export_job_name}, {name: ForecastArn, var: forecast_arn}, {name: Destination, var: destination}, {name: Tags, var: tags}, {name: Format, var: format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, forecast_export_job_name: $forecast_export_job_name, forecast_arn: $forecast_arn, destination: $destination, tags: $tags, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a predictor monitor resource for an existing auto predictor. Predictor monitoring allows you to see how your predictor's performance changes over time. For more information, see Predictor Monitoring (https://docs.aws.amazon.com/forecast/latest/dg/predictor-monitoring.html).
#
# POST /
# Returns: record<MonitorArn: string>
# operationId: CreateMonitor
export def "create-monitor" [
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
  monitor_name: string # The name of the monitor resource.
  resource_arn: string # The Amazon Resource Name (ARN) of the predictor to monitor.
  --tags: list # A list of tags (https://docs.aws.amazon.com/forecast/latest/dg/tagging-forecast-resources.html) to apply to the monitor resource. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateMonitor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MonitorName, var: monitor_name}, {name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, monitor_name: $monitor_name, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation creates a legacy predictor that does not include all the predictor functionalities provided by Amazon Forecast. To create a predictor that is compatible with all aspects of Forecast, use CreateAutoPredictor. Creates an Amazon Forecast predictor. In the request, provide a dataset group and either specify an algorithm or let Amazon Forecast choose an algorithm for you using AutoML. If you specify an algorithm, you also can override algorithm-specific hyperparameters. Amazon Forecast uses the algorithm to train a predictor using the latest version of the datasets in the specified dataset group. You can then generate a forecast using the CreateForecast operation. To see the evaluation metrics, use the GetAccuracyMetrics operation. You can specify a featurization configuration to fill and aggregate the data fields in the TARGET_TIME_SERIES dataset to improve model training. For more information, see FeaturizationConfig. For RELATED_TIME_SERIES datasets, CreatePredictor verifies that the DataFrequency specified when the dataset was created matches the ForecastFrequency. TARGET_TIME_SERIES datasets don't have this restriction. Amazon Forecast also verifies the delimiter and timestamp format. For more information, see howitworks-datasets-groups. By default, predictors are trained and evaluated at the 0.1 (P10), 0.5 (P50), and 0.9 (P90) quantiles. You can choose custom forecast types to train and evaluate your predictor by setting the ForecastTypes. AutoML If you want Amazon Forecast to evaluate each algorithm and choose the one that minimizes the objective function, set PerformAutoML to true. The objective function is defined as the mean of the weighted losses over the forecast types. By default, these are the p10, p50, and p90 quantile losses. For more information, see EvaluationResult. When AutoML is enabled, the following properties are disallowed: AlgorithmArn HPOConfig PerformHPO TrainingParameters To get a list of all of your predictors, use the ListPredictors operation. Before you can use the predictor to create a forecast, the Status of the predictor must be ACTIVE, signifying that training has completed. To get the status, use the DescribePredictor operation.
#
# POST /
# Returns: record<PredictorArn: string>
# operationId: CreatePredictor
export def "create-predictor" [
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
  predictor_name: string # A name for the predictor.
  --algorithm-arn: string # The Amazon Resource Name (ARN) of the algorithm to use for model training. Required if PerformAutoML is not set to true. Supported algorithms: arn:aws:forecast:::algorithm/ARIMA arn:aws:forecast:::algorithm/CNN-QR arn:aws:forecast:::algorithm/Deep_AR_Plus arn:aws:forecast:::algorithm/ETS arn:aws:forecast:::algorithm/NPTS arn:aws:forecast:::algorithm/Prophet
  forecast_horizon: int # Specifies the number of time-steps that the model is trained to predict. The forecast horizon is also called the prediction length. For example, if you configure a dataset for daily data collection (using the DataFrequency parameter of the CreateDataset operation) and set the forecast horizon to 10, the model returns predictions for 10 days. The maximum forecast horizon is the lesser of 500 time-steps or 1/3 of the TARGET_TIME_SERIES dataset length.
  --forecast-types: list<string> # Specifies the forecast types used to train a predictor. You can specify up to five forecast types. Forecast types can be quantiles from 0.01 to 0.99, by increments of 0.01 or higher. You can also specify the mean forecast with mean. The default value is ["0.10", "0.50", "0.9"].
  --perform-auto-ml: oneof<nothing, bool> # Whether to perform AutoML. When Amazon Forecast performs AutoML, it evaluates the algorithms it provides and chooses the best algorithm and configuration for your training dataset. The default value is false. In this case, you are required to specify an algorithm. Set PerformAutoML to true to have Amazon Forecast perform AutoML. This is a good option if you aren't sure which algorithm is suitable for your training data. In this case, PerformHPO must be false.
  --auto-ml-override-strategy: string@auto-ml-override-strategy-completer # The LatencyOptimized AutoML override strategy is only available in private beta. Contact Amazon Web Services Support or your account manager to learn more about access privileges. Used to overide the default AutoML strategy, which is to optimize predictor accuracy. To apply an AutoML strategy that minimizes training time, use LatencyOptimized. This parameter is only valid for predictors trained using AutoML.
  --perform-hpo: oneof<nothing, bool> # Whether to perform hyperparameter optimization (HPO). HPO finds optimal hyperparameter values for your training data. The process of performing HPO is known as running a hyperparameter tuning job. The default value is false. In this case, Amazon Forecast uses default hyperparameter values from the chosen algorithm. To override the default values, set PerformHPO to true and, optionally, supply the HyperParameterTuningJobConfig object. The tuning job specifies a metric to optimize, which hyperparameters participate in tuning, and the valid range for each tunable hyperparameter. In this case, you are required to specify an algorithm and PerformAutoML must be false. The following algorithms support HPO: DeepAR+ CNN-QR
  --training-parameters: record # The hyperparameters to override for model training. The hyperparameters that you can override are listed in the individual algorithms. For the list of supported algorithms, see aws-forecast-choosing-recipes.
  --evaluation-parameters: record # Parameters that define how to split a dataset into training data and testing data, and the number of iterations to perform. These parameters are specified in the predefined algorithms but you can override them in the CreatePredictor request. — shape: {NumberOfBacktestWindows?: int, BackTestWindowOffset?: int}
  --hpo-config: record # Configuration information for a hyperparameter tuning job. You specify this object in the CreatePredictor request. A hyperparameter is a parameter that governs the model training process. You set hyperparameters before training starts, unlike model parameters, which are determined during training. The values of the hyperparameters effect which values are chosen for the model parameters. In a hyperparameter tuning job, Amazon Forecast chooses the set of hyperparameter values that optimize a specified metric. Forecast accomplishes this by running many training jobs over a range of hyperparameter values. The optimum set of values depends on the algorithm, the training data, and the specified metric objective. — shape: {ParameterRanges?: record}
  input_data_config: record # This object belongs to the CreatePredictor operation. If you created your predictor with CreateAutoPredictor, see DataConfig. The data used to train a predictor. The data includes a dataset group and any supplementary features. You specify this object in the CreatePredictor request. — shape: {DatasetGroupArn: string, SupplementaryFeatures?: list}
  featurization_config: record # This object belongs to the CreatePredictor operation. If you created your predictor with CreateAutoPredictor, see AttributeConfig. In a CreatePredictor operation, the specified algorithm trains a model using the specified dataset group. You can optionally tell the operation to modify data fields prior to training a model. These modifications are referred to as featurization. You define featurization using the FeaturizationConfig object. You specify an array of transformations, one for each field that you want to featurize. You then include the FeaturizationConfig object in your CreatePredictor request. Amazon Forecast applies the featurization to the TARGET_TIME_SERIES and RELATED_TIME_SERIES datasets before model training. You can create multiple featurization configurations. For example, you might call the CreatePredictor operation twice by specifying different featurization configurations. — shape: {ForecastFrequency: string, ForecastDimensions?: list<string>, Featurizations?: list}
  --encryption-config: record # An Key Management Service (KMS) key and an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the key. You can specify this optional object in the CreateDataset and CreatePredictor requests. — shape: {RoleArn: string, KMSKeyArn: string}
  --tags: list # The optional metadata that you apply to the predictor to help you categorize and organize them. Each tag consists of a key and an optional value, both of which you define. The following basic restrictions apply to tags: Maximum number of tags per resource - 50. For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8. Maximum value length - 256 Unicode characters in UTF-8. If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for keys as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys with this prefix. Values can have this prefix. If a tag value has aws as its prefix but the key does not, then Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. — item shape: {Key: string, Value: string}
  --optimization-metric: string@optimization-metric-completer # The accuracy metric used to optimize the predictor.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreatePredictor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorName, var: predictor_name}, {name: AlgorithmArn, var: algorithm_arn}, {name: ForecastHorizon, var: forecast_horizon}, {name: ForecastTypes, var: forecast_types}, {name: PerformAutoML, var: perform_auto_ml}, {name: AutoMLOverrideStrategy, var: auto_ml_override_strategy}, {name: PerformHPO, var: perform_hpo}, {name: TrainingParameters, var: training_parameters}, {name: EvaluationParameters, var: evaluation_parameters}, {name: HPOConfig, var: hpo_config}, {name: InputDataConfig, var: input_data_config}, {name: FeaturizationConfig, var: featurization_config}, {name: EncryptionConfig, var: encryption_config}, {name: Tags, var: tags}, {name: OptimizationMetric, var: optimization_metric}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_name: $predictor_name, algorithm_arn: $algorithm_arn, forecast_horizon: $forecast_horizon, forecast_types: $forecast_types, perform_auto_ml: $perform_auto_ml, auto_ml_override_strategy: $auto_ml_override_strategy, perform_hpo: $perform_hpo, training_parameters: $training_parameters, evaluation_parameters: $evaluation_parameters, hpo_config: $hpo_config, input_data_config: $input_data_config, featurization_config: $featurization_config, encryption_config: $encryption_config, tags: $tags, optimization_metric: $optimization_metric
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports backtest forecasts and accuracy metrics generated by the CreateAutoPredictor or CreatePredictor operations. Two folders containing CSV or Parquet files are exported to your specified S3 bucket. The export file names will match the following conventions: <ExportJobName>_<ExportTimestamp>_<PartNumber>.csv The <ExportTimestamp> component is in Java SimpleDate format (yyyy-MM-ddTHH-mm-ssZ). You must specify a DataDestination object that includes an Amazon S3 bucket and an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see aws-forecast-iam-roles. The Status of the export job must be ACTIVE before you can access the export in your Amazon S3 bucket. To get the status, use the DescribePredictorBacktestExportJob operation.
#
# POST /
# Returns: record<PredictorBacktestExportJobArn: string>
# operationId: CreatePredictorBacktestExportJob
export def "create-predictor-backtest-export-job" [
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
  predictor_backtest_export_job_name: string # The name for the backtest export job.
  predictor_arn: string # The Amazon Resource Name (ARN) of the predictor that you want to export.
  destination: record # The destination for an export job. Provide an S3 path, an Identity and Access Management (IAM) role that allows Amazon Forecast to access the location, and an Key Management Service (KMS) key (optional). — shape: {S3Config: record}
  --tags: list # Optional metadata to help you categorize and organize your backtests. Each tag consists of a key and an optional value, both of which you define. Tag keys and values are case sensitive. The following restrictions apply to tags: For each resource, each tag key must be unique and each tag key must have one value. Maximum number of tags per resource: 50. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Accepted characters: all letters and numbers, spaces representable in UTF-8, and + - = . _ : / @. If your tagging schema is used across other services and resources, the character restrictions of those services also apply. Key prefixes cannot include any upper or lowercase combination of aws: or AWS:. Values can have this prefix. If a tag value has aws as its prefix but the key does not, Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. You cannot edit or delete tag keys with this prefix. — item shape: {Key: string, Value: string}
  --format: string # The format of the exported data, CSV or PARQUET. The default value is CSV.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreatePredictorBacktestExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorBacktestExportJobName, var: predictor_backtest_export_job_name}, {name: PredictorArn, var: predictor_arn}, {name: Destination, var: destination}, {name: Tags, var: tags}, {name: Format, var: format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_backtest_export_job_name: $predictor_backtest_export_job_name, predictor_arn: $predictor_arn, destination: $destination, tags: $tags, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# What-if analysis is a scenario modeling technique where you make a hypothetical change to a time series and compare the forecasts generated by these changes against the baseline, unchanged time series. It is important to remember that the purpose of a what-if analysis is to understand how a forecast can change given different modifications to the baseline time series. For example, imagine you are a clothing retailer who is considering an end of season sale to clear space for new styles. After creating a baseline forecast, you can use a what-if analysis to investigate how different sales tactics might affect your goals. You could create a scenario where everything is given a 25% markdown, and another where everything is given a fixed dollar markdown. You could create a scenario where the sale lasts for one week and another where the sale lasts for one month. With a what-if analysis, you can compare many different scenarios against each other. Note that a what-if analysis is meant to display what the forecasting model has learned and how it will behave in the scenarios that you are evaluating. Do not blindly use the results of the what-if analysis to make business decisions. For instance, forecasts might not be accurate for novel scenarios where there is no reference available to determine whether a forecast is good. The TimeSeriesSelector object defines the items that you want in the what-if analysis.
#
# POST /
# Returns: record<WhatIfAnalysisArn: string>
# operationId: CreateWhatIfAnalysis
export def "create-what-if-analysis" [
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
  what_if_analysis_name: string # The name of the what-if analysis. Each name must be unique.
  forecast_arn: string # The Amazon Resource Name (ARN) of the baseline forecast.
  --time-series-selector: record # Defines the set of time series that are used to create the forecasts in a TimeSeriesIdentifiers object. The TimeSeriesIdentifiers object needs the following information: DataSource Format Schema — shape: {TimeSeriesIdentifiers?: record}
  --tags: list # A list of tags (https://docs.aws.amazon.com/forecast/latest/dg/tagging-forecast-resources.html) to apply to the what if forecast. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateWhatIfAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfAnalysisName, var: what_if_analysis_name}, {name: ForecastArn, var: forecast_arn}, {name: TimeSeriesSelector, var: time_series_selector}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_analysis_name: $what_if_analysis_name, forecast_arn: $forecast_arn, time_series_selector: $time_series_selector, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A what-if forecast is a forecast that is created from a modified version of the baseline forecast. Each what-if forecast incorporates either a replacement dataset or a set of transformations to the original dataset.
#
# POST /
# Returns: record<WhatIfForecastArn: string>
# operationId: CreateWhatIfForecast
export def "create-what-if-forecast" [
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
  what_if_forecast_name: string # The name of the what-if forecast. Names must be unique within each what-if analysis.
  what_if_analysis_arn: string # The Amazon Resource Name (ARN) of the what-if analysis.
  --time-series-transformations: list # The transformations that are applied to the baseline time series. Each transformation contains an action and a set of conditions. An action is applied only when all conditions are met. If no conditions are provided, the action is applied to all items. — item shape: {Action?: record, TimeSeriesConditions?: list}
  --time-series-replacements-data-source: record # A replacement dataset is a modified version of the baseline related time series that contains only the values that you want to include in a what-if forecast. The replacement dataset must contain the forecast dimensions and item identifiers in the baseline related time series as well as at least 1 changed time series. This dataset is merged with the baseline related time series to create a transformed dataset that is used for the what-if forecast. — shape: {S3Config: record, Schema: record, Format?: string, TimestampFormat?: string}
  --tags: list # A list of tags (https://docs.aws.amazon.com/forecast/latest/dg/tagging-forecast-resources.html) to apply to the what if forecast. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateWhatIfForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfForecastName, var: what_if_forecast_name}, {name: WhatIfAnalysisArn, var: what_if_analysis_arn}, {name: TimeSeriesTransformations, var: time_series_transformations}, {name: TimeSeriesReplacementsDataSource, var: time_series_replacements_data_source}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_forecast_name: $what_if_forecast_name, what_if_analysis_arn: $what_if_analysis_arn, time_series_transformations: $time_series_transformations, time_series_replacements_data_source: $time_series_replacements_data_source, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports a forecast created by the CreateWhatIfForecast operation to your Amazon Simple Storage Service (Amazon S3) bucket. The forecast file name will match the following conventions: ≈<ForecastExportJobName>_<ExportTimestamp>_<PartNumber> The <ExportTimestamp> component is in Java SimpleDateFormat (yyyy-MM-ddTHH-mm-ssZ). You must specify a DataDestination object that includes an Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see aws-forecast-iam-roles. For more information, see howitworks-forecast. To get a list of all your what-if forecast export jobs, use the ListWhatIfForecastExports operation. The Status of the forecast export job must be ACTIVE before you can access the forecast in your Amazon S3 bucket. To get the status, use the DescribeWhatIfForecastExport operation.
#
# POST /
# Returns: record<WhatIfForecastExportArn: string>
# operationId: CreateWhatIfForecastExport
export def "create-what-if-forecast-export" [
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
  what_if_forecast_export_name: string # The name of the what-if forecast to export.
  what_if_forecast_arns: list<string> # The list of what-if forecast Amazon Resource Names (ARNs) to export.
  destination: record # The destination for an export job. Provide an S3 path, an Identity and Access Management (IAM) role that allows Amazon Forecast to access the location, and an Key Management Service (KMS) key (optional). — shape: {S3Config: record}
  --tags: list # A list of tags (https://docs.aws.amazon.com/forecast/latest/dg/tagging-forecast-resources.html) to apply to the what if forecast. — item shape: {Key: string, Value: string}
  --format: string # The format of the exported data, CSV or PARQUET.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.CreateWhatIfForecastExport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfForecastExportName, var: what_if_forecast_export_name}, {name: WhatIfForecastArns, var: what_if_forecast_arns}, {name: Destination, var: destination}, {name: Tags, var: tags}, {name: Format, var: format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_forecast_export_name: $what_if_forecast_export_name, what_if_forecast_arns: $what_if_forecast_arns, destination: $destination, tags: $tags, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon Forecast dataset that was created using the CreateDataset (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDataset.html) operation. You can only delete datasets that have a status of ACTIVE or CREATE_FAILED. To get the status use the DescribeDataset (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDataset.html) operation. Forecast does not automatically update any dataset groups that contain the deleted dataset. In order to update the dataset group, use the UpdateDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_UpdateDatasetGroup.html) operation, omitting the deleted dataset's ARN.
#
# POST /
# operationId: DeleteDataset
export def "delete-dataset" [
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
  dataset_arn: string # The Amazon Resource Name (ARN) of the dataset to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetArn, var: dataset_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_arn: $dataset_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dataset group created using the CreateDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDatasetGroup.html) operation. You can only delete dataset groups that have a status of ACTIVE, CREATE_FAILED, or UPDATE_FAILED. To get the status, use the DescribeDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDatasetGroup.html) operation. This operation deletes only the dataset group, not the datasets in the group.
#
# POST /
# operationId: DeleteDatasetGroup
export def "delete-dataset-group" [
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
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the dataset group to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteDatasetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetGroupArn, var: dataset_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dataset import job created using the CreateDatasetImportJob (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDatasetImportJob.html) operation. You can delete only dataset import jobs that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribeDatasetImportJob (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDatasetImportJob.html) operation.
#
# POST /
# operationId: DeleteDatasetImportJob
export def "delete-dataset-import-job" [
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
  dataset_import_job_arn: string # The Amazon Resource Name (ARN) of the dataset import job to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteDatasetImportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetImportJobArn, var: dataset_import_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_import_job_arn: $dataset_import_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Explainability resource. You can delete only predictor that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribeExplainability operation.
#
# POST /
# operationId: DeleteExplainability
export def "delete-explainability" [
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
  explainability_arn: string # The Amazon Resource Name (ARN) of the Explainability resource to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteExplainability"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExplainabilityArn, var: explainability_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, explainability_arn: $explainability_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Explainability export.
#
# POST /
# operationId: DeleteExplainabilityExport
export def "delete-explainability-export" [
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
  explainability_export_arn: string # The Amazon Resource Name (ARN) of the Explainability export to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteExplainabilityExport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExplainabilityExportArn, var: explainability_export_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, explainability_export_arn: $explainability_export_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a forecast created using the CreateForecast operation. You can delete only forecasts that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribeForecast operation. You can't delete a forecast while it is being exported. After a forecast is deleted, you can no longer query the forecast.
#
# POST /
# operationId: DeleteForecast
export def "delete-forecast" [
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
  forecast_arn: string # The Amazon Resource Name (ARN) of the forecast to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ForecastArn, var: forecast_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, forecast_arn: $forecast_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a forecast export job created using the CreateForecastExportJob operation. You can delete only export jobs that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribeForecastExportJob operation.
#
# POST /
# operationId: DeleteForecastExportJob
export def "delete-forecast-export-job" [
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
  forecast_export_job_arn: string # The Amazon Resource Name (ARN) of the forecast export job to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteForecastExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ForecastExportJobArn, var: forecast_export_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, forecast_export_job_arn: $forecast_export_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a monitor resource. You can only delete a monitor resource with a status of ACTIVE, ACTIVE_STOPPED, CREATE_FAILED, or CREATE_STOPPED.
#
# POST /
# operationId: DeleteMonitor
export def "delete-monitor" [
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
  monitor_arn: string # The Amazon Resource Name (ARN) of the monitor resource to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteMonitor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MonitorArn, var: monitor_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, monitor_arn: $monitor_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a predictor created using the DescribePredictor or CreatePredictor operations. You can delete only predictor that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribePredictor operation.
#
# POST /
# operationId: DeletePredictor
export def "delete-predictor" [
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
  predictor_arn: string # The Amazon Resource Name (ARN) of the predictor to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeletePredictor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorArn, var: predictor_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_arn: $predictor_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a predictor backtest export job.
#
# POST /
# operationId: DeletePredictorBacktestExportJob
export def "delete-predictor-backtest-export-job" [
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
  predictor_backtest_export_job_arn: string # The Amazon Resource Name (ARN) of the predictor backtest export job to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeletePredictorBacktestExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorBacktestExportJobArn, var: predictor_backtest_export_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_backtest_export_job_arn: $predictor_backtest_export_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an entire resource tree. This operation will delete the parent resource and its child resources. Child resources are resources that were created from another resource. For example, when a forecast is generated from a predictor, the forecast is the child resource and the predictor is the parent resource. Amazon Forecast resources possess the following parent-child resource hierarchies: Dataset: dataset import jobs Dataset Group: predictors, predictor backtest export jobs, forecasts, forecast export jobs Predictor: predictor backtest export jobs, forecasts, forecast export jobs Forecast: forecast export jobs DeleteResourceTree will only delete Amazon Forecast resources, and will not delete datasets or exported files stored in Amazon S3.
#
# POST /
# operationId: DeleteResourceTree
export def "delete-resource-tree" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the parent resource to delete. All child resources of the parent resource will also be deleted.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteResourceTree"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a what-if analysis created using the CreateWhatIfAnalysis operation. You can delete only what-if analyses that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribeWhatIfAnalysis operation. You can't delete a what-if analysis while any of its forecasts are being exported.
#
# POST /
# operationId: DeleteWhatIfAnalysis
export def "delete-what-if-analysis" [
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
  what_if_analysis_arn: string # The Amazon Resource Name (ARN) of the what-if analysis that you want to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteWhatIfAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfAnalysisArn, var: what_if_analysis_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_analysis_arn: $what_if_analysis_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a what-if forecast created using the CreateWhatIfForecast operation. You can delete only what-if forecasts that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribeWhatIfForecast operation. You can't delete a what-if forecast while it is being exported. After a what-if forecast is deleted, you can no longer query the what-if analysis.
#
# POST /
# operationId: DeleteWhatIfForecast
export def "delete-what-if-forecast" [
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
  what_if_forecast_arn: string # The Amazon Resource Name (ARN) of the what-if forecast that you want to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteWhatIfForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfForecastArn, var: what_if_forecast_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_forecast_arn: $what_if_forecast_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a what-if forecast export created using the CreateWhatIfForecastExport operation. You can delete only what-if forecast exports that have a status of ACTIVE or CREATE_FAILED. To get the status, use the DescribeWhatIfForecastExport operation.
#
# POST /
# operationId: DeleteWhatIfForecastExport
export def "delete-what-if-forecast-export" [
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
  what_if_forecast_export_arn: string # The Amazon Resource Name (ARN) of the what-if forecast export that you want to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DeleteWhatIfForecastExport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfForecastExportArn, var: what_if_forecast_export_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_forecast_export_arn: $what_if_forecast_export_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a predictor created using the CreateAutoPredictor operation.
#
# POST /
# Returns: record<PredictorArn: string, PredictorName: string, ForecastHorizon: int, ForecastTypes: list<string>, ForecastFrequency: string, ForecastDimensions: list<string>, DatasetImportJobArns: list<string>, DataConfig: record<DatasetGroupArn: string, AttributeConfigs: list<record>, AdditionalDatasets: list<record>>, EncryptionConfig: record<RoleArn: string, KMSKeyArn: string>, ReferencePredictorSummary: record<Arn: string, State: string>, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, OptimizationMetric: string, ExplainabilityInfo: record<ExplainabilityArn: string, Status: string>, MonitorInfo: record<MonitorArn: string, Status: string>, TimeAlignmentBoundary: record<Month: string, DayOfMonth: int, DayOfWeek: string, Hour: int>>
# operationId: DescribeAutoPredictor
export def "describe-auto-predictor" [
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
  predictor_arn: string # The Amazon Resource Name (ARN) of the predictor.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeAutoPredictor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorArn, var: predictor_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_arn: $predictor_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an Amazon Forecast dataset created using the CreateDataset (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDataset.html) operation. In addition to listing the parameters specified in the CreateDataset request, this operation includes the following dataset properties: CreationTime LastModificationTime Status
#
# POST /
# Returns: record<DatasetArn: string, DatasetName: string, Domain: string, DatasetType: string, DataFrequency: string, Schema: record<Attributes: list<record>>, EncryptionConfig: record<RoleArn: string, KMSKeyArn: string>, Status: string, CreationTime: string, LastModificationTime: string>
# operationId: DescribeDataset
export def "describe-dataset" [
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
  dataset_arn: string # The Amazon Resource Name (ARN) of the dataset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetArn, var: dataset_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_arn: $dataset_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a dataset group created using the CreateDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDatasetGroup.html) operation. In addition to listing the parameters provided in the CreateDatasetGroup request, this operation includes the following properties: DatasetArns - The datasets belonging to the group. CreationTime LastModificationTime Status
#
# POST /
# Returns: record<DatasetGroupName: string, DatasetGroupArn: string, DatasetArns: list<string>, Domain: string, Status: string, CreationTime: string, LastModificationTime: string>
# operationId: DescribeDatasetGroup
export def "describe-dataset-group" [
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
  dataset_group_arn: string # The Amazon Resource Name (ARN) of the dataset group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeDatasetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetGroupArn, var: dataset_group_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a dataset import job created using the CreateDatasetImportJob (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDatasetImportJob.html) operation. In addition to listing the parameters provided in the CreateDatasetImportJob request, this operation includes the following properties: CreationTime LastModificationTime DataSize FieldStatistics Status Message - If an error occurred, information about the error.
#
# POST /
# Returns: record<DatasetImportJobName: string, DatasetImportJobArn: string, DatasetArn: string, TimestampFormat: string, TimeZone: string, UseGeolocationForTimeZone: bool, GeolocationFormat: string, DataSource: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, EstimatedTimeRemainingInMinutes: int, FieldStatistics: record, DataSize: float, Status: string, Message: string, CreationTime: string, LastModificationTime: string, Format: string, ImportMode: string>
# operationId: DescribeDatasetImportJob
export def "describe-dataset-import-job" [
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
  dataset_import_job_arn: string # The Amazon Resource Name (ARN) of the dataset import job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeDatasetImportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetImportJobArn, var: dataset_import_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_import_job_arn: $dataset_import_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an Explainability resource created using the CreateExplainability operation.
#
# POST /
# Returns: record<ExplainabilityArn: string, ExplainabilityName: string, ResourceArn: string, ExplainabilityConfig: record<TimeSeriesGranularity: string, TimePointGranularity: string>, EnableVisualization: bool, DataSource: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Schema: record<Attributes: list<record>>, StartDateTime: string, EndDateTime: string, EstimatedTimeRemainingInMinutes: int, Message: string, Status: string, CreationTime: string, LastModificationTime: string>
# operationId: DescribeExplainability
export def "describe-explainability" [
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
  explainability_arn: string # The Amazon Resource Name (ARN) of the Explaianability to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeExplainability"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExplainabilityArn, var: explainability_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, explainability_arn: $explainability_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an Explainability export created using the CreateExplainabilityExport operation.
#
# POST /
# Returns: record<ExplainabilityExportArn: string, ExplainabilityExportName: string, ExplainabilityArn: string, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, LastModificationTime: string, Format: string>
# operationId: DescribeExplainabilityExport
export def "describe-explainability-export" [
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
  explainability_export_arn: string # The Amazon Resource Name (ARN) of the Explainability export.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeExplainabilityExport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExplainabilityExportArn, var: explainability_export_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, explainability_export_arn: $explainability_export_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a forecast created using the CreateForecast operation. In addition to listing the properties provided in the CreateForecast request, this operation lists the following properties: DatasetGroupArn - The dataset group that provided the training data. CreationTime LastModificationTime Status Message - If an error occurred, information about the error.
#
# POST /
# Returns: record<ForecastArn: string, ForecastName: string, ForecastTypes: list<string>, PredictorArn: string, DatasetGroupArn: string, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, TimeSeriesSelector: record<TimeSeriesIdentifiers: record<DataSource: record, Schema: record, Format: string>>>
# operationId: DescribeForecast
export def "describe-forecast" [
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
  forecast_arn: string # The Amazon Resource Name (ARN) of the forecast.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ForecastArn, var: forecast_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, forecast_arn: $forecast_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a forecast export job created using the CreateForecastExportJob operation. In addition to listing the properties provided by the user in the CreateForecastExportJob request, this operation lists the following properties: CreationTime LastModificationTime Status Message - If an error occurred, information about the error.
#
# POST /
# Returns: record<ForecastExportJobArn: string, ForecastExportJobName: string, ForecastArn: string, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, LastModificationTime: string, Format: string>
# operationId: DescribeForecastExportJob
export def "describe-forecast-export-job" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  forecast_export_job_arn: string # The Amazon Resource Name (ARN) of the forecast export job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeForecastExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ForecastExportJobArn, var: forecast_export_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, forecast_export_job_arn: $forecast_export_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a monitor resource. In addition to listing the properties provided in the CreateMonitor request, this operation lists the following properties: Baseline CreationTime LastEvaluationTime LastEvaluationState LastModificationTime Message Status
#
# POST /
# Returns: record<MonitorName: string, MonitorArn: string, ResourceArn: string, Status: string, LastEvaluationTime: string, LastEvaluationState: string, Baseline: record<PredictorBaseline: record<BaselineMetrics: list>>, Message: string, CreationTime: string, LastModificationTime: string, EstimatedEvaluationTimeRemainingInMinutes: int>
# operationId: DescribeMonitor
export def "describe-monitor" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  monitor_arn: string # The Amazon Resource Name (ARN) of the monitor resource to describe.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeMonitor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MonitorArn, var: monitor_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, monitor_arn: $monitor_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation is only valid for legacy predictors created with CreatePredictor. If you are not using a legacy predictor, use DescribeAutoPredictor. Describes a predictor created using the CreatePredictor operation. In addition to listing the properties provided in the CreatePredictor request, this operation lists the following properties: DatasetImportJobArns - The dataset import jobs used to import training data. AutoMLAlgorithmArns - If AutoML is performed, the algorithms that were evaluated. CreationTime LastModificationTime Status Message - If an error occurred, information about the error.
#
# POST /
# Returns: record<PredictorArn: string, PredictorName: string, AlgorithmArn: string, AutoMLAlgorithmArns: list<string>, ForecastHorizon: int, ForecastTypes: list<string>, PerformAutoML: bool, AutoMLOverrideStrategy: string, PerformHPO: bool, TrainingParameters: record, EvaluationParameters: record<NumberOfBacktestWindows: int, BackTestWindowOffset: int>, HPOConfig: record<ParameterRanges: record<CategoricalParameterRanges: list, ContinuousParameterRanges: list, IntegerParameterRanges: list>>, InputDataConfig: record<DatasetGroupArn: string, SupplementaryFeatures: list<record>>, FeaturizationConfig: record<ForecastFrequency: string, ForecastDimensions: list<string>, Featurizations: list<record>>, EncryptionConfig: record<RoleArn: string, KMSKeyArn: string>, PredictorExecutionDetails: record<PredictorExecutions: list<record>>, EstimatedTimeRemainingInMinutes: int, IsAutoPredictor: bool, DatasetImportJobArns: list<string>, Status: string, Message: string, CreationTime: string, LastModificationTime: string, OptimizationMetric: string>
# operationId: DescribePredictor
export def "describe-predictor" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  predictor_arn: string # The Amazon Resource Name (ARN) of the predictor that you want information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribePredictor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorArn, var: predictor_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_arn: $predictor_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a predictor backtest export job created using the CreatePredictorBacktestExportJob operation. In addition to listing the properties provided by the user in the CreatePredictorBacktestExportJob request, this operation lists the following properties: CreationTime LastModificationTime Status Message (if an error occurred)
#
# POST /
# Returns: record<PredictorBacktestExportJobArn: string, PredictorBacktestExportJobName: string, PredictorArn: string, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, LastModificationTime: string, Format: string>
# operationId: DescribePredictorBacktestExportJob
export def "describe-predictor-backtest-export-job" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  predictor_backtest_export_job_arn: string # The Amazon Resource Name (ARN) of the predictor backtest export job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribePredictorBacktestExportJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorBacktestExportJobArn, var: predictor_backtest_export_job_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_backtest_export_job_arn: $predictor_backtest_export_job_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the what-if analysis created using the CreateWhatIfAnalysis operation. In addition to listing the properties provided in the CreateWhatIfAnalysis request, this operation lists the following properties: CreationTime LastModificationTime Message - If an error occurred, information about the error. Status
#
# POST /
# Returns: record<WhatIfAnalysisName: string, WhatIfAnalysisArn: string, ForecastArn: string, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, TimeSeriesSelector: record<TimeSeriesIdentifiers: record<DataSource: record, Schema: record, Format: string>>>
# operationId: DescribeWhatIfAnalysis
export def "describe-what-if-analysis" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  what_if_analysis_arn: string # The Amazon Resource Name (ARN) of the what-if analysis that you are interested in.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeWhatIfAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfAnalysisArn, var: what_if_analysis_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_analysis_arn: $what_if_analysis_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the what-if forecast created using the CreateWhatIfForecast operation. In addition to listing the properties provided in the CreateWhatIfForecast request, this operation lists the following properties: CreationTime LastModificationTime Message - If an error occurred, information about the error. Status
#
# POST /
# Returns: record<WhatIfForecastName: string, WhatIfForecastArn: string, WhatIfAnalysisArn: string, EstimatedTimeRemainingInMinutes: int, Status: string, Message: string, CreationTime: string, LastModificationTime: string, TimeSeriesTransformations: table<Action: record, TimeSeriesConditions: list>, TimeSeriesReplacementsDataSource: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>, Schema: record<Attributes: list>, Format: string, TimestampFormat: string>, ForecastTypes: list<string>>
# operationId: DescribeWhatIfForecast
export def "describe-what-if-forecast" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  what_if_forecast_arn: string # The Amazon Resource Name (ARN) of the what-if forecast that you are interested in.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeWhatIfForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfForecastArn, var: what_if_forecast_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_forecast_arn: $what_if_forecast_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the what-if forecast export created using the CreateWhatIfForecastExport operation. In addition to listing the properties provided in the CreateWhatIfForecastExport request, this operation lists the following properties: CreationTime LastModificationTime Message - If an error occurred, information about the error. Status
#
# POST /
# Returns: record<WhatIfForecastExportArn: string, WhatIfForecastExportName: string, WhatIfForecastArns: list<string>, Destination: record<S3Config: record<Path: string, RoleArn: string, KMSKeyArn: string>>, Message: string, Status: string, CreationTime: string, EstimatedTimeRemainingInMinutes: int, LastModificationTime: string, Format: string>
# operationId: DescribeWhatIfForecastExport
export def "describe-what-if-forecast-export" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  what_if_forecast_export_arn: string # The Amazon Resource Name (ARN) of the what-if forecast export that you are interested in.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.DescribeWhatIfForecastExport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WhatIfForecastExportArn, var: what_if_forecast_export_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, what_if_forecast_export_arn: $what_if_forecast_export_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides metrics on the accuracy of the models that were trained by the CreatePredictor operation. Use metrics to see how well the model performed and to decide whether to use the predictor to generate a forecast. For more information, see Predictor Metrics (https://docs.aws.amazon.com/forecast/latest/dg/metrics.html). This operation generates metrics for each backtest window that was evaluated. The number of backtest windows (NumberOfBacktestWindows) is specified using the EvaluationParameters object, which is optionally included in the CreatePredictor request. If NumberOfBacktestWindows isn't specified, the number defaults to one. The parameters of the filling method determine which items contribute to the metrics. If you want all items to contribute, specify zero. If you want only those items that have complete data in the range being evaluated to contribute, specify nan. For more information, see FeaturizationMethod. Before you can get accuracy metrics, the Status of the predictor must be ACTIVE, signifying that training has completed. To get the status, use the DescribePredictor operation.
#
# POST /
# Returns: record<PredictorEvaluationResults: table<AlgorithmArn: string, TestWindows: list>, IsAutoPredictor: bool, AutoMLOverrideStrategy: string, OptimizationMetric: string>
# operationId: GetAccuracyMetrics
export def "get-accuracy-metrics" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  predictor_arn: string # The Amazon Resource Name (ARN) of the predictor to get metrics for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.GetAccuracyMetrics"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PredictorArn, var: predictor_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, predictor_arn: $predictor_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of dataset groups created using the CreateDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDatasetGroup.html) operation. For each dataset group, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the dataset group ARN with the DescribeDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDatasetGroup.html) operation.
#
# POST /
# Returns: record<DatasetGroups: table<DatasetGroupArn: string, DatasetGroupName: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListDatasetGroups
export def "list-dataset-groups" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListDatasetGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of dataset import jobs created using the CreateDatasetImportJob (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDatasetImportJob.html) operation. For each import job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the DescribeDatasetImportJob (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDatasetImportJob.html) operation. You can filter the list by providing an array of Filter (https://docs.aws.amazon.com/forecast/latest/dg/API_Filter.html) objects.
#
# POST /
# Returns: record<DatasetImportJobs: table<DatasetImportJobArn: string, DatasetImportJobName: string, DataSource: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string, ImportMode: string>, NextToken: string>
# operationId: ListDatasetImportJobs
export def "list-dataset-import-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, you provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the datasets that match the statement from the list, respectively. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the datasets that match the statement, specify IS. To exclude matching datasets, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are DatasetArn and Status. Value - The value to match. For example, to list all dataset import jobs whose status is ACTIVE, you specify the following filter: "Filters": [ { "Condition": "IS", "Key": "Status", "Value": "ACTIVE" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListDatasetImportJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of datasets created using the CreateDataset (https://docs.aws.amazon.com/forecast/latest/dg/API_CreateDataset.html) operation. For each dataset, a summary of its properties, including its Amazon Resource Name (ARN), is returned. To retrieve the complete set of properties, use the ARN with the DescribeDataset (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDataset.html) operation.
#
# POST /
# Returns: record<Datasets: table<DatasetArn: string, DatasetName: string, DatasetType: string, Domain: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListDatasets
export def "list-datasets" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListDatasets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Explainability resources created using the CreateExplainability operation. This operation returns a summary for each Explainability. You can filter the list using an array of Filter objects. To retrieve the complete set of properties for a particular Explainability resource, use the ARN with the DescribeExplainability operation.
#
# POST /
# Returns: record<Explainabilities: table<ExplainabilityArn: string, ExplainabilityName: string, ResourceArn: string, ExplainabilityConfig: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListExplainabilities
export def "list-explainabilities" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items returned in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the resources that match the statement from the list. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. Key - The name of the parameter to filter on. Valid values are ResourceArn and Status. Value - The value to match. — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListExplainabilities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Explainability exports created using the CreateExplainabilityExport operation. This operation returns a summary for each Explainability export. You can filter the list using an array of Filter objects. To retrieve the complete set of properties for a particular Explainability export, use the ARN with the DescribeExplainability operation.
#
# POST /
# Returns: record<ExplainabilityExports: table<ExplainabilityExportArn: string, ExplainabilityExportName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListExplainabilityExports
export def "list-explainability-exports" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude resources that match the statement from the list. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. Key - The name of the parameter to filter on. Valid values are ResourceArn and Status. Value - The value to match. — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListExplainabilityExports"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of forecast export jobs created using the CreateForecastExportJob operation. For each forecast export job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, use the ARN with the DescribeForecastExportJob operation. You can filter the list using an array of Filter objects.
#
# POST /
# Returns: record<ForecastExportJobs: table<ForecastExportJobArn: string, ForecastExportJobName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListForecastExportJobs
export def "list-forecast-export-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, you provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the forecast export jobs that match the statement from the list, respectively. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the forecast export jobs that match the statement, specify IS. To exclude matching forecast export jobs, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are ForecastArn and Status. Value - The value to match. For example, to list all jobs that export a forecast named electricityforecast, specify the following filter: "Filters": [ { "Condition": "IS", "Key": "ForecastArn", "Value": "arn:aws:forecast:us-west-2:<acct-id>:forecast/electricityforecast" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListForecastExportJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of forecasts created using the CreateForecast operation. For each forecast, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, specify the ARN with the DescribeForecast operation. You can filter the list using an array of Filter objects.
#
# POST /
# Returns: record<Forecasts: table<ForecastArn: string, ForecastName: string, PredictorArn: string, CreatedUsingAutoPredictor: bool, DatasetGroupArn: string, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListForecasts
export def "list-forecasts" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, you provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the forecasts that match the statement from the list, respectively. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the forecasts that match the statement, specify IS. To exclude matching forecasts, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are DatasetGroupArn, PredictorArn, and Status. Value - The value to match. For example, to list all forecasts whose status is not ACTIVE, you would specify: "Filters": [ { "Condition": "IS_NOT", "Key": "Status", "Value": "ACTIVE" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListForecasts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the monitoring evaluation results and predictor events collected by the monitor resource during different windows of time. For information about monitoring see predictor-monitoring. For more information about retrieving monitoring results see Viewing Monitoring Results (https://docs.aws.amazon.com/forecast/latest/dg/predictor-monitoring-results.html).
#
# POST /
# Returns: record<NextToken: string, PredictorMonitorEvaluations: table<ResourceArn: string, MonitorArn: string, EvaluationTime: string, EvaluationState: string, WindowStartDatetime: string, WindowEndDatetime: string, PredictorEvent: record, MonitorDataSource: record, MetricResults: list, NumItemsEvaluated: int, Message: string>>
# operationId: ListMonitorEvaluations
export def "list-monitor-evaluations" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The maximum number of monitoring results to return. (spec name: MaxResults)
  monitor_arn: string # The Amazon Resource Name (ARN) of the monitor resource to get results from.
  --filters: list # An array of filters. For each filter, provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the resources that match the statement from the list. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. Key - The name of the parameter to filter on. The only valid value is EvaluationState. Value - The value to match. Valid values are only SUCCESS or FAILURE. For example, to list only successful monitor evaluations, you would specify: "Filters": [ { "Condition": "IS", "Key": "EvaluationState", "Value": "SUCCESS" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListMonitorEvaluations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: MonitorArn, var: monitor_arn}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, monitor_arn: $monitor_arn, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of monitors created with the CreateMonitor operation and CreateAutoPredictor operation. For each monitor resource, this operation returns of a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve a complete set of properties of a monitor resource by specify the monitor's ARN in the DescribeMonitor operation.
#
# POST /
# Returns: record<Monitors: table<MonitorArn: string, MonitorName: string, ResourceArn: string, Status: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListMonitors
export def "list-monitors" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The maximum number of monitors to include in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the resources that match the statement from the list. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. Key - The name of the parameter to filter on. The only valid value is Status. Value - The value to match. For example, to list all monitors who's status is ACTIVE, you would specify: "Filters": [ { "Condition": "IS", "Key": "Status", "Value": "ACTIVE" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListMonitors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of predictor backtest export jobs created using the CreatePredictorBacktestExportJob operation. This operation returns a summary for each backtest export job. You can filter the list using an array of Filter objects. To retrieve the complete set of properties for a particular backtest export job, use the ARN with the DescribePredictorBacktestExportJob operation.
#
# POST /
# Returns: record<PredictorBacktestExportJobs: table<PredictorBacktestExportJobArn: string, PredictorBacktestExportJobName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListPredictorBacktestExportJobs
export def "list-predictor-backtest-export-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the predictor backtest export jobs that match the statement from the list. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the predictor backtest export jobs that match the statement, specify IS. To exclude matching predictor backtest export jobs, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are PredictorArn and Status. Value - The value to match. — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListPredictorBacktestExportJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of predictors created using the CreateAutoPredictor or CreatePredictor operations. For each predictor, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the DescribeAutoPredictor and DescribePredictor operations. You can filter the list using an array of Filter objects.
#
# POST /
# Returns: record<Predictors: table<PredictorArn: string, PredictorName: string, DatasetGroupArn: string, IsAutoPredictor: bool, ReferencePredictorSummary: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListPredictors
export def "list-predictors" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, you provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the predictors that match the statement from the list, respectively. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the predictors that match the statement, specify IS. To exclude matching predictors, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are DatasetGroupArn and Status. Value - The value to match. For example, to list all predictors whose status is ACTIVE, you would specify: "Filters": [ { "Condition": "IS", "Key": "Status", "Value": "ACTIVE" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListPredictors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for an Amazon Forecast resource.
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource for which to list the tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of what-if analyses created using the CreateWhatIfAnalysis operation. For each what-if analysis, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the what-if analysis ARN with the DescribeWhatIfAnalysis operation.
#
# POST /
# Returns: record<WhatIfAnalyses: table<WhatIfAnalysisArn: string, WhatIfAnalysisName: string, ForecastArn: string, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListWhatIfAnalyses
export def "list-what-if-analyses" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, you provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the what-if analysis jobs that match the statement from the list, respectively. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the what-if analysis jobs that match the statement, specify IS. To exclude matching what-if analysis jobs, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are WhatIfAnalysisArn and Status. Value - The value to match. For example, to list all jobs that export a forecast named electricityWhatIf, specify the following filter: "Filters": [ { "Condition": "IS", "Key": "WhatIfAnalysisArn", "Value": "arn:aws:forecast:us-west-2:<acct-id>:forecast/electricityWhatIf" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListWhatIfAnalyses"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of what-if forecast exports created using the CreateWhatIfForecastExport operation. For each what-if forecast export, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the what-if forecast export ARN with the DescribeWhatIfForecastExport operation.
#
# POST /
# Returns: record<WhatIfForecastExports: table<WhatIfForecastExportArn: string, WhatIfForecastArns: list, WhatIfForecastExportName: string, Destination: record, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListWhatIfForecastExports
export def "list-what-if-forecast-exports" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next&#x2028; request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, you provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the what-if forecast export jobs that match the statement from the list, respectively. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the forecast export jobs that match the statement, specify IS. To exclude matching forecast export jobs, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are WhatIfForecastExportArn and Status. Value - The value to match. For example, to list all jobs that export a forecast named electricityWIFExport, specify the following filter: "Filters": [ { "Condition": "IS", "Key": "WhatIfForecastExportArn", "Value": "arn:aws:forecast:us-west-2:<acct-id>:forecast/electricityWIFExport" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListWhatIfForecastExports"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of what-if forecasts created using the CreateWhatIfForecast operation. For each what-if forecast, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the what-if forecast ARN with the DescribeWhatIfForecast operation.
#
# POST /
# Returns: record<WhatIfForecasts: table<WhatIfForecastArn: string, WhatIfForecastName: string, WhatIfAnalysisArn: string, Status: string, Message: string, CreationTime: string, LastModificationTime: string>, NextToken: string>
# operationId: ListWhatIfForecasts
export def "list-what-if-forecasts" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  --body-next-token: string # If the result of the previous request was truncated, the response includes a NextToken. To retrieve the next set of results, use the token in the next&#x2028; request. Tokens expire after 24 hours. (spec name: NextToken)
  --body-max-results: int # The number of items to return in the response. (spec name: MaxResults)
  --filters: list # An array of filters. For each filter, you provide a condition and a match statement. The condition is either IS or IS_NOT, which specifies whether to include or exclude the what-if forecast export jobs that match the statement from the list, respectively. The match statement consists of a key and a value. Filter properties Condition - The condition to apply. Valid values are IS and IS_NOT. To include the forecast export jobs that match the statement, specify IS. To exclude matching forecast export jobs, specify IS_NOT. Key - The name of the parameter to filter on. Valid values are WhatIfForecastArn and Status. Value - The value to match. For example, to list all jobs that export a forecast named electricityWhatIfForecast, specify the following filter: "Filters": [ { "Condition": "IS", "Key": "WhatIfForecastArn", "Value": "arn:aws:forecast:us-west-2:<acct-id>:forecast/electricityWhatIfForecast" } ] — item shape: {Key: string, Value: string, Condition: "IS"|"IS_NOT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ListWhatIfForecasts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes a stopped monitor resource.
#
# POST /
# operationId: ResumeResource
export def "resume-resource" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the monitor resource to resume.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.ResumeResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a resource. The resource undergoes the following states: CREATE_STOPPING and CREATE_STOPPED. You cannot resume a resource once it has been stopped. This operation can be applied to the following resources (and their corresponding child resources): Dataset Import Job Predictor Job Forecast Job Forecast Export Job Predictor Backtest Export Job Explainability Job Explainability Export Job
#
# POST /
# operationId: StopResource
export def "stop-resource" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource to stop. The supported ARNs are DatasetImportJobArn, PredictorArn, PredictorBacktestExportJobArn, ForecastArn, ForecastExportJobArn, ExplainabilityArn, and ExplainabilityExportArn.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.StopResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are also deleted.
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource for which to list the tags.
  tags: list # The tags to add to the resource. A tag is an array of key-value pairs. The following basic restrictions apply to tags: Maximum number of tags per resource - 50. For each resource, each tag key must be unique, and each tag key can have only one value. Maximum key length - 128 Unicode characters in UTF-8. Maximum value length - 256 Unicode characters in UTF-8. If your tagging schema is used across multiple services and resources, remember that other services may have restrictions on allowed characters. Generally allowed characters are: letters, numbers, and spaces representable in UTF-8, and the following characters: + - = . _ : / @. Tag keys and values are case sensitive. Do not use aws:, AWS:, or any upper or lowercase combination of such as a prefix for keys as it is reserved for Amazon Web Services use. You cannot edit or delete tag keys with this prefix. Values can have this prefix. If a tag value has aws as its prefix but the key does not, then Forecast considers it to be a user tag and will count against the limit of 50 tags. Tags with only the key prefix of aws do not count against your tags per resource limit. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified tags from a resource.
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource for which to list the tags.
  tag_keys: list<string> # The keys of the tags to be removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the datasets in a dataset group with the specified datasets. The Status of the dataset group must be ACTIVE before you can use the dataset group to create a predictor. Use the DescribeDatasetGroup (https://docs.aws.amazon.com/forecast/latest/dg/API_DescribeDatasetGroup.html) operation to get the status.
#
# POST /
# Returns: record
# operationId: UpdateDatasetGroup
export def "update-dataset-group" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  dataset_group_arn: string # The ARN of the dataset group.
  dataset_arns: list<string> # An array of the Amazon Resource Names (ARNs) of the datasets to add to the dataset group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonForecast.UpdateDatasetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetGroupArn, var: dataset_group_arn}, {name: DatasetArns, var: dataset_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_group_arn: $dataset_group_arn, dataset_arns: $dataset_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
