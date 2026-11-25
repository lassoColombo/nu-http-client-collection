# Auto-generated client for Amazon Mechanical Turk v2017-01-17
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mturk-requester/2017-01-17/openapi.json
# Auth: --token flag or $env.AMAZON_MECHANICAL_TURK_TOKEN

const CLIENT = {
  base_url: "http://mturk-requester.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_MECHANICAL_TURK_TOKEN"
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

def base-url-completer [] { ["http://mturk-requester.us-east-1.amazonaws.com" "http://mturk-requester.us-east-2.amazonaws.com" "http://mturk-requester.us-west-1.amazonaws.com" "http://mturk-requester.us-west-2.amazonaws.com" "http://mturk-requester.us-gov-west-1.amazonaws.com" "http://mturk-requester.us-gov-east-1.amazonaws.com" "http://mturk-requester.ca-central-1.amazonaws.com" "http://mturk-requester.eu-north-1.amazonaws.com" "http://mturk-requester.eu-west-1.amazonaws.com" "http://mturk-requester.eu-west-2.amazonaws.com" "http://mturk-requester.eu-west-3.amazonaws.com" "http://mturk-requester.eu-central-1.amazonaws.com" "http://mturk-requester.eu-south-1.amazonaws.com" "http://mturk-requester.af-south-1.amazonaws.com" "http://mturk-requester.ap-northeast-1.amazonaws.com" "http://mturk-requester.ap-northeast-2.amazonaws.com" "http://mturk-requester.ap-northeast-3.amazonaws.com" "http://mturk-requester.ap-southeast-1.amazonaws.com" "http://mturk-requester.ap-southeast-2.amazonaws.com" "http://mturk-requester.ap-east-1.amazonaws.com" "http://mturk-requester.ap-south-1.amazonaws.com" "http://mturk-requester.sa-east-1.amazonaws.com" "http://mturk-requester.me-south-1.amazonaws.com" "https://mturk-requester.us-east-1.amazonaws.com" "https://mturk-requester.us-east-2.amazonaws.com" "https://mturk-requester.us-west-1.amazonaws.com" "https://mturk-requester.us-west-2.amazonaws.com" "https://mturk-requester.us-gov-west-1.amazonaws.com" "https://mturk-requester.us-gov-east-1.amazonaws.com" "https://mturk-requester.ca-central-1.amazonaws.com" "https://mturk-requester.eu-north-1.amazonaws.com" "https://mturk-requester.eu-west-1.amazonaws.com" "https://mturk-requester.eu-west-2.amazonaws.com" "https://mturk-requester.eu-west-3.amazonaws.com" "https://mturk-requester.eu-central-1.amazonaws.com" "https://mturk-requester.eu-south-1.amazonaws.com" "https://mturk-requester.af-south-1.amazonaws.com" "https://mturk-requester.ap-northeast-1.amazonaws.com" "https://mturk-requester.ap-northeast-2.amazonaws.com" "https://mturk-requester.ap-northeast-3.amazonaws.com" "https://mturk-requester.ap-southeast-1.amazonaws.com" "https://mturk-requester.ap-southeast-2.amazonaws.com" "https://mturk-requester.ap-east-1.amazonaws.com" "https://mturk-requester.ap-south-1.amazonaws.com" "https://mturk-requester.sa-east-1.amazonaws.com" "https://mturk-requester.me-south-1.amazonaws.com" "http://mturk-requester.cn-north-1.amazonaws.com.cn" "http://mturk-requester.cn-northwest-1.amazonaws.com.cn" "https://mturk-requester.cn-north-1.amazonaws.com.cn" "https://mturk-requester.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["MTurkRequesterServiceV20170117.AcceptQualificationRequest"] }
def x-amz-target-completer-1 [] { ["MTurkRequesterServiceV20170117.ApproveAssignment"] }
def x-amz-target-completer-2 [] { ["MTurkRequesterServiceV20170117.AssociateQualificationWithWorker"] }
def x-amz-target-completer-3 [] { ["MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT"] }
def x-amz-target-completer-4 [] { ["MTurkRequesterServiceV20170117.CreateHIT"] }
def x-amz-target-completer-5 [] { ["MTurkRequesterServiceV20170117.CreateHITType"] }
def x-amz-target-completer-6 [] { ["MTurkRequesterServiceV20170117.CreateHITWithHITType"] }
def qualification-type-status-completer [] { ["Active" "Inactive"] }
def x-amz-target-completer-7 [] { ["MTurkRequesterServiceV20170117.CreateQualificationType"] }
def x-amz-target-completer-8 [] { ["MTurkRequesterServiceV20170117.CreateWorkerBlock"] }
def x-amz-target-completer-9 [] { ["MTurkRequesterServiceV20170117.DeleteHIT"] }
def x-amz-target-completer-10 [] { ["MTurkRequesterServiceV20170117.DeleteQualificationType"] }
def x-amz-target-completer-11 [] { ["MTurkRequesterServiceV20170117.DeleteWorkerBlock"] }
def x-amz-target-completer-12 [] { ["MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker"] }
def x-amz-target-completer-13 [] { ["MTurkRequesterServiceV20170117.GetAccountBalance"] }
def x-amz-target-completer-14 [] { ["MTurkRequesterServiceV20170117.GetAssignment"] }
def x-amz-target-completer-15 [] { ["MTurkRequesterServiceV20170117.GetFileUploadURL"] }
def x-amz-target-completer-16 [] { ["MTurkRequesterServiceV20170117.GetHIT"] }
def x-amz-target-completer-17 [] { ["MTurkRequesterServiceV20170117.GetQualificationScore"] }
def x-amz-target-completer-18 [] { ["MTurkRequesterServiceV20170117.GetQualificationType"] }
def x-amz-target-completer-19 [] { ["MTurkRequesterServiceV20170117.ListAssignmentsForHIT"] }
def x-amz-target-completer-20 [] { ["MTurkRequesterServiceV20170117.ListBonusPayments"] }
def x-amz-target-completer-21 [] { ["MTurkRequesterServiceV20170117.ListHITs"] }
def x-amz-target-completer-22 [] { ["MTurkRequesterServiceV20170117.ListHITsForQualificationType"] }
def x-amz-target-completer-23 [] { ["MTurkRequesterServiceV20170117.ListQualificationRequests"] }
def x-amz-target-completer-24 [] { ["MTurkRequesterServiceV20170117.ListQualificationTypes"] }
def x-amz-target-completer-25 [] { ["MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT"] }
def status-completer [] { ["Reviewable" "Reviewing"] }
def x-amz-target-completer-26 [] { ["MTurkRequesterServiceV20170117.ListReviewableHITs"] }
def x-amz-target-completer-27 [] { ["MTurkRequesterServiceV20170117.ListWorkerBlocks"] }
def status-completer-1 [] { ["Granted" "Revoked"] }
def x-amz-target-completer-28 [] { ["MTurkRequesterServiceV20170117.ListWorkersWithQualificationType"] }
def x-amz-target-completer-29 [] { ["MTurkRequesterServiceV20170117.NotifyWorkers"] }
def x-amz-target-completer-30 [] { ["MTurkRequesterServiceV20170117.RejectAssignment"] }
def x-amz-target-completer-31 [] { ["MTurkRequesterServiceV20170117.RejectQualificationRequest"] }
def x-amz-target-completer-32 [] { ["MTurkRequesterServiceV20170117.SendBonus"] }
def test-event-type-completer [] { ["AssignmentAbandoned" "AssignmentAccepted" "AssignmentApproved" "AssignmentRejected" "AssignmentReturned" "AssignmentSubmitted" "HITCreated" "HITDisposed" "HITExpired" "HITExtended" "HITReviewable" "Ping"] }
def x-amz-target-completer-33 [] { ["MTurkRequesterServiceV20170117.SendTestEventNotification"] }
def x-amz-target-completer-34 [] { ["MTurkRequesterServiceV20170117.UpdateExpirationForHIT"] }
def x-amz-target-completer-35 [] { ["MTurkRequesterServiceV20170117.UpdateHITReviewStatus"] }
def x-amz-target-completer-36 [] { ["MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT"] }
def x-amz-target-completer-37 [] { ["MTurkRequesterServiceV20170117.UpdateNotificationSettings"] }
def x-amz-target-completer-38 [] { ["MTurkRequesterServiceV20170117.UpdateQualificationType"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-qualification-request: "record"
    approve-assignment: "record"
    associate-qualification-with-worker: "record"
    create-additional-assignments-for-hit: "record"
    create-hit: "record<HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>"
    create-hit-type: "record<HITTypeId: string>"
    create-hit-with-hit-type: "record<HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>"
    create-qualification-type: "record<QualificationType: record<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>"
    create-worker-block: "record"
    delete-hit: "record"
    delete-qualification-type: "record"
    delete-worker-block: "record"
    disassociate-qualification-from-worker: "record"
    get-account-balance: "record<AvailableBalance: string, OnHoldBalance: string>"
    get-assignment: "record<Assignment: record<AssignmentId: string, WorkerId: string, HITId: string, AssignmentStatus: string, AutoApprovalTime: string, AcceptTime: string, SubmitTime: string, ApprovalTime: string, RejectionTime: string, Deadline: string, Answer: string, RequesterFeedback: string>, HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>"
    get-file-upload-url: "record<FileUploadURL: string>"
    get-hit: "record<HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>"
    get-qualification-score: "record<Qualification: record<QualificationTypeId: string, WorkerId: string, GrantTime: string, IntegerValue: int, LocaleValue: record<Country: string, Subdivision: string>, Status: string>>"
    get-qualification-type: "record<QualificationType: record<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>"
    list-assignments-for-hit: "record<NextToken: string, NumResults: int, Assignments: table<AssignmentId: string, WorkerId: string, HITId: string, AssignmentStatus: string, AutoApprovalTime: string, AcceptTime: string, SubmitTime: string, ApprovalTime: string, RejectionTime: string, Deadline: string, Answer: string, RequesterFeedback: string>>"
    list-bonus-payments: "record<NumResults: int, NextToken: string, BonusPayments: table<WorkerId: string, BonusAmount: string, AssignmentId: string, Reason: string, GrantTime: string>>"
    list-hi-ts: "record<NextToken: string, NumResults: int, HITs: table<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>"
    list-hi-ts-for-qualification-type: "record<NextToken: string, NumResults: int, HITs: table<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>"
    list-qualification-requests: "record<NumResults: int, NextToken: string, QualificationRequests: table<QualificationRequestId: string, QualificationTypeId: string, WorkerId: string, Test: string, Answer: string, SubmitTime: string>>"
    list-qualification-types: "record<NumResults: int, NextToken: string, QualificationTypes: table<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>"
    list-review-policy-results-for-hit: "record<HITId: string, AssignmentReviewPolicy: record<PolicyName: string, Parameters: list<record>>, HITReviewPolicy: record<PolicyName: string, Parameters: list<record>>, AssignmentReviewReport: record<ReviewResults: list<record>, ReviewActions: list<record>>, HITReviewReport: record<ReviewResults: list<record>, ReviewActions: list<record>>, NextToken: string>"
    list-reviewable-hi-ts: "record<NextToken: string, NumResults: int, HITs: table<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>"
    list-worker-blocks: "record<NextToken: string, NumResults: int, WorkerBlocks: table<WorkerId: string, Reason: string>>"
    list-workers-with-qualification-type: "record<NextToken: string, NumResults: int, Qualifications: table<QualificationTypeId: string, WorkerId: string, GrantTime: string, IntegerValue: int, LocaleValue: record, Status: string>>"
    notify-workers: "record<NotifyWorkersFailureStatuses: table<NotifyWorkersFailureCode: string, NotifyWorkersFailureMessage: string, WorkerId: string>>"
    reject-assignment: "record"
    reject-qualification-request: "record"
    send-bonus: "record"
    send-test-event-notification: "record"
    update-expiration-for-hit: "record"
    update-hit-review-status: "record"
    update-hit-type-of-hit: "record"
    update-notification-settings: "record"
    update-qualification-type: "record<QualificationType: record<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-qualification-request" "approve-assignment" "associate-qualification-with-worker" "create-additional-assignments-for-hit" "create-hit" "create-hit-type" "create-hit-with-hit-type" "create-qualification-type" "create-worker-block" "delete-hit" "delete-qualification-type" "delete-worker-block" "disassociate-qualification-from-worker" "get-account-balance" "get-assignment" "get-file-upload-url" "get-hit" "get-qualification-score" "get-qualification-type" "list-assignments-for-hit" "list-bonus-payments" "list-hi-ts" "list-hi-ts-for-qualification-type" "list-qualification-requests" "list-qualification-types" "list-review-policy-results-for-hit" "list-reviewable-hi-ts" "list-worker-blocks" "list-workers-with-qualification-type" "notify-workers" "reject-assignment" "reject-qualification-request" "send-bonus" "send-test-event-notification" "update-expiration-for-hit" "update-hit-review-status" "update-hit-type-of-hit" "update-notification-settings" "update-qualification-type" "commands"] | sort) } | get name | first)
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

# The AcceptQualificationRequest operation approves a Worker's request for a Qualification. Only the owner of the Qualification type can grant a Qualification request for that type. A successful request for the AcceptQualificationRequest operation returns with no errors and an empty body.
#
# POST /
# Returns: record
# operationId: AcceptQualificationRequest
export def "accept-qualification-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  qualification_request_id: string # The ID of the Qualification request, as returned by the GetQualificationRequests operation.
  --integer-value: int # The value of the Qualification. You can omit this value if you are using the presence or absence of the Qualification as the basis for a HIT requirement.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.AcceptQualificationRequest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationRequestId, var: qualification_request_id}, {name: IntegerValue, var: integer_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_request_id: $qualification_request_id, integer_value: $integer_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ApproveAssignment operation approves the results of a completed assignment. Approving an assignment initiates two payments from the Requester's Amazon.com account The Worker who submitted the results is paid the reward specified in the HIT. Amazon Mechanical Turk fees are debited. If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted.
#
# POST /
# Returns: record
# operationId: ApproveAssignment
export def "approve-assignment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  assignment_id: string # The ID of the assignment. The assignment must correspond to a HIT created by the Requester.
  --requester-feedback: string # A message for the Worker, which the Worker can see in the Status section of the web site.
  --override-rejection: oneof<nothing, bool> # A flag indicating that an assignment should be approved even if it was previously rejected. Defaults to False.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ApproveAssignment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssignmentId, var: assignment_id}, {name: RequesterFeedback, var: requester_feedback}, {name: OverrideRejection, var: override_rejection}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, assignment_id: $assignment_id, requester_feedback: $requester_feedback, override_rejection: $override_rejection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The AssociateQualificationWithWorker operation gives a Worker a Qualification. AssociateQualificationWithWorker does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. You can only assign a Qualification of a Qualification type that you created (using the CreateQualificationType operation). Note: AssociateQualificationWithWorker does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the RejectQualificationRequest operation.
#
# POST /
# Returns: record
# operationId: AssociateQualificationWithWorker
export def "associate-qualification-with-worker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  qualification_type_id: string # The ID of the Qualification type to use for the assigned Qualification.
  worker_id: string # The ID of the Worker to whom the Qualification is being assigned. Worker IDs are included with submitted HIT assignments and Qualification requests.
  --integer-value: int # The value of the Qualification to assign.
  --send-notification: oneof<nothing, bool> # Specifies whether to send a notification email message to the Worker saying that the qualification was assigned to the Worker. Note: this is true by default.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.AssociateQualificationWithWorker"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}, {name: WorkerId, var: worker_id}, {name: IntegerValue, var: integer_value}, {name: SendNotification, var: send_notification}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id, worker_id: $worker_id, integer_value: $integer_value, send_notification: $send_notification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateAdditionalAssignmentsForHIT operation increases the maximum number of assignments of an existing HIT. To extend the maximum number of assignments, specify the number of additional assignments. HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease exception. HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an AWS.MechanicalTurk.HITTooOldForExtension exception.
#
# POST /
# Returns: record
# operationId: CreateAdditionalAssignmentsForHIT
export def "create-additional-assignments-for-hit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_id: string # The ID of the HIT to extend.
  number_of_additional_assignments: int # The number of additional assignments to request for this HIT.
  --unique-request-token: string # A unique identifier for this request, which allows you to retry the call on error without extending the HIT multiple times. This is useful in cases such as network timeouts where it is unclear whether or not the call succeeded on the server. If the extend HIT already exists in the system from a previous call using the same UniqueRequestToken, subsequent calls will return an error with a message containing the request ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}, {name: NumberOfAdditionalAssignments, var: number_of_additional_assignments}, {name: UniqueRequestToken, var: unique_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id, number_of_additional_assignments: $number_of_additional_assignments, unique_request_token: $unique_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateHIT operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to CreateHIT, a new HIT is created for you, with a new HITTypeID. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time. An alternative way to create HITs is to first generate a HITTypeID using the CreateHITType operation and then call the CreateHITWithHITType operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. CreateHIT also supports several ways to provide question data: by providing a value for the Question parameter that fully specifies the contents of the HIT, or by providing a HitLayoutId and associated HitLayoutParameters. If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see Amazon Mechanical Turk Pricing (https://requester.mturk.com/pricing).
#
# POST /
# Returns: record<HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>
# operationId: CreateHIT
export def "create-hit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-assignments: int # The number of times the HIT can be accepted and completed before the HIT becomes unavailable.
  --auto-approval-delay-in-seconds: int # The number of seconds after an assignment for the HIT has been submitted, after which the assignment is considered Approved automatically unless the Requester explicitly rejects it.
  lifetime_in_seconds: int # An amount of time, in seconds, after which the HIT is no longer available for users to accept. After the lifetime of the HIT elapses, the HIT no longer appears in HIT searches, even if not all of the assignments for the HIT have been accepted.
  assignment_duration_in_seconds: int # The amount of time, in seconds, that a Worker has to complete the HIT after accepting it. If a Worker does not complete the assignment within the specified duration, the assignment is considered abandoned. If the HIT is still active (that is, its lifetime has not elapsed), the assignment becomes available for other users to find and accept.
  reward: string # A string representing a currency amount.
  title: string # The title of the HIT. A title should be short and descriptive about the kind of task the HIT contains. On the Amazon Mechanical Turk web site, the HIT title appears in search results, and everywhere the HIT is mentioned.
  --keywords: string # One or more words or phrases that describe the HIT, separated by commas. These words are used in searches to find HITs.
  description: string # A general description of the HIT. A description includes detailed information about the kind of task the HIT contains. On the Amazon Mechanical Turk web site, the HIT description appears in the expanded view of search results, and in the HIT and assignment screens. A good description gives the user enough information to evaluate the HIT before accepting it.
  --question: string # The data the person completing the HIT uses to produce the results. Constraints: Must be a QuestionForm data structure, an ExternalQuestion data structure, or an HTMLQuestion data structure. The XML question data must not be larger than 64 kilobytes (65,535 bytes) in size, including whitespace. Either a Question parameter or a HITLayoutId parameter must be provided.
  --requester-annotation: string # An arbitrary data field. The RequesterAnnotation parameter lets your application attach arbitrary data to the HIT for tracking purposes. For example, this parameter could be an identifier internal to the Requester's application that corresponds with the HIT. The RequesterAnnotation parameter for a HIT is only visible to the Requester who created the HIT. It is not shown to the Worker, or any other Requester. The RequesterAnnotation parameter may be different for each HIT you submit. It does not affect how your HITs are grouped.
  --qualification-requirements: list # Conditions that a Worker's Qualifications must meet in order to accept the HIT. A HIT can have between zero and ten Qualification requirements. All requirements must be met in order for a Worker to accept the HIT. Additionally, other actions can be restricted using the ActionsGuarded field on each QualificationRequirement structure. — item shape: {QualificationTypeId: string, Comparator: "LessThan"|"LessThanOrEqualTo"|"GreaterThan"|"GreaterThanOrEqualTo"|"EqualTo"|"NotEqualTo"|"Exists"|"DoesNotExist"|"In"|"NotIn", IntegerValues?: list<int>, LocaleValues?: list, RequiredToPreview?: bool, ActionsGuarded?: "Accept"|"PreviewAndAccept"|"DiscoverPreviewAndAccept"}
  --unique-request-token: string # A unique identifier for this request which allows you to retry the call on error without creating duplicate HITs. This is useful in cases such as network timeouts where it is unclear whether or not the call succeeded on the server. If the HIT already exists in the system from a previous call using the same UniqueRequestToken, subsequent calls will return a AWS.MechanicalTurk.HitAlreadyExists error with a message containing the HITId. Note: It is your responsibility to ensure uniqueness of the token. The unique token expires after 24 hours. Subsequent calls using the same UniqueRequestToken made after the 24 hour limit could create duplicate HITs.
  --assignment-review-policy: record # HIT Review Policy data structures represent HIT review policies, which you specify when you create a HIT. — shape: {PolicyName: string, Parameters?: list}
  --hit-review-policy: record # HIT Review Policy data structures represent HIT review policies, which you specify when you create a HIT. — shape: {PolicyName: string, Parameters?: list}
  --hit-layout-id: string # The HITLayoutId allows you to use a pre-existing HIT design with placeholder values and create an additional HIT by providing those values as HITLayoutParameters. Constraints: Either a Question parameter or a HITLayoutId parameter must be provided.
  --hit-layout-parameters: list # If the HITLayoutId is provided, any placeholder values must be filled in with values using the HITLayoutParameter structure. For more information, see HITLayout. — item shape: {Name: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.CreateHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxAssignments, var: max_assignments}, {name: AutoApprovalDelayInSeconds, var: auto_approval_delay_in_seconds}, {name: LifetimeInSeconds, var: lifetime_in_seconds}, {name: AssignmentDurationInSeconds, var: assignment_duration_in_seconds}, {name: Reward, var: reward}, {name: Title, var: title}, {name: Keywords, var: keywords}, {name: Description, var: description}, {name: Question, var: question}, {name: RequesterAnnotation, var: requester_annotation}, {name: QualificationRequirements, var: qualification_requirements}, {name: UniqueRequestToken, var: unique_request_token}, {name: AssignmentReviewPolicy, var: assignment_review_policy}, {name: HITReviewPolicy, var: hit_review_policy}, {name: HITLayoutId, var: hit_layout_id}, {name: HITLayoutParameters, var: hit_layout_parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, max_assignments: $max_assignments, auto_approval_delay_in_seconds: $auto_approval_delay_in_seconds, lifetime_in_seconds: $lifetime_in_seconds, assignment_duration_in_seconds: $assignment_duration_in_seconds, reward: $reward, title: $title, keywords: $keywords, description: $description, question: $question, requester_annotation: $requester_annotation, qualification_requirements: $qualification_requirements, unique_request_token: $unique_request_token, assignment_review_policy: $assignment_review_policy, hit_review_policy: $hit_review_policy, hit_layout_id: $hit_layout_id, hit_layout_parameters: $hit_layout_parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateHITType operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned.
#
# POST /
# Returns: record<HITTypeId: string>
# operationId: CreateHITType
export def "create-hit-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --auto-approval-delay-in-seconds: int # The number of seconds after an assignment for the HIT has been submitted, after which the assignment is considered Approved automatically unless the Requester explicitly rejects it.
  assignment_duration_in_seconds: int # The amount of time, in seconds, that a Worker has to complete the HIT after accepting it. If a Worker does not complete the assignment within the specified duration, the assignment is considered abandoned. If the HIT is still active (that is, its lifetime has not elapsed), the assignment becomes available for other users to find and accept.
  reward: string # A string representing a currency amount.
  title: string # The title of the HIT. A title should be short and descriptive about the kind of task the HIT contains. On the Amazon Mechanical Turk web site, the HIT title appears in search results, and everywhere the HIT is mentioned.
  --keywords: string # One or more words or phrases that describe the HIT, separated by commas. These words are used in searches to find HITs.
  description: string # A general description of the HIT. A description includes detailed information about the kind of task the HIT contains. On the Amazon Mechanical Turk web site, the HIT description appears in the expanded view of search results, and in the HIT and assignment screens. A good description gives the user enough information to evaluate the HIT before accepting it.
  --qualification-requirements: list # Conditions that a Worker's Qualifications must meet in order to accept the HIT. A HIT can have between zero and ten Qualification requirements. All requirements must be met in order for a Worker to accept the HIT. Additionally, other actions can be restricted using the ActionsGuarded field on each QualificationRequirement structure. — item shape: {QualificationTypeId: string, Comparator: "LessThan"|"LessThanOrEqualTo"|"GreaterThan"|"GreaterThanOrEqualTo"|"EqualTo"|"NotEqualTo"|"Exists"|"DoesNotExist"|"In"|"NotIn", IntegerValues?: list<int>, LocaleValues?: list, RequiredToPreview?: bool, ActionsGuarded?: "Accept"|"PreviewAndAccept"|"DiscoverPreviewAndAccept"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.CreateHITType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutoApprovalDelayInSeconds, var: auto_approval_delay_in_seconds}, {name: AssignmentDurationInSeconds, var: assignment_duration_in_seconds}, {name: Reward, var: reward}, {name: Title, var: title}, {name: Keywords, var: keywords}, {name: Description, var: description}, {name: QualificationRequirements, var: qualification_requirements}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, auto_approval_delay_in_seconds: $auto_approval_delay_in_seconds, assignment_duration_in_seconds: $assignment_duration_in_seconds, reward: $reward, title: $title, keywords: $keywords, description: $description, qualification_requirements: $qualification_requirements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateHITWithHITType operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the CreateHITType operation. This is an alternative way to create HITs from the CreateHIT operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. CreateHITWithHITType also supports several ways to provide question data: by providing a value for the Question parameter that fully specifies the contents of the HIT, or by providing a HitLayoutId and associated HitLayoutParameters. If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see Amazon Mechanical Turk Pricing (https://requester.mturk.com/pricing).
#
# POST /
# Returns: record<HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>
# operationId: CreateHITWithHITType
export def "create-hit-with-hit-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_type_id: string # The HIT type ID you want to create this HIT with.
  --max-assignments: int # The number of times the HIT can be accepted and completed before the HIT becomes unavailable.
  lifetime_in_seconds: int # An amount of time, in seconds, after which the HIT is no longer available for users to accept. After the lifetime of the HIT elapses, the HIT no longer appears in HIT searches, even if not all of the assignments for the HIT have been accepted.
  --question: string # The data the person completing the HIT uses to produce the results. Constraints: Must be a QuestionForm data structure, an ExternalQuestion data structure, or an HTMLQuestion data structure. The XML question data must not be larger than 64 kilobytes (65,535 bytes) in size, including whitespace. Either a Question parameter or a HITLayoutId parameter must be provided.
  --requester-annotation: string # An arbitrary data field. The RequesterAnnotation parameter lets your application attach arbitrary data to the HIT for tracking purposes. For example, this parameter could be an identifier internal to the Requester's application that corresponds with the HIT. The RequesterAnnotation parameter for a HIT is only visible to the Requester who created the HIT. It is not shown to the Worker, or any other Requester. The RequesterAnnotation parameter may be different for each HIT you submit. It does not affect how your HITs are grouped.
  --unique-request-token: string # A unique identifier for this request which allows you to retry the call on error without creating duplicate HITs. This is useful in cases such as network timeouts where it is unclear whether or not the call succeeded on the server. If the HIT already exists in the system from a previous call using the same UniqueRequestToken, subsequent calls will return a AWS.MechanicalTurk.HitAlreadyExists error with a message containing the HITId. Note: It is your responsibility to ensure uniqueness of the token. The unique token expires after 24 hours. Subsequent calls using the same UniqueRequestToken made after the 24 hour limit could create duplicate HITs.
  --assignment-review-policy: record # HIT Review Policy data structures represent HIT review policies, which you specify when you create a HIT. — shape: {PolicyName: string, Parameters?: list}
  --hit-review-policy: record # HIT Review Policy data structures represent HIT review policies, which you specify when you create a HIT. — shape: {PolicyName: string, Parameters?: list}
  --hit-layout-id: string # The HITLayoutId allows you to use a pre-existing HIT design with placeholder values and create an additional HIT by providing those values as HITLayoutParameters. Constraints: Either a Question parameter or a HITLayoutId parameter must be provided.
  --hit-layout-parameters: list # If the HITLayoutId is provided, any placeholder values must be filled in with values using the HITLayoutParameter structure. For more information, see HITLayout. — item shape: {Name: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.CreateHITWithHITType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITTypeId, var: hit_type_id}, {name: MaxAssignments, var: max_assignments}, {name: LifetimeInSeconds, var: lifetime_in_seconds}, {name: Question, var: question}, {name: RequesterAnnotation, var: requester_annotation}, {name: UniqueRequestToken, var: unique_request_token}, {name: AssignmentReviewPolicy, var: assignment_review_policy}, {name: HITReviewPolicy, var: hit_review_policy}, {name: HITLayoutId, var: hit_layout_id}, {name: HITLayoutParameters, var: hit_layout_parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_type_id: $hit_type_id, max_assignments: $max_assignments, lifetime_in_seconds: $lifetime_in_seconds, question: $question, requester_annotation: $requester_annotation, unique_request_token: $unique_request_token, assignment_review_policy: $assignment_review_policy, hit_review_policy: $hit_review_policy, hit_layout_id: $hit_layout_id, hit_layout_parameters: $hit_layout_parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateQualificationType operation creates a new Qualification type, which is represented by a QualificationType data structure.
#
# POST /
# Returns: record<QualificationType: record<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>
# operationId: CreateQualificationType
export def "create-qualification-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name you give to the Qualification type. The type name is used to represent the Qualification to Workers, and to find the type using a Qualification type search. It must be unique across all of your Qualification types.
  --keywords: string # One or more words or phrases that describe the Qualification type, separated by commas. The keywords of a type make the type easier to find during a search.
  description: string # A long description for the Qualification type. On the Amazon Mechanical Turk website, the long description is displayed when a Worker examines a Qualification type.
  qualification_type_status: string@qualification-type-status-completer # The initial status of the Qualification type. Constraints: Valid values are: Active | Inactive
  --retry-delay-in-seconds: int # The number of seconds that a Worker must wait after requesting a Qualification of the Qualification type before the worker can retry the Qualification request. Constraints: None. If not specified, retries are disabled and Workers can request a Qualification of this type only once, even if the Worker has not been granted the Qualification. It is not possible to disable retries for a Qualification type after it has been created with retries enabled. If you want to disable retries, you must delete existing retry-enabled Qualification type and then create a new Qualification type with retries disabled.
  --test: string # The questions for the Qualification test a Worker must answer correctly to obtain a Qualification of this type. If this parameter is specified, TestDurationInSeconds must also be specified. Constraints: Must not be longer than 65535 bytes. Must be a QuestionForm data structure. This parameter cannot be specified if AutoGranted is true. Constraints: None. If not specified, the Worker may request the Qualification without answering any questions.
  --answer-key: string # The answers to the Qualification test specified in the Test parameter, in the form of an AnswerKey data structure. Constraints: Must not be longer than 65535 bytes. Constraints: None. If not specified, you must process Qualification requests manually.
  --test-duration-in-seconds: int # The number of seconds the Worker has to complete the Qualification test, starting from the time the Worker requests the Qualification.
  --auto-granted: oneof<nothing, bool> # Specifies whether requests for the Qualification type are granted immediately, without prompting the Worker with a Qualification test. Constraints: If the Test parameter is specified, this parameter cannot be true.
  --auto-granted-value: int # The Qualification value to use for automatically granted Qualifications. This parameter is used only if the AutoGranted parameter is true.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.CreateQualificationType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Keywords, var: keywords}, {name: Description, var: description}, {name: QualificationTypeStatus, var: qualification_type_status}, {name: RetryDelayInSeconds, var: retry_delay_in_seconds}, {name: Test, var: test}, {name: AnswerKey, var: answer_key}, {name: TestDurationInSeconds, var: test_duration_in_seconds}, {name: AutoGranted, var: auto_granted}, {name: AutoGrantedValue, var: auto_granted_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, keywords: $keywords, description: $description, qualification_type_status: $qualification_type_status, retry_delay_in_seconds: $retry_delay_in_seconds, test: $test, answer_key: $answer_key, test_duration_in_seconds: $test_duration_in_seconds, auto_granted: $auto_granted, auto_granted_value: $auto_granted_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateWorkerBlock operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
#
# POST /
# Returns: record
# operationId: CreateWorkerBlock
export def "create-worker-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  worker_id: string # The ID of the Worker to block.
  reason: string # A message explaining the reason for blocking the Worker. This parameter enables you to keep track of your Workers. The Worker does not see this message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.CreateWorkerBlock"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkerId, var: worker_id}, {name: Reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, worker_id: $worker_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DeleteHIT operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. You can only dispose of HITs that are in the Reviewable state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the Reviewable state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. HITs are automatically disposed of after 120 days. After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. Disposed HITs are not returned in results for the ListHITs operation. Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs.
#
# POST /
# Returns: record
# operationId: DeleteHIT
export def "delete-hit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_id: string # The ID of the HIT to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.DeleteHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DeleteQualificationType deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types. DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.
#
# POST /
# Returns: record
# operationId: DeleteQualificationType
export def "delete-qualification-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  qualification_type_id: string # The ID of the QualificationType to dispose.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.DeleteQualificationType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DeleteWorkerBlock operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
#
# POST /
# Returns: record
# operationId: DeleteWorkerBlock
export def "delete-worker-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  worker_id: string # The ID of the Worker to unblock.
  --reason: string # A message that explains the reason for unblocking the Worker. The Worker does not see this message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.DeleteWorkerBlock"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkerId, var: worker_id}, {name: Reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, worker_id: $worker_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DisassociateQualificationFromWorker revokes a previously granted Qualification from a user. You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message.
#
# POST /
# Returns: record
# operationId: DisassociateQualificationFromWorker
export def "disassociate-qualification-from-worker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  worker_id: string # The ID of the Worker who possesses the Qualification to be revoked.
  qualification_type_id: string # The ID of the Qualification type of the Qualification to be revoked.
  --reason: string # A text message that explains why the Qualification was revoked. The user who had the Qualification sees this message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkerId, var: worker_id}, {name: QualificationTypeId, var: qualification_type_id}, {name: Reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, worker_id: $worker_id, qualification_type_id: $qualification_type_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetAccountBalance operation retrieves the Prepaid HITs balance in your Amazon Mechanical Turk account if you are a Prepaid Requester. Alternatively, this operation will retrieve the remaining available AWS Billing usage if you have enabled AWS Billing. Note: If you have enabled AWS Billing and still have a remaining Prepaid HITs balance, this balance can be viewed on the My Account page in the Requester console.
#
# POST /
# Returns: record<AvailableBalance: string, OnHoldBalance: string>
# operationId: GetAccountBalance
export def "get-account-balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.GetAccountBalance"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetAssignment operation retrieves the details of the specified Assignment.
#
# POST /
# Returns: record<Assignment: record<AssignmentId: string, WorkerId: string, HITId: string, AssignmentStatus: string, AutoApprovalTime: string, AcceptTime: string, SubmitTime: string, ApprovalTime: string, RejectionTime: string, Deadline: string, Answer: string, RequesterFeedback: string>, HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>
# operationId: GetAssignment
export def "get-assignment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  assignment_id: string # The ID of the Assignment to be retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.GetAssignment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssignmentId, var: assignment_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, assignment_id: $assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetFileUploadURL operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the FileUploadAnswer element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3.
#
# POST /
# Returns: record<FileUploadURL: string>
# operationId: GetFileUploadURL
export def "get-file-upload-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  assignment_id: string # The ID of the assignment that contains the question with a FileUploadAnswer.
  question_identifier: string # The identifier of the question with a FileUploadAnswer, as specified in the QuestionForm of the HIT.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.GetFileUploadURL"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssignmentId, var: assignment_id}, {name: QuestionIdentifier, var: question_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, assignment_id: $assignment_id, question_identifier: $question_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetHIT operation retrieves the details of the specified HIT.
#
# POST /
# Returns: record<HIT: record<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list<record>, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>
# operationId: GetHIT
export def "get-hit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_id: string # The ID of the HIT to be retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.GetHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetQualificationScore operation returns the value of a Worker's Qualification for a given Qualification type. To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the ListAssignmentsForHIT operation. Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.
#
# POST /
# Returns: record<Qualification: record<QualificationTypeId: string, WorkerId: string, GrantTime: string, IntegerValue: int, LocaleValue: record<Country: string, Subdivision: string>, Status: string>>
# operationId: GetQualificationScore
export def "get-qualification-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  qualification_type_id: string # The ID of the QualificationType.
  worker_id: string # The ID of the Worker whose Qualification is being updated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.GetQualificationScore"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}, {name: WorkerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetQualificationTypeoperation retrieves information about a Qualification type using its ID.
#
# POST /
# Returns: record<QualificationType: record<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>
# operationId: GetQualificationType
export def "get-qualification-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  qualification_type_id: string # The ID of the QualificationType.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.GetQualificationType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListAssignmentsForHIT operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. Only the Requester who created the HIT can retrieve the assignments for that HIT. Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination.
#
# POST /
# Returns: record<NextToken: string, NumResults: int, Assignments: table<AssignmentId: string, WorkerId: string, HITId: string, AssignmentStatus: string, AutoApprovalTime: string, AcceptTime: string, SubmitTime: string, ApprovalTime: string, RejectionTime: string, Deadline: string, Answer: string, RequesterFeedback: string>>
# operationId: ListAssignmentsForHIT
export def "list-assignments-for-hit" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  hit_id: string # The ID of the HIT.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # (spec name: MaxResults)
  --assignment-statuses: list<string> # The status of the assignments to return: Submitted | Approved | Rejected
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListAssignmentsForHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: AssignmentStatuses, var: assignment_statuses}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id, body_next_token: $body_next_token, body_max_results: $body_max_results, assignment_statuses: $assignment_statuses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListBonusPayments operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment.
#
# POST /
# Returns: record<NumResults: int, NextToken: string, BonusPayments: table<WorkerId: string, BonusAmount: string, AssignmentId: string, Reason: string, GrantTime: string>>
# operationId: ListBonusPayments
export def "list-bonus-payments" [
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
  --hit-id: string # The ID of the HIT associated with the bonus payments to retrieve. If not specified, all bonus payments for all assignments for the given HIT are returned. Either the HITId parameter or the AssignmentId parameter must be specified
  --assignment-id: string # The ID of the assignment associated with the bonus payments to retrieve. If specified, only bonus payments for the given assignment are returned. Either the HITId parameter or the AssignmentId parameter must be specified
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListBonusPayments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}, {name: AssignmentId, var: assignment_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id, assignment_id: $assignment_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListHITs operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted.
#
# POST /
# Returns: record<NextToken: string, NumResults: int, HITs: table<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>
# operationId: ListHITs
export def "list-hi-ts" [
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
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListHITs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListHITsForQualificationType operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the DeleteHIT operation or that have been auto-deleted.
#
# POST /
# Returns: record<NextToken: string, NumResults: int, HITs: table<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>
# operationId: ListHITsForQualificationType
export def "list-hi-ts-for-qualification-type" [
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
  qualification_type_id: string # The ID of the Qualification type to use when querying HITs.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # Limit the number of results returned. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListHITsForQualificationType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListQualificationRequests operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation.
#
# POST /
# Returns: record<NumResults: int, NextToken: string, QualificationRequests: table<QualificationRequestId: string, QualificationTypeId: string, WorkerId: string, Test: string, Answer: string, SubmitTime: string>>
# operationId: ListQualificationRequests
export def "list-qualification-requests" [
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
  --qualification-type-id: string # The ID of the QualificationType.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in a single call. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListQualificationRequests"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListQualificationTypes operation returns a list of Qualification types, filtered by an optional search term.
#
# POST /
# Returns: record<NumResults: int, NextToken: string, QualificationTypes: table<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>
# operationId: ListQualificationTypes
export def "list-qualification-types" [
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
  --query: string # A text query against all of the searchable attributes of Qualification types.
  --must-be-requestable: oneof<nothing, bool> # Specifies that only Qualification types that a user can request through the Amazon Mechanical Turk web site, such as by taking a Qualification test, are returned as results of the search. Some Qualification types, such as those assigned automatically by the system, cannot be requested directly by users. If false, all Qualification types, including those managed by the system, are considered. Valid values are True | False.
  --must-be-owned-by-caller: oneof<nothing, bool> # Specifies that only Qualification types that the Requester created are returned. If false, the operation returns all Qualification types.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in a single call. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListQualificationTypes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Query, var: query}, {name: MustBeRequestable, var: must_be_requestable, required: true}, {name: MustBeOwnedByCaller, var: must_be_owned_by_caller}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, query: $query, must_be_requestable: $must_be_requestable, must_be_owned_by_caller: $must_be_owned_by_caller, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListReviewPolicyResultsForHIT operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results.
#
# POST /
# Returns: record<HITId: string, AssignmentReviewPolicy: record<PolicyName: string, Parameters: list<record>>, HITReviewPolicy: record<PolicyName: string, Parameters: list<record>>, AssignmentReviewReport: record<ReviewResults: list<record>, ReviewActions: list<record>>, HITReviewReport: record<ReviewResults: list<record>, ReviewActions: list<record>>, NextToken: string>
# operationId: ListReviewPolicyResultsForHIT
export def "list-review-policy-results-for-hit" [
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
  hit_id: string # The unique identifier of the HIT to retrieve review results for.
  --policy-levels: list<string> # The Policy Level(s) to retrieve review results for - HIT or Assignment. If omitted, the default behavior is to retrieve all data for both policy levels. For a list of all the described policies, see Review Policies.
  --retrieve-actions: oneof<nothing, bool> # Specify if the operation should retrieve a list of the actions taken executing the Review Policies and their outcomes.
  --retrieve-results: oneof<nothing, bool> # Specify if the operation should retrieve a list of the results computed by the Review Policies.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # Limit the number of results returned. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}, {name: PolicyLevels, var: policy_levels}, {name: RetrieveActions, var: retrieve_actions}, {name: RetrieveResults, var: retrieve_results}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id, policy_levels: $policy_levels, retrieve_actions: $retrieve_actions, retrieve_results: $retrieve_results, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListReviewableHITs operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation.
#
# POST /
# Returns: record<NextToken: string, NumResults: int, HITs: table<HITId: string, HITTypeId: string, HITGroupId: string, HITLayoutId: string, CreationTime: string, Title: string, Description: string, Question: string, Keywords: string, HITStatus: string, MaxAssignments: int, Reward: string, AutoApprovalDelayInSeconds: int, Expiration: string, AssignmentDurationInSeconds: int, RequesterAnnotation: string, QualificationRequirements: list, HITReviewStatus: string, NumberOfAssignmentsPending: int, NumberOfAssignmentsAvailable: int, NumberOfAssignmentsCompleted: int>>
# operationId: ListReviewableHITs
export def "list-reviewable-hi-ts" [
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
  --hit-type-id: string # The ID of the HIT type of the HITs to consider for the query. If not specified, all HITs for the Reviewer are considered
  --status: string@status-completer # Can be either Reviewable or Reviewing. Reviewable is the default value.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # Limit the number of results returned. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListReviewableHITs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITTypeId, var: hit_type_id}, {name: Status, var: status}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_type_id: $hit_type_id, status: $status, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListWorkersBlocks operation retrieves a list of Workers who are blocked from working on your HITs.
#
# POST /
# Returns: record<NextToken: string, NumResults: int, WorkerBlocks: table<WorkerId: string, Reason: string>>
# operationId: ListWorkerBlocks
export def "list-worker-blocks" [
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
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListWorkerBlocks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListWorkersWithQualificationType operation returns all of the Workers that have been associated with a given Qualification type.
#
# POST /
# Returns: record<NextToken: string, NumResults: int, Qualifications: table<QualificationTypeId: string, WorkerId: string, GrantTime: string, IntegerValue: int, LocaleValue: record, Status: string>>
# operationId: ListWorkersWithQualificationType
export def "list-workers-with-qualification-type" [
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
  qualification_type_id: string # The ID of the Qualification type of the Qualifications to return.
  --status: string@status-completer-1 # The status of the Qualifications to return. Can be Granted | Revoked.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Mechanical Turk returns a pagination token in the response. You can use this pagination token to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # Limit the number of results returned. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.ListWorkersWithQualificationType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}, {name: Status, var: status}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id, status: $status, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The NotifyWorkers operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker.
#
# POST /
# Returns: record<NotifyWorkersFailureStatuses: table<NotifyWorkersFailureCode: string, NotifyWorkersFailureMessage: string, WorkerId: string>>
# operationId: NotifyWorkers
export def "notify-workers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subject: string # The subject line of the email message to send. Can include up to 200 characters.
  message_text: string # The text of the email message to send. Can include up to 4,096 characters
  worker_ids: list<string> # A list of Worker IDs you wish to notify. You can notify upto 100 Workers at a time.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.NotifyWorkers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Subject, var: subject}, {name: MessageText, var: message_text}, {name: WorkerIds, var: worker_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subject: $subject, message_text: $message_text, worker_ids: $worker_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The RejectAssignment operation rejects the results of a completed assignment. You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. Only the Requester who created the HIT can reject an assignment for the HIT.
#
# POST /
# Returns: record
# operationId: RejectAssignment
export def "reject-assignment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  assignment_id: string # The ID of the assignment. The assignment must correspond to a HIT created by the Requester.
  requester_feedback: string # A message for the Worker, which the Worker can see in the Status section of the web site.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.RejectAssignment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssignmentId, var: assignment_id}, {name: RequesterFeedback, var: requester_feedback}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, assignment_id: $assignment_id, requester_feedback: $requester_feedback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The RejectQualificationRequest operation rejects a user's request for a Qualification. You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.
#
# POST /
# Returns: record
# operationId: RejectQualificationRequest
export def "reject-qualification-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  qualification_request_id: string # The ID of the Qualification request, as returned by the ListQualificationRequests operation.
  --reason: string # A text message explaining why the request was rejected, to be shown to the Worker who made the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.RejectQualificationRequest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationRequestId, var: qualification_request_id}, {name: Reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_request_id: $qualification_request_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The SendBonus operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees.
#
# POST /
# Returns: record
# operationId: SendBonus
export def "send-bonus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  worker_id: string # The ID of the Worker being paid the bonus.
  bonus_amount: string # A string representing a currency amount.
  assignment_id: string # The ID of the assignment for which this bonus is paid.
  reason: string # A message that explains the reason for the bonus payment. The Worker receiving the bonus can see this message.
  --unique-request-token: string # A unique identifier for this request, which allows you to retry the call on error without granting multiple bonuses. This is useful in cases such as network timeouts where it is unclear whether or not the call succeeded on the server. If the bonus already exists in the system from a previous call using the same UniqueRequestToken, subsequent calls will return an error with a message containing the request ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.SendBonus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkerId, var: worker_id}, {name: BonusAmount, var: bonus_amount}, {name: AssignmentId, var: assignment_id}, {name: Reason, var: reason}, {name: UniqueRequestToken, var: unique_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, worker_id: $worker_id, bonus_amount: $bonus_amount, assignment_id: $assignment_id, reason: $reason, unique_request_token: $unique_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The SendTestEventNotification operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately.
#
# POST /
# Returns: record
# operationId: SendTestEventNotification
export def "send-test-event-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  notification: record # The NotificationSpecification data structure describes a HIT event notification for a HIT type. — shape: {Destination: string, Transport: "Email"|"SQS"|"SNS", Version: string, EventTypes: list<string>}
  test_event_type: string@test-event-type-completer # The event to simulate to test the notification specification. This event is included in the test message even if the notification specification does not include the event type. The notification specification does not filter out the test event.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.SendTestEventNotification"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Notification, var: notification}, {name: TestEventType, var: test_event_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, notification: $notification, test_event_type: $test_event_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The UpdateExpirationForHIT operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired.
#
# POST /
# Returns: record
# operationId: UpdateExpirationForHIT
export def "update-expiration-for-hit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_id: string # The HIT to update.
  expire_at: string # The date and time at which you want the HIT to expire (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.UpdateExpirationForHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}, {name: ExpireAt, var: expire_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id, expire_at: $expire_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The UpdateHITReviewStatus operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status.
#
# POST /
# Returns: record
# operationId: UpdateHITReviewStatus
export def "update-hit-review-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_id: string # The ID of the HIT to update.
  --revert: oneof<nothing, bool> # Specifies how to update the HIT status. Default is False. Setting this to false will only transition a HIT from Reviewable to Reviewing Setting this to true will only transition a HIT from Reviewing to Reviewable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.UpdateHITReviewStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}, {name: Revert, var: revert}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id, revert: $revert
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The UpdateHITTypeOfHIT operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones.
#
# POST /
# Returns: record
# operationId: UpdateHITTypeOfHIT
export def "update-hit-type-of-hit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_id: string # The HIT to update.
  hit_type_id: string # The ID of the new HIT type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITId, var: hit_id}, {name: HITTypeId, var: hit_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_id: $hit_id, hit_type_id: $hit_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The UpdateNotificationSettings operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to UpdateNotificationSettings.
#
# POST /
# Returns: record
# operationId: UpdateNotificationSettings
export def "update-notification-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  hit_type_id: string # The ID of the HIT type whose notification specification is being updated.
  --notification: record # The NotificationSpecification data structure describes a HIT event notification for a HIT type. — shape: {Destination: string, Transport: "Email"|"SQS"|"SNS", Version: string, EventTypes: list<string>}
  --active: oneof<nothing, bool> # Specifies whether notifications are sent for HITs of this HIT type, according to the notification specification. You must specify either the Notification parameter or the Active parameter for the call to UpdateNotificationSettings to succeed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.UpdateNotificationSettings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HITTypeId, var: hit_type_id}, {name: Notification, var: notification}, {name: Active, var: active}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, hit_type_id: $hit_type_id, notification: $notification, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The UpdateQualificationType operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.
#
# POST /
# Returns: record<QualificationType: record<QualificationTypeId: string, CreationTime: string, Name: string, Description: string, Keywords: string, QualificationTypeStatus: string, Test: string, TestDurationInSeconds: int, AnswerKey: string, RetryDelayInSeconds: int, IsRequestable: bool, AutoGranted: bool, AutoGrantedValue: int>>
# operationId: UpdateQualificationType
export def "update-qualification-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  qualification_type_id: string # The ID of the Qualification type to update.
  --description: string # The new description of the Qualification type.
  --qualification-type-status: string@qualification-type-status-completer # The new status of the Qualification type - Active | Inactive
  --test: string # The questions for the Qualification test a Worker must answer correctly to obtain a Qualification of this type. If this parameter is specified, TestDurationInSeconds must also be specified. Constraints: Must not be longer than 65535 bytes. Must be a QuestionForm data structure. This parameter cannot be specified if AutoGranted is true. Constraints: None. If not specified, the Worker may request the Qualification without answering any questions.
  --answer-key: string # The answers to the Qualification test specified in the Test parameter, in the form of an AnswerKey data structure.
  --test-duration-in-seconds: int # The number of seconds the Worker has to complete the Qualification test, starting from the time the Worker requests the Qualification.
  --retry-delay-in-seconds: int # The amount of time, in seconds, that Workers must wait after requesting a Qualification of the specified Qualification type before they can retry the Qualification request. It is not possible to disable retries for a Qualification type after it has been created with retries enabled. If you want to disable retries, you must dispose of the existing retry-enabled Qualification type using DisposeQualificationType and then create a new Qualification type with retries disabled using CreateQualificationType.
  --auto-granted: oneof<nothing, bool> # Specifies whether requests for the Qualification type are granted immediately, without prompting the Worker with a Qualification test. Constraints: If the Test parameter is specified, this parameter cannot be true.
  --auto-granted-value: int # The Qualification value to use for automatically granted Qualifications. This parameter is used only if the AutoGranted parameter is true.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "MTurkRequesterServiceV20170117.UpdateQualificationType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QualificationTypeId, var: qualification_type_id}, {name: Description, var: description}, {name: QualificationTypeStatus, var: qualification_type_status}, {name: Test, var: test}, {name: AnswerKey, var: answer_key}, {name: TestDurationInSeconds, var: test_duration_in_seconds}, {name: RetryDelayInSeconds, var: retry_delay_in_seconds}, {name: AutoGranted, var: auto_granted}, {name: AutoGrantedValue, var: auto_granted_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, qualification_type_id: $qualification_type_id, description: $description, qualification_type_status: $qualification_type_status, test: $test, answer_key: $answer_key, test_duration_in_seconds: $test_duration_in_seconds, retry_delay_in_seconds: $retry_delay_in_seconds, auto_granted: $auto_granted, auto_granted_value: $auto_granted_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
