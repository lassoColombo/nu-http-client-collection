# Auto-generated client for Service Broker v1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/servicebroker/v1beta1/openapi.json
# Auth: --token flag or $env.SERVICE_BROKER_TOKEN

const CLIENT = {
  base_url: "https://servicebroker.googleapis.com"
  token_env_var: "SERVICE_BROKER_TOKEN"
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

def base-url-completer [] { ["https://servicebroker.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    servicebroker-projects-brokers-v2-service-instances-service-bindings-delete: "record<description: string, operation: string>"
    servicebroker-projects-brokers-v2-service-instances-service-bindings-get: "record<credentials: record, deploymentName: string, description: string, resourceName: string, route_service_url: string, syslog_drain_url: string, volume_mounts: list<record>>"
    servicebroker-projects-brokers-v2-service-instances-patch: "record<description: string, operation: string>"
    servicebroker-projects-brokers-v2-service-instances-service-bindings-get-last-operation: "record<description: string, state: string>"
    servicebroker-projects-brokers-instances-bindings-list: "record<bindings: table<bind_resource: record, binding_id: string, createTime: string, deploymentName: string, parameters: record, plan_id: string, resourceName: string, service_id: string>, description: string, nextPageToken: string>"
    servicebroker-projects-brokers-list: "record<brokers: table<createTime: string, name: string, title: string, url: string>, nextPageToken: string>"
    servicebroker-projects-brokers-create: "record<createTime: string, name: string, title: string, url: string>"
    servicebroker-projects-brokers-instances-list: "record<description: string, instances: table<context: record, createTime: string, deploymentName: string, description: string, instance_id: string, organization_guid: string, parameters: record, plan_id: string, previous_values: record, resourceName: string, service_id: string, space_guid: string>, nextPageToken: string>"
    servicebroker-projects-brokers-v2-service-instances-service-bindings-create: "record<credentials: record, description: string, operation: string, route_service_url: string, syslog_drain_url: string, volume_mounts: list<record>>"
    servicebroker-projects-brokers-v2-catalog-list: "record<description: string, nextPageToken: string, services: table<bindable: bool, binding_retrievable: bool, bindings_retrievable: bool, dashboard_client: record, description: string, id: string, instances_retrievable: bool, metadata: record, name: string, plan_updateable: bool, plans: list, tags: list>>"
    servicebroker-projects-brokers-v2-service-instances-create: "record<description: string, operation: string>"
    servicebroker-get-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    servicebroker-set-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    servicebroker-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["servicebroker-projects-brokers-v2-service-instances-service-bindings-delete" "servicebroker-projects-brokers-v2-service-instances-service-bindings-get" "servicebroker-projects-brokers-v2-service-instances-patch" "servicebroker-projects-brokers-v2-service-instances-service-bindings-get-last-operation" "servicebroker-projects-brokers-instances-bindings-list" "servicebroker-projects-brokers-list" "servicebroker-projects-brokers-create" "servicebroker-projects-brokers-instances-list" "servicebroker-projects-brokers-v2-service-instances-service-bindings-create" "servicebroker-projects-brokers-v2-catalog-list" "servicebroker-projects-brokers-v2-service-instances-create" "servicebroker-get-iam-policy" "servicebroker-set-iam-policy" "servicebroker-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Unbinds from a service instance. For synchronous/asynchronous request details see CreateServiceInstance method. If binding does not exist HTTP 410 status will be returned.
#
# DELETE /v1beta1/{name}
# Returns: record<description: string, operation: string>
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.delete
export def "servicebroker-projects-brokers-v2-service-instances-service-bindings-delete" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --plan-id: string # The plan id of the service instance.
  --service-id: string # Additional query parameter hints. The service id of the service instance.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: acceptsIncomplete, var: accepts_incomplete}, {name: planId, var: plan_id}, {name: serviceId, var: service_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, accepts_incomplete: $accepts_incomplete, plan_id: $plan_id, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetBinding returns the binding information.
#
# GET /v1beta1/{name}
# Returns: record<credentials: record, deploymentName: string, description: string, resourceName: string, route_service_url: string, syslog_drain_url: string, volume_mounts: list<record>>
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.get
export def "servicebroker-projects-brokers-v2-service-instances-service-bindings-get" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --plan-id: string # Plan id.
  --service-id: string # Service id.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: planId, var: plan_id}, {name: serviceId, var: service_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, plan_id: $plan_id, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing service instance. See CreateServiceInstance for possible response codes.
#
# PATCH /v1beta1/{name}
# Returns: record<description: string, operation: string>
# operationId: servicebroker.projects.brokers.v2.service_instances.patch
export def "servicebroker-projects-brokers-v2-service-instances-patch" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --context: record # Platform specific contextual information under which the service instance is to be provisioned. This replaces organization_guid and space_guid. But can also contain anything. Currently only used for logging context information.
  --create-time: string # Output only. Timestamp for when the instance was created. (format: google-datetime)
  --deployment-name: string # Output only. String containing the Deployment Manager deployment name that was created for this instance,
  --description: string # To return errors when GetInstance call is done via HTTP to be unified with other methods.
  --instance-id: string # The id of the service instance. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required.
  --organization-guid: string # The platform GUID for the organization under which the service is to be provisioned. Required.
  --parameters: record # Configuration options for the service instance. Parameters is JSON object serialized to string.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --previous-values: record # Used only in UpdateServiceInstance request to optionally specify previous fields.
  --resource-name: string # Output only. The resource name of the instance, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
  --space-guid: string # The identifier for the project space within the platform organization. Required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: acceptsIncomplete, var: accepts_incomplete}]
    body: {content_type: "application/json", kind: json, fields: [{name: context, var: context}, {name: createTime, var: create_time}, {name: deploymentName, var: deployment_name}, {name: description, var: description}, {name: instance_id, var: instance_id}, {name: organization_guid, var: organization_guid}, {name: parameters, var: parameters}, {name: plan_id, var: plan_id}, {name: previous_values, var: previous_values}, {name: resourceName, var: resource_name}, {name: service_id, var: service_id}, {name: space_guid, var: space_guid}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, accepts_incomplete: $accepts_incomplete, context: $context, create_time: $create_time, deployment_name: $deployment_name, description: $description, instance_id: $instance_id, organization_guid: $organization_guid, parameters: $parameters, plan_id: $plan_id, previous_values: $previous_values, resource_name: $resource_name, service_id: $service_id, space_guid: $space_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the state of the last operation for the binding. Only last (or current) operation can be polled.
#
# GET /v1beta1/{name}/last_operation
# Returns: record<description: string, state: string>
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.getLast_operation
export def "servicebroker-projects-brokers-v2-service-instances-service-bindings-get-last-operation" [
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --operation: string # If `operation` was returned during mutation operation, this field must be populated with the provided value.
  --plan-id: string # Plan id.
  --service-id: string # Service id.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/last_operation"
    path_params: [{name: name, var: name}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: operation, var: operation}, {name: planId, var: plan_id}, {name: serviceId, var: service_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, operation: $operation, plan_id: $plan_id, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the bindings in the instance.
#
# GET /v1beta1/{parent}/bindings
# Returns: record<bindings: table<bind_resource: record, binding_id: string, createTime: string, deploymentName: string, parameters: record, plan_id: string, resourceName: string, service_id: string>, description: string, nextPageToken: string>
# operationId: servicebroker.projects.brokers.instances.bindings.list
export def "servicebroker-projects-brokers-instances-bindings-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/bindings"
    path_params: [{name: parent, var: parent}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListBrokers lists brokers.
#
# GET /v1beta1/{parent}/brokers
# Returns: record<brokers: table<createTime: string, name: string, title: string, url: string>, nextPageToken: string>
# operationId: servicebroker.projects.brokers.list
export def "servicebroker-projects-brokers-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/brokers"
    path_params: [{name: parent, var: parent}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateBroker creates a Broker.
#
# POST /v1beta1/{parent}/brokers
# Returns: record<createTime: string, name: string, title: string, url: string>
# operationId: servicebroker.projects.brokers.create
export def "servicebroker-projects-brokers-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --create-time: string # Output only. Timestamp for when the broker was created. (format: google-datetime)
  --name: string # Name of the broker in the format: /<project-id>/brokers/. This allows for multiple brokers per project which can be used to enable having custom brokers per GKE cluster, for example.
  --title: string # User friendly title of the broker. Limited to 1024 characters. Requests with longer titles will be rejected.
  --url: string # Output only. URL of the broker OSB-compliant endpoint, for example: https://servicebroker.googleapis.com/projects//brokers/
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/brokers"
    path_params: [{name: parent, var: parent}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}]
    body: {content_type: "application/json", kind: json, fields: [{name: createTime, var: create_time}, {name: name, var: name}, {name: title, var: title}, {name: url, var: url}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, create_time: $create_time, name: $name, title: $title, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the instances in the brokers This API is an extension and not part of the OSB spec. Hence the path is a standard Google API URL.
#
# GET /v1beta1/{parent}/instances
# Returns: record<description: string, instances: table<context: record, createTime: string, deploymentName: string, description: string, instance_id: string, organization_guid: string, parameters: record, plan_id: string, previous_values: record, resourceName: string, service_id: string, space_guid: string>, nextPageToken: string>
# operationId: servicebroker.projects.brokers.instances.list
export def "servicebroker-projects-brokers-instances-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/instances"
    path_params: [{name: parent, var: parent}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateBinding generates a service binding to an existing service instance. See ProviServiceInstance for async operation details.
#
# PUT /v1beta1/{parent}/service_bindings/{binding_id}
# Returns: record<credentials: record, description: string, operation: string, route_service_url: string, syslog_drain_url: string, volume_mounts: list<record>>
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.create
export def "servicebroker-projects-brokers-v2-service-instances-service-bindings-create" [
  parent: string
  binding_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --bind-resource: record # A JSON object that contains data for platform resources associated with the binding to be created.
  --body-binding-id: string # The id of the binding. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required. (spec name: binding_id)
  --create-time: string # Output only. Timestamp for when the binding was created. (format: google-datetime)
  --deployment-name: string # Output only. String containing the Deployment Manager deployment name that was created for this binding,
  --parameters: record # Configuration options for the service binding.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --resource-name: string # Output only. The resource name of the binding, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id/bindings/binding_id.
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1beta1/{parent}/service_bindings/{binding_id}"
    path_params: [{name: parent, var: parent}, {name: binding_id, var: binding_id}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: acceptsIncomplete, var: accepts_incomplete}]
    body: {content_type: "application/json", kind: json, fields: [{name: bind_resource, var: bind_resource}, {name: binding_id, var: body_binding_id}, {name: createTime, var: create_time}, {name: deploymentName, var: deployment_name}, {name: parameters, var: parameters}, {name: plan_id, var: plan_id}, {name: resourceName, var: resource_name}, {name: service_id, var: service_id}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, binding_id: $binding_id, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, accepts_incomplete: $accepts_incomplete, bind_resource: $bind_resource, body_binding_id: $body_binding_id, create_time: $create_time, deployment_name: $deployment_name, parameters: $parameters, plan_id: $plan_id, resource_name: $resource_name, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the Services registered with this broker for consumption for given service registry broker, which contains an set of services. Note, that Service producer API is separate from Broker API.
#
# GET /v1beta1/{parent}/v2/catalog
# Returns: record<description: string, nextPageToken: string, services: table<bindable: bool, binding_retrievable: bool, bindings_retrievable: bool, dashboard_client: record, description: string, id: string, instances_retrievable: bool, metadata: record, name: string, plan_updateable: bool, plans: list, tags: list>>
# operationId: servicebroker.projects.brokers.v2.catalog.list
export def "servicebroker-projects-brokers-v2-catalog-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. If unset or 0, all the results will be returned.
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/v2/catalog"
    path_params: [{name: parent, var: parent}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a service instance. If `request.accepts_incomplete` is false and Broker cannot execute request synchronously HTTP 422 error will be returned along with FAILED_PRECONDITION status. If `request.accepts_incomplete` is true and the Broker decides to execute resource asynchronously then HTTP 202 response code will be returned and a valid polling operation in the response will be included. If Broker executes the request synchronously and it succeeds HTTP 201 response will be furnished. If identical instance exists, then HTTP 200 response will be returned. If an instance with identical ID but mismatching parameters exists, then HTTP 409 status code will be returned.
#
# PUT /v1beta1/{parent}/v2/service_instances/{instance_id}
# Returns: record<description: string, operation: string>
# operationId: servicebroker.projects.brokers.v2.service_instances.create
export def "servicebroker-projects-brokers-v2-service-instances-create" [
  parent: string
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
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # Value indicating that API client supports asynchronous operations. If Broker cannot execute the request synchronously HTTP 422 code will be returned to HTTP clients along with FAILED_PRECONDITION error. If true and broker will execute request asynchronously 202 HTTP code will be returned. This broker always requires this to be true as all mutator operations are asynchronous.
  --context: record # Platform specific contextual information under which the service instance is to be provisioned. This replaces organization_guid and space_guid. But can also contain anything. Currently only used for logging context information.
  --create-time: string # Output only. Timestamp for when the instance was created. (format: google-datetime)
  --deployment-name: string # Output only. String containing the Deployment Manager deployment name that was created for this instance,
  --description: string # To return errors when GetInstance call is done via HTTP to be unified with other methods.
  --body-instance-id: string # The id of the service instance. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required. (spec name: instance_id)
  --organization-guid: string # The platform GUID for the organization under which the service is to be provisioned. Required.
  --parameters: record # Configuration options for the service instance. Parameters is JSON object serialized to string.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --previous-values: record # Used only in UpdateServiceInstance request to optionally specify previous fields.
  --resource-name: string # Output only. The resource name of the instance, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
  --space-guid: string # The identifier for the project space within the platform organization. Required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1beta1/{parent}/v2/service_instances/{instance_id}"
    path_params: [{name: parent, var: parent}, {name: instance_id, var: instance_id}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: acceptsIncomplete, var: accepts_incomplete}]
    body: {content_type: "application/json", kind: json, fields: [{name: context, var: context}, {name: createTime, var: create_time}, {name: deploymentName, var: deployment_name}, {name: description, var: description}, {name: instance_id, var: body_instance_id}, {name: organization_guid, var: organization_guid}, {name: parameters, var: parameters}, {name: plan_id, var: plan_id}, {name: previous_values, var: previous_values}, {name: resourceName, var: resource_name}, {name: service_id, var: service_id}, {name: space_guid, var: space_guid}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, instance_id: $instance_id, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, accepts_incomplete: $accepts_incomplete, context: $context, create_time: $create_time, deployment_name: $deployment_name, description: $description, body_instance_id: $body_instance_id, organization_guid: $organization_guid, parameters: $parameters, plan_id: $plan_id, previous_values: $previous_values, resource_name: $resource_name, service_id: $service_id, space_guid: $space_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# GET /v1beta1/{resource}:getIamPolicy
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: servicebroker.getIamPolicy
export def "servicebroker-get-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --options-requested-policy-version: int # Optional. The policy format version to be returned. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional bindings must specify version 3. Policies without any conditional bindings may specify any valid value or leave the field unset.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{resource}:getIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}, {name: "options.requestedPolicyVersion", var: options_requested_policy_version}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, options_requested_policy_version: $options_requested_policy_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return Public Errors: NOT_FOUND, INVALID_ARGUMENT and PERMISSION_DENIED
#
# POST /v1beta1/{resource}:setIamPolicy
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: servicebroker.setIamPolicy
export def "servicebroker-set-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members` to a single `role`. Members can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. Optionally, a `binding` can specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": ["user:eve@example.com"], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') - etag: BwWWja0YfJA= - version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {bindings?: list, etag?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{resource}:setIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a NOT_FOUND error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1beta1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: servicebroker.testIamPermissions
export def "servicebroker-test-iam-permissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as '*' or 'storage.*') are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{resource}:testIamPermissions"
    path_params: [{name: resource, var: resource}]
    query: [{name: fields, var: fields}, {name: uploadType, var: upload_type}, {name: callback, var: callback}, {name: oauth_token, var: oauth_token}, {name: "$.xgafv", var: xgafv}, {name: alt, var: alt}, {name: access_token, var: access_token}, {name: key, var: key}, {name: upload_protocol, var: upload_protocol}, {name: quotaUser, var: quota_user}, {name: prettyPrint, var: pretty_print}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, fields: $fields, upload_type: $upload_type, callback: $callback, oauth_token: $oauth_token, xgafv: $xgafv, alt: $alt, access_token: $access_token, key: $key, upload_protocol: $upload_protocol, quota_user: $quota_user, pretty_print: $pretty_print, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
