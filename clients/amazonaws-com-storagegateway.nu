# Auto-generated client for AWS Storage Gateway v2013-06-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/storagegateway/2013-06-30/openapi.json
# Auth: --token flag or $env.AWS_STORAGE_GATEWAY_TOKEN

const CLIENT = {
  base_url: "http://storagegateway.us-east-1.amazonaws.com"
  token_env_var: "AWS_STORAGE_GATEWAY_TOKEN"
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

def base-url-completer [] { ["http://storagegateway.us-east-1.amazonaws.com" "http://storagegateway.us-east-2.amazonaws.com" "http://storagegateway.us-west-1.amazonaws.com" "http://storagegateway.us-west-2.amazonaws.com" "http://storagegateway.us-gov-west-1.amazonaws.com" "http://storagegateway.us-gov-east-1.amazonaws.com" "http://storagegateway.ca-central-1.amazonaws.com" "http://storagegateway.eu-north-1.amazonaws.com" "http://storagegateway.eu-west-1.amazonaws.com" "http://storagegateway.eu-west-2.amazonaws.com" "http://storagegateway.eu-west-3.amazonaws.com" "http://storagegateway.eu-central-1.amazonaws.com" "http://storagegateway.eu-south-1.amazonaws.com" "http://storagegateway.af-south-1.amazonaws.com" "http://storagegateway.ap-northeast-1.amazonaws.com" "http://storagegateway.ap-northeast-2.amazonaws.com" "http://storagegateway.ap-northeast-3.amazonaws.com" "http://storagegateway.ap-southeast-1.amazonaws.com" "http://storagegateway.ap-southeast-2.amazonaws.com" "http://storagegateway.ap-east-1.amazonaws.com" "http://storagegateway.ap-south-1.amazonaws.com" "http://storagegateway.sa-east-1.amazonaws.com" "http://storagegateway.me-south-1.amazonaws.com" "https://storagegateway.us-east-1.amazonaws.com" "https://storagegateway.us-east-2.amazonaws.com" "https://storagegateway.us-west-1.amazonaws.com" "https://storagegateway.us-west-2.amazonaws.com" "https://storagegateway.us-gov-west-1.amazonaws.com" "https://storagegateway.us-gov-east-1.amazonaws.com" "https://storagegateway.ca-central-1.amazonaws.com" "https://storagegateway.eu-north-1.amazonaws.com" "https://storagegateway.eu-west-1.amazonaws.com" "https://storagegateway.eu-west-2.amazonaws.com" "https://storagegateway.eu-west-3.amazonaws.com" "https://storagegateway.eu-central-1.amazonaws.com" "https://storagegateway.eu-south-1.amazonaws.com" "https://storagegateway.af-south-1.amazonaws.com" "https://storagegateway.ap-northeast-1.amazonaws.com" "https://storagegateway.ap-northeast-2.amazonaws.com" "https://storagegateway.ap-northeast-3.amazonaws.com" "https://storagegateway.ap-southeast-1.amazonaws.com" "https://storagegateway.ap-southeast-2.amazonaws.com" "https://storagegateway.ap-east-1.amazonaws.com" "https://storagegateway.ap-south-1.amazonaws.com" "https://storagegateway.sa-east-1.amazonaws.com" "https://storagegateway.me-south-1.amazonaws.com" "http://storagegateway.cn-north-1.amazonaws.com.cn" "http://storagegateway.cn-northwest-1.amazonaws.com.cn" "https://storagegateway.cn-north-1.amazonaws.com.cn" "https://storagegateway.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["StorageGateway_20130630.ActivateGateway"] }
def x-amz-target-completer-1 [] { ["StorageGateway_20130630.AddCache"] }
def x-amz-target-completer-2 [] { ["StorageGateway_20130630.AddTagsToResource"] }
def x-amz-target-completer-3 [] { ["StorageGateway_20130630.AddUploadBuffer"] }
def x-amz-target-completer-4 [] { ["StorageGateway_20130630.AddWorkingStorage"] }
def x-amz-target-completer-5 [] { ["StorageGateway_20130630.AssignTapePool"] }
def x-amz-target-completer-6 [] { ["StorageGateway_20130630.AssociateFileSystem"] }
def x-amz-target-completer-7 [] { ["StorageGateway_20130630.AttachVolume"] }
def x-amz-target-completer-8 [] { ["StorageGateway_20130630.CancelArchival"] }
def x-amz-target-completer-9 [] { ["StorageGateway_20130630.CancelRetrieval"] }
def x-amz-target-completer-10 [] { ["StorageGateway_20130630.CreateCachediSCSIVolume"] }
def object-acl-completer [] { ["authenticated-read" "aws-exec-read" "bucket-owner-full-control" "bucket-owner-read" "private" "public-read" "public-read-write"] }
def x-amz-target-completer-11 [] { ["StorageGateway_20130630.CreateNFSFileShare"] }
def case-sensitivity-completer [] { ["CaseSensitive" "ClientSpecified"] }
def x-amz-target-completer-12 [] { ["StorageGateway_20130630.CreateSMBFileShare"] }
def x-amz-target-completer-13 [] { ["StorageGateway_20130630.CreateSnapshot"] }
def x-amz-target-completer-14 [] { ["StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint"] }
def x-amz-target-completer-15 [] { ["StorageGateway_20130630.CreateStorediSCSIVolume"] }
def storage-class-completer [] { ["DEEP_ARCHIVE" "GLACIER"] }
def retention-lock-type-completer [] { ["COMPLIANCE" "GOVERNANCE" "NONE"] }
def x-amz-target-completer-16 [] { ["StorageGateway_20130630.CreateTapePool"] }
def x-amz-target-completer-17 [] { ["StorageGateway_20130630.CreateTapeWithBarcode"] }
def x-amz-target-completer-18 [] { ["StorageGateway_20130630.CreateTapes"] }
def x-amz-target-completer-19 [] { ["StorageGateway_20130630.DeleteAutomaticTapeCreationPolicy"] }
def x-amz-target-completer-20 [] { ["StorageGateway_20130630.DeleteBandwidthRateLimit"] }
def x-amz-target-completer-21 [] { ["StorageGateway_20130630.DeleteChapCredentials"] }
def x-amz-target-completer-22 [] { ["StorageGateway_20130630.DeleteFileShare"] }
def x-amz-target-completer-23 [] { ["StorageGateway_20130630.DeleteGateway"] }
def x-amz-target-completer-24 [] { ["StorageGateway_20130630.DeleteSnapshotSchedule"] }
def x-amz-target-completer-25 [] { ["StorageGateway_20130630.DeleteTape"] }
def x-amz-target-completer-26 [] { ["StorageGateway_20130630.DeleteTapeArchive"] }
def x-amz-target-completer-27 [] { ["StorageGateway_20130630.DeleteTapePool"] }
def x-amz-target-completer-28 [] { ["StorageGateway_20130630.DeleteVolume"] }
def x-amz-target-completer-29 [] { ["StorageGateway_20130630.DescribeAvailabilityMonitorTest"] }
def x-amz-target-completer-30 [] { ["StorageGateway_20130630.DescribeBandwidthRateLimit"] }
def x-amz-target-completer-31 [] { ["StorageGateway_20130630.DescribeBandwidthRateLimitSchedule"] }
def x-amz-target-completer-32 [] { ["StorageGateway_20130630.DescribeCache"] }
def x-amz-target-completer-33 [] { ["StorageGateway_20130630.DescribeCachediSCSIVolumes"] }
def x-amz-target-completer-34 [] { ["StorageGateway_20130630.DescribeChapCredentials"] }
def x-amz-target-completer-35 [] { ["StorageGateway_20130630.DescribeFileSystemAssociations"] }
def x-amz-target-completer-36 [] { ["StorageGateway_20130630.DescribeGatewayInformation"] }
def x-amz-target-completer-37 [] { ["StorageGateway_20130630.DescribeMaintenanceStartTime"] }
def x-amz-target-completer-38 [] { ["StorageGateway_20130630.DescribeNFSFileShares"] }
def x-amz-target-completer-39 [] { ["StorageGateway_20130630.DescribeSMBFileShares"] }
def x-amz-target-completer-40 [] { ["StorageGateway_20130630.DescribeSMBSettings"] }
def x-amz-target-completer-41 [] { ["StorageGateway_20130630.DescribeSnapshotSchedule"] }
def x-amz-target-completer-42 [] { ["StorageGateway_20130630.DescribeStorediSCSIVolumes"] }
def x-amz-target-completer-43 [] { ["StorageGateway_20130630.DescribeTapeArchives"] }
def x-amz-target-completer-44 [] { ["StorageGateway_20130630.DescribeTapeRecoveryPoints"] }
def x-amz-target-completer-45 [] { ["StorageGateway_20130630.DescribeTapes"] }
def x-amz-target-completer-46 [] { ["StorageGateway_20130630.DescribeUploadBuffer"] }
def x-amz-target-completer-47 [] { ["StorageGateway_20130630.DescribeVTLDevices"] }
def x-amz-target-completer-48 [] { ["StorageGateway_20130630.DescribeWorkingStorage"] }
def x-amz-target-completer-49 [] { ["StorageGateway_20130630.DetachVolume"] }
def x-amz-target-completer-50 [] { ["StorageGateway_20130630.DisableGateway"] }
def x-amz-target-completer-51 [] { ["StorageGateway_20130630.DisassociateFileSystem"] }
def x-amz-target-completer-52 [] { ["StorageGateway_20130630.JoinDomain"] }
def x-amz-target-completer-53 [] { ["StorageGateway_20130630.ListAutomaticTapeCreationPolicies"] }
def x-amz-target-completer-54 [] { ["StorageGateway_20130630.ListFileShares"] }
def x-amz-target-completer-55 [] { ["StorageGateway_20130630.ListFileSystemAssociations"] }
def x-amz-target-completer-56 [] { ["StorageGateway_20130630.ListGateways"] }
def x-amz-target-completer-57 [] { ["StorageGateway_20130630.ListLocalDisks"] }
def x-amz-target-completer-58 [] { ["StorageGateway_20130630.ListTagsForResource"] }
def x-amz-target-completer-59 [] { ["StorageGateway_20130630.ListTapePools"] }
def x-amz-target-completer-60 [] { ["StorageGateway_20130630.ListTapes"] }
def x-amz-target-completer-61 [] { ["StorageGateway_20130630.ListVolumeInitiators"] }
def x-amz-target-completer-62 [] { ["StorageGateway_20130630.ListVolumeRecoveryPoints"] }
def x-amz-target-completer-63 [] { ["StorageGateway_20130630.ListVolumes"] }
def x-amz-target-completer-64 [] { ["StorageGateway_20130630.NotifyWhenUploaded"] }
def x-amz-target-completer-65 [] { ["StorageGateway_20130630.RefreshCache"] }
def x-amz-target-completer-66 [] { ["StorageGateway_20130630.RemoveTagsFromResource"] }
def x-amz-target-completer-67 [] { ["StorageGateway_20130630.ResetCache"] }
def x-amz-target-completer-68 [] { ["StorageGateway_20130630.RetrieveTapeArchive"] }
def x-amz-target-completer-69 [] { ["StorageGateway_20130630.RetrieveTapeRecoveryPoint"] }
def x-amz-target-completer-70 [] { ["StorageGateway_20130630.SetLocalConsolePassword"] }
def x-amz-target-completer-71 [] { ["StorageGateway_20130630.SetSMBGuestPassword"] }
def x-amz-target-completer-72 [] { ["StorageGateway_20130630.ShutdownGateway"] }
def x-amz-target-completer-73 [] { ["StorageGateway_20130630.StartAvailabilityMonitorTest"] }
def x-amz-target-completer-74 [] { ["StorageGateway_20130630.StartGateway"] }
def x-amz-target-completer-75 [] { ["StorageGateway_20130630.UpdateAutomaticTapeCreationPolicy"] }
def x-amz-target-completer-76 [] { ["StorageGateway_20130630.UpdateBandwidthRateLimit"] }
def x-amz-target-completer-77 [] { ["StorageGateway_20130630.UpdateBandwidthRateLimitSchedule"] }
def x-amz-target-completer-78 [] { ["StorageGateway_20130630.UpdateChapCredentials"] }
def x-amz-target-completer-79 [] { ["StorageGateway_20130630.UpdateFileSystemAssociation"] }
def gateway-capacity-completer [] { ["Large" "Medium" "Small"] }
def x-amz-target-completer-80 [] { ["StorageGateway_20130630.UpdateGatewayInformation"] }
def x-amz-target-completer-81 [] { ["StorageGateway_20130630.UpdateGatewaySoftwareNow"] }
def x-amz-target-completer-82 [] { ["StorageGateway_20130630.UpdateMaintenanceStartTime"] }
def x-amz-target-completer-83 [] { ["StorageGateway_20130630.UpdateNFSFileShare"] }
def x-amz-target-completer-84 [] { ["StorageGateway_20130630.UpdateSMBFileShare"] }
def x-amz-target-completer-85 [] { ["StorageGateway_20130630.UpdateSMBFileShareVisibility"] }
def x-amz-target-completer-86 [] { ["StorageGateway_20130630.UpdateSMBLocalGroups"] }
def smb-security-strategy-completer [] { ["ClientSpecified" "MandatoryEncryption" "MandatorySigning"] }
def x-amz-target-completer-87 [] { ["StorageGateway_20130630.UpdateSMBSecurityStrategy"] }
def x-amz-target-completer-88 [] { ["StorageGateway_20130630.UpdateSnapshotSchedule"] }
def x-amz-target-completer-89 [] { ["StorageGateway_20130630.UpdateVTLDeviceType"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    activate-gateway: "record<GatewayARN: string>"
    add-cache: "record<GatewayARN: string>"
    add-tags-to-resource: "record<ResourceARN: string>"
    add-upload-buffer: "record<GatewayARN: string>"
    add-working-storage: "record<GatewayARN: string>"
    assign-tape-pool: "record<TapeARN: string>"
    associate-file-system: "record<FileSystemAssociationARN: string>"
    attach-volume: "record<VolumeARN: string, TargetARN: string>"
    cancel-archival: "record<TapeARN: string>"
    cancel-retrieval: "record<TapeARN: string>"
    create-cachedi-scsi-volume: "record<VolumeARN: string, TargetARN: string>"
    create-nfs-file-share: "record<FileShareARN: string>"
    create-smb-file-share: "record<FileShareARN: string>"
    create-snapshot: "record<VolumeARN: string, SnapshotId: string>"
    create-snapshot-from-volume-recovery-point: "record<SnapshotId: string, VolumeARN: string, VolumeRecoveryPointTime: string>"
    create-storedi-scsi-volume: "record<VolumeARN: string, VolumeSizeInBytes: int, TargetARN: string>"
    create-tape-pool: "record<PoolARN: string>"
    create-tape-with-barcode: "record<TapeARN: string>"
    create-tapes: "record<TapeARNs: list<string>>"
    delete-automatic-tape-creation-policy: "record<GatewayARN: string>"
    delete-bandwidth-rate-limit: "record<GatewayARN: string>"
    delete-chap-credentials: "record<TargetARN: string, InitiatorName: string>"
    delete-file-share: "record<FileShareARN: string>"
    delete-gateway: "record<GatewayARN: string>"
    delete-snapshot-schedule: "record<VolumeARN: string>"
    delete-tape: "record<TapeARN: string>"
    delete-tape-archive: "record<TapeARN: string>"
    delete-tape-pool: "record<PoolARN: string>"
    delete-volume: "record<VolumeARN: string>"
    describe-availability-monitor-test: "record<GatewayARN: string, Status: string, StartTime: string>"
    describe-bandwidth-rate-limit: "record<GatewayARN: string, AverageUploadRateLimitInBitsPerSec: int, AverageDownloadRateLimitInBitsPerSec: int>"
    describe-bandwidth-rate-limit-schedule: "record<GatewayARN: string, BandwidthRateLimitIntervals: table<StartHourOfDay: int, StartMinuteOfHour: int, EndHourOfDay: int, EndMinuteOfHour: int, DaysOfWeek: list, AverageUploadRateLimitInBitsPerSec: int, AverageDownloadRateLimitInBitsPerSec: int>>"
    describe-cache: "record<GatewayARN: string, DiskIds: list<string>, CacheAllocatedInBytes: int, CacheUsedPercentage: float, CacheDirtyPercentage: float, CacheHitPercentage: float, CacheMissPercentage: float>"
    describe-cachedi-scsi-volumes: "record<CachediSCSIVolumes: table<VolumeARN: string, VolumeId: string, VolumeType: string, VolumeStatus: string, VolumeAttachmentStatus: string, VolumeSizeInBytes: int, VolumeProgress: float, SourceSnapshotId: string, VolumeiSCSIAttributes: record, CreatedDate: string, VolumeUsedInBytes: int, KMSKey: string, TargetName: string>>"
    describe-chap-credentials: "record<ChapCredentials: table<TargetARN: string, SecretToAuthenticateInitiator: string, InitiatorName: string, SecretToAuthenticateTarget: string>>"
    describe-file-system-associations: "record<FileSystemAssociationInfoList: table<FileSystemAssociationARN: string, LocationARN: string, FileSystemAssociationStatus: string, AuditDestinationARN: string, GatewayARN: string, Tags: list, CacheAttributes: record, EndpointNetworkConfiguration: record, FileSystemAssociationStatusDetails: list>>"
    describe-gateway-information: "record<GatewayARN: string, GatewayId: string, GatewayName: string, GatewayTimezone: string, GatewayState: string, GatewayNetworkInterfaces: table<Ipv4Address: string, MacAddress: string, Ipv6Address: string>, GatewayType: string, NextUpdateAvailabilityDate: string, LastSoftwareUpdate: string, Ec2InstanceId: string, Ec2InstanceRegion: string, Tags: table<Key: string, Value: string>, VPCEndpoint: string, CloudWatchLogGroupARN: string, HostEnvironment: string, EndpointType: string, SoftwareUpdatesEndDate: string, DeprecationDate: string, GatewayCapacity: string, SupportedGatewayCapacities: list<string>, HostEnvironmentId: string>"
    describe-maintenance-start-time: "record<GatewayARN: string, HourOfDay: int, MinuteOfHour: int, DayOfWeek: int, DayOfMonth: int, Timezone: string>"
    describe-nfs-file-shares: "record<NFSFileShareInfoList: table<NFSFileShareDefaults: record, FileShareARN: string, FileShareId: string, FileShareStatus: string, GatewayARN: string, KMSEncrypted: bool, KMSKey: string, Path: string, Role: string, LocationARN: string, DefaultStorageClass: string, ObjectACL: string, ClientList: list, Squash: string, ReadOnly: bool, GuessMIMETypeEnabled: bool, RequesterPays: bool, Tags: list, FileShareName: string, CacheAttributes: record, NotificationPolicy: string, VPCEndpointDNSName: string, BucketRegion: string, AuditDestinationARN: string>>"
    describe-smb-file-shares: "record<SMBFileShareInfoList: table<FileShareARN: string, FileShareId: string, FileShareStatus: string, GatewayARN: string, KMSEncrypted: bool, KMSKey: string, Path: string, Role: string, LocationARN: string, DefaultStorageClass: string, ObjectACL: string, ReadOnly: bool, GuessMIMETypeEnabled: bool, RequesterPays: bool, SMBACLEnabled: bool, AccessBasedEnumeration: bool, AdminUserList: list, ValidUserList: list, InvalidUserList: list, AuditDestinationARN: string, Authentication: string, CaseSensitivity: string, Tags: list, FileShareName: string, CacheAttributes: record, NotificationPolicy: string, VPCEndpointDNSName: string, BucketRegion: string, OplocksEnabled: bool>>"
    describe-smb-settings: "record<GatewayARN: string, DomainName: string, ActiveDirectoryStatus: string, SMBGuestPasswordSet: bool, SMBSecurityStrategy: string, FileSharesVisible: bool, SMBLocalGroups: record<GatewayAdmins: list<string>>>"
    describe-snapshot-schedule: "record<VolumeARN: string, StartAt: int, RecurrenceInHours: int, Description: string, Timezone: string, Tags: table<Key: string, Value: string>>"
    describe-storedi-scsi-volumes: "record<StorediSCSIVolumes: table<VolumeARN: string, VolumeId: string, VolumeType: string, VolumeStatus: string, VolumeAttachmentStatus: string, VolumeSizeInBytes: int, VolumeProgress: float, VolumeDiskId: string, SourceSnapshotId: string, PreservedExistingData: bool, VolumeiSCSIAttributes: record, CreatedDate: string, VolumeUsedInBytes: int, KMSKey: string, TargetName: string>>"
    describe-tape-archives: "record<TapeArchives: table<TapeARN: string, TapeBarcode: string, TapeCreatedDate: string, TapeSizeInBytes: int, CompletionTime: string, RetrievedTo: string, TapeStatus: string, TapeUsedInBytes: int, KMSKey: string, PoolId: string, Worm: bool, RetentionStartDate: string, PoolEntryDate: string>, Marker: string>"
    describe-tape-recovery-points: "record<GatewayARN: string, TapeRecoveryPointInfos: table<TapeARN: string, TapeRecoveryPointTime: string, TapeSizeInBytes: int, TapeStatus: string>, Marker: string>"
    describe-tapes: "record<Tapes: table<TapeARN: string, TapeBarcode: string, TapeCreatedDate: string, TapeSizeInBytes: int, TapeStatus: string, VTLDevice: string, Progress: float, TapeUsedInBytes: int, KMSKey: string, PoolId: string, Worm: bool, RetentionStartDate: string, PoolEntryDate: string>, Marker: string>"
    describe-upload-buffer: "record<GatewayARN: string, DiskIds: list<string>, UploadBufferUsedInBytes: int, UploadBufferAllocatedInBytes: int>"
    describe-vtl-devices: "record<GatewayARN: string, VTLDevices: table<VTLDeviceARN: string, VTLDeviceType: string, VTLDeviceVendor: string, VTLDeviceProductIdentifier: string, DeviceiSCSIAttributes: record>, Marker: string>"
    describe-working-storage: "record<GatewayARN: string, DiskIds: list<string>, WorkingStorageUsedInBytes: int, WorkingStorageAllocatedInBytes: int>"
    detach-volume: "record<VolumeARN: string>"
    disable-gateway: "record<GatewayARN: string>"
    disassociate-file-system: "record<FileSystemAssociationARN: string>"
    join-domain: "record<GatewayARN: string, ActiveDirectoryStatus: string>"
    list-automatic-tape-creation-policies: "record<AutomaticTapeCreationPolicyInfos: table<AutomaticTapeCreationRules: list, GatewayARN: string>>"
    list-file-shares: "record<Marker: string, NextMarker: string, FileShareInfoList: table<FileShareType: string, FileShareARN: string, FileShareId: string, FileShareStatus: string, GatewayARN: string>>"
    list-file-system-associations: "record<Marker: string, NextMarker: string, FileSystemAssociationSummaryList: table<FileSystemAssociationId: string, FileSystemAssociationARN: string, FileSystemAssociationStatus: string, GatewayARN: string>>"
    list-gateways: "record<Gateways: table<GatewayId: string, GatewayARN: string, GatewayType: string, GatewayOperationalState: string, GatewayName: string, Ec2InstanceId: string, Ec2InstanceRegion: string, HostEnvironment: string, HostEnvironmentId: string>, Marker: string>"
    list-local-disks: "record<GatewayARN: string, Disks: table<DiskId: string, DiskPath: string, DiskNode: string, DiskStatus: string, DiskSizeInBytes: int, DiskAllocationType: string, DiskAllocationResource: string, DiskAttributeList: list>>"
    list-tags-for-resource: "record<ResourceARN: string, Marker: string, Tags: table<Key: string, Value: string>>"
    list-tape-pools: "record<PoolInfos: table<PoolARN: string, PoolName: string, StorageClass: string, RetentionLockType: string, RetentionLockTimeInDays: int, PoolStatus: string>, Marker: string>"
    list-tapes: "record<TapeInfos: table<TapeARN: string, TapeBarcode: string, TapeSizeInBytes: int, TapeStatus: string, GatewayARN: string, PoolId: string, RetentionStartDate: string, PoolEntryDate: string>, Marker: string>"
    list-volume-initiators: "record<Initiators: list<string>>"
    list-volume-recovery-points: "record<GatewayARN: string, VolumeRecoveryPointInfos: table<VolumeARN: string, VolumeSizeInBytes: int, VolumeUsageInBytes: int, VolumeRecoveryPointTime: string>>"
    list-volumes: "record<GatewayARN: string, Marker: string, VolumeInfos: table<VolumeARN: string, VolumeId: string, GatewayARN: string, GatewayId: string, VolumeType: string, VolumeSizeInBytes: int, VolumeAttachmentStatus: string>>"
    notify-when-uploaded: "record<FileShareARN: string, NotificationId: string>"
    refresh-cache: "record<FileShareARN: string, NotificationId: string>"
    remove-tags-from-resource: "record<ResourceARN: string>"
    reset-cache: "record<GatewayARN: string>"
    retrieve-tape-archive: "record<TapeARN: string>"
    retrieve-tape-recovery-point: "record<TapeARN: string>"
    set-local-console-password: "record<GatewayARN: string>"
    set-smb-guest-password: "record<GatewayARN: string>"
    shutdown-gateway: "record<GatewayARN: string>"
    start-availability-monitor-test: "record<GatewayARN: string>"
    start-gateway: "record<GatewayARN: string>"
    update-automatic-tape-creation-policy: "record<GatewayARN: string>"
    update-bandwidth-rate-limit: "record<GatewayARN: string>"
    update-bandwidth-rate-limit-schedule: "record<GatewayARN: string>"
    update-chap-credentials: "record<TargetARN: string, InitiatorName: string>"
    update-file-system-association: "record<FileSystemAssociationARN: string>"
    update-gateway-information: "record<GatewayARN: string, GatewayName: string>"
    update-gateway-software-now: "record<GatewayARN: string>"
    update-maintenance-start-time: "record<GatewayARN: string>"
    update-nfs-file-share: "record<FileShareARN: string>"
    update-smb-file-share: "record<FileShareARN: string>"
    update-smb-file-share-visibility: "record<GatewayARN: string>"
    update-smb-local-groups: "record<GatewayARN: string>"
    update-smb-security-strategy: "record<GatewayARN: string>"
    update-snapshot-schedule: "record<VolumeARN: string>"
    update-vtl-device-type: "record<VTLDeviceARN: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["activate-gateway" "add-cache" "add-tags-to-resource" "add-upload-buffer" "add-working-storage" "assign-tape-pool" "associate-file-system" "attach-volume" "cancel-archival" "cancel-retrieval" "create-cachedi-scsi-volume" "create-nfs-file-share" "create-smb-file-share" "create-snapshot" "create-snapshot-from-volume-recovery-point" "create-storedi-scsi-volume" "create-tape-pool" "create-tape-with-barcode" "create-tapes" "delete-automatic-tape-creation-policy" "delete-bandwidth-rate-limit" "delete-chap-credentials" "delete-file-share" "delete-gateway" "delete-snapshot-schedule" "delete-tape" "delete-tape-archive" "delete-tape-pool" "delete-volume" "describe-availability-monitor-test" "describe-bandwidth-rate-limit" "describe-bandwidth-rate-limit-schedule" "describe-cache" "describe-cachedi-scsi-volumes" "describe-chap-credentials" "describe-file-system-associations" "describe-gateway-information" "describe-maintenance-start-time" "describe-nfs-file-shares" "describe-smb-file-shares" "describe-smb-settings" "describe-snapshot-schedule" "describe-storedi-scsi-volumes" "describe-tape-archives" "describe-tape-recovery-points" "describe-tapes" "describe-upload-buffer" "describe-vtl-devices" "describe-working-storage" "detach-volume" "disable-gateway" "disassociate-file-system" "join-domain" "list-automatic-tape-creation-policies" "list-file-shares" "list-file-system-associations" "list-gateways" "list-local-disks" "list-tags-for-resource" "list-tape-pools" "list-tapes" "list-volume-initiators" "list-volume-recovery-points" "list-volumes" "notify-when-uploaded" "refresh-cache" "remove-tags-from-resource" "reset-cache" "retrieve-tape-archive" "retrieve-tape-recovery-point" "set-local-console-password" "set-smb-guest-password" "shutdown-gateway" "start-availability-monitor-test" "start-gateway" "update-automatic-tape-creation-policy" "update-bandwidth-rate-limit" "update-bandwidth-rate-limit-schedule" "update-chap-credentials" "update-file-system-association" "update-gateway-information" "update-gateway-software-now" "update-maintenance-start-time" "update-nfs-file-share" "update-smb-file-share" "update-smb-file-share-visibility" "update-smb-local-groups" "update-smb-security-strategy" "update-snapshot-schedule" "update-vtl-device-type" "commands"] | sort) } | get name | first)
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

# Activates the gateway you previously deployed on your host. In the activation process, you specify information such as the Amazon Web Services Region that you want to use for storing snapshots or tapes, the time zone for scheduled snapshots the gateway snapshot schedule window, an activation key, and a name for your gateway. The activation process also associates your gateway with your account. For more information, see UpdateGatewayInformation. You must turn on the gateway VM before you can activate your gateway.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: ActivateGateway
export def "activate-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  activation_key: string # Your gateway activation key. You can obtain the activation key by sending an HTTP GET request with redirects enabled to the gateway IP address (port 80). The redirect URL returned in the response provides you the activation key for your gateway in the query string parameter activationKey. It may also include other activation-related parameters, however, these are merely defaults -- the arguments you pass to the ActivateGateway API call determine the actual configuration of your gateway. For more information, see Getting activation key (https://docs.aws.amazon.com/storagegateway/latest/userguide/get-activation-key.html) in the Storage Gateway User Guide.
  gateway_name: string # The name you configured for your gateway.
  gateway_timezone: string # A value that indicates the time zone you want to set for the gateway. The time zone is of the format "GMT-hr:mm" or "GMT+hr:mm". For example, GMT-4:00 indicates the time is 4 hours behind GMT. GMT+2:00 indicates the time is 2 hours ahead of GMT. The time zone is used, for example, for scheduling snapshots and your gateway's maintenance schedule.
  gateway_region: string # A value that indicates the Amazon Web Services Region where you want to store your data. The gateway Amazon Web Services Region specified must be the same Amazon Web Services Region as the Amazon Web Services Region in your Host header in the request. For more information about available Amazon Web Services Regions and endpoints for Storage Gateway, see Storage Gateway endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/sg.html) in the Amazon Web Services General Reference. Valid Values: See Storage Gateway endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/sg.html) in the Amazon Web Services General Reference.
  --gateway-type: string # A value that defines the type of gateway to activate. The type specified is critical to all later functions of the gateway and cannot be changed after activation. The default value is CACHED. Valid Values: STORED | CACHED | VTL | VTL_SNOW | FILE_S3 | FILE_FSX_SMB
  --tape-drive-type: string # The value that indicates the type of tape drive to use for tape gateway. This field is optional. Valid Values: IBM-ULT3580-TD5
  --medium-changer-type: string # The value that indicates the type of medium changer to use for tape gateway. This field is optional. Valid Values: STK-L700 | AWS-Gateway-VTL | IBM-03584L32-0402
  --tags: list # A list of up to 50 tags that you can assign to the gateway. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers that can be represented in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256 characters. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ActivateGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActivationKey, var: activation_key}, {name: GatewayName, var: gateway_name}, {name: GatewayTimezone, var: gateway_timezone}, {name: GatewayRegion, var: gateway_region}, {name: GatewayType, var: gateway_type}, {name: TapeDriveType, var: tape_drive_type}, {name: MediumChangerType, var: medium_changer_type}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, activation_key: $activation_key, gateway_name: $gateway_name, gateway_timezone: $gateway_timezone, gateway_region: $gateway_region, gateway_type: $gateway_type, tape_drive_type: $tape_drive_type, medium_changer_type: $medium_changer_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures one or more gateway local disks as cache for a gateway. This operation is only supported in the cached volume, tape, and file gateway type (see How Storage Gateway works (architecture) (https://docs.aws.amazon.com/storagegateway/latest/userguide/StorageGatewayConcepts.html). In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add cache, and one or more disk IDs that you want to configure as cache.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: AddCache
export def "add-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  disk_ids: list<string> # An array of strings that identify disks that are to be configured as working storage. Each string has a minimum length of 1 and maximum length of 300. You can get the disk IDs from the ListLocalDisks API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.AddCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: DiskIds, var: disk_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, disk_ids: $disk_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more tags to the specified resource. You use tags to add metadata to resources, which you can use to categorize these resources. For example, you can categorize resources by purpose, owner, environment, or team. Each tag consists of a key and a value, which you define. You can add tags to the following Storage Gateway resources: Storage gateways of all types Storage volumes Virtual tapes NFS and SMB file shares File System associations You can create a maximum of 50 tags for each resource. Virtual tapes and storage volumes that are recovered to a new gateway maintain their tags.
#
# POST /
# Returns: record<ResourceARN: string>
# operationId: AddTagsToResource
export def "add-tags-to-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource you want to add tags to.
  tags: list # The key-value pair that represents the tag you want to add to the resource. The value can be an empty string. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.AddTagsToResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures one or more gateway local disks as upload buffer for a specified gateway. This operation is supported for the stored volume, cached volume, and tape gateway types. In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add upload buffer, and one or more disk IDs that you want to configure as upload buffer.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: AddUploadBuffer
export def "add-upload-buffer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  disk_ids: list<string> # An array of strings that identify disks that are to be configured as working storage. Each string has a minimum length of 1 and maximum length of 300. You can get the disk IDs from the ListLocalDisks API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.AddUploadBuffer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: DiskIds, var: disk_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, disk_ids: $disk_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures one or more gateway local disks as working storage for a gateway. This operation is only supported in the stored volume gateway type. This operation is deprecated in cached volume API version 20120630. Use AddUploadBuffer instead. Working storage is also referred to as upload buffer. You can also use the AddUploadBuffer operation to add upload buffer to a stored volume gateway. In the request, you specify the gateway Amazon Resource Name (ARN) to which you want to add working storage, and one or more disk IDs that you want to configure as working storage.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: AddWorkingStorage
export def "add-working-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  disk_ids: list<string> # An array of strings that identify disks that are to be configured as working storage. Each string has a minimum length of 1 and maximum length of 300. You can get the disk IDs from the ListLocalDisks API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.AddWorkingStorage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: DiskIds, var: disk_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, disk_ids: $disk_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns a tape to a tape pool for archiving. The tape assigned to a pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the S3 storage class (S3 Glacier or S3 Glacier Deep Archive) that corresponds to the pool.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: AssignTapePool
export def "assign-tape-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  tape_arn: string # The unique Amazon Resource Name (ARN) of the virtual tape that you want to add to the tape pool.
  pool_id: string # The ID of the pool that you want to add your tape to for archiving. The tape in this pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the storage class (S3 Glacier or S3 Glacier Deep Archive) that corresponds to the pool.
  --bypass-governance-retention: oneof<nothing, bool> # Set permissions to bypass governance retention. If the lock type of the archived tape is Governance, the tape's archived age is not older than RetentionLockInDays, and the user does not already have BypassGovernanceRetention, setting this to TRUE enables the user to bypass the retention lock. This parameter is set to true by default for calls from the console. Valid values: TRUE | FALSE
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.AssignTapePool"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TapeARN, var: tape_arn}, {name: PoolId, var: pool_id}, {name: BypassGovernanceRetention, var: bypass_governance_retention}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tape_arn: $tape_arn, pool_id: $pool_id, bypass_governance_retention: $bypass_governance_retention
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate an Amazon FSx file system with the FSx File Gateway. After the association process is complete, the file shares on the Amazon FSx file system are available for access through the gateway. This operation only supports the FSx File Gateway type.
#
# POST /
# Returns: record<FileSystemAssociationARN: string>
# operationId: AssociateFileSystem
export def "associate-file-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  user_name: string # The user name of the user credential that has permission to access the root share D$ of the Amazon FSx file system. The user account must belong to the Amazon FSx delegated admin user group.
  password: string # The password of the user credential. (format: password)
  client_token: string # A unique string value that you supply that is used by the FSx File Gateway to ensure idempotent file system association creation.
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  location_arn: string # The Amazon Resource Name (ARN) of the Amazon FSx file system to associate with the FSx File Gateway.
  --tags: list # A list of up to 50 tags that can be assigned to the file system association. Each tag is a key-value pair. — item shape: {Key: string, Value: string}
  --audit-destination-arn: string # The Amazon Resource Name (ARN) of the storage used for the audit logs.
  --cache-attributes: record # The refresh cache information for the file share or FSx file systems. — shape: {CacheStaleTimeoutInSeconds?: int}
  --endpoint-network-configuration: record # Specifies network configuration information for the gateway associated with the Amazon FSx file system. — shape: {IpAddresses?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.AssociateFileSystem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: UserName, var: user_name}, {name: Password, var: password}, {name: ClientToken, var: client_token}, {name: GatewayARN, var: gateway_arn}, {name: LocationARN, var: location_arn}, {name: Tags, var: tags}, {name: AuditDestinationARN, var: audit_destination_arn}, {name: CacheAttributes, var: cache_attributes}, {name: EndpointNetworkConfiguration, var: endpoint_network_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, user_name: $user_name, password: $password, client_token: $client_token, gateway_arn: $gateway_arn, location_arn: $location_arn, tags: $tags, audit_destination_arn: $audit_destination_arn, cache_attributes: $cache_attributes, endpoint_network_configuration: $endpoint_network_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connects a volume to an iSCSI connection and then attaches the volume to the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance.
#
# POST /
# Returns: record<VolumeARN: string, TargetARN: string>
# operationId: AttachVolume
export def "attach-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --target-name: string # The name of the iSCSI target used by an initiator to connect to a volume and used as a suffix for the target ARN. For example, specifying TargetName as myvolume results in the target ARN of arn:aws:storagegateway:us-east-2:111122223333:gateway/sgw-12A3456B/target/iqn.1997-05.com.amazon:myvolume. The target name must be unique across all volumes on a gateway. If you don't specify a value, Storage Gateway uses the value that was previously used for this volume as the new target name.
  volume_arn: string # The Amazon Resource Name (ARN) of the volume to attach to the specified gateway.
  network_interface_id: string # The network interface of the gateway on which to expose the iSCSI target. Only IPv4 addresses are accepted. Use DescribeGatewayInformation to get a list of the network interfaces available on a gateway. Valid Values: A valid IP address.
  --disk-id: string # The unique device ID or other distinguishing data that identifies the local disk used to create the volume. This value is only required when you are attaching a stored volume.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.AttachVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: TargetName, var: target_name}, {name: VolumeARN, var: volume_arn}, {name: NetworkInterfaceId, var: network_interface_id}, {name: DiskId, var: disk_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, target_name: $target_name, volume_arn: $volume_arn, network_interface_id: $network_interface_id, disk_id: $disk_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels archiving of a virtual tape to the virtual tape shelf (VTS) after the archiving process is initiated. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: CancelArchival
export def "cancel-archival" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  tape_arn: string # The Amazon Resource Name (ARN) of the virtual tape you want to cancel archiving for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CancelArchival"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: TapeARN, var: tape_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, tape_arn: $tape_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels retrieval of a virtual tape from the virtual tape shelf (VTS) to a gateway after the retrieval process is initiated. The virtual tape is returned to the VTS. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: CancelRetrieval
export def "cancel-retrieval" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  tape_arn: string # The Amazon Resource Name (ARN) of the virtual tape you want to cancel retrieval for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CancelRetrieval"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: TapeARN, var: tape_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, tape_arn: $tape_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a cached volume on a specified cached volume gateway. This operation is only supported in the cached volume gateway type. Cache storage must be allocated to the gateway before you can create a cached volume. Use the AddCache operation to add cache storage to a gateway. In the request, you must specify the gateway, size of the volume in bytes, the iSCSI target name, an IP address on which to expose the target, and a unique client token. In response, the gateway creates the volume and returns information about it. This information includes the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target. Optionally, you can provide the ARN for an existing volume as the SourceVolumeARN for this cached volume, which creates an exact copy of the existing volume’s latest recovery point. The VolumeSizeInBytes value must be equal to or larger than the size of the copied volume, in bytes.
#
# POST /
# Returns: record<VolumeARN: string, TargetARN: string>
# operationId: CreateCachediSCSIVolume
export def "create-cachedi-scsi-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  volume_size_in_bytes: int # The size of the volume in bytes.
  --snapshot-id: string # The snapshot ID (e.g. "snap-1122aabb") of the snapshot to restore as the new cached volume. Specify this field if you want to create the iSCSI storage volume from a snapshot; otherwise, do not include this field. To list snapshots for your account use DescribeSnapshots (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html) in the Amazon Elastic Compute Cloud API Reference.
  target_name: string # The name of the iSCSI target used by an initiator to connect to a volume and used as a suffix for the target ARN. For example, specifying TargetName as myvolume results in the target ARN of arn:aws:storagegateway:us-east-2:111122223333:gateway/sgw-12A3456B/target/iqn.1997-05.com.amazon:myvolume. The target name must be unique across all volumes on a gateway. If you don't specify a value, Storage Gateway uses the value that was previously used for this volume as the new target name.
  --source-volume-arn: string # The ARN for an existing volume. Specifying this ARN makes the new volume into an exact copy of the specified existing volume's latest recovery point. The VolumeSizeInBytes value for this new volume must be equal to or larger than the size of the existing volume, in bytes.
  network_interface_id: string # The network interface of the gateway on which to expose the iSCSI target. Only IPv4 addresses are accepted. Use DescribeGatewayInformation to get a list of the network interfaces available on a gateway. Valid Values: A valid IP address.
  client_token: string # A unique identifier that you use to retry a request. If you retry a request, use the same ClientToken you specified in the initial request.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  --tags: list # A list of up to 50 tags that you can assign to a cached volume. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers that you can represent in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256 characters. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateCachediSCSIVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: VolumeSizeInBytes, var: volume_size_in_bytes}, {name: SnapshotId, var: snapshot_id}, {name: TargetName, var: target_name}, {name: SourceVolumeARN, var: source_volume_arn}, {name: NetworkInterfaceId, var: network_interface_id}, {name: ClientToken, var: client_token}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, volume_size_in_bytes: $volume_size_in_bytes, snapshot_id: $snapshot_id, target_name: $target_name, source_volume_arn: $source_volume_arn, network_interface_id: $network_interface_id, client_token: $client_token, kms_encrypted: $kms_encrypted, kms_key: $kms_key, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Network File System (NFS) file share on an existing S3 File Gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using an NFS interface. This operation is only supported for S3 File Gateways. S3 File gateway requires Security Token Service (Amazon Web Services STS) to be activated to enable you to create a file share. Make sure Amazon Web Services STS is activated in the Amazon Web Services Region you are creating your S3 File Gateway in. If Amazon Web Services STS is not activated in the Amazon Web Services Region, activate it. For information about how to activate Amazon Web Services STS, see Activating and deactivating Amazon Web Services STS in an Amazon Web Services Region (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html) in the Identity and Access Management User Guide. S3 File Gateways do not support creating hard or symbolic links on a file share.
#
# POST /
# Returns: record<FileShareARN: string>
# operationId: CreateNFSFileShare
export def "create-nfs-file-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  client_token: string # A unique string value that you supply that is used by S3 File Gateway to ensure idempotent file share creation.
  --nfs-file-share-defaults: record # Describes Network File System (NFS) file share default values. Files and folders stored as Amazon S3 objects in S3 buckets don't, by default, have Unix file permissions assigned to them. Upon discovery in an S3 bucket by Storage Gateway, the S3 objects that represent files and folders are assigned these default Unix permissions. This operation is only supported for S3 File Gateways. — shape: {FileMode?: string, DirectoryMode?: string, GroupId?: int, OwnerId?: int}
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  role: string # The ARN of the IAM role that an S3 File Gateway assumes when it accesses the underlying storage.
  location_arn: string # A custom ARN for the backend storage used for storing data for file shares. It includes a resource ARN with an optional prefix concatenation. The prefix must end with a forward slash (/). You can specify LocationARN as a bucket ARN, access point ARN or access point alias, as shown in the following examples. Bucket ARN: arn:aws:s3:::my-bucket/prefix/ Access point ARN: arn:aws:s3:region:account-id:accesspoint/access-point-name/prefix/ If you specify an access point, the bucket policy must be configured to delegate access control to the access point. For information, see Delegating access control to access points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points-policies.html#access-points-delegating-control) in the Amazon S3 User Guide. Access point alias: test-ap-ab123cdef4gehijklmn5opqrstuvuse1a-s3alias
  --default-storage-class: string
  --object-acl: string@object-acl-completer # A value that sets the access control list (ACL) permission for objects in the S3 bucket that an S3 File Gateway puts objects into. The default value is private.
  --client-list: list<string> # The list of clients that are allowed to access the S3 File Gateway. The list must contain either valid IP addresses or valid CIDR blocks.
  --squash: string # The user mapped to anonymous user. Valid options are the following: RootSquash: Only root is mapped to anonymous user. NoSquash: No one is mapped to anonymous user. AllSquash: Everyone is mapped to anonymous user.
  --read-only: oneof<nothing, bool> # A value that sets the write status of a file share. Set this value to true to set the write status to read-only, otherwise set to false. Valid Values: true | false
  --guess-mime-type-enabled: oneof<nothing, bool> # A value that enables guessing of the MIME type for uploaded objects based on file extensions. Set this value to true to enable MIME type guessing, otherwise set to false. The default value is true. Valid Values: true | false
  --requester-pays: oneof<nothing, bool> # A value that sets who pays the cost of the request and the cost associated with data download from the S3 bucket. If this value is set to true, the requester pays the costs; otherwise, the S3 bucket owner pays. However, the S3 bucket owner always pays the cost of storing data. RequesterPays is a configuration for the S3 bucket that backs the file share, so make sure that the configuration on the file share is the same as the S3 bucket configuration. Valid Values: true | false
  --tags: list # A list of up to 50 tags that can be assigned to the NFS file share. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
  --file-share-name: string # The name of the file share. Optional. FileShareName must be set if an S3 prefix name is set in LocationARN, or if an access point or access point alias is used.
  --cache-attributes: record # The refresh cache information for the file share or FSx file systems. — shape: {CacheStaleTimeoutInSeconds?: int}
  --notification-policy: string # The notification policy of the file share. SettlingTimeInSeconds controls the number of seconds to wait after the last point in time a client wrote to a file before generating an ObjectUploaded notification. Because clients can make many small writes to files, it's best to set this parameter for as long as possible to avoid generating multiple notifications for the same file in a small time period. SettlingTimeInSeconds has no effect on the timing of the object uploading to Amazon S3, only the timing of the notification. The following example sets NotificationPolicy on with SettlingTimeInSeconds set to 60. {\"Upload\": {\"SettlingTimeInSeconds\": 60}} The following example sets NotificationPolicy off. {}
  --vpc-endpoint-dns-name: string # Specifies the DNS name for the VPC endpoint that the NFS file share uses to connect to Amazon S3. This parameter is required for NFS file shares that connect to Amazon S3 through a VPC endpoint, a VPC access point, or an access point alias that points to a VPC access point.
  --bucket-region: string # Specifies the Region of the S3 bucket where the NFS file share stores files. This parameter is required for NFS file shares that connect to Amazon S3 through a VPC endpoint, a VPC access point, or an access point alias that points to a VPC access point.
  --audit-destination-arn: string # The Amazon Resource Name (ARN) of the storage used for audit logs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateNFSFileShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientToken, var: client_token}, {name: NFSFileShareDefaults, var: nfs_file_share_defaults}, {name: GatewayARN, var: gateway_arn}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: Role, var: role}, {name: LocationARN, var: location_arn}, {name: DefaultStorageClass, var: default_storage_class}, {name: ObjectACL, var: object_acl}, {name: ClientList, var: client_list}, {name: Squash, var: squash}, {name: ReadOnly, var: read_only}, {name: GuessMIMETypeEnabled, var: guess_mime_type_enabled}, {name: RequesterPays, var: requester_pays}, {name: Tags, var: tags}, {name: FileShareName, var: file_share_name}, {name: CacheAttributes, var: cache_attributes}, {name: NotificationPolicy, var: notification_policy}, {name: VPCEndpointDNSName, var: vpc_endpoint_dns_name}, {name: BucketRegion, var: bucket_region}, {name: AuditDestinationARN, var: audit_destination_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, nfs_file_share_defaults: $nfs_file_share_defaults, gateway_arn: $gateway_arn, kms_encrypted: $kms_encrypted, kms_key: $kms_key, role: $role, location_arn: $location_arn, default_storage_class: $default_storage_class, object_acl: $object_acl, client_list: $client_list, squash: $squash, read_only: $read_only, guess_mime_type_enabled: $guess_mime_type_enabled, requester_pays: $requester_pays, tags: $tags, file_share_name: $file_share_name, cache_attributes: $cache_attributes, notification_policy: $notification_policy, vpc_endpoint_dns_name: $vpc_endpoint_dns_name, bucket_region: $bucket_region, audit_destination_arn: $audit_destination_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Server Message Block (SMB) file share on an existing S3 File Gateway. In Storage Gateway, a file share is a file system mount point backed by Amazon S3 cloud storage. Storage Gateway exposes file shares using an SMB interface. This operation is only supported for S3 File Gateways. S3 File Gateways require Security Token Service (Amazon Web Services STS) to be activated to enable you to create a file share. Make sure that Amazon Web Services STS is activated in the Amazon Web Services Region you are creating your S3 File Gateway in. If Amazon Web Services STS is not activated in this Amazon Web Services Region, activate it. For information about how to activate Amazon Web Services STS, see Activating and deactivating Amazon Web Services STS in an Amazon Web Services Region (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html) in the Identity and Access Management User Guide. File gateways don't support creating hard or symbolic links on a file share.
#
# POST /
# Returns: record<FileShareARN: string>
# operationId: CreateSMBFileShare
export def "create-smb-file-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  client_token: string # A unique string value that you supply that is used by S3 File Gateway to ensure idempotent file share creation.
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  role: string # The ARN of the IAM role that an S3 File Gateway assumes when it accesses the underlying storage.
  location_arn: string # A custom ARN for the backend storage used for storing data for file shares. It includes a resource ARN with an optional prefix concatenation. The prefix must end with a forward slash (/). You can specify LocationARN as a bucket ARN, access point ARN or access point alias, as shown in the following examples. Bucket ARN: arn:aws:s3:::my-bucket/prefix/ Access point ARN: arn:aws:s3:region:account-id:accesspoint/access-point-name/prefix/ If you specify an access point, the bucket policy must be configured to delegate access control to the access point. For information, see Delegating access control to access points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points-policies.html#access-points-delegating-control) in the Amazon S3 User Guide. Access point alias: test-ap-ab123cdef4gehijklmn5opqrstuvuse1a-s3alias
  --default-storage-class: string
  --object-acl: string@object-acl-completer # A value that sets the access control list (ACL) permission for objects in the S3 bucket that an S3 File Gateway puts objects into. The default value is private.
  --read-only: oneof<nothing, bool> # A value that sets the write status of a file share. Set this value to true to set the write status to read-only, otherwise set to false. Valid Values: true | false
  --guess-mime-type-enabled: oneof<nothing, bool> # A value that enables guessing of the MIME type for uploaded objects based on file extensions. Set this value to true to enable MIME type guessing, otherwise set to false. The default value is true. Valid Values: true | false
  --requester-pays: oneof<nothing, bool> # A value that sets who pays the cost of the request and the cost associated with data download from the S3 bucket. If this value is set to true, the requester pays the costs; otherwise, the S3 bucket owner pays. However, the S3 bucket owner always pays the cost of storing data. RequesterPays is a configuration for the S3 bucket that backs the file share, so make sure that the configuration on the file share is the same as the S3 bucket configuration. Valid Values: true | false
  --smbacl-enabled: oneof<nothing, bool> # Set this value to true to enable access control list (ACL) on the SMB file share. Set it to false to map file and directory permissions to the POSIX permissions. For more information, see Using Microsoft Windows ACLs to control access to an SMB file share (https://docs.aws.amazon.com/storagegateway/latest/userguide/smb-acl.html) in the Storage Gateway User Guide. Valid Values: true | false
  --access-based-enumeration: oneof<nothing, bool> # The files and folders on this share will only be visible to users with read access.
  --admin-user-list: list<string> # A list of users or groups in the Active Directory that will be granted administrator privileges on the file share. These users can do all file operations as the super-user. Acceptable formats include: DOMAIN\User1, user1, @group1, and @DOMAIN\group1. Use this option very carefully, because any user in this list can do anything they like on the file share, regardless of file permissions.
  --valid-user-list: list<string> # A list of users or groups in the Active Directory that are allowed to access the file share. A group must be prefixed with the @ character. Acceptable formats include: DOMAIN\User1, user1, @group1, and @DOMAIN\group1. Can only be set if Authentication is set to ActiveDirectory.
  --invalid-user-list: list<string> # A list of users or groups in the Active Directory that are not allowed to access the file share. A group must be prefixed with the @ character. Acceptable formats include: DOMAIN\User1, user1, @group1, and @DOMAIN\group1. Can only be set if Authentication is set to ActiveDirectory.
  --audit-destination-arn: string # The Amazon Resource Name (ARN) of the storage used for audit logs.
  --authentication: string # The authentication method of the file share. The default is ActiveDirectory. Valid Values: ActiveDirectory | GuestAccess
  --case-sensitivity: string@case-sensitivity-completer # The case of an object name in an Amazon S3 bucket. For ClientSpecified, the client determines the case sensitivity. For CaseSensitive, the gateway determines the case sensitivity. The default value is ClientSpecified.
  --tags: list # A list of up to 50 tags that can be assigned to the NFS file share. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
  --file-share-name: string # The name of the file share. Optional. FileShareName must be set if an S3 prefix name is set in LocationARN, or if an access point or access point alias is used.
  --cache-attributes: record # The refresh cache information for the file share or FSx file systems. — shape: {CacheStaleTimeoutInSeconds?: int}
  --notification-policy: string # The notification policy of the file share. SettlingTimeInSeconds controls the number of seconds to wait after the last point in time a client wrote to a file before generating an ObjectUploaded notification. Because clients can make many small writes to files, it's best to set this parameter for as long as possible to avoid generating multiple notifications for the same file in a small time period. SettlingTimeInSeconds has no effect on the timing of the object uploading to Amazon S3, only the timing of the notification. The following example sets NotificationPolicy on with SettlingTimeInSeconds set to 60. {\"Upload\": {\"SettlingTimeInSeconds\": 60}} The following example sets NotificationPolicy off. {}
  --vpc-endpoint-dns-name: string # Specifies the DNS name for the VPC endpoint that the SMB file share uses to connect to Amazon S3. This parameter is required for SMB file shares that connect to Amazon S3 through a VPC endpoint, a VPC access point, or an access point alias that points to a VPC access point.
  --bucket-region: string # Specifies the Region of the S3 bucket where the SMB file share stores files. This parameter is required for SMB file shares that connect to Amazon S3 through a VPC endpoint, a VPC access point, or an access point alias that points to a VPC access point.
  --oplocks-enabled: oneof<nothing, bool> # Specifies whether opportunistic locking is enabled for the SMB file share. Enabling opportunistic locking on case-sensitive shares is not recommended for workloads that involve access to files with the same name in different case. Valid Values: true | false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateSMBFileShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientToken, var: client_token}, {name: GatewayARN, var: gateway_arn}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: Role, var: role}, {name: LocationARN, var: location_arn}, {name: DefaultStorageClass, var: default_storage_class}, {name: ObjectACL, var: object_acl}, {name: ReadOnly, var: read_only}, {name: GuessMIMETypeEnabled, var: guess_mime_type_enabled}, {name: RequesterPays, var: requester_pays}, {name: SMBACLEnabled, var: smbacl_enabled}, {name: AccessBasedEnumeration, var: access_based_enumeration}, {name: AdminUserList, var: admin_user_list}, {name: ValidUserList, var: valid_user_list}, {name: InvalidUserList, var: invalid_user_list}, {name: AuditDestinationARN, var: audit_destination_arn}, {name: Authentication, var: authentication}, {name: CaseSensitivity, var: case_sensitivity}, {name: Tags, var: tags}, {name: FileShareName, var: file_share_name}, {name: CacheAttributes, var: cache_attributes}, {name: NotificationPolicy, var: notification_policy}, {name: VPCEndpointDNSName, var: vpc_endpoint_dns_name}, {name: BucketRegion, var: bucket_region}, {name: OplocksEnabled, var: oplocks_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, gateway_arn: $gateway_arn, kms_encrypted: $kms_encrypted, kms_key: $kms_key, role: $role, location_arn: $location_arn, default_storage_class: $default_storage_class, object_acl: $object_acl, read_only: $read_only, guess_mime_type_enabled: $guess_mime_type_enabled, requester_pays: $requester_pays, smbacl_enabled: $smbacl_enabled, access_based_enumeration: $access_based_enumeration, admin_user_list: $admin_user_list, valid_user_list: $valid_user_list, invalid_user_list: $invalid_user_list, audit_destination_arn: $audit_destination_arn, authentication: $authentication, case_sensitivity: $case_sensitivity, tags: $tags, file_share_name: $file_share_name, cache_attributes: $cache_attributes, notification_policy: $notification_policy, vpc_endpoint_dns_name: $vpc_endpoint_dns_name, bucket_region: $bucket_region, oplocks_enabled: $oplocks_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a snapshot of a volume. Storage Gateway provides the ability to back up point-in-time snapshots of your data to Amazon Simple Storage (Amazon S3) for durable off-site recovery, and also import the data to an Amazon Elastic Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can take snapshots of your gateway volume on a scheduled or ad hoc basis. This API enables you to take an ad hoc snapshot. For more information, see Editing a snapshot schedule (https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-volumes.html#SchedulingSnapshot). In the CreateSnapshot request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide description for the snapshot. When Storage Gateway takes the snapshot of specified volume, the snapshot and description appears in the Storage Gateway console. In response, Storage Gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. This operation is only supported in stored and cached volume gateway type. To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSnapshots.html) or DeleteSnapshot (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DeleteSnapshot.html) in the Amazon Elastic Compute Cloud API Reference. Volume and snapshot IDs are changing to a longer length ID format. For more information, see the important note on the Welcome (https://docs.aws.amazon.com/storagegateway/latest/APIReference/Welcome.html) page.
#
# POST /
# Returns: record<VolumeARN: string, SnapshotId: string>
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  volume_arn: string # The Amazon Resource Name (ARN) of the volume. Use the ListVolumes operation to return a list of gateway volumes.
  snapshot_description: string # Textual description of the snapshot that appears in the Amazon EC2 console, Elastic Block Store snapshots panel in the Description field, and in the Storage Gateway snapshot Details pane, Description field.
  --tags: list # A list of up to 50 tags that can be assigned to a snapshot. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}, {name: SnapshotDescription, var: snapshot_description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn, snapshot_description: $snapshot_description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a snapshot of a gateway from a volume recovery point. This operation is only supported in the cached volume gateway type. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot. To get a list of volume recovery point for cached volume gateway, use ListVolumeRecoveryPoints. In the CreateSnapshotFromVolumeRecoveryPoint request, you identify the volume by providing its Amazon Resource Name (ARN). You must also provide a description for the snapshot. When the gateway takes a snapshot of the specified volume, the snapshot and its description appear in the Storage Gateway console. In response, the gateway returns you a snapshot ID. You can use this snapshot ID to check the snapshot progress or later use it when you want to create a volume from a snapshot. To list or delete a snapshot, you must use the Amazon EC2 API. For more information, see DescribeSnapshots (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSnapshots.html) or DeleteSnapshot (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DeleteSnapshot.html) in the Amazon Elastic Compute Cloud API Reference.
#
# POST /
# Returns: record<SnapshotId: string, VolumeARN: string, VolumeRecoveryPointTime: string>
# operationId: CreateSnapshotFromVolumeRecoveryPoint
export def "create-snapshot-from-volume-recovery-point" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_arn: string # The Amazon Resource Name (ARN) of the iSCSI volume target. Use the DescribeStorediSCSIVolumes operation to return to retrieve the TargetARN for specified VolumeARN.
  snapshot_description: string # Textual description of the snapshot that appears in the Amazon EC2 console, Elastic Block Store snapshots panel in the Description field, and in the Storage Gateway snapshot Details pane, Description field.
  --tags: list # A list of up to 50 tags that can be assigned to a snapshot. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateSnapshotFromVolumeRecoveryPoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}, {name: SnapshotDescription, var: snapshot_description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn, snapshot_description: $snapshot_description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a volume on a specified gateway. This operation is only supported in the stored volume gateway type. The size of the volume to create is inferred from the disk size. You can choose to preserve existing data on the disk, create volume from an existing snapshot, or create an empty volume. If you choose to create an empty gateway volume, then any existing data on the disk is erased. In the request, you must specify the gateway and the disk information on which you are creating the volume. In response, the gateway creates the volume and returns volume information such as the volume Amazon Resource Name (ARN), its size, and the iSCSI target ARN that initiators can use to connect to the volume target.
#
# POST /
# Returns: record<VolumeARN: string, VolumeSizeInBytes: int, TargetARN: string>
# operationId: CreateStorediSCSIVolume
export def "create-storedi-scsi-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  disk_id: string # The unique identifier for the gateway local disk that is configured as a stored volume. Use ListLocalDisks (https://docs.aws.amazon.com/storagegateway/latest/userguide/API_ListLocalDisks.html) to list disk IDs for a gateway.
  --snapshot-id: string # The snapshot ID (e.g., "snap-1122aabb") of the snapshot to restore as the new stored volume. Specify this field if you want to create the iSCSI storage volume from a snapshot; otherwise, do not include this field. To list snapshots for your account use DescribeSnapshots (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html) in the Amazon Elastic Compute Cloud API Reference.
  --preserve-existing-data: oneof<nothing, bool> # Set to true if you want to preserve the data on the local disk. Otherwise, set to false to create an empty volume. Valid Values: true | false
  target_name: string # The name of the iSCSI target used by an initiator to connect to a volume and used as a suffix for the target ARN. For example, specifying TargetName as myvolume results in the target ARN of arn:aws:storagegateway:us-east-2:111122223333:gateway/sgw-12A3456B/target/iqn.1997-05.com.amazon:myvolume. The target name must be unique across all volumes on a gateway. If you don't specify a value, Storage Gateway uses the value that was previously used for this volume as the new target name.
  network_interface_id: string # The network interface of the gateway on which to expose the iSCSI target. Only IPv4 addresses are accepted. Use DescribeGatewayInformation to get a list of the network interfaces available on a gateway. Valid Values: A valid IP address.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  --tags: list # A list of up to 50 tags that can be assigned to a stored volume. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateStorediSCSIVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: DiskId, var: disk_id}, {name: SnapshotId, var: snapshot_id}, {name: PreserveExistingData, var: preserve_existing_data, required: true}, {name: TargetName, var: target_name}, {name: NetworkInterfaceId, var: network_interface_id}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, disk_id: $disk_id, snapshot_id: $snapshot_id, preserve_existing_data: $preserve_existing_data, target_name: $target_name, network_interface_id: $network_interface_id, kms_encrypted: $kms_encrypted, kms_key: $kms_key, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new custom tape pool. You can use custom tape pool to enable tape retention lock on tapes that are archived in the custom pool.
#
# POST /
# Returns: record<PoolARN: string>
# operationId: CreateTapePool
export def "create-tape-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  pool_name: string # The name of the new custom tape pool.
  storage_class: string@storage-class-completer # The storage class that is associated with the new custom pool. When you use your backup application to eject the tape, the tape is archived directly into the storage class (S3 Glacier or S3 Glacier Deep Archive) that corresponds to the pool.
  --retention-lock-type: string@retention-lock-type-completer # Tape retention lock can be configured in two modes. When configured in governance mode, Amazon Web Services accounts with specific IAM permissions are authorized to remove the tape retention lock from archived virtual tapes. When configured in compliance mode, the tape retention lock cannot be removed by any user, including the root Amazon Web Services account.
  --retention-lock-time-in-days: int # Tape retention lock time is set in days. Tape retention lock can be enabled for up to 100 years (36,500 days).
  --tags: list # A list of up to 50 tags that can be assigned to tape pool. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateTapePool"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PoolName, var: pool_name}, {name: StorageClass, var: storage_class}, {name: RetentionLockType, var: retention_lock_type}, {name: RetentionLockTimeInDays, var: retention_lock_time_in_days}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pool_name: $pool_name, storage_class: $storage_class, retention_lock_type: $retention_lock_type, retention_lock_time_in_days: $retention_lock_time_in_days, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a virtual tape by using your own barcode. You write data to the virtual tape and then archive the tape. A barcode is unique and cannot be reused if it has already been used on a tape. This applies to barcodes used on deleted tapes. This operation is only supported in the tape gateway type. Cache storage must be allocated to the gateway before you can create a virtual tape. Use the AddCache operation to add cache storage to a gateway.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: CreateTapeWithBarcode
export def "create-tape-with-barcode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  tape_size_in_bytes: int # The size, in bytes, of the virtual tape that you want to create. The size must be aligned by gigabyte (1024*1024*1024 bytes).
  tape_barcode: string # The barcode that you want to assign to the tape. Barcodes cannot be reused. This includes barcodes used for tapes that have been deleted.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  --pool-id: string # The ID of the pool that you want to add your tape to for archiving. The tape in this pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the storage class (S3 Glacier or S3 Deep Archive) that corresponds to the pool.
  --worm: oneof<nothing, bool> # Set to TRUE if the tape you are creating is to be configured as a write-once-read-many (WORM) tape.
  --tags: list # A list of up to 50 tags that can be assigned to a virtual tape that has a barcode. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateTapeWithBarcode"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: TapeSizeInBytes, var: tape_size_in_bytes}, {name: TapeBarcode, var: tape_barcode}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: PoolId, var: pool_id}, {name: Worm, var: worm}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, tape_size_in_bytes: $tape_size_in_bytes, tape_barcode: $tape_barcode, kms_encrypted: $kms_encrypted, kms_key: $kms_key, pool_id: $pool_id, worm: $worm, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more virtual tapes. You write data to the virtual tapes and then archive the tapes. This operation is only supported in the tape gateway type. Cache storage must be allocated to the gateway before you can create virtual tapes. Use the AddCache operation to add cache storage to a gateway.
#
# POST /
# Returns: record<TapeARNs: list<string>>
# operationId: CreateTapes
export def "create-tapes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  tape_size_in_bytes: int # The size, in bytes, of the virtual tapes that you want to create. The size must be aligned by gigabyte (1024*1024*1024 bytes).
  client_token: string # A unique identifier that you use to retry a request. If you retry a request, use the same ClientToken you specified in the initial request. Using the same ClientToken prevents creating the tape multiple times.
  num_tapes_to_create: int # The number of virtual tapes that you want to create.
  tape_barcode_prefix: string # A prefix that you append to the barcode of the virtual tape you are creating. This prefix makes the barcode unique. The prefix must be 1-4 characters in length and must be one of the uppercase letters from A to Z.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  --pool-id: string # The ID of the pool that you want to add your tape to for archiving. The tape in this pool is archived in the S3 storage class that is associated with the pool. When you use your backup application to eject the tape, the tape is archived directly into the storage class (S3 Glacier or S3 Glacier Deep Archive) that corresponds to the pool.
  --worm: oneof<nothing, bool> # Set to TRUE if the tape you are creating is to be configured as a write-once-read-many (WORM) tape.
  --tags: list # A list of up to 50 tags that can be assigned to a virtual tape. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.CreateTapes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: TapeSizeInBytes, var: tape_size_in_bytes}, {name: ClientToken, var: client_token}, {name: NumTapesToCreate, var: num_tapes_to_create}, {name: TapeBarcodePrefix, var: tape_barcode_prefix}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: PoolId, var: pool_id}, {name: Worm, var: worm}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, tape_size_in_bytes: $tape_size_in_bytes, client_token: $client_token, num_tapes_to_create: $num_tapes_to_create, tape_barcode_prefix: $tape_barcode_prefix, kms_encrypted: $kms_encrypted, kms_key: $kms_key, pool_id: $pool_id, worm: $worm, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the automatic tape creation policy of a gateway. If you delete this policy, new virtual tapes must be created manually. Use the Amazon Resource Name (ARN) of the gateway in your request to remove the policy.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: DeleteAutomaticTapeCreationPolicy
export def "delete-automatic-tape-creation-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteAutomaticTapeCreationPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the bandwidth rate limits of a gateway. You can delete either the upload and download bandwidth rate limit, or you can delete both. If you delete only one of the limits, the other limit remains unchanged. To specify which gateway to work with, use the Amazon Resource Name (ARN) of the gateway in your request. This operation is supported only for the stored volume, cached volume, and tape gateway types.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: DeleteBandwidthRateLimit
export def "delete-bandwidth-rate-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  bandwidth_type: string # One of the BandwidthType values that indicates the gateway bandwidth rate limit to delete. Valid Values: UPLOAD | DOWNLOAD | ALL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteBandwidthRateLimit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: BandwidthType, var: bandwidth_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, bandwidth_type: $bandwidth_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target and initiator pair. This operation is supported in volume and tape gateway types.
#
# POST /
# Returns: record<TargetARN: string, InitiatorName: string>
# operationId: DeleteChapCredentials
export def "delete-chap-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  target_arn: string # The Amazon Resource Name (ARN) of the iSCSI volume target. Use the DescribeStorediSCSIVolumes operation to return to retrieve the TargetARN for specified VolumeARN.
  initiator_name: string # The iSCSI initiator that connects to the target.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteChapCredentials"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetARN, var: target_arn}, {name: InitiatorName, var: initiator_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, target_arn: $target_arn, initiator_name: $initiator_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a file share from an S3 File Gateway. This operation is only supported for S3 File Gateways.
#
# POST /
# Returns: record<FileShareARN: string>
# operationId: DeleteFileShare
export def "delete-file-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_share_arn: string # The Amazon Resource Name (ARN) of the file share.
  --force-delete: oneof<nothing, bool> # If this value is set to true, the operation deletes a file share immediately and aborts all data uploads to Amazon Web Services. Otherwise, the file share is not deleted until all data is uploaded to Amazon Web Services. This process aborts the data upload process, and the file share enters the FORCE_DELETING status. Valid Values: true | false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteFileShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileShareARN, var: file_share_arn}, {name: ForceDelete, var: force_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_share_arn: $file_share_arn, force_delete: $force_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a gateway. To specify which gateway to delete, use the Amazon Resource Name (ARN) of the gateway in your request. The operation deletes the gateway; however, it does not delete the gateway virtual machine (VM) from your host computer. After you delete a gateway, you cannot reactivate it. Completed snapshots of the gateway volumes are not deleted upon deleting the gateway, however, pending snapshots will not complete. After you delete a gateway, your next step is to remove it from your environment. You no longer pay software charges after the gateway is deleted; however, your existing Amazon EBS snapshots persist and you will continue to be billed for these snapshots. You can choose to remove all remaining Amazon EBS snapshots by canceling your Amazon EC2 subscription. If you prefer not to cancel your Amazon EC2 subscription, you can delete your snapshots using the Amazon EC2 console. For more information, see the Storage Gateway detail page (http://aws.amazon.com/storagegateway).
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: DeleteGateway
export def "delete-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a snapshot of a volume. You can take snapshots of your gateway volumes on a scheduled or ad hoc basis. This API action enables you to delete a snapshot schedule for a volume. For more information, see Backing up your volumes (https://docs.aws.amazon.com/storagegateway/latest/userguide/backing-up-volumes.html). In the DeleteSnapshotSchedule request, you identify the volume by providing its Amazon Resource Name (ARN). This operation is only supported for cached volume gateway types. To list or delete a snapshot, you must use the Amazon EC2 API. For more information, go to DescribeSnapshots (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSnapshots.html) in the Amazon Elastic Compute Cloud API Reference.
#
# POST /
# Returns: record<VolumeARN: string>
# operationId: DeleteSnapshotSchedule
export def "delete-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_arn: string # The volume which snapshot schedule to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteSnapshotSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified virtual tape. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: DeleteTape
export def "delete-tape" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  tape_arn: string # The Amazon Resource Name (ARN) of the virtual tape to delete.
  --bypass-governance-retention: oneof<nothing, bool> # Set to TRUE to delete an archived tape that belongs to a custom pool with tape retention lock. Only archived tapes with tape retention lock set to governance can be deleted. Archived tapes with tape retention lock set to compliance can't be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteTape"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: TapeARN, var: tape_arn}, {name: BypassGovernanceRetention, var: bypass_governance_retention}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, tape_arn: $tape_arn, bypass_governance_retention: $bypass_governance_retention
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified virtual tape from the virtual tape shelf (VTS). This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: DeleteTapeArchive
export def "delete-tape-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  tape_arn: string # The Amazon Resource Name (ARN) of the virtual tape to delete from the virtual tape shelf (VTS).
  --bypass-governance-retention: oneof<nothing, bool> # Set to TRUE to delete an archived tape that belongs to a custom pool with tape retention lock. Only archived tapes with tape retention lock set to governance can be deleted. Archived tapes with tape retention lock set to compliance can't be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteTapeArchive"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TapeARN, var: tape_arn}, {name: BypassGovernanceRetention, var: bypass_governance_retention}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tape_arn: $tape_arn, bypass_governance_retention: $bypass_governance_retention
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a custom tape pool. A custom tape pool can only be deleted if there are no tapes in the pool and if there are no automatic tape creation policies that reference the custom tape pool.
#
# POST /
# Returns: record<PoolARN: string>
# operationId: DeleteTapePool
export def "delete-tape-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  pool_arn: string # The Amazon Resource Name (ARN) of the custom tape pool to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteTapePool"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PoolARN, var: pool_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pool_arn: $pool_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified storage volume that you previously created using the CreateCachediSCSIVolume or CreateStorediSCSIVolume API. This operation is only supported in the cached volume and stored volume types. For stored volume gateways, the local disk that was configured as the storage volume is not deleted. You can reuse the local disk to create another storage volume. Before you delete a volume, make sure there are no iSCSI connections to the volume you are deleting. You should also make sure there is no snapshot in progress. You can use the Amazon Elastic Compute Cloud (Amazon EC2) API to query snapshots on the volume you are deleting and check the snapshot status. For more information, go to DescribeSnapshots (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSnapshots.html) in the Amazon Elastic Compute Cloud API Reference. In the request, you must provide the Amazon Resource Name (ARN) of the storage volume you want to delete.
#
# POST /
# Returns: record<VolumeARN: string>
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  volume_arn: string # The Amazon Resource Name (ARN) of the volume. Use the ListVolumes operation to return a list of gateway volumes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DeleteVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the most recent high availability monitoring test that was performed on the host in a cluster. If a test isn't performed, the status and start time in the response would be null.
#
# POST /
# Returns: record<GatewayARN: string, Status: string, StartTime: string>
# operationId: DescribeAvailabilityMonitorTest
export def "describe-availability-monitor-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeAvailabilityMonitorTest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the bandwidth rate limits of a gateway. By default, these limits are not set, which means no bandwidth rate limiting is in effect. This operation is supported only for the stored volume, cached volume, and tape gateway types. To describe bandwidth rate limits for S3 file gateways, use DescribeBandwidthRateLimitSchedule. This operation returns a value for a bandwidth rate limit only if the limit is set. If no limits are set for the gateway, then this operation returns only the gateway ARN in the response body. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
#
# POST /
# Returns: record<GatewayARN: string, AverageUploadRateLimitInBitsPerSec: int, AverageDownloadRateLimitInBitsPerSec: int>
# operationId: DescribeBandwidthRateLimit
export def "describe-bandwidth-rate-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeBandwidthRateLimit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the bandwidth rate limit schedule of a gateway. By default, gateways do not have bandwidth rate limit schedules, which means no bandwidth rate limiting is in effect. This operation is supported only for volume, tape and S3 file gateways. FSx file gateways do not support bandwidth rate limits. This operation returns information about a gateway's bandwidth rate limit schedule. A bandwidth rate limit schedule consists of one or more bandwidth rate limit intervals. A bandwidth rate limit interval defines a period of time on one or more days of the week, during which bandwidth rate limits are specified for uploading, downloading, or both. A bandwidth rate limit interval consists of one or more days of the week, a start hour and minute, an ending hour and minute, and bandwidth rate limits for uploading and downloading If no bandwidth rate limit schedule intervals are set for the gateway, this operation returns an empty response. To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
#
# POST /
# Returns: record<GatewayARN: string, BandwidthRateLimitIntervals: table<StartHourOfDay: int, StartMinuteOfHour: int, EndHourOfDay: int, EndMinuteOfHour: int, DaysOfWeek: list, AverageUploadRateLimitInBitsPerSec: int, AverageDownloadRateLimitInBitsPerSec: int>>
# operationId: DescribeBandwidthRateLimitSchedule
export def "describe-bandwidth-rate-limit-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeBandwidthRateLimitSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the cache of a gateway. This operation is only supported in the cached volume, tape, and file gateway types. The response includes disk IDs that are configured as cache, and it includes the amount of cache allocated and used.
#
# POST /
# Returns: record<GatewayARN: string, DiskIds: list<string>, CacheAllocatedInBytes: int, CacheUsedPercentage: float, CacheDirtyPercentage: float, CacheHitPercentage: float, CacheMissPercentage: float>
# operationId: DescribeCache
export def "describe-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a description of the gateway volumes specified in the request. This operation is only supported in the cached volume gateway types. The list of gateway volumes in the request must be from one gateway. In the response, Storage Gateway returns volume information sorted by volume Amazon Resource Name (ARN).
#
# POST /
# Returns: record<CachediSCSIVolumes: table<VolumeARN: string, VolumeId: string, VolumeType: string, VolumeStatus: string, VolumeAttachmentStatus: string, VolumeSizeInBytes: int, VolumeProgress: float, SourceSnapshotId: string, VolumeiSCSIAttributes: record, CreatedDate: string, VolumeUsedInBytes: int, KMSKey: string, TargetName: string>>
# operationId: DescribeCachediSCSIVolumes
export def "describe-cachedi-scsi-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_ar_ns: list<string> # An array of strings where each string represents the Amazon Resource Name (ARN) of a cached volume. All of the specified cached volumes must be from the same gateway. Use ListVolumes to get volume ARNs for a gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeCachediSCSIVolumes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARNs, var: volume_ar_ns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_ar_ns: $volume_ar_ns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of Challenge-Handshake Authentication Protocol (CHAP) credentials information for a specified iSCSI target, one for each target-initiator pair. This operation is supported in the volume and tape gateway types.
#
# POST /
# Returns: record<ChapCredentials: table<TargetARN: string, SecretToAuthenticateInitiator: string, InitiatorName: string, SecretToAuthenticateTarget: string>>
# operationId: DescribeChapCredentials
export def "describe-chap-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  target_arn: string # The Amazon Resource Name (ARN) of the iSCSI volume target. Use the DescribeStorediSCSIVolumes operation to return to retrieve the TargetARN for specified VolumeARN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeChapCredentials"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetARN, var: target_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, target_arn: $target_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the file system association information. This operation is only supported for FSx File Gateways.
#
# POST /
# Returns: record<FileSystemAssociationInfoList: table<FileSystemAssociationARN: string, LocationARN: string, FileSystemAssociationStatus: string, AuditDestinationARN: string, GatewayARN: string, Tags: list, CacheAttributes: record, EndpointNetworkConfiguration: record, FileSystemAssociationStatusDetails: list>>
# operationId: DescribeFileSystemAssociations
export def "describe-file-system-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_system_association_arn_list: list<string> # An array containing the Amazon Resource Name (ARN) of each file system association to be described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeFileSystemAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemAssociationARNList, var: file_system_association_arn_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_association_arn_list: $file_system_association_arn_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about a gateway such as its name, network interfaces, configured time zone, and the state (whether the gateway is running or not). To specify which gateway to describe, use the Amazon Resource Name (ARN) of the gateway in your request.
#
# POST /
# Returns: record<GatewayARN: string, GatewayId: string, GatewayName: string, GatewayTimezone: string, GatewayState: string, GatewayNetworkInterfaces: table<Ipv4Address: string, MacAddress: string, Ipv6Address: string>, GatewayType: string, NextUpdateAvailabilityDate: string, LastSoftwareUpdate: string, Ec2InstanceId: string, Ec2InstanceRegion: string, Tags: table<Key: string, Value: string>, VPCEndpoint: string, CloudWatchLogGroupARN: string, HostEnvironment: string, EndpointType: string, SoftwareUpdatesEndDate: string, DeprecationDate: string, GatewayCapacity: string, SupportedGatewayCapacities: list<string>, HostEnvironmentId: string>
# operationId: DescribeGatewayInformation
export def "describe-gateway-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeGatewayInformation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns your gateway's weekly maintenance start time including the day and time of the week. Note that values are in terms of the gateway's time zone.
#
# POST /
# Returns: record<GatewayARN: string, HourOfDay: int, MinuteOfHour: int, DayOfWeek: int, DayOfMonth: int, Timezone: string>
# operationId: DescribeMaintenanceStartTime
export def "describe-maintenance-start-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeMaintenanceStartTime"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a description for one or more Network File System (NFS) file shares from an S3 File Gateway. This operation is only supported for S3 File Gateways.
#
# POST /
# Returns: record<NFSFileShareInfoList: table<NFSFileShareDefaults: record, FileShareARN: string, FileShareId: string, FileShareStatus: string, GatewayARN: string, KMSEncrypted: bool, KMSKey: string, Path: string, Role: string, LocationARN: string, DefaultStorageClass: string, ObjectACL: string, ClientList: list, Squash: string, ReadOnly: bool, GuessMIMETypeEnabled: bool, RequesterPays: bool, Tags: list, FileShareName: string, CacheAttributes: record, NotificationPolicy: string, VPCEndpointDNSName: string, BucketRegion: string, AuditDestinationARN: string>>
# operationId: DescribeNFSFileShares
export def "describe-nfs-file-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_share_arn_list: list<string> # An array containing the Amazon Resource Name (ARN) of each file share to be described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeNFSFileShares"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileShareARNList, var: file_share_arn_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_share_arn_list: $file_share_arn_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a description for one or more Server Message Block (SMB) file shares from a S3 File Gateway. This operation is only supported for S3 File Gateways.
#
# POST /
# Returns: record<SMBFileShareInfoList: table<FileShareARN: string, FileShareId: string, FileShareStatus: string, GatewayARN: string, KMSEncrypted: bool, KMSKey: string, Path: string, Role: string, LocationARN: string, DefaultStorageClass: string, ObjectACL: string, ReadOnly: bool, GuessMIMETypeEnabled: bool, RequesterPays: bool, SMBACLEnabled: bool, AccessBasedEnumeration: bool, AdminUserList: list, ValidUserList: list, InvalidUserList: list, AuditDestinationARN: string, Authentication: string, CaseSensitivity: string, Tags: list, FileShareName: string, CacheAttributes: record, NotificationPolicy: string, VPCEndpointDNSName: string, BucketRegion: string, OplocksEnabled: bool>>
# operationId: DescribeSMBFileShares
export def "describe-smb-file-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_share_arn_list: list<string> # An array containing the Amazon Resource Name (ARN) of each file share to be described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeSMBFileShares"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileShareARNList, var: file_share_arn_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_share_arn_list: $file_share_arn_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a description of a Server Message Block (SMB) file share settings from a file gateway. This operation is only supported for file gateways.
#
# POST /
# Returns: record<GatewayARN: string, DomainName: string, ActiveDirectoryStatus: string, SMBGuestPasswordSet: bool, SMBSecurityStrategy: string, FileSharesVisible: bool, SMBLocalGroups: record<GatewayAdmins: list<string>>>
# operationId: DescribeSMBSettings
export def "describe-smb-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeSMBSettings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the snapshot schedule for the specified gateway volume. The snapshot schedule information includes intervals at which snapshots are automatically initiated on the volume. This operation is only supported in the cached volume and stored volume types.
#
# POST /
# Returns: record<VolumeARN: string, StartAt: int, RecurrenceInHours: int, Description: string, Timezone: string, Tags: table<Key: string, Value: string>>
# operationId: DescribeSnapshotSchedule
export def "describe-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_arn: string # The Amazon Resource Name (ARN) of the volume. Use the ListVolumes operation to return a list of gateway volumes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeSnapshotSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the description of the gateway volumes specified in the request. The list of gateway volumes in the request must be from one gateway. In the response, Storage Gateway returns volume information sorted by volume ARNs. This operation is only supported in stored volume gateway type.
#
# POST /
# Returns: record<StorediSCSIVolumes: table<VolumeARN: string, VolumeId: string, VolumeType: string, VolumeStatus: string, VolumeAttachmentStatus: string, VolumeSizeInBytes: int, VolumeProgress: float, VolumeDiskId: string, SourceSnapshotId: string, PreservedExistingData: bool, VolumeiSCSIAttributes: record, CreatedDate: string, VolumeUsedInBytes: int, KMSKey: string, TargetName: string>>
# operationId: DescribeStorediSCSIVolumes
export def "describe-storedi-scsi-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_ar_ns: list<string> # An array of strings where each string represents the Amazon Resource Name (ARN) of a stored volume. All of the specified stored volumes must be from the same gateway. Use ListVolumes to get volume ARNs for a gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeStorediSCSIVolumes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARNs, var: volume_ar_ns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_ar_ns: $volume_ar_ns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a description of specified virtual tapes in the virtual tape shelf (VTS). This operation is only supported in the tape gateway type. If a specific TapeARN is not specified, Storage Gateway returns a description of all virtual tapes found in the VTS associated with your account.
#
# POST /
# Returns: record<TapeArchives: table<TapeARN: string, TapeBarcode: string, TapeCreatedDate: string, TapeSizeInBytes: int, CompletionTime: string, RetrievedTo: string, TapeStatus: string, TapeUsedInBytes: int, KMSKey: string, PoolId: string, Worm: bool, RetentionStartDate: string, PoolEntryDate: string>, Marker: string>
# operationId: DescribeTapeArchives
export def "describe-tape-archives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  --tape-ar-ns: list<string> # The Amazon Resource Name (ARN) of each of the tapes you want to list. If you don't specify a tape ARN, the response lists all tapes in both your VTL and VTS.
  --body-marker: string # An opaque string that indicates the position at which to begin describing virtual tapes. (spec name: Marker)
  --body-limit: int # Specifies that the number of virtual tapes described be limited to the specified number. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeTapeArchives"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TapeARNs, var: tape_ar_ns}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tape_ar_ns: $tape_ar_ns, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of virtual tape recovery points that are available for the specified tape gateway. A recovery point is a point-in-time view of a virtual tape at which all the data on the virtual tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<GatewayARN: string, TapeRecoveryPointInfos: table<TapeARN: string, TapeRecoveryPointTime: string, TapeSizeInBytes: int, TapeStatus: string>, Marker: string>
# operationId: DescribeTapeRecoveryPoints
export def "describe-tape-recovery-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --body-marker: string # An opaque string that indicates the position at which to begin describing the virtual tape recovery points. (spec name: Marker)
  --body-limit: int # Specifies that the number of virtual tape recovery points that are described be limited to the specified number. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeTapeRecoveryPoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a description of the specified Amazon Resource Name (ARN) of virtual tapes. If a TapeARN is not specified, returns a description of all virtual tapes associated with the specified gateway. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<Tapes: table<TapeARN: string, TapeBarcode: string, TapeCreatedDate: string, TapeSizeInBytes: int, TapeStatus: string, VTLDevice: string, Progress: float, TapeUsedInBytes: int, KMSKey: string, PoolId: string, Worm: bool, RetentionStartDate: string, PoolEntryDate: string>, Marker: string>
# operationId: DescribeTapes
export def "describe-tapes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --tape-ar-ns: list<string> # The Amazon Resource Name (ARN) of each of the tapes you want to list. If you don't specify a tape ARN, the response lists all tapes in both your VTL and VTS.
  --body-marker: string # A marker value, obtained in a previous call to DescribeTapes. This marker indicates which page of results to retrieve. If not specified, the first page of results is retrieved. (spec name: Marker)
  --body-limit: int # Specifies that the number of virtual tapes described be limited to the specified number. Amazon Web Services may impose its own limit, if this field is not set. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeTapes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: TapeARNs, var: tape_ar_ns}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, tape_ar_ns: $tape_ar_ns, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the upload buffer of a gateway. This operation is supported for the stored volume, cached volume, and tape gateway types. The response includes disk IDs that are configured as upload buffer space, and it includes the amount of upload buffer space allocated and used.
#
# POST /
# Returns: record<GatewayARN: string, DiskIds: list<string>, UploadBufferUsedInBytes: int, UploadBufferAllocatedInBytes: int>
# operationId: DescribeUploadBuffer
export def "describe-upload-buffer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeUploadBuffer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a description of virtual tape library (VTL) devices for the specified tape gateway. In the response, Storage Gateway returns VTL device information. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<GatewayARN: string, VTLDevices: table<VTLDeviceARN: string, VTLDeviceType: string, VTLDeviceVendor: string, VTLDeviceProductIdentifier: string, DeviceiSCSIAttributes: record>, Marker: string>
# operationId: DescribeVTLDevices
export def "describe-vtl-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --vtl-device-ar-ns: list<string> # An array of strings, where each string represents the Amazon Resource Name (ARN) of a VTL device. All of the specified VTL devices must be from the same gateway. If no VTL devices are specified, the result will contain all devices on the specified gateway.
  --body-marker: string # An opaque string that indicates the position at which to begin describing the VTL devices. (spec name: Marker)
  --body-limit: int # Specifies that the number of VTL devices described be limited to the specified number. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeVTLDevices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: VTLDeviceARNs, var: vtl_device_ar_ns}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, vtl_device_ar_ns: $vtl_device_ar_ns, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the working storage of a gateway. This operation is only supported in the stored volumes gateway type. This operation is deprecated in cached volumes API version (20120630). Use DescribeUploadBuffer instead. Working storage is also referred to as upload buffer. You can also use the DescribeUploadBuffer operation to add upload buffer to a stored volume gateway. The response includes disk IDs that are configured as working storage, and it includes the amount of working storage allocated and used.
#
# POST /
# Returns: record<GatewayARN: string, DiskIds: list<string>, WorkingStorageUsedInBytes: int, WorkingStorageAllocatedInBytes: int>
# operationId: DescribeWorkingStorage
export def "describe-working-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DescribeWorkingStorage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnects a volume from an iSCSI connection and then detaches the volume from the specified gateway. Detaching and attaching a volume enables you to recover your data from one gateway to a different gateway without creating a snapshot. It also makes it easier to move your volumes from an on-premises gateway to a gateway hosted on an Amazon EC2 instance. This operation is only supported in the volume gateway type.
#
# POST /
# Returns: record<VolumeARN: string>
# operationId: DetachVolume
export def "detach-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49 # required
  volume_arn: string # The Amazon Resource Name (ARN) of the volume to detach from the gateway.
  --force-detach: oneof<nothing, bool> # Set to true to forcibly remove the iSCSI connection of the target volume and detach the volume. The default is false. If this value is set to false, you must manually disconnect the iSCSI connection from the target volume. Valid Values: true | false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DetachVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}, {name: ForceDetach, var: force_detach}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn, force_detach: $force_detach
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables a tape gateway when the gateway is no longer functioning. For example, if your gateway VM is damaged, you can disable the gateway so you can recover virtual tapes. Use this operation for a tape gateway that is not reachable or not functioning. This operation is only supported in the tape gateway type. After a gateway is disabled, it cannot be enabled.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: DisableGateway
export def "disable-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DisableGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates an Amazon FSx file system from the specified gateway. After the disassociation process finishes, the gateway can no longer access the Amazon FSx file system. This operation is only supported in the FSx File Gateway type.
#
# POST /
# Returns: record<FileSystemAssociationARN: string>
# operationId: DisassociateFileSystem
export def "disassociate-file-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51 # required
  file_system_association_arn: string # The Amazon Resource Name (ARN) of the file system association to be deleted.
  --force-delete: oneof<nothing, bool> # If this value is set to true, the operation disassociates an Amazon FSx file system immediately. It ends all data uploads to the file system, and the file system association enters the FORCE_DELETING status. If this value is set to false, the Amazon FSx file system does not disassociate until all data is uploaded.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.DisassociateFileSystem"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemAssociationARN, var: file_system_association_arn}, {name: ForceDelete, var: force_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_association_arn: $file_system_association_arn, force_delete: $force_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a file gateway to an Active Directory domain. This operation is only supported for file gateways that support the SMB file protocol.
#
# POST /
# Returns: record<GatewayARN: string, ActiveDirectoryStatus: string>
# operationId: JoinDomain
export def "join-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  domain_name: string # The name of the domain that you want the gateway to join.
  --organizational-unit: string # The organizational unit (OU) is a container in an Active Directory that can hold users, groups, computers, and other OUs and this parameter specifies the OU that the gateway will join within the AD domain.
  --domain-controllers: list<string> # List of IPv4 addresses, NetBIOS names, or host names of your domain server. If you need to specify the port number include it after the colon (“:”). For example, mydc.mydomain.com:389.
  --timeout-in-seconds: int # Specifies the time in seconds, in which the JoinDomain operation must complete. The default is 20 seconds.
  user_name: string # Sets the user name of user who has permission to add the gateway to the Active Directory domain. The domain user account should be enabled to join computers to the domain. For example, you can use the domain administrator account or an account with delegated permissions to join computers to the domain.
  password: string # Sets the password of the user who has permission to add the gateway to the Active Directory domain. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.JoinDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: DomainName, var: domain_name}, {name: OrganizationalUnit, var: organizational_unit}, {name: DomainControllers, var: domain_controllers}, {name: TimeoutInSeconds, var: timeout_in_seconds}, {name: UserName, var: user_name}, {name: Password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, domain_name: $domain_name, organizational_unit: $organizational_unit, domain_controllers: $domain_controllers, timeout_in_seconds: $timeout_in_seconds, user_name: $user_name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the automatic tape creation policies for a gateway. If there are no automatic tape creation policies for the gateway, it returns an empty list. This operation is only supported for tape gateways.
#
# POST /
# Returns: record<AutomaticTapeCreationPolicyInfos: table<AutomaticTapeCreationRules: list, GatewayARN: string>>
# operationId: ListAutomaticTapeCreationPolicies
export def "list-automatic-tape-creation-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53 # required
  --gateway-arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListAutomaticTapeCreationPolicies"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the file shares for a specific S3 File Gateway, or the list of file shares that belong to the calling user account. This operation is only supported for S3 File Gateways.
#
# POST /
# Returns: record<Marker: string, NextMarker: string, FileShareInfoList: table<FileShareType: string, FileShareARN: string, FileShareId: string, FileShareStatus: string, GatewayARN: string>>
# operationId: ListFileShares
export def "list-file-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54 # required
  --gateway-arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --body-limit: int # The maximum number of file shares to return in the response. The value must be an integer with a value greater than zero. Optional. (spec name: Limit)
  --body-marker: string # Opaque pagination token returned from a previous ListFileShares operation. If present, Marker specifies where to continue the list from after a previous call to ListFileShares. Optional. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListFileShares"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: Limit, var: body_limit}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, body_limit: $body_limit, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of FileSystemAssociationSummary objects. Each object contains a summary of a file system association. This operation is only supported for FSx File Gateways.
#
# POST /
# Returns: record<Marker: string, NextMarker: string, FileSystemAssociationSummaryList: table<FileSystemAssociationId: string, FileSystemAssociationARN: string, FileSystemAssociationStatus: string, GatewayARN: string>>
# operationId: ListFileSystemAssociations
export def "list-file-system-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55 # required
  --gateway-arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --body-limit: int # The maximum number of file system associations to return in the response. If present, Limit must be an integer with a value greater than zero. Optional. (spec name: Limit)
  --body-marker: string # Opaque pagination token returned from a previous ListFileSystemAssociations operation. If present, Marker specifies where to continue the list from after a previous call to ListFileSystemAssociations. Optional. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListFileSystemAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: Limit, var: body_limit}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, body_limit: $body_limit, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists gateways owned by an Amazon Web Services account in an Amazon Web Services Region specified in the request. The returned list is ordered by gateway Amazon Resource Name (ARN). By default, the operation returns a maximum of 100 gateways. This operation supports pagination that allows you to optionally reduce the number of gateways returned in a response. If you have more gateways than are returned in a response (that is, the response returns only a truncated list of your gateways), the response contains a marker that you can specify in your next request to fetch the next page of gateways.
#
# POST /
# Returns: record<Gateways: table<GatewayId: string, GatewayARN: string, GatewayType: string, GatewayOperationalState: string, GatewayName: string, Ec2InstanceId: string, Ec2InstanceRegion: string, HostEnvironment: string, HostEnvironmentId: string>, Marker: string>
# operationId: ListGateways
export def "list-gateways" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56 # required
  --body-marker: string # An opaque string that indicates the position at which to begin the returned list of gateways. (spec name: Marker)
  --body-limit: int # Specifies that the list of gateways returned be limited to the specified number of items. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListGateways"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the gateway's local disks. To specify which gateway to describe, you use the Amazon Resource Name (ARN) of the gateway in the body of the request. The request returns a list of all disks, specifying which are configured as working storage, cache storage, or stored volume or not configured at all. The response includes a DiskStatus field. This field can have a value of present (the disk is available to use), missing (the disk is no longer connected to the gateway), or mismatch (the disk node is occupied by a disk that has incorrect metadata or the disk content is corrupted).
#
# POST /
# Returns: record<GatewayARN: string, Disks: table<DiskId: string, DiskPath: string, DiskNode: string, DiskStatus: string, DiskSizeInBytes: int, DiskAllocationType: string, DiskAllocationResource: string, DiskAttributeList: list>>
# operationId: ListLocalDisks
export def "list-local-disks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListLocalDisks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags that have been added to the specified resource. This operation is supported in storage gateways of all types.
#
# POST /
# Returns: record<ResourceARN: string, Marker: string, Tags: table<Key: string, Value: string>>
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
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource for which you want to list tags.
  --body-marker: string # An opaque string that indicates the position at which to begin returning the list of tags. (spec name: Marker)
  --body-limit: int # Specifies that the list of tags returned be limited to the specified number of items. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists custom tape pools. You specify custom tape pools to list by specifying one or more custom tape pool Amazon Resource Names (ARNs). If you don't specify a custom tape pool ARN, the operation lists all custom tape pools. This operation supports pagination. You can optionally specify the Limit parameter in the body to limit the number of tape pools in the response. If the number of tape pools returned in the response is truncated, the response includes a Marker element that you can use in your subsequent request to retrieve the next set of tape pools.
#
# POST /
# Returns: record<PoolInfos: table<PoolARN: string, PoolName: string, StorageClass: string, RetentionLockType: string, RetentionLockTimeInDays: int, PoolStatus: string>, Marker: string>
# operationId: ListTapePools
export def "list-tape-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-59 # required
  --pool-ar-ns: list<string> # The Amazon Resource Name (ARN) of each of the custom tape pools you want to list. If you don't specify a custom tape pool ARN, the response lists all custom tape pools.
  --body-marker: string # A string that indicates the position at which to begin the returned list of tape pools. (spec name: Marker)
  --body-limit: int # An optional number limit for the tape pools in the list returned by this call. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListTapePools"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PoolARNs, var: pool_ar_ns}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, pool_ar_ns: $pool_ar_ns, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists virtual tapes in your virtual tape library (VTL) and your virtual tape shelf (VTS). You specify the tapes to list by specifying one or more tape Amazon Resource Names (ARNs). If you don't specify a tape ARN, the operation lists all virtual tapes in both your VTL and VTS. This operation supports pagination. By default, the operation returns a maximum of up to 100 tapes. You can optionally specify the Limit parameter in the body to limit the number of tapes in the response. If the number of tapes returned in the response is truncated, the response includes a Marker element that you can use in your subsequent request to retrieve the next set of tapes. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<TapeInfos: table<TapeARN: string, TapeBarcode: string, TapeSizeInBytes: int, TapeStatus: string, GatewayARN: string, PoolId: string, RetentionStartDate: string, PoolEntryDate: string>, Marker: string>
# operationId: ListTapes
export def "list-tapes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-60 # required
  --tape-ar-ns: list<string> # The Amazon Resource Name (ARN) of each of the tapes you want to list. If you don't specify a tape ARN, the response lists all tapes in both your VTL and VTS.
  --body-marker: string # A string that indicates the position at which to begin the returned list of tapes. (spec name: Marker)
  --body-limit: int # An optional number limit for the tapes in the list returned by this call. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListTapes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TapeARNs, var: tape_ar_ns}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tape_ar_ns: $tape_ar_ns, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists iSCSI initiators that are connected to a volume. You can use this operation to determine whether a volume is being used or not. This operation is only supported in the cached volume and stored volume gateway types.
#
# POST /
# Returns: record<Initiators: list<string>>
# operationId: ListVolumeInitiators
export def "list-volume-initiators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_arn: string # The Amazon Resource Name (ARN) of the volume. Use the ListVolumes operation to return a list of gateway volumes for the gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListVolumeInitiators"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the recovery points for a specified gateway. This operation is only supported in the cached volume gateway type. Each cache volume has one recovery point. A volume recovery point is a point in time at which all data of the volume is consistent and from which you can create a snapshot or clone a new cached volume from a source volume. To create a snapshot from a volume recovery point use the CreateSnapshotFromVolumeRecoveryPoint operation.
#
# POST /
# Returns: record<GatewayARN: string, VolumeRecoveryPointInfos: table<VolumeARN: string, VolumeSizeInBytes: int, VolumeUsageInBytes: int, VolumeRecoveryPointTime: string>>
# operationId: ListVolumeRecoveryPoints
export def "list-volume-recovery-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListVolumeRecoveryPoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the iSCSI stored volumes of a gateway. Results are sorted by volume ARN. The response includes only the volume ARNs. If you want additional volume information, use the DescribeStorediSCSIVolumes or the DescribeCachediSCSIVolumes API. The operation supports pagination. By default, the operation returns a maximum of up to 100 volumes. You can optionally specify the Limit field in the body to limit the number of volumes in the response. If the number of volumes returned in the response is truncated, the response includes a Marker field. You can use this Marker value in your subsequent request to retrieve the next set of volumes. This operation is only supported in the cached volume and stored volume gateway types.
#
# POST /
# Returns: record<GatewayARN: string, Marker: string, VolumeInfos: table<VolumeARN: string, VolumeId: string, GatewayARN: string, GatewayId: string, VolumeType: string, VolumeSizeInBytes: int, VolumeAttachmentStatus: string>>
# operationId: ListVolumes
export def "list-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-63 # required
  --gateway-arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --body-marker: string # A string that indicates the position at which to begin the returned list of volumes. Obtain the marker from the response of a previous List iSCSI Volumes request. (spec name: Marker)
  --body-limit: int # Specifies that the list of volumes returned be limited to the specified number of items. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ListVolumes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: Marker, var: body_marker}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, body_marker: $body_marker, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends you notification through CloudWatch Events when all files written to your file share have been uploaded to S3. Amazon S3. Storage Gateway can send a notification through Amazon CloudWatch Events when all files written to your file share up to that point in time have been uploaded to Amazon S3. These files include files written to the file share up to the time that you make a request for notification. When the upload is done, Storage Gateway sends you notification through an Amazon CloudWatch Event. You can configure CloudWatch Events to send the notification through event targets such as Amazon SNS or Lambda function. This operation is only supported for S3 File Gateways. For more information, see Getting file upload notification (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-upload-notification) in the Storage Gateway User Guide.
#
# POST /
# Returns: record<FileShareARN: string, NotificationId: string>
# operationId: NotifyWhenUploaded
export def "notify-when-uploaded" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_share_arn: string # The Amazon Resource Name (ARN) of the file share.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.NotifyWhenUploaded"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileShareARN, var: file_share_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_share_arn: $file_share_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refreshes the cached inventory of objects for the specified file share. This operation finds objects in the Amazon S3 bucket that were added, removed, or replaced since the gateway last listed the bucket's contents and cached the results. This operation does not import files into the S3 File Gateway cache storage. It only updates the cached inventory to reflect changes in the inventory of the objects in the S3 bucket. This operation is only supported in the S3 File Gateway types. You can subscribe to be notified through an Amazon CloudWatch event when your RefreshCache operation completes. For more information, see Getting notified about file operations (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification) in the Storage Gateway User Guide. This operation is Only supported for S3 File Gateways. When this API is called, it only initiates the refresh operation. When the API call completes and returns a success code, it doesn't necessarily mean that the file refresh has completed. You should use the refresh-complete notification to determine that the operation has completed before you check for new files on the gateway file share. You can subscribe to be notified through a CloudWatch event when your RefreshCache operation completes. Throttle limit: This API is asynchronous, so the gateway will accept no more than two refreshes at any time. We recommend using the refresh-complete CloudWatch event notification before issuing additional requests. For more information, see Getting notified about file operations (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification) in the Storage Gateway User Guide. Wait at least 60 seconds between consecutive RefreshCache API requests. RefreshCache does not evict cache entries if invoked consecutively within 60 seconds of a previous RefreshCache request. If you invoke the RefreshCache API when two requests are already being processed, any new request will cause an InvalidGatewayRequestException error because too many requests were sent to the server. The S3 bucket name does not need to be included when entering the list of folders in the FolderList parameter. For more information, see Getting notified about file operations (https://docs.aws.amazon.com/storagegateway/latest/userguide/monitoring-file-gateway.html#get-notification) in the Storage Gateway User Guide.
#
# POST /
# Returns: record<FileShareARN: string, NotificationId: string>
# operationId: RefreshCache
export def "refresh-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_share_arn: string # The Amazon Resource Name (ARN) of the file share.
  --folder-list: list<string> # A comma-separated list of the paths of folders to refresh in the cache. The default is ["/"]. The default refreshes objects and folders at the root of the Amazon S3 bucket. If Recursive is set to true, the entire S3 bucket that the file share has access to is refreshed.
  --recursive: oneof<nothing, bool> # A value that specifies whether to recursively refresh folders in the cache. The refresh includes folders that were in the cache the last time the gateway listed the folder's contents. If this value set to true, each folder that is listed in FolderList is recursively updated. Otherwise, subfolders listed in FolderList are not refreshed. Only objects that are in folders listed directly under FolderList are found and used for the update. The default is true. Valid Values: true | false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.RefreshCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileShareARN, var: file_share_arn}, {name: FolderList, var: folder_list}, {name: Recursive, var: recursive}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_share_arn: $file_share_arn, folder_list: $folder_list, recursive: $recursive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from the specified resource. This operation is supported in storage gateways of all types.
#
# POST /
# Returns: record<ResourceARN: string>
# operationId: RemoveTagsFromResource
export def "remove-tags-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource you want to remove the tags from.
  tag_keys: list<string> # The keys of the tags you want to remove from the specified resource. A tag is composed of a key-value pair.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.RemoveTagsFromResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets all cache disks that have encountered an error and makes the disks available for reconfiguration as cache storage. If your cache disk encounters an error, the gateway prevents read and write operations on virtual tapes in the gateway. For example, an error can occur when a disk is corrupted or removed from the gateway. When a cache is reset, the gateway loses its cache storage. At this point, you can reconfigure the disks as cache disks. This operation is only supported in the cached volume and tape types. If the cache disk you are resetting contains data that has not been uploaded to Amazon S3 yet, that data can be lost. After you reset cache disks, there will be no configured cache disks left in the gateway, so you must configure at least one new cache disk for your gateway to function properly.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: ResetCache
export def "reset-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ResetCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an archived virtual tape from the virtual tape shelf (VTS) to a tape gateway. Virtual tapes archived in the VTS are not associated with any gateway. However after a tape is retrieved, it is associated with a gateway, even though it is also listed in the VTS, that is, archive. This operation is only supported in the tape gateway type. Once a tape is successfully retrieved to a gateway, it cannot be retrieved again to another gateway. You must archive the tape again before you can retrieve it to another gateway. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: RetrieveTapeArchive
export def "retrieve-tape-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  tape_arn: string # The Amazon Resource Name (ARN) of the virtual tape you want to retrieve from the virtual tape shelf (VTS).
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.RetrieveTapeArchive"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TapeARN, var: tape_arn}, {name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tape_arn: $tape_arn, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the recovery point for the specified virtual tape. This operation is only supported in the tape gateway type. A recovery point is a point in time view of a virtual tape at which all the data on the tape is consistent. If your gateway crashes, virtual tapes that have recovery points can be recovered to a new gateway. The virtual tape can be retrieved to only one gateway. The retrieved tape is read-only. The virtual tape can be retrieved to only a tape gateway. There is no charge for retrieving recovery points.
#
# POST /
# Returns: record<TapeARN: string>
# operationId: RetrieveTapeRecoveryPoint
export def "retrieve-tape-recovery-point" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  tape_arn: string # The Amazon Resource Name (ARN) of the virtual tape for which you want to retrieve the recovery point.
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.RetrieveTapeRecoveryPoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TapeARN, var: tape_arn}, {name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tape_arn: $tape_arn, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the password for your VM local console. When you log in to the local console for the first time, you log in to the VM with the default credentials. We recommend that you set a new password. You don't need to know the default password to set a new password.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: SetLocalConsolePassword
export def "set-local-console-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  local_console_password: string # The password you want to set for your VM local console. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.SetLocalConsolePassword"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: LocalConsolePassword, var: local_console_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, local_console_password: $local_console_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the password for the guest user smbguest. The smbguest user is the user when the authentication method for the file share is set to GuestAccess. This operation only supported for S3 File Gateways
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: SetSMBGuestPassword
export def "set-smb-guest-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  password: string # The password that you want to set for your SMB server. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.SetSMBGuestPassword"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: Password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shuts down a gateway. To specify which gateway to shut down, use the Amazon Resource Name (ARN) of the gateway in the body of your request. The operation shuts down the gateway service component running in the gateway's virtual machine (VM) and not the host VM. If you want to shut down the VM, it is recommended that you first shut down the gateway component in the VM to avoid unpredictable conditions. After the gateway is shutdown, you cannot call any other API except StartGateway, DescribeGatewayInformation, and ListGateways. For more information, see ActivateGateway. Your applications cannot read from or write to the gateway's storage volumes, and there are no snapshots taken. When you make a shutdown request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to shut down. You can call the DescribeGatewayInformation API to check the status. For more information, see ActivateGateway. If do not intend to use the gateway again, you must delete the gateway (using DeleteGateway) to no longer pay software charges associated with the gateway.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: ShutdownGateway
export def "shutdown-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.ShutdownGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a test that verifies that the specified gateway is configured for High Availability monitoring in your host environment. This request only initiates the test and that a successful response only indicates that the test was started. It doesn't indicate that the test passed. For the status of the test, invoke the DescribeAvailabilityMonitorTest API. Starting this test will cause your gateway to go offline for a brief period.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: StartAvailabilityMonitorTest
export def "start-availability-monitor-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.StartAvailabilityMonitorTest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a gateway that you previously shut down (see ShutdownGateway). After the gateway starts, you can then make other API calls, your applications can read from or write to the gateway's storage volumes and you will be able to take snapshot backups. When you make a request, you will get a 200 OK success response immediately. However, it might take some time for the gateway to be ready. You should call DescribeGatewayInformation and check the status before making any additional API calls. For more information, see ActivateGateway. To specify which gateway to start, use the Amazon Resource Name (ARN) of the gateway in your request.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: StartGateway
export def "start-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.StartGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the automatic tape creation policy of a gateway. Use this to update the policy with a new set of automatic tape creation rules. This is only supported for tape gateways. By default, there is no automatic tape creation policy. A gateway can have only one automatic tape creation policy.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateAutomaticTapeCreationPolicy
export def "update-automatic-tape-creation-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  automatic_tape_creation_rules: list # An automatic tape creation policy consists of a list of automatic tape creation rules. The rules determine when and how to automatically create new tapes. — item shape: {TapeBarcodePrefix: string, PoolId: string, TapeSizeInBytes: int, MinimumNumTapes: int, Worm?: bool}
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateAutomaticTapeCreationPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AutomaticTapeCreationRules, var: automatic_tape_creation_rules}, {name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, automatic_tape_creation_rules: $automatic_tape_creation_rules, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the bandwidth rate limits of a gateway. You can update both the upload and download bandwidth rate limit or specify only one of the two. If you don't set a bandwidth rate limit, the existing rate limit remains. This operation is supported only for the stored volume, cached volume, and tape gateway types. To update bandwidth rate limits for S3 file gateways, use UpdateBandwidthRateLimitSchedule. By default, a gateway's bandwidth rate limits are not set. If you don't set any limit, the gateway does not have any limitations on its bandwidth usage and could potentially use the maximum available bandwidth. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateBandwidthRateLimit
export def "update-bandwidth-rate-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --average-upload-rate-limit-in-bits-per-sec: int # The average upload bandwidth rate limit in bits per second.
  --average-download-rate-limit-in-bits-per-sec: int # The average download bandwidth rate limit in bits per second.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateBandwidthRateLimit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: AverageUploadRateLimitInBitsPerSec, var: average_upload_rate_limit_in_bits_per_sec}, {name: AverageDownloadRateLimitInBitsPerSec, var: average_download_rate_limit_in_bits_per_sec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, average_upload_rate_limit_in_bits_per_sec: $average_upload_rate_limit_in_bits_per_sec, average_download_rate_limit_in_bits_per_sec: $average_download_rate_limit_in_bits_per_sec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the bandwidth rate limit schedule for a specified gateway. By default, gateways do not have bandwidth rate limit schedules, which means no bandwidth rate limiting is in effect. Use this to initiate or update a gateway's bandwidth rate limit schedule. This operation is supported only for volume, tape and S3 file gateways. FSx file gateways do not support bandwidth rate limits.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateBandwidthRateLimitSchedule
export def "update-bandwidth-rate-limit-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  bandwidth_rate_limit_intervals: list # An array containing bandwidth rate limit schedule intervals for a gateway. When no bandwidth rate limit intervals have been scheduled, the array is empty. — item shape: {StartHourOfDay: int, StartMinuteOfHour: int, EndHourOfDay: int, EndMinuteOfHour: int, DaysOfWeek: list<int>, AverageUploadRateLimitInBitsPerSec?: int, AverageDownloadRateLimitInBitsPerSec?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateBandwidthRateLimitSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: BandwidthRateLimitIntervals, var: bandwidth_rate_limit_intervals}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, bandwidth_rate_limit_intervals: $bandwidth_rate_limit_intervals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Challenge-Handshake Authentication Protocol (CHAP) credentials for a specified iSCSI target. By default, a gateway does not have CHAP enabled; however, for added security, you might use it. This operation is supported in the volume and tape gateway types. When you update CHAP credentials, all existing connections on the target are closed and initiators must reconnect with the new credentials.
#
# POST /
# Returns: record<TargetARN: string, InitiatorName: string>
# operationId: UpdateChapCredentials
export def "update-chap-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  target_arn: string # The Amazon Resource Name (ARN) of the iSCSI volume target. Use the DescribeStorediSCSIVolumes operation to return the TargetARN for specified VolumeARN.
  secret_to_authenticate_initiator: string # The secret key that the initiator (for example, the Windows client) must provide to participate in mutual CHAP with the target. The secret key must be between 12 and 16 bytes when encoded in UTF-8. (format: password)
  initiator_name: string # The iSCSI initiator that connects to the target.
  --secret-to-authenticate-target: string # The secret key that the target must provide to participate in mutual CHAP with the initiator (e.g. Windows client). Byte constraints: Minimum bytes of 12. Maximum bytes of 16. The secret key must be between 12 and 16 bytes when encoded in UTF-8. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateChapCredentials"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetARN, var: target_arn}, {name: SecretToAuthenticateInitiator, var: secret_to_authenticate_initiator}, {name: InitiatorName, var: initiator_name}, {name: SecretToAuthenticateTarget, var: secret_to_authenticate_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, target_arn: $target_arn, secret_to_authenticate_initiator: $secret_to_authenticate_initiator, initiator_name: $initiator_name, secret_to_authenticate_target: $secret_to_authenticate_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a file system association. This operation is only supported in the FSx File Gateways.
#
# POST /
# Returns: record<FileSystemAssociationARN: string>
# operationId: UpdateFileSystemAssociation
export def "update-file-system-association" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_system_association_arn: string # The Amazon Resource Name (ARN) of the file system association that you want to update.
  --user-name: string # The user name of the user credential that has permission to access the root share D$ of the Amazon FSx file system. The user account must belong to the Amazon FSx delegated admin user group.
  --password: string # The password of the user credential. (format: password)
  --audit-destination-arn: string # The Amazon Resource Name (ARN) of the storage used for the audit logs.
  --cache-attributes: record # The refresh cache information for the file share or FSx file systems. — shape: {CacheStaleTimeoutInSeconds?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateFileSystemAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileSystemAssociationARN, var: file_system_association_arn}, {name: UserName, var: user_name}, {name: Password, var: password}, {name: AuditDestinationARN, var: audit_destination_arn}, {name: CacheAttributes, var: cache_attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_system_association_arn: $file_system_association_arn, user_name: $user_name, password: $password, audit_destination_arn: $audit_destination_arn, cache_attributes: $cache_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a gateway's metadata, which includes the gateway's name and time zone. To specify which gateway to update, use the Amazon Resource Name (ARN) of the gateway in your request. For gateways activated after September 2, 2015, the gateway's ARN contains the gateway ID rather than the gateway name. However, changing the name of the gateway has no effect on the gateway's ARN.
#
# POST /
# Returns: record<GatewayARN: string, GatewayName: string>
# operationId: UpdateGatewayInformation
export def "update-gateway-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --gateway-name: string # The name you configured for your gateway.
  --gateway-timezone: string # A value that indicates the time zone of the gateway.
  --cloud-watch-log-group-arn: string # The Amazon Resource Name (ARN) of the Amazon CloudWatch log group that you want to use to monitor and log events in the gateway. For more information, see What is Amazon CloudWatch Logs? (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html)
  --gateway-capacity: string@gateway-capacity-completer # Specifies the size of the gateway's metadata cache.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateGatewayInformation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: GatewayName, var: gateway_name}, {name: GatewayTimezone, var: gateway_timezone}, {name: CloudWatchLogGroupARN, var: cloud_watch_log_group_arn}, {name: GatewayCapacity, var: gateway_capacity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, gateway_name: $gateway_name, gateway_timezone: $gateway_timezone, cloud_watch_log_group_arn: $cloud_watch_log_group_arn, gateway_capacity: $gateway_capacity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the gateway virtual machine (VM) software. The request immediately triggers the software update. When you make this request, you get a 200 OK success response immediately. However, it might take some time for the update to complete. You can call DescribeGatewayInformation to verify the gateway is in the STATE_RUNNING state. A software update forces a system restart of your gateway. You can minimize the chance of any disruption to your applications by increasing your iSCSI Initiators' timeouts. For more information about increasing iSCSI Initiator timeouts for Windows and Linux, see Customizing your Windows iSCSI settings (https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorWindowsClient.html#CustomizeWindowsiSCSISettings) and Customizing your Linux iSCSI settings (https://docs.aws.amazon.com/storagegateway/latest/userguide/ConfiguringiSCSIClientInitiatorRedHatClient.html#CustomizeLinuxiSCSISettings), respectively.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateGatewaySoftwareNow
export def "update-gateway-software-now" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateGatewaySoftwareNow"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a gateway's weekly maintenance start time information, including day and time of the week. The maintenance time is the time in your gateway's time zone.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateMaintenanceStartTime
export def "update-maintenance-start-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  hour_of_day: int # The hour component of the maintenance start time represented as hh, where hh is the hour (00 to 23). The hour of the day is in the time zone of the gateway.
  minute_of_hour: int # The minute component of the maintenance start time represented as mm, where mm is the minute (00 to 59). The minute of the hour is in the time zone of the gateway.
  --day-of-week: int # The day of the week component of the maintenance start time week represented as an ordinal number from 0 to 6, where 0 represents Sunday and 6 Saturday.
  --day-of-month: int # The day of the month component of the maintenance start time represented as an ordinal number from 1 to 28, where 1 represents the first day of the month and 28 represents the last day of the month.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateMaintenanceStartTime"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: HourOfDay, var: hour_of_day}, {name: MinuteOfHour, var: minute_of_hour}, {name: DayOfWeek, var: day_of_week}, {name: DayOfMonth, var: day_of_month}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, hour_of_day: $hour_of_day, minute_of_hour: $minute_of_hour, day_of_week: $day_of_week, day_of_month: $day_of_month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Network File System (NFS) file share. This operation is only supported in S3 File Gateways. To leave a file share field unchanged, set the corresponding input field to null. Updates the following file share settings: Default storage class for your S3 bucket Metadata defaults for your S3 bucket Allowed NFS clients for your file share Squash settings Write status of your file share
#
# POST /
# Returns: record<FileShareARN: string>
# operationId: UpdateNFSFileShare
export def "update-nfs-file-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  file_share_arn: string # The Amazon Resource Name (ARN) of the file share.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  --nfs-file-share-defaults: record # Describes Network File System (NFS) file share default values. Files and folders stored as Amazon S3 objects in S3 buckets don't, by default, have Unix file permissions assigned to them. Upon discovery in an S3 bucket by Storage Gateway, the S3 objects that represent files and folders are assigned these default Unix permissions. This operation is only supported for S3 File Gateways. — shape: {FileMode?: string, DirectoryMode?: string, GroupId?: int, OwnerId?: int}
  --default-storage-class: string
  --object-acl: string@object-acl-completer # A value that sets the access control list (ACL) permission for objects in the S3 bucket that an S3 File Gateway puts objects into. The default value is private.
  --client-list: list<string> # The list of clients that are allowed to access the S3 File Gateway. The list must contain either valid IP addresses or valid CIDR blocks.
  --squash: string # The user mapped to anonymous user. Valid options are the following: RootSquash: Only root is mapped to anonymous user. NoSquash: No one is mapped to anonymous user. AllSquash: Everyone is mapped to anonymous user.
  --read-only: oneof<nothing, bool> # A value that sets the write status of a file share. Set this value to true to set the write status to read-only, otherwise set to false. Valid Values: true | false
  --guess-mime-type-enabled: oneof<nothing, bool> # A value that enables guessing of the MIME type for uploaded objects based on file extensions. Set this value to true to enable MIME type guessing, otherwise set to false. The default value is true. Valid Values: true | false
  --requester-pays: oneof<nothing, bool> # A value that sets who pays the cost of the request and the cost associated with data download from the S3 bucket. If this value is set to true, the requester pays the costs; otherwise, the S3 bucket owner pays. However, the S3 bucket owner always pays the cost of storing data. RequesterPays is a configuration for the S3 bucket that backs the file share, so make sure that the configuration on the file share is the same as the S3 bucket configuration. Valid Values: true | false
  --file-share-name: string # The name of the file share. Optional. FileShareName must be set if an S3 prefix name is set in LocationARN, or if an access point or access point alias is used.
  --cache-attributes: record # The refresh cache information for the file share or FSx file systems. — shape: {CacheStaleTimeoutInSeconds?: int}
  --notification-policy: string # The notification policy of the file share. SettlingTimeInSeconds controls the number of seconds to wait after the last point in time a client wrote to a file before generating an ObjectUploaded notification. Because clients can make many small writes to files, it's best to set this parameter for as long as possible to avoid generating multiple notifications for the same file in a small time period. SettlingTimeInSeconds has no effect on the timing of the object uploading to Amazon S3, only the timing of the notification. The following example sets NotificationPolicy on with SettlingTimeInSeconds set to 60. {\"Upload\": {\"SettlingTimeInSeconds\": 60}} The following example sets NotificationPolicy off. {}
  --audit-destination-arn: string # The Amazon Resource Name (ARN) of the storage used for audit logs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateNFSFileShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileShareARN, var: file_share_arn}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: NFSFileShareDefaults, var: nfs_file_share_defaults}, {name: DefaultStorageClass, var: default_storage_class}, {name: ObjectACL, var: object_acl}, {name: ClientList, var: client_list}, {name: Squash, var: squash}, {name: ReadOnly, var: read_only}, {name: GuessMIMETypeEnabled, var: guess_mime_type_enabled}, {name: RequesterPays, var: requester_pays}, {name: FileShareName, var: file_share_name}, {name: CacheAttributes, var: cache_attributes}, {name: NotificationPolicy, var: notification_policy}, {name: AuditDestinationARN, var: audit_destination_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_share_arn: $file_share_arn, kms_encrypted: $kms_encrypted, kms_key: $kms_key, nfs_file_share_defaults: $nfs_file_share_defaults, default_storage_class: $default_storage_class, object_acl: $object_acl, client_list: $client_list, squash: $squash, read_only: $read_only, guess_mime_type_enabled: $guess_mime_type_enabled, requester_pays: $requester_pays, file_share_name: $file_share_name, cache_attributes: $cache_attributes, notification_policy: $notification_policy, audit_destination_arn: $audit_destination_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Server Message Block (SMB) file share. This operation is only supported for S3 File Gateways. To leave a file share field unchanged, set the corresponding input field to null. File gateways require Security Token Service (Amazon Web Services STS) to be activated to enable you to create a file share. Make sure that Amazon Web Services STS is activated in the Amazon Web Services Region you are creating your file gateway in. If Amazon Web Services STS is not activated in this Amazon Web Services Region, activate it. For information about how to activate Amazon Web Services STS, see Activating and deactivating Amazon Web Services STS in an Amazon Web Services Region (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html) in the Identity and Access Management User Guide. File gateways don't support creating hard or symbolic links on a file share.
#
# POST /
# Returns: record<FileShareARN: string>
# operationId: UpdateSMBFileShare
export def "update-smb-file-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-84 # required
  file_share_arn: string # The Amazon Resource Name (ARN) of the file share.
  --kms-encrypted: oneof<nothing, bool> # Set to true to use Amazon S3 server-side encryption with your own KMS key, or false to use a key managed by Amazon S3. Optional. Valid Values: true | false
  --kms-key: string # The Amazon Resource Name (ARN) of a symmetric customer master key (CMK) used for Amazon S3 server-side encryption. Storage Gateway does not support asymmetric CMKs. This value can only be set when KMSEncrypted is true. Optional.
  --default-storage-class: string
  --object-acl: string@object-acl-completer # A value that sets the access control list (ACL) permission for objects in the S3 bucket that an S3 File Gateway puts objects into. The default value is private.
  --read-only: oneof<nothing, bool> # A value that sets the write status of a file share. Set this value to true to set write status to read-only, otherwise set to false. Valid Values: true | false
  --guess-mime-type-enabled: oneof<nothing, bool> # A value that enables guessing of the MIME type for uploaded objects based on file extensions. Set this value to true to enable MIME type guessing, otherwise set to false. The default value is true. Valid Values: true | false
  --requester-pays: oneof<nothing, bool> # A value that sets who pays the cost of the request and the cost associated with data download from the S3 bucket. If this value is set to true, the requester pays the costs; otherwise, the S3 bucket owner pays. However, the S3 bucket owner always pays the cost of storing data. RequesterPays is a configuration for the S3 bucket that backs the file share, so make sure that the configuration on the file share is the same as the S3 bucket configuration. Valid Values: true | false
  --smbacl-enabled: oneof<nothing, bool> # Set this value to true to enable access control list (ACL) on the SMB file share. Set it to false to map file and directory permissions to the POSIX permissions. For more information, see Using Microsoft Windows ACLs to control access to an SMB file share (https://docs.aws.amazon.com/storagegateway/latest/userguide/smb-acl.html) in the Storage Gateway User Guide. Valid Values: true | false
  --access-based-enumeration: oneof<nothing, bool> # The files and folders on this share will only be visible to users with read access.
  --admin-user-list: list<string> # A list of users or groups in the Active Directory that have administrator rights to the file share. A group must be prefixed with the @ character. Acceptable formats include: DOMAIN\User1, user1, @group1, and @DOMAIN\group1. Can only be set if Authentication is set to ActiveDirectory.
  --valid-user-list: list<string> # A list of users or groups in the Active Directory that are allowed to access the file share. A group must be prefixed with the @ character. Acceptable formats include: DOMAIN\User1, user1, @group1, and @DOMAIN\group1. Can only be set if Authentication is set to ActiveDirectory.
  --invalid-user-list: list<string> # A list of users or groups in the Active Directory that are not allowed to access the file share. A group must be prefixed with the @ character. Acceptable formats include: DOMAIN\User1, user1, @group1, and @DOMAIN\group1. Can only be set if Authentication is set to ActiveDirectory.
  --audit-destination-arn: string # The Amazon Resource Name (ARN) of the storage used for audit logs.
  --case-sensitivity: string@case-sensitivity-completer # The case of an object name in an Amazon S3 bucket. For ClientSpecified, the client determines the case sensitivity. For CaseSensitive, the gateway determines the case sensitivity. The default value is ClientSpecified.
  --file-share-name: string # The name of the file share. Optional. FileShareName must be set if an S3 prefix name is set in LocationARN, or if an access point or access point alias is used.
  --cache-attributes: record # The refresh cache information for the file share or FSx file systems. — shape: {CacheStaleTimeoutInSeconds?: int}
  --notification-policy: string # The notification policy of the file share. SettlingTimeInSeconds controls the number of seconds to wait after the last point in time a client wrote to a file before generating an ObjectUploaded notification. Because clients can make many small writes to files, it's best to set this parameter for as long as possible to avoid generating multiple notifications for the same file in a small time period. SettlingTimeInSeconds has no effect on the timing of the object uploading to Amazon S3, only the timing of the notification. The following example sets NotificationPolicy on with SettlingTimeInSeconds set to 60. {\"Upload\": {\"SettlingTimeInSeconds\": 60}} The following example sets NotificationPolicy off. {}
  --oplocks-enabled: oneof<nothing, bool> # Specifies whether opportunistic locking is enabled for the SMB file share. Enabling opportunistic locking on case-sensitive shares is not recommended for workloads that involve access to files with the same name in different case. Valid Values: true | false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateSMBFileShare"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FileShareARN, var: file_share_arn}, {name: KMSEncrypted, var: kms_encrypted}, {name: KMSKey, var: kms_key}, {name: DefaultStorageClass, var: default_storage_class}, {name: ObjectACL, var: object_acl}, {name: ReadOnly, var: read_only}, {name: GuessMIMETypeEnabled, var: guess_mime_type_enabled}, {name: RequesterPays, var: requester_pays}, {name: SMBACLEnabled, var: smbacl_enabled}, {name: AccessBasedEnumeration, var: access_based_enumeration}, {name: AdminUserList, var: admin_user_list}, {name: ValidUserList, var: valid_user_list}, {name: InvalidUserList, var: invalid_user_list}, {name: AuditDestinationARN, var: audit_destination_arn}, {name: CaseSensitivity, var: case_sensitivity}, {name: FileShareName, var: file_share_name}, {name: CacheAttributes, var: cache_attributes}, {name: NotificationPolicy, var: notification_policy}, {name: OplocksEnabled, var: oplocks_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, file_share_arn: $file_share_arn, kms_encrypted: $kms_encrypted, kms_key: $kms_key, default_storage_class: $default_storage_class, object_acl: $object_acl, read_only: $read_only, guess_mime_type_enabled: $guess_mime_type_enabled, requester_pays: $requester_pays, smbacl_enabled: $smbacl_enabled, access_based_enumeration: $access_based_enumeration, admin_user_list: $admin_user_list, valid_user_list: $valid_user_list, invalid_user_list: $invalid_user_list, audit_destination_arn: $audit_destination_arn, case_sensitivity: $case_sensitivity, file_share_name: $file_share_name, cache_attributes: $cache_attributes, notification_policy: $notification_policy, oplocks_enabled: $oplocks_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Controls whether the shares on an S3 File Gateway are visible in a net view or browse list. The operation is only supported for S3 File Gateways.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateSMBFileShareVisibility
export def "update-smb-file-share-visibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-85 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  --file-shares-visible: oneof<nothing, bool> # The shares on this gateway appear when listing shares.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateSMBFileShareVisibility"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: FileSharesVisible, var: file_shares_visible, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, file_shares_visible: $file_shares_visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the list of Active Directory users and groups that have special permissions for SMB file shares on the gateway.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateSMBLocalGroups
export def "update-smb-local-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-86 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  smb_local_groups: record # A list of Active Directory users and groups that have special permissions for SMB file shares on the gateway. — shape: {GatewayAdmins?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateSMBLocalGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: SMBLocalGroups, var: smb_local_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, smb_local_groups: $smb_local_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the SMB security strategy on a file gateway. This action is only supported in file gateways. This API is called Security level in the User Guide. A higher security level can affect performance of the gateway.
#
# POST /
# Returns: record<GatewayARN: string>
# operationId: UpdateSMBSecurityStrategy
export def "update-smb-security-strategy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-87 # required
  gateway_arn: string # The Amazon Resource Name (ARN) of the gateway. Use the ListGateways operation to return a list of gateways for your account and Amazon Web Services Region.
  smb_security_strategy: string@smb-security-strategy-completer # Specifies the type of security strategy. ClientSpecified: if you use this option, requests are established based on what is negotiated by the client. This option is recommended when you want to maximize compatibility across different clients in your environment. Supported only in S3 File Gateway. MandatorySigning: if you use this option, file gateway only allows connections from SMBv2 or SMBv3 clients that have signing enabled. This option works with SMB clients on Microsoft Windows Vista, Windows Server 2008 or newer. MandatoryEncryption: if you use this option, file gateway only allows connections from SMBv3 clients that have encryption enabled. This option is highly recommended for environments that handle sensitive data. This option works with SMB clients on Microsoft Windows 8, Windows Server 2012 or newer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateSMBSecurityStrategy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GatewayARN, var: gateway_arn}, {name: SMBSecurityStrategy, var: smb_security_strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, gateway_arn: $gateway_arn, smb_security_strategy: $smb_security_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a snapshot schedule configured for a gateway volume. This operation is only supported in the cached volume and stored volume gateway types. The default snapshot schedule for volume is once every 24 hours, starting at the creation time of the volume. You can use this API to change the snapshot schedule configured for the volume. In the request you must identify the gateway volume whose snapshot schedule you want to update, and the schedule information, including when you want the snapshot to begin on a day and the frequency (in hours) of snapshots.
#
# POST /
# Returns: record<VolumeARN: string>
# operationId: UpdateSnapshotSchedule
export def "update-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-88 # required
  volume_arn: string # The Amazon Resource Name (ARN) of the volume. Use the ListVolumes operation to return a list of gateway volumes.
  start_at: int # The hour of the day at which the snapshot schedule begins represented as hh, where hh is the hour (0 to 23). The hour of the day is in the time zone of the gateway.
  recurrence_in_hours: int # Frequency of snapshots. Specify the number of hours between snapshots.
  --description: string # Optional description of the snapshot that overwrites the existing description.
  --tags: list # A list of up to 50 tags that can be assigned to a snapshot. Each tag is a key-value pair. Valid characters for key and value are letters, spaces, and numbers representable in UTF-8 format, and the following special characters: + - = . _ : / @. The maximum length of a tag's key is 128 characters, and the maximum length for a tag's value is 256. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateSnapshotSchedule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeARN, var: volume_arn}, {name: StartAt, var: start_at}, {name: RecurrenceInHours, var: recurrence_in_hours}, {name: Description, var: description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_arn: $volume_arn, start_at: $start_at, recurrence_in_hours: $recurrence_in_hours, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the type of medium changer in a tape gateway. When you activate a tape gateway, you select a medium changer type for the tape gateway. This operation enables you to select a different type of medium changer after a tape gateway is activated. This operation is only supported in the tape gateway type.
#
# POST /
# Returns: record<VTLDeviceARN: string>
# operationId: UpdateVTLDeviceType
export def "update-vtl-device-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-89 # required
  vtl_device_arn: string # The Amazon Resource Name (ARN) of the medium changer you want to select.
  device_type: string # The type of medium changer you want to select. Valid Values: STK-L700 | AWS-Gateway-VTL | IBM-03584L32-0402
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "StorageGateway_20130630.UpdateVTLDeviceType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VTLDeviceARN, var: vtl_device_arn}, {name: DeviceType, var: device_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vtl_device_arn: $vtl_device_arn, device_type: $device_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
