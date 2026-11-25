# Auto-generated client for Amazon Pinpoint v2016-12-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/pinpoint/2016-12-01/openapi.json
# Auth: --token flag or $env.AMAZON_PINPOINT_TOKEN

const CLIENT = {
  base_url: "http://pinpoint.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_PINPOINT_TOKEN"
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

def base-url-completer [] { ["http://pinpoint.us-east-1.amazonaws.com" "http://pinpoint.us-east-2.amazonaws.com" "http://pinpoint.us-west-1.amazonaws.com" "http://pinpoint.us-west-2.amazonaws.com" "http://pinpoint.us-gov-west-1.amazonaws.com" "http://pinpoint.us-gov-east-1.amazonaws.com" "http://pinpoint.ca-central-1.amazonaws.com" "http://pinpoint.eu-north-1.amazonaws.com" "http://pinpoint.eu-west-1.amazonaws.com" "http://pinpoint.eu-west-2.amazonaws.com" "http://pinpoint.eu-west-3.amazonaws.com" "http://pinpoint.eu-central-1.amazonaws.com" "http://pinpoint.eu-south-1.amazonaws.com" "http://pinpoint.af-south-1.amazonaws.com" "http://pinpoint.ap-northeast-1.amazonaws.com" "http://pinpoint.ap-northeast-2.amazonaws.com" "http://pinpoint.ap-northeast-3.amazonaws.com" "http://pinpoint.ap-southeast-1.amazonaws.com" "http://pinpoint.ap-southeast-2.amazonaws.com" "http://pinpoint.ap-east-1.amazonaws.com" "http://pinpoint.ap-south-1.amazonaws.com" "http://pinpoint.sa-east-1.amazonaws.com" "http://pinpoint.me-south-1.amazonaws.com" "https://pinpoint.us-east-1.amazonaws.com" "https://pinpoint.us-east-2.amazonaws.com" "https://pinpoint.us-west-1.amazonaws.com" "https://pinpoint.us-west-2.amazonaws.com" "https://pinpoint.us-gov-west-1.amazonaws.com" "https://pinpoint.us-gov-east-1.amazonaws.com" "https://pinpoint.ca-central-1.amazonaws.com" "https://pinpoint.eu-north-1.amazonaws.com" "https://pinpoint.eu-west-1.amazonaws.com" "https://pinpoint.eu-west-2.amazonaws.com" "https://pinpoint.eu-west-3.amazonaws.com" "https://pinpoint.eu-central-1.amazonaws.com" "https://pinpoint.eu-south-1.amazonaws.com" "https://pinpoint.af-south-1.amazonaws.com" "https://pinpoint.ap-northeast-1.amazonaws.com" "https://pinpoint.ap-northeast-2.amazonaws.com" "https://pinpoint.ap-northeast-3.amazonaws.com" "https://pinpoint.ap-southeast-1.amazonaws.com" "https://pinpoint.ap-southeast-2.amazonaws.com" "https://pinpoint.ap-east-1.amazonaws.com" "https://pinpoint.ap-south-1.amazonaws.com" "https://pinpoint.sa-east-1.amazonaws.com" "https://pinpoint.me-south-1.amazonaws.com" "http://pinpoint.cn-north-1.amazonaws.com.cn" "http://pinpoint.cn-northwest-1.amazonaws.com.cn" "https://pinpoint.cn-north-1.amazonaws.com.cn" "https://pinpoint.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-app: "record<ApplicationResponse: record<Arn: string, Id: string, Name: string, tags: record, CreationDate: string>>"
    get-apps: "record<ApplicationsResponse: record<Item: list<record>, NextToken: string>>"
    create-campaign: "record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>"
    get-campaigns: "record<CampaignsResponse: record<Item: list<record>, NextToken: string>>"
    create-email-template: "record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>"
    delete-email-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    get-email-template: "record<EmailTemplateResponse: record<Arn: string, CreationDate: string, DefaultSubstitutions: string, HtmlPart: string, LastModifiedDate: string, RecommenderId: string, Subject: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, TextPart: string, Version: string>>"
    update-email-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    create-export-job: "record<ExportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<RoleArn: string, S3UrlPrefix: string, SegmentId: string, SegmentVersion: int>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>"
    get-export-jobs: "record<ExportJobsResponse: record<Item: list<record>, NextToken: string>>"
    create-import-job: "record<ImportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<DefineSegment: bool, ExternalId: string, Format: string, RegisterEndpoints: bool, RoleArn: string, S3Url: string, SegmentId: string, SegmentName: string>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>"
    get-import-jobs: "record<ImportJobsResponse: record<Item: list<record>, NextToken: string>>"
    create-in-app-template: "record<TemplateCreateMessageBody: record<Arn: string, Message: string, RequestID: string>>"
    delete-in-app-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    get-in-app-template: "record<InAppTemplateResponse: record<Arn: string, Content: list<record>, CreationDate: string, CustomConfig: record, LastModifiedDate: string, Layout: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string>>"
    update-in-app-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    create-journey: "record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>"
    list-journeys: "record<JourneysResponse: record<Item: list<record>, NextToken: string>>"
    create-push-template: "record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>"
    delete-push-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    get-push-template: "record<PushNotificationTemplateResponse: record<ADM: record<Action: string, Body: string, ImageIconUrl: string, ImageUrl: string, RawContent: string, SmallImageIconUrl: string, Sound: string, Title: string, Url: string>, APNS: record<Action: string, Body: string, MediaUrl: string, RawContent: string, Sound: string, Title: string, Url: string>, Arn: string, Baidu: record<Action: string, Body: string, ImageIconUrl: string, ImageUrl: string, RawContent: string, SmallImageIconUrl: string, Sound: string, Title: string, Url: string>, CreationDate: string, Default: record<Action: string, Body: string, Sound: string, Title: string, Url: string>, DefaultSubstitutions: string, GCM: record<Action: string, Body: string, ImageIconUrl: string, ImageUrl: string, RawContent: string, SmallImageIconUrl: string, Sound: string, Title: string, Url: string>, LastModifiedDate: string, RecommenderId: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string>>"
    update-push-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    create-recommender-configuration: "record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>"
    get-recommender-configurations: "record<ListRecommenderConfigurationsResponse: record<Item: list<record>, NextToken: string>>"
    create-segment: "record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>"
    get-segments: "record<SegmentsResponse: record<Item: list<record>, NextToken: string>>"
    create-sms-template: "record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>"
    delete-sms-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    get-sms-template: "record<SMSTemplateResponse: record<Arn: string, Body: string, CreationDate: string, DefaultSubstitutions: string, LastModifiedDate: string, RecommenderId: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string>>"
    update-sms-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    create-voice-template: "record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>"
    delete-voice-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    get-voice-template: "record<VoiceTemplateResponse: record<Arn: string, Body: string, CreationDate: string, DefaultSubstitutions: string, LanguageCode: string, LastModifiedDate: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string, VoiceId: string>>"
    update-voice-template: "record<MessageBody: record<Message: string, RequestID: string>>"
    delete-adm-channel: "record<ADMChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-adm-channel: "record<ADMChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-adm-channel: "record<ADMChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    delete-apns-channel: "record<APNSChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-apns-channel: "record<APNSChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-apns-channel: "record<APNSChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    delete-apns-sandbox-channel: "record<APNSSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-apns-sandbox-channel: "record<APNSSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-apns-sandbox-channel: "record<APNSSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    delete-apns-voip-channel: "record<APNSVoipChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-apns-voip-channel: "record<APNSVoipChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-apns-voip-channel: "record<APNSVoipChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    delete-apns-voip-sandbox-channel: "record<APNSVoipSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-apns-voip-sandbox-channel: "record<APNSVoipSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-apns-voip-sandbox-channel: "record<APNSVoipSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    delete-app: "record<ApplicationResponse: record<Arn: string, Id: string, Name: string, tags: record, CreationDate: string>>"
    get-app: "record<ApplicationResponse: record<Arn: string, Id: string, Name: string, tags: record, CreationDate: string>>"
    delete-baidu-channel: "record<BaiduChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-baidu-channel: "record<BaiduChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-baidu-channel: "record<BaiduChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    delete-campaign: "record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>"
    get-campaign: "record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>"
    update-campaign: "record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>"
    delete-email-channel: "record<EmailChannelResponse: record<ApplicationId: string, ConfigurationSet: string, CreationDate: string, Enabled: bool, FromAddress: string, HasCredential: bool, Id: string, Identity: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, MessagesPerSecond: int, Platform: string, RoleArn: string, Version: int>>"
    get-email-channel: "record<EmailChannelResponse: record<ApplicationId: string, ConfigurationSet: string, CreationDate: string, Enabled: bool, FromAddress: string, HasCredential: bool, Id: string, Identity: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, MessagesPerSecond: int, Platform: string, RoleArn: string, Version: int>>"
    update-email-channel: "record<EmailChannelResponse: record<ApplicationId: string, ConfigurationSet: string, CreationDate: string, Enabled: bool, FromAddress: string, HasCredential: bool, Id: string, Identity: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, MessagesPerSecond: int, Platform: string, RoleArn: string, Version: int>>"
    delete-endpoint: "record<EndpointResponse: record<Address: string, ApplicationId: string, Attributes: record, ChannelType: string, CohortId: string, CreationDate: string, Demographic: record<AppVersion: string, Locale: string, Make: string, Model: string, ModelVersion: string, Platform: string, PlatformVersion: string, Timezone: string>, EffectiveDate: string, EndpointStatus: string, Id: string, Location: record<City: string, Country: string, Latitude: float, Longitude: float, PostalCode: string, Region: string>, Metrics: record, OptOut: string, RequestId: string, User: record<UserAttributes: record, UserId: string>>>"
    get-endpoint: "record<EndpointResponse: record<Address: string, ApplicationId: string, Attributes: record, ChannelType: string, CohortId: string, CreationDate: string, Demographic: record<AppVersion: string, Locale: string, Make: string, Model: string, ModelVersion: string, Platform: string, PlatformVersion: string, Timezone: string>, EffectiveDate: string, EndpointStatus: string, Id: string, Location: record<City: string, Country: string, Latitude: float, Longitude: float, PostalCode: string, Region: string>, Metrics: record, OptOut: string, RequestId: string, User: record<UserAttributes: record, UserId: string>>>"
    update-endpoint: "record<MessageBody: record<Message: string, RequestID: string>>"
    delete-event-stream: "record<EventStream: record<ApplicationId: string, DestinationStreamArn: string, ExternalId: string, LastModifiedDate: string, LastUpdatedBy: string, RoleArn: string>>"
    get-event-stream: "record<EventStream: record<ApplicationId: string, DestinationStreamArn: string, ExternalId: string, LastModifiedDate: string, LastUpdatedBy: string, RoleArn: string>>"
    put-event-stream: "record<EventStream: record<ApplicationId: string, DestinationStreamArn: string, ExternalId: string, LastModifiedDate: string, LastUpdatedBy: string, RoleArn: string>>"
    delete-gcm-channel: "record<GCMChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-gcm-channel: "record<GCMChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-gcm-channel: "record<GCMChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    delete-journey: "record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>"
    get-journey: "record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>"
    update-journey: "record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>"
    delete-recommender-configuration: "record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>"
    get-recommender-configuration: "record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>"
    update-recommender-configuration: "record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>"
    delete-segment: "record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>"
    get-segment: "record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>"
    update-segment: "record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>"
    delete-sms-channel: "record<SMSChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, PromotionalMessagesPerSecond: int, SenderId: string, ShortCode: string, TransactionalMessagesPerSecond: int, Version: int>>"
    get-sms-channel: "record<SMSChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, PromotionalMessagesPerSecond: int, SenderId: string, ShortCode: string, TransactionalMessagesPerSecond: int, Version: int>>"
    update-sms-channel: "record<SMSChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, PromotionalMessagesPerSecond: int, SenderId: string, ShortCode: string, TransactionalMessagesPerSecond: int, Version: int>>"
    delete-user-endpoints: "record<EndpointsResponse: record<Item: list<record>>>"
    get-user-endpoints: "record<EndpointsResponse: record<Item: list<record>>>"
    delete-voice-channel: "record<VoiceChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-voice-channel: "record<VoiceChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    update-voice-channel: "record<VoiceChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>"
    get-application-date-range-kpi: "record<ApplicationDateRangeKpiResponse: record<ApplicationId: string, EndTime: string, KpiName: string, KpiResult: record<Rows: list>, NextToken: string, StartTime: string>>"
    get-application-settings: "record<ApplicationSettingsResource: record<ApplicationId: string, CampaignHook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, QuietTime: record<End: string, Start: string>>>"
    update-application-settings: "record<ApplicationSettingsResource: record<ApplicationId: string, CampaignHook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, QuietTime: record<End: string, Start: string>>>"
    get-campaign-activities: "record<ActivitiesResponse: record<Item: list<record>, NextToken: string>>"
    get-campaign-date-range-kpi: "record<CampaignDateRangeKpiResponse: record<ApplicationId: string, CampaignId: string, EndTime: string, KpiName: string, KpiResult: record<Rows: list>, NextToken: string, StartTime: string>>"
    get-campaign-version: "record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>"
    get-campaign-versions: "record<CampaignsResponse: record<Item: list<record>, NextToken: string>>"
    get-channels: "record<ChannelsResponse: record<Channels: record>>"
    get-export-job: "record<ExportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<RoleArn: string, S3UrlPrefix: string, SegmentId: string, SegmentVersion: int>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>"
    get-import-job: "record<ImportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<DefineSegment: bool, ExternalId: string, Format: string, RegisterEndpoints: bool, RoleArn: string, S3Url: string, SegmentId: string, SegmentName: string>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>"
    get-in-app-messages: "record<InAppMessagesResponse: record<InAppMessageCampaigns: list<record>>>"
    get-journey-date-range-kpi: "record<JourneyDateRangeKpiResponse: record<ApplicationId: string, EndTime: string, JourneyId: string, KpiName: string, KpiResult: record<Rows: list>, NextToken: string, StartTime: string>>"
    get-journey-execution-activity-metrics: "record<JourneyExecutionActivityMetricsResponse: record<ActivityType: string, ApplicationId: string, JourneyActivityId: string, JourneyId: string, LastEvaluatedTime: string, Metrics: record>>"
    get-journey-execution-metrics: "record<JourneyExecutionMetricsResponse: record<ApplicationId: string, JourneyId: string, LastEvaluatedTime: string, Metrics: record>>"
    get-segment-export-jobs: "record<ExportJobsResponse: record<Item: list<record>, NextToken: string>>"
    get-segment-import-jobs: "record<ImportJobsResponse: record<Item: list<record>, NextToken: string>>"
    get-segment-version: "record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>"
    get-segment-versions: "record<SegmentsResponse: record<Item: list<record>, NextToken: string>>"
    list-tags-for-resource: "record<TagsModel: record<tags: record>>"
    list-template-versions: "record<TemplateVersionsResponse: record<Item: list<record>, Message: string, NextToken: string, RequestID: string>>"
    list-templates: "record<TemplatesResponse: record<Item: list<record>, NextToken: string>>"
    phone-number-validate: "record<NumberValidateResponse: record<Carrier: string, City: string, CleansedPhoneNumberE164: string, CleansedPhoneNumberNational: string, Country: string, CountryCodeIso2: string, CountryCodeNumeric: string, County: string, OriginalCountryCodeIso2: string, OriginalPhoneNumber: string, PhoneType: string, PhoneTypeCode: int, Timezone: string, ZipCode: string>>"
    put-events: "record<EventsResponse: record<Results: record>>"
    remove-attributes: "record<AttributesResource: record<ApplicationId: string, AttributeType: string, Attributes: list<string>>>"
    send-messages: "record<MessageResponse: record<ApplicationId: string, EndpointResult: record, RequestId: string, Result: record>>"
    send-otp-message: "record<MessageResponse: record<ApplicationId: string, EndpointResult: record, RequestId: string, Result: record>>"
    send-users-messages: "record<SendUsersMessageResponse: record<ApplicationId: string, RequestId: string, Result: record>>"
    update-endpoints-batch: "record<MessageBody: record<Message: string, RequestID: string>>"
    update-journey-state: "record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>"
    update-template-active-version: "record<MessageBody: record<Message: string, RequestID: string>>"
    verify-otp-message: "record<VerificationResponse: record<Valid: bool>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-app" "get-apps" "create-campaign" "get-campaigns" "create-email-template" "delete-email-template" "get-email-template" "update-email-template" "create-export-job" "get-export-jobs" "create-import-job" "get-import-jobs" "create-in-app-template" "delete-in-app-template" "get-in-app-template" "update-in-app-template" "create-journey" "list-journeys" "create-push-template" "delete-push-template" "get-push-template" "update-push-template" "create-recommender-configuration" "get-recommender-configurations" "create-segment" "get-segments" "create-sms-template" "delete-sms-template" "get-sms-template" "update-sms-template" "create-voice-template" "delete-voice-template" "get-voice-template" "update-voice-template" "delete-adm-channel" "get-adm-channel" "update-adm-channel" "delete-apns-channel" "get-apns-channel" "update-apns-channel" "delete-apns-sandbox-channel" "get-apns-sandbox-channel" "update-apns-sandbox-channel" "delete-apns-voip-channel" "get-apns-voip-channel" "update-apns-voip-channel" "delete-apns-voip-sandbox-channel" "get-apns-voip-sandbox-channel" "update-apns-voip-sandbox-channel" "delete-app" "get-app" "delete-baidu-channel" "get-baidu-channel" "update-baidu-channel" "delete-campaign" "get-campaign" "update-campaign" "delete-email-channel" "get-email-channel" "update-email-channel" "delete-endpoint" "get-endpoint" "update-endpoint" "delete-event-stream" "get-event-stream" "put-event-stream" "delete-gcm-channel" "get-gcm-channel" "update-gcm-channel" "delete-journey" "get-journey" "update-journey" "delete-recommender-configuration" "get-recommender-configuration" "update-recommender-configuration" "delete-segment" "get-segment" "update-segment" "delete-sms-channel" "get-sms-channel" "update-sms-channel" "delete-user-endpoints" "get-user-endpoints" "delete-voice-channel" "get-voice-channel" "update-voice-channel" "get-application-date-range-kpi" "get-application-settings" "update-application-settings" "get-campaign-activities" "get-campaign-date-range-kpi" "get-campaign-version" "get-campaign-versions" "get-channels" "get-export-job" "get-import-job" "get-in-app-messages" "get-journey-date-range-kpi" "get-journey-execution-activity-metrics" "get-journey-execution-metrics" "get-segment-export-jobs" "get-segment-import-jobs" "get-segment-version" "get-segment-versions" "list-tags-for-resource" "tag-resource" "list-template-versions" "list-templates" "phone-number-validate" "put-events" "remove-attributes" "send-messages" "send-otp-message" "send-users-messages" "untag-resource" "update-endpoints-batch" "update-journey-state" "update-template-active-version" "verify-otp-message" "commands"] | sort) } | get name | first)
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

# Creates an application.
#
# POST /v1/apps
# Returns: record<ApplicationResponse: record<Arn: string, Id: string, Name: string, tags: record, CreationDate: string>>
# operationId: CreateApp
export def "create-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  create_application_request: record # Specifies the display name of an application and the tags to associate with the application. — shape: {Name?: string, tags?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreateApplicationRequest, var: create_application_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, create_application_request: $create_application_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about all the applications that are associated with your Amazon Pinpoint account.
#
# GET /v1/apps
# Returns: record<ApplicationsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetApps
export def "get-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps"
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new campaign for an application or updates the settings of an existing campaign for an application.
#
# POST /v1/apps/{application-id}/campaigns
# Returns: record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>
# operationId: CreateCampaign
export def "create-campaign" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_campaign_request: record # Specifies the configuration and other settings for a campaign. — shape: {AdditionalTreatments?: list, CustomDeliveryConfiguration?: record, Description?: string, HoldoutPercent?: int, Hook?: record, IsPaused?: bool, Limits?: record, MessageConfiguration?: record, Name?: string, Schedule?: record, SegmentId?: string, SegmentVersion?: int, tags?: record, TemplateConfiguration?: record, TreatmentDescription?: string, TreatmentName?: string, Priority?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/campaigns"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteCampaignRequest, var: write_campaign_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_campaign_request: $write_campaign_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status, configuration, and other settings for all the campaigns that are associated with an application.
#
# GET /v1/apps/{application-id}/campaigns
# Returns: record<CampaignsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetCampaigns
export def "get-campaigns" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/campaigns"
    path_params: [{name: application-id, var: application_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a message template for messages that are sent through the email channel.
#
# POST /v1/templates/{template-name}/email
# Returns: record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>
# operationId: CreateEmailTemplate
export def "create-email-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  email_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the email channel. — shape: {DefaultSubstitutions?: string, HtmlPart?: string, RecommenderId?: string, Subject?: string, tags?: record, TemplateDescription?: string, TextPart?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/templates/{template-name}/email"
    path_params: [{name: template-name, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EmailTemplateRequest, var: email_template_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, email_template_request: $email_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a message template for messages that were sent through the email channel.
#
# DELETE /v1/templates/{template-name}/email
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: DeleteEmailTemplate
export def "delete-email-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/email"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the content and settings of a message template for messages that are sent through the email channel.
#
# GET /v1/templates/{template-name}/email
# Returns: record<EmailTemplateResponse: record<Arn: string, CreationDate: string, DefaultSubstitutions: string, HtmlPart: string, LastModifiedDate: string, RecommenderId: string, Subject: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, TextPart: string, Version: string>>
# operationId: GetEmailTemplate
export def "get-email-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/email"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing message template for messages that are sent through the email channel.
#
# PUT /v1/templates/{template-name}/email
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdateEmailTemplate
export def "update-email-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  email_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the email channel. — shape: {DefaultSubstitutions?: string, HtmlPart?: string, RecommenderId?: string, Subject?: string, tags?: record, TemplateDescription?: string, TextPart?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/templates/{template-name}/email"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: create-new-version, var: create_new_version}, {name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EmailTemplateRequest, var: email_template_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, create_new_version: $create_new_version, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, email_template_request: $email_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an export job for an application.
#
# POST /v1/apps/{application-id}/jobs/export
# Returns: record<ExportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<RoleArn: string, S3UrlPrefix: string, SegmentId: string, SegmentVersion: int>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>
# operationId: CreateExportJob
export def "create-export-job" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  export_job_request: record # Specifies the settings for a job that exports endpoint definitions to an Amazon Simple Storage Service (Amazon S3) bucket. — shape: {RoleArn?: string, S3UrlPrefix?: string, SegmentId?: string, SegmentVersion?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/jobs/export"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExportJobRequest, var: export_job_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, export_job_request: $export_job_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of all the export jobs for an application.
#
# GET /v1/apps/{application-id}/jobs/export
# Returns: record<ExportJobsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetExportJobs
export def "get-export-jobs" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/jobs/export"
    path_params: [{name: application-id, var: application_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an import job for an application.
#
# POST /v1/apps/{application-id}/jobs/import
# Returns: record<ImportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<DefineSegment: bool, ExternalId: string, Format: string, RegisterEndpoints: bool, RoleArn: string, S3Url: string, SegmentId: string, SegmentName: string>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>
# operationId: CreateImportJob
export def "create-import-job" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  import_job_request: record # Specifies the settings for a job that imports endpoint definitions from an Amazon Simple Storage Service (Amazon S3) bucket. — shape: {DefineSegment?: bool, ExternalId?: string, Format?: "CSV"|"JSON", RegisterEndpoints?: bool, RoleArn?: string, S3Url?: string, SegmentId?: string, SegmentName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/jobs/import"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ImportJobRequest, var: import_job_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, import_job_request: $import_job_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of all the import jobs for an application.
#
# GET /v1/apps/{application-id}/jobs/import
# Returns: record<ImportJobsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetImportJobs
export def "get-import-jobs" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/jobs/import"
    path_params: [{name: application-id, var: application_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new message template for messages using the in-app message channel.
#
# POST /v1/templates/{template-name}/inapp
# Returns: record<TemplateCreateMessageBody: record<Arn: string, Message: string, RequestID: string>>
# operationId: CreateInAppTemplate
export def "create-in-app-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  in_app_template_request: record # InApp Template Request. — shape: {Content?: list, CustomConfig?: record, Layout?: "BOTTOM_BANNER"|"TOP_BANNER"|"OVERLAYS"|"MOBILE_FEED"|"MIDDLE_BANNER"|"CAROUSEL", tags?: record, TemplateDescription?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/templates/{template-name}/inapp"
    path_params: [{name: template-name, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InAppTemplateRequest, var: in_app_template_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, in_app_template_request: $in_app_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a message template for messages sent using the in-app message channel.
#
# DELETE /v1/templates/{template-name}/inapp
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: DeleteInAppTemplate
export def "delete-in-app-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/inapp"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the content and settings of a message template for messages sent through the in-app channel.
#
# GET /v1/templates/{template-name}/inapp
# Returns: record<InAppTemplateResponse: record<Arn: string, Content: list<record>, CreationDate: string, CustomConfig: record, LastModifiedDate: string, Layout: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string>>
# operationId: GetInAppTemplate
export def "get-in-app-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/inapp"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing message template for messages sent through the in-app message channel.
#
# PUT /v1/templates/{template-name}/inapp
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdateInAppTemplate
export def "update-in-app-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  in_app_template_request: record # InApp Template Request. — shape: {Content?: list, CustomConfig?: record, Layout?: "BOTTOM_BANNER"|"TOP_BANNER"|"OVERLAYS"|"MOBILE_FEED"|"MIDDLE_BANNER"|"CAROUSEL", tags?: record, TemplateDescription?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/templates/{template-name}/inapp"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: create-new-version, var: create_new_version}, {name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: InAppTemplateRequest, var: in_app_template_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, create_new_version: $create_new_version, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, in_app_template_request: $in_app_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a journey for an application.
#
# POST /v1/apps/{application-id}/journeys
# Returns: record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>
# operationId: CreateJourney
export def "create-journey" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_journey_request: record # Specifies the configuration and other settings for a journey. — shape: {Activities?: record, CreationDate?: string, LastModifiedDate?: string, Limits?: record, LocalTime?: bool, Name?: string, QuietTime?: record, RefreshFrequency?: string, Schedule?: record, StartActivity?: string, StartCondition?: record, State?: "DRAFT"|"ACTIVE"|"COMPLETED"|"CANCELLED"|"CLOSED"|"PAUSED", WaitForQuietTime?: bool, RefreshOnSegmentUpdate?: bool, JourneyChannelSettings?: record, SendingSchedule?: bool, OpenHours?: record, ClosedDays?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/journeys"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteJourneyRequest, var: write_journey_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_journey_request: $write_journey_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status, configuration, and other settings for all the journeys that are associated with an application.
#
# GET /v1/apps/{application-id}/journeys
# Returns: record<JourneysResponse: record<Item: list<record>, NextToken: string>>
# operationId: ListJourneys
export def "list-journeys" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/journeys"
    path_params: [{name: application-id, var: application_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a message template for messages that are sent through a push notification channel.
#
# POST /v1/templates/{template-name}/push
# Returns: record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>
# operationId: CreatePushTemplate
export def "create-push-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  push_notification_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through a push notification channel. — shape: {ADM?: record, APNS?: record, Baidu?: record, Default?: record, DefaultSubstitutions?: string, GCM?: record, RecommenderId?: string, tags?: record, TemplateDescription?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/templates/{template-name}/push"
    path_params: [{name: template-name, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PushNotificationTemplateRequest, var: push_notification_template_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, push_notification_template_request: $push_notification_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a message template for messages that were sent through a push notification channel.
#
# DELETE /v1/templates/{template-name}/push
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: DeletePushTemplate
export def "delete-push-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/push"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the content and settings of a message template for messages that are sent through a push notification channel.
#
# GET /v1/templates/{template-name}/push
# Returns: record<PushNotificationTemplateResponse: record<ADM: record<Action: string, Body: string, ImageIconUrl: string, ImageUrl: string, RawContent: string, SmallImageIconUrl: string, Sound: string, Title: string, Url: string>, APNS: record<Action: string, Body: string, MediaUrl: string, RawContent: string, Sound: string, Title: string, Url: string>, Arn: string, Baidu: record<Action: string, Body: string, ImageIconUrl: string, ImageUrl: string, RawContent: string, SmallImageIconUrl: string, Sound: string, Title: string, Url: string>, CreationDate: string, Default: record<Action: string, Body: string, Sound: string, Title: string, Url: string>, DefaultSubstitutions: string, GCM: record<Action: string, Body: string, ImageIconUrl: string, ImageUrl: string, RawContent: string, SmallImageIconUrl: string, Sound: string, Title: string, Url: string>, LastModifiedDate: string, RecommenderId: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string>>
# operationId: GetPushTemplate
export def "get-push-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/push"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing message template for messages that are sent through a push notification channel.
#
# PUT /v1/templates/{template-name}/push
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdatePushTemplate
export def "update-push-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  push_notification_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through a push notification channel. — shape: {ADM?: record, APNS?: record, Baidu?: record, Default?: record, DefaultSubstitutions?: string, GCM?: record, RecommenderId?: string, tags?: record, TemplateDescription?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/templates/{template-name}/push"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: create-new-version, var: create_new_version}, {name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PushNotificationTemplateRequest, var: push_notification_template_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, create_new_version: $create_new_version, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, push_notification_template_request: $push_notification_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Pinpoint configuration for a recommender model.
#
# POST /v1/recommenders
# Returns: record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>
# operationId: CreateRecommenderConfiguration
export def "create-recommender-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  create_recommender_configuration: record # Specifies Amazon Pinpoint configuration settings for retrieving and processing recommendation data from a recommender model. — shape: {Attributes?: record, Description?: string, Name?: string, RecommendationProviderIdType?: string, RecommendationProviderRoleArn?: string, RecommendationProviderUri?: string, RecommendationTransformerUri?: string, RecommendationsDisplayName?: string, RecommendationsPerMessage?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/recommenders"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreateRecommenderConfiguration, var: create_recommender_configuration}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, create_recommender_configuration: $create_recommender_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about all the recommender model configurations that are associated with your Amazon Pinpoint account.
#
# GET /v1/recommenders
# Returns: record<ListRecommenderConfigurationsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetRecommenderConfigurations
export def "get-recommender-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/recommenders"
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
#
# POST /v1/apps/{application-id}/segments
# Returns: record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>
# operationId: CreateSegment
export def "create-segment" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_segment_request: record # Specifies the configuration, dimension, and other settings for a segment. A WriteSegmentRequest object can include a Dimensions object or a SegmentGroups object, but not both. — shape: {Dimensions?: record, Name?: string, SegmentGroups?: record, tags?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/segments"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteSegmentRequest, var: write_segment_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_segment_request: $write_segment_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the configuration, dimension, and other settings for all the segments that are associated with an application.
#
# GET /v1/apps/{application-id}/segments
# Returns: record<SegmentsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetSegments
export def "get-segments" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/segments"
    path_params: [{name: application-id, var: application_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a message template for messages that are sent through the SMS channel.
#
# POST /v1/templates/{template-name}/sms
# Returns: record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>
# operationId: CreateSmsTemplate
export def "create-sms-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  sms_template_request: record # Specifies the content and settings for a message template that can be used in text messages that are sent through the SMS channel. — shape: {Body?: string, DefaultSubstitutions?: string, RecommenderId?: string, tags?: record, TemplateDescription?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/templates/{template-name}/sms"
    path_params: [{name: template-name, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SMSTemplateRequest, var: sms_template_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sms_template_request: $sms_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a message template for messages that were sent through the SMS channel.
#
# DELETE /v1/templates/{template-name}/sms
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: DeleteSmsTemplate
export def "delete-sms-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/sms"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the content and settings of a message template for messages that are sent through the SMS channel.
#
# GET /v1/templates/{template-name}/sms
# Returns: record<SMSTemplateResponse: record<Arn: string, Body: string, CreationDate: string, DefaultSubstitutions: string, LastModifiedDate: string, RecommenderId: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string>>
# operationId: GetSmsTemplate
export def "get-sms-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/sms"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing message template for messages that are sent through the SMS channel.
#
# PUT /v1/templates/{template-name}/sms
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdateSmsTemplate
export def "update-sms-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  sms_template_request: record # Specifies the content and settings for a message template that can be used in text messages that are sent through the SMS channel. — shape: {Body?: string, DefaultSubstitutions?: string, RecommenderId?: string, tags?: record, TemplateDescription?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/templates/{template-name}/sms"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: create-new-version, var: create_new_version}, {name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SMSTemplateRequest, var: sms_template_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, create_new_version: $create_new_version, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sms_template_request: $sms_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a message template for messages that are sent through the voice channel.
#
# POST /v1/templates/{template-name}/voice
# Returns: record<CreateTemplateMessageBody: record<Arn: string, Message: string, RequestID: string>>
# operationId: CreateVoiceTemplate
export def "create-voice-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  voice_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the voice channel. — shape: {Body?: string, DefaultSubstitutions?: string, LanguageCode?: string, tags?: record, TemplateDescription?: string, VoiceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/templates/{template-name}/voice"
    path_params: [{name: template-name, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: VoiceTemplateRequest, var: voice_template_request}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, voice_template_request: $voice_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a message template for messages that were sent through the voice channel.
#
# DELETE /v1/templates/{template-name}/voice
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: DeleteVoiceTemplate
export def "delete-voice-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/voice"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the content and settings of a message template for messages that are sent through the voice channel.
#
# GET /v1/templates/{template-name}/voice
# Returns: record<VoiceTemplateResponse: record<Arn: string, Body: string, CreationDate: string, DefaultSubstitutions: string, LanguageCode: string, LastModifiedDate: string, tags: record, TemplateDescription: string, TemplateName: string, TemplateType: string, Version: string, VoiceId: string>>
# operationId: GetVoiceTemplate
export def "get-voice-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
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
    path: "/v1/templates/{template-name}/voice"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing message template for messages that are sent through the voice channel.
#
# PUT /v1/templates/{template-name}/voice
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdateVoiceTemplate
export def "update-voice-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-new-version: oneof<nothing, bool> # Specifies whether to save the updates as a new version of the message template. Valid values are: true, save the updates as a new version; and, false, save the updates to (overwrite) the latest existing version of the template. If you don't specify a value for this parameter, Amazon Pinpoint saves the updates to (overwrites) the latest existing version of the template. If you specify a value of true for this parameter, don't specify a value for the version parameter. Otherwise, an error will occur.
  --version: string # The unique identifier for the version of the message template to update, retrieve information about, or delete. To retrieve identifiers and other information for all the versions of a template, use the Template Versions resource. If specified, this value must match the identifier for an existing template version. If specified for an update operation, this value must match the identifier for the latest existing version of the template. This restriction helps ensure that race conditions don't occur. If you don't specify a value for this parameter, Amazon Pinpoint does the following: For a get operation, retrieves information about the active version of the template. For an update operation, saves the updates to (overwrites) the latest existing version of the template, if the create-new-version parameter isn't used or is set to false. For a delete operation, deletes the template, including all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  voice_template_request: record # Specifies the content and settings for a message template that can be used in messages that are sent through the voice channel. — shape: {Body?: string, DefaultSubstitutions?: string, LanguageCode?: string, tags?: record, TemplateDescription?: string, VoiceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/templates/{template-name}/voice"
    path_params: [{name: template-name, var: template_name}]
    query: [{name: create-new-version, var: create_new_version}, {name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: VoiceTemplateRequest, var: voice_template_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    template_name: $template_name, create_new_version: $create_new_version, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, voice_template_request: $voice_template_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the ADM channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/adm
# Returns: record<ADMChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteAdmChannel
export def "delete-adm-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/adm"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the ADM channel for an application.
#
# GET /v1/apps/{application-id}/channels/adm
# Returns: record<ADMChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetAdmChannel
export def "get-adm-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/adm"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the ADM channel for an application or updates the status and settings of the ADM channel for an application.
#
# PUT /v1/apps/{application-id}/channels/adm
# Returns: record<ADMChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateAdmChannel
export def "update-adm-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  adm_channel_request: record # Specifies the status and settings of the ADM (Amazon Device Messaging) channel for an application. — shape: {ClientId?: string, ClientSecret?: string, Enabled?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/adm"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ADMChannelRequest, var: adm_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, adm_channel_request: $adm_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the APNs channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns
# Returns: record<APNSChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteApnsChannel
export def "delete-apns-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the APNs channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns
# Returns: record<APNSChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetApnsChannel
export def "get-apns-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the APNs channel for an application or updates the status and settings of the APNs channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns
# Returns: record<APNSChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateApnsChannel
export def "update-apns-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  apns_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) channel for an application. — shape: {BundleId?: string, Certificate?: string, DefaultAuthenticationMethod?: string, Enabled?: bool, PrivateKey?: string, TeamId?: string, TokenKey?: string, TokenKeyId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/apns"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: APNSChannelRequest, var: apns_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, apns_channel_request: $apns_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the APNs sandbox channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns_sandbox
# Returns: record<APNSSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteApnsSandboxChannel
export def "delete-apns-sandbox-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns_sandbox"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the APNs sandbox channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns_sandbox
# Returns: record<APNSSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetApnsSandboxChannel
export def "get-apns-sandbox-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns_sandbox"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the APNs sandbox channel for an application or updates the status and settings of the APNs sandbox channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns_sandbox
# Returns: record<APNSSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateApnsSandboxChannel
export def "update-apns-sandbox-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  apns_sandbox_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) sandbox channel for an application. — shape: {BundleId?: string, Certificate?: string, DefaultAuthenticationMethod?: string, Enabled?: bool, PrivateKey?: string, TeamId?: string, TokenKey?: string, TokenKeyId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/apns_sandbox"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: APNSSandboxChannelRequest, var: apns_sandbox_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, apns_sandbox_channel_request: $apns_sandbox_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the APNs VoIP channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns_voip
# Returns: record<APNSVoipChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteApnsVoipChannel
export def "delete-apns-voip-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns_voip"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the APNs VoIP channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns_voip
# Returns: record<APNSVoipChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetApnsVoipChannel
export def "get-apns-voip-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns_voip"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the APNs VoIP channel for an application or updates the status and settings of the APNs VoIP channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns_voip
# Returns: record<APNSVoipChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateApnsVoipChannel
export def "update-apns-voip-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  apns_voip_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) VoIP channel for an application. — shape: {BundleId?: string, Certificate?: string, DefaultAuthenticationMethod?: string, Enabled?: bool, PrivateKey?: string, TeamId?: string, TokenKey?: string, TokenKeyId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/apns_voip"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: APNSVoipChannelRequest, var: apns_voip_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, apns_voip_channel_request: $apns_voip_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the APNs VoIP sandbox channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/apns_voip_sandbox
# Returns: record<APNSVoipSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteApnsVoipSandboxChannel
export def "delete-apns-voip-sandbox-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns_voip_sandbox"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the APNs VoIP sandbox channel for an application.
#
# GET /v1/apps/{application-id}/channels/apns_voip_sandbox
# Returns: record<APNSVoipSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetApnsVoipSandboxChannel
export def "get-apns-voip-sandbox-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/apns_voip_sandbox"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the APNs VoIP sandbox channel for an application or updates the status and settings of the APNs VoIP sandbox channel for an application.
#
# PUT /v1/apps/{application-id}/channels/apns_voip_sandbox
# Returns: record<APNSVoipSandboxChannelResponse: record<ApplicationId: string, CreationDate: string, DefaultAuthenticationMethod: string, Enabled: bool, HasCredential: bool, HasTokenKey: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateApnsVoipSandboxChannel
export def "update-apns-voip-sandbox-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  apns_voip_sandbox_channel_request: record # Specifies the status and settings of the APNs (Apple Push Notification service) VoIP sandbox channel for an application. — shape: {BundleId?: string, Certificate?: string, DefaultAuthenticationMethod?: string, Enabled?: bool, PrivateKey?: string, TeamId?: string, TokenKey?: string, TokenKeyId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/apns_voip_sandbox"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: APNSVoipSandboxChannelRequest, var: apns_voip_sandbox_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, apns_voip_sandbox_channel_request: $apns_voip_sandbox_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an application.
#
# DELETE /v1/apps/{application-id}
# Returns: record<ApplicationResponse: record<Arn: string, Id: string, Name: string, tags: record, CreationDate: string>>
# operationId: DeleteApp
export def "delete-app" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about an application.
#
# GET /v1/apps/{application-id}
# Returns: record<ApplicationResponse: record<Arn: string, Id: string, Name: string, tags: record, CreationDate: string>>
# operationId: GetApp
export def "get-app" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the Baidu channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/baidu
# Returns: record<BaiduChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteBaiduChannel
export def "delete-baidu-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/baidu"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the Baidu channel for an application.
#
# GET /v1/apps/{application-id}/channels/baidu
# Returns: record<BaiduChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetBaiduChannel
export def "get-baidu-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/baidu"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the Baidu channel for an application or updates the status and settings of the Baidu channel for an application.
#
# PUT /v1/apps/{application-id}/channels/baidu
# Returns: record<BaiduChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateBaiduChannel
export def "update-baidu-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  baidu_channel_request: record # Specifies the status and settings of the Baidu (Baidu Cloud Push) channel for an application. — shape: {ApiKey?: string, Enabled?: bool, SecretKey?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/baidu"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: BaiduChannelRequest, var: baidu_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, baidu_channel_request: $baidu_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a campaign from an application.
#
# DELETE /v1/apps/{application-id}/campaigns/{campaign-id}
# Returns: record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>
# operationId: DeleteCampaign
export def "delete-campaign" [
  application_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/campaigns/{campaign-id}"
    path_params: [{name: application-id, var: application_id}, {name: campaign-id, var: campaign_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, campaign_id: $campaign_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status, configuration, and other settings for a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}
# Returns: record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>
# operationId: GetCampaign
export def "get-campaign" [
  application_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/campaigns/{campaign-id}"
    path_params: [{name: application-id, var: application_id}, {name: campaign-id, var: campaign_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, campaign_id: $campaign_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration and other settings for a campaign.
#
# PUT /v1/apps/{application-id}/campaigns/{campaign-id}
# Returns: record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>
# operationId: UpdateCampaign
export def "update-campaign" [
  application_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_campaign_request: record # Specifies the configuration and other settings for a campaign. — shape: {AdditionalTreatments?: list, CustomDeliveryConfiguration?: record, Description?: string, HoldoutPercent?: int, Hook?: record, IsPaused?: bool, Limits?: record, MessageConfiguration?: record, Name?: string, Schedule?: record, SegmentId?: string, SegmentVersion?: int, tags?: record, TemplateConfiguration?: record, TreatmentDescription?: string, TreatmentName?: string, Priority?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/campaigns/{campaign-id}"
    path_params: [{name: application-id, var: application_id}, {name: campaign-id, var: campaign_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteCampaignRequest, var: write_campaign_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, campaign_id: $campaign_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_campaign_request: $write_campaign_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the email channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/email
# Returns: record<EmailChannelResponse: record<ApplicationId: string, ConfigurationSet: string, CreationDate: string, Enabled: bool, FromAddress: string, HasCredential: bool, Id: string, Identity: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, MessagesPerSecond: int, Platform: string, RoleArn: string, Version: int>>
# operationId: DeleteEmailChannel
export def "delete-email-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/email"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the email channel for an application.
#
# GET /v1/apps/{application-id}/channels/email
# Returns: record<EmailChannelResponse: record<ApplicationId: string, ConfigurationSet: string, CreationDate: string, Enabled: bool, FromAddress: string, HasCredential: bool, Id: string, Identity: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, MessagesPerSecond: int, Platform: string, RoleArn: string, Version: int>>
# operationId: GetEmailChannel
export def "get-email-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/email"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the email channel for an application or updates the status and settings of the email channel for an application.
#
# PUT /v1/apps/{application-id}/channels/email
# Returns: record<EmailChannelResponse: record<ApplicationId: string, ConfigurationSet: string, CreationDate: string, Enabled: bool, FromAddress: string, HasCredential: bool, Id: string, Identity: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, MessagesPerSecond: int, Platform: string, RoleArn: string, Version: int>>
# operationId: UpdateEmailChannel
export def "update-email-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  email_channel_request: record # Specifies the status and settings of the email channel for an application. — shape: {ConfigurationSet?: string, Enabled?: bool, FromAddress?: string, Identity?: string, RoleArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/email"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EmailChannelRequest, var: email_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, email_channel_request: $email_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an endpoint from an application.
#
# DELETE /v1/apps/{application-id}/endpoints/{endpoint-id}
# Returns: record<EndpointResponse: record<Address: string, ApplicationId: string, Attributes: record, ChannelType: string, CohortId: string, CreationDate: string, Demographic: record<AppVersion: string, Locale: string, Make: string, Model: string, ModelVersion: string, Platform: string, PlatformVersion: string, Timezone: string>, EffectiveDate: string, EndpointStatus: string, Id: string, Location: record<City: string, Country: string, Latitude: float, Longitude: float, PostalCode: string, Region: string>, Metrics: record, OptOut: string, RequestId: string, User: record<UserAttributes: record, UserId: string>>>
# operationId: DeleteEndpoint
export def "delete-endpoint" [
  application_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/endpoints/{endpoint-id}"
    path_params: [{name: application-id, var: application_id}, {name: endpoint-id, var: endpoint_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, endpoint_id: $endpoint_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the settings and attributes of a specific endpoint for an application.
#
# GET /v1/apps/{application-id}/endpoints/{endpoint-id}
# Returns: record<EndpointResponse: record<Address: string, ApplicationId: string, Attributes: record, ChannelType: string, CohortId: string, CreationDate: string, Demographic: record<AppVersion: string, Locale: string, Make: string, Model: string, ModelVersion: string, Platform: string, PlatformVersion: string, Timezone: string>, EffectiveDate: string, EndpointStatus: string, Id: string, Location: record<City: string, Country: string, Latitude: float, Longitude: float, PostalCode: string, Region: string>, Metrics: record, OptOut: string, RequestId: string, User: record<UserAttributes: record, UserId: string>>>
# operationId: GetEndpoint
export def "get-endpoint" [
  application_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/endpoints/{endpoint-id}"
    path_params: [{name: application-id, var: application_id}, {name: endpoint-id, var: endpoint_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, endpoint_id: $endpoint_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new endpoint for an application or updates the settings and attributes of an existing endpoint for an application. You can also use this operation to define custom attributes for an endpoint. If an update includes one or more values for a custom attribute, Amazon Pinpoint replaces (overwrites) any existing values with the new values.
#
# PUT /v1/apps/{application-id}/endpoints/{endpoint-id}
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdateEndpoint
export def "update-endpoint" [
  application_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  endpoint_request: record # Specifies the channel type and other settings for an endpoint. — shape: {Address?: string, Attributes?: record, ChannelType?: "PUSH"|"GCM"|"APNS"|"APNS_SANDBOX"|"APNS_VOIP"|"APNS_VOIP_SANDBOX"|"ADM"|"SMS"|"VOICE"|"EMAIL"|"BAIDU"|"CUSTOM"|"IN_APP", Demographic?: record, EffectiveDate?: string, EndpointStatus?: string, Location?: record, Metrics?: record, OptOut?: string, RequestId?: string, User?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/endpoints/{endpoint-id}"
    path_params: [{name: application-id, var: application_id}, {name: endpoint-id, var: endpoint_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointRequest, var: endpoint_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, endpoint_id: $endpoint_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, endpoint_request: $endpoint_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the event stream for an application.
#
# DELETE /v1/apps/{application-id}/eventstream
# Returns: record<EventStream: record<ApplicationId: string, DestinationStreamArn: string, ExternalId: string, LastModifiedDate: string, LastUpdatedBy: string, RoleArn: string>>
# operationId: DeleteEventStream
export def "delete-event-stream" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/eventstream"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the event stream settings for an application.
#
# GET /v1/apps/{application-id}/eventstream
# Returns: record<EventStream: record<ApplicationId: string, DestinationStreamArn: string, ExternalId: string, LastModifiedDate: string, LastUpdatedBy: string, RoleArn: string>>
# operationId: GetEventStream
export def "get-event-stream" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/eventstream"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new event stream for an application or updates the settings of an existing event stream for an application.
#
# POST /v1/apps/{application-id}/eventstream
# Returns: record<EventStream: record<ApplicationId: string, DestinationStreamArn: string, ExternalId: string, LastModifiedDate: string, LastUpdatedBy: string, RoleArn: string>>
# operationId: PutEventStream
export def "put-event-stream" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_event_stream: record # Specifies the Amazon Resource Name (ARN) of an event stream to publish events to and the AWS Identity and Access Management (IAM) role to use when publishing those events. — shape: {DestinationStreamArn?: string, RoleArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/eventstream"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteEventStream, var: write_event_stream}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_event_stream: $write_event_stream
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the GCM channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/gcm
# Returns: record<GCMChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteGcmChannel
export def "delete-gcm-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/gcm"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the GCM channel for an application.
#
# GET /v1/apps/{application-id}/channels/gcm
# Returns: record<GCMChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetGcmChannel
export def "get-gcm-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/gcm"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the GCM channel for an application or updates the status and settings of the GCM channel for an application.
#
# PUT /v1/apps/{application-id}/channels/gcm
# Returns: record<GCMChannelResponse: record<ApplicationId: string, CreationDate: string, Credential: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateGcmChannel
export def "update-gcm-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  gcm_channel_request: record # Specifies the status and settings of the GCM channel for an application. This channel enables Amazon Pinpoint to send push notifications through the Firebase Cloud Messaging (FCM), formerly Google Cloud Messaging (GCM), service. — shape: {ApiKey?: string, Enabled?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/gcm"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GCMChannelRequest, var: gcm_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, gcm_channel_request: $gcm_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a journey from an application.
#
# DELETE /v1/apps/{application-id}/journeys/{journey-id}
# Returns: record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>
# operationId: DeleteJourney
export def "delete-journey" [
  application_id: string
  journey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/journeys/{journey-id}"
    path_params: [{name: application-id, var: application_id}, {name: journey-id, var: journey_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, journey_id: $journey_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status, configuration, and other settings for a journey.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}
# Returns: record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>
# operationId: GetJourney
export def "get-journey" [
  application_id: string
  journey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/journeys/{journey-id}"
    path_params: [{name: application-id, var: application_id}, {name: journey-id, var: journey_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, journey_id: $journey_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration and other settings for a journey.
#
# PUT /v1/apps/{application-id}/journeys/{journey-id}
# Returns: record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>
# operationId: UpdateJourney
export def "update-journey" [
  application_id: string
  journey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_journey_request: record # Specifies the configuration and other settings for a journey. — shape: {Activities?: record, CreationDate?: string, LastModifiedDate?: string, Limits?: record, LocalTime?: bool, Name?: string, QuietTime?: record, RefreshFrequency?: string, Schedule?: record, StartActivity?: string, StartCondition?: record, State?: "DRAFT"|"ACTIVE"|"COMPLETED"|"CANCELLED"|"CLOSED"|"PAUSED", WaitForQuietTime?: bool, RefreshOnSegmentUpdate?: bool, JourneyChannelSettings?: record, SendingSchedule?: bool, OpenHours?: record, ClosedDays?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/journeys/{journey-id}"
    path_params: [{name: application-id, var: application_id}, {name: journey-id, var: journey_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteJourneyRequest, var: write_journey_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, journey_id: $journey_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_journey_request: $write_journey_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon Pinpoint configuration for a recommender model.
#
# DELETE /v1/recommenders/{recommender-id}
# Returns: record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>
# operationId: DeleteRecommenderConfiguration
export def "delete-recommender-configuration" [
  recommender_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/recommenders/{recommender-id}"
    path_params: [{name: recommender-id, var: recommender_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    recommender_id: $recommender_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about an Amazon Pinpoint configuration for a recommender model.
#
# GET /v1/recommenders/{recommender-id}
# Returns: record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>
# operationId: GetRecommenderConfiguration
export def "get-recommender-configuration" [
  recommender_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/recommenders/{recommender-id}"
    path_params: [{name: recommender-id, var: recommender_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    recommender_id: $recommender_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon Pinpoint configuration for a recommender model.
#
# PUT /v1/recommenders/{recommender-id}
# Returns: record<RecommenderConfigurationResponse: record<Attributes: record, CreationDate: string, Description: string, Id: string, LastModifiedDate: string, Name: string, RecommendationProviderIdType: string, RecommendationProviderRoleArn: string, RecommendationProviderUri: string, RecommendationTransformerUri: string, RecommendationsDisplayName: string, RecommendationsPerMessage: int>>
# operationId: UpdateRecommenderConfiguration
export def "update-recommender-configuration" [
  recommender_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  update_recommender_configuration: record # Specifies Amazon Pinpoint configuration settings for retrieving and processing recommendation data from a recommender model. — shape: {Attributes?: record, Description?: string, Name?: string, RecommendationProviderIdType?: string, RecommendationProviderRoleArn?: string, RecommendationProviderUri?: string, RecommendationTransformerUri?: string, RecommendationsDisplayName?: string, RecommendationsPerMessage?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/recommenders/{recommender-id}"
    path_params: [{name: recommender-id, var: recommender_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UpdateRecommenderConfiguration, var: update_recommender_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    recommender_id: $recommender_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, update_recommender_configuration: $update_recommender_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a segment from an application.
#
# DELETE /v1/apps/{application-id}/segments/{segment-id}
# Returns: record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>
# operationId: DeleteSegment
export def "delete-segment" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/segments/{segment-id}"
    path_params: [{name: application-id, var: application_id}, {name: segment-id, var: segment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, segment_id: $segment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the configuration, dimension, and other settings for a specific segment that's associated with an application.
#
# GET /v1/apps/{application-id}/segments/{segment-id}
# Returns: record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>
# operationId: GetSegment
export def "get-segment" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/segments/{segment-id}"
    path_params: [{name: application-id, var: application_id}, {name: segment-id, var: segment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, segment_id: $segment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new segment for an application or updates the configuration, dimension, and other settings for an existing segment that's associated with an application.
#
# PUT /v1/apps/{application-id}/segments/{segment-id}
# Returns: record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>
# operationId: UpdateSegment
export def "update-segment" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_segment_request: record # Specifies the configuration, dimension, and other settings for a segment. A WriteSegmentRequest object can include a Dimensions object or a SegmentGroups object, but not both. — shape: {Dimensions?: record, Name?: string, SegmentGroups?: record, tags?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/segments/{segment-id}"
    path_params: [{name: application-id, var: application_id}, {name: segment-id, var: segment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteSegmentRequest, var: write_segment_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, segment_id: $segment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_segment_request: $write_segment_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the SMS channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/sms
# Returns: record<SMSChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, PromotionalMessagesPerSecond: int, SenderId: string, ShortCode: string, TransactionalMessagesPerSecond: int, Version: int>>
# operationId: DeleteSmsChannel
export def "delete-sms-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/sms"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the SMS channel for an application.
#
# GET /v1/apps/{application-id}/channels/sms
# Returns: record<SMSChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, PromotionalMessagesPerSecond: int, SenderId: string, ShortCode: string, TransactionalMessagesPerSecond: int, Version: int>>
# operationId: GetSmsChannel
export def "get-sms-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/sms"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the SMS channel for an application or updates the status and settings of the SMS channel for an application.
#
# PUT /v1/apps/{application-id}/channels/sms
# Returns: record<SMSChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, PromotionalMessagesPerSecond: int, SenderId: string, ShortCode: string, TransactionalMessagesPerSecond: int, Version: int>>
# operationId: UpdateSmsChannel
export def "update-sms-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  sms_channel_request: record # Specifies the status and settings of the SMS channel for an application. — shape: {Enabled?: bool, SenderId?: string, ShortCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/sms"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SMSChannelRequest, var: sms_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sms_channel_request: $sms_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all the endpoints that are associated with a specific user ID.
#
# DELETE /v1/apps/{application-id}/users/{user-id}
# Returns: record<EndpointsResponse: record<Item: list<record>>>
# operationId: DeleteUserEndpoints
export def "delete-user-endpoints" [
  application_id: string
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
    method: delete
    path: "/v1/apps/{application-id}/users/{user-id}"
    path_params: [{name: application-id, var: application_id}, {name: user-id, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about all the endpoints that are associated with a specific user ID.
#
# GET /v1/apps/{application-id}/users/{user-id}
# Returns: record<EndpointsResponse: record<Item: list<record>>>
# operationId: GetUserEndpoints
export def "get-user-endpoints" [
  application_id: string
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
    path: "/v1/apps/{application-id}/users/{user-id}"
    path_params: [{name: application-id, var: application_id}, {name: user-id, var: user_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, user_id: $user_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the voice channel for an application and deletes any existing settings for the channel.
#
# DELETE /v1/apps/{application-id}/channels/voice
# Returns: record<VoiceChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: DeleteVoiceChannel
export def "delete-voice-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/voice"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the voice channel for an application.
#
# GET /v1/apps/{application-id}/channels/voice
# Returns: record<VoiceChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: GetVoiceChannel
export def "get-voice-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels/voice"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the voice channel for an application or updates the status and settings of the voice channel for an application.
#
# PUT /v1/apps/{application-id}/channels/voice
# Returns: record<VoiceChannelResponse: record<ApplicationId: string, CreationDate: string, Enabled: bool, HasCredential: bool, Id: string, IsArchived: bool, LastModifiedBy: string, LastModifiedDate: string, Platform: string, Version: int>>
# operationId: UpdateVoiceChannel
export def "update-voice-channel" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  voice_channel_request: record # Specifies the status and settings of the voice channel for an application. — shape: {Enabled?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/channels/voice"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: VoiceChannelRequest, var: voice_channel_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, voice_channel_request: $voice_channel_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves (queries) pre-aggregated data for a standard metric that applies to an application.
#
# GET /v1/apps/{application-id}/kpis/daterange/{kpi-name}
# Returns: record<ApplicationDateRangeKpiResponse: record<ApplicationId: string, EndTime: string, KpiName: string, KpiResult: record<Rows: list>, NextToken: string, StartTime: string>>
# operationId: GetApplicationDateRangeKpi
export def "get-application-date-range-kpi" [
  application_id: string
  kpi_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019. (format: date-time)
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --start-time: string # The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day. (format: date-time)
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
    path: "/v1/apps/{application-id}/kpis/daterange/{kpi-name}"
    path_params: [{name: application-id, var: application_id}, {name: kpi-name, var: kpi_name}]
    query: [{name: end-time, var: end_time}, {name: next-token, var: next_token}, {name: page-size, var: page_size}, {name: start-time, var: start_time}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, kpi_name: $kpi_name, end_time: $end_time, next_token: $next_token, page_size: $page_size, start_time: $start_time, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the settings for an application.
#
# GET /v1/apps/{application-id}/settings
# Returns: record<ApplicationSettingsResource: record<ApplicationId: string, CampaignHook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, QuietTime: record<End: string, Start: string>>>
# operationId: GetApplicationSettings
export def "get-application-settings" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/settings"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings for an application.
#
# PUT /v1/apps/{application-id}/settings
# Returns: record<ApplicationSettingsResource: record<ApplicationId: string, CampaignHook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, QuietTime: record<End: string, Start: string>>>
# operationId: UpdateApplicationSettings
export def "update-application-settings" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  write_application_settings_request: record # Specifies the default settings for an application. — shape: {CampaignHook?: record, CloudWatchMetricsEnabled?: bool, EventTaggingEnabled?: bool, Limits?: record, QuietTime?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/settings"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WriteApplicationSettingsRequest, var: write_application_settings_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, write_application_settings_request: $write_application_settings_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about all the activities for a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/activities
# Returns: record<ActivitiesResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetCampaignActivities
export def "get-campaign-activities" [
  application_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/campaigns/{campaign-id}/activities"
    path_params: [{name: application-id, var: application_id}, {name: campaign-id, var: campaign_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, campaign_id: $campaign_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves (queries) pre-aggregated data for a standard metric that applies to a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}
# Returns: record<CampaignDateRangeKpiResponse: record<ApplicationId: string, CampaignId: string, EndTime: string, KpiName: string, KpiResult: record<Rows: list>, NextToken: string, StartTime: string>>
# operationId: GetCampaignDateRangeKpi
export def "get-campaign-date-range-kpi" [
  application_id: string
  campaign_id: string
  kpi_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019. (format: date-time)
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --start-time: string # The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day. (format: date-time)
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
    path: "/v1/apps/{application-id}/campaigns/{campaign-id}/kpis/daterange/{kpi-name}"
    path_params: [{name: application-id, var: application_id}, {name: campaign-id, var: campaign_id}, {name: kpi-name, var: kpi_name}]
    query: [{name: end-time, var: end_time}, {name: next-token, var: next_token}, {name: page-size, var: page_size}, {name: start-time, var: start_time}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, campaign_id: $campaign_id, kpi_name: $kpi_name, end_time: $end_time, next_token: $next_token, page_size: $page_size, start_time: $start_time, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status, configuration, and other settings for a specific version of a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}
# Returns: record<CampaignResponse: record<AdditionalTreatments: list<record>, ApplicationId: string, Arn: string, CreationDate: string, CustomDeliveryConfiguration: record<DeliveryUri: string, EndpointTypes: list>, DefaultState: record<CampaignStatus: string>, Description: string, HoldoutPercent: int, Hook: record<LambdaFunctionName: string, Mode: string, WebUrl: string>, Id: string, IsPaused: bool, LastModifiedDate: string, Limits: record<Daily: int, MaximumDuration: int, MessagesPerSecond: int, Total: int, Session: int>, MessageConfiguration: record<ADMMessage: record, APNSMessage: record, BaiduMessage: record, CustomMessage: record, DefaultMessage: record, EmailMessage: record, GCMMessage: record, SMSMessage: record, InAppMessage: record>, Name: string, Schedule: record<EndTime: string, EventFilter: record, Frequency: string, IsLocalTime: bool, QuietTime: record, StartTime: string, Timezone: string>, SegmentId: string, SegmentVersion: int, State: record<CampaignStatus: string>, tags: record, TemplateConfiguration: record<EmailTemplate: record, PushTemplate: record, SMSTemplate: record, VoiceTemplate: record>, TreatmentDescription: string, TreatmentName: string, Version: int, Priority: int>>
# operationId: GetCampaignVersion
export def "get-campaign-version" [
  application_id: string
  campaign_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions/{version}"
    path_params: [{name: application-id, var: application_id}, {name: campaign-id, var: campaign_id}, {name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, campaign_id: $campaign_id, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status, configuration, and other settings for all versions of a campaign.
#
# GET /v1/apps/{application-id}/campaigns/{campaign-id}/versions
# Returns: record<CampaignsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetCampaignVersions
export def "get-campaign-versions" [
  application_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/campaigns/{campaign-id}/versions"
    path_params: [{name: application-id, var: application_id}, {name: campaign-id, var: campaign_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, campaign_id: $campaign_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the history and status of each channel for an application.
#
# GET /v1/apps/{application-id}/channels
# Returns: record<ChannelsResponse: record<Channels: record>>
# operationId: GetChannels
export def "get-channels" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/channels"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of a specific export job for an application.
#
# GET /v1/apps/{application-id}/jobs/export/{job-id}
# Returns: record<ExportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<RoleArn: string, S3UrlPrefix: string, SegmentId: string, SegmentVersion: int>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>
# operationId: GetExportJob
export def "get-export-job" [
  application_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/jobs/export/{job-id}"
    path_params: [{name: application-id, var: application_id}, {name: job-id, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of a specific import job for an application.
#
# GET /v1/apps/{application-id}/jobs/import/{job-id}
# Returns: record<ImportJobResponse: record<ApplicationId: string, CompletedPieces: int, CompletionDate: string, CreationDate: string, Definition: record<DefineSegment: bool, ExternalId: string, Format: string, RegisterEndpoints: bool, RoleArn: string, S3Url: string, SegmentId: string, SegmentName: string>, FailedPieces: int, Failures: list<string>, Id: string, JobStatus: string, TotalFailures: int, TotalPieces: int, TotalProcessed: int, Type: string>>
# operationId: GetImportJob
export def "get-import-job" [
  application_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/jobs/import/{job-id}"
    path_params: [{name: application-id, var: application_id}, {name: job-id, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the in-app messages targeted for the provided endpoint ID.
#
# GET /v1/apps/{application-id}/endpoints/{endpoint-id}/inappmessages
# Returns: record<InAppMessagesResponse: record<InAppMessageCampaigns: list<record>>>
# operationId: GetInAppMessages
export def "get-in-app-messages" [
  application_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/endpoints/{endpoint-id}/inappmessages"
    path_params: [{name: application-id, var: application_id}, {name: endpoint-id, var: endpoint_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, endpoint_id: $endpoint_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves (queries) pre-aggregated data for a standard engagement metric that applies to a journey.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}
# Returns: record<JourneyDateRangeKpiResponse: record<ApplicationId: string, EndTime: string, JourneyId: string, KpiName: string, KpiResult: record<Rows: list>, NextToken: string, StartTime: string>>
# operationId: GetJourneyDateRangeKpi
export def "get-journey-date-range-kpi" [
  application_id: string
  journey_id: string
  kpi_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The last date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-26T20:00:00Z for 8:00 PM UTC July 26, 2019. (format: date-time)
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --start-time: string # The first date and time to retrieve data for, as part of an inclusive date range that filters the query results. This value should be in extended ISO 8601 format and use Coordinated Universal Time (UTC), for example: 2019-07-19T20:00:00Z for 8:00 PM UTC July 19, 2019. This value should also be fewer than 90 days from the current day. (format: date-time)
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
    path: "/v1/apps/{application-id}/journeys/{journey-id}/kpis/daterange/{kpi-name}"
    path_params: [{name: application-id, var: application_id}, {name: journey-id, var: journey_id}, {name: kpi-name, var: kpi_name}]
    query: [{name: end-time, var: end_time}, {name: next-token, var: next_token}, {name: page-size, var: page_size}, {name: start-time, var: start_time}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, journey_id: $journey_id, kpi_name: $kpi_name, end_time: $end_time, next_token: $next_token, page_size: $page_size, start_time: $start_time, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey activity.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics
# Returns: record<JourneyExecutionActivityMetricsResponse: record<ActivityType: string, ApplicationId: string, JourneyActivityId: string, JourneyId: string, LastEvaluatedTime: string, Metrics: record>>
# operationId: GetJourneyExecutionActivityMetrics
export def "get-journey-execution-activity-metrics" [
  application_id: string
  journey_id: string
  journey_activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
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
    path: "/v1/apps/{application-id}/journeys/{journey-id}/activities/{journey-activity-id}/execution-metrics"
    path_params: [{name: application-id, var: application_id}, {name: journey-id, var: journey_id}, {name: journey-activity-id, var: journey_activity_id}]
    query: [{name: next-token, var: next_token}, {name: page-size, var: page_size}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, journey_id: $journey_id, journey_activity_id: $journey_activity_id, next_token: $next_token, page_size: $page_size, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves (queries) pre-aggregated data for a standard execution metric that applies to a journey.
#
# GET /v1/apps/{application-id}/journeys/{journey-id}/execution-metrics
# Returns: record<JourneyExecutionMetricsResponse: record<ApplicationId: string, JourneyId: string, LastEvaluatedTime: string, Metrics: record>>
# operationId: GetJourneyExecutionMetrics
export def "get-journey-execution-metrics" [
  application_id: string
  journey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
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
    path: "/v1/apps/{application-id}/journeys/{journey-id}/execution-metrics"
    path_params: [{name: application-id, var: application_id}, {name: journey-id, var: journey_id}]
    query: [{name: next-token, var: next_token}, {name: page-size, var: page_size}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, journey_id: $journey_id, next_token: $next_token, page_size: $page_size, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the export jobs for a segment.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/jobs/export
# Returns: record<ExportJobsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetSegmentExportJobs
export def "get-segment-export-jobs" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/segments/{segment-id}/jobs/export"
    path_params: [{name: application-id, var: application_id}, {name: segment-id, var: segment_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, segment_id: $segment_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the status and settings of the import jobs for a segment.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/jobs/import
# Returns: record<ImportJobsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetSegmentImportJobs
export def "get-segment-import-jobs" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/segments/{segment-id}/jobs/import"
    path_params: [{name: application-id, var: application_id}, {name: segment-id, var: segment_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, segment_id: $segment_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the configuration, dimension, and other settings for a specific version of a segment that's associated with an application.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/versions/{version}
# Returns: record<SegmentResponse: record<ApplicationId: string, Arn: string, CreationDate: string, Dimensions: record<Attributes: record, Behavior: record, Demographic: record, Location: record, Metrics: record, UserAttributes: record>, Id: string, ImportDefinition: record<ChannelCounts: record, ExternalId: string, Format: string, RoleArn: string, S3Url: string, Size: int>, LastModifiedDate: string, Name: string, SegmentGroups: record<Groups: list, Include: string>, SegmentType: string, tags: record, Version: int>>
# operationId: GetSegmentVersion
export def "get-segment-version" [
  application_id: string
  segment_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apps/{application-id}/segments/{segment-id}/versions/{version}"
    path_params: [{name: application-id, var: application_id}, {name: segment-id, var: segment_id}, {name: version, var: version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, segment_id: $segment_id, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the configuration, dimension, and other settings for all the versions of a specific segment that's associated with an application.
#
# GET /v1/apps/{application-id}/segments/{segment-id}/versions
# Returns: record<SegmentsResponse: record<Item: list<record>, NextToken: string>>
# operationId: GetSegmentVersions
export def "get-segment-versions" [
  application_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --qp-token: string # The NextToken string that specifies which page of results to return in a paginated response. (spec name: token)
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
    path: "/v1/apps/{application-id}/segments/{segment-id}/versions"
    path_params: [{name: application-id, var: application_id}, {name: segment-id, var: segment_id}]
    query: [{name: page-size, var: page_size}, {name: token, var: qp_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, segment_id: $segment_id, page_size: $page_size, qp_token: $qp_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the tags (keys and values) that are associated with an application, campaign, message template, or segment.
#
# GET /v1/tags/{resource-arn}
# Returns: record<TagsModel: record<tags: record>>
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
    path: "/v1/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more tags (keys and values) to an application, campaign, message template, or segment.
#
# POST /v1/tags/{resource-arn}
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
  tags_model: record # Specifies the tags (keys and values) for an application, campaign, message template, or segment. — shape: {tags?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TagsModel, var: tags_model}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags_model: $tags_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about all the versions of a specific message template.
#
# GET /v1/templates/{template-name}/{template-type}/versions
# Returns: record<TemplateVersionsResponse: record<Item: list<record>, Message: string, NextToken: string, RequestID: string>>
# operationId: ListTemplateVersions
export def "list-template-versions" [
  template_name: string
  template_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
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
    path: "/v1/templates/{template-name}/{template-type}/versions"
    path_params: [{name: template-name, var: template_name}, {name: template-type, var: template_type}]
    query: [{name: next-token, var: next_token}, {name: page-size, var: page_size}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, template_type: $template_type, next_token: $next_token, page_size: $page_size, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about all the message templates that are associated with your Amazon Pinpoint account.
#
# GET /v1/templates
# Returns: record<TemplatesResponse: record<Item: list<record>, NextToken: string>>
# operationId: ListTemplates
export def "list-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The string that specifies which page of results to return in a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --page-size: string # The maximum number of items to include in each page of a paginated response. This parameter is not supported for application, campaign, and journey metrics.
  --prefix: string # The substring to match in the names of the message templates to include in the results. If you specify this value, Amazon Pinpoint returns only those templates whose names begin with the value that you specify.
  --template-type: string # The type of message template to include in the results. Valid values are: EMAIL, PUSH, SMS, and VOICE. To include all types of templates in the results, don't include this parameter in your request.
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
    path: "/v1/templates"
    query: [{name: next-token, var: next_token}, {name: page-size, var: page_size}, {name: prefix, var: prefix}, {name: template-type, var: template_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, page_size: $page_size, prefix: $prefix, template_type: $template_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a phone number.
#
# POST /v1/phone/number/validate
# Returns: record<NumberValidateResponse: record<Carrier: string, City: string, CleansedPhoneNumberE164: string, CleansedPhoneNumberNational: string, Country: string, CountryCodeIso2: string, CountryCodeNumeric: string, County: string, OriginalCountryCodeIso2: string, OriginalPhoneNumber: string, PhoneType: string, PhoneTypeCode: int, Timezone: string, ZipCode: string>>
# operationId: PhoneNumberValidate
export def "phone-number-validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  number_validate_request: record # Specifies a phone number to validate and retrieve information about. — shape: {IsoCountryCode?: string, PhoneNumber?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/phone/number/validate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: NumberValidateRequest, var: number_validate_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, number_validate_request: $number_validate_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new event to record for endpoints, or creates or updates endpoint data that existing events are associated with.
#
# POST /v1/apps/{application-id}/events
# Returns: record<EventsResponse: record<Results: record>>
# operationId: PutEvents
export def "put-events" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  events_request: record # Specifies a batch of events to process. — shape: {BatchItem?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/events"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventsRequest, var: events_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, events_request: $events_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more attributes, of the same attribute type, from all the endpoints that are associated with an application.
#
# PUT /v1/apps/{application-id}/attributes/{attribute-type}
# Returns: record<AttributesResource: record<ApplicationId: string, AttributeType: string, Attributes: list<string>>>
# operationId: RemoveAttributes
export def "remove-attributes" [
  application_id: string
  attribute_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  update_attributes_request: record # Specifies one or more attributes to remove from all the endpoints that are associated with an application. — shape: {Blacklist?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/attributes/{attribute-type}"
    path_params: [{name: application-id, var: application_id}, {name: attribute-type, var: attribute_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: UpdateAttributesRequest, var: update_attributes_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, attribute_type: $attribute_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, update_attributes_request: $update_attributes_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates and sends a direct message.
#
# POST /v1/apps/{application-id}/messages
# Returns: record<MessageResponse: record<ApplicationId: string, EndpointResult: record, RequestId: string, Result: record>>
# operationId: SendMessages
export def "send-messages" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  message_request: record # Specifies the configuration and other settings for a message. — shape: {Addresses?: record, Context?: record, Endpoints?: record, MessageConfiguration?: record, TemplateConfiguration?: record, TraceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/messages"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MessageRequest, var: message_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, message_request: $message_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an OTP message
#
# POST /v1/apps/{application-id}/otp
# Returns: record<MessageResponse: record<ApplicationId: string, EndpointResult: record, RequestId: string, Result: record>>
# operationId: SendOTPMessage
export def "send-otp-message" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  send_otp_message_request_parameters: record # Send OTP message request parameters. — shape: {AllowedAttempts?: int, BrandName?: string, Channel?: string, CodeLength?: int, DestinationIdentity?: string, EntityId?: string, Language?: string, OriginationIdentity?: string, ReferenceId?: string, TemplateId?: string, ValidityPeriod?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/otp"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SendOTPMessageRequestParameters, var: send_otp_message_request_parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, send_otp_message_request_parameters: $send_otp_message_request_parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates and sends a message to a list of users.
#
# POST /v1/apps/{application-id}/users-messages
# Returns: record<SendUsersMessageResponse: record<ApplicationId: string, RequestId: string, Result: record>>
# operationId: SendUsersMessages
export def "send-users-messages" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  send_users_message_request: record # Specifies the configuration and other settings for a message to send to all the endpoints that are associated with a list of users. — shape: {Context?: record, MessageConfiguration?: record, TemplateConfiguration?: record, TraceId?: string, Users?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/users-messages"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SendUsersMessageRequest, var: send_users_message_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, send_users_message_request: $send_users_message_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags (keys and values) from an application, campaign, message template, or segment.
#
# DELETE /v1/tags/{resource-arn}
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
  --tag-keys: list<string> # The key of the tag to remove from the resource. To remove multiple tags, append the tagKeys parameter and argument for each additional tag to remove, separated by an ampersand (&). (required)
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
    path: "/v1/tags/{resource-arn}"
    path_params: [{name: resource-arn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new batch of endpoints for an application or updates the settings and attributes of a batch of existing endpoints for an application. You can also use this operation to define custom attributes for a batch of endpoints. If an update includes one or more values for a custom attribute, Amazon Pinpoint replaces (overwrites) any existing values with the new values.
#
# PUT /v1/apps/{application-id}/endpoints
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdateEndpointsBatch
export def "update-endpoints-batch" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  endpoint_batch_request: record # Specifies a batch of endpoints to create or update and the settings and attributes to set or change for each endpoint. — shape: {Item?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/endpoints"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointBatchRequest, var: endpoint_batch_request}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, endpoint_batch_request: $endpoint_batch_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels (stops) an active journey.
#
# PUT /v1/apps/{application-id}/journeys/{journey-id}/state
# Returns: record<JourneyResponse: record<Activities: record, ApplicationId: string, CreationDate: string, Id: string, LastModifiedDate: string, Limits: record<DailyCap: int, EndpointReentryCap: int, MessagesPerSecond: int, EndpointReentryInterval: string>, LocalTime: bool, Name: string, QuietTime: record<End: string, Start: string>, RefreshFrequency: string, Schedule: record<EndTime: string, StartTime: string, Timezone: string>, StartActivity: string, StartCondition: record<Description: string, EventStartCondition: record, SegmentStartCondition: record>, State: string, tags: record, WaitForQuietTime: bool, RefreshOnSegmentUpdate: bool, JourneyChannelSettings: record<ConnectCampaignArn: string, ConnectCampaignExecutionRoleArn: string>, SendingSchedule: bool, OpenHours: record<EMAIL: record, SMS: record, PUSH: record, VOICE: record, CUSTOM: record>, ClosedDays: record<EMAIL: list, SMS: list, PUSH: list, VOICE: list, CUSTOM: list>>>
# operationId: UpdateJourneyState
export def "update-journey-state" [
  application_id: string
  journey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  journey_state_request: record # Changes the status of a journey. — shape: {State?: "DRAFT"|"ACTIVE"|"COMPLETED"|"CANCELLED"|"CLOSED"|"PAUSED"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/apps/{application-id}/journeys/{journey-id}/state"
    path_params: [{name: application-id, var: application_id}, {name: journey-id, var: journey_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: JourneyStateRequest, var: journey_state_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, journey_id: $journey_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, journey_state_request: $journey_state_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the status of a specific version of a message template to active.
#
# PUT /v1/templates/{template-name}/{template-type}/active-version
# Returns: record<MessageBody: record<Message: string, RequestID: string>>
# operationId: UpdateTemplateActiveVersion
export def "update-template-active-version" [
  template_name: string
  template_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  template_active_version_request: record # Specifies which version of a message template to use as the active version of the template. — shape: {Version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/templates/{template-name}/{template-type}/active-version"
    path_params: [{name: template-name, var: template_name}, {name: template-type, var: template_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TemplateActiveVersionRequest, var: template_active_version_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, template_type: $template_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template_active_version_request: $template_active_version_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify an OTP
#
# POST /v1/apps/{application-id}/verify-otp
# Returns: record<VerificationResponse: record<Valid: bool>>
# operationId: VerifyOTPMessage
export def "verify-otp-message" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  verify_otp_message_request_parameters: record # Verify OTP message request. — shape: {DestinationIdentity?: string, Otp?: string, ReferenceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/{application-id}/verify-otp"
    path_params: [{name: application-id, var: application_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: VerifyOTPMessageRequestParameters, var: verify_otp_message_request_parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, verify_otp_message_request_parameters: $verify_otp_message_request_parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
