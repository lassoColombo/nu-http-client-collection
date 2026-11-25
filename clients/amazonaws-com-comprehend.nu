# Auto-generated client for Amazon Comprehend v2017-11-27
# Source: https://api.apis.guru/v2/specs/amazonaws.com/comprehend/2017-11-27/openapi.json
# Auth: --token flag or $env.AMAZON_COMPREHEND_TOKEN

const CLIENT = {
  base_url: "http://comprehend.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_COMPREHEND_TOKEN"
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

def base-url-completer [] { ["http://comprehend.us-east-1.amazonaws.com" "http://comprehend.us-east-2.amazonaws.com" "http://comprehend.us-west-1.amazonaws.com" "http://comprehend.us-west-2.amazonaws.com" "http://comprehend.us-gov-west-1.amazonaws.com" "http://comprehend.us-gov-east-1.amazonaws.com" "http://comprehend.ca-central-1.amazonaws.com" "http://comprehend.eu-north-1.amazonaws.com" "http://comprehend.eu-west-1.amazonaws.com" "http://comprehend.eu-west-2.amazonaws.com" "http://comprehend.eu-west-3.amazonaws.com" "http://comprehend.eu-central-1.amazonaws.com" "http://comprehend.eu-south-1.amazonaws.com" "http://comprehend.af-south-1.amazonaws.com" "http://comprehend.ap-northeast-1.amazonaws.com" "http://comprehend.ap-northeast-2.amazonaws.com" "http://comprehend.ap-northeast-3.amazonaws.com" "http://comprehend.ap-southeast-1.amazonaws.com" "http://comprehend.ap-southeast-2.amazonaws.com" "http://comprehend.ap-east-1.amazonaws.com" "http://comprehend.ap-south-1.amazonaws.com" "http://comprehend.sa-east-1.amazonaws.com" "http://comprehend.me-south-1.amazonaws.com" "https://comprehend.us-east-1.amazonaws.com" "https://comprehend.us-east-2.amazonaws.com" "https://comprehend.us-west-1.amazonaws.com" "https://comprehend.us-west-2.amazonaws.com" "https://comprehend.us-gov-west-1.amazonaws.com" "https://comprehend.us-gov-east-1.amazonaws.com" "https://comprehend.ca-central-1.amazonaws.com" "https://comprehend.eu-north-1.amazonaws.com" "https://comprehend.eu-west-1.amazonaws.com" "https://comprehend.eu-west-2.amazonaws.com" "https://comprehend.eu-west-3.amazonaws.com" "https://comprehend.eu-central-1.amazonaws.com" "https://comprehend.eu-south-1.amazonaws.com" "https://comprehend.af-south-1.amazonaws.com" "https://comprehend.ap-northeast-1.amazonaws.com" "https://comprehend.ap-northeast-2.amazonaws.com" "https://comprehend.ap-northeast-3.amazonaws.com" "https://comprehend.ap-southeast-1.amazonaws.com" "https://comprehend.ap-southeast-2.amazonaws.com" "https://comprehend.ap-east-1.amazonaws.com" "https://comprehend.ap-south-1.amazonaws.com" "https://comprehend.sa-east-1.amazonaws.com" "https://comprehend.me-south-1.amazonaws.com" "http://comprehend.cn-north-1.amazonaws.com.cn" "http://comprehend.cn-northwest-1.amazonaws.com.cn" "https://comprehend.cn-north-1.amazonaws.com.cn" "https://comprehend.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Comprehend_20171127.BatchDetectDominantLanguage"] }
def language-code-completer [] { ["ar" "de" "en" "es" "fr" "hi" "it" "ja" "ko" "pt" "zh" "zh-TW"] }
def x-amz-target-completer-1 [] { ["Comprehend_20171127.BatchDetectEntities"] }
def x-amz-target-completer-2 [] { ["Comprehend_20171127.BatchDetectKeyPhrases"] }
def x-amz-target-completer-3 [] { ["Comprehend_20171127.BatchDetectSentiment"] }
def language-code-completer-1 [] { ["de" "en" "es" "fr" "it" "pt"] }
def x-amz-target-completer-4 [] { ["Comprehend_20171127.BatchDetectSyntax"] }
def x-amz-target-completer-5 [] { ["Comprehend_20171127.BatchDetectTargetedSentiment"] }
def x-amz-target-completer-6 [] { ["Comprehend_20171127.ClassifyDocument"] }
def x-amz-target-completer-7 [] { ["Comprehend_20171127.ContainsPiiEntities"] }
def dataset-type-completer [] { ["TEST" "TRAIN"] }
def x-amz-target-completer-8 [] { ["Comprehend_20171127.CreateDataset"] }
def mode-completer [] { ["MULTI_CLASS" "MULTI_LABEL"] }
def x-amz-target-completer-9 [] { ["Comprehend_20171127.CreateDocumentClassifier"] }
def x-amz-target-completer-10 [] { ["Comprehend_20171127.CreateEndpoint"] }
def x-amz-target-completer-11 [] { ["Comprehend_20171127.CreateEntityRecognizer"] }
def model-type-completer [] { ["DOCUMENT_CLASSIFIER" "ENTITY_RECOGNIZER"] }
def x-amz-target-completer-12 [] { ["Comprehend_20171127.CreateFlywheel"] }
def x-amz-target-completer-13 [] { ["Comprehend_20171127.DeleteDocumentClassifier"] }
def x-amz-target-completer-14 [] { ["Comprehend_20171127.DeleteEndpoint"] }
def x-amz-target-completer-15 [] { ["Comprehend_20171127.DeleteEntityRecognizer"] }
def x-amz-target-completer-16 [] { ["Comprehend_20171127.DeleteFlywheel"] }
def x-amz-target-completer-17 [] { ["Comprehend_20171127.DeleteResourcePolicy"] }
def x-amz-target-completer-18 [] { ["Comprehend_20171127.DescribeDataset"] }
def x-amz-target-completer-19 [] { ["Comprehend_20171127.DescribeDocumentClassificationJob"] }
def x-amz-target-completer-20 [] { ["Comprehend_20171127.DescribeDocumentClassifier"] }
def x-amz-target-completer-21 [] { ["Comprehend_20171127.DescribeDominantLanguageDetectionJob"] }
def x-amz-target-completer-22 [] { ["Comprehend_20171127.DescribeEndpoint"] }
def x-amz-target-completer-23 [] { ["Comprehend_20171127.DescribeEntitiesDetectionJob"] }
def x-amz-target-completer-24 [] { ["Comprehend_20171127.DescribeEntityRecognizer"] }
def x-amz-target-completer-25 [] { ["Comprehend_20171127.DescribeEventsDetectionJob"] }
def x-amz-target-completer-26 [] { ["Comprehend_20171127.DescribeFlywheel"] }
def x-amz-target-completer-27 [] { ["Comprehend_20171127.DescribeFlywheelIteration"] }
def x-amz-target-completer-28 [] { ["Comprehend_20171127.DescribeKeyPhrasesDetectionJob"] }
def x-amz-target-completer-29 [] { ["Comprehend_20171127.DescribePiiEntitiesDetectionJob"] }
def x-amz-target-completer-30 [] { ["Comprehend_20171127.DescribeResourcePolicy"] }
def x-amz-target-completer-31 [] { ["Comprehend_20171127.DescribeSentimentDetectionJob"] }
def x-amz-target-completer-32 [] { ["Comprehend_20171127.DescribeTargetedSentimentDetectionJob"] }
def x-amz-target-completer-33 [] { ["Comprehend_20171127.DescribeTopicsDetectionJob"] }
def x-amz-target-completer-34 [] { ["Comprehend_20171127.DetectDominantLanguage"] }
def x-amz-target-completer-35 [] { ["Comprehend_20171127.DetectEntities"] }
def x-amz-target-completer-36 [] { ["Comprehend_20171127.DetectKeyPhrases"] }
def x-amz-target-completer-37 [] { ["Comprehend_20171127.DetectPiiEntities"] }
def x-amz-target-completer-38 [] { ["Comprehend_20171127.DetectSentiment"] }
def x-amz-target-completer-39 [] { ["Comprehend_20171127.DetectSyntax"] }
def x-amz-target-completer-40 [] { ["Comprehend_20171127.DetectTargetedSentiment"] }
def x-amz-target-completer-41 [] { ["Comprehend_20171127.ImportModel"] }
def x-amz-target-completer-42 [] { ["Comprehend_20171127.ListDatasets"] }
def x-amz-target-completer-43 [] { ["Comprehend_20171127.ListDocumentClassificationJobs"] }
def x-amz-target-completer-44 [] { ["Comprehend_20171127.ListDocumentClassifierSummaries"] }
def x-amz-target-completer-45 [] { ["Comprehend_20171127.ListDocumentClassifiers"] }
def x-amz-target-completer-46 [] { ["Comprehend_20171127.ListDominantLanguageDetectionJobs"] }
def x-amz-target-completer-47 [] { ["Comprehend_20171127.ListEndpoints"] }
def x-amz-target-completer-48 [] { ["Comprehend_20171127.ListEntitiesDetectionJobs"] }
def x-amz-target-completer-49 [] { ["Comprehend_20171127.ListEntityRecognizerSummaries"] }
def x-amz-target-completer-50 [] { ["Comprehend_20171127.ListEntityRecognizers"] }
def x-amz-target-completer-51 [] { ["Comprehend_20171127.ListEventsDetectionJobs"] }
def x-amz-target-completer-52 [] { ["Comprehend_20171127.ListFlywheelIterationHistory"] }
def x-amz-target-completer-53 [] { ["Comprehend_20171127.ListFlywheels"] }
def x-amz-target-completer-54 [] { ["Comprehend_20171127.ListKeyPhrasesDetectionJobs"] }
def x-amz-target-completer-55 [] { ["Comprehend_20171127.ListPiiEntitiesDetectionJobs"] }
def x-amz-target-completer-56 [] { ["Comprehend_20171127.ListSentimentDetectionJobs"] }
def x-amz-target-completer-57 [] { ["Comprehend_20171127.ListTagsForResource"] }
def x-amz-target-completer-58 [] { ["Comprehend_20171127.ListTargetedSentimentDetectionJobs"] }
def x-amz-target-completer-59 [] { ["Comprehend_20171127.ListTopicsDetectionJobs"] }
def x-amz-target-completer-60 [] { ["Comprehend_20171127.PutResourcePolicy"] }
def x-amz-target-completer-61 [] { ["Comprehend_20171127.StartDocumentClassificationJob"] }
def x-amz-target-completer-62 [] { ["Comprehend_20171127.StartDominantLanguageDetectionJob"] }
def x-amz-target-completer-63 [] { ["Comprehend_20171127.StartEntitiesDetectionJob"] }
def x-amz-target-completer-64 [] { ["Comprehend_20171127.StartEventsDetectionJob"] }
def x-amz-target-completer-65 [] { ["Comprehend_20171127.StartFlywheelIteration"] }
def x-amz-target-completer-66 [] { ["Comprehend_20171127.StartKeyPhrasesDetectionJob"] }
def mode-completer-1 [] { ["ONLY_OFFSETS" "ONLY_REDACTION"] }
def x-amz-target-completer-67 [] { ["Comprehend_20171127.StartPiiEntitiesDetectionJob"] }
def x-amz-target-completer-68 [] { ["Comprehend_20171127.StartSentimentDetectionJob"] }
def x-amz-target-completer-69 [] { ["Comprehend_20171127.StartTargetedSentimentDetectionJob"] }
def x-amz-target-completer-70 [] { ["Comprehend_20171127.StartTopicsDetectionJob"] }
def x-amz-target-completer-71 [] { ["Comprehend_20171127.StopDominantLanguageDetectionJob"] }
def x-amz-target-completer-72 [] { ["Comprehend_20171127.StopEntitiesDetectionJob"] }
def x-amz-target-completer-73 [] { ["Comprehend_20171127.StopEventsDetectionJob"] }
def x-amz-target-completer-74 [] { ["Comprehend_20171127.StopKeyPhrasesDetectionJob"] }
def x-amz-target-completer-75 [] { ["Comprehend_20171127.StopPiiEntitiesDetectionJob"] }
def x-amz-target-completer-76 [] { ["Comprehend_20171127.StopSentimentDetectionJob"] }
def x-amz-target-completer-77 [] { ["Comprehend_20171127.StopTargetedSentimentDetectionJob"] }
def x-amz-target-completer-78 [] { ["Comprehend_20171127.StopTrainingDocumentClassifier"] }
def x-amz-target-completer-79 [] { ["Comprehend_20171127.StopTrainingEntityRecognizer"] }
def x-amz-target-completer-80 [] { ["Comprehend_20171127.TagResource"] }
def x-amz-target-completer-81 [] { ["Comprehend_20171127.UntagResource"] }
def x-amz-target-completer-82 [] { ["Comprehend_20171127.UpdateEndpoint"] }
def x-amz-target-completer-83 [] { ["Comprehend_20171127.UpdateFlywheel"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-detect-dominant-language: "record<ResultList: table<Index: int, Languages: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>"
    batch-detect-entities: "record<ResultList: table<Index: int, Entities: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>"
    batch-detect-key-phrases: "record<ResultList: table<Index: int, KeyPhrases: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>"
    batch-detect-sentiment: "record<ResultList: table<Index: int, Sentiment: string, SentimentScore: record>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>"
    batch-detect-syntax: "record<ResultList: table<Index: int, SyntaxTokens: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>"
    batch-detect-targeted-sentiment: "record<ResultList: table<Index: int, Entities: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>"
    classify-document: "record<Classes: table<Name: string, Score: float, Page: int>, Labels: table<Name: string, Score: float, Page: int>, DocumentMetadata: record<Pages: int, ExtractedCharacters: list<record>>, DocumentType: table<Page: int, Type: string>, Errors: table<Page: int, ErrorCode: string, ErrorMessage: string>, Warnings: table<Page: int, WarnCode: string, WarnMessage: string>>"
    contains-pii-entities: "record<Labels: table<Name: string, Score: float>>"
    create-dataset: "record<DatasetArn: string>"
    create-document-classifier: "record<DocumentClassifierArn: string>"
    create-endpoint: "record<EndpointArn: string, ModelArn: string>"
    create-entity-recognizer: "record<EntityRecognizerArn: string>"
    create-flywheel: "record<FlywheelArn: string, ActiveModelArn: string>"
    delete-document-classifier: "record"
    delete-endpoint: "record"
    delete-entity-recognizer: "record"
    delete-flywheel: "record"
    delete-resource-policy: "record"
    describe-dataset: "record<DatasetProperties: record<DatasetArn: string, DatasetName: string, DatasetType: string, DatasetS3Uri: string, Description: string, Status: string, Message: string, NumberOfDocuments: int, CreationTime: string, EndTime: string>>"
    describe-document-classification-job: "record<DocumentClassificationJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, DocumentClassifierArn: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, FlywheelArn: string>>"
    describe-document-classifier: "record<DocumentClassifierProperties: record<DocumentClassifierArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record<DataFormat: string, S3Uri: string, TestS3Uri: string, LabelDelimiter: string, AugmentedManifests: list, DocumentType: string, Documents: record, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string, FlywheelStatsS3Prefix: string>, ClassifierMetadata: record<NumberOfLabels: int, NumberOfTrainedDocuments: int, NumberOfTestDocuments: int, EvaluationMetrics: record>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, Mode: string, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string>>"
    describe-dominant-language-detection-job: "record<DominantLanguageDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>"
    describe-endpoint: "record<EndpointProperties: record<EndpointArn: string, Status: string, Message: string, ModelArn: string, DesiredModelArn: string, DesiredInferenceUnits: int, CurrentInferenceUnits: int, CreationTime: string, LastModifiedTime: string, DataAccessRoleArn: string, DesiredDataAccessRoleArn: string, FlywheelArn: string>>"
    describe-entities-detection-job: "record<EntitiesDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, EntityRecognizerArn: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, FlywheelArn: string>>"
    describe-entity-recognizer: "record<EntityRecognizerProperties: record<EntityRecognizerArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record<DataFormat: string, EntityTypes: list, Documents: record, Annotations: record, EntityList: record, AugmentedManifests: list>, RecognizerMetadata: record<NumberOfTrainedDocuments: int, NumberOfTestDocuments: int, EvaluationMetrics: record, EntityTypes: list>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string, OutputDataConfig: record<FlywheelStatsS3Prefix: string>>>"
    describe-events-detection-job: "record<EventsDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, TargetEventTypes: list<string>>>"
    describe-flywheel: "record<FlywheelProperties: record<FlywheelArn: string, ActiveModelArn: string, DataAccessRoleArn: string, TaskConfig: record<LanguageCode: string, DocumentClassificationConfig: record, EntityRecognitionConfig: record>, DataLakeS3Uri: string, DataSecurityConfig: record<ModelKmsKeyId: string, VolumeKmsKeyId: string, DataLakeKmsKeyId: string, VpcConfig: record>, Status: string, ModelType: string, Message: string, CreationTime: string, LastModifiedTime: string, LatestFlywheelIteration: string>>"
    describe-flywheel-iteration: "record<FlywheelIterationProperties: record<FlywheelArn: string, FlywheelIterationId: string, CreationTime: string, EndTime: string, Status: string, Message: string, EvaluatedModelArn: string, EvaluatedModelMetrics: record<AverageF1Score: float, AveragePrecision: float, AverageRecall: float, AverageAccuracy: float>, TrainedModelArn: string, TrainedModelMetrics: record<AverageF1Score: float, AveragePrecision: float, AverageRecall: float, AverageAccuracy: float>, EvaluationManifestS3Prefix: string>>"
    describe-key-phrases-detection-job: "record<KeyPhrasesDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>"
    describe-pii-entities-detection-job: "record<PiiEntitiesDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, RedactionConfig: record<PiiEntityTypes: list, MaskMode: string, MaskCharacter: string>, LanguageCode: string, DataAccessRoleArn: string, Mode: string>>"
    describe-resource-policy: "record<ResourcePolicy: string, CreationTime: string, LastModifiedTime: string, PolicyRevisionId: string>"
    describe-sentiment-detection-job: "record<SentimentDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>"
    describe-targeted-sentiment-detection-job: "record<TargetedSentimentDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>"
    describe-topics-detection-job: "record<TopicsDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, NumberOfTopics: int, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>"
    detect-dominant-language: "record<Languages: table<LanguageCode: string, Score: float>>"
    detect-entities: "record<Entities: table<Score: float, Type: string, Text: string, BeginOffset: int, EndOffset: int, BlockReferences: list>, DocumentMetadata: record<Pages: int, ExtractedCharacters: list<record>>, DocumentType: table<Page: int, Type: string>, Blocks: table<Id: string, BlockType: string, Text: string, Page: int, Geometry: record, Relationships: list>, Errors: table<Page: int, ErrorCode: string, ErrorMessage: string>>"
    detect-key-phrases: "record<KeyPhrases: table<Score: float, Text: string, BeginOffset: int, EndOffset: int>>"
    detect-pii-entities: "record<Entities: table<Score: float, Type: string, BeginOffset: int, EndOffset: int>>"
    detect-sentiment: "record<Sentiment: string, SentimentScore: record<Positive: float, Negative: float, Neutral: float, Mixed: float>>"
    detect-syntax: "record<SyntaxTokens: table<TokenId: int, Text: string, BeginOffset: int, EndOffset: int, PartOfSpeech: record>>"
    detect-targeted-sentiment: "record<Entities: table<DescriptiveMentionIndex: list, Mentions: list>>"
    import-model: "record<ModelArn: string>"
    list-datasets: "record<DatasetPropertiesList: table<DatasetArn: string, DatasetName: string, DatasetType: string, DatasetS3Uri: string, Description: string, Status: string, Message: string, NumberOfDocuments: int, CreationTime: string, EndTime: string>, NextToken: string>"
    list-document-classification-jobs: "record<DocumentClassificationJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, DocumentClassifierArn: string, InputDataConfig: record, OutputDataConfig: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, FlywheelArn: string>, NextToken: string>"
    list-document-classifier-summaries: "record<DocumentClassifierSummariesList: table<DocumentClassifierName: string, NumberOfVersions: int, LatestVersionCreatedAt: string, LatestVersionName: string, LatestVersionStatus: string>, NextToken: string>"
    list-document-classifiers: "record<DocumentClassifierPropertiesList: table<DocumentClassifierArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record, OutputDataConfig: record, ClassifierMetadata: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, Mode: string, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string>, NextToken: string>"
    list-dominant-language-detection-jobs: "record<DominantLanguageDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>"
    list-endpoints: "record<EndpointPropertiesList: table<EndpointArn: string, Status: string, Message: string, ModelArn: string, DesiredModelArn: string, DesiredInferenceUnits: int, CurrentInferenceUnits: int, CreationTime: string, LastModifiedTime: string, DataAccessRoleArn: string, DesiredDataAccessRoleArn: string, FlywheelArn: string>, NextToken: string>"
    list-entities-detection-jobs: "record<EntitiesDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, EntityRecognizerArn: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, FlywheelArn: string>, NextToken: string>"
    list-entity-recognizer-summaries: "record<EntityRecognizerSummariesList: table<RecognizerName: string, NumberOfVersions: int, LatestVersionCreatedAt: string, LatestVersionName: string, LatestVersionStatus: string>, NextToken: string>"
    list-entity-recognizers: "record<EntityRecognizerPropertiesList: table<EntityRecognizerArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record, RecognizerMetadata: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string, OutputDataConfig: record>, NextToken: string>"
    list-events-detection-jobs: "record<EventsDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, TargetEventTypes: list>, NextToken: string>"
    list-flywheel-iteration-history: "record<FlywheelIterationPropertiesList: table<FlywheelArn: string, FlywheelIterationId: string, CreationTime: string, EndTime: string, Status: string, Message: string, EvaluatedModelArn: string, EvaluatedModelMetrics: record, TrainedModelArn: string, TrainedModelMetrics: record, EvaluationManifestS3Prefix: string>, NextToken: string>"
    list-flywheels: "record<FlywheelSummaryList: table<FlywheelArn: string, ActiveModelArn: string, DataLakeS3Uri: string, Status: string, ModelType: string, Message: string, CreationTime: string, LastModifiedTime: string, LatestFlywheelIteration: string>, NextToken: string>"
    list-key-phrases-detection-jobs: "record<KeyPhrasesDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>"
    list-pii-entities-detection-jobs: "record<PiiEntitiesDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, RedactionConfig: record, LanguageCode: string, DataAccessRoleArn: string, Mode: string>, NextToken: string>"
    list-sentiment-detection-jobs: "record<SentimentDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>"
    list-tags-for-resource: "record<ResourceArn: string, Tags: table<Key: string, Value: string>>"
    list-targeted-sentiment-detection-jobs: "record<TargetedSentimentDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>"
    list-topics-detection-jobs: "record<TopicsDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, NumberOfTopics: int, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>"
    put-resource-policy: "record<PolicyRevisionId: string>"
    start-document-classification-job: "record<JobId: string, JobArn: string, JobStatus: string, DocumentClassifierArn: string>"
    start-dominant-language-detection-job: "record<JobId: string, JobArn: string, JobStatus: string>"
    start-entities-detection-job: "record<JobId: string, JobArn: string, JobStatus: string, EntityRecognizerArn: string>"
    start-events-detection-job: "record<JobId: string, JobArn: string, JobStatus: string>"
    start-flywheel-iteration: "record<FlywheelArn: string, FlywheelIterationId: string>"
    start-key-phrases-detection-job: "record<JobId: string, JobArn: string, JobStatus: string>"
    start-pii-entities-detection-job: "record<JobId: string, JobArn: string, JobStatus: string>"
    start-sentiment-detection-job: "record<JobId: string, JobArn: string, JobStatus: string>"
    start-targeted-sentiment-detection-job: "record<JobId: string, JobArn: string, JobStatus: string>"
    start-topics-detection-job: "record<JobId: string, JobArn: string, JobStatus: string>"
    stop-dominant-language-detection-job: "record<JobId: string, JobStatus: string>"
    stop-entities-detection-job: "record<JobId: string, JobStatus: string>"
    stop-events-detection-job: "record<JobId: string, JobStatus: string>"
    stop-key-phrases-detection-job: "record<JobId: string, JobStatus: string>"
    stop-pii-entities-detection-job: "record<JobId: string, JobStatus: string>"
    stop-sentiment-detection-job: "record<JobId: string, JobStatus: string>"
    stop-targeted-sentiment-detection-job: "record<JobId: string, JobStatus: string>"
    stop-training-document-classifier: "record"
    stop-training-entity-recognizer: "record"
    tag-resource: "record"
    untag-resource: "record"
    update-endpoint: "record<DesiredModelArn: string>"
    update-flywheel: "record<FlywheelProperties: record<FlywheelArn: string, ActiveModelArn: string, DataAccessRoleArn: string, TaskConfig: record<LanguageCode: string, DocumentClassificationConfig: record, EntityRecognitionConfig: record>, DataLakeS3Uri: string, DataSecurityConfig: record<ModelKmsKeyId: string, VolumeKmsKeyId: string, DataLakeKmsKeyId: string, VpcConfig: record>, Status: string, ModelType: string, Message: string, CreationTime: string, LastModifiedTime: string, LatestFlywheelIteration: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-detect-dominant-language" "batch-detect-entities" "batch-detect-key-phrases" "batch-detect-sentiment" "batch-detect-syntax" "batch-detect-targeted-sentiment" "classify-document" "contains-pii-entities" "create-dataset" "create-document-classifier" "create-endpoint" "create-entity-recognizer" "create-flywheel" "delete-document-classifier" "delete-endpoint" "delete-entity-recognizer" "delete-flywheel" "delete-resource-policy" "describe-dataset" "describe-document-classification-job" "describe-document-classifier" "describe-dominant-language-detection-job" "describe-endpoint" "describe-entities-detection-job" "describe-entity-recognizer" "describe-events-detection-job" "describe-flywheel" "describe-flywheel-iteration" "describe-key-phrases-detection-job" "describe-pii-entities-detection-job" "describe-resource-policy" "describe-sentiment-detection-job" "describe-targeted-sentiment-detection-job" "describe-topics-detection-job" "detect-dominant-language" "detect-entities" "detect-key-phrases" "detect-pii-entities" "detect-sentiment" "detect-syntax" "detect-targeted-sentiment" "import-model" "list-datasets" "list-document-classification-jobs" "list-document-classifier-summaries" "list-document-classifiers" "list-dominant-language-detection-jobs" "list-endpoints" "list-entities-detection-jobs" "list-entity-recognizer-summaries" "list-entity-recognizers" "list-events-detection-jobs" "list-flywheel-iteration-history" "list-flywheels" "list-key-phrases-detection-jobs" "list-pii-entities-detection-jobs" "list-sentiment-detection-jobs" "list-tags-for-resource" "list-targeted-sentiment-detection-jobs" "list-topics-detection-jobs" "put-resource-policy" "start-document-classification-job" "start-dominant-language-detection-job" "start-entities-detection-job" "start-events-detection-job" "start-flywheel-iteration" "start-key-phrases-detection-job" "start-pii-entities-detection-job" "start-sentiment-detection-job" "start-targeted-sentiment-detection-job" "start-topics-detection-job" "stop-dominant-language-detection-job" "stop-entities-detection-job" "stop-events-detection-job" "stop-key-phrases-detection-job" "stop-pii-entities-detection-job" "stop-sentiment-detection-job" "stop-targeted-sentiment-detection-job" "stop-training-document-classifier" "stop-training-entity-recognizer" "tag-resource" "untag-resource" "update-endpoint" "update-flywheel" "commands"] | sort) } | get name | first)
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

# Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see Amazon Comprehend Supported Languages (https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html).
#
# POST /
# Returns: record<ResultList: table<Index: int, Languages: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDetectDominantLanguage
export def "batch-detect-dominant-language" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text_list: list<string> # A list containing the UTF-8 encoded text of the input documents. The list can contain a maximum of 25 documents. Each document should contain at least 20 characters. The maximum size of each document is 5 KB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.BatchDetectDominantLanguage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TextList, var: text_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text_list: $text_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see Entities (https://docs.aws.amazon.com/comprehend/latest/dg/how-entities.html) in the Comprehend Developer Guide.
#
# POST /
# Returns: record<ResultList: table<Index: int, Entities: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDetectEntities
export def "batch-detect-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text_list: list<string> # A list containing the UTF-8 encoded text of the input documents. The list can contain a maximum of 25 documents. The maximum size of each document is 5 KB.
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. All documents must be in the same language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.BatchDetectEntities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TextList, var: text_list}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text_list: $text_list, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detects the key noun phrases found in a batch of documents.
#
# POST /
# Returns: record<ResultList: table<Index: int, KeyPhrases: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDetectKeyPhrases
export def "batch-detect-key-phrases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text_list: list<string> # A list containing the UTF-8 encoded text of the input documents. The list can contain a maximum of 25 documents. The maximum size of each document is 5 KB.
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. All documents must be in the same language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.BatchDetectKeyPhrases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TextList, var: text_list}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text_list: $text_list, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects a batch of documents and returns an inference of the prevailing sentiment, POSITIVE, NEUTRAL, MIXED, or NEGATIVE, in each one.
#
# POST /
# Returns: record<ResultList: table<Index: int, Sentiment: string, SentimentScore: record>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDetectSentiment
export def "batch-detect-sentiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text_list: list<string> # A list containing the UTF-8 encoded text of the input documents. The list can contain a maximum of 25 documents. The maximum size of each document is 5 KB.
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. All documents must be in the same language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.BatchDetectSentiment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TextList, var: text_list}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text_list: $text_list, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see Syntax (https://docs.aws.amazon.com/comprehend/latest/dg/how-syntax.html) in the Comprehend Developer Guide.
#
# POST /
# Returns: record<ResultList: table<Index: int, SyntaxTokens: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDetectSyntax
export def "batch-detect-syntax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text_list: list<string> # A list containing the UTF-8 encoded text of the input documents. The list can contain a maximum of 25 documents. The maximum size for each document is 5 KB.
  language_code: string@language-code-completer-1 # The language of the input documents. You can specify any of the following languages supported by Amazon Comprehend: German ("de"), English ("en"), Spanish ("es"), French ("fr"), Italian ("it"), or Portuguese ("pt"). All documents must be in the same language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.BatchDetectSyntax"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TextList, var: text_list}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text_list: $text_list, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects a batch of documents and returns a sentiment analysis for each entity identified in the documents. For more information about targeted sentiment, see Targeted sentiment (https://docs.aws.amazon.com/comprehend/latest/dg/how-targeted-sentiment.html).
#
# POST /
# Returns: record<ResultList: table<Index: int, Entities: list>, ErrorList: table<Index: int, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDetectTargetedSentiment
export def "batch-detect-targeted-sentiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text_list: list<string> # A list containing the UTF-8 encoded text of the input documents. The list can contain a maximum of 25 documents. The maximum size of each document is 5 KB.
  language_code: string@language-code-completer # The language of the input documents. Currently, English is the only supported language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.BatchDetectTargetedSentiment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TextList, var: text_list}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text_list: $text_list, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new document classification request to analyze a single document in real-time, using a previously created and trained custom model and an endpoint. You can input plain text or you can upload a single-page input document (text, PDF, Word, or image). If the system detects errors while processing a page in the input document, the API response includes an entry in Errors that describes the errors. If the system detects a document-level error in your input document, the API returns an InvalidRequestException error response. For details about this exception, see Errors in semi-structured documents (https://docs.aws.amazon.com/comprehend/latest/dg/idp-inputs-sync-err.html) in the Comprehend Developer Guide.
#
# POST /
# Returns: record<Classes: table<Name: string, Score: float, Page: int>, Labels: table<Name: string, Score: float, Page: int>, DocumentMetadata: record<Pages: int, ExtractedCharacters: list<record>>, DocumentType: table<Page: int, Type: string>, Errors: table<Page: int, ErrorCode: string, ErrorMessage: string>, Warnings: table<Page: int, WarnCode: string, WarnMessage: string>>
# operationId: ClassifyDocument
export def "classify-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --text: string # The document text to be analyzed. If you enter text using this parameter, do not use the Bytes parameter. (format: password)
  endpoint_arn: string # The Amazon Resource Number (ARN) of the endpoint. For information about endpoints, see Managing endpoints (https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
  --bytes: string # Use the Bytes parameter to input a text, PDF, Word or image file. You can also use the Bytes parameter to input an Amazon Textract DetectDocumentText or AnalyzeDocument output file. Provide the input document as a sequence of base64-encoded bytes. If your code uses an Amazon Web Services SDK to classify documents, the SDK may encode the document file bytes for you. The maximum length of this field depends on the input document type. For details, see Inputs for real-time custom analysis (https://docs.aws.amazon.com/comprehend/latest/dg/idp-inputs-sync.html) in the Comprehend Developer Guide. If you use the Bytes parameter, do not use the Text parameter.
  --document-reader-config: record # Provides configuration parameters to override the default actions for extracting text from PDF documents and image files. By default, Amazon Comprehend performs the following actions to extract text from files, based on the input file type: Word files - Amazon Comprehend parser extracts the text. Digital PDF files - Amazon Comprehend parser extracts the text. Image files and scanned PDF files - Amazon Comprehend uses the Amazon Textract DetectDocumentText API to extract the text. DocumentReaderConfig does not apply to plain text files or Word files. For image files and PDF documents, you can override these default actions using the fields listed below. For more information, see Setting text extraction options (https://docs.aws.amazon.com/comprehend/latest/dg/idp-set-textract-options.html) in the Comprehend Developer Guide. — shape: {DocumentReadAction: "TEXTRACT_DETECT_DOCUMENT_TEXT"|"TEXTRACT_ANALYZE_DOCUMENT", DocumentReadMode?: "SERVICE_DEFAULT"|"FORCE_DOCUMENT_READ_ACTION", FeatureTypes?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ClassifyDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: EndpointArn, var: endpoint_arn}, {name: Bytes, var: bytes}, {name: DocumentReaderConfig, var: document_reader_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, endpoint_arn: $endpoint_arn, bytes: $bytes, document_reader_config: $document_reader_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Analyzes input text for the presence of personally identifiable information (PII) and returns the labels of identified PII entity types such as name, address, bank account number, or phone number.
#
# POST /
# Returns: record<Labels: table<Name: string, Score: float>>
# operationId: ContainsPiiEntities
export def "contains-pii-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # A UTF-8 text string. The maximum string size is 100 KB.
  language_code: string@language-code-completer # The language of the input documents. Currently, English is the only valid language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ContainsPiiEntities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a dataset to upload training or test data for a model associated with a flywheel. For more information about datasets, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  flywheel_arn: string # The Amazon Resource Number (ARN) of the flywheel of the flywheel to receive the data.
  dataset_name: string # Name of the dataset.
  --dataset-type: string@dataset-type-completer # The dataset type. You can specify that the data in a dataset is for training the model or for testing the model.
  --description: string # Description of the dataset.
  input_data_config: record # Specifies the format and location of the input data for the dataset. — shape: {AugmentedManifests?: list, DataFormat?: "COMPREHEND_CSV"|"AUGMENTED_MANIFEST", DocumentClassifierInputDataConfig?: record, EntityRecognizerInputDataConfig?: record}
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  --tags: list # Tags for the dataset. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.CreateDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}, {name: DatasetName, var: dataset_name}, {name: DatasetType, var: dataset_type}, {name: Description, var: description}, {name: InputDataConfig, var: input_data_config}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn, dataset_name: $dataset_name, dataset_type: $dataset_type, description: $description, input_data_config: $input_data_config, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new document classifier that you can use to categorize documents. To create a classifier, you provide a set of training documents that are labeled with the categories that you want to use. For more information, see Training classifier models (https://docs.aws.amazon.com/comprehend/latest/dg/training-classifier-model.html) in the Comprehend Developer Guide.
#
# POST /
# Returns: record<DocumentClassifierArn: string>
# operationId: CreateDocumentClassifier
export def "create-document-classifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_classifier_name: string # The name of the document classifier.
  --version-name: string # The version name given to the newly created classifier. Version names can have a maximum of 256 characters. Alphanumeric characters, hyphens (-) and underscores (_) are allowed. The version name must be unique among all models with the same classifier name in the Amazon Web Services account/Amazon Web Services Region.
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data.
  --tags: list # Tags to associate with the document classifier. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
  input_data_config: record # The input properties for training a document classifier. For more information on how the input file is formatted, see Preparing training data (https://docs.aws.amazon.com/comprehend/latest/dg/prep-classifier-data.html) in the Comprehend Developer Guide. — shape: {DataFormat?: "COMPREHEND_CSV"|"AUGMENTED_MANIFEST", S3Uri?: string, TestS3Uri?: string, LabelDelimiter?: string, AugmentedManifests?: list, DocumentType?: "PLAIN_TEXT_DOCUMENT"|"SEMI_STRUCTURED_DOCUMENT", Documents?: record, DocumentReaderConfig?: record}
  --output-data-config: record # Provide the location for output data from a custom classifier job. This field is mandatory if you are training a native classifier model. — shape: {S3Uri?: string, KmsKeyId?: string, FlywheelStatsS3Prefix?: string}
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the languages supported by Amazon Comprehend. All documents must be in the same language.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --mode: string@mode-completer # Indicates the mode in which the classifier will be trained. The classifier can be trained in multi-class mode, which identifies one and only one class for each document, or multi-label mode, which identifies one or more labels for each document. In multi-label mode, multiple labels for an individual document are separated by a delimiter. The default delimiter between labels is a pipe (|).
  --model-kms-key-id: string # ID for the KMS key that Amazon Comprehend uses to encrypt trained custom models. The ModelKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --model-policy: string # The resource-based policy to attach to your custom document classifier model. You can use this policy to allow another Amazon Web Services account to import your custom model. Provide your policy as a JSON body that you enter as a UTF-8 encoded string without line breaks. To provide valid JSON, enclose the attribute names and values in double quotes. If the JSON body is also enclosed in double quotes, then you must escape the double quotes that are inside the policy: "{\"attribute\": \"value\", \"attribute\": [\"value\"]}" To avoid escaping quotes, you can use single quotes to enclose the policy and double quotes to enclose the JSON names and values: '{"attribute": "value", "attribute": ["value"]}'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.CreateDocumentClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentClassifierName, var: document_classifier_name}, {name: VersionName, var: version_name}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: Tags, var: tags}, {name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: ClientRequestToken, var: client_request_token}, {name: LanguageCode, var: language_code}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Mode, var: mode}, {name: ModelKmsKeyId, var: model_kms_key_id}, {name: ModelPolicy, var: model_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_classifier_name: $document_classifier_name, version_name: $version_name, data_access_role_arn: $data_access_role_arn, tags: $tags, input_data_config: $input_data_config, output_data_config: $output_data_config, client_request_token: $client_request_token, language_code: $language_code, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, mode: $mode, model_kms_key_id: $model_kms_key_id, model_policy: $model_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a model-specific endpoint for synchronous inference for a previously trained custom model For information about endpoints, see Managing endpoints (https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
#
# POST /
# Returns: record<EndpointArn: string, ModelArn: string>
# operationId: CreateEndpoint
export def "create-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  endpoint_name: string # This is the descriptive suffix that becomes part of the EndpointArn used for all subsequent requests to this resource.
  --model-arn: string # The Amazon Resource Number (ARN) of the model to which the endpoint will be attached.
  desired_inference_units: int # The desired number of inference units to be used by the model using this endpoint. Each inference unit represents of a throughput of 100 characters per second.
  --client-request-token: string # An idempotency token provided by the customer. If this token matches a previous endpoint creation request, Amazon Comprehend will not return a ResourceInUseException.
  --tags: list # Tags to associate with the endpoint. A tag is a key-value pair that adds metadata to the endpoint. For example, a tag with "Sales" as the key might be added to an endpoint to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to trained custom models encrypted with a customer managed key (ModelKmsKeyId).
  --flywheel-arn: string # The Amazon Resource Number (ARN) of the flywheel to which the endpoint will be attached.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.CreateEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointName, var: endpoint_name}, {name: ModelArn, var: model_arn}, {name: DesiredInferenceUnits, var: desired_inference_units}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: FlywheelArn, var: flywheel_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_name: $endpoint_name, model_arn: $model_arn, desired_inference_units: $desired_inference_units, client_request_token: $client_request_token, tags: $tags, data_access_role_arn: $data_access_role_arn, flywheel_arn: $flywheel_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an entity recognizer using submitted files. After your CreateEntityRecognizer request is submitted, you can check job status using the DescribeEntityRecognizer API.
#
# POST /
# Returns: record<EntityRecognizerArn: string>
# operationId: CreateEntityRecognizer
export def "create-entity-recognizer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  recognizer_name: string # The name given to the newly created recognizer. Recognizer names can be a maximum of 256 characters. Alphanumeric characters, hyphens (-) and underscores (_) are allowed. The name must be unique in the account/Region.
  --version-name: string # The version name given to the newly created recognizer. Version names can be a maximum of 256 characters. Alphanumeric characters, hyphens (-) and underscores (_) are allowed. The version name must be unique among all models with the same recognizer name in the account/Region.
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data.
  --tags: list # Tags to associate with the entity recognizer. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
  input_data_config: record # Specifies the format and location of the input data. — shape: {DataFormat?: "COMPREHEND_CSV"|"AUGMENTED_MANIFEST", EntityTypes: list, Documents?: record, Annotations?: record, EntityList?: record, AugmentedManifests?: list}
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  language_code: string@language-code-completer # You can specify any of the following languages: English ("en"), Spanish ("es"), French ("fr"), Italian ("it"), German ("de"), or Portuguese ("pt"). If you plan to use this entity recognizer with PDF, Word, or image input files, you must specify English as the language. All training documents must be in the same language.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --model-kms-key-id: string # ID for the KMS key that Amazon Comprehend uses to encrypt trained custom models. The ModelKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --model-policy: string # The JSON resource-based policy to attach to your custom entity recognizer model. You can use this policy to allow another Amazon Web Services account to import your custom model. Provide your JSON as a UTF-8 encoded string without line breaks. To provide valid JSON for your policy, enclose the attribute names and values in double quotes. If the JSON body is also enclosed in double quotes, then you must escape the double quotes that are inside the policy: "{\"attribute\": \"value\", \"attribute\": [\"value\"]}" To avoid escaping quotes, you can use single quotes to enclose the policy and double quotes to enclose the JSON names and values: '{"attribute": "value", "attribute": ["value"]}'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.CreateEntityRecognizer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RecognizerName, var: recognizer_name}, {name: VersionName, var: version_name}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: Tags, var: tags}, {name: InputDataConfig, var: input_data_config}, {name: ClientRequestToken, var: client_request_token}, {name: LanguageCode, var: language_code}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: ModelKmsKeyId, var: model_kms_key_id}, {name: ModelPolicy, var: model_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, recognizer_name: $recognizer_name, version_name: $version_name, data_access_role_arn: $data_access_role_arn, tags: $tags, input_data_config: $input_data_config, client_request_token: $client_request_token, language_code: $language_code, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, model_kms_key_id: $model_kms_key_id, model_policy: $model_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A flywheel is an Amazon Web Services resource that orchestrates the ongoing training of a model for custom classification or custom entity recognition. You can create a flywheel to start with an existing trained model, or Comprehend can create and train a new model. When you create the flywheel, Comprehend creates a data lake in your account. The data lake holds the training data and test data for all versions of the model. To use a flywheel with an existing trained model, you specify the active model version. Comprehend copies the model's training data and test data into the flywheel's data lake. To use the flywheel with a new model, you need to provide a dataset for training data (and optional test data) when you create the flywheel. For more information about flywheels, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record<FlywheelArn: string, ActiveModelArn: string>
# operationId: CreateFlywheel
export def "create-flywheel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  flywheel_name: string # Name for the flywheel.
  --active-model-arn: string # To associate an existing model with the flywheel, specify the Amazon Resource Number (ARN) of the model version.
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend the permissions required to access the flywheel data in the data lake.
  --task-config: record # Configuration about the custom classifier associated with the flywheel. — shape: {LanguageCode: "en"|"es"|"fr"|"de"|"it"|"pt"|"ar"|"hi"|"ja"|"ko"|"zh"|"zh-TW", DocumentClassificationConfig?: record, EntityRecognitionConfig?: record}
  --model-type: string@model-type-completer # The model type.
  data_lake_s3_uri: string # Enter the S3 location for the data lake. You can specify a new S3 bucket or a new folder of an existing S3 bucket. The flywheel creates the data lake at this location.
  --data-security-config: record # Data security configuration. — shape: {ModelKmsKeyId?: string, VolumeKmsKeyId?: string, DataLakeKmsKeyId?: string, VpcConfig?: record}
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  --tags: list # The tags to associate with this flywheel. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.CreateFlywheel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelName, var: flywheel_name}, {name: ActiveModelArn, var: active_model_arn}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: TaskConfig, var: task_config}, {name: ModelType, var: model_type}, {name: DataLakeS3Uri, var: data_lake_s3_uri}, {name: DataSecurityConfig, var: data_security_config}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_name: $flywheel_name, active_model_arn: $active_model_arn, data_access_role_arn: $data_access_role_arn, task_config: $task_config, model_type: $model_type, data_lake_s3_uri: $data_lake_s3_uri, data_security_config: $data_security_config, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously created document classifier Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a ResourceInUseException will be returned. This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use.
#
# POST /
# Returns: record
# operationId: DeleteDocumentClassifier
export def "delete-document-classifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_classifier_arn: string # The Amazon Resource Name (ARN) that identifies the document classifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DeleteDocumentClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentClassifierArn, var: document_classifier_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_classifier_arn: $document_classifier_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted. For information about endpoints, see Managing endpoints (https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
#
# POST /
# Returns: record
# operationId: DeleteEndpoint
export def "delete-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  endpoint_arn: string # The Amazon Resource Number (ARN) of the endpoint being deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DeleteEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an entity recognizer. Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a ResourceInUseException will be returned. This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use.
#
# POST /
# Returns: record
# operationId: DeleteEntityRecognizer
export def "delete-entity-recognizer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  entity_recognizer_arn: string # The Amazon Resource Name (ARN) that identifies the entity recognizer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DeleteEntityRecognizer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EntityRecognizerArn, var: entity_recognizer_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, entity_recognizer_arn: $entity_recognizer_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a flywheel. When you delete the flywheel, Amazon Comprehend does not delete the data lake or the model associated with the flywheel. For more information about flywheels, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record
# operationId: DeleteFlywheel
export def "delete-flywheel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  flywheel_arn: string # The Amazon Resource Number (ARN) of the flywheel to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DeleteFlywheel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource-based policy that is attached to a custom model.
#
# POST /
# Returns: record
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The Amazon Resource Name (ARN) of the custom model version that has the policy to delete.
  --policy-revision-id: string # The revision ID of the policy to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DeleteResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: PolicyRevisionId, var: policy_revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, policy_revision_id: $policy_revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the dataset that you specify. For more information about datasets, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record<DatasetProperties: record<DatasetArn: string, DatasetName: string, DatasetType: string, DatasetS3Uri: string, Description: string, Status: string, Message: string, NumberOfDocuments: int, CreationTime: string, EndTime: string>>
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  dataset_arn: string # The ARN of the dataset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeDataset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatasetArn, var: dataset_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, dataset_arn: $dataset_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
#
# POST /
# Returns: record<DocumentClassificationJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, DocumentClassifierArn: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, FlywheelArn: string>>
# operationId: DescribeDocumentClassificationJob
export def "describe-document-classification-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Comprehend generated for the job. The StartDocumentClassificationJob operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeDocumentClassificationJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a document classifier.
#
# POST /
# Returns: record<DocumentClassifierProperties: record<DocumentClassifierArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record<DataFormat: string, S3Uri: string, TestS3Uri: string, LabelDelimiter: string, AugmentedManifests: list, DocumentType: string, Documents: record, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string, FlywheelStatsS3Prefix: string>, ClassifierMetadata: record<NumberOfLabels: int, NumberOfTrainedDocuments: int, NumberOfTestDocuments: int, EvaluationMetrics: record>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, Mode: string, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string>>
# operationId: DescribeDocumentClassifier
export def "describe-document-classifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  document_classifier_arn: string # The Amazon Resource Name (ARN) that identifies the document classifier. The CreateDocumentClassifier operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeDocumentClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentClassifierArn, var: document_classifier_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_classifier_arn: $document_classifier_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
#
# POST /
# Returns: record<DominantLanguageDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>
# operationId: DescribeDominantLanguageDetectionJob
export def "describe-dominant-language-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Comprehend generated for the job. The StartDominantLanguageDetectionJob operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeDominantLanguageDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint. For information about endpoints, see Managing endpoints (https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
#
# POST /
# Returns: record<EndpointProperties: record<EndpointArn: string, Status: string, Message: string, ModelArn: string, DesiredModelArn: string, DesiredInferenceUnits: int, CurrentInferenceUnits: int, CreationTime: string, LastModifiedTime: string, DataAccessRoleArn: string, DesiredDataAccessRoleArn: string, FlywheelArn: string>>
# operationId: DescribeEndpoint
export def "describe-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  endpoint_arn: string # The Amazon Resource Number (ARN) of the endpoint being described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
#
# POST /
# Returns: record<EntitiesDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, EntityRecognizerArn: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, FlywheelArn: string>>
# operationId: DescribeEntitiesDetectionJob
export def "describe-entities-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Comprehend generated for the job. The StartEntitiesDetectionJob operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeEntitiesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
#
# POST /
# Returns: record<EntityRecognizerProperties: record<EntityRecognizerArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record<DataFormat: string, EntityTypes: list, Documents: record, Annotations: record, EntityList: record, AugmentedManifests: list>, RecognizerMetadata: record<NumberOfTrainedDocuments: int, NumberOfTestDocuments: int, EvaluationMetrics: record, EntityTypes: list>, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string, OutputDataConfig: record<FlywheelStatsS3Prefix: string>>>
# operationId: DescribeEntityRecognizer
export def "describe-entity-recognizer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  entity_recognizer_arn: string # The Amazon Resource Name (ARN) that identifies the entity recognizer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeEntityRecognizer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EntityRecognizerArn, var: entity_recognizer_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, entity_recognizer_arn: $entity_recognizer_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status and details of an events detection job.
#
# POST /
# Returns: record<EventsDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, TargetEventTypes: list<string>>>
# operationId: DescribeEventsDetectionJob
export def "describe-events-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier of the events detection job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeEventsDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides configuration information about the flywheel. For more information about flywheels, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record<FlywheelProperties: record<FlywheelArn: string, ActiveModelArn: string, DataAccessRoleArn: string, TaskConfig: record<LanguageCode: string, DocumentClassificationConfig: record, EntityRecognitionConfig: record>, DataLakeS3Uri: string, DataSecurityConfig: record<ModelKmsKeyId: string, VolumeKmsKeyId: string, DataLakeKmsKeyId: string, VpcConfig: record>, Status: string, ModelType: string, Message: string, CreationTime: string, LastModifiedTime: string, LatestFlywheelIteration: string>>
# operationId: DescribeFlywheel
export def "describe-flywheel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  flywheel_arn: string # The Amazon Resource Number (ARN) of the flywheel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeFlywheel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the configuration properties of a flywheel iteration. For more information about flywheels, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record<FlywheelIterationProperties: record<FlywheelArn: string, FlywheelIterationId: string, CreationTime: string, EndTime: string, Status: string, Message: string, EvaluatedModelArn: string, EvaluatedModelMetrics: record<AverageF1Score: float, AveragePrecision: float, AverageRecall: float, AverageAccuracy: float>, TrainedModelArn: string, TrainedModelMetrics: record<AverageF1Score: float, AveragePrecision: float, AverageRecall: float, AverageAccuracy: float>, EvaluationManifestS3Prefix: string>>
# operationId: DescribeFlywheelIteration
export def "describe-flywheel-iteration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  flywheel_arn: string
  flywheel_iteration_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeFlywheelIteration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}, {name: FlywheelIterationId, var: flywheel_iteration_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn, flywheel_iteration_id: $flywheel_iteration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
#
# POST /
# Returns: record<KeyPhrasesDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>
# operationId: DescribeKeyPhrasesDetectionJob
export def "describe-key-phrases-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Comprehend generated for the job. The StartKeyPhrasesDetectionJob operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeKeyPhrasesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a PII entities detection job. For example, you can use this operation to get the job status.
#
# POST /
# Returns: record<PiiEntitiesDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, RedactionConfig: record<PiiEntityTypes: list, MaskMode: string, MaskCharacter: string>, LanguageCode: string, DataAccessRoleArn: string, Mode: string>>
# operationId: DescribePiiEntitiesDetectionJob
export def "describe-pii-entities-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Comprehend generated for the job. The operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribePiiEntitiesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a resource-based policy that is attached to a custom model, including the JSON body of the policy.
#
# POST /
# Returns: record<ResourcePolicy: string, CreationTime: string, LastModifiedTime: string, PolicyRevisionId: string>
# operationId: DescribeResourcePolicy
export def "describe-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The Amazon Resource Name (ARN) of the custom model version that has the resource policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
#
# POST /
# Returns: record<SentimentDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>
# operationId: DescribeSentimentDetectionJob
export def "describe-sentiment-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Comprehend generated for the job. The operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeSentimentDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a targeted sentiment detection job. Use this operation to get the status of the job.
#
# POST /
# Returns: record<TargetedSentimentDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>
# operationId: DescribeTargetedSentimentDetectionJob
export def "describe-targeted-sentiment-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier that Amazon Comprehend generated for the job. The StartTargetedSentimentDetectionJob operation returns this identifier in its response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeTargetedSentimentDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
#
# POST /
# Returns: record<TopicsDetectionJobProperties: record<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record<S3Uri: string, InputFormat: string, DocumentReaderConfig: record>, OutputDataConfig: record<S3Uri: string, KmsKeyId: string>, NumberOfTopics: int, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record<SecurityGroupIds: list, Subnets: list>>>
# operationId: DescribeTopicsDetectionJob
export def "describe-topics-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # The identifier assigned by the user to the detection job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DescribeTopicsDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see Amazon Comprehend Supported Languages (https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html).
#
# POST /
# Returns: record<Languages: table<LanguageCode: string, Score: float>>
# operationId: DetectDominantLanguage
export def "detect-dominant-language" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # A UTF-8 text string. The string must contain at least 20 characters. The maximum string size is 100 KB. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DetectDominantLanguage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detects named entities in input text when you use the pre-trained model. Detects custom entities if you have a custom entity recognition model. When detecting named entities using the pre-trained model, use plain text as the input. For more information about named entities, see Entities (https://docs.aws.amazon.com/comprehend/latest/dg/how-entities.html) in the Comprehend Developer Guide. When you use a custom entity recognition model, you can input plain text or you can upload a single-page input document (text, PDF, Word, or image). If the system detects errors while processing a page in the input document, the API response includes an entry in Errors for each error. If the system detects a document-level error in your input document, the API returns an InvalidRequestException error response. For details about this exception, see Errors in semi-structured documents (https://docs.aws.amazon.com/comprehend/latest/dg/idp-inputs-sync-err.html) in the Comprehend Developer Guide.
#
# POST /
# Returns: record<Entities: table<Score: float, Type: string, Text: string, BeginOffset: int, EndOffset: int, BlockReferences: list>, DocumentMetadata: record<Pages: int, ExtractedCharacters: list<record>>, DocumentType: table<Page: int, Type: string>, Blocks: table<Id: string, BlockType: string, Text: string, Page: int, Geometry: record, Relationships: list>, Errors: table<Page: int, ErrorCode: string, ErrorMessage: string>>
# operationId: DetectEntities
export def "detect-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --text: string # A UTF-8 text string. The maximum string size is 100 KB. If you enter text using this parameter, do not use the Bytes parameter. (format: password)
  --language-code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. If your request includes the endpoint for a custom entity recognition model, Amazon Comprehend uses the language of your custom model, and it ignores any language code that you specify here. All input documents must be in the same language.
  --endpoint-arn: string # The Amazon Resource Name of an endpoint that is associated with a custom entity recognition model. Provide an endpoint if you want to detect entities by using your own custom model instead of the default model that is used by Amazon Comprehend. If you specify an endpoint, Amazon Comprehend uses the language of your custom model, and it ignores any language code that you provide in your request. For information about endpoints, see Managing endpoints (https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
  --bytes: string # This field applies only when you use a custom entity recognition model that was trained with PDF annotations. For other cases, enter your text input in the Text field. Use the Bytes parameter to input a text, PDF, Word or image file. Using a plain-text file in the Bytes parameter is equivelent to using the Text parameter (the Entities field in the response is identical). You can also use the Bytes parameter to input an Amazon Textract DetectDocumentText or AnalyzeDocument output file. Provide the input document as a sequence of base64-encoded bytes. If your code uses an Amazon Web Services SDK to detect entities, the SDK may encode the document file bytes for you. The maximum length of this field depends on the input document type. For details, see Inputs for real-time custom analysis (https://docs.aws.amazon.com/comprehend/latest/dg/idp-inputs-sync.html) in the Comprehend Developer Guide. If you use the Bytes parameter, do not use the Text parameter.
  --document-reader-config: record # Provides configuration parameters to override the default actions for extracting text from PDF documents and image files. By default, Amazon Comprehend performs the following actions to extract text from files, based on the input file type: Word files - Amazon Comprehend parser extracts the text. Digital PDF files - Amazon Comprehend parser extracts the text. Image files and scanned PDF files - Amazon Comprehend uses the Amazon Textract DetectDocumentText API to extract the text. DocumentReaderConfig does not apply to plain text files or Word files. For image files and PDF documents, you can override these default actions using the fields listed below. For more information, see Setting text extraction options (https://docs.aws.amazon.com/comprehend/latest/dg/idp-set-textract-options.html) in the Comprehend Developer Guide. — shape: {DocumentReadAction: "TEXTRACT_DETECT_DOCUMENT_TEXT"|"TEXTRACT_ANALYZE_DOCUMENT", DocumentReadMode?: "SERVICE_DEFAULT"|"FORCE_DOCUMENT_READ_ACTION", FeatureTypes?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DetectEntities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: LanguageCode, var: language_code}, {name: EndpointArn, var: endpoint_arn}, {name: Bytes, var: bytes}, {name: DocumentReaderConfig, var: document_reader_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, language_code: $language_code, endpoint_arn: $endpoint_arn, bytes: $bytes, document_reader_config: $document_reader_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detects the key noun phrases found in the text.
#
# POST /
# Returns: record<KeyPhrases: table<Score: float, Text: string, BeginOffset: int, EndOffset: int>>
# operationId: DetectKeyPhrases
export def "detect-key-phrases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # A UTF-8 text string. The string must contain less than 100 KB of UTF-8 encoded characters. (format: password)
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. All documents must be in the same language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DetectKeyPhrases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects the input text for entities that contain personally identifiable information (PII) and returns information about them.
#
# POST /
# Returns: record<Entities: table<Score: float, Type: string, BeginOffset: int, EndOffset: int>>
# operationId: DetectPiiEntities
export def "detect-pii-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # A UTF-8 text string. The maximum string size is 100 KB.
  language_code: string@language-code-completer # The language of the input documents. Currently, English is the only valid language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DetectPiiEntities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects text and returns an inference of the prevailing sentiment (POSITIVE, NEUTRAL, MIXED, or NEGATIVE).
#
# POST /
# Returns: record<Sentiment: string, SentimentScore: record<Positive: float, Negative: float, Neutral: float, Mixed: float>>
# operationId: DetectSentiment
export def "detect-sentiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # A UTF-8 text string. The maximum string size is 5 KB. (format: password)
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. All documents must be in the same language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DetectSentiment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects text for syntax and the part of speech of words in the document. For more information, see Syntax (https://docs.aws.amazon.com/comprehend/latest/dg/how-syntax.html) in the Comprehend Developer Guide.
#
# POST /
# Returns: record<SyntaxTokens: table<TokenId: int, Text: string, BeginOffset: int, EndOffset: int, PartOfSpeech: record>>
# operationId: DetectSyntax
export def "detect-syntax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # A UTF-8 string. The maximum string size is 5 KB. (format: password)
  language_code: string@language-code-completer-1 # The language code of the input documents. You can specify any of the following languages supported by Amazon Comprehend: German ("de"), English ("en"), Spanish ("es"), French ("fr"), Italian ("it"), or Portuguese ("pt").
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DetectSyntax"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspects the input text and returns a sentiment analysis for each entity identified in the text. For more information about targeted sentiment, see Targeted sentiment (https://docs.aws.amazon.com/comprehend/latest/dg/how-targeted-sentiment.html).
#
# POST /
# Returns: record<Entities: table<DescriptiveMentionIndex: list, Mentions: list>>
# operationId: DetectTargetedSentiment
export def "detect-targeted-sentiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  text: string # A UTF-8 text string. The maximum string length is 5 KB. (format: password)
  language_code: string@language-code-completer # The language of the input documents. Currently, English is the only supported language.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.DetectTargetedSentiment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Text, var: text}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, text: $text, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new custom model that replicates a source custom model that you import. The source model can be in your Amazon Web Services account or another one. If the source model is in another Amazon Web Services account, then it must have a resource-based policy that authorizes you to import it. The source model must be in the same Amazon Web Services Region that you're using when you import. You can't import a model that's in a different Region.
#
# POST /
# Returns: record<ModelArn: string>
# operationId: ImportModel
export def "import-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  source_model_arn: string # The Amazon Resource Name (ARN) of the custom model to import.
  --model-name: string # The name to assign to the custom model that is created in Amazon Comprehend by this import.
  --version-name: string # The version name given to the custom model that is created by this import. Version names can have a maximum of 256 characters. Alphanumeric characters, hyphens (-) and underscores (_) are allowed. The version name must be unique among all models with the same classifier name in the account/Region.
  --model-kms-key-id: string # ID for the KMS key that Amazon Comprehend uses to encrypt trained custom models. The ModelKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend permission to use Amazon Key Management Service (KMS) to encrypt or decrypt the custom model.
  --tags: list # Tags to associate with the custom model that is created by this import. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ImportModel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceModelArn, var: source_model_arn}, {name: ModelName, var: model_name}, {name: VersionName, var: version_name}, {name: ModelKmsKeyId, var: model_kms_key_id}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_model_arn: $source_model_arn, model_name: $model_name, version_name: $version_name, model_kms_key_id: $model_kms_key_id, data_access_role_arn: $data_access_role_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the datasets that you have configured in this Region. For more information about datasets, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record<DatasetPropertiesList: table<DatasetArn: string, DatasetName: string, DatasetType: string, DatasetS3Uri: string, Description: string, Status: string, Message: string, NumberOfDocuments: int, CreationTime: string, EndTime: string>, NextToken: string>
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  --flywheel-arn: string # The Amazon Resource Number (ARN) of the flywheel.
  --filter: record # Filter the datasets based on creation time or dataset status. — shape: {Status?: "CREATING"|"COMPLETED"|"FAILED", DatasetType?: "TRAIN"|"TEST", CreationTimeAfter?: string, CreationTimeBefore?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # Maximum number of results to return in a response. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListDatasets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}, {name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the documentation classification jobs that you have submitted.
#
# POST /
# Returns: record<DocumentClassificationJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, DocumentClassifierArn: string, InputDataConfig: record, OutputDataConfig: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, FlywheelArn: string>, NextToken: string>
# operationId: ListDocumentClassificationJobs
export def "list-document-classification-jobs" [
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
  --filter: record # Provides information for filtering a list of document classification jobs. For more information, see the operation. You can provide only one filter parameter in each request. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListDocumentClassificationJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of summaries of the document classifiers that you have created
#
# POST /
# Returns: record<DocumentClassifierSummariesList: table<DocumentClassifierName: string, NumberOfVersions: int, LatestVersionCreatedAt: string, LatestVersionName: string, LatestVersionStatus: string>, NextToken: string>
# operationId: ListDocumentClassifierSummaries
export def "list-document-classifier-summaries" [
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
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return on each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListDocumentClassifierSummaries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the document classifiers that you have created.
#
# POST /
# Returns: record<DocumentClassifierPropertiesList: table<DocumentClassifierArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record, OutputDataConfig: record, ClassifierMetadata: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, Mode: string, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string>, NextToken: string>
# operationId: ListDocumentClassifiers
export def "list-document-classifiers" [
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
  --filter: record # Provides information for filtering a list of document classifiers. You can only specify one filtering parameter in a request. For more information, see the ListDocumentClassifiers operation. — shape: {Status?: "SUBMITTED"|"TRAINING"|"DELETING"|"STOP_REQUESTED"|"STOPPED"|"IN_ERROR"|"TRAINED"|"TRAINED_WITH_WARNING", DocumentClassifierName?: string, SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListDocumentClassifiers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the dominant language detection jobs that you have submitted.
#
# POST /
# Returns: record<DominantLanguageDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>
# operationId: ListDominantLanguageDetectionJobs
export def "list-dominant-language-detection-jobs" [
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
  --filter: record # Provides information for filtering a list of dominant language detection jobs. For more information, see the operation. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListDominantLanguageDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all existing endpoints that you've created. For information about endpoints, see Managing endpoints (https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
#
# POST /
# Returns: record<EndpointPropertiesList: table<EndpointArn: string, Status: string, Message: string, ModelArn: string, DesiredModelArn: string, DesiredInferenceUnits: int, CurrentInferenceUnits: int, CreationTime: string, LastModifiedTime: string, DataAccessRoleArn: string, DesiredDataAccessRoleArn: string, FlywheelArn: string>, NextToken: string>
# operationId: ListEndpoints
export def "list-endpoints" [
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
  --filter: record # The filter used to determine which endpoints are returned. You can filter jobs on their name, model, status, or the date and time that they were created. You can only set one filter at a time. — shape: {ModelArn?: string, Status?: "CREATING"|"DELETING"|"FAILED"|"IN_SERVICE"|"UPDATING", CreationTimeBefore?: string, CreationTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the entity detection jobs that you have submitted.
#
# POST /
# Returns: record<EntitiesDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, EntityRecognizerArn: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, FlywheelArn: string>, NextToken: string>
# operationId: ListEntitiesDetectionJobs
export def "list-entities-detection-jobs" [
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
  --filter: record # Provides information for filtering a list of dominant language detection jobs. For more information, see the operation. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListEntitiesDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of summaries for the entity recognizers that you have created.
#
# POST /
# Returns: record<EntityRecognizerSummariesList: table<RecognizerName: string, NumberOfVersions: int, LatestVersionCreatedAt: string, LatestVersionName: string, LatestVersionStatus: string>, NextToken: string>
# operationId: ListEntityRecognizerSummaries
export def "list-entity-recognizer-summaries" [
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
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return on each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListEntityRecognizerSummaries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list. The results of this list are not in any particular order. Please get the list and sort locally if needed.
#
# POST /
# Returns: record<EntityRecognizerPropertiesList: table<EntityRecognizerArn: string, LanguageCode: string, Status: string, Message: string, SubmitTime: string, EndTime: string, TrainingStartTime: string, TrainingEndTime: string, InputDataConfig: record, RecognizerMetadata: record, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record, ModelKmsKeyId: string, VersionName: string, SourceModelArn: string, FlywheelArn: string, OutputDataConfig: record>, NextToken: string>
# operationId: ListEntityRecognizers
export def "list-entity-recognizers" [
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
  --filter: record # Provides information for filtering a list of entity recognizers. You can only specify one filtering parameter in a request. For more information, see the ListEntityRecognizers operation./> — shape: {Status?: "SUBMITTED"|"TRAINING"|"DELETING"|"STOP_REQUESTED"|"STOPPED"|"IN_ERROR"|"TRAINED"|"TRAINED_WITH_WARNING", RecognizerName?: string, SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return on each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListEntityRecognizers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the events detection jobs that you have submitted.
#
# POST /
# Returns: record<EventsDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, TargetEventTypes: list>, NextToken: string>
# operationId: ListEventsDetectionJobs
export def "list-events-detection-jobs" [
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
  --filter: record # Provides information for filtering a list of event detection jobs. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListEventsDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about the history of a flywheel iteration. For more information about flywheels, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record<FlywheelIterationPropertiesList: table<FlywheelArn: string, FlywheelIterationId: string, CreationTime: string, EndTime: string, Status: string, Message: string, EvaluatedModelArn: string, EvaluatedModelMetrics: record, TrainedModelArn: string, TrainedModelMetrics: record, EvaluationManifestS3Prefix: string>, NextToken: string>
# operationId: ListFlywheelIterationHistory
export def "list-flywheel-iteration-history" [
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
  flywheel_arn: string # The ARN of the flywheel.
  --filter: record # Filter the flywheel iterations based on creation time. — shape: {CreationTimeAfter?: string, CreationTimeBefore?: string}
  --body-next-token: string # Next token (spec name: NextToken)
  --body-max-results: int # Maximum number of iteration history results to return (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListFlywheelIterationHistory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}, {name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the flywheels that you have created.
#
# POST /
# Returns: record<FlywheelSummaryList: table<FlywheelArn: string, ActiveModelArn: string, DataLakeS3Uri: string, Status: string, ModelType: string, Message: string, CreationTime: string, LastModifiedTime: string, LatestFlywheelIteration: string>, NextToken: string>
# operationId: ListFlywheels
export def "list-flywheels" [
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
  --filter: record # Filter the flywheels based on creation time or flywheel status. — shape: {Status?: "CREATING"|"ACTIVE"|"UPDATING"|"DELETING"|"FAILED", CreationTimeAfter?: string, CreationTimeBefore?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # Maximum number of results to return in a response. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListFlywheels"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of key phrase detection jobs that you have submitted.
#
# POST /
# Returns: record<KeyPhrasesDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>
# operationId: ListKeyPhrasesDetectionJobs
export def "list-key-phrases-detection-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --filter: record # Provides information for filtering a list of dominant language detection jobs. For more information, see the operation. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListKeyPhrasesDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the PII entity detection jobs that you have submitted.
#
# POST /
# Returns: record<PiiEntitiesDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, RedactionConfig: record, LanguageCode: string, DataAccessRoleArn: string, Mode: string>, NextToken: string>
# operationId: ListPiiEntitiesDetectionJobs
export def "list-pii-entities-detection-jobs" [
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
  --filter: record # Provides information for filtering a list of PII entity detection jobs. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListPiiEntitiesDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of sentiment detection jobs that you have submitted.
#
# POST /
# Returns: record<SentimentDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>
# operationId: ListSentimentDetectionJobs
export def "list-sentiment-detection-jobs" [
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
  --filter: record # Provides information for filtering a list of dominant language detection jobs. For more information, see the operation. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListSentimentDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all tags associated with a given Amazon Comprehend resource.
#
# POST /
# Returns: record<ResourceArn: string, Tags: table<Key: string, Value: string>>
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the given Amazon Comprehend resource you are querying.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of targeted sentiment detection jobs that you have submitted.
#
# POST /
# Returns: record<TargetedSentimentDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, LanguageCode: string, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>
# operationId: ListTargetedSentimentDetectionJobs
export def "list-targeted-sentiment-detection-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  --filter: record # Provides information for filtering a list of dominant language detection jobs. For more information, see the ListTargetedSentimentDetectionJobs operation. — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListTargetedSentimentDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the topic detection jobs that you have submitted.
#
# POST /
# Returns: record<TopicsDetectionJobPropertiesList: table<JobId: string, JobArn: string, JobName: string, JobStatus: string, Message: string, SubmitTime: string, EndTime: string, InputDataConfig: record, OutputDataConfig: record, NumberOfTopics: int, DataAccessRoleArn: string, VolumeKmsKeyId: string, VpcConfig: record>, NextToken: string>
# operationId: ListTopicsDetectionJobs
export def "list-topics-detection-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  --filter: record # Provides information for filtering topic detection jobs. For more information, see . — shape: {JobName?: string, JobStatus?: "SUBMITTED"|"IN_PROGRESS"|"COMPLETED"|"FAILED"|"STOP_REQUESTED"|"STOPPED", SubmitTimeBefore?: string, SubmitTimeAfter?: string}
  --body-next-token: string # Identifies the next page of results to return. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return in each page. The default is 100. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.ListTopicsDetectionJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a resource-based policy to a custom model. You can use this policy to authorize an entity in another Amazon Web Services account to import the custom model, which replicates it in Amazon Comprehend in their account.
#
# POST /
# Returns: record<PolicyRevisionId: string>
# operationId: PutResourcePolicy
export def "put-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The Amazon Resource Name (ARN) of the custom model to attach the policy to.
  resource_policy: string # The JSON resource-based policy to attach to your custom model. Provide your JSON as a UTF-8 encoded string without line breaks. To provide valid JSON for your policy, enclose the attribute names and values in double quotes. If the JSON body is also enclosed in double quotes, then you must escape the double quotes that are inside the policy: "{\"attribute\": \"value\", \"attribute\": [\"value\"]}" To avoid escaping quotes, you can use single quotes to enclose the policy and double quotes to enclose the JSON names and values: '{"attribute": "value", "attribute": ["value"]}'
  --policy-revision-id: string # The revision ID that Amazon Comprehend assigned to the policy that you are updating. If you are creating a new policy that has no prior version, don't use this parameter. Amazon Comprehend creates the revision ID for you.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.PutResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: ResourcePolicy, var: resource_policy}, {name: PolicyRevisionId, var: policy_revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, resource_policy: $resource_policy, policy_revision_id: $policy_revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous document classification job. Use the DescribeDocumentClassificationJob operation to track the progress of the job.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string, DocumentClassifierArn: string>
# operationId: StartDocumentClassificationJob
export def "start-document-classification-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --job-name: string # The identifier of the job.
  --document-classifier-arn: string # The Amazon Resource Name (ARN) of the document classifier to use to process the job.
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data.
  --client-request-token: string # A unique identifier for the request. If you do not set the client request token, Amazon Comprehend generates one.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --tags: list # Tags to associate with the document classification job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
  --flywheel-arn: string # The Amazon Resource Number (ARN) of the flywheel associated with the model to use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartDocumentClassificationJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobName, var: job_name}, {name: DocumentClassifierArn, var: document_classifier_arn}, {name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: ClientRequestToken, var: client_request_token}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Tags, var: tags}, {name: FlywheelArn, var: flywheel_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_name: $job_name, document_classifier_arn: $document_classifier_arn, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, client_request_token: $client_request_token, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, tags: $tags, flywheel_arn: $flywheel_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string>
# operationId: StartDominantLanguageDetectionJob
export def "start-dominant-language-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data. For more information, see Role-based permissions (https://docs.aws.amazon.com/comprehend/latest/dg/security_iam_id-based-policy-examples.html#auth-role-permissions).
  --job-name: string # An identifier for the job.
  --client-request-token: string # A unique identifier for the request. If you do not set the client request token, Amazon Comprehend generates one.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --tags: list # Tags to associate with the dominant language detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartDominantLanguageDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: ClientRequestToken, var: client_request_token}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, client_request_token: $client_request_token, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job. This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional EntityRecognizerArn must be used in order to provide access to the recognizer being used to detect the custom entity.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string, EntityRecognizerArn: string>
# operationId: StartEntitiesDetectionJob
export def "start-entities-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-63 # required
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data. For more information, see Role-based permissions (https://docs.aws.amazon.com/comprehend/latest/dg/security_iam_id-based-policy-examples.html#auth-role-permissions).
  --job-name: string # The identifier of the job.
  --entity-recognizer-arn: string # The Amazon Resource Name (ARN) that identifies the specific entity recognizer to be used by the StartEntitiesDetectionJob. This ARN is optional and is only used for a custom entity recognition job.
  language_code: string@language-code-completer # The language of the input documents. All documents must be in the same language. You can specify any of the languages supported by Amazon Comprehend. If custom entities recognition is used, this parameter is ignored and the language used for training the model is used instead.
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --tags: list # Tags to associate with the entities detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
  --flywheel-arn: string # The Amazon Resource Number (ARN) of the flywheel associated with the model to use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartEntitiesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: EntityRecognizerArn, var: entity_recognizer_arn}, {name: LanguageCode, var: language_code}, {name: ClientRequestToken, var: client_request_token}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Tags, var: tags}, {name: FlywheelArn, var: flywheel_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, entity_recognizer_arn: $entity_recognizer_arn, language_code: $language_code, client_request_token: $client_request_token, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, tags: $tags, flywheel_arn: $flywheel_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous event detection job for a collection of documents.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string>
# operationId: StartEventsDetectionJob
export def "start-events-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64 # required
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data.
  --job-name: string # The identifier of the events detection job.
  language_code: string@language-code-completer # The language code of the input documents.
  --client-request-token: string # An unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  target_event_types: list<string> # The types of events to detect in the input documents.
  --tags: list # Tags to associate with the events detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartEventsDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: LanguageCode, var: language_code}, {name: ClientRequestToken, var: client_request_token}, {name: TargetEventTypes, var: target_event_types}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, language_code: $language_code, client_request_token: $client_request_token, target_event_types: $target_event_types, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the flywheel iteration.This operation uses any new datasets to train a new model version. For more information about flywheels, see Flywheel overview (https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
#
# POST /
# Returns: record<FlywheelArn: string, FlywheelIterationId: string>
# operationId: StartFlywheelIteration
export def "start-flywheel-iteration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-65 # required
  flywheel_arn: string # The ARN of the flywheel.
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartFlywheelIteration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string>
# operationId: StartKeyPhrasesDetectionJob
export def "start-key-phrases-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66 # required
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data. For more information, see Role-based permissions (https://docs.aws.amazon.com/comprehend/latest/dg/security_iam_id-based-policy-examples.html#auth-role-permissions).
  --job-name: string # The identifier of the job.
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. All documents must be in the same language.
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --tags: list # Tags to associate with the key phrases detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartKeyPhrasesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: LanguageCode, var: language_code}, {name: ClientRequestToken, var: client_request_token}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, language_code: $language_code, client_request_token: $client_request_token, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous PII entity detection job for a collection of documents.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string>
# operationId: StartPiiEntitiesDetectionJob
export def "start-pii-entities-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67 # required
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  mode: string@mode-completer-1 # Specifies whether the output provides the locations (offsets) of PII entities or a file in which PII entities are redacted.
  --redaction-config: record # Provides configuration parameters for PII entity redaction. — shape: {PiiEntityTypes?: list<string>, MaskMode?: "MASK"|"REPLACE_WITH_PII_ENTITY_TYPE", MaskCharacter?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data.
  --job-name: string # The identifier of the job.
  language_code: string@language-code-completer # The language of the input documents. Currently, English is the only valid language.
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  --tags: list # Tags to associate with the PII entities detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartPiiEntitiesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: Mode, var: mode}, {name: RedactionConfig, var: redaction_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: LanguageCode, var: language_code}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, mode: $mode, redaction_config: $redaction_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, language_code: $language_code, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous sentiment detection job for a collection of documents. Use the operation to track the status of a job.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string>
# operationId: StartSentimentDetectionJob
export def "start-sentiment-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68 # required
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data. For more information, see Role-based permissions (https://docs.aws.amazon.com/comprehend/latest/dg/security_iam_id-based-policy-examples.html#auth-role-permissions).
  --job-name: string # The identifier of the job.
  language_code: string@language-code-completer # The language of the input documents. You can specify any of the primary languages supported by Amazon Comprehend. All documents must be in the same language.
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --tags: list # Tags to associate with the sentiment detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartSentimentDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: LanguageCode, var: language_code}, {name: ClientRequestToken, var: client_request_token}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, language_code: $language_code, client_request_token: $client_request_token, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous targeted sentiment detection job for a collection of documents. Use the DescribeTargetedSentimentDetectionJob operation to track the status of a job.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string>
# operationId: StartTargetedSentimentDetectionJob
export def "start-targeted-sentiment-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-69 # required
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data. For more information, see Role-based permissions (https://docs.aws.amazon.com/comprehend/latest/dg/access-control-managing-permissions.html#auth-role-permissions).
  --job-name: string # The identifier of the job.
  language_code: string@language-code-completer # The language of the input documents. Currently, English is the only supported language.
  --client-request-token: string # A unique identifier for the request. If you don't set the client request token, Amazon Comprehend generates one.
  --volume-kms-key-id: string # ID for the KMS key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --tags: list # Tags to associate with the targeted sentiment detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartTargetedSentimentDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: LanguageCode, var: language_code}, {name: ClientRequestToken, var: client_request_token}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, language_code: $language_code, client_request_token: $client_request_token, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an asynchronous topic detection job. Use the DescribeTopicDetectionJob operation to track the status of a job.
#
# POST /
# Returns: record<JobId: string, JobArn: string, JobStatus: string>
# operationId: StartTopicsDetectionJob
export def "start-topics-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70 # required
  input_data_config: record # The input properties for an inference job. The document reader config field applies only to non-text inputs for custom analysis. — shape: {S3Uri: string, InputFormat?: "ONE_DOC_PER_FILE"|"ONE_DOC_PER_LINE", DocumentReaderConfig?: record}
  output_data_config: record # Provides configuration parameters for the output of inference jobs. — shape: {S3Uri: string, KmsKeyId?: string}
  data_access_role_arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend read access to your input data. For more information, see Role-based permissions (https://docs.aws.amazon.com/comprehend/latest/dg/security_iam_id-based-policy-examples.html#auth-role-permissions).
  --job-name: string # The identifier of the job.
  --number-of-topics: int # The number of topics to detect.
  --client-request-token: string # A unique identifier for the request. If you do not set the client request token, Amazon Comprehend generates one.
  --volume-kms-key-id: string # ID for the Amazon Web Services Key Management Service (KMS) key that Amazon Comprehend uses to encrypt data on the storage volume attached to the ML compute instance(s) that process the analysis job. The VolumeKmsKeyId can be either of the following formats: KMS Key ID: "1234abcd-12ab-34cd-56ef-1234567890ab" Amazon Resource Name (ARN) of a KMS Key: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  --vpc-config: record # Configuration parameters for an optional private Virtual Private Cloud (VPC) containing the resources you are using for the job. For more information, see Amazon VPC (https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html). — shape: {SecurityGroupIds: list<string>, Subnets: list<string>}
  --tags: list # Tags to associate with the topics detection job. A tag is a key-value pair that adds metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StartTopicsDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InputDataConfig, var: input_data_config}, {name: OutputDataConfig, var: output_data_config}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: JobName, var: job_name}, {name: NumberOfTopics, var: number_of_topics}, {name: ClientRequestToken, var: client_request_token}, {name: VolumeKmsKeyId, var: volume_kms_key_id}, {name: VpcConfig, var: vpc_config}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, input_data_config: $input_data_config, output_data_config: $output_data_config, data_access_role_arn: $data_access_role_arn, job_name: $job_name, number_of_topics: $number_of_topics, client_request_token: $client_request_token, volume_kms_key_id: $volume_kms_key_id, vpc_config: $vpc_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a dominant language detection job in progress. If the job state is IN_PROGRESS the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopDominantLanguageDetectionJob
export def "stop-dominant-language-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-71 # required
  job_id: string # The identifier of the dominant language detection job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopDominantLanguageDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an entities detection job in progress. If the job state is IN_PROGRESS the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopEntitiesDetectionJob
export def "stop-entities-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-72 # required
  job_id: string # The identifier of the entities detection job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopEntitiesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an events detection job in progress.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopEventsDetectionJob
export def "stop-events-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-73 # required
  job_id: string # The identifier of the events detection job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopEventsDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a key phrases detection job in progress. If the job state is IN_PROGRESS the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopKeyPhrasesDetectionJob
export def "stop-key-phrases-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-74 # required
  job_id: string # The identifier of the key phrases detection job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopKeyPhrasesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a PII entities detection job in progress.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopPiiEntitiesDetectionJob
export def "stop-pii-entities-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-75 # required
  job_id: string # The identifier of the PII entities detection job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopPiiEntitiesDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a sentiment detection job in progress. If the job state is IN_PROGRESS, the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is be stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopSentimentDetectionJob
export def "stop-sentiment-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-76 # required
  job_id: string # The identifier of the sentiment detection job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopSentimentDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a targeted sentiment detection job in progress. If the job state is IN_PROGRESS, the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is be stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
#
# POST /
# Returns: record<JobId: string, JobStatus: string>
# operationId: StopTargetedSentimentDetectionJob
export def "stop-targeted-sentiment-detection-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-77 # required
  job_id: string # The identifier of the targeted sentiment detection job to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopTargetedSentimentDetectionJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a document classifier training job while in progress. If the training job state is TRAINING, the job is marked for termination and put into the STOP_REQUESTED state. If the training job completes before it can be stopped, it is put into the TRAINED; otherwise the training job is stopped and put into the STOPPED state and the service sends back an HTTP 200 response with an empty HTTP body.
#
# POST /
# Returns: record
# operationId: StopTrainingDocumentClassifier
export def "stop-training-document-classifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-78 # required
  document_classifier_arn: string # The Amazon Resource Name (ARN) that identifies the document classifier currently being trained.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopTrainingDocumentClassifier"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DocumentClassifierArn, var: document_classifier_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, document_classifier_arn: $document_classifier_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an entity recognizer training job while in progress. If the training job state is TRAINING, the job is marked for termination and put into the STOP_REQUESTED state. If the training job completes before it can be stopped, it is put into the TRAINED; otherwise the training job is stopped and putted into the STOPPED state and the service sends back an HTTP 200 response with an empty HTTP body.
#
# POST /
# Returns: record
# operationId: StopTrainingEntityRecognizer
export def "stop-training-entity-recognizer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-79 # required
  entity_recognizer_arn: string # The Amazon Resource Name (ARN) that identifies the entity recognizer currently being trained.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.StopTrainingEntityRecognizer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EntityRecognizerArn, var: entity_recognizer_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, entity_recognizer_arn: $entity_recognizer_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department.
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
  --x-amz-target: string@x-amz-target-completer-80 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the given Amazon Comprehend resource to which you want to associate the tags.
  tags: list # Tags being associated with a specific Amazon Comprehend resource. There can be a maximum of 50 tags (both existing and pending) associated with a specific resource. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a specific tag associated with an Amazon Comprehend resource.
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
  --x-amz-target: string@x-amz-target-completer-81 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the given Amazon Comprehend resource from which you want to remove the tags.
  tag_keys: list<string> # The initial part of a key-value pair that forms a tag being removed from a given resource. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department. Keys must be unique and cannot be duplicated for a particular resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information about the specified endpoint. For information about endpoints, see Managing endpoints (https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
#
# POST /
# Returns: record<DesiredModelArn: string>
# operationId: UpdateEndpoint
export def "update-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-82 # required
  endpoint_arn: string # The Amazon Resource Number (ARN) of the endpoint being updated.
  --desired-model-arn: string # The ARN of the new model to use when updating an existing endpoint.
  --desired-inference-units: int # The desired number of inference units to be used by the model using this endpoint. Each inference unit represents of a throughput of 100 characters per second.
  --desired-data-access-role-arn: string # Data access role ARN to use in case the new model is encrypted with a customer CMK.
  --flywheel-arn: string # The Amazon Resource Number (ARN) of the flywheel
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.UpdateEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}, {name: DesiredModelArn, var: desired_model_arn}, {name: DesiredInferenceUnits, var: desired_inference_units}, {name: DesiredDataAccessRoleArn, var: desired_data_access_role_arn}, {name: FlywheelArn, var: flywheel_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn, desired_model_arn: $desired_model_arn, desired_inference_units: $desired_inference_units, desired_data_access_role_arn: $desired_data_access_role_arn, flywheel_arn: $flywheel_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the configuration information for an existing flywheel.
#
# POST /
# Returns: record<FlywheelProperties: record<FlywheelArn: string, ActiveModelArn: string, DataAccessRoleArn: string, TaskConfig: record<LanguageCode: string, DocumentClassificationConfig: record, EntityRecognitionConfig: record>, DataLakeS3Uri: string, DataSecurityConfig: record<ModelKmsKeyId: string, VolumeKmsKeyId: string, DataLakeKmsKeyId: string, VpcConfig: record>, Status: string, ModelType: string, Message: string, CreationTime: string, LastModifiedTime: string, LatestFlywheelIteration: string>>
# operationId: UpdateFlywheel
export def "update-flywheel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-83 # required
  flywheel_arn: string # The Amazon Resource Number (ARN) of the flywheel to update.
  --active-model-arn: string # The Amazon Resource Number (ARN) of the active model version.
  --data-access-role-arn: string # The Amazon Resource Name (ARN) of the IAM role that grants Amazon Comprehend permission to access the flywheel data.
  --data-security-config: record # Data security configuration. — shape: {ModelKmsKeyId?: string, VolumeKmsKeyId?: string, VpcConfig?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Comprehend_20171127.UpdateFlywheel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FlywheelArn, var: flywheel_arn}, {name: ActiveModelArn, var: active_model_arn}, {name: DataAccessRoleArn, var: data_access_role_arn}, {name: DataSecurityConfig, var: data_security_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, flywheel_arn: $flywheel_arn, active_model_arn: $active_model_arn, data_access_role_arn: $data_access_role_arn, data_security_config: $data_security_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
