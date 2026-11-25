# Auto-generated client for Routing v1.0.0
# Source: https://api.apis.guru/v2/specs/tomtom.com/routing/1.0.0/openapi.json
# Auth: --token flag or $env.ROUTING_TOKEN

const CLIENT = {
  base_url: "https://api.tomtom.com"
  token_env_var: "ROUTING_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-key, in: query, header_name: key, prefix: ""}
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

def base-url-completer [] { ["https://api.tomtom.com"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def version-number-completer [] { ["1"] }
def content-type-completer [] { ["json" "jsonp" "xml"] }
def report-completer [] { ["effectiveSettings"] }
def route-type-completer [] { ["eco" "fastest" "shortest" "thrilling"] }
def travel-mode-completer [] { ["bicycle" "bus" "car" "motorcycle" "pedestrian" "taxi" "truck" "van"] }
def hilliness-completer [] { ["high" "low" "normal"] }
def windingness-completer [] { ["high" "low" "normal"] }
def vehicle-engine-type-completer [] { ["combustion" "electric"] }
def alternative-type-completer [] { ["anyRoute" "betterRoute"] }
def instructions-type-completer [] { ["coded" "tagged" "text"] }
def route-representation-completer [] { ["none" "polyline"] }
def compute-travel-time-for-completer [] { ["all" "none"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-routing-version-number-calculate-reachable-range-origin-content-type" "post-routing-version-number-calculate-reachable-range-origin-content-type" "get-routing-version-number-calculate-route-locations-content-type" "post-routing-version-number-calculate-route-locations-content-type" "commands"] | sort) } | get name | first)
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

# Reachable Range
#
# GET /routing/{versionNumber}/calculateReachableRange/{origin}/{contentType}
export def "get-routing-version-number-calculate-reachable-range-origin-content-type" [
  version_number: int@version-number-completer
  origin: string
  content_type: string@content-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fuel-budget-in-liters: float # Fuel budget in liters. Determines the maximum vehicle range using the specified Combustion Consumption Model. (format: float)
  --energy-budget-ink-wh: float # Electric energy budget in kilowatt hours (kWh). Determines the maximum vehicle range using the specified Electric Consumption Model. (format: float, e.g. 43)
  --time-budget-in-sec: float # Time budget in seconds. Determines the maximum vehicle range using the specified driving time. The consumption parameters in the request will only affect eco-routes, and thereby indirectly the driving time. (format: float)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion, e.g. electric)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs. (e.g. 50,8.2:130,21.3)
]: nothing -> any {
  http-request {
    method: get
    path: "/routing/{versionNumber}/calculateReachableRange/{origin}/{contentType}"
    path_params: [{name: versionNumber, var: version_number}, {name: origin, var: origin}, {name: contentType, var: content_type}]
    query: [{name: fuelBudgetInLiters, var: fuel_budget_in_liters}, {name: energyBudgetInkWh, var: energy_budget_ink_wh}, {name: timeBudgetInSec, var: time_budget_in_sec}, {name: callback, var: callback}, {name: report, var: report}, {name: departAt, var: depart_at}, {name: arriveAt, var: arrive_at}, {name: routeType, var: route_type}, {name: traffic, var: traffic}, {name: avoid, var: avoid}, {name: travelMode, var: travel_mode}, {name: hilliness, var: hilliness}, {name: windingness, var: windingness}, {name: vehicleMaxSpeed, var: vehicle_max_speed}, {name: vehicleWeight, var: vehicle_weight}, {name: vehicleAxleWeight, var: vehicle_axle_weight}, {name: vehicleLength, var: vehicle_length}, {name: vehicleWidth, var: vehicle_width}, {name: vehicleHeight, var: vehicle_height}, {name: vehicleCommercial, var: vehicle_commercial}, {name: vehicleLoadType, var: vehicle_load_type}, {name: constantSpeedConsumptionInLitersPerHundredkm, var: constant_speed_consumption_in_liters_per_hundredkm}, {name: currentFuelInLiters, var: current_fuel_in_liters}, {name: auxiliaryPowerInLitersPerHour, var: auxiliary_power_in_liters_per_hour}, {name: fuelEnergyDensityInMJoulesPerLiter, var: fuel_energy_density_in_m_joules_per_liter}, {name: accelerationEfficiency, var: acceleration_efficiency}, {name: decelerationEfficiency, var: deceleration_efficiency}, {name: uphillEfficiency, var: uphill_efficiency}, {name: downhillEfficiency, var: downhill_efficiency}, {name: vehicleEngineType, var: vehicle_engine_type}, {name: constantSpeedConsumptionInkWhPerHundredkm, var: constant_speed_consumption_ink_wh_per_hundredkm}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, origin: $origin, content_type: $content_type, fuel_budget_in_liters: $fuel_budget_in_liters, energy_budget_ink_wh: $energy_budget_ink_wh, time_budget_in_sec: $time_budget_in_sec, callback: $callback, report: $report, depart_at: $depart_at, arrive_at: $arrive_at, route_type: $route_type, traffic: $traffic, avoid: $avoid, travel_mode: $travel_mode, hilliness: $hilliness, windingness: $windingness, vehicle_max_speed: $vehicle_max_speed, vehicle_weight: $vehicle_weight, vehicle_axle_weight: $vehicle_axle_weight, vehicle_length: $vehicle_length, vehicle_width: $vehicle_width, vehicle_height: $vehicle_height, vehicle_commercial: $vehicle_commercial, vehicle_load_type: $vehicle_load_type, constant_speed_consumption_in_liters_per_hundredkm: $constant_speed_consumption_in_liters_per_hundredkm, current_fuel_in_liters: $current_fuel_in_liters, auxiliary_power_in_liters_per_hour: $auxiliary_power_in_liters_per_hour, fuel_energy_density_in_m_joules_per_liter: $fuel_energy_density_in_m_joules_per_liter, acceleration_efficiency: $acceleration_efficiency, deceleration_efficiency: $deceleration_efficiency, uphill_efficiency: $uphill_efficiency, downhill_efficiency: $downhill_efficiency, vehicle_engine_type: $vehicle_engine_type, constant_speed_consumption_ink_wh_per_hundredkm: $constant_speed_consumption_ink_wh_per_hundredkm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reachable Range
#
# POST /routing/{versionNumber}/calculateReachableRange/{origin}/{contentType}
export def "post-routing-version-number-calculate-reachable-range-origin-content-type" [
  version_number: int@version-number-completer
  origin: string
  content_type: string@content-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fuel-budget-in-liters: float # Fuel budget in liters. Determines the maximum vehicle range using the specified Combustion Consumption Model. (format: float)
  --energy-budget-ink-wh: float # Electric energy budget in kilowatt hours (kWh). Determines the maximum vehicle range using the specified Electric Consumption Model. (format: float, e.g. 43)
  --time-budget-in-sec: float # Time budget in seconds. Determines the maximum vehicle range using the specified driving time. The consumption parameters in the request will only affect eco-routes, and thereby indirectly the driving time. (format: float)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion, e.g. electric)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs. (e.g. 50,8.2:130,21.3)
  --allow-vignette: list<string>
  --avoid-areas: record # shape: {rectangles?: list}
  --avoid-vignette: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing/{versionNumber}/calculateReachableRange/{origin}/{contentType}"
    path_params: [{name: versionNumber, var: version_number}, {name: origin, var: origin}, {name: contentType, var: content_type}]
    query: [{name: fuelBudgetInLiters, var: fuel_budget_in_liters}, {name: energyBudgetInkWh, var: energy_budget_ink_wh}, {name: timeBudgetInSec, var: time_budget_in_sec}, {name: callback, var: callback}, {name: report, var: report}, {name: departAt, var: depart_at}, {name: arriveAt, var: arrive_at}, {name: routeType, var: route_type}, {name: traffic, var: traffic}, {name: avoid, var: avoid}, {name: travelMode, var: travel_mode}, {name: hilliness, var: hilliness}, {name: windingness, var: windingness}, {name: vehicleMaxSpeed, var: vehicle_max_speed}, {name: vehicleWeight, var: vehicle_weight}, {name: vehicleAxleWeight, var: vehicle_axle_weight}, {name: vehicleLength, var: vehicle_length}, {name: vehicleWidth, var: vehicle_width}, {name: vehicleHeight, var: vehicle_height}, {name: vehicleCommercial, var: vehicle_commercial}, {name: vehicleLoadType, var: vehicle_load_type}, {name: constantSpeedConsumptionInLitersPerHundredkm, var: constant_speed_consumption_in_liters_per_hundredkm}, {name: currentFuelInLiters, var: current_fuel_in_liters}, {name: auxiliaryPowerInLitersPerHour, var: auxiliary_power_in_liters_per_hour}, {name: fuelEnergyDensityInMJoulesPerLiter, var: fuel_energy_density_in_m_joules_per_liter}, {name: accelerationEfficiency, var: acceleration_efficiency}, {name: decelerationEfficiency, var: deceleration_efficiency}, {name: uphillEfficiency, var: uphill_efficiency}, {name: downhillEfficiency, var: downhill_efficiency}, {name: vehicleEngineType, var: vehicle_engine_type}, {name: constantSpeedConsumptionInkWhPerHundredkm, var: constant_speed_consumption_ink_wh_per_hundredkm}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowVignette, var: allow_vignette}, {name: avoidAreas, var: avoid_areas}, {name: avoidVignette, var: avoid_vignette}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, origin: $origin, content_type: $content_type, fuel_budget_in_liters: $fuel_budget_in_liters, energy_budget_ink_wh: $energy_budget_ink_wh, time_budget_in_sec: $time_budget_in_sec, callback: $callback, report: $report, depart_at: $depart_at, arrive_at: $arrive_at, route_type: $route_type, traffic: $traffic, avoid: $avoid, travel_mode: $travel_mode, hilliness: $hilliness, windingness: $windingness, vehicle_max_speed: $vehicle_max_speed, vehicle_weight: $vehicle_weight, vehicle_axle_weight: $vehicle_axle_weight, vehicle_length: $vehicle_length, vehicle_width: $vehicle_width, vehicle_height: $vehicle_height, vehicle_commercial: $vehicle_commercial, vehicle_load_type: $vehicle_load_type, constant_speed_consumption_in_liters_per_hundredkm: $constant_speed_consumption_in_liters_per_hundredkm, current_fuel_in_liters: $current_fuel_in_liters, auxiliary_power_in_liters_per_hour: $auxiliary_power_in_liters_per_hour, fuel_energy_density_in_m_joules_per_liter: $fuel_energy_density_in_m_joules_per_liter, acceleration_efficiency: $acceleration_efficiency, deceleration_efficiency: $deceleration_efficiency, uphill_efficiency: $uphill_efficiency, downhill_efficiency: $downhill_efficiency, vehicle_engine_type: $vehicle_engine_type, constant_speed_consumption_ink_wh_per_hundredkm: $constant_speed_consumption_ink_wh_per_hundredkm, allow_vignette: $allow_vignette, avoid_areas: $avoid_areas, avoid_vignette: $avoid_vignette
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Route
#
# GET /routing/{versionNumber}/calculateRoute/{locations}/{contentType}
export def "get-routing-version-number-calculate-route-locations-content-type" [
  version_number: int@version-number-completer
  locations: string
  content_type: string@content-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-alternatives: int # Number of alternative routes to be calculated. (default: 0)
  --alternative-type: string@alternative-type-completer # Determines whether the alternative routes to be calculated should be better with respect to the planning criteria provided than the reference route. (default: anyRoute)
  --min-deviation-distance: int # All alternative routes will follow the reference route for the specified minimum number of meters starting from the origin point. (default: 0)
  --min-deviation-time: int # All alternative routes will follow the reference route for the specified minimum number of seconds starting from the origin point. (default: 0)
  --instructions-type: string@instructions-type-completer # If specified, guidance instructions will be returned (if available).
  --language: string # The language parameter determines the language of the guidance messages. (default: en-GB)
  --compute-best-order: oneof<nothing, bool> # Re-order the route waypoints to reduce the route length. (default: false)
  --route-representation: string@route-representation-completer # Specifies the representation of the set of routes provided as a response. (default: polyline)
  --compute-travel-time-for: string@compute-travel-time-for-completer # Specifies whether to return additional travel times using different types of traffic information (none, historic, live) as well as the default best-estimate travel time. (default: none)
  --vehicle-heading: int # The directional heading of the vehicle in degrees. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.).
  --section-type: string # Specifies which section types are explicitly reported in the route response. Can be specified multiple times. - carTrain, ferry, tunnel or motorway - pedestrian - tollRoad - tollVignette - country - travelMode - traffic (default: travelMode)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools - alreadyUsedRoads (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion)
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
]: nothing -> any {
  http-request {
    method: get
    path: "/routing/{versionNumber}/calculateRoute/{locations}/{contentType}"
    path_params: [{name: versionNumber, var: version_number}, {name: locations, var: locations}, {name: contentType, var: content_type}]
    query: [{name: maxAlternatives, var: max_alternatives}, {name: alternativeType, var: alternative_type}, {name: minDeviationDistance, var: min_deviation_distance}, {name: minDeviationTime, var: min_deviation_time}, {name: instructionsType, var: instructions_type}, {name: language, var: language}, {name: computeBestOrder, var: compute_best_order}, {name: routeRepresentation, var: route_representation}, {name: computeTravelTimeFor, var: compute_travel_time_for}, {name: vehicleHeading, var: vehicle_heading}, {name: sectionType, var: section_type}, {name: callback, var: callback}, {name: report, var: report}, {name: departAt, var: depart_at}, {name: arriveAt, var: arrive_at}, {name: routeType, var: route_type}, {name: traffic, var: traffic}, {name: avoid, var: avoid}, {name: travelMode, var: travel_mode}, {name: hilliness, var: hilliness}, {name: windingness, var: windingness}, {name: vehicleMaxSpeed, var: vehicle_max_speed}, {name: vehicleWeight, var: vehicle_weight}, {name: vehicleAxleWeight, var: vehicle_axle_weight}, {name: vehicleLength, var: vehicle_length}, {name: vehicleWidth, var: vehicle_width}, {name: vehicleHeight, var: vehicle_height}, {name: vehicleCommercial, var: vehicle_commercial}, {name: vehicleLoadType, var: vehicle_load_type}, {name: vehicleEngineType, var: vehicle_engine_type}, {name: constantSpeedConsumptionInLitersPerHundredkm, var: constant_speed_consumption_in_liters_per_hundredkm}, {name: currentFuelInLiters, var: current_fuel_in_liters}, {name: auxiliaryPowerInLitersPerHour, var: auxiliary_power_in_liters_per_hour}, {name: fuelEnergyDensityInMJoulesPerLiter, var: fuel_energy_density_in_m_joules_per_liter}, {name: accelerationEfficiency, var: acceleration_efficiency}, {name: decelerationEfficiency, var: deceleration_efficiency}, {name: uphillEfficiency, var: uphill_efficiency}, {name: downhillEfficiency, var: downhill_efficiency}, {name: constantSpeedConsumptionInkWhPerHundredkm, var: constant_speed_consumption_ink_wh_per_hundredkm}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, locations: $locations, content_type: $content_type, max_alternatives: $max_alternatives, alternative_type: $alternative_type, min_deviation_distance: $min_deviation_distance, min_deviation_time: $min_deviation_time, instructions_type: $instructions_type, language: $language, compute_best_order: $compute_best_order, route_representation: $route_representation, compute_travel_time_for: $compute_travel_time_for, vehicle_heading: $vehicle_heading, section_type: $section_type, callback: $callback, report: $report, depart_at: $depart_at, arrive_at: $arrive_at, route_type: $route_type, traffic: $traffic, avoid: $avoid, travel_mode: $travel_mode, hilliness: $hilliness, windingness: $windingness, vehicle_max_speed: $vehicle_max_speed, vehicle_weight: $vehicle_weight, vehicle_axle_weight: $vehicle_axle_weight, vehicle_length: $vehicle_length, vehicle_width: $vehicle_width, vehicle_height: $vehicle_height, vehicle_commercial: $vehicle_commercial, vehicle_load_type: $vehicle_load_type, vehicle_engine_type: $vehicle_engine_type, constant_speed_consumption_in_liters_per_hundredkm: $constant_speed_consumption_in_liters_per_hundredkm, current_fuel_in_liters: $current_fuel_in_liters, auxiliary_power_in_liters_per_hour: $auxiliary_power_in_liters_per_hour, fuel_energy_density_in_m_joules_per_liter: $fuel_energy_density_in_m_joules_per_liter, acceleration_efficiency: $acceleration_efficiency, deceleration_efficiency: $deceleration_efficiency, uphill_efficiency: $uphill_efficiency, downhill_efficiency: $downhill_efficiency, constant_speed_consumption_ink_wh_per_hundredkm: $constant_speed_consumption_ink_wh_per_hundredkm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Route
#
# POST /routing/{versionNumber}/calculateRoute/{locations}/{contentType}
export def "post-routing-version-number-calculate-route-locations-content-type" [
  version_number: int@version-number-completer
  locations: string
  content_type: string@content-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-alternatives: int # Number of alternative routes to be calculated. (default: 0)
  --alternative-type: string@alternative-type-completer # Determines whether the alternative routes to be calculated should be better with respect to the planning criteria provided than the reference route. (default: anyRoute)
  --min-deviation-distance: int # All alternative routes will follow the reference route for the specified minimum number of meters starting from the origin point. (default: 0)
  --min-deviation-time: int # All alternative routes will follow the reference route for the specified minimum number of seconds starting from the origin point. (default: 0)
  --instructions-type: string@instructions-type-completer # If specified, guidance instructions will be returned (if available).
  --language: string # The language parameter determines the language of the guidance messages. (default: en-GB)
  --compute-best-order: oneof<nothing, bool> # Re-order the route waypoints to reduce the route length. (default: false)
  --route-representation: string@route-representation-completer # Specifies the representation of the set of routes provided as a response. (default: polyline)
  --compute-travel-time-for: string@compute-travel-time-for-completer # Specifies whether to return additional travel times using different types of traffic information (none, historic, live) as well as the default best-estimate travel time. (default: none)
  --vehicle-heading: int # The directional heading of the vehicle in degrees. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.).
  --section-type: string # Specifies which section types are explicitly reported in the route response. Can be specified multiple times. - carTrain, ferry, tunnel or motorway - pedestrian - tollRoad - tollVignette - country - travelMode - traffic (default: travelMode)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools - alreadyUsedRoads (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion)
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --allow-vignette: list<string>
  --avoid-areas: record # shape: {rectangles?: list}
  --avoid-vignette: list<string>
  --supporting-points: list # item shape: {latitude?: string, longitude?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/routing/{versionNumber}/calculateRoute/{locations}/{contentType}"
    path_params: [{name: versionNumber, var: version_number}, {name: locations, var: locations}, {name: contentType, var: content_type}]
    query: [{name: maxAlternatives, var: max_alternatives}, {name: alternativeType, var: alternative_type}, {name: minDeviationDistance, var: min_deviation_distance}, {name: minDeviationTime, var: min_deviation_time}, {name: instructionsType, var: instructions_type}, {name: language, var: language}, {name: computeBestOrder, var: compute_best_order}, {name: routeRepresentation, var: route_representation}, {name: computeTravelTimeFor, var: compute_travel_time_for}, {name: vehicleHeading, var: vehicle_heading}, {name: sectionType, var: section_type}, {name: callback, var: callback}, {name: report, var: report}, {name: departAt, var: depart_at}, {name: arriveAt, var: arrive_at}, {name: routeType, var: route_type}, {name: traffic, var: traffic}, {name: avoid, var: avoid}, {name: travelMode, var: travel_mode}, {name: hilliness, var: hilliness}, {name: windingness, var: windingness}, {name: vehicleMaxSpeed, var: vehicle_max_speed}, {name: vehicleWeight, var: vehicle_weight}, {name: vehicleAxleWeight, var: vehicle_axle_weight}, {name: vehicleLength, var: vehicle_length}, {name: vehicleWidth, var: vehicle_width}, {name: vehicleHeight, var: vehicle_height}, {name: vehicleCommercial, var: vehicle_commercial}, {name: vehicleLoadType, var: vehicle_load_type}, {name: vehicleEngineType, var: vehicle_engine_type}, {name: constantSpeedConsumptionInLitersPerHundredkm, var: constant_speed_consumption_in_liters_per_hundredkm}, {name: currentFuelInLiters, var: current_fuel_in_liters}, {name: auxiliaryPowerInLitersPerHour, var: auxiliary_power_in_liters_per_hour}, {name: fuelEnergyDensityInMJoulesPerLiter, var: fuel_energy_density_in_m_joules_per_liter}, {name: accelerationEfficiency, var: acceleration_efficiency}, {name: decelerationEfficiency, var: deceleration_efficiency}, {name: uphillEfficiency, var: uphill_efficiency}, {name: downhillEfficiency, var: downhill_efficiency}, {name: constantSpeedConsumptionInkWhPerHundredkm, var: constant_speed_consumption_ink_wh_per_hundredkm}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowVignette, var: allow_vignette}, {name: avoidAreas, var: avoid_areas}, {name: avoidVignette, var: avoid_vignette}, {name: supportingPoints, var: supporting_points}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, locations: $locations, content_type: $content_type, max_alternatives: $max_alternatives, alternative_type: $alternative_type, min_deviation_distance: $min_deviation_distance, min_deviation_time: $min_deviation_time, instructions_type: $instructions_type, language: $language, compute_best_order: $compute_best_order, route_representation: $route_representation, compute_travel_time_for: $compute_travel_time_for, vehicle_heading: $vehicle_heading, section_type: $section_type, callback: $callback, report: $report, depart_at: $depart_at, arrive_at: $arrive_at, route_type: $route_type, traffic: $traffic, avoid: $avoid, travel_mode: $travel_mode, hilliness: $hilliness, windingness: $windingness, vehicle_max_speed: $vehicle_max_speed, vehicle_weight: $vehicle_weight, vehicle_axle_weight: $vehicle_axle_weight, vehicle_length: $vehicle_length, vehicle_width: $vehicle_width, vehicle_height: $vehicle_height, vehicle_commercial: $vehicle_commercial, vehicle_load_type: $vehicle_load_type, vehicle_engine_type: $vehicle_engine_type, constant_speed_consumption_in_liters_per_hundredkm: $constant_speed_consumption_in_liters_per_hundredkm, current_fuel_in_liters: $current_fuel_in_liters, auxiliary_power_in_liters_per_hour: $auxiliary_power_in_liters_per_hour, fuel_energy_density_in_m_joules_per_liter: $fuel_energy_density_in_m_joules_per_liter, acceleration_efficiency: $acceleration_efficiency, deceleration_efficiency: $deceleration_efficiency, uphill_efficiency: $uphill_efficiency, downhill_efficiency: $downhill_efficiency, constant_speed_consumption_ink_wh_per_hundredkm: $constant_speed_consumption_ink_wh_per_hundredkm, allow_vignette: $allow_vignette, avoid_areas: $avoid_areas, avoid_vignette: $avoid_vignette, supporting_points: $supporting_points
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
