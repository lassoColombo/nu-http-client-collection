# Auto-generated client for Amazon DynamoDB Accelerator (DAX) v2017-04-19
# Source: https://api.apis.guru/v2/specs/amazonaws.com/dax/2017-04-19/openapi.json
# Auth: --token flag or $env.AMAZON_DYNAMODB_ACCELERATOR_DAX_TOKEN

const CLIENT = {
  base_url: "http://dax.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_DYNAMODB_ACCELERATOR_DAX_TOKEN"
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

def base-url-completer [] { ["http://dax.us-east-1.amazonaws.com" "http://dax.us-east-2.amazonaws.com" "http://dax.us-west-1.amazonaws.com" "http://dax.us-west-2.amazonaws.com" "http://dax.us-gov-west-1.amazonaws.com" "http://dax.us-gov-east-1.amazonaws.com" "http://dax.ca-central-1.amazonaws.com" "http://dax.eu-north-1.amazonaws.com" "http://dax.eu-west-1.amazonaws.com" "http://dax.eu-west-2.amazonaws.com" "http://dax.eu-west-3.amazonaws.com" "http://dax.eu-central-1.amazonaws.com" "http://dax.eu-south-1.amazonaws.com" "http://dax.af-south-1.amazonaws.com" "http://dax.ap-northeast-1.amazonaws.com" "http://dax.ap-northeast-2.amazonaws.com" "http://dax.ap-northeast-3.amazonaws.com" "http://dax.ap-southeast-1.amazonaws.com" "http://dax.ap-southeast-2.amazonaws.com" "http://dax.ap-east-1.amazonaws.com" "http://dax.ap-south-1.amazonaws.com" "http://dax.sa-east-1.amazonaws.com" "http://dax.me-south-1.amazonaws.com" "https://dax.us-east-1.amazonaws.com" "https://dax.us-east-2.amazonaws.com" "https://dax.us-west-1.amazonaws.com" "https://dax.us-west-2.amazonaws.com" "https://dax.us-gov-west-1.amazonaws.com" "https://dax.us-gov-east-1.amazonaws.com" "https://dax.ca-central-1.amazonaws.com" "https://dax.eu-north-1.amazonaws.com" "https://dax.eu-west-1.amazonaws.com" "https://dax.eu-west-2.amazonaws.com" "https://dax.eu-west-3.amazonaws.com" "https://dax.eu-central-1.amazonaws.com" "https://dax.eu-south-1.amazonaws.com" "https://dax.af-south-1.amazonaws.com" "https://dax.ap-northeast-1.amazonaws.com" "https://dax.ap-northeast-2.amazonaws.com" "https://dax.ap-northeast-3.amazonaws.com" "https://dax.ap-southeast-1.amazonaws.com" "https://dax.ap-southeast-2.amazonaws.com" "https://dax.ap-east-1.amazonaws.com" "https://dax.ap-south-1.amazonaws.com" "https://dax.sa-east-1.amazonaws.com" "https://dax.me-south-1.amazonaws.com" "http://dax.cn-north-1.amazonaws.com.cn" "http://dax.cn-northwest-1.amazonaws.com.cn" "https://dax.cn-north-1.amazonaws.com.cn" "https://dax.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def cluster-endpoint-encryption-type-completer [] { ["NONE" "TLS"] }
def x-amz-target-completer [] { ["AmazonDAXV3.CreateCluster"] }
def x-amz-target-completer-1 [] { ["AmazonDAXV3.CreateParameterGroup"] }
def x-amz-target-completer-2 [] { ["AmazonDAXV3.CreateSubnetGroup"] }
def x-amz-target-completer-3 [] { ["AmazonDAXV3.DecreaseReplicationFactor"] }
def x-amz-target-completer-4 [] { ["AmazonDAXV3.DeleteCluster"] }
def x-amz-target-completer-5 [] { ["AmazonDAXV3.DeleteParameterGroup"] }
def x-amz-target-completer-6 [] { ["AmazonDAXV3.DeleteSubnetGroup"] }
def x-amz-target-completer-7 [] { ["AmazonDAXV3.DescribeClusters"] }
def x-amz-target-completer-8 [] { ["AmazonDAXV3.DescribeDefaultParameters"] }
def source-type-completer [] { ["CLUSTER" "PARAMETER_GROUP" "SUBNET_GROUP"] }
def x-amz-target-completer-9 [] { ["AmazonDAXV3.DescribeEvents"] }
def x-amz-target-completer-10 [] { ["AmazonDAXV3.DescribeParameterGroups"] }
def x-amz-target-completer-11 [] { ["AmazonDAXV3.DescribeParameters"] }
def x-amz-target-completer-12 [] { ["AmazonDAXV3.DescribeSubnetGroups"] }
def x-amz-target-completer-13 [] { ["AmazonDAXV3.IncreaseReplicationFactor"] }
def x-amz-target-completer-14 [] { ["AmazonDAXV3.ListTags"] }
def x-amz-target-completer-15 [] { ["AmazonDAXV3.RebootNode"] }
def x-amz-target-completer-16 [] { ["AmazonDAXV3.TagResource"] }
def x-amz-target-completer-17 [] { ["AmazonDAXV3.UntagResource"] }
def x-amz-target-completer-18 [] { ["AmazonDAXV3.UpdateCluster"] }
def x-amz-target-completer-19 [] { ["AmazonDAXV3.UpdateParameterGroup"] }
def x-amz-target-completer-20 [] { ["AmazonDAXV3.UpdateSubnetGroup"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-cluster: "record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>"
    create-parameter-group: "record<ParameterGroup: record<ParameterGroupName: string, Description: string>>"
    create-subnet-group: "record<SubnetGroup: record<SubnetGroupName: string, Description: string, VpcId: string, Subnets: list<record>>>"
    decrease-replication-factor: "record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>"
    delete-cluster: "record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>"
    delete-parameter-group: "record<DeletionMessage: string>"
    delete-subnet-group: "record<DeletionMessage: string>"
    describe-clusters: "record<NextToken: string, Clusters: table<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record, NodeIdsToRemove: list, Nodes: list, PreferredMaintenanceWindow: string, NotificationConfiguration: record, SubnetGroup: string, SecurityGroups: list, IamRoleArn: string, ParameterGroup: record, SSEDescription: record, ClusterEndpointEncryptionType: string>>"
    describe-default-parameters: "record<NextToken: string, Parameters: table<ParameterName: string, ParameterType: string, ParameterValue: string, NodeTypeSpecificValues: list, Description: string, Source: string, DataType: string, AllowedValues: string, IsModifiable: string, ChangeType: string>>"
    describe-events: "record<NextToken: string, Events: table<SourceName: string, SourceType: string, Message: string, Date: string>>"
    describe-parameter-groups: "record<NextToken: string, ParameterGroups: table<ParameterGroupName: string, Description: string>>"
    describe-parameters: "record<NextToken: string, Parameters: table<ParameterName: string, ParameterType: string, ParameterValue: string, NodeTypeSpecificValues: list, Description: string, Source: string, DataType: string, AllowedValues: string, IsModifiable: string, ChangeType: string>>"
    describe-subnet-groups: "record<NextToken: string, SubnetGroups: table<SubnetGroupName: string, Description: string, VpcId: string, Subnets: list>>"
    increase-replication-factor: "record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>"
    list-tags: "record<Tags: table<Key: string, Value: string>, NextToken: string>"
    reboot-node: "record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>"
    tag-resource: "record<Tags: table<Key: string, Value: string>>"
    untag-resource: "record<Tags: table<Key: string, Value: string>>"
    update-cluster: "record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>"
    update-parameter-group: "record<ParameterGroup: record<ParameterGroupName: string, Description: string>>"
    update-subnet-group: "record<SubnetGroup: record<SubnetGroupName: string, Description: string, VpcId: string, Subnets: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-cluster" "create-parameter-group" "create-subnet-group" "decrease-replication-factor" "delete-cluster" "delete-parameter-group" "delete-subnet-group" "describe-clusters" "describe-default-parameters" "describe-events" "describe-parameter-groups" "describe-parameters" "describe-subnet-groups" "increase-replication-factor" "list-tags" "reboot-node" "tag-resource" "untag-resource" "update-cluster" "update-parameter-group" "update-subnet-group" "commands"] | sort) } | get name | first)
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

# Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
#
# POST /
# Returns: record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>
# operationId: CreateCluster
export def "create-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cluster_name: string # The cluster identifier. This parameter is stored as a lowercase string. Constraints: A name must contain from 1 to 20 alphanumeric characters or hyphens. The first character must be a letter. A name cannot end with a hyphen or contain two consecutive hyphens.
  node_type: string # The compute and memory capacity of the nodes in the cluster.
  --description: string # A description of the cluster.
  replication_factor: int # The number of nodes in the DAX cluster. A replication factor of 1 will create a single-node cluster, without any read replicas. For additional fault tolerance, you can create a multiple node cluster with one or more read replicas. To do this, set ReplicationFactor to a number between 3 (one primary and two read replicas) and 10 (one primary and nine read replicas). If the AvailabilityZones parameter is provided, its length must equal the ReplicationFactor. AWS recommends that you have at least two read replicas per cluster.
  --availability-zones: list<string> # The Availability Zones (AZs) in which the cluster nodes will reside after the cluster has been created or updated. If provided, the length of this list must equal the ReplicationFactor parameter. If you omit this parameter, DAX will spread the nodes across Availability Zones for the highest availability.
  --subnet-group-name: string # The name of the subnet group to be used for the replication group. DAX clusters can only run in an Amazon VPC environment. All of the subnets that you specify in a subnet group must exist in the same VPC.
  --security-group-ids: list<string> # A list of security group IDs to be assigned to each node in the DAX cluster. (Each of the security group ID is system-generated.) If this parameter is not specified, DAX assigns the default VPC security group to each node.
  --preferred-maintenance-window: string # Specifies the weekly time range during which maintenance on the DAX cluster is performed. It is specified as a range in the format ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Valid values for ddd are: sun mon tue wed thu fri sat Example: sun:05:00-sun:09:00 If you don't specify a preferred maintenance window when you create or modify a cache cluster, DAX assigns a 60-minute maintenance window on a randomly selected day of the week.
  --notification-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic to which notifications will be sent. The Amazon SNS topic owner must be same as the DAX cluster owner.
  iam_role_arn: string # A valid Amazon Resource Name (ARN) that identifies an IAM role. At runtime, DAX will assume this role and use the role's permissions to access DynamoDB on your behalf.
  --parameter-group-name: string # The parameter group to be associated with the DAX cluster.
  --tags: list # A set of tags to associate with the DAX cluster. — item shape: {Key?: string, Value?: string}
  --sse-specification: record # Represents the settings used to enable server-side encryption. — shape: {Enabled: bool}
  --cluster-endpoint-encryption-type: string@cluster-endpoint-encryption-type-completer # The type of encryption the cluster's endpoint should support. Values are: NONE for no encryption TLS for Transport Layer Security
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.CreateCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterName, var: cluster_name}, {name: NodeType, var: node_type}, {name: Description, var: description}, {name: ReplicationFactor, var: replication_factor}, {name: AvailabilityZones, var: availability_zones}, {name: SubnetGroupName, var: subnet_group_name}, {name: SecurityGroupIds, var: security_group_ids}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: NotificationTopicArn, var: notification_topic_arn}, {name: IamRoleArn, var: iam_role_arn}, {name: ParameterGroupName, var: parameter_group_name}, {name: Tags, var: tags}, {name: SSESpecification, var: sse_specification}, {name: ClusterEndpointEncryptionType, var: cluster_endpoint_encryption_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_name: $cluster_name, node_type: $node_type, description: $description, replication_factor: $replication_factor, availability_zones: $availability_zones, subnet_group_name: $subnet_group_name, security_group_ids: $security_group_ids, preferred_maintenance_window: $preferred_maintenance_window, notification_topic_arn: $notification_topic_arn, iam_role_arn: $iam_role_arn, parameter_group_name: $parameter_group_name, tags: $tags, sse_specification: $sse_specification, cluster_endpoint_encryption_type: $cluster_endpoint_encryption_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
#
# POST /
# Returns: record<ParameterGroup: record<ParameterGroupName: string, Description: string>>
# operationId: CreateParameterGroup
export def "create-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  parameter_group_name: string # The name of the parameter group to apply to all of the clusters in this replication group.
  --description: string # A description of the parameter group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.CreateParameterGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParameterGroupName, var: parameter_group_name}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parameter_group_name: $parameter_group_name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new subnet group.
#
# POST /
# Returns: record<SubnetGroup: record<SubnetGroupName: string, Description: string, VpcId: string, Subnets: list<record>>>
# operationId: CreateSubnetGroup
export def "create-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subnet_group_name: string # A name for the subnet group. This value is stored as a lowercase string.
  --description: string # A description for the subnet group
  subnet_ids: list<string> # A list of VPC subnet IDs for the subnet group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.CreateSubnetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubnetGroupName, var: subnet_group_name}, {name: Description, var: description}, {name: SubnetIds, var: subnet_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subnet_group_name: $subnet_group_name, description: $description, subnet_ids: $subnet_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more nodes from a DAX cluster. You cannot use DecreaseReplicationFactor to remove the last node in a DAX cluster. If you need to do this, use DeleteCluster instead.
#
# POST /
# Returns: record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>
# operationId: DecreaseReplicationFactor
export def "decrease-replication-factor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cluster_name: string # The name of the DAX cluster from which you want to remove nodes.
  new_replication_factor: int # The new number of nodes for the DAX cluster.
  --availability-zones: list<string> # The Availability Zone(s) from which to remove nodes.
  --node-ids-to-remove: list<string> # The unique identifiers of the nodes to be removed from the cluster.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DecreaseReplicationFactor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterName, var: cluster_name}, {name: NewReplicationFactor, var: new_replication_factor}, {name: AvailabilityZones, var: availability_zones}, {name: NodeIdsToRemove, var: node_ids_to_remove}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_name: $cluster_name, new_replication_factor: $new_replication_factor, availability_zones: $availability_zones, node_ids_to_remove: $node_ids_to_remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously provisioned DAX cluster. DeleteCluster deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
#
# POST /
# Returns: record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>
# operationId: DeleteCluster
export def "delete-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cluster_name: string # The name of the cluster to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DeleteCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterName, var: cluster_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_name: $cluster_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
#
# POST /
# Returns: record<DeletionMessage: string>
# operationId: DeleteParameterGroup
export def "delete-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  parameter_group_name: string # The name of the parameter group to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DeleteParameterGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParameterGroupName, var: parameter_group_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parameter_group_name: $parameter_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subnet group. You cannot delete a subnet group if it is associated with any DAX clusters.
#
# POST /
# Returns: record<DeletionMessage: string>
# operationId: DeleteSubnetGroup
export def "delete-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subnet_group_name: string # The name of the subnet group to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DeleteSubnetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubnetGroupName, var: subnet_group_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subnet_group_name: $subnet_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied. If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned. If the cluster is in the DELETING state, only cluster level information will be displayed. If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is available, the cluster is ready for use. If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.
#
# POST /
# Returns: record<NextToken: string, Clusters: table<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record, NodeIdsToRemove: list, Nodes: list, PreferredMaintenanceWindow: string, NotificationConfiguration: record, SubnetGroup: string, SecurityGroups: list, IamRoleArn: string, ParameterGroup: record, SSEDescription: record, ClusterEndpointEncryptionType: string>>
# operationId: DescribeClusters
export def "describe-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --cluster-names: list<string> # The names of the DAX clusters being described.
  --max-results: int # The maximum number of results to include in the response. If more results exist than the specified MaxResults value, a token is included in the response so that the remaining results can be retrieved. The value for MaxResults must be between 20 and 100.
  --next-token: string # An optional token returned from a prior request. Use this token for pagination of results from this action. If this parameter is specified, the response includes only results beyond the token, up to the value specified by MaxResults.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DescribeClusters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterNames, var: cluster_names}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_names: $cluster_names, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default system parameter information for the DAX caching software.
#
# POST /
# Returns: record<NextToken: string, Parameters: table<ParameterName: string, ParameterType: string, ParameterValue: string, NodeTypeSpecificValues: list, Description: string, Source: string, DataType: string, AllowedValues: string, IsModifiable: string, ChangeType: string>>
# operationId: DescribeDefaultParameters
export def "describe-default-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # The maximum number of results to include in the response. If more results exist than the specified MaxResults value, a token is included in the response so that the remaining results can be retrieved. The value for MaxResults must be between 20 and 100.
  --next-token: string # An optional token returned from a prior request. Use this token for pagination of results from this action. If this parameter is specified, the response includes only results beyond the token, up to the value specified by MaxResults.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DescribeDefaultParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter. By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.
#
# POST /
# Returns: record<NextToken: string, Events: table<SourceName: string, SourceType: string, Message: string, Date: string>>
# operationId: DescribeEvents
export def "describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --source-name: string # The identifier of the event source for which events will be returned. If not specified, then all sources are included in the response.
  --source-type: string@source-type-completer # The event source to retrieve events for. If no value is specified, all events are returned.
  --start-time: string # The beginning of the time interval to retrieve events for, specified in ISO 8601 format. (format: date-time)
  --end-time: string # The end of the time interval for which to retrieve events, specified in ISO 8601 format. (format: date-time)
  --duration: int # The number of minutes' worth of events to retrieve.
  --max-results: int # The maximum number of results to include in the response. If more results exist than the specified MaxResults value, a token is included in the response so that the remaining results can be retrieved. The value for MaxResults must be between 20 and 100.
  --next-token: string # An optional token returned from a prior request. Use this token for pagination of results from this action. If this parameter is specified, the response includes only results beyond the token, up to the value specified by MaxResults.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DescribeEvents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceName, var: source_name}, {name: SourceType, var: source_type}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: Duration, var: duration}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_name: $source_name, source_type: $source_type, start_time: $start_time, end_time: $end_time, duration: $duration, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
#
# POST /
# Returns: record<NextToken: string, ParameterGroups: table<ParameterGroupName: string, Description: string>>
# operationId: DescribeParameterGroups
export def "describe-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --parameter-group-names: list<string> # The names of the parameter groups.
  --max-results: int # The maximum number of results to include in the response. If more results exist than the specified MaxResults value, a token is included in the response so that the remaining results can be retrieved. The value for MaxResults must be between 20 and 100.
  --next-token: string # An optional token returned from a prior request. Use this token for pagination of results from this action. If this parameter is specified, the response includes only results beyond the token, up to the value specified by MaxResults.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DescribeParameterGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParameterGroupNames, var: parameter_group_names}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parameter_group_names: $parameter_group_names, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the detailed parameter list for a particular parameter group.
#
# POST /
# Returns: record<NextToken: string, Parameters: table<ParameterName: string, ParameterType: string, ParameterValue: string, NodeTypeSpecificValues: list, Description: string, Source: string, DataType: string, AllowedValues: string, IsModifiable: string, ChangeType: string>>
# operationId: DescribeParameters
export def "describe-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  parameter_group_name: string # The name of the parameter group.
  --source: string # How the parameter is defined. For example, system denotes a system-defined parameter.
  --max-results: int # The maximum number of results to include in the response. If more results exist than the specified MaxResults value, a token is included in the response so that the remaining results can be retrieved. The value for MaxResults must be between 20 and 100.
  --next-token: string # An optional token returned from a prior request. Use this token for pagination of results from this action. If this parameter is specified, the response includes only results beyond the token, up to the value specified by MaxResults.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DescribeParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParameterGroupName, var: parameter_group_name}, {name: Source, var: source}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parameter_group_name: $parameter_group_name, source: $source, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
#
# POST /
# Returns: record<NextToken: string, SubnetGroups: table<SubnetGroupName: string, Description: string, VpcId: string, Subnets: list>>
# operationId: DescribeSubnetGroups
export def "describe-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --subnet-group-names: list<string> # The name of the subnet group.
  --max-results: int # The maximum number of results to include in the response. If more results exist than the specified MaxResults value, a token is included in the response so that the remaining results can be retrieved. The value for MaxResults must be between 20 and 100.
  --next-token: string # An optional token returned from a prior request. Use this token for pagination of results from this action. If this parameter is specified, the response includes only results beyond the token, up to the value specified by MaxResults.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.DescribeSubnetGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubnetGroupNames, var: subnet_group_names}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subnet_group_names: $subnet_group_names, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more nodes to a DAX cluster.
#
# POST /
# Returns: record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>
# operationId: IncreaseReplicationFactor
export def "increase-replication-factor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cluster_name: string # The name of the DAX cluster that will receive additional nodes.
  new_replication_factor: int # The new number of nodes for the DAX cluster.
  --availability-zones: list<string> # The Availability Zones (AZs) in which the cluster nodes will be created. All nodes belonging to the cluster are placed in these Availability Zones. Use this parameter if you want to distribute the nodes across multiple AZs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.IncreaseReplicationFactor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterName, var: cluster_name}, {name: NewReplicationFactor, var: new_replication_factor}, {name: AvailabilityZones, var: availability_zones}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_name: $cluster_name, new_replication_factor: $new_replication_factor, availability_zones: $availability_zones
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all of the tags for a DAX cluster. You can call ListTags up to 10 times per second, per account.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>, NextToken: string>
# operationId: ListTags
export def "list-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_name: string # The name of the DAX resource to which the tags belong.
  --next-token: string # An optional token returned from a prior request. Use this token for pagination of results from this action. If this parameter is specified, the response includes only results beyond the token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.ListTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceName, var: resource_name}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING. RebootNode restarts the DAX engine process and does not remove the contents of the cache.
#
# POST /
# Returns: record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>
# operationId: RebootNode
export def "reboot-node" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cluster_name: string # The name of the DAX cluster containing the node to be rebooted.
  node_id: string # The system-assigned ID of the node to be rebooted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.RebootNode"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterName, var: cluster_name}, {name: NodeId, var: node_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_name: $cluster_name, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a set of tags with a DAX resource. You can call TagResource up to 5 times per second, per account.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>>
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  resource_name: string # The name of the DAX resource to which tags should be added.
  tags: list # The tags to be assigned to the DAX resource. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceName, var: resource_name}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the association of tags from a DAX resource. You can call UntagResource up to 5 times per second, per account.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>>
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  resource_name: string # The name of the DAX resource from which the tags should be removed.
  tag_keys: list<string> # A list of tag keys. If the DAX cluster has any tags with these keys, then the tags are removed from the cluster.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceName, var: resource_name}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
#
# POST /
# Returns: record<Cluster: record<ClusterName: string, Description: string, ClusterArn: string, TotalNodes: int, ActiveNodes: int, NodeType: string, Status: string, ClusterDiscoveryEndpoint: record<Address: string, Port: int, URL: string>, NodeIdsToRemove: list<string>, Nodes: list<record>, PreferredMaintenanceWindow: string, NotificationConfiguration: record<TopicArn: string, TopicStatus: string>, SubnetGroup: string, SecurityGroups: list<record>, IamRoleArn: string, ParameterGroup: record<ParameterGroupName: string, ParameterApplyStatus: string, NodeIdsToReboot: list>, SSEDescription: record<Status: string>, ClusterEndpointEncryptionType: string>>
# operationId: UpdateCluster
export def "update-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cluster_name: string # The name of the DAX cluster to be modified.
  --description: string # A description of the changes being made to the cluster.
  --preferred-maintenance-window: string # A range of time when maintenance of DAX cluster software will be performed. For example: sun:01:00-sun:09:00. Cluster maintenance normally takes less than 30 minutes, and is performed automatically within the maintenance window.
  --notification-topic-arn: string # The Amazon Resource Name (ARN) that identifies the topic.
  --notification-topic-status: string # The current state of the topic. A value of “active” means that notifications will be sent to the topic. A value of “inactive” means that notifications will not be sent to the topic.
  --parameter-group-name: string # The name of a parameter group for this cluster.
  --security-group-ids: list<string> # A list of user-specified security group IDs to be assigned to each node in the DAX cluster. If this parameter is not specified, DAX assigns the default VPC security group to each node.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.UpdateCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterName, var: cluster_name}, {name: Description, var: description}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: NotificationTopicArn, var: notification_topic_arn}, {name: NotificationTopicStatus, var: notification_topic_status}, {name: ParameterGroupName, var: parameter_group_name}, {name: SecurityGroupIds, var: security_group_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_name: $cluster_name, description: $description, preferred_maintenance_window: $preferred_maintenance_window, notification_topic_arn: $notification_topic_arn, notification_topic_status: $notification_topic_status, parameter_group_name: $parameter_group_name, security_group_ids: $security_group_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
#
# POST /
# Returns: record<ParameterGroup: record<ParameterGroupName: string, Description: string>>
# operationId: UpdateParameterGroup
export def "update-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  parameter_group_name: string # The name of the parameter group.
  parameter_name_values: list # An array of name-value pairs for the parameters in the group. Each element in the array represents a single parameter. record-ttl-millis and query-ttl-millis are the only supported parameter names. For more details, see Configuring TTL Settings (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.cluster-management.html#DAX.cluster-management.custom-settings.ttl). — item shape: {ParameterName?: string, ParameterValue?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.UpdateParameterGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParameterGroupName, var: parameter_group_name}, {name: ParameterNameValues, var: parameter_name_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parameter_group_name: $parameter_group_name, parameter_name_values: $parameter_name_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing subnet group.
#
# POST /
# Returns: record<SubnetGroup: record<SubnetGroupName: string, Description: string, VpcId: string, Subnets: list<record>>>
# operationId: UpdateSubnetGroup
export def "update-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subnet_group_name: string # The name of the subnet group.
  --description: string # A description of the subnet group.
  --subnet-ids: list<string> # A list of subnet IDs in the subnet group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDAXV3.UpdateSubnetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubnetGroupName, var: subnet_group_name}, {name: Description, var: description}, {name: SubnetIds, var: subnet_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subnet_group_name: $subnet_group_name, description: $description, subnet_ids: $subnet_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
