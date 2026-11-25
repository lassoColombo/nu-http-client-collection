# Auto-generated client for Amazon Connect Service v2017-08-08
# Source: https://api.apis.guru/v2/specs/amazonaws.com/connect/2017-08-08/openapi.json
# Auth: --token flag or $env.AMAZON_CONNECT_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://connect.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_CONNECT_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://connect.us-east-1.amazonaws.com" "http://connect.us-east-2.amazonaws.com" "http://connect.us-west-1.amazonaws.com" "http://connect.us-west-2.amazonaws.com" "http://connect.us-gov-west-1.amazonaws.com" "http://connect.us-gov-east-1.amazonaws.com" "http://connect.ca-central-1.amazonaws.com" "http://connect.eu-north-1.amazonaws.com" "http://connect.eu-west-1.amazonaws.com" "http://connect.eu-west-2.amazonaws.com" "http://connect.eu-west-3.amazonaws.com" "http://connect.eu-central-1.amazonaws.com" "http://connect.eu-south-1.amazonaws.com" "http://connect.af-south-1.amazonaws.com" "http://connect.ap-northeast-1.amazonaws.com" "http://connect.ap-northeast-2.amazonaws.com" "http://connect.ap-northeast-3.amazonaws.com" "http://connect.ap-southeast-1.amazonaws.com" "http://connect.ap-southeast-2.amazonaws.com" "http://connect.ap-east-1.amazonaws.com" "http://connect.ap-south-1.amazonaws.com" "http://connect.sa-east-1.amazonaws.com" "http://connect.me-south-1.amazonaws.com" "https://connect.us-east-1.amazonaws.com" "https://connect.us-east-2.amazonaws.com" "https://connect.us-west-1.amazonaws.com" "https://connect.us-west-2.amazonaws.com" "https://connect.us-gov-west-1.amazonaws.com" "https://connect.us-gov-east-1.amazonaws.com" "https://connect.ca-central-1.amazonaws.com" "https://connect.eu-north-1.amazonaws.com" "https://connect.eu-west-1.amazonaws.com" "https://connect.eu-west-2.amazonaws.com" "https://connect.eu-west-3.amazonaws.com" "https://connect.eu-central-1.amazonaws.com" "https://connect.eu-south-1.amazonaws.com" "https://connect.af-south-1.amazonaws.com" "https://connect.ap-northeast-1.amazonaws.com" "https://connect.ap-northeast-2.amazonaws.com" "https://connect.ap-northeast-3.amazonaws.com" "https://connect.ap-southeast-1.amazonaws.com" "https://connect.ap-southeast-2.amazonaws.com" "https://connect.ap-east-1.amazonaws.com" "https://connect.ap-south-1.amazonaws.com" "https://connect.sa-east-1.amazonaws.com" "https://connect.me-south-1.amazonaws.com" "http://connect.cn-north-1.amazonaws.com.cn" "http://connect.cn-northwest-1.amazonaws.com.cn" "https://connect.cn-north-1.amazonaws.com.cn" "https://connect.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def language-code-completer [] { ["ar-AE" "de-CH" "de-DE" "en-AB" "en-AU" "en-GB" "en-IE" "en-IN" "en-NZ" "en-US" "en-WL" "en-ZA" "es-ES" "es-US" "fr-CA" "fr-FR" "hi-IN" "it-IT" "ja-JP" "ko-KR" "pt-BR" "pt-PT" "zh-CN"] }
def resource-type-completer [] { ["AGENT_EVENTS" "ATTACHMENTS" "CALL_RECORDINGS" "CHAT_TRANSCRIPTS" "CONTACT_EVALUATIONS" "CONTACT_TRACE_RECORDS" "MEDIA_STREAMS" "REAL_TIME_CONTACT_ANALYSIS_SEGMENTS" "SCHEDULED_REPORTS"] }
def state-completer [] { ["DISABLED" "ENABLED"] }
def type-completer [] { ["AGENT_HOLD" "AGENT_TRANSFER" "AGENT_WHISPER" "CONTACT_FLOW" "CUSTOMER_HOLD" "CUSTOMER_QUEUE" "CUSTOMER_WHISPER" "OUTBOUND_WHISPER" "QUEUE_TRANSFER"] }
def identity-management-type-completer [] { ["CONNECT_MANAGED" "EXISTING_DIRECTORY" "SAML"] }
def integration-type-completer [] { ["CASES_DOMAIN" "EVENT" "PINPOINT_APP" "VOICE_ID" "WISDOM_ASSISTANT" "WISDOM_KNOWLEDGE_BASE"] }
def source-type-completer [] { ["SALESFORCE" "ZENDESK"] }
def publish-status-completer [] { ["DRAFT" "PUBLISHED"] }
def event-source-name-completer [] { ["OnPostCallAnalysisAvailable" "OnPostChatAnalysisAvailable" "OnRealTimeCallAnalysisAvailable" "OnSalesforceCaseCreate" "OnZendeskTicketCreate" "OnZendeskTicketStatusUpdate"] }
def status-completer [] { ["ACTIVE" "INACTIVE"] }
def use-case-type-completer [] { ["CONNECT_CAMPAIGNS" "RULES_EVALUATION"] }
def attribute-type-completer [] { ["AUTO_RESOLVE_BEST_VOICES" "CONTACTFLOW_LOGS" "CONTACT_LENS" "EARLY_MEDIA" "ENHANCED_CONTACT_MONITORING" "HIGH_VOLUME_OUTBOUND" "INBOUND_CALLS" "MULTI_PARTY_CONFERENCE" "OUTBOUND_CALLS" "USE_CUSTOM_TTS_VOICES"] }
def lex-version-completer [] { ["V1" "V2"] }
def state-completer-1 [] { ["ACTIVE" "ARCHIVED"] }
def phone-number-country-code-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AN" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BR" "BS" "BT" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GG" "GH" "GI" "GL" "GM" "GN" "GQ" "GR" "GT" "GU" "GW" "GY" "HK" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def phone-number-type-completer [] { ["DID" "TOLL_FREE"] }
def state-completer-2 [] { ["ACTIVE" "CREATION_FAILED" "CREATION_IN_PROGRESS" "DELETE_IN_PROGRESS"] }
def traffic-type-completer [] { ["CAMPAIGN" "GENERAL"] }
def contact-flow-state-completer [] { ["ACTIVE" "ARCHIVED"] }
def status-completer-1 [] { ["DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-default-vocabulary: "record"
    associate-instance-storage-config: "record<AssociationId: string>"
    associate-security-key: "record<AssociationId: string>"
    claim-phone-number: "record<PhoneNumberId: string, PhoneNumberArn: string>"
    create-agent-status: "record<AgentStatusARN: string, AgentStatusId: string>"
    list-agent-statuses: "record<NextToken: string, AgentStatusSummaryList: table<Id: string, Arn: string, Name: string, Type: string>>"
    create-contact-flow: "record<ContactFlowId: string, ContactFlowArn: string>"
    create-contact-flow-module: "record<Id: string, Arn: string>"
    create-hours-of-operation: "record<HoursOfOperationId: string, HoursOfOperationArn: string>"
    create-instance: "record<Id: string, Arn: string>"
    list-instances: "record<InstanceSummaryList: table<Id: string, Arn: string, IdentityManagementType: string, InstanceAlias: string, CreatedTime: string, ServiceRole: string, InstanceStatus: string, InboundCallsEnabled: bool, OutboundCallsEnabled: bool>, NextToken: string>"
    create-integration-association: "record<IntegrationAssociationId: string, IntegrationAssociationArn: string>"
    list-integration-associations: "record<IntegrationAssociationSummaryList: table<IntegrationAssociationId: string, IntegrationAssociationArn: string, InstanceId: string, IntegrationType: string, IntegrationArn: string, SourceApplicationUrl: string, SourceApplicationName: string, SourceType: string>, NextToken: string>"
    create-participant: "record<ParticipantCredentials: record<ParticipantToken: string, Expiry: string>, ParticipantId: string>"
    create-queue: "record<QueueArn: string, QueueId: string>"
    create-quick-connect: "record<QuickConnectARN: string, QuickConnectId: string>"
    list-quick-connects: "record<QuickConnectSummaryList: table<Id: string, Arn: string, Name: string, QuickConnectType: string>, NextToken: string>"
    create-routing-profile: "record<RoutingProfileArn: string, RoutingProfileId: string>"
    create-rule: "record<RuleArn: string, RuleId: string>"
    list-rules: "record<RuleSummaryList: table<Name: string, RuleId: string, RuleArn: string, EventSourceName: string, PublishStatus: string, ActionSummaries: list, CreatedTime: string, LastUpdatedTime: string>, NextToken: string>"
    create-security-profile: "record<SecurityProfileId: string, SecurityProfileArn: string>"
    create-task-template: "record<Id: string, Arn: string>"
    list-task-templates: "record<TaskTemplates: table<Id: string, Arn: string, Name: string, Description: string, Status: string, LastModifiedTime: string, CreatedTime: string>, NextToken: string>"
    create-traffic-distribution-group: "record<Id: string, Arn: string>"
    create-use-case: "record<UseCaseId: string, UseCaseArn: string>"
    list-use-cases: "record<UseCaseSummaryList: table<UseCaseId: string, UseCaseArn: string, UseCaseType: string>, NextToken: string>"
    create-user: "record<UserId: string, UserArn: string>"
    create-user-hierarchy-group: "record<HierarchyGroupId: string, HierarchyGroupArn: string>"
    create-vocabulary: "record<VocabularyArn: string, VocabularyId: string, State: string>"
    delete-contact-flow: "record"
    describe-contact-flow: "record<ContactFlow: record<Arn: string, Id: string, Name: string, Type: string, State: string, Description: string, Content: string, Tags: record>>"
    delete-contact-flow-module: "record"
    describe-contact-flow-module: "record<ContactFlowModule: record<Arn: string, Id: string, Name: string, Content: string, Description: string, State: string, Status: string, Tags: record>>"
    describe-hours-of-operation: "record<HoursOfOperation: record<HoursOfOperationId: string, HoursOfOperationArn: string, Name: string, Description: string, TimeZone: string, Config: list<record>, Tags: record>>"
    describe-instance: "record<Instance: record<Id: string, Arn: string, IdentityManagementType: string, InstanceAlias: string, CreatedTime: string, ServiceRole: string, InstanceStatus: string, StatusReason: record<Message: string>, InboundCallsEnabled: bool, OutboundCallsEnabled: bool>>"
    describe-quick-connect: "record<QuickConnect: record<QuickConnectARN: string, QuickConnectId: string, Name: string, Description: string, QuickConnectConfig: record<QuickConnectType: string, UserConfig: record, QueueConfig: record, PhoneConfig: record>, Tags: record>>"
    describe-rule: "record<Rule: record<Name: string, RuleId: string, RuleArn: string, TriggerEventSource: record<EventSourceName: string, IntegrationAssociationId: string>, Function: string, Actions: list<record>, PublishStatus: string, CreatedTime: string, LastUpdatedTime: string, LastUpdatedBy: string, Tags: record>>"
    describe-security-profile: "record<SecurityProfile: record<Id: string, OrganizationResourceId: string, Arn: string, SecurityProfileName: string, Description: string, Tags: record, AllowedAccessControlTags: record, TagRestrictedResources: list<string>>>"
    delete-task-template: "record"
    get-task-template: "record<InstanceId: string, Id: string, Arn: string, Name: string, Description: string, ContactFlowId: string, Constraints: record<RequiredFields: list<record>, ReadOnlyFields: list<record>, InvisibleFields: list<record>>, Defaults: record<DefaultFieldValues: list<record>>, Fields: table<Id: record, Description: string, Type: string, SingleSelectOptions: list>, Status: string, LastModifiedTime: string, CreatedTime: string, Tags: record>"
    update-task-template: "record<InstanceId: string, Id: string, Arn: string, Name: string, Description: string, ContactFlowId: string, Constraints: record<RequiredFields: list<record>, ReadOnlyFields: list<record>, InvisibleFields: list<record>>, Defaults: record<DefaultFieldValues: list<record>>, Fields: table<Id: record, Description: string, Type: string, SingleSelectOptions: list>, Status: string, LastModifiedTime: string, CreatedTime: string>"
    delete-traffic-distribution-group: "record"
    describe-traffic-distribution-group: "record<TrafficDistributionGroup: record<Id: string, Arn: string, Name: string, Description: string, InstanceArn: string, Status: string, Tags: record>>"
    describe-user: "record<User: record<Id: string, Arn: string, Username: string, IdentityInfo: record<FirstName: string, LastName: string, Email: string, SecondaryEmail: string, Mobile: string>, PhoneConfig: record<PhoneType: string, AutoAccept: bool, AfterContactWorkTimeLimit: int, DeskPhoneNumber: string>, DirectoryUserId: string, SecurityProfileIds: list<string>, RoutingProfileId: string, HierarchyGroupId: string, Tags: record>>"
    describe-user-hierarchy-group: "record<HierarchyGroup: record<Id: string, Arn: string, Name: string, LevelId: string, HierarchyPath: record<LevelOne: record, LevelTwo: record, LevelThree: record, LevelFour: record, LevelFive: record>, Tags: record>>"
    delete-vocabulary: "record<VocabularyArn: string, VocabularyId: string, State: string>"
    describe-agent-status: "record<AgentStatus: record<AgentStatusARN: string, AgentStatusId: string, Name: string, Description: string, Type: string, DisplayOrder: int, State: string, Tags: record>>"
    describe-contact: "record<Contact: record<Arn: string, Id: string, InitialContactId: string, PreviousContactId: string, InitiationMethod: string, Name: string, Description: string, Channel: string, QueueInfo: record<Id: string, EnqueueTimestamp: string>, AgentInfo: record<Id: string, ConnectedToAgentTimestamp: string>, InitiationTimestamp: string, DisconnectTimestamp: string, LastUpdateTimestamp: string, ScheduledTimestamp: string, RelatedContactId: string, WisdomInfo: record<SessionArn: string>>>"
    update-contact: "record"
    describe-instance-attribute: "record<Attribute: record<AttributeType: string, Value: string>>"
    describe-instance-storage-config: "record<StorageConfig: record<AssociationId: string, StorageType: string, S3Config: record<BucketName: string, BucketPrefix: string, EncryptionConfig: record>, KinesisVideoStreamConfig: record<Prefix: string, RetentionPeriodHours: int, EncryptionConfig: record>, KinesisStreamConfig: record<StreamArn: string>, KinesisFirehoseConfig: record<FirehoseArn: string>>>"
    describe-phone-number: "record<ClaimedPhoneNumberSummary: record<PhoneNumberId: string, PhoneNumberArn: string, PhoneNumber: string, PhoneNumberCountryCode: string, PhoneNumberType: string, PhoneNumberDescription: string, TargetArn: string, Tags: record, PhoneNumberStatus: record<Status: string, Message: string>>>"
    update-phone-number: "record<PhoneNumberId: string, PhoneNumberArn: string>"
    describe-queue: "record<Queue: record<Name: string, QueueArn: string, QueueId: string, Description: string, OutboundCallerConfig: record<OutboundCallerIdName: string, OutboundCallerIdNumberId: string, OutboundFlowId: string>, HoursOfOperationId: string, MaxContacts: int, Status: string, Tags: record>>"
    describe-routing-profile: "record<RoutingProfile: record<InstanceId: string, Name: string, RoutingProfileArn: string, RoutingProfileId: string, Description: string, MediaConcurrencies: list<record>, DefaultOutboundQueueId: string, Tags: record, NumberOfAssociatedQueues: int, NumberOfAssociatedUsers: int>>"
    describe-user-hierarchy-structure: "record<HierarchyStructure: record<LevelOne: record<Id: string, Arn: string, Name: string>, LevelTwo: record<Id: string, Arn: string, Name: string>, LevelThree: record<Id: string, Arn: string, Name: string>, LevelFour: record<Id: string, Arn: string, Name: string>, LevelFive: record<Id: string, Arn: string, Name: string>>>"
    describe-vocabulary: "record<Vocabulary: record<Name: string, Id: string, Arn: string, LanguageCode: string, State: string, LastModifiedTime: string, FailureReason: string, Content: string, Tags: record>>"
    dismiss-user-contact: "record"
    get-contact-attributes: "record<Attributes: record>"
    get-current-metric-data: "record<NextToken: string, MetricResults: table<Dimensions: record, Collections: list>, DataSnapshotTime: string, ApproximateTotalCount: int>"
    get-current-user-data: "record<NextToken: string, UserDataList: table<User: record, RoutingProfile: record, HierarchyPath: record, Status: record, AvailableSlotsByChannel: record, MaxSlotsByChannel: record, ActiveSlotsByChannel: record, Contacts: list, NextStatus: string>, ApproximateTotalCount: int>"
    get-federation-token: "record<Credentials: record<AccessToken: string, AccessTokenExpiration: string, RefreshToken: string, RefreshTokenExpiration: string>, SignInUrl: string, UserArn: string, UserId: string>"
    get-metric-data: "record<NextToken: string, MetricResults: table<Dimensions: record, Collections: list>>"
    get-metric-data-v2: "record<NextToken: string, MetricResults: table<Dimensions: record, Collections: list>>"
    get-traffic-distribution: "record<TelephonyConfig: record<Distributions: list<record>>, Id: string, Arn: string>"
    update-traffic-distribution: "record"
    list-approved-origins: "record<Origins: list<string>, NextToken: string>"
    list-bots: "record<LexBots: table<LexBot: record, LexV2Bot: record>, NextToken: string>"
    list-contact-flow-modules: "record<ContactFlowModulesSummaryList: table<Id: string, Arn: string, Name: string, State: string>, NextToken: string>"
    list-contact-flows: "record<ContactFlowSummaryList: table<Id: string, Arn: string, Name: string, ContactFlowType: string, ContactFlowState: string>, NextToken: string>"
    list-contact-references: "record<ReferenceSummaryList: table<Url: record, Attachment: record, String: record, Number: record, Date: record, Email: record>, NextToken: string>"
    list-default-vocabularies: "record<DefaultVocabularyList: table<InstanceId: string, LanguageCode: string, VocabularyId: string, VocabularyName: string>, NextToken: string>"
    list-hours-of-operations: "record<HoursOfOperationSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>"
    list-instance-attributes: "record<Attributes: table<AttributeType: string, Value: string>, NextToken: string>"
    list-instance-storage-configs: "record<StorageConfigs: table<AssociationId: string, StorageType: string, S3Config: record, KinesisVideoStreamConfig: record, KinesisStreamConfig: record, KinesisFirehoseConfig: record>, NextToken: string>"
    list-lambda-functions: "record<LambdaFunctions: list<string>, NextToken: string>"
    list-lex-bots: "record<LexBots: table<Name: string, LexRegion: string>, NextToken: string>"
    list-phone-numbers: "record<PhoneNumberSummaryList: table<Id: string, Arn: string, PhoneNumber: string, PhoneNumberType: string, PhoneNumberCountryCode: string>, NextToken: string>"
    list-phone-numbers-v2: "record<NextToken: string, ListPhoneNumbersSummaryList: table<PhoneNumberId: string, PhoneNumberArn: string, PhoneNumber: string, PhoneNumberCountryCode: string, PhoneNumberType: string, TargetArn: string>>"
    list-prompts: "record<PromptSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>"
    list-queue-quick-connects: "record<NextToken: string, QuickConnectSummaryList: table<Id: string, Arn: string, Name: string, QuickConnectType: string>>"
    list-queues: "record<QueueSummaryList: table<Id: string, Arn: string, Name: string, QueueType: string>, NextToken: string>"
    list-routing-profile-queues: "record<NextToken: string, RoutingProfileQueueConfigSummaryList: table<QueueId: string, QueueArn: string, QueueName: string, Priority: int, Delay: int, Channel: string>>"
    list-routing-profiles: "record<RoutingProfileSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>"
    list-security-keys: "record<SecurityKeys: table<AssociationId: string, Key: string, CreationTime: string>, NextToken: string>"
    list-security-profile-permissions: "record<Permissions: list<string>, NextToken: string>"
    list-security-profiles: "record<SecurityProfileSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    list-traffic-distribution-groups: "record<NextToken: string, TrafficDistributionGroupSummaryList: table<Id: string, Arn: string, Name: string, InstanceArn: string, Status: string>>"
    list-user-hierarchy-groups: "record<UserHierarchyGroupSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>"
    list-users: "record<UserSummaryList: table<Id: string, Arn: string, Username: string>, NextToken: string>"
    monitor-contact: "record<ContactId: string, ContactArn: string>"
    put-user-status: "record"
    replicate-instance: "record<Id: string, Arn: string>"
    resume-contact-recording: "record"
    search-available-phone-numbers: "record<NextToken: string, AvailableNumbersList: table<PhoneNumber: string, PhoneNumberCountryCode: string, PhoneNumberType: string>>"
    search-queues: "record<Queues: table<Name: string, QueueArn: string, QueueId: string, Description: string, OutboundCallerConfig: record, HoursOfOperationId: string, MaxContacts: int, Status: string, Tags: record>, NextToken: string, ApproximateTotalCount: int>"
    search-routing-profiles: "record<RoutingProfiles: table<InstanceId: string, Name: string, RoutingProfileArn: string, RoutingProfileId: string, Description: string, MediaConcurrencies: list, DefaultOutboundQueueId: string, Tags: record, NumberOfAssociatedQueues: int, NumberOfAssociatedUsers: int>, NextToken: string, ApproximateTotalCount: int>"
    search-security-profiles: "record<SecurityProfiles: table<Id: string, OrganizationResourceId: string, Arn: string, SecurityProfileName: string, Description: string, Tags: record>, NextToken: string, ApproximateTotalCount: int>"
    search-users: "record<Users: table<Arn: string, DirectoryUserId: string, HierarchyGroupId: string, Id: string, IdentityInfo: record, PhoneConfig: record, RoutingProfileId: string, SecurityProfileIds: list, Tags: record, Username: string>, NextToken: string, ApproximateTotalCount: int>"
    search-vocabularies: "record<VocabularySummaryList: table<Name: string, Id: string, Arn: string, LanguageCode: string, State: string, LastModifiedTime: string, FailureReason: string>, NextToken: string>"
    start-chat-contact: "record<ContactId: string, ParticipantId: string, ParticipantToken: string, ContinuedFromContactId: string>"
    start-contact-recording: "record"
    start-contact-streaming: "record<StreamingId: string>"
    start-outbound-voice-contact: "record<ContactId: string>"
    start-task-contact: "record<ContactId: string>"
    stop-contact: "record"
    stop-contact-recording: "record"
    stop-contact-streaming: "record"
    suspend-contact-recording: "record"
    transfer-contact: "record<ContactId: string, ContactArn: string>"
    update-contact-attributes: "record"
    update-contact-flow-content: "record"
    update-contact-flow-metadata: "record"
    update-contact-flow-module-content: "record"
    update-contact-flow-module-metadata: "record"
    update-contact-flow-name: "record"
    update-contact-schedule: "record"
    update-participant-role-config: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-approved-origin" "associate-bot" "disassociate-bot" "associate-default-vocabulary" "associate-instance-storage-config" "associate-lambda-function" "associate-lex-bot" "associate-phone-number-contact-flow" "associate-queue-quick-connects" "associate-routing-profile-queues" "associate-security-key" "claim-phone-number" "create-agent-status" "list-agent-statuses" "create-contact-flow" "create-contact-flow-module" "create-hours-of-operation" "create-instance" "list-instances" "create-integration-association" "list-integration-associations" "create-participant" "create-queue" "create-quick-connect" "list-quick-connects" "create-routing-profile" "create-rule" "list-rules" "create-security-profile" "create-task-template" "list-task-templates" "create-traffic-distribution-group" "create-use-case" "list-use-cases" "create-user" "create-user-hierarchy-group" "create-vocabulary" "delete-contact-flow" "describe-contact-flow" "delete-contact-flow-module" "describe-contact-flow-module" "delete-hours-of-operation" "describe-hours-of-operation" "update-hours-of-operation" "delete-instance" "describe-instance" "delete-integration-association" "delete-quick-connect" "describe-quick-connect" "delete-rule" "describe-rule" "update-rule" "delete-security-profile" "describe-security-profile" "update-security-profile" "delete-task-template" "get-task-template" "update-task-template" "delete-traffic-distribution-group" "describe-traffic-distribution-group" "delete-use-case" "delete-user" "describe-user" "delete-user-hierarchy-group" "describe-user-hierarchy-group" "delete-vocabulary" "describe-agent-status" "update-agent-status" "describe-contact" "update-contact" "describe-instance-attribute" "update-instance-attribute" "describe-instance-storage-config" "disassociate-instance-storage-config" "update-instance-storage-config" "describe-phone-number" "release-phone-number" "update-phone-number" "describe-queue" "describe-routing-profile" "describe-user-hierarchy-structure" "update-user-hierarchy-structure" "describe-vocabulary" "disassociate-approved-origin" "disassociate-lambda-function" "disassociate-lex-bot" "disassociate-phone-number-contact-flow" "disassociate-queue-quick-connects" "disassociate-routing-profile-queues" "disassociate-security-key" "dismiss-user-contact" "get-contact-attributes" "get-current-metric-data" "get-current-user-data" "get-federation-token" "get-metric-data" "get-metric-data-v2" "get-traffic-distribution" "update-traffic-distribution" "list-approved-origins" "list-bots" "list-contact-flow-modules" "list-contact-flows" "list-contact-references" "list-default-vocabularies" "list-hours-of-operations" "list-instance-attributes" "list-instance-storage-configs" "list-lambda-functions" "list-lex-bots" "list-phone-numbers" "list-phone-numbers-v2" "list-prompts" "list-queue-quick-connects" "list-queues" "list-routing-profile-queues" "update-routing-profile-queues" "list-routing-profiles" "list-security-keys" "list-security-profile-permissions" "list-security-profiles" "list-tags-for-resource" "tag-resource" "list-traffic-distribution-groups" "list-user-hierarchy-groups" "list-users" "monitor-contact" "put-user-status" "replicate-instance" "resume-contact-recording" "search-available-phone-numbers" "search-queues" "search-routing-profiles" "search-security-profiles" "search-users" "search-vocabularies" "start-chat-contact" "start-contact-recording" "start-contact-streaming" "start-outbound-voice-contact" "start-task-contact" "stop-contact" "stop-contact-recording" "stop-contact-streaming" "suspend-contact-recording" "transfer-contact" "untag-resource" "update-contact-attributes" "update-contact-flow-content" "update-contact-flow-metadata" "update-contact-flow-module-content" "update-contact-flow-module-metadata" "update-contact-flow-name" "update-contact-schedule" "update-participant-role-config" "update-queue-hours-of-operation" "update-queue-max-contacts" "update-queue-name" "update-queue-outbound-caller-config" "update-queue-status" "update-quick-connect-config" "update-quick-connect-name" "update-routing-profile-concurrency" "update-routing-profile-default-outbound-queue" "update-routing-profile-name" "update-user-hierarchy" "update-user-hierarchy-group-name" "update-user-identity-info" "update-user-phone-config" "update-user-routing-profile" "update-user-security-profiles" "commands"] | sort) } | get name | first)
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

# This API is in preview release for Amazon Connect and is subject to change. Associates an approved origin to an Amazon Connect instance.
#
# PUT /instance/{InstanceId}/approved-origin
# operationId: AssociateApprovedOrigin
export def "associate-approved-origin" [
  instance_id: string
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
  origin: string # The domain to add to your allow list.
]: any -> any {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/approved-origin"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Origin, var: origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, origin: $origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Allows the specified Amazon Connect instance to access the specified Amazon Lex or Amazon Lex V2 bot.
#
# PUT /instance/{InstanceId}/bot
# operationId: AssociateBot
export def "associate-bot" [
  instance_id: string
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
  --lex-bot: record # Configuration information of an Amazon Lex bot. — shape: {Name?: string, LexRegion?: string}
  --lex-v2-bot: record # Configuration information of an Amazon Lex V2 bot. — shape: {AliasArn?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/bot"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LexBot, var: lex_bot}, {name: LexV2Bot, var: lex_v2_bot}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lex_bot: $lex_bot, lex_v2_bot: $lex_v2_bot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Revokes authorization from the specified instance to access the specified Amazon Lex or Amazon Lex V2 bot.
#
# POST /instance/{InstanceId}/bot
# operationId: DisassociateBot
export def "disassociate-bot" [
  instance_id: string
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
  --lex-bot: record # Configuration information of an Amazon Lex bot. — shape: {Name?: string, LexRegion?: string}
  --lex-v2-bot: record # Configuration information of an Amazon Lex V2 bot. — shape: {AliasArn?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/instance/{InstanceId}/bot"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LexBot, var: lex_bot}, {name: LexV2Bot, var: lex_v2_bot}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lex_bot: $lex_bot, lex_v2_bot: $lex_v2_bot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates an existing vocabulary as the default. Contact Lens for Amazon Connect uses the vocabulary in post-call and real-time analysis sessions for the given language.
#
# PUT /default-vocabulary/{InstanceId}/{LanguageCode}
# Returns: record
# operationId: AssociateDefaultVocabulary
export def "associate-default-vocabulary" [
  instance_id: string
  language_code: string@language-code-completer
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
  --vocabulary-id: string # The identifier of the custom vocabulary. If this is empty, the default is set to none.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/default-vocabulary/{InstanceId}/{LanguageCode}"
    path_params: [{name: InstanceId, var: instance_id}, {name: LanguageCode, var: language_code}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: VocabularyId, var: vocabulary_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, language_code: $language_code, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, vocabulary_id: $vocabulary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Associates a storage resource type for the first time. You can only associate one type of storage configuration in a single call. This means, for example, that you can't define an instance with multiple S3 buckets for storing chat transcripts. This API does not create a resource that doesn't exist. It only associates it to the instance. Ensure that the resource being specified in the storage configuration, like an S3 bucket, exists when being used for association.
#
# PUT /instance/{InstanceId}/storage-config
# Returns: record<AssociationId: string>
# operationId: AssociateInstanceStorageConfig
export def "associate-instance-storage-config" [
  instance_id: string
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
  resource_type: string@resource-type-completer # A valid resource type.
  storage_config: record # The storage configuration for the instance. — shape: {AssociationId?: string, StorageType?: "S3"|"KINESIS_VIDEO_STREAM"|"KINESIS_STREAM"|"KINESIS_FIREHOSE", S3Config?: record, KinesisVideoStreamConfig?: record, KinesisStreamConfig?: record, KinesisFirehoseConfig?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/storage-config"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceType, var: resource_type}, {name: StorageConfig, var: storage_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_type: $resource_type, storage_config: $storage_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Allows the specified Amazon Connect instance to access the specified Lambda function.
#
# PUT /instance/{InstanceId}/lambda-function
# operationId: AssociateLambdaFunction
export def "associate-lambda-function" [
  instance_id: string
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
  function_arn: string # The Amazon Resource Name (ARN) for the Lambda function being associated. Maximum number of characters allowed is 140.
]: any -> any {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/lambda-function"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FunctionArn, var: function_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, function_arn: $function_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Allows the specified Amazon Connect instance to access the specified Amazon Lex V1 bot. This API only supports the association of Amazon Lex V1 bots.
#
# PUT /instance/{InstanceId}/lex-bot
# operationId: AssociateLexBot
export def "associate-lex-bot" [
  instance_id: string
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
  lex_bot: record # Configuration information of an Amazon Lex bot. — shape: {Name?: string, LexRegion?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/lex-bot"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LexBot, var: lex_bot}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lex_bot: $lex_bot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a flow with a phone number claimed to your Amazon Connect instance. If the number is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the PhoneNumberId URI request parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# PUT /phone-number/{PhoneNumberId}/contact-flow
# operationId: AssociatePhoneNumberContactFlow
export def "associate-phone-number-contact-flow" [
  phone_number_id: string
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_flow_id: string # The identifier of the flow.
]: any -> any {
  $in | http-request {
    method: put
    path: "/phone-number/{PhoneNumberId}/contact-flow"
    path_params: [{name: PhoneNumberId, var: phone_number_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactFlowId, var: contact_flow_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_flow_id: $contact_flow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Associates a set of quick connects with a queue.
#
# POST /queues/{InstanceId}/{QueueId}/associate-quick-connects
# operationId: AssociateQueueQuickConnects
export def "associate-queue-quick-connects" [
  instance_id: string
  queue_id: string
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
  quick_connect_ids: list<string> # The quick connects to associate with this queue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/queues/{InstanceId}/{QueueId}/associate-quick-connects"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: QuickConnectIds, var: quick_connect_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, quick_connect_ids: $quick_connect_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a set of queues with a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/associate-queues
# operationId: AssociateRoutingProfileQueues
export def "associate-routing-profile-queues" [
  instance_id: string
  routing_profile_id: string
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
  queue_configs: list # The queues to associate with this routing profile. — item shape: {QueueReference: record, Priority: int, Delay: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}/associate-queues"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: QueueConfigs, var: queue_configs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, queue_configs: $queue_configs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Associates a security key to the instance.
#
# PUT /instance/{InstanceId}/security-key
# Returns: record<AssociationId: string>
# operationId: AssociateSecurityKey
export def "associate-security-key" [
  instance_id: string
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
  key: string # A valid security key in PEM format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/security-key"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Key, var: key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claims an available phone number to your Amazon Connect instance or traffic distribution group. You can call this API only in the same Amazon Web Services Region where the Amazon Connect instance or traffic distribution group was created. For more information about how to use this operation, see Claim a phone number in your country (https://docs.aws.amazon.com/connect/latest/adminguide/claim-phone-number.html) and Claim phone numbers to traffic distribution groups (https://docs.aws.amazon.com/connect/latest/adminguide/claim-phone-numbers-traffic-distribution-groups.html) in the Amazon Connect Administrator Guide. You can call the SearchAvailablePhoneNumbers (https://docs.aws.amazon.com/connect/latest/APIReference/API_SearchAvailablePhoneNumbers.html) API for available phone numbers that you can claim. Call the DescribePhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_DescribePhoneNumber.html) API to verify the status of a previous ClaimPhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_ClaimPhoneNumber.html) operation.
#
# POST /phone-number/claim
# Returns: record<PhoneNumberId: string, PhoneNumberArn: string>
# operationId: ClaimPhoneNumber
export def "claim-phone-number" [
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
  target_arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to.
  phone_number: string # The phone number you want to claim. Phone numbers are formatted [+] [country code] [subscriber number including area code].
  --phone-number-description: string # The description of the phone number.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). Pattern: ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-number/claim"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetArn, var: target_arn}, {name: PhoneNumber, var: phone_number}, {name: PhoneNumberDescription, var: phone_number_description}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target_arn: $target_arn, phone_number: $phone_number, phone_number_description: $phone_number_description, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Creates an agent status for the specified Amazon Connect instance.
#
# PUT /agent-status/{InstanceId}
# Returns: record<AgentStatusARN: string, AgentStatusId: string>
# operationId: CreateAgentStatus
export def "create-agent-status" [
  instance_id: string
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
  name: string # The name of the status.
  --description: string # The description of the status.
  state: string@state-completer # The state of the status.
  --display-order: int # The display order of the status.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/agent-status/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: State, var: state}, {name: DisplayOrder, var: display_order}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, state: $state, display_order: $display_order, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Lists agent statuses.
#
# GET /agent-status/{InstanceId}
# Returns: record<NextToken: string, AgentStatusSummaryList: table<Id: string, Arn: string, Name: string, Type: string>>
# operationId: ListAgentStatuses
export def "list-agent-statuses" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --agent-status-types: list<string> # Available agent status types.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/agent-status/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: AgentStatusTypes, var: agent_status_types, style: multi}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, agent_status_types: $agent_status_types, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a flow for the specified Amazon Connect instance. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# PUT /contact-flows/{InstanceId}
# Returns: record<ContactFlowId: string, ContactFlowArn: string>
# operationId: CreateContactFlow
export def "create-contact-flow" [
  instance_id: string
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
  name: string # The name of the flow.
  type: string@type-completer # The type of the flow. For descriptions of the available types, see Choose a flow type (https://docs.aws.amazon.com/connect/latest/adminguide/create-contact-flow.html#contact-flow-types) in the Amazon Connect Administrator Guide.
  --description: string # The description of the flow.
  content: string # The content of the flow.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contact-flows/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Type, var: type}, {name: Description, var: description}, {name: Content, var: content}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, type: $type, description: $description, content: $content, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a flow module for the specified Amazon Connect instance.
#
# PUT /contact-flow-modules/{InstanceId}
# Returns: record<Id: string, Arn: string>
# operationId: CreateContactFlowModule
export def "create-contact-flow-module" [
  instance_id: string
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
  name: string # The name of the flow module.
  --description: string # The description of the flow module.
  content: string # The content of the flow module.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contact-flow-modules/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: Content, var: content}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, content: $content, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Creates hours of operation.
#
# PUT /hours-of-operations/{InstanceId}
# Returns: record<HoursOfOperationId: string, HoursOfOperationArn: string>
# operationId: CreateHoursOfOperation
export def "create-hours-of-operation" [
  instance_id: string
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
  name: string # The name of the hours of operation.
  --description: string # The description of the hours of operation.
  time_zone: string # The time zone of the hours of operation.
  config: list # Configuration information for the hours of operation: day, start time, and end time. — item shape: {Day: "SUNDAY"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY", StartTime: record, EndTime: record}
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/hours-of-operations/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: TimeZone, var: time_zone}, {name: Config, var: config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, time_zone: $time_zone, config: $config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Initiates an Amazon Connect instance with all the supported channels enabled. It does not attach any storage, such as Amazon Simple Storage Service (Amazon S3) or Amazon Kinesis. It also does not allow for any configurations on features, such as Contact Lens for Amazon Connect. Amazon Connect enforces a limit on the total number of instances that you can create or delete in 30 days. If you exceed this limit, you will get an error message indicating there has been an excessive number of attempts at creating or deleting instances. You must wait 30 days before you can restart creating and deleting instances in your account.
#
# PUT /instance
# Returns: record<Id: string, Arn: string>
# operationId: CreateInstance
export def "create-instance" [
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
  --client-token: string # The idempotency token.
  identity_management_type: string@identity-management-type-completer # The type of identity management for your Amazon Connect users.
  --instance-alias: string # The name for your instance. (format: password)
  --directory-id: string # The identifier for the directory.
  --inbound-calls-enabled: oneof<nothing, bool> # Your contact center handles incoming contacts.
  --outbound-calls-enabled: oneof<nothing, bool> # Your contact center allows outbound calls.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instance"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientToken, var: client_token}, {name: IdentityManagementType, var: identity_management_type}, {name: InstanceAlias, var: instance_alias}, {name: DirectoryId, var: directory_id}, {name: InboundCallsEnabled, var: inbound_calls_enabled, required: true}, {name: OutboundCallsEnabled, var: outbound_calls_enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, identity_management_type: $identity_management_type, instance_alias: $instance_alias, directory_id: $directory_id, inbound_calls_enabled: $inbound_calls_enabled, outbound_calls_enabled: $outbound_calls_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Return a list of instances which are in active state, creation-in-progress state, and failed state. Instances that aren't successfully created (they are in a failed state) are returned only for 24 hours after the CreateInstance API was invoked.
#
# GET /instance
# Returns: record<InstanceSummaryList: table<Id: string, Arn: string, IdentityManagementType: string, InstanceAlias: string, CreatedTime: string, ServiceRole: string, InstanceStatus: string, InboundCallsEnabled: bool, OutboundCallsEnabled: bool>, NextToken: string>
# operationId: ListInstances
export def "list-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Web Services resource association with an Amazon Connect instance.
#
# PUT /instance/{InstanceId}/integration-associations
# Returns: record<IntegrationAssociationId: string, IntegrationAssociationArn: string>
# operationId: CreateIntegrationAssociation
export def "create-integration-association" [
  instance_id: string
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
  integration_type: string@integration-type-completer # The type of information to be ingested.
  integration_arn: string # The Amazon Resource Name (ARN) of the integration. When integrating with Amazon Pinpoint, the Amazon Connect and Amazon Pinpoint instances must be in the same account.
  --source-application-url: string # The URL for the external application. This field is only required for the EVENT integration type.
  --source-application-name: string # The name of the external application. This field is only required for the EVENT integration type.
  --source-type: string@source-type-completer # The type of the data source. This field is only required for the EVENT integration type.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/integration-associations"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: IntegrationType, var: integration_type}, {name: IntegrationArn, var: integration_arn}, {name: SourceApplicationUrl, var: source_application_url}, {name: SourceApplicationName, var: source_application_name}, {name: SourceType, var: source_type}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, integration_type: $integration_type, integration_arn: $integration_arn, source_application_url: $source_application_url, source_application_name: $source_application_name, source_type: $source_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides summary information about the Amazon Web Services resource associations for the specified Amazon Connect instance.
#
# GET /instance/{InstanceId}/integration-associations
# Returns: record<IntegrationAssociationSummaryList: table<IntegrationAssociationId: string, IntegrationAssociationArn: string, InstanceId: string, IntegrationType: string, IntegrationArn: string, SourceApplicationUrl: string, SourceApplicationName: string, SourceType: string>, NextToken: string>
# operationId: ListIntegrationAssociations
export def "list-integration-associations" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-type: string@integration-type-completer # The integration type.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/integration-associations"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: integrationType, var: integration_type}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, integration_type: $integration_type, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new participant into an on-going chat contact. For more information, see Customize chat flow experiences by integrating custom participants (https://docs.aws.amazon.com/connect/latest/adminguide/chat-customize-flow.html).
#
# POST /contact/create-participant
# Returns: record<ParticipantCredentials: record<ParticipantToken: string, Expiry: string>, ParticipantId: string>
# operationId: CreateParticipant
export def "create-participant" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact in this instance of Amazon Connect. Only contacts in the CHAT channel are supported.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  participant_details: record # The details to add for the participant. — shape: {ParticipantRole?: "AGENT"|"CUSTOMER"|"SYSTEM"|"CUSTOM_BOT", DisplayName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/create-participant"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: ClientToken, var: client_token}, {name: ParticipantDetails, var: participant_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, client_token: $client_token, participant_details: $participant_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Creates a new queue for the specified Amazon Connect instance. If the number being used in the input is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the OutboundCallerIdNumberId value of the OutboundCallerConfig (https://docs.aws.amazon.com/connect/latest/APIReference/API_OutboundCallerConfig) request body parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# PUT /queues/{InstanceId}
# Returns: record<QueueArn: string, QueueId: string>
# operationId: CreateQueue
export def "create-queue" [
  instance_id: string
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
  name: string # The name of the queue.
  --description: string # The description of the queue.
  --outbound-caller-config: record # The outbound caller ID name, number, and outbound whisper flow. — shape: {OutboundCallerIdName?: string, OutboundCallerIdNumberId?: string, OutboundFlowId?: string}
  hours_of_operation_id: string # The identifier for the hours of operation.
  --max-contacts: int # The maximum number of contacts that can be in the queue before it is considered full.
  --quick-connect-ids: list<string> # The quick connects available to agents who are working the queue.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/queues/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: OutboundCallerConfig, var: outbound_caller_config}, {name: HoursOfOperationId, var: hours_of_operation_id}, {name: MaxContacts, var: max_contacts}, {name: QuickConnectIds, var: quick_connect_ids}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, outbound_caller_config: $outbound_caller_config, hours_of_operation_id: $hours_of_operation_id, max_contacts: $max_contacts, quick_connect_ids: $quick_connect_ids, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a quick connect for the specified Amazon Connect instance.
#
# PUT /quick-connects/{InstanceId}
# Returns: record<QuickConnectARN: string, QuickConnectId: string>
# operationId: CreateQuickConnect
export def "create-quick-connect" [
  instance_id: string
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
  name: string # The name of the quick connect.
  --description: string # The description of the quick connect.
  quick_connect_config: record # Contains configuration settings for a quick connect. — shape: {QuickConnectType?: "USER"|"QUEUE"|"PHONE_NUMBER", UserConfig?: record, QueueConfig?: record, PhoneConfig?: record}
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/quick-connects/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: QuickConnectConfig, var: quick_connect_config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, quick_connect_config: $quick_connect_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the quick connects for the specified Amazon Connect instance.
#
# GET /quick-connects/{InstanceId}
# Returns: record<QuickConnectSummaryList: table<Id: string, Arn: string, Name: string, QuickConnectType: string>, NextToken: string>
# operationId: ListQuickConnects
export def "list-quick-connects" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --quick-connect-types: list<string> # The type of quick connect. In the Amazon Connect console, when you create a quick connect, you are prompted to assign one of the following types: Agent (USER), External (PHONE_NUMBER), or Queue (QUEUE).
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/quick-connects/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: QuickConnectTypes, var: quick_connect_types, style: multi}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, quick_connect_types: $quick_connect_types, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new routing profile.
#
# PUT /routing-profiles/{InstanceId}
# Returns: record<RoutingProfileArn: string, RoutingProfileId: string>
# operationId: CreateRoutingProfile
export def "create-routing-profile" [
  instance_id: string
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
  name: string # The name of the routing profile. Must not be more than 127 characters.
  description: string # Description of the routing profile. Must not be more than 250 characters.
  default_outbound_queue_id: string # The default outbound queue for the routing profile.
  --queue-configs: list # The inbound queues associated with the routing profile. If no queue is added, the agent can make only outbound calls. The limit of 10 array members applies to the maximum number of RoutingProfileQueueConfig objects that can be passed during a CreateRoutingProfile API request. It is different from the quota of 50 queues per routing profile per instance that is listed in Amazon Connect service quotas (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html). — item shape: {QueueReference: record, Priority: int, Delay: int}
  media_concurrencies: list # The channels that agents can handle in the Contact Control Panel (CCP) for this routing profile. — item shape: {Channel: "VOICE"|"CHAT"|"TASK", Concurrency: int, CrossChannelBehavior?: record}
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/routing-profiles/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: DefaultOutboundQueueId, var: default_outbound_queue_id}, {name: QueueConfigs, var: queue_configs}, {name: MediaConcurrencies, var: media_concurrencies}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, default_outbound_queue_id: $default_outbound_queue_id, queue_configs: $queue_configs, media_concurrencies: $media_concurrencies, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a rule for the specified Amazon Connect instance. Use the Rules Function language (https://docs.aws.amazon.com/connect/latest/APIReference/connect-rules-language.html) to code conditions for the rule.
#
# POST /rules/{InstanceId}
# Returns: record<RuleArn: string, RuleId: string>
# operationId: CreateRule
export def "create-rule" [
  instance_id: string
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
  name: string # A unique name for the rule.
  trigger_event_source: record # The name of the event source. This field is required if TriggerEventSource is one of the following values: OnZendeskTicketCreate | OnZendeskTicketStatusUpdate | OnSalesforceCaseCreate — shape: {EventSourceName?: "OnPostCallAnalysisAvailable"|"OnRealTimeCallAnalysisAvailable"|"OnPostChatAnalysisAvailable"|"OnZendeskTicketCreate"|"OnZendeskTicketStatusUpdate"|"OnSalesforceCaseCreate", IntegrationAssociationId?: string}
  function: string # The conditions of the rule.
  actions: list # A list of actions to be run when the rule is triggered. — item shape: {ActionType: "CREATE_TASK"|"ASSIGN_CONTACT_CATEGORY"|"GENERATE_EVENTBRIDGE_EVENT"|"SEND_NOTIFICATION", TaskAction?: record, EventBridgeAction?: record, AssignContactCategoryAction?: record, SendNotificationAction?: record}
  publish_status: string@publish-status-completer # The publish status of the rule.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rules/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: TriggerEventSource, var: trigger_event_source}, {name: Function, var: function}, {name: Actions, var: actions}, {name: PublishStatus, var: publish_status}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, trigger_event_source: $trigger_event_source, function: $function, actions: $actions, publish_status: $publish_status, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all rules for the specified Amazon Connect instance.
#
# GET /rules/{InstanceId}
# Returns: record<RuleSummaryList: table<Name: string, RuleId: string, RuleArn: string, EventSourceName: string, PublishStatus: string, ActionSummaries: list, CreatedTime: string, LastUpdatedTime: string>, NextToken: string>
# operationId: ListRules
export def "list-rules" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --publish-status: string@publish-status-completer # The publish status of the rule.
  --event-source-name: string@event-source-name-completer # The name of the event source.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/rules/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: publishStatus, var: publish_status}, {name: eventSourceName, var: event_source_name}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, publish_status: $publish_status, event_source_name: $event_source_name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Creates a security profile.
#
# PUT /security-profiles/{InstanceId}
# Returns: record<SecurityProfileId: string, SecurityProfileArn: string>
# operationId: CreateSecurityProfile
export def "create-security-profile" [
  instance_id: string
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
  security_profile_name: string # The name of the security profile.
  --description: string # The description of the security profile.
  --permissions: list<string> # Permissions assigned to the security profile. For a list of valid permissions, see List of security profile permissions (https://docs.aws.amazon.com/connect/latest/adminguide/security-profile-list.html).
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
  --allowed-access-control-tags: record # The list of tags that a security profile uses to restrict access to resources in Amazon Connect.
  --tag-restricted-resources: list<string> # The list of resources that a security profile applies tag restrictions to in Amazon Connect. Following are acceptable ResourceNames: User | SecurityProfile | Queue | RoutingProfile
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/security-profiles/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SecurityProfileName, var: security_profile_name}, {name: Description, var: description}, {name: Permissions, var: permissions}, {name: Tags, var: tags}, {name: AllowedAccessControlTags, var: allowed_access_control_tags}, {name: TagRestrictedResources, var: tag_restricted_resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, security_profile_name: $security_profile_name, description: $description, permissions: $permissions, tags: $tags, allowed_access_control_tags: $allowed_access_control_tags, tag_restricted_resources: $tag_restricted_resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new task template in the specified Amazon Connect instance.
#
# PUT /instance/{InstanceId}/task/template
# Returns: record<Id: string, Arn: string>
# operationId: CreateTaskTemplate
export def "create-task-template" [
  instance_id: string
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
  name: string # The name of the task template.
  --description: string # The description of the task template.
  --contact-flow-id: string # The identifier of the flow that runs by default when a task is created by referencing this template.
  --constraints: record # Describes constraints that apply to the template fields. — shape: {RequiredFields?: list, ReadOnlyFields?: list, InvisibleFields?: list}
  --defaults: record # Describes default values for fields on a template. — shape: {DefaultFieldValues?: list}
  --status: string@status-completer # Marks a template as ACTIVE or INACTIVE for a task to refer to it. Tasks can only be created from ACTIVE templates. If a template is marked as INACTIVE, then a task that refers to this template cannot be created.
  fields: list # Fields that are part of the template. — item shape: {Id: record, Description?: string, Type?: "NAME"|"DESCRIPTION"|"SCHEDULED_TIME"|"QUICK_CONNECT"|"URL"|"NUMBER"|"TEXT"|"TEXT_AREA"|"DATE_TIME"|"BOOLEAN"|"SINGLE_SELECT"|"EMAIL", SingleSelectOptions?: list<string>}
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/task/template"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: ContactFlowId, var: contact_flow_id}, {name: Constraints, var: constraints}, {name: Defaults, var: defaults}, {name: Status, var: status}, {name: Fields, var: fields}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, contact_flow_id: $contact_flow_id, constraints: $constraints, defaults: $defaults, status: $status, fields: $fields, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists task templates for the specified Amazon Connect instance.
#
# GET /instance/{InstanceId}/task/template
# Returns: record<TaskTemplates: table<Id: string, Arn: string, Name: string, Description: string, Status: string, LastModifiedTime: string, CreatedTime: string>, NextToken: string>
# operationId: ListTaskTemplates
export def "list-task-templates" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. It is not expected that you set this because the value returned in the previous response is always null.
  --max-results: int # The maximum number of results to return per page. It is not expected that you set this.
  --status: string@status-completer # Marks a template as ACTIVE or INACTIVE for a task to refer to it. Tasks can only be created from ACTIVE templates. If a template is marked as INACTIVE, then a task that refers to this template cannot be created.
  --name: string # The name of the task template.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/task/template"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: status, var: status}, {name: name, var: name}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, status: $status, name: $name, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a traffic distribution group given an Amazon Connect instance that has been replicated. For more information about creating traffic distribution groups, see Set up traffic distribution groups (https://docs.aws.amazon.com/connect/latest/adminguide/setup-traffic-distribution-groups.html) in the Amazon Connect Administrator Guide.
#
# PUT /traffic-distribution-group
# Returns: record<Id: string, Arn: string>
# operationId: CreateTrafficDistributionGroup
export def "create-traffic-distribution-group" [
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
  name: string # The name for the traffic distribution group.
  --description: string # A description for the traffic distribution group.
  instance_id: string # The identifier of the Amazon Connect instance that has been replicated. You can find the instanceId in the ARN of the instance.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/traffic-distribution-group"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: InstanceId, var: instance_id}, {name: ClientToken, var: client_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, instance_id: $instance_id, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a use case for an integration association.
#
# PUT /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases
# Returns: record<UseCaseId: string, UseCaseArn: string>
# operationId: CreateUseCase
export def "create-use-case" [
  instance_id: string
  integration_association_id: string
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
  use_case_type: string@use-case-type-completer # The type of use case to associate to the integration association. Each integration association can have only one of each use case type.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases"
    path_params: [{name: InstanceId, var: instance_id}, {name: IntegrationAssociationId, var: integration_association_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UseCaseType, var: use_case_type}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, integration_association_id: $integration_association_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, use_case_type: $use_case_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the use cases for the integration association.
#
# GET /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases
# Returns: record<UseCaseSummaryList: table<UseCaseId: string, UseCaseArn: string, UseCaseType: string>, NextToken: string>
# operationId: ListUseCases
export def "list-use-cases" [
  instance_id: string
  integration_association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases"
    path_params: [{name: InstanceId, var: instance_id}, {name: IntegrationAssociationId, var: integration_association_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, integration_association_id: $integration_association_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user account for the specified Amazon Connect instance. For information about how to create user accounts using the Amazon Connect console, see Add Users (https://docs.aws.amazon.com/connect/latest/adminguide/user-management.html) in the Amazon Connect Administrator Guide.
#
# PUT /users/{InstanceId}
# Returns: record<UserId: string, UserArn: string>
# operationId: CreateUser
export def "create-user" [
  instance_id: string
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
  username: string # The user name for the account. For instances not using SAML for identity management, the user name can include up to 20 characters. If you are using SAML for identity management, the user name can include up to 64 characters from [a-zA-Z0-9_-.\@]+.
  --password: string # The password for the user account. A password is required if you are using Amazon Connect for identity management. Otherwise, it is an error to include a password.
  --identity-info: record # Contains information about the identity of a user. — shape: {FirstName?: string, LastName?: string, Email?: string, SecondaryEmail?: string, Mobile?: string}
  phone_config: record # Contains information about the phone configuration settings for a user. — shape: {PhoneType?: "SOFT_PHONE"|"DESK_PHONE", AutoAccept?: bool, AfterContactWorkTimeLimit?: int, DeskPhoneNumber?: string}
  --directory-user-id: string # The identifier of the user account in the directory used for identity management. If Amazon Connect cannot access the directory, you can specify this identifier to authenticate users. If you include the identifier, we assume that Amazon Connect cannot access the directory. Otherwise, the identity information is used to authenticate users from your directory. This parameter is required if you are using an existing directory for identity management in Amazon Connect when Amazon Connect cannot access your directory to authenticate users. If you are using SAML for identity management and include this parameter, an error is returned.
  security_profile_ids: list<string> # The identifier of the security profile for the user.
  routing_profile_id: string # The identifier of the routing profile for the user.
  --hierarchy-group-id: string # The identifier of the hierarchy group for the user.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Username, var: username}, {name: Password, var: password}, {name: IdentityInfo, var: identity_info}, {name: PhoneConfig, var: phone_config}, {name: DirectoryUserId, var: directory_user_id}, {name: SecurityProfileIds, var: security_profile_ids}, {name: RoutingProfileId, var: routing_profile_id}, {name: HierarchyGroupId, var: hierarchy_group_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, username: $username, password: $password, identity_info: $identity_info, phone_config: $phone_config, directory_user_id: $directory_user_id, security_profile_ids: $security_profile_ids, routing_profile_id: $routing_profile_id, hierarchy_group_id: $hierarchy_group_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new user hierarchy group.
#
# PUT /user-hierarchy-groups/{InstanceId}
# Returns: record<HierarchyGroupId: string, HierarchyGroupArn: string>
# operationId: CreateUserHierarchyGroup
export def "create-user-hierarchy-group" [
  instance_id: string
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
  name: string # The name of the user hierarchy group. Must not be more than 100 characters.
  --parent-group-id: string # The identifier for the parent hierarchy group. The user hierarchy is created at level one if the parent group ID is null.
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user-hierarchy-groups/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: ParentGroupId, var: parent_group_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, parent_group_id: $parent_group_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom vocabulary associated with your Amazon Connect instance. You can set a custom vocabulary to be your default vocabulary for a given language. Contact Lens for Amazon Connect uses the default vocabulary in post-call and real-time contact analysis sessions for that language.
#
# POST /vocabulary/{InstanceId}
# Returns: record<VocabularyArn: string, VocabularyId: string, State: string>
# operationId: CreateVocabulary
export def "create-vocabulary" [
  instance_id: string
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
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). If a create request is received more than once with same client token, subsequent requests return the previous response without creating a vocabulary again.
  vocabulary_name: string # A unique name of the custom vocabulary.
  language_code: string@language-code-completer # The language code of the vocabulary entries. For a list of languages and their corresponding language codes, see What is Amazon Transcribe? (https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-whatis.html)
  content: string # The content of the custom vocabulary in plain-text format with a table of values. Each row in the table represents a word or a phrase, described with Phrase, IPA, SoundsLike, and DisplayAs fields. Separate the fields with TAB characters. The size limit is 50KB. For more information, see Create a custom vocabulary using a table (https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html#create-vocabulary-table).
  --tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vocabulary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientToken, var: client_token}, {name: VocabularyName, var: vocabulary_name}, {name: LanguageCode, var: language_code}, {name: Content, var: content}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, vocabulary_name: $vocabulary_name, language_code: $language_code, content: $content, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a flow for the specified Amazon Connect instance.
#
# DELETE /contact-flows/{InstanceId}/{ContactFlowId}
# Returns: record
# operationId: DeleteContactFlow
export def "delete-contact-flow" [
  instance_id: string
  contact_flow_id: string
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
    path: "/contact-flows/{InstanceId}/{ContactFlowId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowId, var: contact_flow_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_id: $contact_flow_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified flow. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# GET /contact-flows/{InstanceId}/{ContactFlowId}
# Returns: record<ContactFlow: record<Arn: string, Id: string, Name: string, Type: string, State: string, Description: string, Content: string, Tags: record>>
# operationId: DescribeContactFlow
export def "describe-contact-flow" [
  instance_id: string
  contact_flow_id: string
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
    path: "/contact-flows/{InstanceId}/{ContactFlowId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowId, var: contact_flow_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_id: $contact_flow_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified flow module.
#
# DELETE /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}
# Returns: record
# operationId: DeleteContactFlowModule
export def "delete-contact-flow-module" [
  instance_id: string
  contact_flow_module_id: string
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
    path: "/contact-flow-modules/{InstanceId}/{ContactFlowModuleId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowModuleId, var: contact_flow_module_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_module_id: $contact_flow_module_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified flow module.
#
# GET /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}
# Returns: record<ContactFlowModule: record<Arn: string, Id: string, Name: string, Content: string, Description: string, State: string, Status: string, Tags: record>>
# operationId: DescribeContactFlowModule
export def "describe-contact-flow-module" [
  instance_id: string
  contact_flow_module_id: string
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
    path: "/contact-flow-modules/{InstanceId}/{ContactFlowModuleId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowModuleId, var: contact_flow_module_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_module_id: $contact_flow_module_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes an hours of operation.
#
# DELETE /hours-of-operations/{InstanceId}/{HoursOfOperationId}
# operationId: DeleteHoursOfOperation
export def "delete-hours-of-operation" [
  instance_id: string
  hours_of_operation_id: string
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
    path: "/hours-of-operations/{InstanceId}/{HoursOfOperationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: HoursOfOperationId, var: hours_of_operation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, hours_of_operation_id: $hours_of_operation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the hours of operation.
#
# GET /hours-of-operations/{InstanceId}/{HoursOfOperationId}
# Returns: record<HoursOfOperation: record<HoursOfOperationId: string, HoursOfOperationArn: string, Name: string, Description: string, TimeZone: string, Config: list<record>, Tags: record>>
# operationId: DescribeHoursOfOperation
export def "describe-hours-of-operation" [
  instance_id: string
  hours_of_operation_id: string
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
    path: "/hours-of-operations/{InstanceId}/{HoursOfOperationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: HoursOfOperationId, var: hours_of_operation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, hours_of_operation_id: $hours_of_operation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the hours of operation.
#
# POST /hours-of-operations/{InstanceId}/{HoursOfOperationId}
# operationId: UpdateHoursOfOperation
export def "update-hours-of-operation" [
  instance_id: string
  hours_of_operation_id: string
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
  --name: string # The name of the hours of operation.
  --description: string # The description of the hours of operation.
  --time-zone: string # The time zone of the hours of operation.
  --config: list # Configuration information of the hours of operation. — item shape: {Day: "SUNDAY"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY", StartTime: record, EndTime: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/hours-of-operations/{InstanceId}/{HoursOfOperationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: HoursOfOperationId, var: hours_of_operation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: TimeZone, var: time_zone}, {name: Config, var: config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, hours_of_operation_id: $hours_of_operation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, time_zone: $time_zone, config: $config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes the Amazon Connect instance. Amazon Connect enforces a limit on the total number of instances that you can create or delete in 30 days. If you exceed this limit, you will get an error message indicating there has been an excessive number of attempts at creating or deleting instances. You must wait 30 days before you can restart creating and deleting instances in your account.
#
# DELETE /instance/{InstanceId}
# operationId: DeleteInstance
export def "delete-instance" [
  instance_id: string
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
    path: "/instance/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Returns the current state of the specified instance identifier. It tracks the instance while it is being created and returns an error status, if applicable. If an instance is not created successfully, the instance status reason field returns details relevant to the reason. The instance in a failed state is returned only for 24 hours after the CreateInstance API was invoked.
#
# GET /instance/{InstanceId}
# Returns: record<Instance: record<Id: string, Arn: string, IdentityManagementType: string, InstanceAlias: string, CreatedTime: string, ServiceRole: string, InstanceStatus: string, StatusReason: record<Message: string>, InboundCallsEnabled: bool, OutboundCallsEnabled: bool>>
# operationId: DescribeInstance
export def "describe-instance" [
  instance_id: string
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
    path: "/instance/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon Web Services resource association from an Amazon Connect instance. The association must not have any use cases associated with it.
#
# DELETE /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}
# operationId: DeleteIntegrationAssociation
export def "delete-integration-association" [
  instance_id: string
  integration_association_id: string
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
    path: "/instance/{InstanceId}/integration-associations/{IntegrationAssociationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: IntegrationAssociationId, var: integration_association_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, integration_association_id: $integration_association_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a quick connect.
#
# DELETE /quick-connects/{InstanceId}/{QuickConnectId}
# operationId: DeleteQuickConnect
export def "delete-quick-connect" [
  instance_id: string
  quick_connect_id: string
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
    path: "/quick-connects/{InstanceId}/{QuickConnectId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: QuickConnectId, var: quick_connect_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, quick_connect_id: $quick_connect_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the quick connect.
#
# GET /quick-connects/{InstanceId}/{QuickConnectId}
# Returns: record<QuickConnect: record<QuickConnectARN: string, QuickConnectId: string, Name: string, Description: string, QuickConnectConfig: record<QuickConnectType: string, UserConfig: record, QueueConfig: record, PhoneConfig: record>, Tags: record>>
# operationId: DescribeQuickConnect
export def "describe-quick-connect" [
  instance_id: string
  quick_connect_id: string
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
    path: "/quick-connects/{InstanceId}/{QuickConnectId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: QuickConnectId, var: quick_connect_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, quick_connect_id: $quick_connect_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a rule for the specified Amazon Connect instance.
#
# DELETE /rules/{InstanceId}/{RuleId}
# operationId: DeleteRule
export def "delete-rule" [
  instance_id: string
  rule_id: string
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
    path: "/rules/{InstanceId}/{RuleId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: RuleId, var: rule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, rule_id: $rule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a rule for the specified Amazon Connect instance.
#
# GET /rules/{InstanceId}/{RuleId}
# Returns: record<Rule: record<Name: string, RuleId: string, RuleArn: string, TriggerEventSource: record<EventSourceName: string, IntegrationAssociationId: string>, Function: string, Actions: list<record>, PublishStatus: string, CreatedTime: string, LastUpdatedTime: string, LastUpdatedBy: string, Tags: record>>
# operationId: DescribeRule
export def "describe-rule" [
  instance_id: string
  rule_id: string
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
    path: "/rules/{InstanceId}/{RuleId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: RuleId, var: rule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, rule_id: $rule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a rule for the specified Amazon Connect instance. Use the Rules Function language (https://docs.aws.amazon.com/connect/latest/APIReference/connect-rules-language.html) to code conditions for the rule.
#
# PUT /rules/{InstanceId}/{RuleId}
# operationId: UpdateRule
export def "update-rule" [
  instance_id: string
  rule_id: string
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
  name: string # The name of the rule. You can change the name only if TriggerEventSource is one of the following values: OnZendeskTicketCreate | OnZendeskTicketStatusUpdate | OnSalesforceCaseCreate
  function: string # The conditions of the rule.
  actions: list # A list of actions to be run when the rule is triggered. — item shape: {ActionType: "CREATE_TASK"|"ASSIGN_CONTACT_CATEGORY"|"GENERATE_EVENTBRIDGE_EVENT"|"SEND_NOTIFICATION", TaskAction?: record, EventBridgeAction?: record, AssignContactCategoryAction?: record, SendNotificationAction?: record}
  publish_status: string@publish-status-completer # The publish status of the rule.
]: any -> any {
  $in | http-request {
    method: put
    path: "/rules/{InstanceId}/{RuleId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: RuleId, var: rule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Function, var: function}, {name: Actions, var: actions}, {name: PublishStatus, var: publish_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, rule_id: $rule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, function: $function, actions: $actions, publish_status: $publish_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes a security profile.
#
# DELETE /security-profiles/{InstanceId}/{SecurityProfileId}
# operationId: DeleteSecurityProfile
export def "delete-security-profile" [
  instance_id: string
  security_profile_id: string
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
    path: "/security-profiles/{InstanceId}/{SecurityProfileId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: SecurityProfileId, var: security_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, security_profile_id: $security_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Gets basic information about the security profle.
#
# GET /security-profiles/{InstanceId}/{SecurityProfileId}
# Returns: record<SecurityProfile: record<Id: string, OrganizationResourceId: string, Arn: string, SecurityProfileName: string, Description: string, Tags: record, AllowedAccessControlTags: record, TagRestrictedResources: list<string>>>
# operationId: DescribeSecurityProfile
export def "describe-security-profile" [
  instance_id: string
  security_profile_id: string
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
    path: "/security-profiles/{InstanceId}/{SecurityProfileId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: SecurityProfileId, var: security_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, security_profile_id: $security_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates a security profile.
#
# POST /security-profiles/{InstanceId}/{SecurityProfileId}
# operationId: UpdateSecurityProfile
export def "update-security-profile" [
  instance_id: string
  security_profile_id: string
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
  --description: string # The description of the security profile.
  --permissions: list<string> # The permissions granted to a security profile. For a list of valid permissions, see List of security profile permissions (https://docs.aws.amazon.com/connect/latest/adminguide/security-profile-list.html).
  --allowed-access-control-tags: record # The list of tags that a security profile uses to restrict access to resources in Amazon Connect.
  --tag-restricted-resources: list<string> # The list of resources that a security profile applies tag restrictions to in Amazon Connect.
]: any -> any {
  $in | http-request {
    method: post
    path: "/security-profiles/{InstanceId}/{SecurityProfileId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: SecurityProfileId, var: security_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Permissions, var: permissions}, {name: AllowedAccessControlTags, var: allowed_access_control_tags}, {name: TagRestrictedResources, var: tag_restricted_resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, security_profile_id: $security_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, permissions: $permissions, allowed_access_control_tags: $allowed_access_control_tags, tag_restricted_resources: $tag_restricted_resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the task template.
#
# DELETE /instance/{InstanceId}/task/template/{TaskTemplateId}
# Returns: record
# operationId: DeleteTaskTemplate
export def "delete-task-template" [
  instance_id: string
  task_template_id: string
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
    path: "/instance/{InstanceId}/task/template/{TaskTemplateId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: TaskTemplateId, var: task_template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, task_template_id: $task_template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details about a specific task template in the specified Amazon Connect instance.
#
# GET /instance/{InstanceId}/task/template/{TaskTemplateId}
# Returns: record<InstanceId: string, Id: string, Arn: string, Name: string, Description: string, ContactFlowId: string, Constraints: record<RequiredFields: list<record>, ReadOnlyFields: list<record>, InvisibleFields: list<record>>, Defaults: record<DefaultFieldValues: list<record>>, Fields: table<Id: record, Description: string, Type: string, SingleSelectOptions: list>, Status: string, LastModifiedTime: string, CreatedTime: string, Tags: record>
# operationId: GetTaskTemplate
export def "get-task-template" [
  instance_id: string
  task_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-version: string # The system generated version of a task template that is associated with a task, when the task is created.
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
    path: "/instance/{InstanceId}/task/template/{TaskTemplateId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: TaskTemplateId, var: task_template_id}]
    query: [{name: snapshotVersion, var: snapshot_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, task_template_id: $task_template_id, snapshot_version: $snapshot_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates details about a specific task template in the specified Amazon Connect instance. This operation does not support partial updates. Instead it does a full update of template content.
#
# POST /instance/{InstanceId}/task/template/{TaskTemplateId}
# Returns: record<InstanceId: string, Id: string, Arn: string, Name: string, Description: string, ContactFlowId: string, Constraints: record<RequiredFields: list<record>, ReadOnlyFields: list<record>, InvisibleFields: list<record>>, Defaults: record<DefaultFieldValues: list<record>>, Fields: table<Id: record, Description: string, Type: string, SingleSelectOptions: list>, Status: string, LastModifiedTime: string, CreatedTime: string>
# operationId: UpdateTaskTemplate
export def "update-task-template" [
  instance_id: string
  task_template_id: string
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
  --name: string # The name of the task template.
  --description: string # The description of the task template.
  --contact-flow-id: string # The identifier of the flow that runs by default when a task is created by referencing this template.
  --constraints: record # Describes constraints that apply to the template fields. — shape: {RequiredFields?: list, ReadOnlyFields?: list, InvisibleFields?: list}
  --defaults: record # Describes default values for fields on a template. — shape: {DefaultFieldValues?: list}
  --status: string@status-completer # Marks a template as ACTIVE or INACTIVE for a task to refer to it. Tasks can only be created from ACTIVE templates. If a template is marked as INACTIVE, then a task that refers to this template cannot be created.
  --fields: list # Fields that are part of the template. — item shape: {Id: record, Description?: string, Type?: "NAME"|"DESCRIPTION"|"SCHEDULED_TIME"|"QUICK_CONNECT"|"URL"|"NUMBER"|"TEXT"|"TEXT_AREA"|"DATE_TIME"|"BOOLEAN"|"SINGLE_SELECT"|"EMAIL", SingleSelectOptions?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/instance/{InstanceId}/task/template/{TaskTemplateId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: TaskTemplateId, var: task_template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: ContactFlowId, var: contact_flow_id}, {name: Constraints, var: constraints}, {name: Defaults, var: defaults}, {name: Status, var: status}, {name: Fields, var: fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, task_template_id: $task_template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, contact_flow_id: $contact_flow_id, constraints: $constraints, defaults: $defaults, status: $status, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a traffic distribution group. This API can be called only in the Region where the traffic distribution group is created. For more information about deleting traffic distribution groups, see Delete traffic distribution groups (https://docs.aws.amazon.com/connect/latest/adminguide/delete-traffic-distribution-groups.html) in the Amazon Connect Administrator Guide.
#
# DELETE /traffic-distribution-group/{TrafficDistributionGroupId}
# Returns: record
# operationId: DeleteTrafficDistributionGroup
export def "delete-traffic-distribution-group" [
  traffic_distribution_group_id: string
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
    path: "/traffic-distribution-group/{TrafficDistributionGroupId}"
    path_params: [{name: TrafficDistributionGroupId, var: traffic_distribution_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    traffic_distribution_group_id: $traffic_distribution_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details and status of a traffic distribution group.
#
# GET /traffic-distribution-group/{TrafficDistributionGroupId}
# Returns: record<TrafficDistributionGroup: record<Id: string, Arn: string, Name: string, Description: string, InstanceArn: string, Status: string, Tags: record>>
# operationId: DescribeTrafficDistributionGroup
export def "describe-traffic-distribution-group" [
  traffic_distribution_group_id: string
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
    path: "/traffic-distribution-group/{TrafficDistributionGroupId}"
    path_params: [{name: TrafficDistributionGroupId, var: traffic_distribution_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    traffic_distribution_group_id: $traffic_distribution_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a use case from an integration association.
#
# DELETE /instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases/{UseCaseId}
# operationId: DeleteUseCase
export def "delete-use-case" [
  instance_id: string
  integration_association_id: string
  use_case_id: string
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
    path: "/instance/{InstanceId}/integration-associations/{IntegrationAssociationId}/use-cases/{UseCaseId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: IntegrationAssociationId, var: integration_association_id}, {name: UseCaseId, var: use_case_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, integration_association_id: $integration_association_id, use_case_id: $use_case_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user account from the specified Amazon Connect instance. For information about what happens to a user's data when their account is deleted, see Delete Users from Your Amazon Connect Instance (https://docs.aws.amazon.com/connect/latest/adminguide/delete-users.html) in the Amazon Connect Administrator Guide.
#
# DELETE /users/{InstanceId}/{UserId}
# operationId: DeleteUser
export def "delete-user" [
  instance_id: string
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
    path: "/users/{InstanceId}/{UserId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified user account. You can find the instance ID in the Amazon Connect console (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
#
# GET /users/{InstanceId}/{UserId}
# Returns: record<User: record<Id: string, Arn: string, Username: string, IdentityInfo: record<FirstName: string, LastName: string, Email: string, SecondaryEmail: string, Mobile: string>, PhoneConfig: record<PhoneType: string, AutoAccept: bool, AfterContactWorkTimeLimit: int, DeskPhoneNumber: string>, DirectoryUserId: string, SecurityProfileIds: list<string>, RoutingProfileId: string, HierarchyGroupId: string, Tags: record>>
# operationId: DescribeUser
export def "describe-user" [
  instance_id: string
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
    path: "/users/{InstanceId}/{UserId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing user hierarchy group. It must not be associated with any agents or have any active child groups.
#
# DELETE /user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}
# operationId: DeleteUserHierarchyGroup
export def "delete-user-hierarchy-group" [
  instance_id: string
  hierarchy_group_id: string
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
    path: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: HierarchyGroupId, var: hierarchy_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, hierarchy_group_id: $hierarchy_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified hierarchy group.
#
# GET /user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}
# Returns: record<HierarchyGroup: record<Id: string, Arn: string, Name: string, LevelId: string, HierarchyPath: record<LevelOne: record, LevelTwo: record, LevelThree: record, LevelFour: record, LevelFive: record>, Tags: record>>
# operationId: DescribeUserHierarchyGroup
export def "describe-user-hierarchy-group" [
  instance_id: string
  hierarchy_group_id: string
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
    path: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: HierarchyGroupId, var: hierarchy_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, hierarchy_group_id: $hierarchy_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the vocabulary that has the given identifier.
#
# POST /vocabulary-remove/{InstanceId}/{VocabularyId}
# Returns: record<VocabularyArn: string, VocabularyId: string, State: string>
# operationId: DeleteVocabulary
export def "delete-vocabulary" [
  instance_id: string
  vocabulary_id: string
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
    method: post
    path: "/vocabulary-remove/{InstanceId}/{VocabularyId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: VocabularyId, var: vocabulary_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, vocabulary_id: $vocabulary_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Describes an agent status.
#
# GET /agent-status/{InstanceId}/{AgentStatusId}
# Returns: record<AgentStatus: record<AgentStatusARN: string, AgentStatusId: string, Name: string, Description: string, Type: string, DisplayOrder: int, State: string, Tags: record>>
# operationId: DescribeAgentStatus
export def "describe-agent-status" [
  instance_id: string
  agent_status_id: string
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
    path: "/agent-status/{InstanceId}/{AgentStatusId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AgentStatusId, var: agent_status_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, agent_status_id: $agent_status_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates agent status.
#
# POST /agent-status/{InstanceId}/{AgentStatusId}
# operationId: UpdateAgentStatus
export def "update-agent-status" [
  instance_id: string
  agent_status_id: string
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
  --name: string # The name of the agent status.
  --description: string # The description of the agent status.
  --state: string@state-completer # The state of the agent status.
  --display-order: int # The display order of the agent status.
  --reset-order-number: oneof<nothing, bool> # A number indicating the reset order of the agent status.
]: any -> any {
  $in | http-request {
    method: post
    path: "/agent-status/{InstanceId}/{AgentStatusId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AgentStatusId, var: agent_status_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: State, var: state}, {name: DisplayOrder, var: display_order}, {name: ResetOrderNumber, var: reset_order_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, agent_status_id: $agent_status_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, state: $state, display_order: $display_order, reset_order_number: $reset_order_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the specified contact. Contact information remains available in Amazon Connect for 24 months, and then it is deleted. Only data from November 12, 2021, and later is returned by this API.
#
# GET /contacts/{InstanceId}/{ContactId}
# Returns: record<Contact: record<Arn: string, Id: string, InitialContactId: string, PreviousContactId: string, InitiationMethod: string, Name: string, Description: string, Channel: string, QueueInfo: record<Id: string, EnqueueTimestamp: string>, AgentInfo: record<Id: string, ConnectedToAgentTimestamp: string>, InitiationTimestamp: string, DisconnectTimestamp: string, LastUpdateTimestamp: string, ScheduledTimestamp: string, RelatedContactId: string, WisdomInfo: record<SessionArn: string>>>
# operationId: DescribeContact
export def "describe-contact" [
  instance_id: string
  contact_id: string
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
    path: "/contacts/{InstanceId}/{ContactId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_id: $contact_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Adds or updates user-defined contact information associated with the specified contact. At least one field to be updated must be present in the request. You can add or update user-defined contact information for both ongoing and completed contacts.
#
# POST /contacts/{InstanceId}/{ContactId}
# Returns: record
# operationId: UpdateContact
export def "update-contact" [
  instance_id: string
  contact_id: string
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
  --name: string # The name of the contact.
  --description: string # The description of the contact.
  --references: record # Well-formed data on contact, shown to agents on Contact Control Panel (CCP).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts/{InstanceId}/{ContactId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: References, var: references}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_id: $contact_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, references: $references
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the specified instance attribute.
#
# GET /instance/{InstanceId}/attribute/{AttributeType}
# Returns: record<Attribute: record<AttributeType: string, Value: string>>
# operationId: DescribeInstanceAttribute
export def "describe-instance-attribute" [
  instance_id: string
  attribute_type: string@attribute-type-completer
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
    path: "/instance/{InstanceId}/attribute/{AttributeType}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AttributeType, var: attribute_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, attribute_type: $attribute_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the value for the specified attribute type.
#
# POST /instance/{InstanceId}/attribute/{AttributeType}
# operationId: UpdateInstanceAttribute
export def "update-instance-attribute" [
  instance_id: string
  attribute_type: string@attribute-type-completer
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
  value: string # The value for the attribute. Maximum character limit is 100.
]: any -> any {
  $in | http-request {
    method: post
    path: "/instance/{InstanceId}/attribute/{AttributeType}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AttributeType, var: attribute_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, attribute_type: $attribute_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Retrieves the current storage configurations for the specified resource type, association ID, and instance ID.
#
# GET /instance/{InstanceId}/storage-config/{AssociationId}
# Returns: record<StorageConfig: record<AssociationId: string, StorageType: string, S3Config: record<BucketName: string, BucketPrefix: string, EncryptionConfig: record>, KinesisVideoStreamConfig: record<Prefix: string, RetentionPeriodHours: int, EncryptionConfig: record>, KinesisStreamConfig: record<StreamArn: string>, KinesisFirehoseConfig: record<FirehoseArn: string>>>
# operationId: DescribeInstanceStorageConfig
export def "describe-instance-storage-config" [
  instance_id: string
  association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type. (required)
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
    path: "/instance/{InstanceId}/storage-config/{AssociationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AssociationId, var: association_id}]
    query: [{name: resourceType, var: resource_type, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, association_id: $association_id, resource_type: $resource_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Removes the storage type configurations for the specified resource type and association ID.
#
# DELETE /instance/{InstanceId}/storage-config/{AssociationId}
# operationId: DisassociateInstanceStorageConfig
export def "disassociate-instance-storage-config" [
  instance_id: string
  association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type. (required)
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
    path: "/instance/{InstanceId}/storage-config/{AssociationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AssociationId, var: association_id}]
    query: [{name: resourceType, var: resource_type, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, association_id: $association_id, resource_type: $resource_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates an existing configuration for a resource type. This API is idempotent.
#
# POST /instance/{InstanceId}/storage-config/{AssociationId}
# operationId: UpdateInstanceStorageConfig
export def "update-instance-storage-config" [
  instance_id: string
  association_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  storage_config: record # The storage configuration for the instance. — shape: {AssociationId?: string, StorageType?: "S3"|"KINESIS_VIDEO_STREAM"|"KINESIS_STREAM"|"KINESIS_FIREHOSE", S3Config?: record, KinesisVideoStreamConfig?: record, KinesisStreamConfig?: record, KinesisFirehoseConfig?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/instance/{InstanceId}/storage-config/{AssociationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AssociationId, var: association_id}]
    query: [{name: resourceType, var: resource_type, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StorageConfig, var: storage_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, association_id: $association_id, resource_type: $resource_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, storage_config: $storage_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details and status of a phone number that’s claimed to your Amazon Connect instance or traffic distribution group. If the number is claimed to a traffic distribution group, and you are calling in the Amazon Web Services Region where the traffic distribution group was created, you can use either a phone number ARN or UUID value for the PhoneNumberId URI request parameter. However, if the number is claimed to a traffic distribution group and you are calling this API in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# GET /phone-number/{PhoneNumberId}
# Returns: record<ClaimedPhoneNumberSummary: record<PhoneNumberId: string, PhoneNumberArn: string, PhoneNumber: string, PhoneNumberCountryCode: string, PhoneNumberType: string, PhoneNumberDescription: string, TargetArn: string, Tags: record, PhoneNumberStatus: record<Status: string, Message: string>>>
# operationId: DescribePhoneNumber
export def "describe-phone-number" [
  phone_number_id: string
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
    path: "/phone-number/{PhoneNumberId}"
    path_params: [{name: PhoneNumberId, var: phone_number_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Releases a phone number previously claimed to an Amazon Connect instance or traffic distribution group. You can call this API only in the Amazon Web Services Region where the number was claimed. To release phone numbers from a traffic distribution group, use the ReleasePhoneNumber API, not the Amazon Connect console. After releasing a phone number, the phone number enters into a cooldown period of 30 days. It cannot be searched for or claimed again until the period has ended. If you accidentally release a phone number, contact Amazon Web Services Support.
#
# DELETE /phone-number/{PhoneNumberId}
# operationId: ReleasePhoneNumber
export def "release-phone-number" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
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
    path: "/phone-number/{PhoneNumberId}"
    path_params: [{name: PhoneNumberId, var: phone_number_id}]
    query: [{name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates your claimed phone number from its current Amazon Connect instance or traffic distribution group to another Amazon Connect instance or traffic distribution group in the same Amazon Web Services Region. You can call DescribePhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_DescribePhoneNumber.html) API to verify the status of a previous UpdatePhoneNumber (https://docs.aws.amazon.com/connect/latest/APIReference/API_UpdatePhoneNumber.html) operation.
#
# PUT /phone-number/{PhoneNumberId}
# Returns: record<PhoneNumberId: string, PhoneNumberArn: string>
# operationId: UpdatePhoneNumber
export def "update-phone-number" [
  phone_number_id: string
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
  target_arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/phone-number/{PhoneNumberId}"
    path_params: [{name: PhoneNumberId, var: phone_number_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetArn, var: target_arn}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target_arn: $target_arn, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Describes the specified queue.
#
# GET /queues/{InstanceId}/{QueueId}
# Returns: record<Queue: record<Name: string, QueueArn: string, QueueId: string, Description: string, OutboundCallerConfig: record<OutboundCallerIdName: string, OutboundCallerIdNumberId: string, OutboundFlowId: string>, HoursOfOperationId: string, MaxContacts: int, Status: string, Tags: record>>
# operationId: DescribeQueue
export def "describe-queue" [
  instance_id: string
  queue_id: string
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
    path: "/queues/{InstanceId}/{QueueId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified routing profile.
#
# GET /routing-profiles/{InstanceId}/{RoutingProfileId}
# Returns: record<RoutingProfile: record<InstanceId: string, Name: string, RoutingProfileArn: string, RoutingProfileId: string, Description: string, MediaConcurrencies: list<record>, DefaultOutboundQueueId: string, Tags: record, NumberOfAssociatedQueues: int, NumberOfAssociatedUsers: int>>
# operationId: DescribeRoutingProfile
export def "describe-routing-profile" [
  instance_id: string
  routing_profile_id: string
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
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the hierarchy structure of the specified Amazon Connect instance.
#
# GET /user-hierarchy-structure/{InstanceId}
# Returns: record<HierarchyStructure: record<LevelOne: record<Id: string, Arn: string, Name: string>, LevelTwo: record<Id: string, Arn: string, Name: string>, LevelThree: record<Id: string, Arn: string, Name: string>, LevelFour: record<Id: string, Arn: string, Name: string>, LevelFive: record<Id: string, Arn: string, Name: string>>>
# operationId: DescribeUserHierarchyStructure
export def "describe-user-hierarchy-structure" [
  instance_id: string
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
    path: "/user-hierarchy-structure/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the user hierarchy structure: add, remove, and rename user hierarchy levels.
#
# POST /user-hierarchy-structure/{InstanceId}
# operationId: UpdateUserHierarchyStructure
export def "update-user-hierarchy-structure" [
  instance_id: string
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
  hierarchy_structure: record # Contains information about the level hierarchy to update. — shape: {LevelOne?: record, LevelTwo?: record, LevelThree?: record, LevelFour?: record, LevelFive?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/user-hierarchy-structure/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: HierarchyStructure, var: hierarchy_structure}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hierarchy_structure: $hierarchy_structure
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified vocabulary.
#
# GET /vocabulary/{InstanceId}/{VocabularyId}
# Returns: record<Vocabulary: record<Name: string, Id: string, Arn: string, LanguageCode: string, State: string, LastModifiedTime: string, FailureReason: string, Content: string, Tags: record>>
# operationId: DescribeVocabulary
export def "describe-vocabulary" [
  instance_id: string
  vocabulary_id: string
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
    path: "/vocabulary/{InstanceId}/{VocabularyId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: VocabularyId, var: vocabulary_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, vocabulary_id: $vocabulary_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Revokes access to integrated applications from Amazon Connect.
#
# DELETE /instance/{InstanceId}/approved-origin
# operationId: DisassociateApprovedOrigin
export def "disassociate-approved-origin" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin: string # The domain URL of the integrated application. (required)
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
    path: "/instance/{InstanceId}/approved-origin"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: origin, var: origin, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, origin: $origin, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Remove the Lambda function from the dropdown options available in the relevant flow blocks.
#
# DELETE /instance/{InstanceId}/lambda-function
# operationId: DisassociateLambdaFunction
export def "disassociate-lambda-function" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --function-arn: string # The Amazon Resource Name (ARN) of the Lambda function being disassociated. (required)
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
    path: "/instance/{InstanceId}/lambda-function"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: functionArn, var: function_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, function_arn: $function_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Revokes authorization from the specified instance to access the specified Amazon Lex bot.
#
# DELETE /instance/{InstanceId}/lex-bot
# operationId: DisassociateLexBot
export def "disassociate-lex-bot" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bot-name: string # The name of the Amazon Lex bot. Maximum character limit of 50. (required)
  --lex-region: string # The Amazon Web Services Region in which the Amazon Lex bot has been created. (required)
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
    path: "/instance/{InstanceId}/lex-bot"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: botName, var: bot_name, required: true}, {name: lexRegion, var: lex_region, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, bot_name: $bot_name, lex_region: $lex_region, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the flow association from a phone number claimed to your Amazon Connect instance. If the number is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the PhoneNumberId URI request parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# DELETE /phone-number/{PhoneNumberId}/contact-flow
# operationId: DisassociatePhoneNumberContactFlow
export def "disassociate-phone-number-contact-flow" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance. (required)
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
    path: "/phone-number/{PhoneNumberId}/contact-flow"
    path_params: [{name: PhoneNumberId, var: phone_number_id}]
    query: [{name: instanceId, var: instance_id, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    phone_number_id: $phone_number_id, instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Disassociates a set of quick connects from a queue.
#
# POST /queues/{InstanceId}/{QueueId}/disassociate-quick-connects
# operationId: DisassociateQueueQuickConnects
export def "disassociate-queue-quick-connects" [
  instance_id: string
  queue_id: string
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
  quick_connect_ids: list<string> # The quick connects to disassociate from the queue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/queues/{InstanceId}/{QueueId}/disassociate-quick-connects"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: QuickConnectIds, var: quick_connect_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, quick_connect_ids: $quick_connect_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a set of queues from a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/disassociate-queues
# operationId: DisassociateRoutingProfileQueues
export def "disassociate-routing-profile-queues" [
  instance_id: string
  routing_profile_id: string
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
  queue_references: list # The queues to disassociate from this routing profile. — item shape: {QueueId: string, Channel: "VOICE"|"CHAT"|"TASK"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}/disassociate-queues"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: QueueReferences, var: queue_references}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, queue_references: $queue_references
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Deletes the specified security key.
#
# DELETE /instance/{InstanceId}/security-key/{AssociationId}
# operationId: DisassociateSecurityKey
export def "disassociate-security-key" [
  instance_id: string
  association_id: string
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
    path: "/instance/{InstanceId}/security-key/{AssociationId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: AssociationId, var: association_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, association_id: $association_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dismisses contacts from an agent’s CCP and returns the agent to an available state, which allows the agent to receive a new routed contact. Contacts can only be dismissed if they are in a MISSED, ERROR, ENDED, or REJECTED state in the Agent Event Stream (https://docs.aws.amazon.com/connect/latest/adminguide/about-contact-states.html).
#
# POST /users/{InstanceId}/{UserId}/contact
# Returns: record
# operationId: DismissUserContact
export def "dismiss-user-contact" [
  instance_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  contact_id: string # The identifier of the contact.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{InstanceId}/{UserId}/contact"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContactId, var: contact_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the contact attributes for the specified contact.
#
# GET /contact/attributes/{InstanceId}/{InitialContactId}
# Returns: record<Attributes: record>
# operationId: GetContactAttributes
export def "get-contact-attributes" [
  instance_id: string
  initial_contact_id: string
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
    path: "/contact/attributes/{InstanceId}/{InitialContactId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: InitialContactId, var: initial_contact_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, initial_contact_id: $initial_contact_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the real-time metric data from the specified Amazon Connect instance. For a description of each metric, see Real-time Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html) in the Amazon Connect Administrator Guide.
#
# POST /metrics/current/{InstanceId}
# Returns: record<NextToken: string, MetricResults: table<Dimensions: record, Collections: list>, DataSnapshotTime: string, ApproximateTotalCount: int>
# operationId: GetCurrentMetricData
export def "get-current-metric-data" [
  instance_id: string
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
  filters: record # Contains the filter to apply when retrieving metrics. — shape: {Queues?: list<string>, Channels?: list<string>, RoutingProfiles?: list<string>}
  --groupings: list<string> # The grouping applied to the metrics returned. For example, when grouped by QUEUE, the metrics returned apply to each queue rather than aggregated for all queues. If you group by CHANNEL, you should include a Channels filter. VOICE, CHAT, and TASK channels are supported. If you group by ROUTING_PROFILE, you must include either a queue or routing profile filter. In addition, a routing profile filter is required for metrics CONTACTS_SCHEDULED, CONTACTS_IN_QUEUE, and OLDEST_CONTACT_AGE. If no Grouping is included in the request, a summary of metrics is returned.
  current_metrics: list # The metrics to retrieve. Specify the name and unit for each metric. The following metrics are available. For a description of all the metrics, see Real-time Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html) in the Amazon Connect Administrator Guide. AGENTS_AFTER_CONTACT_WORK Unit: COUNT Name in real-time metrics report: ACW (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#aftercallwork-real-time) AGENTS_AVAILABLE Unit: COUNT Name in real-time metrics report: Available (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#available-real-time) AGENTS_ERROR Unit: COUNT Name in real-time metrics report: Error (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#error-real-time) AGENTS_NON_PRODUCTIVE Unit: COUNT Name in real-time metrics report: NPT (Non-Productive Time) (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#non-productive-time-real-time) AGENTS_ON_CALL Unit: COUNT Name in real-time metrics report: On contact (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#on-call-real-time) AGENTS_ON_CONTACT Unit: COUNT Name in real-time metrics report: On contact (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#on-call-real-time) AGENTS_ONLINE Unit: COUNT Name in real-time metrics report: Online (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#online-real-time) AGENTS_STAFFED Unit: COUNT Name in real-time metrics report: Staffed (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#staffed-real-time) CONTACTS_IN_QUEUE Unit: COUNT Name in real-time metrics report: In queue (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#in-queue-real-time) CONTACTS_SCHEDULED Unit: COUNT Name in real-time metrics report: Scheduled (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#scheduled-real-time) OLDEST_CONTACT_AGE Unit: SECONDS When you use groupings, Unit says SECONDS and the Value is returned in SECONDS. When you do not use groupings, Unit says SECONDS but the Value is returned in MILLISECONDS. For example, if you get a response like this: { "Metric": { "Name": "OLDEST_CONTACT_AGE", "Unit": "SECONDS" }, "Value": 24113.0 } The actual OLDEST_CONTACT_AGE is 24 seconds. Name in real-time metrics report: Oldest (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#oldest-real-time) SLOTS_ACTIVE Unit: COUNT Name in real-time metrics report: Active (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#active-real-time) SLOTS_AVAILABLE Unit: COUNT Name in real-time metrics report: Availability (https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-definitions.html#availability-real-time) — item shape: {Name?: "AGENTS_ONLINE"|"AGENTS_AVAILABLE"|"AGENTS_ON_CALL"|"AGENTS_NON_PRODUCTIVE"|"AGENTS_AFTER_CONTACT_WORK"|"AGENTS_ERROR"|"AGENTS_STAFFED"|"CONTACTS_IN_QUEUE"|"OLDEST_CONTACT_AGE"|"CONTACTS_SCHEDULED"|"AGENTS_ON_CONTACT"|"SLOTS_ACTIVE"|"SLOTS_AVAILABLE", Unit?: "SECONDS"|"COUNT"|"PERCENT"}
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. The token expires after 5 minutes from the time it is created. Subsequent requests that use the token must use the same request parameters as the request that generated the token. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --sort-criteria: list # The way to sort the resulting response based on metrics. You can enter one sort criteria. By default resources are sorted based on AGENTS_ONLINE, DESCENDING. The metric collection is sorted based on the input metrics. Note the following: Sorting on SLOTS_ACTIVE and SLOTS_AVAILABLE is not supported. — item shape: {SortByMetric?: "AGENTS_ONLINE"|"AGENTS_AVAILABLE"|"AGENTS_ON_CALL"|"AGENTS_NON_PRODUCTIVE"|"AGENTS_AFTER_CONTACT_WORK"|"AGENTS_ERROR"|"AGENTS_STAFFED"|"CONTACTS_IN_QUEUE"|"OLDEST_CONTACT_AGE"|"CONTACTS_SCHEDULED"|"AGENTS_ON_CONTACT"|"SLOTS_ACTIVE"|"SLOTS_AVAILABLE", SortOrder?: "ASCENDING"|"DESCENDING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metrics/current/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: Groupings, var: groupings}, {name: CurrentMetrics, var: current_metrics}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: SortCriteria, var: sort_criteria}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, groupings: $groupings, current_metrics: $current_metrics, body_next_token: $body_next_token, body_max_results: $body_max_results, sort_criteria: $sort_criteria
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the real-time active user data from the specified Amazon Connect instance.
#
# POST /metrics/userdata/{InstanceId}
# Returns: record<NextToken: string, UserDataList: table<User: record, RoutingProfile: record, HierarchyPath: record, Status: record, AvailableSlotsByChannel: record, MaxSlotsByChannel: record, ActiveSlotsByChannel: record, Contacts: list, NextStatus: string>, ApproximateTotalCount: int>
# operationId: GetCurrentUserData
export def "get-current-user-data" [
  instance_id: string
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
  filters: record # A filter for the user data. — shape: {Queues?: list<string>, ContactFilter?: record, RoutingProfiles?: list<string>, Agents?: list<string>, UserHierarchyGroups?: list<string>}
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metrics/userdata/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a token for federation. This API doesn't support root users. If you try to invoke GetFederationToken with root credentials, an error message similar to the following one appears: Provided identity: Principal: .... User: .... cannot be used for federation with Amazon Connect
#
# GET /user/federate/{InstanceId}
# Returns: record<Credentials: record<AccessToken: string, AccessTokenExpiration: string, RefreshToken: string, RefreshTokenExpiration: string>, SignInUrl: string, UserArn: string, UserId: string>
# operationId: GetFederationToken
export def "get-federation-token" [
  instance_id: string
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
    path: "/user/federate/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets historical metric data from the specified Amazon Connect instance. For a description of each historical metric, see Historical Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator Guide.
#
# POST /metrics/historical/{InstanceId}
# Returns: record<NextToken: string, MetricResults: table<Dimensions: record, Collections: list>>
# operationId: GetMetricData
export def "get-metric-data" [
  instance_id: string
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
  start_time: string # The timestamp, in UNIX Epoch time format, at which to start the reporting interval for the retrieval of historical metrics data. The time must be specified using a multiple of 5 minutes, such as 10:05, 10:10, 10:15. The start time cannot be earlier than 24 hours before the time of the request. Historical metrics are available only for 24 hours. (format: date-time)
  end_time: string # The timestamp, in UNIX Epoch time format, at which to end the reporting interval for the retrieval of historical metrics data. The time must be specified using an interval of 5 minutes, such as 11:00, 11:05, 11:10, and must be later than the start time timestamp. The time range between the start and end time must be less than 24 hours. (format: date-time)
  filters: record # Contains the filter to apply when retrieving metrics. — shape: {Queues?: list<string>, Channels?: list<string>, RoutingProfiles?: list<string>}
  --groupings: list<string> # The grouping applied to the metrics returned. For example, when results are grouped by queue, the metrics returned are grouped by queue. The values returned apply to the metrics for each queue rather than aggregated for all queues. If no grouping is specified, a summary of metrics for all queues is returned.
  historical_metrics: list # The metrics to retrieve. Specify the name, unit, and statistic for each metric. The following historical metrics are available. For a description of each metric, see Historical Metrics Definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator Guide. This API does not support a contacts incoming metric (there's no CONTACTS_INCOMING metric missing from the documented list). ABANDON_TIME Unit: SECONDS Statistic: AVG AFTER_CONTACT_WORK_TIME Unit: SECONDS Statistic: AVG API_CONTACTS_HANDLED Unit: COUNT Statistic: SUM CALLBACK_CONTACTS_HANDLED Unit: COUNT Statistic: SUM CONTACTS_ABANDONED Unit: COUNT Statistic: SUM CONTACTS_AGENT_HUNG_UP_FIRST Unit: COUNT Statistic: SUM CONTACTS_CONSULTED Unit: COUNT Statistic: SUM CONTACTS_HANDLED Unit: COUNT Statistic: SUM CONTACTS_HANDLED_INCOMING Unit: COUNT Statistic: SUM CONTACTS_HANDLED_OUTBOUND Unit: COUNT Statistic: SUM CONTACTS_HOLD_ABANDONS Unit: COUNT Statistic: SUM CONTACTS_MISSED Unit: COUNT Statistic: SUM CONTACTS_QUEUED Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_IN Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_IN_FROM_QUEUE Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_OUT Unit: COUNT Statistic: SUM CONTACTS_TRANSFERRED_OUT_FROM_QUEUE Unit: COUNT Statistic: SUM HANDLE_TIME Unit: SECONDS Statistic: AVG HOLD_TIME Unit: SECONDS Statistic: AVG INTERACTION_AND_HOLD_TIME Unit: SECONDS Statistic: AVG INTERACTION_TIME Unit: SECONDS Statistic: AVG OCCUPANCY Unit: PERCENT Statistic: AVG QUEUE_ANSWER_TIME Unit: SECONDS Statistic: AVG QUEUED_TIME Unit: SECONDS Statistic: MAX SERVICE_LEVEL You can include up to 20 SERVICE_LEVEL metrics in a request. Unit: PERCENT Statistic: AVG Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). — item shape: {Name?: "CONTACTS_QUEUED"|"CONTACTS_HANDLED"|"CONTACTS_ABANDONED"|"CONTACTS_CONSULTED"|"CONTACTS_AGENT_HUNG_UP_FIRST"|"CONTACTS_HANDLED_INCOMING"|"CONTACTS_HANDLED_OUTBOUND"|"CONTACTS_HOLD_ABANDONS"|"CONTACTS_TRANSFERRED_IN"|"CONTACTS_TRANSFERRED_OUT"|"CONTACTS_TRANSFERRED_IN_FROM_QUEUE"|"CONTACTS_TRANSFERRED_OUT_FROM_QUEUE"|"CONTACTS_MISSED"|"CALLBACK_CONTACTS_HANDLED"|"API_CONTACTS_HANDLED"|"OCCUPANCY"|"HANDLE_TIME"|"AFTER_CONTACT_WORK_TIME"|"QUEUED_TIME"|"ABANDON_TIME"|"QUEUE_ANSWER_TIME"|"HOLD_TIME"|"INTERACTION_TIME"|"INTERACTION_AND_HOLD_TIME"|"SERVICE_LEVEL", ... (3 more fields)}
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metrics/historical/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: Filters, var: filters}, {name: Groupings, var: groupings}, {name: HistoricalMetrics, var: historical_metrics}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, start_time: $start_time, end_time: $end_time, filters: $filters, groupings: $groupings, historical_metrics: $historical_metrics, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets metric data from the specified Amazon Connect instance. GetMetricDataV2 offers more features than GetMetricData (https://docs.aws.amazon.com/connect/latest/APIReference/API_GetMetricData.html), the previous version of this API. It has new metrics, offers filtering at a metric level, and offers the ability to filter and group data by channels, queues, routing profiles, agents, and agent hierarchy levels. It can retrieve historical data for the last 14 days, in 24-hour intervals. For a description of the historical metrics that are supported by GetMetricDataV2 and GetMetricData, see Historical metrics definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator's Guide. This API is not available in the Amazon Web Services GovCloud (US) Regions.
#
# POST /metrics/data
# Returns: record<NextToken: string, MetricResults: table<Dimensions: record, Collections: list>>
# operationId: GetMetricDataV2
export def "get-metric-data-v2" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. This includes the instanceId an Amazon Connect instance.
  start_time: string # The timestamp, in UNIX Epoch time format, at which to start the reporting interval for the retrieval of historical metrics data. The time must be before the end time timestamp. The time range between the start and end time must be less than 24 hours. The start time cannot be earlier than 14 days before the time of the request. Historical metrics are available for 14 days. (format: date-time)
  end_time: string # The timestamp, in UNIX Epoch time format, at which to end the reporting interval for the retrieval of historical metrics data. The time must be later than the start time timestamp. It cannot be later than the current timestamp. The time range between the start and end time must be less than 24 hours. (format: date-time)
  filters: list # The filters to apply to returned metrics. You can filter on the following resources: Queues Routing profiles Agents Channels User hierarchy groups At least one filter must be passed from queues, routing profiles, agents, or user hierarchy groups. To filter by phone number, see Create a historical metrics report (https://docs.aws.amazon.com/connect/latest/adminguide/create-historical-metrics-report.html) in the Amazon Connect Administrator's Guide. Note the following limits: Filter keys: A maximum of 5 filter keys are supported in a single request. Valid filter keys: QUEUE | ROUTING_PROFILE | AGENT | CHANNEL | AGENT_HIERARCHY_LEVEL_ONE | AGENT_HIERARCHY_LEVEL_TWO | AGENT_HIERARCHY_LEVEL_THREE | AGENT_HIERARCHY_LEVEL_FOUR | AGENT_HIERARCHY_LEVEL_FIVE Filter values: A maximum of 100 filter values are supported in a single request. For example, a GetMetricDataV2 request can filter by 50 queues, 35 agents, and 15 routing profiles for a total of 100 filter values. VOICE, CHAT, and TASK are valid filterValue for the CHANNEL filter key. — item shape: {FilterKey?: string, FilterValues?: list<string>}
  --groupings: list<string> # The grouping applied to the metrics that are returned. For example, when results are grouped by queue, the metrics returned are grouped by queue. The values that are returned apply to the metrics for each queue. They are not aggregated for all queues. If no grouping is specified, a summary of all metrics is returned. Valid grouping keys: QUEUE | ROUTING_PROFILE | AGENT | CHANNEL | AGENT_HIERARCHY_LEVEL_ONE | AGENT_HIERARCHY_LEVEL_TWO | AGENT_HIERARCHY_LEVEL_THREE | AGENT_HIERARCHY_LEVEL_FOUR | AGENT_HIERARCHY_LEVEL_FIVE
  metrics: list # The metrics to retrieve. Specify the name, groupings, and filters for each metric. The following historical metrics are available. For a description of each metric, see Historical metrics definitions (https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics-definitions.html) in the Amazon Connect Administrator's Guide. AGENT_ADHERENT_TIME This metric is available only in Amazon Web Services Regions where Forecasting, capacity planning, and scheduling (https://docs.aws.amazon.com/connect/latest/adminguide/regions.html#optimization_region) is available. Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AGENT_NON_RESPONSE Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AGENT_OCCUPANCY Unit: Percentage Valid groupings and filters: Routing Profile, Agent, Agent Hierarchy AGENT_SCHEDULE_ADHERENCE This metric is available only in Amazon Web Services Regions where Forecasting, capacity planning, and scheduling (https://docs.aws.amazon.com/connect/latest/adminguide/regions.html#optimization_region) is available. Unit: Percent Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AGENT_SCHEDULED_TIME This metric is available only in Amazon Web Services Regions where Forecasting, capacity planning, and scheduling (https://docs.aws.amazon.com/connect/latest/adminguide/regions.html#optimization_region) is available. Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_ABANDON_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_AFTER_CONTACT_WORK_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_AGENT_CONNECTING_TIME Unit: Seconds Valid metric filter key: INITIATION_METHOD. For now, this metric only supports the following as INITIATION_METHOD: INBOUND | OUTBOUND | CALLBACK | API Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_HANDLE_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_HOLD_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_INTERACTION_AND_HOLD_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy AVG_INTERACTION_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile AVG_QUEUE_ANSWER_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile CONTACTS_ABANDONED Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_CREATED Unit: Count Valid metric filter key: INITIATION_METHOD Valid groupings and filters: Queue, Channel, Routing Profile CONTACTS_HANDLED Unit: Count Valid metric filter key: INITIATION_METHOD, DISCONNECT_REASON Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_HOLD_ABANDONS Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_QUEUED Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_TRANSFERRED_OUT Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_TRANSFERRED_OUT_BY_AGENT Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy CONTACTS_TRANSFERRED_OUT_FROM_QUEUE Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy MAX_QUEUED_TIME Unit: Seconds Valid groupings and filters: Queue, Channel, Routing Profile, Agent, Agent Hierarchy SERVICE_LEVEL You can include up to 20 SERVICE_LEVEL metrics in a request. Unit: Percent Valid groupings and filters: Queue, Channel, Routing Profile Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). SUM_CONTACTS_ANSWERED_IN_X Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). SUM_CONTACTS_ABANDONED_IN_X Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile Threshold: For ThresholdValue, enter any whole number from 1 to 604800 (inclusive), in seconds. For Comparison, you must enter LT (for "Less than"). SUM_CONTACTS_DISCONNECTED Valid metric filter key: DISCONNECT_REASON Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile SUM_RETRY_CALLBACK_ATTEMPTS Unit: Count Valid groupings and filters: Queue, Channel, Routing Profile — item shape: {Name?: string, Threshold?: list, MetricFilters?: list}
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metrics/data"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: Filters, var: filters}, {name: Groupings, var: groupings}, {name: Metrics, var: metrics}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, start_time: $start_time, end_time: $end_time, filters: $filters, groupings: $groupings, metrics: $metrics, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the current traffic distribution for a given traffic distribution group.
#
# GET /traffic-distribution/{Id}
# Returns: record<TelephonyConfig: record<Distributions: list<record>>, Id: string, Arn: string>
# operationId: GetTrafficDistribution
export def "get-traffic-distribution" [
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
    path: "/traffic-distribution/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the traffic distribution for a given traffic distribution group. For more information about updating a traffic distribution group, see Update telephony traffic distribution across Amazon Web Services Regions (https://docs.aws.amazon.com/connect/latest/adminguide/update-telephony-traffic-distribution.html) in the Amazon Connect Administrator Guide.
#
# PUT /traffic-distribution/{Id}
# Returns: record
# operationId: UpdateTrafficDistribution
export def "update-traffic-distribution" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --telephony-config: record # The distribution of traffic between the instance and its replicas. — shape: {Distributions?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/traffic-distribution/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TelephonyConfig, var: telephony_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, telephony_config: $telephony_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all approved origins associated with the instance.
#
# GET /instance/{InstanceId}/approved-origins
# Returns: record<Origins: list<string>, NextToken: string>
# operationId: ListApprovedOrigins
export def "list-approved-origins" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/approved-origins"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. For the specified version of Amazon Lex, returns a paginated list of all the Amazon Lex bots currently associated with the instance. Use this API to returns both Amazon Lex V1 and V2 bots.
#
# GET /instance/{InstanceId}/bots
# Returns: record<LexBots: table<LexBot: record, LexV2Bot: record>, NextToken: string>
# operationId: ListBots
export def "list-bots" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --lex-version: string@lex-version-completer # The version of Amazon Lex or Amazon Lex V2. (required)
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/bots"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: lexVersion, var: lex_version, required: true}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, lex_version: $lex_version, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the flow modules for the specified Amazon Connect instance.
#
# GET /contact-flow-modules-summary/{InstanceId}
# Returns: record<ContactFlowModulesSummaryList: table<Id: string, Arn: string, Name: string, State: string>, NextToken: string>
# operationId: ListContactFlowModules
export def "list-contact-flow-modules" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --state: string@state-completer-1 # The state of the flow module.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/contact-flow-modules-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: state, var: state}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, state: $state, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the flows for the specified Amazon Connect instance. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html). For more information about flows, see Flows (https://docs.aws.amazon.com/connect/latest/adminguide/concepts-contact-flows.html) in the Amazon Connect Administrator Guide.
#
# GET /contact-flows-summary/{InstanceId}
# Returns: record<ContactFlowSummaryList: table<Id: string, Arn: string, Name: string, ContactFlowType: string, ContactFlowState: string>, NextToken: string>
# operationId: ListContactFlows
export def "list-contact-flows" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-flow-types: list<string> # The type of flow.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/contact-flows-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: contactFlowTypes, var: contact_flow_types, style: multi}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_types: $contact_flow_types, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. For the specified referenceTypes, returns a list of references associated with the contact.
#
# GET /contact/references/{InstanceId}/{ContactId}
# Returns: record<ReferenceSummaryList: table<Url: record, Attachment: record, String: record, Number: record, Date: record, Email: record>, NextToken: string>
# operationId: ListContactReferences
export def "list-contact-references" [
  instance_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference-types: list<string> # The type of reference. (required)
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. This is not expected to be set, because the value returned in the previous response is always null.
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/contact/references/{InstanceId}/{ContactId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}]
    query: [{name: referenceTypes, var: reference_types, style: multi, required: true}, {name: nextToken, var: next_token}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_id: $contact_id, reference_types: $reference_types, next_token: $next_token, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the default vocabularies for the specified Amazon Connect instance.
#
# POST /default-vocabulary-summary/{InstanceId}
# Returns: record<DefaultVocabularyList: table<InstanceId: string, LanguageCode: string, VocabularyId: string, VocabularyName: string>, NextToken: string>
# operationId: ListDefaultVocabularies
export def "list-default-vocabularies" [
  instance_id: string
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
  --language-code: string@language-code-completer # The language code of the vocabulary entries. For a list of languages and their corresponding language codes, see What is Amazon Transcribe? (https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-whatis.html)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/default-vocabulary-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LanguageCode, var: language_code}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, language_code: $language_code, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the hours of operation for the specified Amazon Connect instance. For more information about hours of operation, see Set the Hours of Operation for a Queue (https://docs.aws.amazon.com/connect/latest/adminguide/set-hours-operation.html) in the Amazon Connect Administrator Guide.
#
# GET /hours-of-operations-summary/{InstanceId}
# Returns: record<HoursOfOperationSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>
# operationId: ListHoursOfOperations
export def "list-hours-of-operations" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/hours-of-operations-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all attribute types for the given instance.
#
# GET /instance/{InstanceId}/attributes
# Returns: record<Attributes: table<AttributeType: string, Value: string>, NextToken: string>
# operationId: ListInstanceAttributes
export def "list-instance-attributes" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/attributes"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of storage configs for the identified instance and resource type.
#
# GET /instance/{InstanceId}/storage-configs
# Returns: record<StorageConfigs: table<AssociationId: string, StorageType: string, S3Config: record, KinesisVideoStreamConfig: record, KinesisStreamConfig: record, KinesisFirehoseConfig: record>, NextToken: string>
# operationId: ListInstanceStorageConfigs
export def "list-instance-storage-configs" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer # A valid resource type. (required)
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/storage-configs"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: resourceType, var: resource_type, required: true}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, resource_type: $resource_type, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all Lambda functions that display in the dropdown options in the relevant flow blocks.
#
# GET /instance/{InstanceId}/lambda-functions
# Returns: record<LambdaFunctions: list<string>, NextToken: string>
# operationId: ListLambdaFunctions
export def "list-lambda-functions" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/lambda-functions"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all the Amazon Lex V1 bots currently associated with the instance. To return both Amazon Lex V1 and V2 bots, use the ListBots (https://docs.aws.amazon.com/connect/latest/APIReference/API_ListBots.html) API.
#
# GET /instance/{InstanceId}/lex-bots
# Returns: record<LexBots: table<Name: string, LexRegion: string>, NextToken: string>
# operationId: ListLexBots
export def "list-lex-bots" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. If no value is specified, the default is 10.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/lex-bots"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the phone numbers for the specified Amazon Connect instance. For more information about phone numbers, see Set Up Phone Numbers for Your Contact Center (https://docs.aws.amazon.com/connect/latest/adminguide/contact-center-phone-number.html) in the Amazon Connect Administrator Guide. The phone number Arn value that is returned from each of the items in the PhoneNumberSummaryList (https://docs.aws.amazon.com/connect/latest/APIReference/API_ListPhoneNumbers.html#connect-ListPhoneNumbers-response-PhoneNumberSummaryList) cannot be used to tag phone number resources. It will fail with a ResourceNotFoundException. Instead, use the ListPhoneNumbersV2 (https://docs.aws.amazon.com/connect/latest/APIReference/API_ListPhoneNumbersV2.html) API. It returns the new phone number ARN that can be used to tag phone number resources.
#
# GET /phone-numbers-summary/{InstanceId}
# Returns: record<PhoneNumberSummaryList: table<Id: string, Arn: string, PhoneNumber: string, PhoneNumberType: string, PhoneNumberCountryCode: string>, NextToken: string>
# operationId: ListPhoneNumbers
export def "list-phone-numbers" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-number-types: list<string> # The type of phone number.
  --phone-number-country-codes: list<string> # The ISO country code.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/phone-numbers-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: phoneNumberTypes, var: phone_number_types, style: multi}, {name: phoneNumberCountryCodes, var: phone_number_country_codes, style: multi}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, phone_number_types: $phone_number_types, phone_number_country_codes: $phone_number_country_codes, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists phone numbers claimed to your Amazon Connect instance or traffic distribution group. If the provided TargetArn is a traffic distribution group, you can call this API in both Amazon Web Services Regions associated with traffic distribution group. For more information about phone numbers, see Set Up Phone Numbers for Your Contact Center (https://docs.aws.amazon.com/connect/latest/adminguide/contact-center-phone-number.html) in the Amazon Connect Administrator Guide.
#
# POST /phone-number/list
# Returns: record<NextToken: string, ListPhoneNumbersSummaryList: table<PhoneNumberId: string, PhoneNumberArn: string, PhoneNumber: string, PhoneNumberCountryCode: string, PhoneNumberType: string, TargetArn: string>>
# operationId: ListPhoneNumbersV2
export def "list-phone-numbers-v2" [
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
  --target-arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to. If TargetArn input is not provided, this API lists numbers claimed to all the Amazon Connect instances belonging to your account in the same Amazon Web Services Region as the request.
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --phone-number-country-codes: list<string> # The ISO country code.
  --phone-number-types: list<string> # The type of phone number.
  --phone-number-prefix: string # The prefix of the phone number. If provided, it must contain + as part of the country code.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-number/list"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetArn, var: target_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: PhoneNumberCountryCodes, var: phone_number_country_codes}, {name: PhoneNumberTypes, var: phone_number_types}, {name: PhoneNumberPrefix, var: phone_number_prefix}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target_arn: $target_arn, body_max_results: $body_max_results, body_next_token: $body_next_token, phone_number_country_codes: $phone_number_country_codes, phone_number_types: $phone_number_types, phone_number_prefix: $phone_number_prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the prompts for the specified Amazon Connect instance.
#
# GET /prompts-summary/{InstanceId}
# Returns: record<PromptSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>
# operationId: ListPrompts
export def "list-prompts" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/prompts-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Lists the quick connects associated with a queue.
#
# GET /queues/{InstanceId}/{QueueId}/quick-connects
# Returns: record<NextToken: string, QuickConnectSummaryList: table<Id: string, Arn: string, Name: string, QuickConnectType: string>>
# operationId: ListQueueQuickConnects
export def "list-queue-quick-connects" [
  instance_id: string
  queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/queues/{InstanceId}/{QueueId}/quick-connects"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the queues for the specified Amazon Connect instance. If you do not specify a QueueTypes parameter, both standard and agent queues are returned. This might cause an unexpected truncation of results if you have more than 1000 agents and you limit the number of results of the API call in code. For more information about queues, see Queues: Standard and Agent (https://docs.aws.amazon.com/connect/latest/adminguide/concepts-queues-standard-and-agent.html) in the Amazon Connect Administrator Guide.
#
# GET /queues-summary/{InstanceId}
# Returns: record<QueueSummaryList: table<Id: string, Arn: string, Name: string, QueueType: string>, NextToken: string>
# operationId: ListQueues
export def "list-queues" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --queue-types: list<string> # The type of queue.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/queues-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: queueTypes, var: queue_types, style: multi}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_types: $queue_types, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the queues associated with a routing profile.
#
# GET /routing-profiles/{InstanceId}/{RoutingProfileId}/queues
# Returns: record<NextToken: string, RoutingProfileQueueConfigSummaryList: table<QueueId: string, QueueArn: string, QueueName: string, Priority: int, Delay: int, Channel: string>>
# operationId: ListRoutingProfileQueues
export def "list-routing-profile-queues" [
  instance_id: string
  routing_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}/queues"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties associated with a set of queues for a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/queues
# operationId: UpdateRoutingProfileQueues
export def "update-routing-profile-queues" [
  instance_id: string
  routing_profile_id: string
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
  queue_configs: list # The queues to be updated for this routing profile. Queues must first be associated to the routing profile. You can do this using AssociateRoutingProfileQueues. — item shape: {QueueReference: record, Priority: int, Delay: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}/queues"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: QueueConfigs, var: queue_configs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, queue_configs: $queue_configs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides summary information about the routing profiles for the specified Amazon Connect instance. For more information about routing profiles, see Routing Profiles (https://docs.aws.amazon.com/connect/latest/adminguide/concepts-routing.html) and Create a Routing Profile (https://docs.aws.amazon.com/connect/latest/adminguide/routing-profiles.html) in the Amazon Connect Administrator Guide.
#
# GET /routing-profiles-summary/{InstanceId}
# Returns: record<RoutingProfileSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>
# operationId: ListRoutingProfiles
export def "list-routing-profiles" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/routing-profiles-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Returns a paginated list of all security keys associated with the instance.
#
# GET /instance/{InstanceId}/security-keys
# Returns: record<SecurityKeys: table<AssociationId: string, Key: string, CreationTime: string>, NextToken: string>
# operationId: ListSecurityKeys
export def "list-security-keys" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/instance/{InstanceId}/security-keys"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Lists the permissions granted to a security profile.
#
# GET /security-profiles-permissions/{InstanceId}/{SecurityProfileId}
# Returns: record<Permissions: list<string>, NextToken: string>
# operationId: ListSecurityProfilePermissions
export def "list-security-profile-permissions" [
  instance_id: string
  security_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/security-profiles-permissions/{InstanceId}/{SecurityProfileId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: SecurityProfileId, var: security_profile_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, security_profile_id: $security_profile_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides summary information about the security profiles for the specified Amazon Connect instance. For more information about security profiles, see Security Profiles (https://docs.aws.amazon.com/connect/latest/adminguide/connect-security-profiles.html) in the Amazon Connect Administrator Guide.
#
# GET /security-profiles-summary/{InstanceId}
# Returns: record<SecurityProfileSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>
# operationId: ListSecurityProfiles
export def "list-security-profiles" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/security-profiles-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for the specified resource. For sample policies that use tags, see Amazon Connect Identity-Based Policy Examples (https://docs.aws.amazon.com/connect/latest/adminguide/security_iam_id-based-policy-examples.html) in the Amazon Connect Administrator Guide.
#
# GET /tags/{resourceArn}
# Returns: record<tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified tags to the specified resource. Some of the supported resource types are agents, routing profiles, queues, quick connects, contact flows, agent statuses, hours of operation, phone numbers, security profiles, and task templates. For a complete list, see Tagging resources in Amazon Connect (https://docs.aws.amazon.com/connect/latest/adminguide/tagging.html). For sample policies that use tags, see Amazon Connect Identity-Based Policy Examples (https://docs.aws.amazon.com/connect/latest/adminguide/security_iam_id-based-policy-examples.html) in the Amazon Connect Administrator Guide.
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
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
  tags: record # The tags used to organize, track, or control access for this resource. For example, { "tags": {"key1":"value1", "key2":"value2"} }.
]: any -> any {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists traffic distribution groups.
#
# GET /traffic-distribution-groups
# Returns: record<NextToken: string, TrafficDistributionGroupSummaryList: table<Id: string, Arn: string, Name: string, InstanceArn: string, Status: string>>
# operationId: ListTrafficDistributionGroups
export def "list-traffic-distribution-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --instance-id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/traffic-distribution-groups"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: instanceId, var: instance_id}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, instance_id: $instance_id, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides summary information about the hierarchy groups for the specified Amazon Connect instance. For more information about agent hierarchies, see Set Up Agent Hierarchies (https://docs.aws.amazon.com/connect/latest/adminguide/agent-hierarchy.html) in the Amazon Connect Administrator Guide.
#
# GET /user-hierarchy-groups-summary/{InstanceId}
# Returns: record<UserHierarchyGroupSummaryList: table<Id: string, Arn: string, Name: string>, NextToken: string>
# operationId: ListUserHierarchyGroups
export def "list-user-hierarchy-groups" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/user-hierarchy-groups-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides summary information about the users for the specified Amazon Connect instance.
#
# GET /users-summary/{InstanceId}
# Returns: record<UserSummaryList: table<Id: string, Arn: string, Username: string>, NextToken: string>
# operationId: ListUsers
export def "list-users" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page. The default MaxResult size is 100.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/users-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates silent monitoring of a contact. The Contact Control Panel (CCP) of the user specified by userId will be set to silent monitoring mode on the contact.
#
# POST /contact/monitor
# Returns: record<ContactId: string, ContactArn: string>
# operationId: MonitorContact
export def "monitor-contact" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instanceId in the ARN of the instance.
  contact_id: string # The identifier of the contact.
  user_id: string # The identifier of the user account.
  --allowed-monitor-capabilities: list<string> # Specify which monitoring actions the user is allowed to take. For example, whether the user is allowed to escalate from silent monitoring to barge.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/monitor"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: UserId, var: user_id}, {name: AllowedMonitorCapabilities, var: allowed_monitor_capabilities}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, user_id: $user_id, allowed_monitor_capabilities: $allowed_monitor_capabilities, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the current status of a user or agent in Amazon Connect. If the agent is currently handling a contact, this sets the agent's next status. For more information, see Agent status (https://docs.aws.amazon.com/connect/latest/adminguide/metrics-agent-status.html) and Set your next status (https://docs.aws.amazon.com/connect/latest/adminguide/set-next-status.html) in the Amazon Connect Administrator Guide.
#
# PUT /users/{InstanceId}/{UserId}/status
# Returns: record
# operationId: PutUserStatus
export def "put-user-status" [
  instance_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  agent_status_id: string # The identifier of the agent status.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{InstanceId}/{UserId}/status"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AgentStatusId, var: agent_status_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, agent_status_id: $agent_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replicates an Amazon Connect instance in the specified Amazon Web Services Region. For more information about replicating an Amazon Connect instance, see Create a replica of your existing Amazon Connect instance (https://docs.aws.amazon.com/connect/latest/adminguide/create-replica-connect-instance.html) in the Amazon Connect Administrator Guide.
#
# POST /instance/{InstanceId}/replicate
# Returns: record<Id: string, Arn: string>
# operationId: ReplicateInstance
export def "replicate-instance" [
  instance_id: string
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
  replica_region: string # The Amazon Web Services Region where to replicate the Amazon Connect instance.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  replica_alias: string # The alias for the replicated instance. The ReplicaAlias must be unique. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/instance/{InstanceId}/replicate"
    path_params: [{name: InstanceId, var: instance_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicaRegion, var: replica_region}, {name: ClientToken, var: client_token}, {name: ReplicaAlias, var: replica_alias}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, replica_region: $replica_region, client_token: $client_token, replica_alias: $replica_alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When a contact is being recorded, and the recording has been suspended using SuspendContactRecording, this API resumes recording the call. Only voice recordings are supported at this time.
#
# POST /contact/resume-recording
# Returns: record
# operationId: ResumeContactRecording
export def "resume-contact-recording" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/resume-recording"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: InitialContactId, var: initial_contact_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, initial_contact_id: $initial_contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for available phone numbers that you can claim to your Amazon Connect instance or traffic distribution group. If the provided TargetArn is a traffic distribution group, you can call this API in both Amazon Web Services Regions associated with the traffic distribution group.
#
# POST /phone-number/search-available
# Returns: record<NextToken: string, AvailableNumbersList: table<PhoneNumber: string, PhoneNumberCountryCode: string, PhoneNumberType: string>>
# operationId: SearchAvailablePhoneNumbers
export def "search-available-phone-numbers" [
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
  target_arn: string # The Amazon Resource Name (ARN) for Amazon Connect instances or traffic distribution groups that phone numbers are claimed to.
  phone_number_country_code: string@phone-number-country-code-completer # The ISO country code.
  phone_number_type: string@phone-number-type-completer # The type of phone number.
  --phone-number-prefix: string # The prefix of the phone number. If provided, it must contain + as part of the country code.
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-number/search-available"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetArn, var: target_arn}, {name: PhoneNumberCountryCode, var: phone_number_country_code}, {name: PhoneNumberType, var: phone_number_type}, {name: PhoneNumberPrefix, var: phone_number_prefix}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target_arn: $target_arn, phone_number_country_code: $phone_number_country_code, phone_number_type: $phone_number_type, phone_number_prefix: $phone_number_prefix, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Searches queues in an Amazon Connect instance, with optional filtering.
#
# POST /search-queues
# Returns: record<Queues: table<Name: string, QueueArn: string, QueueId: string, Description: string, OutboundCallerConfig: record, HoursOfOperationId: string, MaxContacts: int, Status: string, Tags: record>, NextToken: string, ApproximateTotalCount: int>
# operationId: SearchQueues
export def "search-queues" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
  --search-criteria: record # The search criteria to be used to return queues. The name and description fields support "contains" queries with a minimum of 2 characters and a maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: list, AndConditions?: list, StringCondition?: record, QueueTypeCondition?: "STANDARD"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search-queues"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: SearchFilter, var: search_filter}, {name: SearchCriteria, var: search_criteria}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, body_next_token: $body_next_token, body_max_results: $body_max_results, search_filter: $search_filter, search_criteria: $search_criteria
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Searches routing profiles in an Amazon Connect instance, with optional filtering.
#
# POST /search-routing-profiles
# Returns: record<RoutingProfiles: table<InstanceId: string, Name: string, RoutingProfileArn: string, RoutingProfileId: string, Description: string, MediaConcurrencies: list, DefaultOutboundQueueId: string, Tags: record, NumberOfAssociatedQueues: int, NumberOfAssociatedUsers: int>, NextToken: string, ApproximateTotalCount: int>
# operationId: SearchRoutingProfiles
export def "search-routing-profiles" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
  --search-criteria: record # The search criteria to be used to return routing profiles. The name and description fields support "contains" queries with a minimum of 2 characters and a maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: list, AndConditions?: list, StringCondition?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search-routing-profiles"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: SearchFilter, var: search_filter}, {name: SearchCriteria, var: search_criteria}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, body_next_token: $body_next_token, body_max_results: $body_max_results, search_filter: $search_filter, search_criteria: $search_criteria
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Searches security profiles in an Amazon Connect instance, with optional filtering.
#
# POST /search-security-profiles
# Returns: record<SecurityProfiles: table<Id: string, OrganizationResourceId: string, Arn: string, SecurityProfileName: string, Description: string, Tags: record>, NextToken: string, ApproximateTotalCount: int>
# operationId: SearchSecurityProfiles
export def "search-security-profiles" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --search-criteria: record # The search criteria to be used to return security profiles. The name field support "contains" queries with a minimum of 2 characters and maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: list, AndConditions?: list, StringCondition?: record}
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search-security-profiles"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: SearchCriteria, var: search_criteria}, {name: SearchFilter, var: search_filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, body_next_token: $body_next_token, body_max_results: $body_max_results, search_criteria: $search_criteria, search_filter: $search_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches users in an Amazon Connect instance, with optional filtering. AfterContactWorkTimeLimit is returned in milliseconds.
#
# POST /search-users
# Returns: record<Users: table<Arn: string, DirectoryUserId: string, HierarchyGroupId: string, Id: string, IdentityInfo: record, PhoneConfig: record, RoutingProfileId: string, SecurityProfileIds: list, Tags: record, Username: string>, NextToken: string, ApproximateTotalCount: int>
# operationId: SearchUsers
export def "search-users" [
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
  --instance-id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --search-filter: record # Filters to be applied to search results. — shape: {TagFilter?: record}
  --search-criteria: record # The search criteria to be used to return users. The name and description fields support "contains" queries with a minimum of 2 characters and a maximum of 25 characters. Any queries with character lengths outside of this range will throw invalid results. — shape: {OrConditions?: list, AndConditions?: list, StringCondition?: record, HierarchyGroupCondition?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search-users"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: SearchFilter, var: search_filter}, {name: SearchCriteria, var: search_criteria}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, body_next_token: $body_next_token, body_max_results: $body_max_results, search_filter: $search_filter, search_criteria: $search_criteria
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for vocabularies within a specific Amazon Connect instance using State, NameStartsWith, and LanguageCode.
#
# POST /vocabulary-summary/{InstanceId}
# Returns: record<VocabularySummaryList: table<Name: string, Id: string, Arn: string, LanguageCode: string, State: string, LastModifiedTime: string, FailureReason: string>, NextToken: string>
# operationId: SearchVocabularies
export def "search-vocabularies" [
  instance_id: string
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
  --body-max-results: int # The maximum number of results to return per page. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: NextToken)
  --state: string@state-completer-2 # The current state of the custom vocabulary.
  --name-starts-with: string # The starting pattern of the name of the vocabulary.
  --language-code: string@language-code-completer # The language code of the vocabulary entries. For a list of languages and their corresponding language codes, see What is Amazon Transcribe? (https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-whatis.html)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vocabulary-summary/{InstanceId}"
    path_params: [{name: InstanceId, var: instance_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: State, var: state}, {name: NameStartsWith, var: name_starts_with}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token, state: $state, name_starts_with: $name_starts_with, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the CreateParticipantConnection (https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html) API in the Amazon Connect Participant Service. When a new chat contact is successfully created, clients must subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking CreateParticipantConnection (https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html) with WEBSOCKET and CONNECTION_CREDENTIALS. A 429 error occurs in the following situations: API rate limit is exceeded. API TPS throttling returns a TooManyRequests exception. The quota for concurrent active chats (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html) is exceeded. Active chat throttling returns a LimitExceededException. If you use the ChatDurationInMinutes parameter and receive a 400 error, your account may not support the ability to configure custom chat durations. For more information, contact Amazon Web Services Support. For more information about chat, see Chat (https://docs.aws.amazon.com/connect/latest/adminguide/chat.html) in the Amazon Connect Administrator Guide.
#
# PUT /contact/chat
# Returns: record<ContactId: string, ParticipantId: string, ParticipantToken: string, ContinuedFromContactId: string>
# operationId: StartChatContact
export def "start-chat-contact" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_flow_id: string # The identifier of the flow for initiating the chat. To see the ContactFlowId in the Amazon Connect console user interface, on the navigation menu go to Routing, Contact Flows. Choose the flow. On the flow page, under the name of the flow, choose Show additional flow information. The ContactFlowId is the last part of the ARN, shown here in bold: arn:aws:connect:us-west-2:xxxxxxxxxxxx:instance/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/contact-flow/846ec553-a005-41c0-8341-xxxxxxxxxxxx
  --attributes: record # A custom key-value pair using an attribute map. The attributes are standard Amazon Connect attributes. They can be accessed in flows just like any other contact attributes. There can be up to 32,768 UTF-8 bytes across all key-value pairs per contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
  participant_details: record # The customer's details. — shape: {DisplayName?: string}
  --initial-message: record # A chat message. — shape: {ContentType?: string, Content?: string}
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  --chat-duration-in-minutes: int # The total duration of the newly started chat session. If not specified, the chat session duration defaults to 25 hour. The minimum configurable time is 60 minutes. The maximum configurable time is 10,080 minutes (7 days).
  --supported-messaging-content-types: list<string> # The supported chat message content types. Supported types are text/plain, text/markdown, application/json, application/vnd.amazonaws.connect.message.interactive, and application/vnd.amazonaws.connect.message.interactive.response. Content types must always contain text/plain. You can then put any other supported type in the list. For example, all the following lists are valid because they contain text/plain: [text/plain, text/markdown, application/json], [text/markdown, text/plain], [text/plain, application/json, application/vnd.amazonaws.connect.message.interactive.response]. The type application/vnd.amazonaws.connect.message.interactive is required to use the Show view (https://docs.aws.amazon.com/connect/latest/adminguide/show-view-block.html) flow block.
  --persistent-chat: record # Enable persistent chats. For more information about enabling persistent chat, and for example use cases and how to configure for them, see Enable persistent chat (https://docs.aws.amazon.com/connect/latest/adminguide/chat-persistence.html). — shape: {RehydrationType?: "ENTIRE_PAST_SESSION"|"FROM_SEGMENT", SourceContactId?: string}
  --related-contact-id: string # The unique identifier for an Amazon Connect contact. This identifier is related to the chat starting. You cannot provide data for both RelatedContactId and PersistentChat.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contact/chat"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactFlowId, var: contact_flow_id}, {name: Attributes, var: attributes}, {name: ParticipantDetails, var: participant_details}, {name: InitialMessage, var: initial_message}, {name: ClientToken, var: client_token}, {name: ChatDurationInMinutes, var: chat_duration_in_minutes}, {name: SupportedMessagingContentTypes, var: supported_messaging_content_types}, {name: PersistentChat, var: persistent_chat}, {name: RelatedContactId, var: related_contact_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_flow_id: $contact_flow_id, attributes: $attributes, participant_details: $participant_details, initial_message: $initial_message, client_token: $client_token, chat_duration_in_minutes: $chat_duration_in_minutes, supported_messaging_content_types: $supported_messaging_content_types, persistent_chat: $persistent_chat, related_contact_id: $related_contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts recording the contact: If the API is called before the agent joins the call, recording starts when the agent joins the call. If the API is called after the agent joins the call, recording starts at the time of the API call. StartContactRecording is a one-time action. For example, if you use StopContactRecording to stop recording an ongoing call, you can't use StartContactRecording to restart it. For scenarios where the recording has started and you want to suspend and resume it, such as when collecting sensitive information (for example, a credit card number), use SuspendContactRecording and ResumeContactRecording. You can use this API to override the recording behavior configured in the Set recording behavior (https://docs.aws.amazon.com/connect/latest/adminguide/set-recording-behavior.html) block. Only voice recordings are supported at this time.
#
# POST /contact/start-recording
# Returns: record
# operationId: StartContactRecording
export def "start-contact-recording" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
  voice_recording_configuration: record # Contains information about the recording configuration settings. — shape: {VoiceRecordingTrack?: "FROM_AGENT"|"TO_AGENT"|"ALL"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/start-recording"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: InitialContactId, var: initial_contact_id}, {name: VoiceRecordingConfiguration, var: voice_recording_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, initial_contact_id: $initial_contact_id, voice_recording_configuration: $voice_recording_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates real-time message streaming for a new chat contact. For more information about message streaming, see Enable real-time chat message streaming (https://docs.aws.amazon.com/connect/latest/adminguide/chat-message-streaming.html) in the Amazon Connect Administrator Guide.
#
# POST /contact/start-streaming
# Returns: record<StreamingId: string>
# operationId: StartContactStreaming
export def "start-contact-streaming" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
  chat_streaming_configuration: record # The streaming configuration, such as the Amazon SNS streaming endpoint. — shape: {StreamingEndpointArn?: string}
  client_token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/start-streaming"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: ChatStreamingConfiguration, var: chat_streaming_configuration}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, chat_streaming_configuration: $chat_streaming_configuration, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Places an outbound call to a contact, and then initiates the flow. It performs the actions in the flow that's specified (in ContactFlowId). Agents do not initiate the outbound API, which means that they do not dial the contact. If the flow places an outbound call to a contact, and then puts the contact in queue, the call is then routed to the agent, like any other inbound case. There is a 60-second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails. UK numbers with a 447 prefix are not allowed by default. Before you can dial these UK mobile numbers, you must submit a service quota increase request. For more information, see Amazon Connect Service Quotas (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html) in the Amazon Connect Administrator Guide. Campaign calls are not allowed by default. Before you can make a call with TrafficType = CAMPAIGN, you must submit a service quota increase request to the quota Amazon Connect campaigns (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html#outbound-communications-quotas).
#
# PUT /contact/outbound-voice
# Returns: record<ContactId: string>
# operationId: StartOutboundVoiceContact
export def "start-outbound-voice-contact" [
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
  destination_phone_number: string # The phone number of the customer, in E.164 format.
  contact_flow_id: string # The identifier of the flow for the outbound call. To see the ContactFlowId in the Amazon Connect console user interface, on the navigation menu go to Routing, Contact Flows. Choose the flow. On the flow page, under the name of the flow, choose Show additional flow information. The ContactFlowId is the last part of the ARN, shown here in bold: arn:aws:connect:us-west-2:xxxxxxxxxxxx:instance/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/contact-flow/846ec553-a005-41c0-8341-xxxxxxxxxxxx
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). The token is valid for 7 days after creation. If a contact is already started, the contact ID is returned.
  --source-phone-number: string # The phone number associated with the Amazon Connect instance, in E.164 format. If you do not specify a source phone number, you must specify a queue.
  --queue-id: string # The queue for the call. If you specify a queue, the phone displayed for caller ID is the phone number specified in the queue. If you do not specify a queue, the queue defined in the flow is used. If you do not specify a queue, you must specify a source phone number.
  --attributes: record # A custom key-value pair using an attribute map. The attributes are standard Amazon Connect attributes, and can be accessed in flows just like any other contact attributes. There can be up to 32,768 UTF-8 bytes across all key-value pairs per contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
  --answer-machine-detection-config: record # Configuration of the answering machine detection. — shape: {EnableAnswerMachineDetection?: bool, AwaitAnswerMachinePrompt?: bool}
  --campaign-id: string # The campaign identifier of the outbound communication.
  --traffic-type: string@traffic-type-completer # Denotes the class of traffic. Calls with different traffic types are handled differently by Amazon Connect. The default value is GENERAL. Use CAMPAIGN if EnableAnswerMachineDetection is set to true. For all other cases, use GENERAL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contact/outbound-voice"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DestinationPhoneNumber, var: destination_phone_number}, {name: ContactFlowId, var: contact_flow_id}, {name: InstanceId, var: instance_id}, {name: ClientToken, var: client_token}, {name: SourcePhoneNumber, var: source_phone_number}, {name: QueueId, var: queue_id}, {name: Attributes, var: attributes}, {name: AnswerMachineDetectionConfig, var: answer_machine_detection_config}, {name: CampaignId, var: campaign_id}, {name: TrafficType, var: traffic_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, destination_phone_number: $destination_phone_number, contact_flow_id: $contact_flow_id, instance_id: $instance_id, client_token: $client_token, source_phone_number: $source_phone_number, queue_id: $queue_id, attributes: $attributes, answer_machine_detection_config: $answer_machine_detection_config, campaign_id: $campaign_id, traffic_type: $traffic_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a flow to start a new task.
#
# PUT /contact/task
# Returns: record<ContactId: string>
# operationId: StartTaskContact
export def "start-task-contact" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  --previous-contact-id: string # The identifier of the previous chat, voice, or task contact.
  --contact-flow-id: string # The identifier of the flow for initiating the tasks. To see the ContactFlowId in the Amazon Connect console user interface, on the navigation menu go to Routing, Contact Flows. Choose the flow. On the flow page, under the name of the flow, choose Show additional flow information. The ContactFlowId is the last part of the ARN, shown here in bold: arn:aws:connect:us-west-2:xxxxxxxxxxxx:instance/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/contact-flow/846ec553-a005-41c0-8341-xxxxxxxxxxxx
  --attributes: record # A custom key-value pair using an attribute map. The attributes are standard Amazon Connect attributes, and can be accessed in flows just like any other contact attributes. There can be up to 32,768 UTF-8 bytes across all key-value pairs per contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
  name: string # The name of a task that is shown to an agent in the Contact Control Panel (CCP).
  --references: record # A formatted URL that is shown to an agent in the Contact Control Panel (CCP).
  --description: string # A description of the task that is shown to an agent in the Contact Control Panel (CCP).
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
  --scheduled-time: string # The timestamp, in Unix Epoch seconds format, at which to start running the inbound flow. The scheduled time cannot be in the past. It must be within up to 6 days in future. (format: date-time)
  --task-template-id: string # A unique identifier for the task template.
  --quick-connect-id: string # The identifier for the quick connect.
  --related-contact-id: string # The contactId that is related (https://docs.aws.amazon.com/connect/latest/adminguide/tasks.html#linked-tasks) to this contact.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contact/task"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: PreviousContactId, var: previous_contact_id}, {name: ContactFlowId, var: contact_flow_id}, {name: Attributes, var: attributes}, {name: Name, var: name}, {name: References, var: references}, {name: Description, var: description}, {name: ClientToken, var: client_token}, {name: ScheduledTime, var: scheduled_time}, {name: TaskTemplateId, var: task_template_id}, {name: QuickConnectId, var: quick_connect_id}, {name: RelatedContactId, var: related_contact_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, previous_contact_id: $previous_contact_id, contact_flow_id: $contact_flow_id, attributes: $attributes, name: $name, references: $references, description: $description, client_token: $client_token, scheduled_time: $scheduled_time, task_template_id: $task_template_id, quick_connect_id: $quick_connect_id, related_contact_id: $related_contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ends the specified contact. This call does not work for the following initiation methods: DISCONNECT TRANSFER QUEUE_TRANSFER
#
# POST /contact/stop
# Returns: record
# operationId: StopContact
export def "stop-contact" [
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
  contact_id: string # The ID of the contact.
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/stop"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContactId, var: contact_id}, {name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, contact_id: $contact_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops recording a call when a contact is being recorded. StopContactRecording is a one-time action. If you use StopContactRecording to stop recording an ongoing call, you can't use StartContactRecording to restart it. For scenarios where the recording has started and you want to suspend it for sensitive information (for example, to collect a credit card number), and then restart it, use SuspendContactRecording and ResumeContactRecording. Only voice recordings are supported at this time.
#
# POST /contact/stop-recording
# Returns: record
# operationId: StopContactRecording
export def "stop-contact-recording" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/stop-recording"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: InitialContactId, var: initial_contact_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, initial_contact_id: $initial_contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ends message streaming on a specified contact. To restart message streaming on that contact, call the StartContactStreaming (https://docs.aws.amazon.com/connect/latest/APIReference/API_StartContactStreaming.html) API.
#
# POST /contact/stop-streaming
# Returns: record
# operationId: StopContactStreaming
export def "stop-contact-streaming" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact. This is the identifier of the contact that is associated with the first interaction with the contact center.
  streaming_id: string # The identifier of the streaming configuration enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/stop-streaming"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: StreamingId, var: streaming_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, streaming_id: $streaming_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When a contact is being recorded, this API suspends recording the call. For example, you might suspend the call recording while collecting sensitive information, such as a credit card number. Then use ResumeContactRecording to restart recording. The period of time that the recording is suspended is filled with silence in the final recording. Only voice recordings are supported at this time.
#
# POST /contact/suspend-recording
# Returns: record
# operationId: SuspendContactRecording
export def "suspend-contact-recording" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/suspend-recording"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: InitialContactId, var: initial_contact_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, initial_contact_id: $initial_contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers contacts from one agent or queue to another agent or queue at any point after a contact is created. You can transfer a contact to another queue by providing the flow which orchestrates the contact to the destination queue. This gives you more control over contact handling and helps you adhere to the service level agreement (SLA) guaranteed to your customers. Note the following requirements: Transfer is supported for only TASK contacts. Do not use both QueueId and UserId in the same call. The following flow types are supported: Inbound flow, Transfer to agent flow, and Transfer to queue flow. The TransferContact API can be called only on active contacts. A contact cannot be transferred more than 11 times.
#
# POST /contact/transfer
# Returns: record<ContactId: string, ContactArn: string>
# operationId: TransferContact
export def "transfer-contact" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact in this instance of Amazon Connect.
  --queue-id: string # The identifier for the queue.
  --user-id: string # The identifier for the user.
  contact_flow_id: string # The identifier of the flow.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If not provided, the Amazon Web Services SDK populates this field. For more information about idempotency, see Making retries safe with idempotent APIs (https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/transfer"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: QueueId, var: queue_id}, {name: UserId, var: user_id}, {name: ContactFlowId, var: contact_flow_id}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, queue_id: $queue_id, user_id: $user_id, contact_flow_id: $contact_flow_id, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified tags from the specified resource.
#
# DELETE /tags/{resourceArn}
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # The tag keys. (required)
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates user-defined contact attributes associated with the specified contact. You can create or update user-defined attributes for both ongoing and completed contacts. For example, while the call is active, you can update the customer's name or the reason the customer called. You can add notes about steps that the agent took during the call that display to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or to identify abusive callers. Contact attributes are available in Amazon Connect for 24 months, and are then deleted. For information about contact record retention and the maximum size of the contact record attributes section, see Feature specifications (https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html#feature-limits) in the Amazon Connect Administrator Guide.
#
# POST /contact/attributes
# Returns: record
# operationId: UpdateContactAttributes
export def "update-contact-attributes" [
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
  initial_contact_id: string # The identifier of the contact. This is the identifier of the contact associated with the first interaction with the contact center.
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  attributes: record # The Amazon Connect attributes. These attributes can be accessed in flows just like any other contact attributes. You can have up to 32,768 UTF-8 bytes across all attributes for a contact. Attribute keys can include only alphanumeric, dash, and underscore characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/attributes"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InitialContactId, var: initial_contact_id}, {name: InstanceId, var: instance_id}, {name: Attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, initial_contact_id: $initial_contact_id, instance_id: $instance_id, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified flow. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# POST /contact-flows/{InstanceId}/{ContactFlowId}/content
# Returns: record
# operationId: UpdateContactFlowContent
export def "update-contact-flow-content" [
  instance_id: string
  contact_flow_id: string
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
  content: string # The JSON string that represents flow's content. For an example, see Example contact flow in Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language-example.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact-flows/{InstanceId}/{ContactFlowId}/content"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowId, var: contact_flow_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_id: $contact_flow_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates metadata about specified flow.
#
# POST /contact-flows/{InstanceId}/{ContactFlowId}/metadata
# Returns: record
# operationId: UpdateContactFlowMetadata
export def "update-contact-flow-metadata" [
  instance_id: string
  contact_flow_id: string
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
  --name: string # The name of the flow.
  --description: string # The description of the flow.
  --contact-flow-state: string@contact-flow-state-completer # The state of flow.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact-flows/{InstanceId}/{ContactFlowId}/metadata"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowId, var: contact_flow_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: ContactFlowState, var: contact_flow_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_id: $contact_flow_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, contact_flow_state: $contact_flow_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates specified flow module for the specified Amazon Connect instance.
#
# POST /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}/content
# Returns: record
# operationId: UpdateContactFlowModuleContent
export def "update-contact-flow-module-content" [
  instance_id: string
  contact_flow_module_id: string
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
  content: string # The content of the flow module.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact-flow-modules/{InstanceId}/{ContactFlowModuleId}/content"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowModuleId, var: contact_flow_module_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_module_id: $contact_flow_module_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates metadata about specified flow module.
#
# POST /contact-flow-modules/{InstanceId}/{ContactFlowModuleId}/metadata
# Returns: record
# operationId: UpdateContactFlowModuleMetadata
export def "update-contact-flow-module-metadata" [
  instance_id: string
  contact_flow_module_id: string
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
  --name: string # The name of the flow module.
  --description: string # The description of the flow module.
  --state: string@state-completer-1 # The state of flow module.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact-flow-modules/{InstanceId}/{ContactFlowModuleId}/metadata"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowModuleId, var: contact_flow_module_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: State, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_module_id: $contact_flow_module_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The name of the flow. You can also create and update flows using the Amazon Connect Flow language (https://docs.aws.amazon.com/connect/latest/APIReference/flow-language.html).
#
# POST /contact-flows/{InstanceId}/{ContactFlowId}/name
# Returns: record
# operationId: UpdateContactFlowName
export def "update-contact-flow-name" [
  instance_id: string
  contact_flow_id: string
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
  --name: string # The name of the flow.
  --description: string # The description of the flow.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact-flows/{InstanceId}/{ContactFlowId}/name"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactFlowId, var: contact_flow_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_flow_id: $contact_flow_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the scheduled time of a task contact that is already scheduled.
#
# POST /contact/schedule
# Returns: record
# operationId: UpdateContactSchedule
export def "update-contact-schedule" [
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
  instance_id: string # The identifier of the Amazon Connect instance. You can find the instance ID (https://docs.aws.amazon.com/connect/latest/adminguide/find-instance-arn.html) in the Amazon Resource Name (ARN) of the instance.
  contact_id: string # The identifier of the contact.
  scheduled_time: string # The timestamp, in Unix Epoch seconds format, at which to start running the inbound flow. The scheduled time cannot be in the past. It must be within up to 6 days in future. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contact/schedule"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}, {name: ScheduledTime, var: scheduled_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, instance_id: $instance_id, contact_id: $contact_id, scheduled_time: $scheduled_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates timeouts for when human chat participants are to be considered idle, and when agents are automatically disconnected from a chat due to idleness. You can set four timers: Customer idle timeout Customer auto-disconnect timeout Agent idle timeout Agent auto-disconnect timeout For more information about how chat timeouts work, see Set up chat timeouts for human participants (https://docs.aws.amazon.com/connect/latest/adminguide/setup-chat-timeouts.html).
#
# PUT /contact/participant-role-config/{InstanceId}/{ContactId}
# Returns: record
# operationId: UpdateParticipantRoleConfig
export def "update-participant-role-config" [
  instance_id: string
  contact_id: string
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
  channel_configuration: record # Configuration information for the chat participant role. — shape: {Chat?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contact/participant-role-config/{InstanceId}/{ContactId}"
    path_params: [{name: InstanceId, var: instance_id}, {name: ContactId, var: contact_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ChannelConfiguration, var: channel_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, contact_id: $contact_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, channel_configuration: $channel_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the hours of operation for the specified queue.
#
# POST /queues/{InstanceId}/{QueueId}/hours-of-operation
# operationId: UpdateQueueHoursOfOperation
export def "update-queue-hours-of-operation" [
  instance_id: string
  queue_id: string
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
  hours_of_operation_id: string # The identifier for the hours of operation.
]: any -> any {
  $in | http-request {
    method: post
    path: "/queues/{InstanceId}/{QueueId}/hours-of-operation"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: HoursOfOperationId, var: hours_of_operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hours_of_operation_id: $hours_of_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the maximum number of contacts allowed in a queue before it is considered full.
#
# POST /queues/{InstanceId}/{QueueId}/max-contacts
# operationId: UpdateQueueMaxContacts
export def "update-queue-max-contacts" [
  instance_id: string
  queue_id: string
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
  --max-contacts: int # The maximum number of contacts that can be in the queue before it is considered full.
]: any -> any {
  $in | http-request {
    method: post
    path: "/queues/{InstanceId}/{QueueId}/max-contacts"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxContacts, var: max_contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, max_contacts: $max_contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the name and description of a queue. At least Name or Description must be provided.
#
# POST /queues/{InstanceId}/{QueueId}/name
# operationId: UpdateQueueName
export def "update-queue-name" [
  instance_id: string
  queue_id: string
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
  --name: string # The name of the queue.
  --description: string # The description of the queue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/queues/{InstanceId}/{QueueId}/name"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the outbound caller ID name, number, and outbound whisper flow for a specified queue. If the number being used in the input is claimed to a traffic distribution group, and you are calling this API using an instance in the Amazon Web Services Region where the traffic distribution group was created, you can use either a full phone number ARN or UUID value for the OutboundCallerIdNumberId value of the OutboundCallerConfig (https://docs.aws.amazon.com/connect/latest/APIReference/API_OutboundCallerConfig) request body parameter. However, if the number is claimed to a traffic distribution group and you are calling this API using an instance in the alternate Amazon Web Services Region associated with the traffic distribution group, you must provide a full phone number ARN. If a UUID is provided in this scenario, you will receive a ResourceNotFoundException.
#
# POST /queues/{InstanceId}/{QueueId}/outbound-caller-config
# operationId: UpdateQueueOutboundCallerConfig
export def "update-queue-outbound-caller-config" [
  instance_id: string
  queue_id: string
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
  outbound_caller_config: record # The outbound caller ID name, number, and outbound whisper flow. — shape: {OutboundCallerIdName?: string, OutboundCallerIdNumberId?: string, OutboundFlowId?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/queues/{InstanceId}/{QueueId}/outbound-caller-config"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: OutboundCallerConfig, var: outbound_caller_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, outbound_caller_config: $outbound_caller_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API is in preview release for Amazon Connect and is subject to change. Updates the status of the queue.
#
# POST /queues/{InstanceId}/{QueueId}/status
# operationId: UpdateQueueStatus
export def "update-queue-status" [
  instance_id: string
  queue_id: string
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
  status: string@status-completer-1 # The status of the queue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/queues/{InstanceId}/{QueueId}/status"
    path_params: [{name: InstanceId, var: instance_id}, {name: QueueId, var: queue_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, queue_id: $queue_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration settings for the specified quick connect.
#
# POST /quick-connects/{InstanceId}/{QuickConnectId}/config
# operationId: UpdateQuickConnectConfig
export def "update-quick-connect-config" [
  instance_id: string
  quick_connect_id: string
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
  quick_connect_config: record # Contains configuration settings for a quick connect. — shape: {QuickConnectType?: "USER"|"QUEUE"|"PHONE_NUMBER", UserConfig?: record, QueueConfig?: record, PhoneConfig?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/quick-connects/{InstanceId}/{QuickConnectId}/config"
    path_params: [{name: InstanceId, var: instance_id}, {name: QuickConnectId, var: quick_connect_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: QuickConnectConfig, var: quick_connect_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, quick_connect_id: $quick_connect_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, quick_connect_config: $quick_connect_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name and description of a quick connect. The request accepts the following data in JSON format. At least Name or Description must be provided.
#
# POST /quick-connects/{InstanceId}/{QuickConnectId}/name
# operationId: UpdateQuickConnectName
export def "update-quick-connect-name" [
  instance_id: string
  quick_connect_id: string
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
  --name: string # The name of the quick connect.
  --description: string # The description of the quick connect.
]: any -> any {
  $in | http-request {
    method: post
    path: "/quick-connects/{InstanceId}/{QuickConnectId}/name"
    path_params: [{name: InstanceId, var: instance_id}, {name: QuickConnectId, var: quick_connect_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, quick_connect_id: $quick_connect_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the channels that agents can handle in the Contact Control Panel (CCP) for a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/concurrency
# operationId: UpdateRoutingProfileConcurrency
export def "update-routing-profile-concurrency" [
  instance_id: string
  routing_profile_id: string
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
  media_concurrencies: list # The channels that agents can handle in the Contact Control Panel (CCP). — item shape: {Channel: "VOICE"|"CHAT"|"TASK", Concurrency: int, CrossChannelBehavior?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}/concurrency"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MediaConcurrencies, var: media_concurrencies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, media_concurrencies: $media_concurrencies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the default outbound queue of a routing profile.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/default-outbound-queue
# operationId: UpdateRoutingProfileDefaultOutboundQueue
export def "update-routing-profile-default-outbound-queue" [
  instance_id: string
  routing_profile_id: string
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
  default_outbound_queue_id: string # The identifier for the default outbound queue.
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}/default-outbound-queue"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DefaultOutboundQueueId, var: default_outbound_queue_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, default_outbound_queue_id: $default_outbound_queue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name and description of a routing profile. The request accepts the following data in JSON format. At least Name or Description must be provided.
#
# POST /routing-profiles/{InstanceId}/{RoutingProfileId}/name
# operationId: UpdateRoutingProfileName
export def "update-routing-profile-name" [
  instance_id: string
  routing_profile_id: string
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
  --name: string # The name of the routing profile. Must not be more than 127 characters.
  --description: string # The description of the routing profile. Must not be more than 250 characters.
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing-profiles/{InstanceId}/{RoutingProfileId}/name"
    path_params: [{name: InstanceId, var: instance_id}, {name: RoutingProfileId, var: routing_profile_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, routing_profile_id: $routing_profile_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns the specified hierarchy group to the specified user.
#
# POST /users/{InstanceId}/{UserId}/hierarchy
# operationId: UpdateUserHierarchy
export def "update-user-hierarchy" [
  instance_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --hierarchy-group-id: string # The identifier of the hierarchy group.
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{InstanceId}/{UserId}/hierarchy"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: HierarchyGroupId, var: hierarchy_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hierarchy_group_id: $hierarchy_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of the user hierarchy group.
#
# POST /user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}/name
# operationId: UpdateUserHierarchyGroupName
export def "update-user-hierarchy-group-name" [
  instance_id: string
  hierarchy_group_id: string
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
  name: string # The name of the hierarchy group. Must not be more than 100 characters.
]: any -> any {
  $in | http-request {
    method: post
    path: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}/name"
    path_params: [{name: InstanceId, var: instance_id}, {name: HierarchyGroupId, var: hierarchy_group_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, hierarchy_group_id: $hierarchy_group_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the identity information for the specified user. We strongly recommend limiting who has the ability to invoke UpdateUserIdentityInfo. Someone with that ability can change the login credentials of other users by changing their email address. This poses a security risk to your organization. They can change the email address of a user to the attacker's email address, and then reset the password through email. For more information, see Best Practices for Security Profiles (https://docs.aws.amazon.com/connect/latest/adminguide/security-profile-best-practices.html) in the Amazon Connect Administrator Guide.
#
# POST /users/{InstanceId}/{UserId}/identity-info
# operationId: UpdateUserIdentityInfo
export def "update-user-identity-info" [
  instance_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  identity_info: record # Contains information about the identity of a user. — shape: {FirstName?: string, LastName?: string, Email?: string, SecondaryEmail?: string, Mobile?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{InstanceId}/{UserId}/identity-info"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: IdentityInfo, var: identity_info}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, identity_info: $identity_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the phone configuration settings for the specified user.
#
# POST /users/{InstanceId}/{UserId}/phone-config
# operationId: UpdateUserPhoneConfig
export def "update-user-phone-config" [
  instance_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  phone_config: record # Contains information about the phone configuration settings for a user. — shape: {PhoneType?: "SOFT_PHONE"|"DESK_PHONE", AutoAccept?: bool, AfterContactWorkTimeLimit?: int, DeskPhoneNumber?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{InstanceId}/{UserId}/phone-config"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PhoneConfig, var: phone_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, phone_config: $phone_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns the specified routing profile to the specified user.
#
# POST /users/{InstanceId}/{UserId}/routing-profile
# operationId: UpdateUserRoutingProfile
export def "update-user-routing-profile" [
  instance_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  routing_profile_id: string # The identifier of the routing profile for the user.
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{InstanceId}/{UserId}/routing-profile"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: RoutingProfileId, var: routing_profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, routing_profile_id: $routing_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns the specified security profiles to the specified user.
#
# POST /users/{InstanceId}/{UserId}/security-profiles
# operationId: UpdateUserSecurityProfiles
export def "update-user-security-profiles" [
  instance_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  security_profile_ids: list<string> # The identifiers of the security profiles for the user.
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{InstanceId}/{UserId}/security-profiles"
    path_params: [{name: InstanceId, var: instance_id}, {name: UserId, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SecurityProfileIds, var: security_profile_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, security_profile_ids: $security_profile_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
