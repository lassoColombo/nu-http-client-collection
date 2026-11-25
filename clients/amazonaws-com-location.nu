# Auto-generated client for Amazon Location Service v2020-11-19
# Source: https://api.apis.guru/v2/specs/amazonaws.com/location/2020-11-19/openapi.json
# Auth: --token flag or $env.AMAZON_LOCATION_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://geo.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_LOCATION_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://geo.us-east-1.amazonaws.com" "http://geo.us-east-2.amazonaws.com" "http://geo.us-west-1.amazonaws.com" "http://geo.us-west-2.amazonaws.com" "http://geo.us-gov-west-1.amazonaws.com" "http://geo.us-gov-east-1.amazonaws.com" "http://geo.ca-central-1.amazonaws.com" "http://geo.eu-north-1.amazonaws.com" "http://geo.eu-west-1.amazonaws.com" "http://geo.eu-west-2.amazonaws.com" "http://geo.eu-west-3.amazonaws.com" "http://geo.eu-central-1.amazonaws.com" "http://geo.eu-south-1.amazonaws.com" "http://geo.af-south-1.amazonaws.com" "http://geo.ap-northeast-1.amazonaws.com" "http://geo.ap-northeast-2.amazonaws.com" "http://geo.ap-northeast-3.amazonaws.com" "http://geo.ap-southeast-1.amazonaws.com" "http://geo.ap-southeast-2.amazonaws.com" "http://geo.ap-east-1.amazonaws.com" "http://geo.ap-south-1.amazonaws.com" "http://geo.sa-east-1.amazonaws.com" "http://geo.me-south-1.amazonaws.com" "https://geo.us-east-1.amazonaws.com" "https://geo.us-east-2.amazonaws.com" "https://geo.us-west-1.amazonaws.com" "https://geo.us-west-2.amazonaws.com" "https://geo.us-gov-west-1.amazonaws.com" "https://geo.us-gov-east-1.amazonaws.com" "https://geo.ca-central-1.amazonaws.com" "https://geo.eu-north-1.amazonaws.com" "https://geo.eu-west-1.amazonaws.com" "https://geo.eu-west-2.amazonaws.com" "https://geo.eu-west-3.amazonaws.com" "https://geo.eu-central-1.amazonaws.com" "https://geo.eu-south-1.amazonaws.com" "https://geo.af-south-1.amazonaws.com" "https://geo.ap-northeast-1.amazonaws.com" "https://geo.ap-northeast-2.amazonaws.com" "https://geo.ap-northeast-3.amazonaws.com" "https://geo.ap-southeast-1.amazonaws.com" "https://geo.ap-southeast-2.amazonaws.com" "https://geo.ap-east-1.amazonaws.com" "https://geo.ap-south-1.amazonaws.com" "https://geo.sa-east-1.amazonaws.com" "https://geo.me-south-1.amazonaws.com" "http://geo.cn-north-1.amazonaws.com.cn" "http://geo.cn-northwest-1.amazonaws.com.cn" "https://geo.cn-north-1.amazonaws.com.cn" "https://geo.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def distance-unit-completer [] { ["Kilometers" "Miles"] }
def travel-mode-completer [] { ["Bicycle" "Car" "Motorcycle" "Truck" "Walking"] }
def pricing-plan-completer [] { ["MobileAssetManagement" "MobileAssetTracking" "RequestBasedUsage"] }
def position-filtering-completer [] { ["AccuracyBased" "DistanceBased" "TimeBased"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-tracker-consumer: "record"
    batch-delete-device-position-history: "record<Errors: table<DeviceId: string, Error: record>>"
    batch-delete-geofence: "record<Errors: table<Error: record, GeofenceId: string>>"
    batch-evaluate-geofences: "record<Errors: table<DeviceId: string, Error: record, SampleTime: string>>"
    batch-get-device-position: "record<DevicePositions: table<Accuracy: record, DeviceId: string, Position: list, PositionProperties: record, ReceivedTime: string, SampleTime: string>, Errors: table<DeviceId: string, Error: record>>"
    batch-put-geofence: "record<Errors: table<Error: record, GeofenceId: string>, Successes: table<CreateTime: string, GeofenceId: string, UpdateTime: string>>"
    batch-update-device-position: "record<Errors: table<DeviceId: string, Error: record, SampleTime: string>>"
    calculate-route: "record<Legs: table<Distance: float, DurationSeconds: float, EndPosition: list, Geometry: record, StartPosition: list, Steps: list>, Summary: record<DataSource: string, Distance: float, DistanceUnit: string, DurationSeconds: float, RouteBBox: list<float>>>"
    calculate-route-matrix: "record<RouteMatrix: list<list<record>>, SnappedDeparturePositions: list<list<float>>, SnappedDestinationPositions: list<list<float>>, Summary: record<DataSource: string, DistanceUnit: string, ErrorCount: int, RouteCount: int>>"
    create-geofence-collection: "record<CollectionArn: string, CollectionName: string, CreateTime: string>"
    create-key: "record<CreateTime: string, Key: string, KeyArn: string, KeyName: string>"
    create-map: "record<CreateTime: string, MapArn: string, MapName: string>"
    create-place-index: "record<CreateTime: string, IndexArn: string, IndexName: string>"
    create-route-calculator: "record<CalculatorArn: string, CalculatorName: string, CreateTime: string>"
    create-tracker: "record<CreateTime: string, TrackerArn: string, TrackerName: string>"
    delete-geofence-collection: "record"
    describe-geofence-collection: "record<CollectionArn: string, CollectionName: string, CreateTime: string, Description: string, KmsKeyId: string, PricingPlan: string, PricingPlanDataSource: string, Tags: record, UpdateTime: string>"
    update-geofence-collection: "record<CollectionArn: string, CollectionName: string, UpdateTime: string>"
    delete-key: "record"
    describe-key: "record<CreateTime: string, Description: string, ExpireTime: string, Key: string, KeyArn: string, KeyName: string, Restrictions: record<AllowActions: list<string>, AllowReferers: list<string>, AllowResources: list<string>>, Tags: record, UpdateTime: string>"
    update-key: "record<KeyArn: string, KeyName: string, UpdateTime: string>"
    delete-map: "record"
    describe-map: "record<Configuration: record<Style: string>, CreateTime: string, DataSource: string, Description: string, MapArn: string, MapName: string, PricingPlan: string, Tags: record, UpdateTime: string>"
    update-map: "record<MapArn: string, MapName: string, UpdateTime: string>"
    delete-place-index: "record"
    describe-place-index: "record<CreateTime: string, DataSource: string, DataSourceConfiguration: record<IntendedUse: string>, Description: string, IndexArn: string, IndexName: string, PricingPlan: string, Tags: record, UpdateTime: string>"
    update-place-index: "record<IndexArn: string, IndexName: string, UpdateTime: string>"
    delete-route-calculator: "record"
    describe-route-calculator: "record<CalculatorArn: string, CalculatorName: string, CreateTime: string, DataSource: string, Description: string, PricingPlan: string, Tags: record, UpdateTime: string>"
    update-route-calculator: "record<CalculatorArn: string, CalculatorName: string, UpdateTime: string>"
    delete-tracker: "record"
    describe-tracker: "record<CreateTime: string, Description: string, KmsKeyId: string, PositionFiltering: string, PricingPlan: string, PricingPlanDataSource: string, Tags: record, TrackerArn: string, TrackerName: string, UpdateTime: string>"
    update-tracker: "record<TrackerArn: string, TrackerName: string, UpdateTime: string>"
    disassociate-tracker-consumer: "record"
    get-device-position: "record<Accuracy: record<Horizontal: float>, DeviceId: string, Position: list<float>, PositionProperties: record, ReceivedTime: string, SampleTime: string>"
    get-device-position-history: "record<DevicePositions: table<Accuracy: record, DeviceId: string, Position: list, PositionProperties: record, ReceivedTime: string, SampleTime: string>, NextToken: string>"
    get-geofence: "record<CreateTime: string, GeofenceId: string, Geometry: record<Circle: record<Center: list, Radius: float>, Polygon: list<list>>, Status: string, UpdateTime: string>"
    put-geofence: "record<CreateTime: string, GeofenceId: string, UpdateTime: string>"
    get-map-glyphs: "record<Blob: string>"
    get-map-sprites: "record<Blob: string>"
    get-map-style-descriptor: "record<Blob: string>"
    get-map-tile: "record<Blob: string>"
    get-place: "record<Place: record<AddressNumber: string, Country: string, Geometry: record<Point: list>, Interpolated: bool, Label: string, Municipality: string, Neighborhood: string, PostalCode: string, Region: string, Street: string, SubRegion: string, TimeZone: record<Name: string, Offset: int>, UnitNumber: string, UnitType: string>>"
    list-device-positions: "record<Entries: table<Accuracy: record, DeviceId: string, Position: list, PositionProperties: record, SampleTime: string>, NextToken: string>"
    list-geofence-collections: "record<Entries: table<CollectionName: string, CreateTime: string, Description: string, PricingPlan: string, PricingPlanDataSource: string, UpdateTime: string>, NextToken: string>"
    list-geofences: "record<Entries: table<CreateTime: string, GeofenceId: string, Geometry: record, Status: string, UpdateTime: string>, NextToken: string>"
    list-keys: "record<Entries: table<CreateTime: string, Description: string, ExpireTime: string, KeyName: string, Restrictions: record, UpdateTime: string>, NextToken: string>"
    list-maps: "record<Entries: table<CreateTime: string, DataSource: string, Description: string, MapName: string, PricingPlan: string, UpdateTime: string>, NextToken: string>"
    list-place-indexes: "record<Entries: table<CreateTime: string, DataSource: string, Description: string, IndexName: string, PricingPlan: string, UpdateTime: string>, NextToken: string>"
    list-route-calculators: "record<Entries: table<CalculatorName: string, CreateTime: string, DataSource: string, Description: string, PricingPlan: string, UpdateTime: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: record>"
    tag-resource: "record"
    list-tracker-consumers: "record<ConsumerArns: list<string>, NextToken: string>"
    list-trackers: "record<Entries: table<CreateTime: string, Description: string, PricingPlan: string, PricingPlanDataSource: string, TrackerName: string, UpdateTime: string>, NextToken: string>"
    search-place-index-for-position: "record<Results: table<Distance: float, Place: record, PlaceId: string>, Summary: record<DataSource: string, Language: string, MaxResults: int, Position: list<float>>>"
    search-place-index-for-suggestions: "record<Results: table<PlaceId: string, Text: string>, Summary: record<BiasPosition: list<float>, DataSource: string, FilterBBox: list<float>, FilterCountries: list<string>, Language: string, MaxResults: int, Text: string>>"
    search-place-index-for-text: "record<Results: table<Distance: float, Place: record, PlaceId: string, Relevance: float>, Summary: record<BiasPosition: list<float>, DataSource: string, FilterBBox: list<float>, FilterCountries: list<string>, Language: string, MaxResults: int, ResultBBox: list<float>, Text: string>>"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-tracker-consumer" "batch-delete-device-position-history" "batch-delete-geofence" "batch-evaluate-geofences" "batch-get-device-position" "batch-put-geofence" "batch-update-device-position" "calculate-route" "calculate-route-matrix" "create-geofence-collection" "create-key" "create-map" "create-place-index" "create-route-calculator" "create-tracker" "delete-geofence-collection" "describe-geofence-collection" "update-geofence-collection" "delete-key" "describe-key" "update-key" "delete-map" "describe-map" "update-map" "delete-place-index" "describe-place-index" "update-place-index" "delete-route-calculator" "describe-route-calculator" "update-route-calculator" "delete-tracker" "describe-tracker" "update-tracker" "disassociate-tracker-consumer" "get-device-position" "get-device-position-history" "get-geofence" "put-geofence" "get-map-glyphs" "get-map-sprites" "get-map-style-descriptor" "get-map-tile" "get-place" "list-device-positions" "list-geofence-collections" "list-geofences" "list-keys" "list-maps" "list-place-indexes" "list-route-calculators" "list-tags-for-resource" "tag-resource" "list-tracker-consumers" "list-trackers" "search-place-index-for-position" "search-place-index-for-suggestions" "search-place-index-for-text" "untag-resource" "commands"] | sort) } | get name | first)
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

# Creates an association between a geofence collection and a tracker resource. This allows the tracker resource to communicate location data to the linked geofence collection. You can associate up to five geofence collections to each tracker resource. Currently not supported — Cross-account configurations, such as creating associations between a tracker resource in one account and a geofence collection in another account.
#
# POST /tracking/v0/trackers/{TrackerName}/consumers
# Returns: record
# operationId: AssociateTrackerConsumer
export def "associate-tracker-consumer" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  consumer_arn: string # The Amazon Resource Name (ARN) for the geofence collection to be associated to tracker resource. Used when you need to specify a resource across all Amazon Web Services. Format example: arn:aws:geo:region:account-id:geofence-collection/ExampleGeofenceCollectionConsumer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers/{TrackerName}/consumers"
    path_params: [{name: TrackerName, var: tracker_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConsumerArn, var: consumer_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, consumer_arn: $consumer_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the position history of one or more devices from a tracker resource.
#
# POST /tracking/v0/trackers/{TrackerName}/delete-positions
# Returns: record<Errors: table<DeviceId: string, Error: record>>
# operationId: BatchDeleteDevicePositionHistory
export def "batch-delete-device-position-history" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  device_ids: list<string> # Devices whose position history you want to delete. For example, for two devices: “DeviceIds” : [DeviceId1,DeviceId2]
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers/{TrackerName}/delete-positions"
    path_params: [{name: TrackerName, var: tracker_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeviceIds, var: device_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, device_ids: $device_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a batch of geofences from a geofence collection. This operation deletes the resource permanently.
#
# POST /geofencing/v0/collections/{CollectionName}/delete-geofences
# Returns: record<Errors: table<Error: record, GeofenceId: string>>
# operationId: BatchDeleteGeofence
export def "batch-delete-geofence" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  geofence_ids: list<string> # The batch of geofences to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofencing/v0/collections/{CollectionName}/delete-geofences"
    path_params: [{name: CollectionName, var: collection_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GeofenceIds, var: geofence_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, geofence_ids: $geofence_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluates device positions against the geofence geometries from a given geofence collection. This operation always returns an empty response because geofences are asynchronously evaluated. The evaluation determines if the device has entered or exited a geofenced area, and then publishes one of the following events to Amazon EventBridge: ENTER if Amazon Location determines that the tracked device has entered a geofenced area. EXIT if Amazon Location determines that the tracked device has exited a geofenced area. The last geofence that a device was observed within is tracked for 30 days after the most recent device position update. Geofence evaluation uses the given device position. It does not account for the optional Accuracy of a DevicePositionUpdate. The DeviceID is used as a string to represent the device. You do not need to have a Tracker associated with the DeviceID.
#
# POST /geofencing/v0/collections/{CollectionName}/positions
# Returns: record<Errors: table<DeviceId: string, Error: record, SampleTime: string>>
# operationId: BatchEvaluateGeofences
export def "batch-evaluate-geofences" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  device_position_updates: list # Contains device details for each device to be evaluated against the given geofence collection. — item shape: {Accuracy?: record, DeviceId: string, Position: list<float>, PositionProperties?: record, SampleTime: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofencing/v0/collections/{CollectionName}/positions"
    path_params: [{name: CollectionName, var: collection_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DevicePositionUpdates, var: device_position_updates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, device_position_updates: $device_position_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the latest device positions for requested devices.
#
# POST /tracking/v0/trackers/{TrackerName}/get-positions
# Returns: record<DevicePositions: table<Accuracy: record, DeviceId: string, Position: list, PositionProperties: record, ReceivedTime: string, SampleTime: string>, Errors: table<DeviceId: string, Error: record>>
# operationId: BatchGetDevicePosition
export def "batch-get-device-position" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  device_ids: list<string> # Devices whose position you want to retrieve. For example, for two devices: device-ids=DeviceId1&device-ids=DeviceId2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers/{TrackerName}/get-positions"
    path_params: [{name: TrackerName, var: tracker_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeviceIds, var: device_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, device_ids: $device_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A batch request for storing geofence geometries into a given geofence collection, or updates the geometry of an existing geofence if a geofence ID is included in the request.
#
# POST /geofencing/v0/collections/{CollectionName}/put-geofences
# Returns: record<Errors: table<Error: record, GeofenceId: string>, Successes: table<CreateTime: string, GeofenceId: string, UpdateTime: string>>
# operationId: BatchPutGeofence
export def "batch-put-geofence" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entries: list # The batch of geofences to be stored in a geofence collection. — item shape: {GeofenceId: string, Geometry: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofencing/v0/collections/{CollectionName}/put-geofences"
    path_params: [{name: CollectionName, var: collection_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads position update data for one or more devices to a tracker resource. Amazon Location uses the data when it reports the last known device position and position history. Amazon Location retains location data for 30 days. Position updates are handled based on the PositionFiltering property of the tracker. When PositionFiltering is set to TimeBased, updates are evaluated against linked geofence collections, and location data is stored at a maximum of one position per 30 second interval. If your update frequency is more often than every 30 seconds, only one update per 30 seconds is stored for each unique device ID. When PositionFiltering is set to DistanceBased filtering, location data is stored and evaluated against linked geofence collections only if the device has moved more than 30 m (98.4 ft). When PositionFiltering is set to AccuracyBased filtering, location data is stored and evaluated against linked geofence collections only if the device has moved more than the measured accuracy. For example, if two consecutive updates from a device have a horizontal accuracy of 5 m and 10 m, the second update is neither stored or evaluated if the device has moved less than 15 m. If PositionFiltering is set to AccuracyBased filtering, Amazon Location uses the default value { "Horizontal": 0} when accuracy is not provided on a DevicePositionUpdate.
#
# POST /tracking/v0/trackers/{TrackerName}/positions
# Returns: record<Errors: table<DeviceId: string, Error: record, SampleTime: string>>
# operationId: BatchUpdateDevicePosition
export def "batch-update-device-position" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  updates: list # Contains the position update details for each device. — item shape: {Accuracy?: record, DeviceId: string, Position: list<float>, PositionProperties?: record, SampleTime: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers/{TrackerName}/positions"
    path_params: [{name: TrackerName, var: tracker_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Updates, var: updates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, updates: $updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculates a route (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route.html) given the following required parameters: DeparturePosition and DestinationPosition. Requires that you first create a route calculator resource (https://docs.aws.amazon.com/location-routes/latest/APIReference/API_CreateRouteCalculator.html). By default, a request that doesn't specify a departure time uses the best time of day to travel with the best traffic conditions when calculating the route. Additional options include: Specifying a departure time (https://docs.aws.amazon.com/location/latest/developerguide/departure-time.html) using either DepartureTime or DepartNow. This calculates a route based on predictive traffic data at the given time. You can't specify both DepartureTime and DepartNow in a single request. Specifying both parameters returns a validation error. Specifying a travel mode (https://docs.aws.amazon.com/location/latest/developerguide/travel-mode.html) using TravelMode sets the transportation mode used to calculate the routes. This also lets you specify additional route preferences in CarModeOptions if traveling by Car, or TruckModeOptions if traveling by Truck. If you specify walking for the travel mode and your data provider is Esri, the start and destination must be within 40km.
#
# POST /routes/v0/calculators/{CalculatorName}/calculate/route
# Returns: record<Legs: table<Distance: float, DurationSeconds: float, EndPosition: list, Geometry: record, StartPosition: list, Steps: list>, Summary: record<DataSource: string, Distance: float, DistanceUnit: string, DurationSeconds: float, RouteBBox: list<float>>>
# operationId: CalculateRoute
export def "calculate-route" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --car-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Car. — shape: {AvoidFerries?: bool, AvoidTolls?: bool}
  --depart-now: oneof<nothing, bool> # Sets the time of departure as the current time. Uses the current time to calculate a route. Otherwise, the best time of day to travel with the best traffic conditions is used to calculate the route. Default Value: false Valid Values: false | true
  departure_position: list<float> # The start position for the route. Defined in World Geodetic System (WGS 84) (https://earth-info.nga.mil/index.php?dir=wgs84&action=wgs84) format: [longitude, latitude]. For example, [-123.115, 49.285] If you specify a departure that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). If Esri is the provider for your route calculator, specifying a route that is longer than 400 km returns a 400 RoutesValidationException error. Valid Values: [-180 to 180,-90 to 90]
  --departure-time: string # Specifies the desired time of departure. Uses the given time to calculate the route. Otherwise, the best time of day to travel with the best traffic conditions is used to calculate the route. Setting a departure time in the past returns a 400 ValidationException error. In ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. For example, 2020–07-2T12:15:20.000Z+01:00 (format: date-time)
  destination_position: list<float> # The finish position for the route. Defined in World Geodetic System (WGS 84) (https://earth-info.nga.mil/index.php?dir=wgs84&action=wgs84) format: [longitude, latitude]. For example, [-122.339, 47.615] If you specify a destination that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). Valid Values: [-180 to 180,-90 to 90]
  --distance-unit: string@distance-unit-completer # Set the unit system to specify the distance. Default Value: Kilometers
  --include-leg-geometry: oneof<nothing, bool> # Set to include the geometry details in the result for each path between a pair of positions. Default Value: false Valid Values: false | true
  --travel-mode: string@travel-mode-completer # Specifies the mode of transport when calculating a route. Used in estimating the speed of travel and road compatibility. You can choose Car, Truck, Walking, Bicycle or Motorcycle as options for the TravelMode. Bicycle and Motorcycle are only valid when using Grab as a data provider, and only within Southeast Asia. Truck is not available for Grab. For more details on the using Grab for routing, including areas of coverage, see GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html) in the Amazon Location Service Developer Guide. The TravelMode you specify also determines how you specify route preferences: If traveling by Car use the CarModeOptions parameter. If traveling by Truck use the TruckModeOptions parameter. Default Value: Car
  --truck-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Truck. — shape: {AvoidFerries?: bool, AvoidTolls?: bool, Dimensions?: record, Weight?: record}
  --waypoint-positions: list # Specifies an ordered list of up to 23 intermediate positions to include along a route between the departure position and destination position. For example, from the DeparturePosition [-123.115, 49.285], the route follows the order that the waypoint positions are given [[-122.757, 49.0021],[-122.349, 47.620]] If you specify a waypoint position that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). Specifying more than 23 waypoints returns a 400 ValidationException error. If Esri is the provider for your route calculator, specifying a route that is longer than 400 km returns a 400 RoutesValidationException error. Valid Values: [-180 to 180,-90 to 90]
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/routes/v0/calculators/{CalculatorName}/calculate/route"
    path_params: [{name: CalculatorName, var: calculator_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CarModeOptions, var: car_mode_options}, {name: DepartNow, var: depart_now}, {name: DeparturePosition, var: departure_position}, {name: DepartureTime, var: departure_time}, {name: DestinationPosition, var: destination_position}, {name: DistanceUnit, var: distance_unit}, {name: IncludeLegGeometry, var: include_leg_geometry}, {name: TravelMode, var: travel_mode}, {name: TruckModeOptions, var: truck_mode_options}, {name: WaypointPositions, var: waypoint_positions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calculator_name: $calculator_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, car_mode_options: $car_mode_options, depart_now: $depart_now, departure_position: $departure_position, departure_time: $departure_time, destination_position: $destination_position, distance_unit: $distance_unit, include_leg_geometry: $include_leg_geometry, travel_mode: $travel_mode, truck_mode_options: $truck_mode_options, waypoint_positions: $waypoint_positions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculates a route matrix (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route-matrix.html) given the following required parameters: DeparturePositions and DestinationPositions. CalculateRouteMatrix calculates routes and returns the travel time and travel distance from each departure position to each destination position in the request. For example, given departure positions A and B, and destination positions X and Y, CalculateRouteMatrix will return time and distance for routes from A to X, A to Y, B to X, and B to Y (in that order). The number of results returned (and routes calculated) will be the number of DeparturePositions times the number of DestinationPositions. Your account is charged for each route calculated, not the number of requests. Requires that you first create a route calculator resource (https://docs.aws.amazon.com/location-routes/latest/APIReference/API_CreateRouteCalculator.html). By default, a request that doesn't specify a departure time uses the best time of day to travel with the best traffic conditions when calculating routes. Additional options include: Specifying a departure time (https://docs.aws.amazon.com/location/latest/developerguide/departure-time.html) using either DepartureTime or DepartNow. This calculates routes based on predictive traffic data at the given time. You can't specify both DepartureTime and DepartNow in a single request. Specifying both parameters returns a validation error. Specifying a travel mode (https://docs.aws.amazon.com/location/latest/developerguide/travel-mode.html) using TravelMode sets the transportation mode used to calculate the routes. This also lets you specify additional route preferences in CarModeOptions if traveling by Car, or TruckModeOptions if traveling by Truck.
#
# POST /routes/v0/calculators/{CalculatorName}/calculate/route-matrix
# Returns: record<RouteMatrix: list<list<record>>, SnappedDeparturePositions: list<list<float>>, SnappedDestinationPositions: list<list<float>>, Summary: record<DataSource: string, DistanceUnit: string, ErrorCount: int, RouteCount: int>>
# operationId: CalculateRouteMatrix
export def "calculate-route-matrix" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --car-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Car. — shape: {AvoidFerries?: bool, AvoidTolls?: bool}
  --depart-now: oneof<nothing, bool> # Sets the time of departure as the current time. Uses the current time to calculate the route matrix. You can't set both DepartureTime and DepartNow. If neither is set, the best time of day to travel with the best traffic conditions is used to calculate the route matrix. Default Value: false Valid Values: false | true
  departure_positions: list # The list of departure (origin) positions for the route matrix. An array of points, each of which is itself a 2-value array defined in WGS 84 (https://earth-info.nga.mil/GandG/wgs84/index.html) format: [longitude, latitude]. For example, [-123.115, 49.285]. Depending on the data provider selected in the route calculator resource there may be additional restrictions on the inputs you can choose. See Position restrictions (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route-matrix.html#matrix-routing-position-limits) in the Amazon Location Service Developer Guide. For route calculators that use Esri as the data provider, if you specify a departure that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). The snapped value is available in the result in SnappedDeparturePositions. Valid Values: [-180 to 180,-90 to 90]
  --departure-time: string # Specifies the desired time of departure. Uses the given time to calculate the route matrix. You can't set both DepartureTime and DepartNow. If neither is set, the best time of day to travel with the best traffic conditions is used to calculate the route matrix. Setting a departure time in the past returns a 400 ValidationException error. In ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. For example, 2020–07-2T12:15:20.000Z+01:00 (format: date-time)
  destination_positions: list # The list of destination positions for the route matrix. An array of points, each of which is itself a 2-value array defined in WGS 84 (https://earth-info.nga.mil/GandG/wgs84/index.html) format: [longitude, latitude]. For example, [-122.339, 47.615] Depending on the data provider selected in the route calculator resource there may be additional restrictions on the inputs you can choose. See Position restrictions (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route-matrix.html#matrix-routing-position-limits) in the Amazon Location Service Developer Guide. For route calculators that use Esri as the data provider, if you specify a destination that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). The snapped value is available in the result in SnappedDestinationPositions. Valid Values: [-180 to 180,-90 to 90]
  --distance-unit: string@distance-unit-completer # Set the unit system to specify the distance. Default Value: Kilometers
  --travel-mode: string@travel-mode-completer # Specifies the mode of transport when calculating a route. Used in estimating the speed of travel and road compatibility. The TravelMode you specify also determines how you specify route preferences: If traveling by Car use the CarModeOptions parameter. If traveling by Truck use the TruckModeOptions parameter. Bicycle or Motorcycle are only valid when using Grab as a data provider, and only within Southeast Asia. Truck is not available for Grab. For more information about using Grab as a data provider, see GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html) in the Amazon Location Service Developer Guide. Default Value: Car
  --truck-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Truck. — shape: {AvoidFerries?: bool, AvoidTolls?: bool, Dimensions?: record, Weight?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/routes/v0/calculators/{CalculatorName}/calculate/route-matrix"
    path_params: [{name: CalculatorName, var: calculator_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CarModeOptions, var: car_mode_options}, {name: DepartNow, var: depart_now}, {name: DeparturePositions, var: departure_positions}, {name: DepartureTime, var: departure_time}, {name: DestinationPositions, var: destination_positions}, {name: DistanceUnit, var: distance_unit}, {name: TravelMode, var: travel_mode}, {name: TruckModeOptions, var: truck_mode_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calculator_name: $calculator_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, car_mode_options: $car_mode_options, depart_now: $depart_now, departure_positions: $departure_positions, departure_time: $departure_time, destination_positions: $destination_positions, distance_unit: $distance_unit, travel_mode: $travel_mode, truck_mode_options: $truck_mode_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a geofence collection, which manages and stores geofences.
#
# POST /geofencing/v0/collections
# Returns: record<CollectionArn: string, CollectionName: string, CreateTime: string>
# operationId: CreateGeofenceCollection
export def "create-geofence-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  collection_name: string # A custom name for the geofence collection. Requirements: Contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique geofence collection name. No spaces allowed. For example, ExampleGeofenceCollection.
  --description: string # An optional description for the geofence collection.
  --kms-key-id: string # A key identifier for an Amazon Web Services KMS customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html). Enter a key ID, key ARN, alias name, or alias ARN.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
  --tags: record # Applies one or more tags to the geofence collection. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofencing/v0/collections"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CollectionName, var: collection_name}, {name: Description, var: description}, {name: KmsKeyId, var: kms_key_id}, {name: PricingPlan, var: pricing_plan}, {name: PricingPlanDataSource, var: pricing_plan_data_source}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, collection_name: $collection_name, description: $description, kms_key_id: $kms_key_id, pricing_plan: $pricing_plan, pricing_plan_data_source: $pricing_plan_data_source, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an API key resource in your Amazon Web Services account, which lets you grant geo:GetMap* actions for Amazon Location Map resources to the API key bearer. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# POST /metadata/v0/keys
# Returns: record<CreateTime: string, Key: string, KeyArn: string, KeyName: string>
# operationId: CreateKey
export def "create-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # An optional description for the API key resource.
  --expire-time: string # The optional timestamp for when the API key resource will expire in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. One of NoExpiry or ExpireTime must be set. (format: date-time)
  key_name: string # A custom name for the API key resource. Requirements: Contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique API key name. No spaces allowed. For example, ExampleAPIKey.
  --no-expiry: oneof<nothing, bool> # Optionally set to true to set no expiration time for the API key. One of NoExpiry or ExpireTime must be set.
  restrictions: record # API Restrictions on the allowed actions, resources, and referers for an API key resource. — shape: {AllowActions?: list<string>, AllowReferers?: list<string>, AllowResources?: list<string>}
  --tags: record # Applies one or more tags to the map resource. A tag is a key-value pair that helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/v0/keys"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: ExpireTime, var: expire_time}, {name: KeyName, var: key_name}, {name: NoExpiry, var: no_expiry}, {name: Restrictions, var: restrictions}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, expire_time: $expire_time, key_name: $key_name, no_expiry: $no_expiry, restrictions: $restrictions, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a map resource in your Amazon Web Services account, which provides map tiles of different styles sourced from global location data providers. If your application is tracking or routing assets you use in your business, such as delivery vehicles or employees, you must not use Esri as your geolocation provider. See section 82 of the Amazon Web Services service terms (http://aws.amazon.com/service-terms) for more details.
#
# POST /maps/v0/maps
# Returns: record<CreateTime: string, MapArn: string, MapName: string>
# operationId: CreateMap
export def "create-map" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  configuration: record # Specifies the map tile style selected from an available provider. — shape: {Style?: string}
  --description: string # An optional description for the map resource.
  map_name: string # The name for the map resource. Requirements: Must contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique map resource name. No spaces allowed. For example, ExampleMap.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --tags: record # Applies one or more tags to the map resource. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/maps/v0/maps"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Configuration, var: configuration}, {name: Description, var: description}, {name: MapName, var: map_name}, {name: PricingPlan, var: pricing_plan}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, configuration: $configuration, description: $description, map_name: $map_name, pricing_plan: $pricing_plan, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a place index resource in your Amazon Web Services account. Use a place index resource to geocode addresses and other text queries by using the SearchPlaceIndexForText operation, and reverse geocode coordinates by using the SearchPlaceIndexForPosition operation, and enable autosuggestions by using the SearchPlaceIndexForSuggestions operation. If your application is tracking or routing assets you use in your business, such as delivery vehicles or employees, you must not use Esri as your geolocation provider. See section 82 of the Amazon Web Services service terms (http://aws.amazon.com/service-terms) for more details.
#
# POST /places/v0/indexes
# Returns: record<CreateTime: string, IndexArn: string, IndexName: string>
# operationId: CreatePlaceIndex
export def "create-place-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  data_source: string # Specifies the geospatial data provider for the new place index. This field is case-sensitive. Enter the valid values as shown. For example, entering HERE returns an error. Valid values include: Esri – For additional information about Esri (https://docs.aws.amazon.com/location/latest/developerguide/esri.html)'s coverage in your region of interest, see Esri details on geocoding coverage (https://developers.arcgis.com/rest/geocode/api-reference/geocode-coverage.htm). Grab – Grab provides place index functionality for Southeast Asia. For additional information about GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html)' coverage, see GrabMaps countries and areas covered (https://docs.aws.amazon.com/location/latest/developerguide/grab.html#grab-coverage-area). Here – For additional information about HERE Technologies (https://docs.aws.amazon.com/location/latest/developerguide/HERE.html)' coverage in your region of interest, see HERE details on goecoding coverage (https://developer.here.com/documentation/geocoder/dev_guide/topics/coverage-geocoder.html). If you specify HERE Technologies (Here) as the data provider, you may not store results (https://docs.aws.amazon.com/location-places/latest/APIReference/API_DataSourceConfiguration.html) for locations in Japan. For more information, see the Amazon Web Services Service Terms (http://aws.amazon.com/service-terms/) for Amazon Location Service. For additional information , see Data providers (https://docs.aws.amazon.com/location/latest/developerguide/what-is-data-provider.html) on the Amazon Location Service Developer Guide.
  --data-source-configuration: record # Specifies the data storage option chosen for requesting Places. When using Amazon Location Places: If using HERE Technologies as a data provider, you can't store results for locations in Japan by setting IntendedUse to Storage. parameter. Under the MobileAssetTracking or MobilAssetManagement pricing plan, you can't store results from your place index resources by setting IntendedUse to Storage. This returns a validation exception error. For more information, see the AWS Service Terms (https://aws.amazon.com/service-terms/) for Amazon Location Service. — shape: {IntendedUse?: "SingleUse"|"Storage"}
  --description: string # The optional description for the place index resource.
  index_name: string # The name of the place index resource. Requirements: Contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique place index resource name. No spaces allowed. For example, ExamplePlaceIndex.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --tags: record # Applies one or more tags to the place index resource. A tag is a key-value pair that helps you manage, identify, search, and filter your resources. Format: "key" : "value" Restrictions: Maximum 50 tags per resource. Each tag key must be unique and must have exactly one associated value. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @ Cannot use "aws:" as a prefix for a key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/v0/indexes"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSource, var: data_source}, {name: DataSourceConfiguration, var: data_source_configuration}, {name: Description, var: description}, {name: IndexName, var: index_name}, {name: PricingPlan, var: pricing_plan}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, data_source: $data_source, data_source_configuration: $data_source_configuration, description: $description, index_name: $index_name, pricing_plan: $pricing_plan, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a route calculator resource in your Amazon Web Services account. You can send requests to a route calculator resource to estimate travel time, distance, and get directions. A route calculator sources traffic and road network data from your chosen data provider. If your application is tracking or routing assets you use in your business, such as delivery vehicles or employees, you must not use Esri as your geolocation provider. See section 82 of the Amazon Web Services service terms (http://aws.amazon.com/service-terms) for more details.
#
# POST /routes/v0/calculators
# Returns: record<CalculatorArn: string, CalculatorName: string, CreateTime: string>
# operationId: CreateRouteCalculator
export def "create-route-calculator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  calculator_name: string # The name of the route calculator resource. Requirements: Can use alphanumeric characters (A–Z, a–z, 0–9) , hyphens (-), periods (.), and underscores (_). Must be a unique Route calculator resource name. No spaces allowed. For example, ExampleRouteCalculator.
  data_source: string # Specifies the data provider of traffic and road network data. This field is case-sensitive. Enter the valid values as shown. For example, entering HERE returns an error. Valid values include: Esri – For additional information about Esri (https://docs.aws.amazon.com/location/latest/developerguide/esri.html)'s coverage in your region of interest, see Esri details on street networks and traffic coverage (https://doc.arcgis.com/en/arcgis-online/reference/network-coverage.htm). Route calculators that use Esri as a data source only calculate routes that are shorter than 400 km. Grab – Grab provides routing functionality for Southeast Asia. For additional information about GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html)' coverage, see GrabMaps countries and areas covered (https://docs.aws.amazon.com/location/latest/developerguide/grab.html#grab-coverage-area). Here – For additional information about HERE Technologies (https://docs.aws.amazon.com/location/latest/developerguide/HERE.html)' coverage in your region of interest, see HERE car routing coverage (https://developer.here.com/documentation/routing-api/dev_guide/topics/coverage/car-routing.html) and HERE truck routing coverage (https://developer.here.com/documentation/routing-api/dev_guide/topics/coverage/truck-routing.html). For additional information , see Data providers (https://docs.aws.amazon.com/location/latest/developerguide/what-is-data-provider.html) on the Amazon Location Service Developer Guide.
  --description: string # The optional description for the route calculator resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --tags: record # Applies one or more tags to the route calculator resource. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. For example: { "tag1" : "value1", "tag2" : "value2"} Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/routes/v0/calculators"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CalculatorName, var: calculator_name}, {name: DataSource, var: data_source}, {name: Description, var: description}, {name: PricingPlan, var: pricing_plan}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, calculator_name: $calculator_name, data_source: $data_source, description: $description, pricing_plan: $pricing_plan, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a tracker resource in your Amazon Web Services account, which lets you retrieve current and historical location of devices.
#
# POST /tracking/v0/trackers
# Returns: record<CreateTime: string, TrackerArn: string, TrackerName: string>
# operationId: CreateTracker
export def "create-tracker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # An optional description for the tracker resource.
  --kms-key-id: string # A key identifier for an Amazon Web Services KMS customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html). Enter a key ID, key ARN, alias name, or alias ARN.
  --position-filtering: string@position-filtering-completer # Specifies the position filtering for the tracker resource. Valid values: TimeBased - Location updates are evaluated against linked geofence collections, but not every location update is stored. If your update frequency is more often than 30 seconds, only one update per 30 seconds is stored for each unique device ID. DistanceBased - If the device has moved less than 30 m (98.4 ft), location updates are ignored. Location updates within this area are neither evaluated against linked geofence collections, nor stored. This helps control costs by reducing the number of geofence evaluations and historical device positions to paginate through. Distance-based filtering can also reduce the effects of GPS noise when displaying device trajectories on a map. AccuracyBased - If the device has moved less than the measured accuracy, location updates are ignored. For example, if two consecutive updates from a device have a horizontal accuracy of 5 m and 10 m, the second update is ignored if the device has moved less than 15 m. Ignored location updates are neither evaluated against linked geofence collections, nor stored. This can reduce the effects of GPS noise when displaying device trajectories on a map, and can help control your costs by reducing the number of geofence evaluations. This field is optional. If not specified, the default value is TimeBased.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
  --tags: record # Applies one or more tags to the tracker resource. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
  tracker_name: string # The name for the tracker resource. Requirements: Contain only alphanumeric characters (A-Z, a-z, 0-9) , hyphens (-), periods (.), and underscores (_). Must be a unique tracker resource name. No spaces allowed. For example, ExampleTracker.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: KmsKeyId, var: kms_key_id}, {name: PositionFiltering, var: position_filtering}, {name: PricingPlan, var: pricing_plan}, {name: PricingPlanDataSource, var: pricing_plan_data_source}, {name: Tags, var: tags}, {name: TrackerName, var: tracker_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, kms_key_id: $kms_key_id, position_filtering: $position_filtering, pricing_plan: $pricing_plan, pricing_plan_data_source: $pricing_plan_data_source, tags: $tags, tracker_name: $tracker_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a geofence collection from your Amazon Web Services account. This operation deletes the resource permanently. If the geofence collection is the target of a tracker resource, the devices will no longer be monitored.
#
# DELETE /geofencing/v0/collections/{CollectionName}
# Returns: record
# operationId: DeleteGeofenceCollection
export def "delete-geofence-collection" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/geofencing/v0/collections/{CollectionName}"
    path_params: [{name: CollectionName, var: collection_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the geofence collection details.
#
# GET /geofencing/v0/collections/{CollectionName}
# Returns: record<CollectionArn: string, CollectionName: string, CreateTime: string, Description: string, KmsKeyId: string, PricingPlan: string, PricingPlanDataSource: string, Tags: record, UpdateTime: string>
# operationId: DescribeGeofenceCollection
export def "describe-geofence-collection" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/geofencing/v0/collections/{CollectionName}"
    path_params: [{name: CollectionName, var: collection_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified properties of a given geofence collection.
#
# PATCH /geofencing/v0/collections/{CollectionName}
# Returns: record<CollectionArn: string, CollectionName: string, UpdateTime: string>
# operationId: UpdateGeofenceCollection
export def "update-geofence-collection" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the geofence collection.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/geofencing/v0/collections/{CollectionName}"
    path_params: [{name: CollectionName, var: collection_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: PricingPlan, var: pricing_plan}, {name: PricingPlanDataSource, var: pricing_plan_data_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, pricing_plan: $pricing_plan, pricing_plan_data_source: $pricing_plan_data_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified API key. The API key must have been deactivated more than 90 days previously.
#
# DELETE /metadata/v0/keys/{KeyName}
# Returns: record
# operationId: DeleteKey
export def "delete-key" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/metadata/v0/keys/{KeyName}"
    path_params: [{name: KeyName, var: key_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the API key resource details. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# GET /metadata/v0/keys/{KeyName}
# Returns: record<CreateTime: string, Description: string, ExpireTime: string, Key: string, KeyArn: string, KeyName: string, Restrictions: record<AllowActions: list<string>, AllowReferers: list<string>, AllowResources: list<string>>, Tags: record, UpdateTime: string>
# operationId: DescribeKey
export def "describe-key" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/metadata/v0/keys/{KeyName}"
    path_params: [{name: KeyName, var: key_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified properties of a given API key resource. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# PATCH /metadata/v0/keys/{KeyName}
# Returns: record<KeyArn: string, KeyName: string, UpdateTime: string>
# operationId: UpdateKey
export def "update-key" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the API key resource.
  --expire-time: string # Updates the timestamp for when the API key resource will expire in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. (format: date-time)
  --force-update: oneof<nothing, bool> # The boolean flag to be included for updating ExpireTime or Restrictions details. Must be set to true to update an API key resource that has been used in the past 7 days. False if force update is not preferred Default value: False
  --no-expiry: oneof<nothing, bool> # Whether the API key should expire. Set to true to set the API key to have no expiration time.
  --restrictions: record # API Restrictions on the allowed actions, resources, and referers for an API key resource. — shape: {AllowActions?: list<string>, AllowReferers?: list<string>, AllowResources?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/metadata/v0/keys/{KeyName}"
    path_params: [{name: KeyName, var: key_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: ExpireTime, var: expire_time}, {name: ForceUpdate, var: force_update}, {name: NoExpiry, var: no_expiry}, {name: Restrictions, var: restrictions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, expire_time: $expire_time, force_update: $force_update, no_expiry: $no_expiry, restrictions: $restrictions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a map resource from your Amazon Web Services account. This operation deletes the resource permanently. If the map is being used in an application, the map may not render.
#
# DELETE /maps/v0/maps/{MapName}
# Returns: record
# operationId: DeleteMap
export def "delete-map" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/maps/v0/maps/{MapName}"
    path_params: [{name: MapName, var: map_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_name: $map_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the map resource details.
#
# GET /maps/v0/maps/{MapName}
# Returns: record<Configuration: record<Style: string>, CreateTime: string, DataSource: string, Description: string, MapArn: string, MapName: string, PricingPlan: string, Tags: record, UpdateTime: string>
# operationId: DescribeMap
export def "describe-map" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/maps/v0/maps/{MapName}"
    path_params: [{name: MapName, var: map_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_name: $map_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified properties of a given map resource.
#
# PATCH /maps/v0/maps/{MapName}
# Returns: record<MapArn: string, MapName: string, UpdateTime: string>
# operationId: UpdateMap
export def "update-map" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the map resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/maps/v0/maps/{MapName}"
    path_params: [{name: MapName, var: map_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: PricingPlan, var: pricing_plan}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_name: $map_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, pricing_plan: $pricing_plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a place index resource from your Amazon Web Services account. This operation deletes the resource permanently.
#
# DELETE /places/v0/indexes/{IndexName}
# Returns: record
# operationId: DeletePlaceIndex
export def "delete-place-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/places/v0/indexes/{IndexName}"
    path_params: [{name: IndexName, var: index_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the place index resource details.
#
# GET /places/v0/indexes/{IndexName}
# Returns: record<CreateTime: string, DataSource: string, DataSourceConfiguration: record<IntendedUse: string>, Description: string, IndexArn: string, IndexName: string, PricingPlan: string, Tags: record, UpdateTime: string>
# operationId: DescribePlaceIndex
export def "describe-place-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/places/v0/indexes/{IndexName}"
    path_params: [{name: IndexName, var: index_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified properties of a given place index resource.
#
# PATCH /places/v0/indexes/{IndexName}
# Returns: record<IndexArn: string, IndexName: string, UpdateTime: string>
# operationId: UpdatePlaceIndex
export def "update-place-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --data-source-configuration: record # Specifies the data storage option chosen for requesting Places. When using Amazon Location Places: If using HERE Technologies as a data provider, you can't store results for locations in Japan by setting IntendedUse to Storage. parameter. Under the MobileAssetTracking or MobilAssetManagement pricing plan, you can't store results from your place index resources by setting IntendedUse to Storage. This returns a validation exception error. For more information, see the AWS Service Terms (https://aws.amazon.com/service-terms/) for Amazon Location Service. — shape: {IntendedUse?: "SingleUse"|"Storage"}
  --description: string # Updates the description for the place index resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/places/v0/indexes/{IndexName}"
    path_params: [{name: IndexName, var: index_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceConfiguration, var: data_source_configuration}, {name: Description, var: description}, {name: PricingPlan, var: pricing_plan}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, data_source_configuration: $data_source_configuration, description: $description, pricing_plan: $pricing_plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a route calculator resource from your Amazon Web Services account. This operation deletes the resource permanently.
#
# DELETE /routes/v0/calculators/{CalculatorName}
# Returns: record
# operationId: DeleteRouteCalculator
export def "delete-route-calculator" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/routes/v0/calculators/{CalculatorName}"
    path_params: [{name: CalculatorName, var: calculator_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calculator_name: $calculator_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the route calculator resource details.
#
# GET /routes/v0/calculators/{CalculatorName}
# Returns: record<CalculatorArn: string, CalculatorName: string, CreateTime: string, DataSource: string, Description: string, PricingPlan: string, Tags: record, UpdateTime: string>
# operationId: DescribeRouteCalculator
export def "describe-route-calculator" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/routes/v0/calculators/{CalculatorName}"
    path_params: [{name: CalculatorName, var: calculator_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calculator_name: $calculator_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified properties for a given route calculator resource.
#
# PATCH /routes/v0/calculators/{CalculatorName}
# Returns: record<CalculatorArn: string, CalculatorName: string, UpdateTime: string>
# operationId: UpdateRouteCalculator
export def "update-route-calculator" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the route calculator resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/routes/v0/calculators/{CalculatorName}"
    path_params: [{name: CalculatorName, var: calculator_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: PricingPlan, var: pricing_plan}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calculator_name: $calculator_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, pricing_plan: $pricing_plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a tracker resource from your Amazon Web Services account. This operation deletes the resource permanently. If the tracker resource is in use, you may encounter an error. Make sure that the target resource isn't a dependency for your applications.
#
# DELETE /tracking/v0/trackers/{TrackerName}
# Returns: record
# operationId: DeleteTracker
export def "delete-tracker" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/tracking/v0/trackers/{TrackerName}"
    path_params: [{name: TrackerName, var: tracker_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the tracker resource details.
#
# GET /tracking/v0/trackers/{TrackerName}
# Returns: record<CreateTime: string, Description: string, KmsKeyId: string, PositionFiltering: string, PricingPlan: string, PricingPlanDataSource: string, Tags: record, TrackerArn: string, TrackerName: string, UpdateTime: string>
# operationId: DescribeTracker
export def "describe-tracker" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/tracking/v0/trackers/{TrackerName}"
    path_params: [{name: TrackerName, var: tracker_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified properties of a given tracker resource.
#
# PATCH /tracking/v0/trackers/{TrackerName}
# Returns: record<TrackerArn: string, TrackerName: string, UpdateTime: string>
# operationId: UpdateTracker
export def "update-tracker" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the tracker resource.
  --position-filtering: string@position-filtering-completer # Updates the position filtering for the tracker resource. Valid values: TimeBased - Location updates are evaluated against linked geofence collections, but not every location update is stored. If your update frequency is more often than 30 seconds, only one update per 30 seconds is stored for each unique device ID. DistanceBased - If the device has moved less than 30 m (98.4 ft), location updates are ignored. Location updates within this distance are neither evaluated against linked geofence collections, nor stored. This helps control costs by reducing the number of geofence evaluations and historical device positions to paginate through. Distance-based filtering can also reduce the effects of GPS noise when displaying device trajectories on a map. AccuracyBased - If the device has moved less than the measured accuracy, location updates are ignored. For example, if two consecutive updates from a device have a horizontal accuracy of 5 m and 10 m, the second update is ignored if the device has moved less than 15 m. Ignored location updates are neither evaluated against linked geofence collections, nor stored. This helps educe the effects of GPS noise when displaying device trajectories on a map, and can help control costs by reducing the number of geofence evaluations.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tracking/v0/trackers/{TrackerName}"
    path_params: [{name: TrackerName, var: tracker_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: PositionFiltering, var: position_filtering}, {name: PricingPlan, var: pricing_plan}, {name: PricingPlanDataSource, var: pricing_plan_data_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, position_filtering: $position_filtering, pricing_plan: $pricing_plan, pricing_plan_data_source: $pricing_plan_data_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the association between a tracker resource and a geofence collection. Once you unlink a tracker resource from a geofence collection, the tracker positions will no longer be automatically evaluated against geofences.
#
# DELETE /tracking/v0/trackers/{TrackerName}/consumers/{ConsumerArn}
# Returns: record
# operationId: DisassociateTrackerConsumer
export def "disassociate-tracker-consumer" [
  tracker_name: string
  consumer_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/tracking/v0/trackers/{TrackerName}/consumers/{ConsumerArn}"
    path_params: [{name: TrackerName, var: tracker_name}, {name: ConsumerArn, var: consumer_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, consumer_arn: $consumer_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a device's most recent position according to its sample time. Device positions are deleted after 30 days.
#
# GET /tracking/v0/trackers/{TrackerName}/devices/{DeviceId}/positions/latest
# Returns: record<Accuracy: record<Horizontal: float>, DeviceId: string, Position: list<float>, PositionProperties: record, ReceivedTime: string, SampleTime: string>
# operationId: GetDevicePosition
export def "get-device-position" [
  tracker_name: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/tracking/v0/trackers/{TrackerName}/devices/{DeviceId}/positions/latest"
    path_params: [{name: TrackerName, var: tracker_name}, {name: DeviceId, var: device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, device_id: $device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the device position history from a tracker resource within a specified range of time. Device positions are deleted after 30 days.
#
# POST /tracking/v0/trackers/{TrackerName}/devices/{DeviceId}/list-positions
# Returns: record<DevicePositions: table<Accuracy: record, DeviceId: string, Position: list, PositionProperties: record, ReceivedTime: string, SampleTime: string>, NextToken: string>
# operationId: GetDevicePositionHistory
export def "get-device-position-history" [
  tracker_name: string
  device_id: string
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
  --end-time-exclusive: string # Specify the end time for the position history in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. By default, the value will be the time that the request is made. Requirement: The time specified for EndTimeExclusive must be after the time for StartTimeInclusive. (format: date-time)
  --body-max-results: int # An optional limit for the number of device positions returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
  --start-time-inclusive: string # Specify the start time for the position history in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. By default, the value will be 24 hours prior to the time that the request is made. Requirement: The time specified for StartTimeInclusive must be before EndTimeExclusive. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers/{TrackerName}/devices/{DeviceId}/list-positions"
    path_params: [{name: TrackerName, var: tracker_name}, {name: DeviceId, var: device_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndTimeExclusive, var: end_time_exclusive}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: StartTimeInclusive, var: start_time_inclusive}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, device_id: $device_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, end_time_exclusive: $end_time_exclusive, body_max_results: $body_max_results, body_next_token: $body_next_token, start_time_inclusive: $start_time_inclusive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the geofence details from a geofence collection.
#
# GET /geofencing/v0/collections/{CollectionName}/geofences/{GeofenceId}
# Returns: record<CreateTime: string, GeofenceId: string, Geometry: record<Circle: record<Center: list, Radius: float>, Polygon: list<list>>, Status: string, UpdateTime: string>
# operationId: GetGeofence
export def "get-geofence" [
  collection_name: string
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/geofencing/v0/collections/{CollectionName}/geofences/{GeofenceId}"
    path_params: [{name: CollectionName, var: collection_name}, {name: GeofenceId, var: geofence_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, geofence_id: $geofence_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stores a geofence geometry in a given geofence collection, or updates the geometry of an existing geofence if a geofence ID is included in the request.
#
# PUT /geofencing/v0/collections/{CollectionName}/geofences/{GeofenceId}
# Returns: record<CreateTime: string, GeofenceId: string, UpdateTime: string>
# operationId: PutGeofence
export def "put-geofence" [
  collection_name: string
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  geometry: record # Contains the geofence geometry details. A geofence geometry is made up of either a polygon or a circle. Can be either a polygon or a circle. Including both will return a validation error. Amazon Location doesn't currently support polygons with holes, multipolygons, polygons that are wound clockwise, or that cross the antimeridian. — shape: {Circle?: record, Polygon?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/geofencing/v0/collections/{CollectionName}/geofences/{GeofenceId}"
    path_params: [{name: CollectionName, var: collection_name}, {name: GeofenceId, var: geofence_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Geometry, var: geometry}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, geofence_id: $geofence_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, geometry: $geometry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves glyphs used to display labels on a map.
#
# GET /maps/v0/maps/{MapName}/glyphs/{FontStack}/{FontUnicodeRange}
# Returns: record<Blob: string>
# operationId: GetMapGlyphs
export def "get-map-glyphs" [
  map_name: string
  font_stack: string
  font_unicode_range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
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
    path: "/maps/v0/maps/{MapName}/glyphs/{FontStack}/{FontUnicodeRange}"
    path_params: [{name: MapName, var: map_name}, {name: FontStack, var: font_stack}, {name: FontUnicodeRange, var: font_unicode_range}]
    query: [{name: key, var: key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_name: $map_name, font_stack: $font_stack, font_unicode_range: $font_unicode_range, key: $key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the sprite sheet corresponding to a map resource. The sprite sheet is a PNG image paired with a JSON document describing the offsets of individual icons that will be displayed on a rendered map.
#
# GET /maps/v0/maps/{MapName}/sprites/{FileName}
# Returns: record<Blob: string>
# operationId: GetMapSprites
export def "get-map-sprites" [
  map_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
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
    path: "/maps/v0/maps/{MapName}/sprites/{FileName}"
    path_params: [{name: MapName, var: map_name}, {name: FileName, var: file_name}]
    query: [{name: key, var: key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_name: $map_name, file_name: $file_name, key: $key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the map style descriptor from a map resource. The style descriptor contains speciﬁcations on how features render on a map. For example, what data to display, what order to display the data in, and the style for the data. Style descriptors follow the Mapbox Style Specification.
#
# GET /maps/v0/maps/{MapName}/style-descriptor
# Returns: record<Blob: string>
# operationId: GetMapStyleDescriptor
export def "get-map-style-descriptor" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
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
    path: "/maps/v0/maps/{MapName}/style-descriptor"
    path_params: [{name: MapName, var: map_name}]
    query: [{name: key, var: key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_name: $map_name, key: $key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a vector data tile from the map resource. Map tiles are used by clients to render a map. they're addressed using a grid arrangement with an X coordinate, Y coordinate, and Z (zoom) level. The origin (0, 0) is the top left of the map. Increasing the zoom level by 1 doubles both the X and Y dimensions, so a tile containing data for the entire world at (0/0/0) will be split into 4 tiles at zoom 1 (1/0/0, 1/0/1, 1/1/0, 1/1/1).
#
# GET /maps/v0/maps/{MapName}/tiles/{Z}/{X}/{Y}
# Returns: record<Blob: string>
# operationId: GetMapTile
export def "get-map-tile" [
  map_name: string
  z: string
  x: string
  y: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
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
    path: "/maps/v0/maps/{MapName}/tiles/{Z}/{X}/{Y}"
    path_params: [{name: MapName, var: map_name}, {name: Z, var: z}, {name: X, var: x}, {name: Y, var: y}]
    query: [{name: key, var: key}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_name: $map_name, z: $z, x: $x, y: $y, key: $key, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finds a place by its unique ID. A PlaceId is returned by other search operations. A PlaceId is valid only if all of the following are the same in the original search request and the call to GetPlace. Customer Amazon Web Services account Amazon Web Services Region Data provider specified in the place index resource
#
# GET /places/v0/indexes/{IndexName}/places/{PlaceId}
# Returns: record<Place: record<AddressNumber: string, Country: string, Geometry: record<Point: list>, Interpolated: bool, Label: string, Municipality: string, Neighborhood: string, PostalCode: string, Region: string, Street: string, SubRegion: string, TimeZone: record<Name: string, Offset: int>, UnitNumber: string, UnitType: string>>
# operationId: GetPlace
export def "get-place" [
  index_name: string
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for a location around Athens, Greece, with the language parameter set to en. The city in the results will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the city in the results will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
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
    path: "/places/v0/indexes/{IndexName}/places/{PlaceId}"
    path_params: [{name: IndexName, var: index_name}, {name: PlaceId, var: place_id}]
    query: [{name: language, var: language}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, place_id: $place_id, language: $language, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A batch request to retrieve all device positions.
#
# POST /tracking/v0/trackers/{TrackerName}/list-positions
# Returns: record<Entries: table<Accuracy: record, DeviceId: string, Position: list, PositionProperties: record, SampleTime: string>, NextToken: string>
# operationId: ListDevicePositions
export def "list-device-positions" [
  tracker_name: string
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
  --body-max-results: int # An optional limit for the number of entries returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers/{TrackerName}/list-positions"
    path_params: [{name: TrackerName, var: tracker_name}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists geofence collections in your Amazon Web Services account.
#
# POST /geofencing/v0/list-collections
# Returns: record<Entries: table<CollectionName: string, CreateTime: string, Description: string, PricingPlan: string, PricingPlanDataSource: string, UpdateTime: string>, NextToken: string>
# operationId: ListGeofenceCollections
export def "list-geofence-collections" [
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
  --body-max-results: int # An optional limit for the number of resources returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofencing/v0/list-collections"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists geofences stored in a given geofence collection.
#
# POST /geofencing/v0/collections/{CollectionName}/list-geofences
# Returns: record<Entries: table<CreateTime: string, GeofenceId: string, Geometry: record, Status: string, UpdateTime: string>, NextToken: string>
# operationId: ListGeofences
export def "list-geofences" [
  collection_name: string
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
  --body-max-results: int # An optional limit for the number of geofences returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/geofencing/v0/collections/{CollectionName}/list-geofences"
    path_params: [{name: CollectionName, var: collection_name}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_name: $collection_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists API key resources in your Amazon Web Services account. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# POST /metadata/v0/list-keys
# Returns: record<Entries: table<CreateTime: string, Description: string, ExpireTime: string, KeyName: string, Restrictions: record, UpdateTime: string>, NextToken: string>
# operationId: ListKeys
export def "list-keys" [
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
  --filter: record # Options for filtering API keys. — shape: {KeyStatus?: "Active"|"Expired"}
  --body-max-results: int # An optional limit for the number of resources returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata/v0/list-keys"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filter: $filter, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists map resources in your Amazon Web Services account.
#
# POST /maps/v0/list-maps
# Returns: record<Entries: table<CreateTime: string, DataSource: string, Description: string, MapName: string, PricingPlan: string, UpdateTime: string>, NextToken: string>
# operationId: ListMaps
export def "list-maps" [
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
  --body-max-results: int # An optional limit for the number of resources returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/maps/v0/list-maps"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists place index resources in your Amazon Web Services account.
#
# POST /places/v0/list-indexes
# Returns: record<Entries: table<CreateTime: string, DataSource: string, Description: string, IndexName: string, PricingPlan: string, UpdateTime: string>, NextToken: string>
# operationId: ListPlaceIndexes
export def "list-place-indexes" [
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
  --body-max-results: int # An optional limit for the maximum number of results returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/v0/list-indexes"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists route calculator resources in your Amazon Web Services account.
#
# POST /routes/v0/list-calculators
# Returns: record<Entries: table<CalculatorName: string, CreateTime: string, DataSource: string, Description: string, PricingPlan: string, UpdateTime: string>, NextToken: string>
# operationId: ListRouteCalculators
export def "list-route-calculators" [
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
  --body-max-results: int # An optional maximum number of results returned in a single call. Default Value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default Value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/routes/v0/list-calculators"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of tags that are applied to the specified Amazon Location resource.
#
# GET /tags/{ResourceArn}
# Returns: record<Tags: record>
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
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns one or more tags (key-value pairs) to the specified Amazon Location Service resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the TagResource operation with an Amazon Location Service resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the tags already associated with the resource. If you specify a tag key that's already associated with the resource, the new tag value that you specify replaces the previous value for that tag. You can associate up to 50 tags with a resource.
#
# POST /tags/{ResourceArn}
# Returns: record
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
  tags: record # Applies one or more tags to specific resource. A tag is a key-value pair that helps you manage, identify, search, and filter your resources. Format: "key" : "value" Restrictions: Maximum 50 tags per resource. Each tag key must be unique and must have exactly one associated value. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @ Cannot use "aws:" as a prefix for a key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists geofence collections currently associated to the given tracker resource.
#
# POST /tracking/v0/trackers/{TrackerName}/list-consumers
# Returns: record<ConsumerArns: list<string>, NextToken: string>
# operationId: ListTrackerConsumers
export def "list-tracker-consumers" [
  tracker_name: string
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
  --body-max-results: int # An optional limit for the number of resources returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/trackers/{TrackerName}/list-consumers"
    path_params: [{name: TrackerName, var: tracker_name}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracker_name: $tracker_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists tracker resources in your Amazon Web Services account.
#
# POST /tracking/v0/list-trackers
# Returns: record<Entries: table<CreateTime: string, Description: string, PricingPlan: string, PricingPlanDataSource: string, TrackerName: string, UpdateTime: string>, NextToken: string>
# operationId: ListTrackers
export def "list-trackers" [
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
  --body-max-results: int # An optional limit for the number of resources returned in a single call. Default value: 100 (spec name: MaxResults)
  --body-next-token: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking/v0/list-trackers"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverse geocodes a given coordinate and returns a legible address. Allows you to search for Places or points of interest near a given position.
#
# POST /places/v0/indexes/{IndexName}/search/position
# Returns: record<Results: table<Distance: float, Place: record, PlaceId: string>, Summary: record<DataSource: string, Language: string, MaxResults: int, Position: list<float>>>
# operationId: SearchPlaceIndexForPosition
export def "search-place-index-for-position" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for a location around Athens, Greece, with the language parameter set to en. The city in the results will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the city in the results will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
  --max-results: int # An optional parameter. The maximum number of results returned per request. Default value: 50
  position: list<float> # Specifies the longitude and latitude of the position to query. This parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents a position with longitude -123.1174 and latitude 49.2847.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/v0/indexes/{IndexName}/search/position"
    path_params: [{name: IndexName, var: index_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Language, var: language}, {name: MaxResults, var: max_results}, {name: Position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, language: $language, max_results: $max_results, position: $position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates suggestions for addresses and points of interest based on partial or misspelled free-form text. This operation is also known as autocomplete, autosuggest, or fuzzy matching. Optional parameters let you narrow your search results by bounding box or country, or bias your search toward a specific position on the globe. You can search for suggested place names near a specified position by using BiasPosition, or filter results within a bounding box by using FilterBBox. These parameters are mutually exclusive; using both BiasPosition and FilterBBox in the same command returns an error.
#
# POST /places/v0/indexes/{IndexName}/search/suggestions
# Returns: record<Results: table<PlaceId: string, Text: string>, Summary: record<BiasPosition: list<float>, DataSource: string, FilterBBox: list<float>, FilterCountries: list<string>, Language: string, MaxResults: int, Text: string>>
# operationId: SearchPlaceIndexForSuggestions
export def "search-place-index-for-suggestions" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bias-position: list<float> # An optional parameter that indicates a preference for place suggestions that are closer to a specified position. If provided, this parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents the position with longitude -123.1174 and latitude 49.2847. BiasPosition and FilterBBox are mutually exclusive. Specifying both options results in an error.
  --filter-b-box: list<float> # An optional parameter that limits the search results by returning only suggestions within a specified bounding box. If provided, this parameter must contain a total of four consecutive numbers in two pairs. The first pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the southwest corner of the bounding box; the second pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the northeast corner of the bounding box. For example, [-12.7935, -37.4835, -12.0684, -36.9542] represents a bounding box where the southwest corner has longitude -12.7935 and latitude -37.4835, and the northeast corner has longitude -12.0684 and latitude -36.9542. FilterBBox and BiasPosition are mutually exclusive. Specifying both options results in an error.
  --filter-countries: list<string> # An optional parameter that limits the search results by returning only suggestions within the provided list of countries. Use the ISO 3166 (https://www.iso.org/iso-3166-country-codes.html) 3-digit country code. For example, Australia uses three upper-case characters: AUS.
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for Athens, Gr to get suggestions with the language parameter set to en. The results found will most likely be returned as Athens, Greece. If you set the language parameter to el, for Greek, then the result found will more likely be returned as Αθήνα, Ελλάδα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
  --max-results: int # An optional parameter. The maximum number of results returned per request. The default: 5
  text: string # The free-form partial text to use to generate place suggestions. For example, eiffel tow. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/v0/indexes/{IndexName}/search/suggestions"
    path_params: [{name: IndexName, var: index_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: BiasPosition, var: bias_position}, {name: FilterBBox, var: filter_b_box}, {name: FilterCountries, var: filter_countries}, {name: Language, var: language}, {name: MaxResults, var: max_results}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bias_position: $bias_position, filter_b_box: $filter_b_box, filter_countries: $filter_countries, language: $language, max_results: $max_results, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geocodes free-form text, such as an address, name, city, or region to allow you to search for Places or points of interest. Optional parameters let you narrow your search results by bounding box or country, or bias your search toward a specific position on the globe. You can search for places near a given position using BiasPosition, or filter results within a bounding box using FilterBBox. Providing both parameters simultaneously returns an error. Search results are returned in order of highest to lowest relevance.
#
# POST /places/v0/indexes/{IndexName}/search/text
# Returns: record<Results: table<Distance: float, Place: record, PlaceId: string, Relevance: float>, Summary: record<BiasPosition: list<float>, DataSource: string, FilterBBox: list<float>, FilterCountries: list<string>, Language: string, MaxResults: int, ResultBBox: list<float>, Text: string>>
# operationId: SearchPlaceIndexForText
export def "search-place-index-for-text" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bias-position: list<float> # An optional parameter that indicates a preference for places that are closer to a specified position. If provided, this parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents the position with longitude -123.1174 and latitude 49.2847. BiasPosition and FilterBBox are mutually exclusive. Specifying both options results in an error.
  --filter-b-box: list<float> # An optional parameter that limits the search results by returning only places that are within the provided bounding box. If provided, this parameter must contain a total of four consecutive numbers in two pairs. The first pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the southwest corner of the bounding box; the second pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the northeast corner of the bounding box. For example, [-12.7935, -37.4835, -12.0684, -36.9542] represents a bounding box where the southwest corner has longitude -12.7935 and latitude -37.4835, and the northeast corner has longitude -12.0684 and latitude -36.9542. FilterBBox and BiasPosition are mutually exclusive. Specifying both options results in an error.
  --filter-countries: list<string> # An optional parameter that limits the search results by returning only places that are in a specified list of countries. Valid values include ISO 3166 (https://www.iso.org/iso-3166-country-codes.html) 3-digit country codes. For example, Australia uses three upper-case characters: AUS.
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for Athens, Greece, with the language parameter set to en. The result found will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the result found will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
  --max-results: int # An optional parameter. The maximum number of results returned per request. The default: 50
  text: string # The address, name, city, or region to be used in the search in free-form text format. For example, 123 Any Street. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/places/v0/indexes/{IndexName}/search/text"
    path_params: [{name: IndexName, var: index_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: BiasPosition, var: bias_position}, {name: FilterBBox, var: filter_b_box}, {name: FilterCountries, var: filter_countries}, {name: Language, var: language}, {name: MaxResults, var: max_results}, {name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bias_position: $bias_position, filter_b_box: $filter_b_box, filter_countries: $filter_countries, language: $language, max_results: $max_results, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from the specified Amazon Location resource.
#
# DELETE /tags/{ResourceArn}
# Returns: record
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
  --tag-keys: list<string> # The list of tag keys to remove from the specified resource. (required)
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
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
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
