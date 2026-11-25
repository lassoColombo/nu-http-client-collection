# Auto-generated client for Amazon FSx v2018-03-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/fsx/2018-03-01/openapi.json
# Auth: --token flag or $env.AMAZON_FSX_TOKEN

const CLIENT = {
  base_url: "http://fsx.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_FSX_TOKEN"
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

def base-url-completer [] { ["http://fsx.us-east-1.amazonaws.com" "http://fsx.us-east-2.amazonaws.com" "http://fsx.us-west-1.amazonaws.com" "http://fsx.us-west-2.amazonaws.com" "http://fsx.us-gov-west-1.amazonaws.com" "http://fsx.us-gov-east-1.amazonaws.com" "http://fsx.ca-central-1.amazonaws.com" "http://fsx.eu-north-1.amazonaws.com" "http://fsx.eu-west-1.amazonaws.com" "http://fsx.eu-west-2.amazonaws.com" "http://fsx.eu-west-3.amazonaws.com" "http://fsx.eu-central-1.amazonaws.com" "http://fsx.eu-south-1.amazonaws.com" "http://fsx.af-south-1.amazonaws.com" "http://fsx.ap-northeast-1.amazonaws.com" "http://fsx.ap-northeast-2.amazonaws.com" "http://fsx.ap-northeast-3.amazonaws.com" "http://fsx.ap-southeast-1.amazonaws.com" "http://fsx.ap-southeast-2.amazonaws.com" "http://fsx.ap-east-1.amazonaws.com" "http://fsx.ap-south-1.amazonaws.com" "http://fsx.sa-east-1.amazonaws.com" "http://fsx.me-south-1.amazonaws.com" "https://fsx.us-east-1.amazonaws.com" "https://fsx.us-east-2.amazonaws.com" "https://fsx.us-west-1.amazonaws.com" "https://fsx.us-west-2.amazonaws.com" "https://fsx.us-gov-west-1.amazonaws.com" "https://fsx.us-gov-east-1.amazonaws.com" "https://fsx.ca-central-1.amazonaws.com" "https://fsx.eu-north-1.amazonaws.com" "https://fsx.eu-west-1.amazonaws.com" "https://fsx.eu-west-2.amazonaws.com" "https://fsx.eu-west-3.amazonaws.com" "https://fsx.eu-central-1.amazonaws.com" "https://fsx.eu-south-1.amazonaws.com" "https://fsx.af-south-1.amazonaws.com" "https://fsx.ap-northeast-1.amazonaws.com" "https://fsx.ap-northeast-2.amazonaws.com" "https://fsx.ap-northeast-3.amazonaws.com" "https://fsx.ap-southeast-1.amazonaws.com" "https://fsx.ap-southeast-2.amazonaws.com" "https://fsx.ap-east-1.amazonaws.com" "https://fsx.ap-south-1.amazonaws.com" "https://fsx.sa-east-1.amazonaws.com" "https://fsx.me-south-1.amazonaws.com" "http://fsx.cn-north-1.amazonaws.com.cn" "http://fsx.cn-northwest-1.amazonaws.com.cn" "https://fsx.cn-north-1.amazonaws.com.cn" "https://fsx.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSSimbaAPIService_v20180301.AssociateFileSystemAliases"] }
def x-amz-target-completer-1 [] { ["AWSSimbaAPIService_v20180301.CancelDataRepositoryTask"] }
def x-amz-target-completer-2 [] { ["AWSSimbaAPIService_v20180301.CopyBackup"] }
def x-amz-target-completer-3 [] { ["AWSSimbaAPIService_v20180301.CreateBackup"] }
def x-amz-target-completer-4 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation"] }
def type-completer [] { ["AUTO_RELEASE_DATA" "EXPORT_TO_REPOSITORY" "IMPORT_METADATA_FROM_REPOSITORY" "RELEASE_DATA_FROM_FILESYSTEM"] }
def x-amz-target-completer-5 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryTask"] }
def file-cache-type-completer [] { ["LUSTRE"] }
def x-amz-target-completer-6 [] { ["AWSSimbaAPIService_v20180301.CreateFileCache"] }
def file-system-type-completer [] { ["LUSTRE" "ONTAP" "OPENZFS" "WINDOWS"] }
def storage-type-completer [] { ["HDD" "SSD"] }
def x-amz-target-completer-7 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystem"] }
def x-amz-target-completer-8 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"] }
def x-amz-target-completer-9 [] { ["AWSSimbaAPIService_v20180301.CreateSnapshot"] }
def root-volume-security-style-completer [] { ["MIXED" "NTFS" "UNIX"] }
def x-amz-target-completer-10 [] { ["AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine"] }
def volume-type-completer [] { ["ONTAP" "OPENZFS"] }
def x-amz-target-completer-11 [] { ["AWSSimbaAPIService_v20180301.CreateVolume"] }
def x-amz-target-completer-12 [] { ["AWSSimbaAPIService_v20180301.CreateVolumeFromBackup"] }
def x-amz-target-completer-13 [] { ["AWSSimbaAPIService_v20180301.DeleteBackup"] }
def x-amz-target-completer-14 [] { ["AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation"] }
def x-amz-target-completer-15 [] { ["AWSSimbaAPIService_v20180301.DeleteFileCache"] }
def x-amz-target-completer-16 [] { ["AWSSimbaAPIService_v20180301.DeleteFileSystem"] }
def x-amz-target-completer-17 [] { ["AWSSimbaAPIService_v20180301.DeleteSnapshot"] }
def x-amz-target-completer-18 [] { ["AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine"] }
def x-amz-target-completer-19 [] { ["AWSSimbaAPIService_v20180301.DeleteVolume"] }
def x-amz-target-completer-20 [] { ["AWSSimbaAPIService_v20180301.DescribeBackups"] }
def x-amz-target-completer-21 [] { ["AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations"] }
def x-amz-target-completer-22 [] { ["AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks"] }
def x-amz-target-completer-23 [] { ["AWSSimbaAPIService_v20180301.DescribeFileCaches"] }
def x-amz-target-completer-24 [] { ["AWSSimbaAPIService_v20180301.DescribeFileSystemAliases"] }
def x-amz-target-completer-25 [] { ["AWSSimbaAPIService_v20180301.DescribeFileSystems"] }
def x-amz-target-completer-26 [] { ["AWSSimbaAPIService_v20180301.DescribeSnapshots"] }
def x-amz-target-completer-27 [] { ["AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines"] }
def x-amz-target-completer-28 [] { ["AWSSimbaAPIService_v20180301.DescribeVolumes"] }
def x-amz-target-completer-29 [] { ["AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases"] }
def x-amz-target-completer-30 [] { ["AWSSimbaAPIService_v20180301.ListTagsForResource"] }
def x-amz-target-completer-31 [] { ["AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks"] }
def x-amz-target-completer-32 [] { ["AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot"] }
def x-amz-target-completer-33 [] { ["AWSSimbaAPIService_v20180301.TagResource"] }
def x-amz-target-completer-34 [] { ["AWSSimbaAPIService_v20180301.UntagResource"] }
def x-amz-target-completer-35 [] { ["AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation"] }
def x-amz-target-completer-36 [] { ["AWSSimbaAPIService_v20180301.UpdateFileCache"] }
def x-amz-target-completer-37 [] { ["AWSSimbaAPIService_v20180301.UpdateFileSystem"] }
def x-amz-target-completer-38 [] { ["AWSSimbaAPIService_v20180301.UpdateSnapshot"] }
def x-amz-target-completer-39 [] { ["AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine"] }
def x-amz-target-completer-40 [] { ["AWSSimbaAPIService_v20180301.UpdateVolume"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-file-system-aliases: "record<Aliases: table<Name: string, Lifecycle: string>>"
    cancel-data-repository-task: "record<Lifecycle: string, TaskId: string>"
    copy-backup: "record<Backup: record<BackupId: string, Lifecycle: string, FailureDetails: record<Message: string>, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: string, ActiveDirectoryId: string, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>>>"
    create-backup: "record<Backup: record<BackupId: string, Lifecycle: string, FailureDetails: record<Message: string>, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: string, ActiveDirectoryId: string, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>>>"
    create-data-repository-association: "record<Association: record<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record<Message: string>, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list<string>, NFS: record<Version: string, DnsIps: list, AutoExportPolicy: record>>>"
    create-data-repository-task: "record<DataRepositoryTask: record<TaskId: string, Lifecycle: string, Type: string, CreationTime: string, StartTime: string, EndTime: string, ResourceARN: string, Tags: list<record>, FileSystemId: string, Paths: list<string>, FailureDetails: record<Message: string>, Status: record<TotalCount: int, SucceededCount: int, FailedCount: int, LastUpdatedTime: string, ReleasedCapacity: int>, Report: record<Enabled: bool, Path: string, Format: string, Scope: string>, CapacityToRelease: int, FileCacheId: string>>"
    create-file-cache: "record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, CopyTagsToDataRepositoryAssociations: bool, LustreConfiguration: record<PerUnitStorageThroughput: int, DeploymentType: string, MountName: string, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: list<string>>>"
    create-file-system: "record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>"
    create-file-system-from-backup: "record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>"
    create-snapshot: "record<Snapshot: record<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: list<record>>>"
    create-storage-virtual-machine: "record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: string, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: string>>"
    create-volume: "record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>"
    create-volume-from-backup: "record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>"
    delete-backup: "record<BackupId: string, Lifecycle: string>"
    delete-data-repository-association: "record<AssociationId: string, Lifecycle: string, DeleteDataInFileSystem: bool>"
    delete-file-cache: "record<FileCacheId: string, Lifecycle: string>"
    delete-file-system: "record<FileSystemId: string, Lifecycle: string, WindowsResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>, LustreResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>, OpenZFSResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>>"
    delete-snapshot: "record<SnapshotId: string, Lifecycle: string>"
    delete-storage-virtual-machine: "record<StorageVirtualMachineId: string, Lifecycle: string>"
    delete-volume: "record<VolumeId: string, Lifecycle: string, OntapResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>>"
    describe-backups: "record<Backups: table<BackupId: string, Lifecycle: string, FailureDetails: record, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list, FileSystem: record, DirectoryInformation: record, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record>, NextToken: string>"
    describe-data-repository-associations: "record<Associations: table<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record, Tags: list, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list, NFS: record>, NextToken: string>"
    describe-data-repository-tasks: "record<DataRepositoryTasks: table<TaskId: string, Lifecycle: string, Type: string, CreationTime: string, StartTime: string, EndTime: string, ResourceARN: string, Tags: list, FileSystemId: string, Paths: list, FailureDetails: record, Status: record, Report: record, CapacityToRelease: int, FileCacheId: string>, NextToken: string>"
    describe-file-caches: "record<FileCaches: table<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, LustreConfiguration: record, DataRepositoryAssociationIds: list>, NextToken: string>"
    describe-file-system-aliases: "record<Aliases: table<Name: string, Lifecycle: string>, NextToken: string>"
    describe-file-systems: "record<FileSystems: table<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, NextToken: string>"
    describe-snapshots: "record<Snapshots: table<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record, Tags: list, AdministrativeActions: list>, NextToken: string>"
    describe-storage-virtual-machines: "record<StorageVirtualMachines: table<ActiveDirectoryConfiguration: record, CreationTime: string, Endpoints: record, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list, LifecycleTransitionReason: record, RootVolumeSecurityStyle: string>, NextToken: string>"
    describe-volumes: "record<Volumes: table<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>, NextToken: string>"
    disassociate-file-system-aliases: "record<Aliases: table<Name: string, Lifecycle: string>>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>, NextToken: string>"
    release-file-system-nfs-v3-locks: "record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>"
    restore-volume-from-snapshot: "record<VolumeId: string, Lifecycle: string, AdministrativeActions: table<AdministrativeActionType: string, ProgressPercent: int, RequestTime: string, Status: string, TargetFileSystemValues: record, FailureDetails: record, TargetVolumeValues: record, TargetSnapshotValues: record>>"
    tag-resource: "record"
    untag-resource: "record"
    update-data-repository-association: "record<Association: record<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record<Message: string>, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list<string>, NFS: record<Version: string, DnsIps: list, AutoExportPolicy: record>>>"
    update-file-cache: "record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, LustreConfiguration: record<PerUnitStorageThroughput: int, DeploymentType: string, MountName: string, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: list<string>>>"
    update-file-system: "record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>"
    update-snapshot: "record<Snapshot: record<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: list<record>>>"
    update-storage-virtual-machine: "record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: string, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: string>>"
    update-volume: "record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-file-system-aliases" "cancel-data-repository-task" "copy-backup" "create-backup" "create-data-repository-association" "create-data-repository-task" "create-file-cache" "create-file-system" "create-file-system-from-backup" "create-snapshot" "create-storage-virtual-machine" "create-volume" "create-volume-from-backup" "delete-backup" "delete-data-repository-association" "delete-file-cache" "delete-file-system" "delete-snapshot" "delete-storage-virtual-machine" "delete-volume" "describe-backups" "describe-data-repository-associations" "describe-data-repository-tasks" "describe-file-caches" "describe-file-system-aliases" "describe-file-systems" "describe-snapshots" "describe-storage-virtual-machines" "describe-volumes" "disassociate-file-system-aliases" "list-tags-for-resource" "release-file-system-nfs-v3-locks" "restore-volume-from-snapshot" "tag-resource" "untag-resource" "update-data-repository-association" "update-file-cache" "update-file-system" "update-snapshot" "update-storage-virtual-machine" "update-volume" "commands"] | sort) } | get name | first)
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

# Use this action to associate one or more Domain Name Server (DNS) aliases with an existing Amazon FSx for Windows File Server file system. A file system can have a maximum of 50 DNS aliases associated with it at any one time. If you try to associate a DNS alias that is already associated with the file system, FSx takes no action on that alias in the request. For more information, see Working with DNS Aliases (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/managing-dns-aliases.html) and Walkthrough 5: Using DNS aliases to access your file system (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/walkthrough05-file-system-custom-CNAME.html), including additional steps you must take to be able to access your file system using a DNS alias. The system response shows the DNS aliases that Amazon FSx is attempting to associate with the file system. Use the API operation to monitor the status of the aliases Amazon FSx is associating with the file system.
#
# POST /
# Returns: record<Aliases: table<Name: string, Lifecycle: string>>
# operationId: AssociateFileSystemAliases
export def "associate-file-system-aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  aliases: list<string> # An array of one or more DNS alias names to associate with the file system. The alias name has to comply with the following formatting requirements: Formatted as a fully-qualified domain name (FQDN), hostname.domain , for example, accounting.corp.example.com. Can contain alphanumeric characters and the hyphen (-). Cannot start or end with a hyphen. Can start with a numeric. For DNS alias names, Amazon FSx stores alphabetic characters as lowercase letters (a-z), regardless of how you specify them: as uppercase letters, lowercase letters, or the corresponding letters in escape codes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.AssociateFileSystemAliases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: FileSystemId, var: file_system_id}, {name: Aliases, var: aliases}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, file_system_id: $file_system_id, aliases: $aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the PENDING or EXECUTING state. When you cancel a task, Amazon FSx does the following. Any files that FSx has already exported are not reverted. FSx continues to export any files that are "in-flight" when the cancel operation is received. FSx does not export any files that have not yet been exported.
#
# POST /
# Returns: record<Lifecycle: string, TaskId: string>
# operationId: CancelDataRepositoryTask
export def "cancel-data-repository-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  task_id: string # Specifies the data repository task to cancel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CancelDataRepositoryTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskId, var: task_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies an existing backup within the same Amazon Web Services account to another Amazon Web Services Region (cross-Region copy) or within the same Amazon Web Services Region (in-Region copy). You can have up to five backup copy requests in progress to a single destination Region per account. You can use cross-Region backup copies for cross-Region disaster recovery. You can periodically take backups and copy them to another Region so that in the event of a disaster in the primary Region, you can restore from backup and recover availability quickly in the other Region. You can make cross-Region copies only within your Amazon Web Services partition. A partition is a grouping of Regions. Amazon Web Services currently has three partitions: aws (Standard Regions), aws-cn (China Regions), and aws-us-gov (Amazon Web Services GovCloud [US] Regions). You can also use backup copies to clone your file dataset to another Region or within the same Region. You can use the SourceRegion parameter to specify the Amazon Web Services Region from which the backup will be copied. For example, if you make the call from the us-west-1 Region and want to copy a backup from the us-east-2 Region, you specify us-east-2 in the SourceRegion parameter to make a cross-Region copy. If you don't specify a Region, the backup copy is created in the same Region where the request is sent from (in-Region copy). For more information about creating backup copies, see Copying backups (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html#copy-backups) in the Amazon FSx for Windows User Guide, Copying backups (https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html#copy-backups) in the Amazon FSx for Lustre User Guide, and Copying backups (https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html#copy-backups) in the Amazon FSx for OpenZFS User Guide.
#
# POST /
# Returns: record<Backup: record<BackupId: string, Lifecycle: string, FailureDetails: record<Message: string>, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: string, ActiveDirectoryId: string, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>>>
# operationId: CopyBackup
export def "copy-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  source_backup_id: string # The ID of the source backup. Specifies the ID of the backup that's being copied.
  --source-region: string # The source Amazon Web Services Region of the backup. Specifies the Amazon Web Services Region from which the backup is being copied. The source and destination Regions must be in the same Amazon Web Services partition. If you don't specify a Region, SourceRegion defaults to the Region where the request is sent from (in-Region copy).
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --copy-tags: oneof<nothing, bool> # A Boolean flag indicating whether tags from the source backup should be copied to the backup copy. This value defaults to false. If you set CopyTags to true and the source backup has existing tags, you can use the Tags parameter to create new tags, provided that the sum of the source backup tags and the new tags doesn't exceed 50. Both sets of tags are merged. If there are tag conflicts (for example, two tags with the same key but different values), the tags created with the Tags parameter take precedence.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CopyBackup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: SourceBackupId, var: source_backup_id}, {name: SourceRegion, var: source_region}, {name: KmsKeyId, var: kms_key_id}, {name: CopyTags, var: copy_tags}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, source_backup_id: $source_backup_id, source_region: $source_region, kms_key_id: $kms_key_id, copy_tags: $copy_tags, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a backup of an existing Amazon FSx for Windows File Server file system, Amazon FSx for Lustre file system, Amazon FSx for NetApp ONTAP volume, or Amazon FSx for OpenZFS file system. We recommend creating regular backups so that you can restore a file system or volume from a backup if an issue arises with the original file system or volume. For Amazon FSx for Lustre file systems, you can create a backup only for file systems that have the following configuration: A Persistent deployment type Are not linked to a data repository For more information about backups, see the following: For Amazon FSx for Lustre, see Working with FSx for Lustre backups (https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html). For Amazon FSx for Windows, see Working with FSx for Windows backups (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html). For Amazon FSx for NetApp ONTAP, see Working with FSx for NetApp ONTAP backups (https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/using-backups.html). For Amazon FSx for OpenZFS, see Working with FSx for OpenZFS backups (https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html). If a backup with the specified client request token exists and the parameters match, this operation returns the description of the existing backup. If a backup with the specified client request token exists and the parameters don't match, this operation returns IncompatibleParameterError. If a backup with the specified client request token doesn't exist, CreateBackup does the following: Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the backup. By using the idempotent operation, you can retry a CreateBackup operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same. The CreateBackup operation returns while the backup's lifecycle state is still CREATING. You can check the backup creation status by calling the DescribeBackups (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeBackups.html) operation, which returns the backup state along with other information.
#
# POST /
# Returns: record<Backup: record<BackupId: string, Lifecycle: string, FailureDetails: record<Message: string>, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: string, ActiveDirectoryId: string, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>>>
# operationId: CreateBackup
export def "create-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --file-system-id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --volume-id: string # (Optional) The ID of the FSx for ONTAP volume to back up.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateBackup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemId, var: file_system_id}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}, {name: VolumeId, var: volume_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_id: $file_system_id, client_request_token: $client_request_token, tags: $tags, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon FSx for Lustre data repository association (DRA). A data repository association is a link between a directory on the file system and an Amazon S3 bucket or prefix. You can have a maximum of 8 data repository associations on a file system. Data repository associations are supported for all file systems except for Scratch_1 deployment type. Each data repository association must have a unique Amazon FSx file system directory and a unique S3 bucket or prefix associated with it. You can configure a data repository association for automatic import only, for automatic export only, or for both. To learn more about linking a data repository to your file system, see Linking your file system to an S3 bucket (https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html). CreateDataRepositoryAssociation isn't supported on Amazon File Cache resources. To create a DRA on Amazon File Cache, use the CreateFileCache operation.
#
# POST /
# Returns: record<Association: record<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record<Message: string>, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list<string>, NFS: record<Version: string, DnsIps: list, AutoExportPolicy: record>>>
# operationId: CreateDataRepositoryAssociation
export def "create-data-repository-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --file-system-path: string # A path on the file system that points to a high-level directory (such as /ns1/) or subdirectory (such as /ns1/subdir/) that will be mapped 1-1 with DataRepositoryPath. The leading forward slash in the name is required. Two data repository associations cannot have overlapping file system paths. For example, if a data repository is associated with file system path /ns1/, then you cannot link another data repository with file system path /ns1/ns2. This path specifies where in your file system files will be exported from or imported to. This file system directory can be linked to only one Amazon S3 bucket, and no other S3 bucket can be linked to the directory. If you specify only a forward slash (/) as the file system path, you can link only one data repository to the file system. You can only specify "/" as the file system path for the first data repository associated with a file system.
  data_repository_path: string # The path to the Amazon S3 data repository that will be linked to the file system. The path can be an S3 bucket or prefix in the format s3://myBucket/myPrefix/. This path specifies where in the S3 data repository files will be imported from or exported to.
  --batch-import-meta-data-on-create: oneof<nothing, bool> # Set to true to run an import data repository task to import metadata from the data repository to the file system after the data repository association is created. Default is false.
  --imported-file-chunk-size: int # For files imported from a data repository, this value determines the stripe count and maximum amount of data per file (in MiB) stored on a single physical disk. The maximum number of disks that a single file can be striped across is limited by the total number of disks that make up the file system. The default chunk size is 1,024 MiB (1 GiB) and can go as high as 512,000 MiB (500 GiB). Amazon S3 objects have a maximum size of 5 TB.
  --s3: record # The configuration for an Amazon S3 data repository linked to an Amazon FSx for Lustre file system with a data repository association. The configuration consists of an AutoImportPolicy that defines which file events on the data repository are automatically imported to the file system and an AutoExportPolicy that defines which file events on the file system are automatically exported to the data repository. File events are when files or directories are added, changed, or deleted on the file system or the data repository. Data repository associations on Amazon File Cache don't use S3DataRepositoryConfiguration because they don't support automatic import or automatic export. — shape: {AutoImportPolicy?: record, AutoExportPolicy?: record}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemId, var: file_system_id}, {name: FileSystemPath, var: file_system_path}, {name: DataRepositoryPath, var: data_repository_path}, {name: BatchImportMetaDataOnCreate, var: batch_import_meta_data_on_create}, {name: ImportedFileChunkSize, var: imported_file_chunk_size}, {name: S3, var: s3}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_id: $file_system_id, file_system_path: $file_system_path, data_repository_path: $data_repository_path, batch_import_meta_data_on_create: $batch_import_meta_data_on_create, imported_file_chunk_size: $imported_file_chunk_size, s3: $s3, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repositories. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to a linked data repository. A CreateDataRepositoryTask operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see Data Repository Tasks (https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html). To learn more about linking a data repository to your file system, see Linking your file system to an S3 bucket (https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html).
#
# POST /
# Returns: record<DataRepositoryTask: record<TaskId: string, Lifecycle: string, Type: string, CreationTime: string, StartTime: string, EndTime: string, ResourceARN: string, Tags: list<record>, FileSystemId: string, Paths: list<string>, FailureDetails: record<Message: string>, Status: record<TotalCount: int, SucceededCount: int, FailedCount: int, LastUpdatedTime: string, ReleasedCapacity: int>, Report: record<Enabled: bool, Path: string, Format: string, Scope: string>, CapacityToRelease: int, FileCacheId: string>>
# operationId: CreateDataRepositoryTask
export def "create-data-repository-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  type: string@type-completer # Specifies the type of data repository task to create.
  --paths: list<string> # A list of paths for the data repository task to use when the task is processed. If a path that you provide isn't valid, the task fails. For export tasks, the list contains paths on the Amazon FSx file system from which the files are exported to the Amazon S3 bucket. The default path is the file system root directory. The paths you provide need to be relative to the mount point of the file system. If the mount point is /mnt/fsx and /mnt/fsx/path1 is a directory or file on the file system you want to export, then the path to provide is path1. For import tasks, the list contains paths in the Amazon S3 bucket from which POSIX metadata changes are imported to the Amazon FSx file system. The path can be an S3 bucket or prefix in the format s3://myBucket/myPrefix (where myPrefix is optional).
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  report: record # Provides a report detailing the data repository task results of the files processed that match the criteria specified in the report Scope parameter. FSx delivers the report to the file system's linked data repository in Amazon S3, using the path specified in the report Path parameter. You can specify whether or not a report gets generated for a task using the Enabled parameter. — shape: {Enabled: bool, Path?: string, Format?: "REPORT_CSV_20191124", Scope?: "FAILED_FILES_ONLY"}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --capacity-to-release: int # Specifies the amount of data to release, in GiB, by an Amazon File Cache AUTO_RELEASE_DATA task that automatically releases files from the cache.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateDataRepositoryTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Type, var: type}, {name: Paths, var: paths}, {name: FileSystemId, var: file_system_id}, {name: Report, var: report}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}, {name: CapacityToRelease, var: capacity_to_release}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, type: $type, paths: $paths, file_system_id: $file_system_id, report: $report, client_request_token: $client_request_token, tags: $tags, capacity_to_release: $capacity_to_release
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon File Cache resource. You can use this operation with a client request token in the request that Amazon File Cache uses to ensure idempotent creation. If a cache with the specified client request token exists and the parameters match, CreateFileCache returns the description of the existing cache. If a cache with the specified client request token exists and the parameters don't match, this call returns IncompatibleParameterError. If a file cache with the specified client request token doesn't exist, CreateFileCache does the following: Creates a new, empty Amazon File Cache resourcewith an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the cache in JSON format. The CreateFileCache call returns while the cache's lifecycle state is still CREATING. You can check the cache creation status by calling the DescribeFileCaches (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html) operation, which returns the cache state along with other information.
#
# POST /
# Returns: record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, CopyTagsToDataRepositoryAssociations: bool, LustreConfiguration: record<PerUnitStorageThroughput: int, DeploymentType: string, MountName: string, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: list<string>>>
# operationId: CreateFileCache
export def "create-file-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_cache_type: string@file-cache-type-completer # The type of cache that you're creating, which must be LUSTRE.
  file_cache_type_version: string # Sets the Lustre version for the cache that you're creating, which must be 2.12.
  storage_capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
  subnet_ids: list<string> # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the CreateFileCache operation.
  --security-group-ids: list<string> # A list of IDs specifying the security groups to apply to all network interfaces created for file system access. This list isn't returned in later requests to describe the file system.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --copy-tags-to-data-repository-associations: oneof<nothing, bool> # A boolean flag indicating whether tags for the cache should be copied to data repository associations. This value defaults to false.
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --lustre-configuration: record # The Amazon File Cache configuration for the cache that you are creating. — shape: {PerUnitStorageThroughput: int, DeploymentType: "CACHE_1", WeeklyMaintenanceStartTime?: string, MetadataConfiguration: record}
  --data-repository-associations: list # A list of up to 8 configurations for data repository associations (DRAs) to be created during the cache creation. The DRAs link the cache to either an Amazon S3 data repository or a Network File System (NFS) data repository that supports the NFSv3 protocol. The DRA configurations must meet the following requirements: All configurations on the list must be of the same data repository type, either all S3 or all NFS. A cache can't link to different data repository types at the same time. An NFS DRA must link to an NFS file system that supports the NFSv3 protocol. DRA automatic import and automatic export is not supported. — item shape: {FileCachePath: string, DataRepositoryPath: string, DataRepositorySubdirectories?: list<string>, NFS?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateFileCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: FileCacheType, var: file_cache_type}, {name: FileCacheTypeVersion, var: file_cache_type_version}, {name: StorageCapacity, var: storage_capacity}, {name: SubnetIds, var: subnet_ids}, {name: SecurityGroupIds, var: security_group_ids}, {name: Tags, var: tags}, {name: CopyTagsToDataRepositoryAssociations, var: copy_tags_to_data_repository_associations}, {name: KmsKeyId, var: kms_key_id}, {name: LustreConfiguration, var: lustre_configuration}, {name: DataRepositoryAssociations, var: data_repository_associations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, file_cache_type: $file_cache_type, file_cache_type_version: $file_cache_type_version, storage_capacity: $storage_capacity, subnet_ids: $subnet_ids, security_group_ids: $security_group_ids, tags: $tags, copy_tags_to_data_repository_associations: $copy_tags_to_data_repository_associations, kms_key_id: $kms_key_id, lustre_configuration: $lustre_configuration, data_repository_associations: $data_repository_associations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new, empty Amazon FSx file system. You can create the following supported Amazon FSx file systems using the CreateFileSystem API operation: Amazon FSx for Lustre Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a CreateFileSystem operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same. If a file system with the specified client request token exists and the parameters match, CreateFileSystem returns the description of the existing file system. If a file system with the specified client request token exists and the parameters don't match, this call returns IncompatibleParameterError. If a file system with the specified client request token doesn't exist, CreateFileSystem does the following: Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the file system in JSON format. The CreateFileSystem call returns while the file system's lifecycle state is still CREATING. You can check the file-system creation status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns the file system state along with other information.
#
# POST /
# Returns: record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>
# operationId: CreateFileSystem
export def "create-file-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_type: string@file-system-type-completer # The type of file system.
  storage_capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
  --storage-type: string@storage-type-completer # The storage type for your Amazon FSx file system.
  subnet_ids: list<string> # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the CreateFileCache operation.
  --security-group-ids: list<string> # A list of IDs specifying the security groups to apply to all network interfaces created for file system access. This list isn't returned in later requests to describe the file system.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --windows-configuration: record # The configuration object for the Microsoft Windows file system used in CreateFileSystem and CreateFileSystemFromBackup operations. — shape: {ActiveDirectoryId?: string, SelfManagedActiveDirectoryConfiguration?: record, DeploymentType?: "MULTI_AZ_1"|"SINGLE_AZ_1"|"SINGLE_AZ_2", PreferredSubnetId?: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, Aliases?: list<string>, AuditLogConfiguration?: record}
  --lustre-configuration: record # The Lustre configuration for the file system being created. The following parameters are not supported for file systems with a data repository association created with . AutoImportPolicy ExportPath ImportedChunkSize ImportPath — shape: {WeeklyMaintenanceStartTime?: string, ImportPath?: string, ExportPath?: string, ImportedFileChunkSize?: int, DeploymentType?: "SCRATCH_1"|"SCRATCH_2"|"PERSISTENT_1"|"PERSISTENT_2", AutoImportPolicy?: "NONE"|"NEW"|"NEW_CHANGED"|"NEW_CHANGED_DELETED", PerUnitStorageThroughput?: int, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, DriveCacheType?: "NONE"|"READ", DataCompressionType?: "NONE"|"LZ4", LogConfiguration?: record, ... (1 more fields)}
  --ontap-configuration: record # The ONTAP configuration properties of the FSx for ONTAP file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, DeploymentType: "MULTI_AZ_1"|"SINGLE_AZ_1", EndpointIpAddressRange?: string, FsxAdminPassword?: string, DiskIopsConfiguration?: record, PreferredSubnetId?: string, RouteTableIds?: list<string>, ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string}
  --file-system-type-version: string # (Optional) For FSx for Lustre file systems, sets the Lustre version for the file system that you're creating. Valid values are 2.10 and 2.12: 2.10 is supported by the Scratch and Persistent_1 Lustre deployment types. 2.12 is supported by all Lustre deployment types. 2.12 is required when setting FSx for Lustre DeploymentType to PERSISTENT_2. Default value = 2.10, except when DeploymentType is set to PERSISTENT_2, then the default is 2.12. If you set FileSystemTypeVersion to 2.10 for a PERSISTENT_2 Lustre deployment type, the CreateFileSystem operation fails.
  --open-zfs-configuration: record # The Amazon FSx for OpenZFS configuration properties for the file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, CopyTagsToVolumes?: bool, DailyAutomaticBackupStartTime?: string, DeploymentType: "SINGLE_AZ_1"|"SINGLE_AZ_2", ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record, RootVolumeConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateFileSystem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: FileSystemType, var: file_system_type}, {name: StorageCapacity, var: storage_capacity}, {name: StorageType, var: storage_type}, {name: SubnetIds, var: subnet_ids}, {name: SecurityGroupIds, var: security_group_ids}, {name: Tags, var: tags}, {name: KmsKeyId, var: kms_key_id}, {name: WindowsConfiguration, var: windows_configuration}, {name: LustreConfiguration, var: lustre_configuration}, {name: OntapConfiguration, var: ontap_configuration}, {name: FileSystemTypeVersion, var: file_system_type_version}, {name: OpenZFSConfiguration, var: open_zfs_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, file_system_type: $file_system_type, storage_capacity: $storage_capacity, storage_type: $storage_type, subnet_ids: $subnet_ids, security_group_ids: $security_group_ids, tags: $tags, kms_key_id: $kms_key_id, windows_configuration: $windows_configuration, lustre_configuration: $lustre_configuration, ontap_configuration: $ontap_configuration, file_system_type_version: $file_system_type_version, open_zfs_configuration: $open_zfs_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon FSx for Lustre, Amazon FSx for Windows File Server, or Amazon FSx for OpenZFS file system from an existing Amazon FSx backup. If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a file system with the specified client request token exists but the parameters don't match, this call returns IncompatibleParameterError. If a file system with the specified client request token doesn't exist, this operation does the following: Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the file system. Parameters like the Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings. By using the idempotent operation, you can retry a CreateFileSystemFromBackup call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives a success message as long as the parameters are the same. The CreateFileSystemFromBackup call returns while the file system's lifecycle state is still CREATING. You can check the file-system creation status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns the file system state along with other information.
#
# POST /
# Returns: record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>
# operationId: CreateFileSystemFromBackup
export def "create-file-system-from-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  subnet_ids: list<string> # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the CreateFileCache operation.
  --security-group-ids: list<string> # A list of IDs specifying the security groups to apply to all network interfaces created for file system access. This list isn't returned in later requests to describe the file system.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --windows-configuration: record # The configuration object for the Microsoft Windows file system used in CreateFileSystem and CreateFileSystemFromBackup operations. — shape: {ActiveDirectoryId?: string, SelfManagedActiveDirectoryConfiguration?: record, DeploymentType?: "MULTI_AZ_1"|"SINGLE_AZ_1"|"SINGLE_AZ_2", PreferredSubnetId?: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, Aliases?: list<string>, AuditLogConfiguration?: record}
  --lustre-configuration: record # The Lustre configuration for the file system being created. The following parameters are not supported for file systems with a data repository association created with . AutoImportPolicy ExportPath ImportedChunkSize ImportPath — shape: {WeeklyMaintenanceStartTime?: string, ImportPath?: string, ExportPath?: string, ImportedFileChunkSize?: int, DeploymentType?: "SCRATCH_1"|"SCRATCH_2"|"PERSISTENT_1"|"PERSISTENT_2", AutoImportPolicy?: "NONE"|"NEW"|"NEW_CHANGED"|"NEW_CHANGED_DELETED", PerUnitStorageThroughput?: int, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, DriveCacheType?: "NONE"|"READ", DataCompressionType?: "NONE"|"LZ4", LogConfiguration?: record, ... (1 more fields)}
  --storage-type: string@storage-type-completer # The storage type for your Amazon FSx file system.
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --file-system-type-version: string # Sets the version for the Amazon FSx for Lustre file system that you're creating from a backup. Valid values are 2.10 and 2.12. You don't need to specify FileSystemTypeVersion because it will be applied using the backup's FileSystemTypeVersion setting. If you choose to specify FileSystemTypeVersion when creating from backup, the value must match the backup's FileSystemTypeVersion setting.
  --open-zfs-configuration: record # The Amazon FSx for OpenZFS configuration properties for the file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, CopyTagsToVolumes?: bool, DailyAutomaticBackupStartTime?: string, DeploymentType: "SINGLE_AZ_1"|"SINGLE_AZ_2", ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record, RootVolumeConfiguration?: record}
  --storage-capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupId, var: backup_id}, {name: ClientRequestToken, var: client_request_token}, {name: SubnetIds, var: subnet_ids}, {name: SecurityGroupIds, var: security_group_ids}, {name: Tags, var: tags}, {name: WindowsConfiguration, var: windows_configuration}, {name: LustreConfiguration, var: lustre_configuration}, {name: StorageType, var: storage_type}, {name: KmsKeyId, var: kms_key_id}, {name: FileSystemTypeVersion, var: file_system_type_version}, {name: OpenZFSConfiguration, var: open_zfs_configuration}, {name: StorageCapacity, var: storage_capacity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, backup_id: $backup_id, client_request_token: $client_request_token, subnet_ids: $subnet_ids, security_group_ids: $security_group_ids, tags: $tags, windows_configuration: $windows_configuration, lustre_configuration: $lustre_configuration, storage_type: $storage_type, kms_key_id: $kms_key_id, file_system_type_version: $file_system_type_version, open_zfs_configuration: $open_zfs_configuration, storage_capacity: $storage_capacity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a snapshot of an existing Amazon FSx for OpenZFS volume. With snapshots, you can easily undo file changes and compare file versions by restoring the volume to a previous version. If a snapshot with the specified client request token exists, and the parameters match, this operation returns the description of the existing snapshot. If a snapshot with the specified client request token exists, and the parameters don't match, this operation returns IncompatibleParameterError. If a snapshot with the specified client request token doesn't exist, CreateSnapshot does the following: Creates a new OpenZFS snapshot with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the snapshot. By using the idempotent operation, you can retry a CreateSnapshot operation without the risk of creating an extra snapshot. This approach can be useful when an initial call fails in a way that makes it unclear whether a snapshot was created. If you use the same client request token and the initial call created a snapshot, the operation returns a successful result because all the parameters are the same. The CreateSnapshot operation returns while the snapshot's lifecycle state is still CREATING. You can check the snapshot creation status by calling the DescribeSnapshots (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeSnapshots.html) operation, which returns the snapshot state along with other information.
#
# POST /
# Returns: record<Snapshot: record<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: list<record>>>
# operationId: CreateSnapshot
export def "create-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: string # The name of the snapshot.
  volume_id: string # The ID of the volume that you are taking a snapshot of.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: Name, var: name}, {name: VolumeId, var: volume_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, name: $name, volume_id: $volume_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a storage virtual machine (SVM) for an Amazon FSx for ONTAP file system.
#
# POST /
# Returns: record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: string, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: string>>
# operationId: CreateStorageVirtualMachine
export def "create-storage-virtual-machine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --active-directory-configuration: record # The configuration that Amazon FSx uses to join the ONTAP storage virtual machine (SVM) to your self-managed (including on-premises) Microsoft Active Directory (AD) directory. — shape: {NetBiosName: string, SelfManagedActiveDirectoryConfiguration?: record}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  name: string # The name of the SVM.
  --svm-admin-password: string # The password to use when managing the SVM using the NetApp ONTAP CLI or REST API. If you do not specify a password, you can still use the file system's fsxadmin user to manage the SVM. (format: password)
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --root-volume-security-style: string@root-volume-security-style-completer # The security style of the root volume of the SVM. Specify one of the following values: UNIX if the file system is managed by a UNIX administrator, the majority of users are NFS clients, and an application accessing the data uses a UNIX user as the service account. NTFS if the file system is managed by a Windows administrator, the majority of users are SMB clients, and an application accessing the data uses a Windows user as the service account. MIXED if the file system is managed by both UNIX and Windows administrators and users consist of both NFS and SMB clients.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveDirectoryConfiguration, var: active_directory_configuration}, {name: ClientRequestToken, var: client_request_token}, {name: FileSystemId, var: file_system_id}, {name: Name, var: name}, {name: SvmAdminPassword, var: svm_admin_password}, {name: Tags, var: tags}, {name: RootVolumeSecurityStyle, var: root_volume_security_style}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, active_directory_configuration: $active_directory_configuration, client_request_token: $client_request_token, file_system_id: $file_system_id, name: $name, svm_admin_password: $svm_admin_password, tags: $tags, root_volume_security_style: $root_volume_security_style
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an FSx for ONTAP or Amazon FSx for OpenZFS storage volume.
#
# POST /
# Returns: record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>
# operationId: CreateVolume
export def "create-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_type: string@volume-type-completer # Specifies the type of volume to create; ONTAP and OPENZFS are the only valid volume types.
  name: string # Specifies the name of the volume that you're creating.
  --ontap-configuration: record # Specifies the configuration of the ONTAP volume that you are creating. — shape: {JunctionPath?: string, SecurityStyle?: "UNIX"|"NTFS"|"MIXED", SizeInMegabytes: int, StorageEfficiencyEnabled?: bool, StorageVirtualMachineId: string, TieringPolicy?: record, OntapVolumeType?: "RW"|"DP", SnapshotPolicy?: string, CopyTagsToBackups?: bool}
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --open-zfs-configuration: record # Specifies the configuration of the Amazon FSx for OpenZFS volume that you are creating. — shape: {ParentVolumeId: string, StorageCapacityReservationGiB?: int, StorageCapacityQuotaGiB?: int, RecordSizeKiB?: int, DataCompressionType?: "NONE"|"ZSTD"|"LZ4", CopyTagsToSnapshots?: bool, OriginSnapshot?: record, ReadOnly?: bool, NfsExports?: list, UserAndGroupQuotas?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: VolumeType, var: volume_type}, {name: Name, var: name}, {name: OntapConfiguration, var: ontap_configuration}, {name: Tags, var: tags}, {name: OpenZFSConfiguration, var: open_zfs_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, volume_type: $volume_type, name: $name, ontap_configuration: $ontap_configuration, tags: $tags, open_zfs_configuration: $open_zfs_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon FSx for NetApp ONTAP volume from an existing Amazon FSx volume backup.
#
# POST /
# Returns: record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>
# operationId: CreateVolumeFromBackup
export def "create-volume-from-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: string # The name of the new volume you're creating.
  --ontap-configuration: record # Specifies the configuration of the ONTAP volume that you are creating. — shape: {JunctionPath?: string, SecurityStyle?: "UNIX"|"NTFS"|"MIXED", SizeInMegabytes: int, StorageEfficiencyEnabled?: bool, StorageVirtualMachineId: string, TieringPolicy?: record, OntapVolumeType?: "RW"|"DP", SnapshotPolicy?: string, CopyTagsToBackups?: bool}
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.CreateVolumeFromBackup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupId, var: backup_id}, {name: ClientRequestToken, var: client_request_token}, {name: Name, var: name}, {name: OntapConfiguration, var: ontap_configuration}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, backup_id: $backup_id, client_request_token: $client_request_token, name: $name, ontap_configuration: $ontap_configuration, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon FSx backup. After deletion, the backup no longer exists, and its data is gone. The DeleteBackup call returns instantly. The backup won't show up in later DescribeBackups calls. The data in a deleted backup is also deleted and can't be recovered by any means.
#
# POST /
# Returns: record<BackupId: string, Lifecycle: string>
# operationId: DeleteBackup
export def "delete-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DeleteBackup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupId, var: backup_id}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, backup_id: $backup_id, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a data repository association on an Amazon FSx for Lustre file system. Deleting the data repository association unlinks the file system from the Amazon S3 bucket. When deleting a data repository association, you have the option of deleting the data in the file system that corresponds to the data repository association. Data repository associations are supported for all file systems except for Scratch_1 deployment type.
#
# POST /
# Returns: record<AssociationId: string, Lifecycle: string, DeleteDataInFileSystem: bool>
# operationId: DeleteDataRepositoryAssociation
export def "delete-data-repository-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  association_id: string # The ID of the data repository association that you want to delete.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --delete-data-in-file-system: oneof<nothing, bool> # Set to true to delete the data in the file system that corresponds to the data repository association.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationId, var: association_id}, {name: ClientRequestToken, var: client_request_token}, {name: DeleteDataInFileSystem, var: delete_data_in_file_system}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, client_request_token: $client_request_token, delete_data_in_file_system: $delete_data_in_file_system
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon File Cache resource. After deletion, the cache no longer exists, and its data is gone. The DeleteFileCache operation returns while the cache has the DELETING status. You can check the cache deletion status by calling the DescribeFileCaches (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html) operation, which returns a list of caches in your account. If you pass the cache ID for a deleted cache, the DescribeFileCaches operation returns a FileCacheNotFound error. The data in a deleted cache is also deleted and can't be recovered by any means.
#
# POST /
# Returns: record<FileCacheId: string, Lifecycle: string>
# operationId: DeleteFileCache
export def "delete-file-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_cache_id: string # The ID of the cache that's being deleted.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DeleteFileCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileCacheId, var: file_cache_id}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_cache_id: $file_cache_id, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a file system. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups and snapshots are also deleted. To delete an Amazon FSx for NetApp ONTAP file system, first delete all the volumes and storage virtual machines (SVMs) on the file system. Then provide a FileSystemId value to the DeleFileSystem operation. By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup isn't subject to the file system's retention policy, and must be manually deleted. The DeleteFileSystem operation returns while the file system has the DELETING status. You can check the file system deletion status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the DescribeFileSystems operation returns a FileSystemNotFound error. If a data repository task is in a PENDING or EXECUTING state, deleting an Amazon FSx for Lustre file system will fail with an HTTP status code 400 (Bad Request). The data in a deleted file system is also deleted and can't be recovered by any means.
#
# POST /
# Returns: record<FileSystemId: string, Lifecycle: string, WindowsResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>, LustreResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>, OpenZFSResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>>
# operationId: DeleteFileSystem
export def "delete-file-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --windows-configuration: record # The configuration object for the Microsoft Windows file system used in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list}
  --lustre-configuration: record # The configuration object for the Amazon FSx for Lustre file system being deleted in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list}
  --open-zfs-configuration: record # The configuration object for the Amazon FSx for OpenZFS file system used in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list, Options?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DeleteFileSystem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemId, var: file_system_id}, {name: ClientRequestToken, var: client_request_token}, {name: WindowsConfiguration, var: windows_configuration}, {name: LustreConfiguration, var: lustre_configuration}, {name: OpenZFSConfiguration, var: open_zfs_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_id: $file_system_id, client_request_token: $client_request_token, windows_configuration: $windows_configuration, lustre_configuration: $lustre_configuration, open_zfs_configuration: $open_zfs_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon FSx for OpenZFS snapshot. After deletion, the snapshot no longer exists, and its data is gone. Deleting a snapshot doesn't affect snapshots stored in a file system backup. The DeleteSnapshot operation returns instantly. The snapshot appears with the lifecycle status of DELETING until the deletion is complete.
#
# POST /
# Returns: record<SnapshotId: string, Lifecycle: string>
# operationId: DeleteSnapshot
export def "delete-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  snapshot_id: string # The ID of the snapshot that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DeleteSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: SnapshotId, var: snapshot_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Amazon FSx for ONTAP storage virtual machine (SVM). Prior to deleting an SVM, you must delete all non-root volumes in the SVM, otherwise the operation will fail.
#
# POST /
# Returns: record<StorageVirtualMachineId: string, Lifecycle: string>
# operationId: DeleteStorageVirtualMachine
export def "delete-storage-virtual-machine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  storage_virtual_machine_id: string # The ID of the SVM that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: StorageVirtualMachineId, var: storage_virtual_machine_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, storage_virtual_machine_id: $storage_virtual_machine_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /
# Returns: record<VolumeId: string, Lifecycle: string, OntapResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>>
# operationId: DeleteVolume
export def "delete-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: string # The ID of the volume that you are deleting.
  --ontap-configuration: record # Use to specify skipping a final backup, or to add tags to a final backup. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list}
  --open-zfs-configuration: record # A value that specifies whether to delete all child volumes and snapshots. — shape: {Options?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DeleteVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: VolumeId, var: volume_id}, {name: OntapConfiguration, var: ontap_configuration}, {name: OpenZFSConfiguration, var: open_zfs_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, volume_id: $volume_id, ontap_configuration: $ontap_configuration, open_zfs_configuration: $open_zfs_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the description of a specific Amazon FSx backup, if a BackupIds value is provided for that backup. Otherwise, it returns all backups owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all backups, you can optionally specify the MaxResults parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of the NextToken value from the last response. This operation is used in an iterative process to retrieve a list of your backups. DescribeBackups is called first without a NextToken value. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken value. When using this operation, keep the following in mind: The operation might return fewer than the MaxResults value of backup descriptions while still including a NextToken value. The order of the backups returned in the response of one DescribeBackups call and the order of the backups returned across the responses of a multi-call iteration is unspecified.
#
# POST /
# Returns: record<Backups: table<BackupId: string, Lifecycle: string, FailureDetails: record, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list, FileSystem: record, DirectoryInformation: record, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record>, NextToken: string>
# operationId: DescribeBackups
export def "describe-backups" [
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
  --backup-ids: list<string> # A list of backup IDs.
  --filters: list # A list of Filter elements. — item shape: {Name?: "file-system-id"|"backup-type"|"file-system-type"|"volume-id"|"data-repository-type"|"file-cache-id"|"file-cache-type", Values?: list<string>}
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeBackups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BackupIds, var: backup_ids}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, backup_ids: $backup_ids, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository associations, if one or more AssociationIds values are provided in the request, or if filters are used in the request. Data repository associations are supported on Amazon File Cache resources and all Amazon FSx for Lustre file systems excluding Scratch_1 deployment types. You can use filters to narrow the response to include just data repository associations for specific file systems (use the file-system-id filter with the ID of the file system) or caches (use the file-cache-id filter with the ID of the cache), or data repository associations for a specific repository type (use the data-repository-type filter with a value of S3 or NFS). If you don't use filters, the response returns all data repository associations owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all data repository associations, you can paginate the response by using the optional MaxResults parameter to limit the number of data repository associations returned in a response. If more data repository associations remain, a NextToken value is returned in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response.
#
# POST /
# Returns: record<Associations: table<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record, Tags: list, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list, NFS: record>, NextToken: string>
# operationId: DescribeDataRepositoryAssociations
export def "describe-data-repository-associations" [
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
  --association-ids: list<string> # IDs of the data repository associations whose descriptions you want to retrieve (String).
  --filters: list # A list of Filter elements. — item shape: {Name?: "file-system-id"|"backup-type"|"file-system-type"|"volume-id"|"data-repository-type"|"file-cache-id"|"file-cache-type", Values?: list<string>}
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationIds, var: association_ids}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_ids: $association_ids, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository tasks, if one or more TaskIds values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems or caches, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all tasks, you can paginate the response by using the optional MaxResults parameter to limit the number of tasks returned in a response. If more tasks remain, a NextToken value is returned in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response.
#
# POST /
# Returns: record<DataRepositoryTasks: table<TaskId: string, Lifecycle: string, Type: string, CreationTime: string, StartTime: string, EndTime: string, ResourceARN: string, Tags: list, FileSystemId: string, Paths: list, FailureDetails: record, Status: record, Report: record, CapacityToRelease: int, FileCacheId: string>, NextToken: string>
# operationId: DescribeDataRepositoryTasks
export def "describe-data-repository-tasks" [
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
  --task-ids: list<string> # (Optional) IDs of the tasks whose descriptions you want to retrieve (String).
  --filters: list # (Optional) You can use filters to narrow the DescribeDataRepositoryTasks response to include just tasks for specific file systems, or tasks in a specific lifecycle state. — item shape: {Name?: "file-system-id"|"task-lifecycle"|"data-repository-association-id"|"file-cache-id", Values?: list<string>}
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaskIds, var: task_ids}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, task_ids: $task_ids, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the description of a specific Amazon File Cache resource, if a FileCacheIds value is provided for that cache. Otherwise, it returns descriptions of all caches owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all cache descriptions, you can optionally specify the MaxResults parameter to limit the number of descriptions in a response. If more cache descriptions remain, the operation returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This operation is used in an iterative process to retrieve a list of your cache descriptions. DescribeFileCaches is called first without a NextTokenvalue. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this operation, keep the following in mind: The implementation might return fewer than MaxResults cache descriptions while still including a NextToken value. The order of caches returned in the response of one DescribeFileCaches call and the order of caches returned across the responses of a multicall iteration is unspecified.
#
# POST /
# Returns: record<FileCaches: table<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, LustreConfiguration: record, DataRepositoryAssociationIds: list>, NextToken: string>
# operationId: DescribeFileCaches
export def "describe-file-caches" [
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
  --file-cache-ids: list<string> # IDs of the caches whose descriptions you want to retrieve (String).
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeFileCaches"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileCacheIds, var: file_cache_ids}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_cache_ids: $file_cache_ids, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the DNS aliases that are associated with the specified Amazon FSx for Windows File Server file system. A history of all DNS aliases that have been associated with and disassociated from the file system is available in the list of AdministrativeAction provided in the DescribeFileSystems operation response.
#
# POST /
# Returns: record<Aliases: table<Name: string, Lifecycle: string>, NextToken: string>
# operationId: DescribeFileSystemAliases
export def "describe-file-system-aliases" [
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeFileSystemAliases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: FileSystemId, var: file_system_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, file_system_id: $file_system_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the description of specific Amazon FSx file systems, if a FileSystemIds value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all file system descriptions, you can optionally specify the MaxResults parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This operation is used in an iterative process to retrieve a list of your file system descriptions. DescribeFileSystems is called first without a NextTokenvalue. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this operation, keep the following in mind: The implementation might return fewer than MaxResults file system descriptions while still including a NextToken value. The order of file systems returned in the response of one DescribeFileSystems call and the order of file systems returned across the responses of a multicall iteration is unspecified.
#
# POST /
# Returns: record<FileSystems: table<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, NextToken: string>
# operationId: DescribeFileSystems
export def "describe-file-systems" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --file-system-ids: list<string> # A list of file system IDs.
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeFileSystems"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemIds, var: file_system_ids}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_ids: $file_system_ids, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the description of specific Amazon FSx for OpenZFS snapshots, if a SnapshotIds value is provided. Otherwise, this operation returns all snapshots owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all snapshots, you can optionally specify the MaxResults parameter to limit the number of snapshots in a response. If more backups remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. Use this operation in an iterative process to retrieve a list of your snapshots. DescribeSnapshots is called first without a NextToken value. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken value. When using this operation, keep the following in mind: The operation might return fewer than the MaxResults value of snapshot descriptions while still including a NextToken value. The order of snapshots returned in the response of one DescribeSnapshots call and the order of backups returned across the responses of a multi-call iteration is unspecified.
#
# POST /
# Returns: record<Snapshots: table<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record, Tags: list, AdministrativeActions: list>, NextToken: string>
# operationId: DescribeSnapshots
export def "describe-snapshots" [
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
  --snapshot-ids: list<string> # The IDs of the snapshots that you want to retrieve. This parameter value overrides any filters. If any IDs aren't found, a SnapshotNotFound error occurs.
  --filters: list # The filters structure. The supported names are file-system-id or volume-id. — item shape: {Name?: "file-system-id"|"volume-id", Values?: list<string>}
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeSnapshots"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SnapshotIds, var: snapshot_ids}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, snapshot_ids: $snapshot_ids, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes one or more Amazon FSx for NetApp ONTAP storage virtual machines (SVMs).
#
# POST /
# Returns: record<StorageVirtualMachines: table<ActiveDirectoryConfiguration: record, CreationTime: string, Endpoints: record, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list, LifecycleTransitionReason: record, RootVolumeSecurityStyle: string>, NextToken: string>
# operationId: DescribeStorageVirtualMachines
export def "describe-storage-virtual-machines" [
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
  --storage-virtual-machine-ids: list<string> # Enter the ID of one or more SVMs that you want to view.
  --filters: list # Enter a filter name:value pair to view a select set of SVMs. — item shape: {Name?: "file-system-id", Values?: list<string>}
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StorageVirtualMachineIds, var: storage_virtual_machine_ids}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, storage_virtual_machine_ids: $storage_virtual_machine_ids, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes one or more Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volumes.
#
# POST /
# Returns: record<Volumes: table<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>, NextToken: string>
# operationId: DescribeVolumes
export def "describe-volumes" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --volume-ids: list<string> # The IDs of the volumes whose descriptions you want to retrieve.
  --filters: list # Enter a filter Name and Values pair to view a select set of volumes. — item shape: {Name?: "file-system-id"|"storage-virtual-machine-id", Values?: list<string>}
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DescribeVolumes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeIds, var: volume_ids}, {name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_ids: $volume_ids, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this action to disassociate, or remove, one or more Domain Name Service (DNS) aliases from an Amazon FSx for Windows File Server file system. If you attempt to disassociate a DNS alias that is not associated with the file system, Amazon FSx responds with a 400 Bad Request. For more information, see Working with DNS Aliases (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/managing-dns-aliases.html). The system generated response showing the DNS aliases that Amazon FSx is attempting to disassociate from the file system. Use the API operation to monitor the status of the aliases Amazon FSx is disassociating with the file system.
#
# POST /
# Returns: record<Aliases: table<Name: string, Lifecycle: string>>
# operationId: DisassociateFileSystemAliases
export def "disassociate-file-system-aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  aliases: list<string> # An array of one or more DNS alias names to disassociate, or remove, from the file system.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: FileSystemId, var: file_system_id}, {name: Aliases, var: aliases}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, file_system_id: $file_system_id, aliases: $aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists tags for Amazon FSx resources. When retrieving all tags, you can optionally specify the MaxResults parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This action is used in an iterative process to retrieve a list of your tags. ListTagsForResource is called first without a NextTokenvalue. Then the action continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this action, keep the following in mind: The implementation might return fewer than MaxResults file system descriptions while still including a NextToken value. The order of tags returned in the response of one ListTagsForResource call and the order of tags returned across the responses of a multi-call iteration is unspecified.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>, NextToken: string>
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
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  resource_arn: string # The Amazon Resource Name (ARN) for a given resource. ARNs uniquely identify Amazon Web Services resources. We require an ARN when you need to specify a resource unambiguously across all of Amazon Web Services. For more information, see Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  --body-max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (spec name: MaxResults)
  --body-next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Releases the file system lock from an Amazon FSx for OpenZFS file system.
#
# POST /
# Returns: record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>
# operationId: ReleaseFileSystemNfsV3Locks
export def "release-file-system-nfs-v3-locks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemId, var: file_system_id}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_id: $file_system_id, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an Amazon FSx for OpenZFS volume to the state saved by the specified snapshot.
#
# POST /
# Returns: record<VolumeId: string, Lifecycle: string, AdministrativeActions: table<AdministrativeActionType: string, ProgressPercent: int, RequestTime: string, Status: string, TargetFileSystemValues: record, FailureDetails: record, TargetVolumeValues: record, TargetSnapshotValues: record>>
# operationId: RestoreVolumeFromSnapshot
export def "restore-volume-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: string # The ID of the volume that you are restoring.
  snapshot_id: string # The ID of the source snapshot. Specifies the snapshot that you are restoring from.
  --options: list<string> # The settings used when restoring the specified volume from snapshot. DELETE_INTERMEDIATE_SNAPSHOTS - Deletes snapshots between the current state and the specified snapshot. If there are intermediate snapshots and this option isn't used, RestoreVolumeFromSnapshot fails. DELETE_CLONED_VOLUMES - Deletes any dependent clone volumes created from intermediate snapshots. If there are any dependent clone volumes and this option isn't used, RestoreVolumeFromSnapshot fails.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: VolumeId, var: volume_id}, {name: SnapshotId, var: snapshot_id}, {name: Options, var: options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, volume_id: $volume_id, snapshot_id: $snapshot_id, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tags an Amazon FSx resource.
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  resource_arn: string # The Amazon Resource Name (ARN) for a given resource. ARNs uniquely identify Amazon Web Services resources. We require an ARN when you need to specify a resource unambiguously across all of Amazon Web Services. For more information, see Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action removes a tag from an Amazon FSx resource.
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  resource_arn: string # The Amazon Resource Name (ARN) for a given resource. ARNs uniquely identify Amazon Web Services resources. We require an ARN when you need to specify a resource unambiguously across all of Amazon Web Services. For more information, see Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  tag_keys: list<string> # A list of TagKey values, with a maximum of 50 elements.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of an existing data repository association on an Amazon FSx for Lustre file system. Data repository associations are supported for all file systems except for Scratch_1 deployment type.
#
# POST /
# Returns: record<Association: record<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record<Message: string>, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list<string>, NFS: record<Version: string, DnsIps: list, AutoExportPolicy: record>>>
# operationId: UpdateDataRepositoryAssociation
export def "update-data-repository-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  association_id: string # The ID of the data repository association that you are updating.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --imported-file-chunk-size: int # For files imported from a data repository, this value determines the stripe count and maximum amount of data per file (in MiB) stored on a single physical disk. The maximum number of disks that a single file can be striped across is limited by the total number of disks that make up the file system. The default chunk size is 1,024 MiB (1 GiB) and can go as high as 512,000 MiB (500 GiB). Amazon S3 objects have a maximum size of 5 TB.
  --s3: record # The configuration for an Amazon S3 data repository linked to an Amazon FSx for Lustre file system with a data repository association. The configuration consists of an AutoImportPolicy that defines which file events on the data repository are automatically imported to the file system and an AutoExportPolicy that defines which file events on the file system are automatically exported to the data repository. File events are when files or directories are added, changed, or deleted on the file system or the data repository. Data repository associations on Amazon File Cache don't use S3DataRepositoryConfiguration because they don't support automatic import or automatic export. — shape: {AutoImportPolicy?: record, AutoExportPolicy?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssociationId, var: association_id}, {name: ClientRequestToken, var: client_request_token}, {name: ImportedFileChunkSize, var: imported_file_chunk_size}, {name: S3, var: s3}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, client_request_token: $client_request_token, imported_file_chunk_size: $imported_file_chunk_size, s3: $s3
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of an existing Amazon File Cache resource. You can update multiple properties in a single request.
#
# POST /
# Returns: record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, LustreConfiguration: record<PerUnitStorageThroughput: int, DeploymentType: string, MountName: string, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: list<string>>>
# operationId: UpdateFileCache
export def "update-file-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_cache_id: string # The ID of the cache that you are updating.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --lustre-configuration: record # The configuration update for an Amazon File Cache resource. — shape: {WeeklyMaintenanceStartTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.UpdateFileCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileCacheId, var: file_cache_id}, {name: ClientRequestToken, var: client_request_token}, {name: LustreConfiguration, var: lustre_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_cache_id: $file_cache_id, client_request_token: $client_request_token, lustre_configuration: $lustre_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this operation to update the configuration of an existing Amazon FSx file system. You can update multiple properties in a single request. For FSx for Windows File Server file systems, you can update the following properties: AuditLogConfiguration AutomaticBackupRetentionDays DailyAutomaticBackupStartTime SelfManagedActiveDirectoryConfiguration StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime For FSx for Lustre file systems, you can update the following properties: AutoImportPolicy AutomaticBackupRetentionDays DailyAutomaticBackupStartTime DataCompressionType LustreRootSquashConfiguration StorageCapacity WeeklyMaintenanceStartTime For FSx for ONTAP file systems, you can update the following properties: AddRouteTableIds AutomaticBackupRetentionDays DailyAutomaticBackupStartTime DiskIopsConfiguration FsxAdminPassword RemoveRouteTableIds StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime For FSx for OpenZFS file systems, you can update the following properties: AutomaticBackupRetentionDays CopyTagsToBackups CopyTagsToVolumes DailyAutomaticBackupStartTime DiskIopsConfiguration StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime
#
# POST /
# Returns: record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>
# operationId: UpdateFileSystem
export def "update-file-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --storage-capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
  --windows-configuration: record # Updates the configuration for an existing Amazon FSx for Windows File Server file system. Amazon FSx only overwrites existing properties with non-null values provided in the request. — shape: {WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, ThroughputCapacity?: int, SelfManagedActiveDirectoryConfiguration?: record, AuditLogConfiguration?: record}
  --lustre-configuration: record # The configuration object for Amazon FSx for Lustre file systems used in the UpdateFileSystem operation. — shape: {WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, AutoImportPolicy?: "NONE"|"NEW"|"NEW_CHANGED"|"NEW_CHANGED_DELETED", DataCompressionType?: "NONE"|"LZ4", LogConfiguration?: record, RootSquashConfiguration?: record}
  --ontap-configuration: record # The configuration updates for an Amazon FSx for NetApp ONTAP file system. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, FsxAdminPassword?: string, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record, ThroughputCapacity?: int, AddRouteTableIds?: list<string>, RemoveRouteTableIds?: list<string>}
  --open-zfs-configuration: record # The configuration updates for an Amazon FSx for OpenZFS file system. — shape: {AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, CopyTagsToVolumes?: bool, DailyAutomaticBackupStartTime?: string, ThroughputCapacity?: int, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.UpdateFileSystem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemId, var: file_system_id}, {name: ClientRequestToken, var: client_request_token}, {name: StorageCapacity, var: storage_capacity}, {name: WindowsConfiguration, var: windows_configuration}, {name: LustreConfiguration, var: lustre_configuration}, {name: OntapConfiguration, var: ontap_configuration}, {name: OpenZFSConfiguration, var: open_zfs_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_id: $file_system_id, client_request_token: $client_request_token, storage_capacity: $storage_capacity, windows_configuration: $windows_configuration, lustre_configuration: $lustre_configuration, ontap_configuration: $ontap_configuration, open_zfs_configuration: $open_zfs_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of an Amazon FSx for OpenZFS snapshot.
#
# POST /
# Returns: record<Snapshot: record<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: list<record>>>
# operationId: UpdateSnapshot
export def "update-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: string # The name of the snapshot to update.
  snapshot_id: string # The ID of the snapshot that you want to update, in the format fsvolsnap-0123456789abcdef0.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.UpdateSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: Name, var: name}, {name: SnapshotId, var: snapshot_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, name: $name, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon FSx for ONTAP storage virtual machine (SVM).
#
# POST /
# Returns: record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: string, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: string>>
# operationId: UpdateStorageVirtualMachine
export def "update-storage-virtual-machine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --active-directory-configuration: record # Updates the Microsoft Active Directory (AD) configuration of an SVM joined to an AD. Please note, account credentials are not returned in the response payload. — shape: {SelfManagedActiveDirectoryConfiguration?: record}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  storage_virtual_machine_id: string # The ID of the SVM that you want to update, in the format svm-0123456789abcdef0.
  --svm-admin-password: string # Enter a new SvmAdminPassword if you are updating it. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveDirectoryConfiguration, var: active_directory_configuration}, {name: ClientRequestToken, var: client_request_token}, {name: StorageVirtualMachineId, var: storage_virtual_machine_id}, {name: SvmAdminPassword, var: svm_admin_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, active_directory_configuration: $active_directory_configuration, client_request_token: $client_request_token, storage_virtual_machine_id: $storage_virtual_machine_id, svm_admin_password: $svm_admin_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /
# Returns: record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>
# operationId: UpdateVolume
export def "update-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: string # The ID of the volume that you want to update, in the format fsvol-0123456789abcdef0.
  --ontap-configuration: record # Used to specify changes to the ONTAP configuration for the volume you are updating. — shape: {JunctionPath?: string, SecurityStyle?: "UNIX"|"NTFS"|"MIXED", SizeInMegabytes?: int, StorageEfficiencyEnabled?: bool, TieringPolicy?: record, SnapshotPolicy?: string, CopyTagsToBackups?: bool}
  --name: string # The name of the OpenZFS volume. OpenZFS root volumes are automatically named FSX. Child volume names must be unique among their parent volume's children. The name of the volume is part of the mount string for the OpenZFS volume.
  --open-zfs-configuration: record # Used to specify changes to the OpenZFS configuration for the volume that you are updating. — shape: {StorageCapacityReservationGiB?: int, StorageCapacityQuotaGiB?: int, RecordSizeKiB?: int, DataCompressionType?: "NONE"|"ZSTD"|"LZ4", NfsExports?: list, UserAndGroupQuotas?: list, ReadOnly?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSSimbaAPIService_v20180301.UpdateVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientRequestToken, var: client_request_token}, {name: VolumeId, var: volume_id}, {name: OntapConfiguration, var: ontap_configuration}, {name: Name, var: name}, {name: OpenZFSConfiguration, var: open_zfs_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_request_token: $client_request_token, volume_id: $volume_id, ontap_configuration: $ontap_configuration, name: $name, open_zfs_configuration: $open_zfs_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
