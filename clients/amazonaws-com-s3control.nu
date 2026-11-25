# Auto-generated client for AWS S3 Control v2018-08-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/s3control/2018-08-20/openapi.json
# Auth: --token flag or $env.AWS_S3_CONTROL_TOKEN

const CLIENT = {
  base_url: "http://s3-control.us-east-1.amazonaws.com"
  token_env_var: "AWS_S3_CONTROL_TOKEN"
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

def base-url-completer [] { ["http://s3-control.us-east-1.amazonaws.com" "http://s3-control.us-east-2.amazonaws.com" "http://s3-control.us-west-1.amazonaws.com" "http://s3-control.us-west-2.amazonaws.com" "http://s3-control.us-gov-west-1.amazonaws.com" "http://s3-control.us-gov-east-1.amazonaws.com" "http://s3-control.ca-central-1.amazonaws.com" "http://s3-control.eu-north-1.amazonaws.com" "http://s3-control.eu-west-1.amazonaws.com" "http://s3-control.eu-west-2.amazonaws.com" "http://s3-control.eu-west-3.amazonaws.com" "http://s3-control.eu-central-1.amazonaws.com" "http://s3-control.eu-south-1.amazonaws.com" "http://s3-control.af-south-1.amazonaws.com" "http://s3-control.ap-northeast-1.amazonaws.com" "http://s3-control.ap-northeast-2.amazonaws.com" "http://s3-control.ap-northeast-3.amazonaws.com" "http://s3-control.ap-southeast-1.amazonaws.com" "http://s3-control.ap-southeast-2.amazonaws.com" "http://s3-control.ap-east-1.amazonaws.com" "http://s3-control.ap-south-1.amazonaws.com" "http://s3-control.sa-east-1.amazonaws.com" "http://s3-control.me-south-1.amazonaws.com" "https://s3-control.us-east-1.amazonaws.com" "https://s3-control.us-east-2.amazonaws.com" "https://s3-control.us-west-1.amazonaws.com" "https://s3-control.us-west-2.amazonaws.com" "https://s3-control.us-gov-west-1.amazonaws.com" "https://s3-control.us-gov-east-1.amazonaws.com" "https://s3-control.ca-central-1.amazonaws.com" "https://s3-control.eu-north-1.amazonaws.com" "https://s3-control.eu-west-1.amazonaws.com" "https://s3-control.eu-west-2.amazonaws.com" "https://s3-control.eu-west-3.amazonaws.com" "https://s3-control.eu-central-1.amazonaws.com" "https://s3-control.eu-south-1.amazonaws.com" "https://s3-control.af-south-1.amazonaws.com" "https://s3-control.ap-northeast-1.amazonaws.com" "https://s3-control.ap-northeast-2.amazonaws.com" "https://s3-control.ap-northeast-3.amazonaws.com" "https://s3-control.ap-southeast-1.amazonaws.com" "https://s3-control.ap-southeast-2.amazonaws.com" "https://s3-control.ap-east-1.amazonaws.com" "https://s3-control.ap-south-1.amazonaws.com" "https://s3-control.sa-east-1.amazonaws.com" "https://s3-control.me-south-1.amazonaws.com" "http://s3-control.cn-north-1.amazonaws.com.cn" "http://s3-control.cn-northwest-1.amazonaws.com.cn" "https://s3-control.cn-north-1.amazonaws.com.cn" "https://s3-control.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-acl-completer [] { ["authenticated-read" "private" "public-read" "public-read-write"] }
def requested-job-status-completer [] { ["Cancelled" "Ready"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-access-point" "delete-access-point" "get-access-point" "create-access-point-for-object-lambda" "delete-access-point-for-object-lambda" "get-access-point-for-object-lambda" "create-bucket" "create-job" "list-jobs" "create-multi-region-access-point" "delete-access-point-policy" "get-access-point-policy" "put-access-point-policy" "delete-access-point-policy-for-object-lambda" "get-access-point-policy-for-object-lambda" "put-access-point-policy-for-object-lambda" "delete-bucket" "get-bucket" "delete-bucket-lifecycle-configuration" "get-bucket-lifecycle-configuration" "put-bucket-lifecycle-configuration" "delete-bucket-policy" "get-bucket-policy" "put-bucket-policy" "delete-bucket-replication" "get-bucket-replication" "put-bucket-replication" "delete-bucket-tagging" "get-bucket-tagging" "put-bucket-tagging" "delete-job-tagging" "get-job-tagging" "put-job-tagging" "delete-multi-region-access-point" "delete-public-access-block" "get-public-access-block" "put-public-access-block" "delete-storage-lens-configuration" "get-storage-lens-configuration" "put-storage-lens-configuration" "delete-storage-lens-configuration-tagging" "get-storage-lens-configuration-tagging" "put-storage-lens-configuration-tagging" "describe-job" "describe-multi-region-access-point-operation" "get-access-point-configuration-for-object-lambda" "put-access-point-configuration-for-object-lambda" "get-access-point-policy-status" "get-access-point-policy-status-for-object-lambda" "get-bucket-versioning" "put-bucket-versioning" "get-multi-region-access-point" "get-multi-region-access-point-policy" "get-multi-region-access-point-policy-status" "get-multi-region-access-point-routes" "submit-multi-region-access-point-routes" "list-access-points" "list-access-points-for-object-lambda" "list-multi-region-access-points" "list-regional-buckets" "list-storage-lens-configurations" "put-multi-region-access-point-policy" "update-job-priority" "update-job-status" "commands"] | sort) } | get name | first)
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

# Creates an access point and associates it with the specified bucket. For more information, see Managing Data Access with Amazon S3 Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html) in the Amazon S3 User Guide. S3 on Outposts only supports VPC-style access points. For more information, see Accessing Amazon S3 on Outposts using virtual private cloud (VPC) only access points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html#API_control_CreateAccessPoint_Examples) section. The following actions are related to CreateAccessPoint: GetAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html) DeleteAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html) ListAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPoints.html)
#
# PUT /v20180820/accesspoint/{name}
# operationId: CreateAccessPoint
export def "create-access-point" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/accesspoint/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html#API_control_DeleteAccessPoint_Examples) section. The following actions are related to DeleteAccessPoint: CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) GetAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html) ListAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPoints.html)
#
# DELETE /v20180820/accesspoint/{name}
# operationId: DeleteAccessPoint
export def "delete-access-point" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access point. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/accesspoint/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns configuration information about the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html#API_control_GetAccessPoint_Examples) section. The following actions are related to GetAccessPoint: CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) DeleteAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html) ListAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPoints.html)
#
# GET /v20180820/accesspoint/{name}
# operationId: GetAccessPoint
export def "get-access-point" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspoint/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Object Lambda Access Point. For more information, see Transforming objects with Object Lambda Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/transforming-objects.html) in the Amazon S3 User Guide. The following actions are related to CreateAccessPointForObjectLambda: DeleteAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointForObjectLambda.html) GetAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointForObjectLambda.html) ListAccessPointsForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPointsForObjectLambda.html)
#
# PUT /v20180820/accesspointforobjectlambda/{name}
# operationId: CreateAccessPointForObjectLambda
export def "create-access-point-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for owner of the specified Object Lambda Access Point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/accesspointforobjectlambda/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Object Lambda Access Point. The following actions are related to DeleteAccessPointForObjectLambda: CreateAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPointForObjectLambda.html) GetAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointForObjectLambda.html) ListAccessPointsForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPointsForObjectLambda.html)
#
# DELETE /v20180820/accesspointforobjectlambda/{name}
# operationId: DeleteAccessPointForObjectLambda
export def "delete-access-point-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/accesspointforobjectlambda/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns configuration information about the specified Object Lambda Access Point The following actions are related to GetAccessPointForObjectLambda: CreateAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPointForObjectLambda.html) DeleteAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointForObjectLambda.html) ListAccessPointsForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListAccessPointsForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda/{name}
# operationId: GetAccessPointForObjectLambda
export def "get-access-point-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspointforobjectlambda/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action creates an Amazon S3 on Outposts bucket. To create an S3 bucket, see Create Bucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html) in the Amazon S3 API Reference. Creates a new Outposts bucket. By creating the bucket, you become the bucket owner. To create an Outposts bucket, you must have S3 on Outposts. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. Not every string is an acceptable bucket name. For information on bucket naming restrictions, see Working with Amazon S3 Buckets (https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html#bucketnamingrules). S3 on Outposts buckets support: Tags LifecycleConfigurations for deleting expired objects For a complete list of restrictions and Amazon S3 feature limitations on S3 on Outposts, see Amazon S3 on Outposts Restrictions and Limitations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OnOutpostsRestrictionsLimitations.html). For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and x-amz-outpost-id in your API request, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html#API_control_CreateBucket_Examples) section. The following actions are related to CreateBucket for Amazon S3 on Outposts: PutObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html) GetBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucket.html) DeleteBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucket.html) CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) PutAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html)
#
# PUT /v20180820/bucket/{name}
# operationId: CreateBucket
export def "create-bucket" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-acl: string@x-amz-acl-completer # The canned ACL to apply to the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-full-control: string # Allows grantee the read, write, read ACP, and write ACP permissions on the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-read: string # Allows grantee to list the objects in the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-read-acp: string # Allows grantee to read the bucket ACL. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-write: string # Allows grantee to create, overwrite, and delete any object in the bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-grant-write-acp: string # Allows grantee to write the ACL for the applicable bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-bucket-object-lock-enabled: oneof<nothing, bool> # Specifies whether you want S3 Object Lock to be enabled for the new bucket. This is not supported by Amazon S3 on Outposts buckets.
  --x-amz-outpost-id: string # The ID of the Outposts where the bucket is being created. This ID is required by Amazon S3 on Outposts buckets.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/bucket/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-acl, var: x_amz_acl}, {name: x-amz-grant-full-control, var: x_amz_grant_full_control}, {name: x-amz-grant-read, var: x_amz_grant_read}, {name: x-amz-grant-read-acp, var: x_amz_grant_read_acp}, {name: x-amz-grant-write, var: x_amz_grant_write}, {name: x-amz-grant-write-acp, var: x_amz_grant_write_acp}, {name: x-amz-bucket-object-lock-enabled, var: x_amz_bucket_object_lock_enabled}, {name: x-amz-outpost-id, var: x_amz_outpost_id}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_acl: $x_amz_acl, x_amz_grant_full_control: $x_amz_grant_full_control, x_amz_grant_read: $x_amz_grant_read, x_amz_grant_read_acp: $x_amz_grant_read_acp, x_amz_grant_write: $x_amz_grant_write, x_amz_grant_write_acp: $x_amz_grant_write_acp, x_amz_bucket_object_lock_enabled: $x_amz_bucket_object_lock_enabled, x_amz_outpost_id: $x_amz_outpost_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# You can use S3 Batch Operations to perform large-scale batch actions on Amazon S3 objects. Batch Operations can run a single action on lists of Amazon S3 objects that you specify. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. This action creates a S3 Batch Operations job. Related actions include: DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) UpdateJobPriority (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobPriority.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html) JobOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_JobOperation.html)
#
# POST /v20180820/jobs
# operationId: CreateJob
export def "create-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID that creates the job. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/v20180820/jobs"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists current S3 Batch Operations jobs and jobs that have ended within the last 30 days for the Amazon Web Services account making the request. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) UpdateJobPriority (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobPriority.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# GET /v20180820/jobs
# operationId: ListJobs
export def "list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-statuses: list<string> # The List Jobs request returns jobs that match the statuses listed in this element.
  --next-token: string # A pagination token to request the next page of results. Use the token that Amazon S3 returned in the NextToken element of the ListJobsResult from the previous List Jobs request.
  --max-results: int # The maximum number of jobs that Amazon S3 will include in the List Jobs response. If there are more jobs than this number, the response will include a pagination token in the NextToken field to enable you to retrieve the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/jobs"
    query: [{name: jobStatuses, var: job_statuses, style: multi}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    job_statuses: $job_statuses, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Multi-Region Access Point and associates it with the specified buckets. For more information about creating Multi-Region Access Points, see Creating Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/CreatingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. This request is asynchronous, meaning that you might receive a response before the command has completed. When this request provides a response, it provides a token that you can use to monitor the status of the request with DescribeMultiRegionAccessPointOperation. The following actions are related to CreateMultiRegionAccessPoint: DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# POST /v20180820/async-requests/mrap/create
# operationId: CreateMultiRegionAccessPoint
export def "create-multi-region-access-point" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. The owner of the Multi-Region Access Point also must own the underlying buckets. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/v20180820/async-requests/mrap/create"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the access point policy for the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicy.html#API_control_DeleteAccessPointPolicy_Examples) section. The following actions are related to DeleteAccessPointPolicy: PutAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html) GetAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicy.html)
#
# DELETE /v20180820/accesspoint/{name}/policy
# operationId: DeleteAccessPointPolicy
export def "delete-access-point-policy" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified access point. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/accesspoint/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the access point policy associated with the specified access point. The following actions are related to GetAccessPointPolicy: PutAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html) DeleteAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicy.html)
#
# GET /v20180820/accesspoint/{name}/policy
# operationId: GetAccessPointPolicy
export def "get-access-point-policy" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified access point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspoint/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicy.html#API_control_PutAccessPointPolicy_Examples) section. The following actions are related to PutAccessPointPolicy: GetAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicy.html) DeleteAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicy.html)
#
# PUT /v20180820/accesspoint/{name}/policy
# operationId: PutAccessPointPolicy
export def "put-access-point-policy" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for owner of the bucket associated with the specified access point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/accesspoint/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the resource policy for an Object Lambda Access Point. The following actions are related to DeleteAccessPointPolicyForObjectLambda: GetAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicyForObjectLambda.html) PutAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicyForObjectLambda.html)
#
# DELETE /v20180820/accesspointforobjectlambda/{name}/policy
# operationId: DeleteAccessPointPolicyForObjectLambda
export def "delete-access-point-policy-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/accesspointforobjectlambda/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the resource policy for an Object Lambda Access Point. The following actions are related to GetAccessPointPolicyForObjectLambda: DeleteAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicyForObjectLambda.html) PutAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointPolicyForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda/{name}/policy
# operationId: GetAccessPointPolicyForObjectLambda
export def "get-access-point-policy-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspointforobjectlambda/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or replaces resource policy for an Object Lambda Access Point. For an example policy, see Creating Object Lambda Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/olap-create.html#olap-create-cli) in the Amazon S3 User Guide. The following actions are related to PutAccessPointPolicyForObjectLambda: DeleteAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointPolicyForObjectLambda.html) GetAccessPointPolicyForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointPolicyForObjectLambda.html)
#
# PUT /v20180820/accesspointforobjectlambda/{name}/policy
# operationId: PutAccessPointPolicyForObjectLambda
export def "put-access-point-policy-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/accesspointforobjectlambda/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action deletes an Amazon S3 on Outposts bucket. To delete an S3 bucket, see DeleteBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html) in the Amazon S3 API Reference. Deletes the Amazon S3 on Outposts bucket. All objects (including all object versions and delete markers) in the bucket must be deleted before the bucket itself can be deleted. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucket.html#API_control_DeleteBucket_Examples) section. Related Resources CreateBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html) GetBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucket.html) DeleteObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html)
#
# DELETE /v20180820/bucket/{name}
# operationId: DeleteBucket
export def "delete-bucket" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID that owns the Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/bucket/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Amazon S3 on Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. If you are using an identity other than the root user of the Amazon Web Services account that owns the Outposts bucket, the calling identity must have the s3-outposts:GetBucket permissions on the specified Outposts bucket and belong to the Outposts bucket owner's account in order to use this action. Only users from Outposts bucket owner account with the right permissions can perform actions on an Outposts bucket. If you don't have s3-outposts:GetBucket permissions or you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 403 Access Denied error. The following actions are related to GetBucket for Amazon S3 on Outposts: All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucket.html#API_control_GetBucket_Examples) section. PutObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html) CreateBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html) DeleteBucket (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucket.html)
#
# GET /v20180820/bucket/{name}
# operationId: GetBucket
export def "get-bucket" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/bucket/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action deletes an Amazon S3 on Outposts bucket's lifecycle configuration. To delete an S3 bucket's lifecycle configuration, see DeleteBucketLifecycle (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html) in the Amazon S3 API Reference. Deletes the lifecycle configuration from the specified Outposts bucket. Amazon S3 on Outposts removes all the lifecycle configuration rules in the lifecycle subresource associated with the bucket. Your objects never expire, and Amazon S3 on Outposts no longer automatically deletes any objects on the basis of rules contained in the deleted lifecycle configuration. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. To use this action, you must have permission to perform the s3-outposts:DeleteLifecycleConfiguration action. By default, the bucket owner has this permission and the Outposts bucket owner can grant this permission to others. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketLifecycleConfiguration.html#API_control_DeleteBucketLifecycleConfiguration_Examples) section. For more information about object expiration, see Elements to Describe Lifecycle Actions (https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#intro-lifecycle-rules-actions). Related actions include: PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html)
#
# DELETE /v20180820/bucket/{name}/lifecycleconfiguration
# operationId: DeleteBucketLifecycleConfiguration
export def "delete-bucket-lifecycle-configuration" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the lifecycle configuration to delete. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/bucket/{name}/lifecycleconfiguration"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action gets an Amazon S3 on Outposts bucket's lifecycle configuration. To get an S3 bucket's lifecycle configuration, see GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html) in the Amazon S3 API Reference. Returns the lifecycle configuration information set on the Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) and for information about lifecycle configuration, see Object Lifecycle Management (https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html) in Amazon S3 User Guide. To use this action, you must have permission to perform the s3-outposts:GetLifecycleConfiguration action. The Outposts bucket owner has this permission, by default. The bucket owner can grant this permission to others. For more information about permissions, see Permissions Related to Bucket Subresource Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources) and Managing Access Permissions to Your Amazon S3 Resources (https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html#API_control_GetBucketLifecycleConfiguration_Examples) section. GetBucketLifecycleConfiguration has the following special error: Error code: NoSuchLifecycleConfiguration Description: The lifecycle configuration does not exist. HTTP Status Code: 404 Not Found SOAP Fault Code Prefix: Client The following actions are related to GetBucketLifecycleConfiguration: PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) DeleteBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketLifecycleConfiguration.html)
#
# GET /v20180820/bucket/{name}/lifecycleconfiguration
# operationId: GetBucketLifecycleConfiguration
export def "get-bucket-lifecycle-configuration" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/bucket/{name}/lifecycleconfiguration"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action puts a lifecycle configuration to an Amazon S3 on Outposts bucket. To put a lifecycle configuration to an S3 bucket, see PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html) in the Amazon S3 API Reference. Creates a new lifecycle configuration for the S3 on Outposts bucket or replaces an existing lifecycle configuration. Outposts buckets only support lifecycle configurations that delete/expire objects after a certain period of time and abort incomplete multipart uploads. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html#API_control_PutBucketLifecycleConfiguration_Examples) section. The following actions are related to PutBucketLifecycleConfiguration: GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html) DeleteBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketLifecycleConfiguration.html)
#
# PUT /v20180820/bucket/{name}/lifecycleconfiguration
# operationId: PutBucketLifecycleConfiguration
export def "put-bucket-lifecycle-configuration" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/bucket/{name}/lifecycleconfiguration"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action deletes an Amazon S3 on Outposts bucket policy. To delete an S3 bucket policy, see DeleteBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketPolicy.html) in the Amazon S3 API Reference. This implementation of the DELETE action uses the policy subresource to delete the policy of a specified Amazon S3 on Outposts bucket. If you are using an identity other than the root user of the Amazon Web Services account that owns the bucket, the calling identity must have the s3-outposts:DeleteBucketPolicy permissions on the specified Outposts bucket and belong to the bucket owner's account to use this action. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. If you don't have DeleteBucketPolicy permissions, Amazon S3 returns a 403 Access Denied error. If you have the correct permissions, but you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 405 Method Not Allowed error. As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this action, even if the policy explicitly denies the root user the ability to perform this action. For more information about bucket policies, see Using Bucket Policies and User Policies (https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketPolicy.html#API_control_DeleteBucketPolicy_Examples) section. The following actions are related to DeleteBucketPolicy: GetBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketPolicy.html) PutBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketPolicy.html)
#
# DELETE /v20180820/bucket/{name}/policy
# operationId: DeleteBucketPolicy
export def "delete-bucket-policy" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/bucket/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action gets a bucket policy for an Amazon S3 on Outposts bucket. To get a policy for an S3 bucket, see GetBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicy.html) in the Amazon S3 API Reference. Returns the policy of a specified Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. If you are using an identity other than the root user of the Amazon Web Services account that owns the bucket, the calling identity must have the GetBucketPolicy permissions on the specified bucket and belong to the bucket owner's account in order to use this action. Only users from Outposts bucket owner account with the right permissions can perform actions on an Outposts bucket. If you don't have s3-outposts:GetBucketPolicy permissions or you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 403 Access Denied error. As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this action, even if the policy explicitly denies the root user the ability to perform this action. For more information about bucket policies, see Using Bucket Policies and User Policies (https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketPolicy.html#API_control_GetBucketPolicy_Examples) section. The following actions are related to GetBucketPolicy: GetObject (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html) PutBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketPolicy.html) DeleteBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketPolicy.html)
#
# GET /v20180820/bucket/{name}/policy
# operationId: GetBucketPolicy
export def "get-bucket-policy" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/bucket/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action puts a bucket policy to an Amazon S3 on Outposts bucket. To put a policy on an S3 bucket, see PutBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketPolicy.html) in the Amazon S3 API Reference. Applies an Amazon S3 bucket policy to an Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. If you are using an identity other than the root user of the Amazon Web Services account that owns the Outposts bucket, the calling identity must have the PutBucketPolicy permissions on the specified Outposts bucket and belong to the bucket owner's account in order to use this action. If you don't have PutBucketPolicy permissions, Amazon S3 returns a 403 Access Denied error. If you have the correct permissions, but you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a 405 Method Not Allowed error. As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this action, even if the policy explicitly denies the root user the ability to perform this action. For more information about bucket policies, see Using Bucket Policies and User Policies (https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketPolicy.html#API_control_PutBucketPolicy_Examples) section. The following actions are related to PutBucketPolicy: GetBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketPolicy.html) DeleteBucketPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketPolicy.html)
#
# PUT /v20180820/bucket/{name}/policy
# operationId: PutBucketPolicy
export def "put-bucket-policy" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
  --x-amz-confirm-remove-self-bucket-access: oneof<nothing, bool> # Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future. This is not supported by Amazon S3 on Outposts buckets.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/bucket/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}, {name: x-amz-confirm-remove-self-bucket-access, var: x_amz_confirm_remove_self_bucket_access}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, x_amz_confirm_remove_self_bucket_access: $x_amz_confirm_remove_self_bucket_access, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation deletes an Amazon S3 on Outposts bucket's replication configuration. To delete an S3 bucket's replication configuration, see DeleteBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html) in the Amazon S3 API Reference. Deletes the replication configuration from the specified S3 on Outposts bucket. To use this operation, you must have permissions to perform the s3-outposts:PutReplicationConfiguration action. The Outposts bucket owner has this permission by default and can grant it to others. For more information about permissions, see Setting up IAM with S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsIAM.html) and Managing access to S3 on Outposts buckets (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsBucketPolicy.html) in the Amazon S3 User Guide. It can take a while to propagate PUT or DELETE requests for a replication configuration to all S3 on Outposts systems. Therefore, the replication configuration that's returned by a GET request soon after a PUT or DELETE request might return a more recent result than what's on the Outpost. If an Outpost is offline, the delay in updating the replication configuration on that Outpost can be significant. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketReplication.html#API_control_DeleteBucketReplication_Examples) section. For information about S3 replication on Outposts configuration, see Replicating objects for S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsReplication.html) in the Amazon S3 User Guide. The following operations are related to DeleteBucketReplication: PutBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketReplication.html) GetBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketReplication.html)
#
# DELETE /v20180820/bucket/{name}/replication
# operationId: DeleteBucketReplication
export def "delete-bucket-replication" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket to delete the replication configuration for. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/bucket/{name}/replication"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation gets an Amazon S3 on Outposts bucket's replication configuration. To get an S3 bucket's replication configuration, see GetBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html) in the Amazon S3 API Reference. Returns the replication configuration of an S3 on Outposts bucket. For more information about S3 on Outposts, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. For information about S3 replication on Outposts configuration, see Replicating objects for S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsReplication.html) in the Amazon S3 User Guide. It can take a while to propagate PUT or DELETE requests for a replication configuration to all S3 on Outposts systems. Therefore, the replication configuration that's returned by a GET request soon after a PUT or DELETE request might return a more recent result than what's on the Outpost. If an Outpost is offline, the delay in updating the replication configuration on that Outpost can be significant. This action requires permissions for the s3-outposts:GetReplicationConfiguration action. The Outposts bucket owner has this permission by default and can grant it to others. For more information about permissions, see Setting up IAM with S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsIAM.html) and Managing access to S3 on Outposts bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsBucketPolicy.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketReplication.html#API_control_GetBucketReplication_Examples) section. If you include the Filter element in a replication configuration, you must also include the DeleteMarkerReplication, Status, and Priority elements. The response also returns those elements. For information about S3 on Outposts replication failure reasons, see Replication failure reasons (https://docs.aws.amazon.com/AmazonS3/latest/userguide/outposts-replication-eventbridge.html#outposts-replication-failure-codes) in the Amazon S3 User Guide. The following operations are related to GetBucketReplication: PutBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketReplication.html) DeleteBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketReplication.html)
#
# GET /v20180820/bucket/{name}/replication
# operationId: GetBucketReplication
export def "get-bucket-replication" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/bucket/{name}/replication"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action creates an Amazon S3 on Outposts bucket's replication configuration. To create an S3 bucket's replication configuration, see PutBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplication.html) in the Amazon S3 API Reference. Creates a replication configuration or replaces an existing one. For information about S3 replication on Outposts configuration, see Replicating objects for S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsReplication.html) in the Amazon S3 User Guide. It can take a while to propagate PUT or DELETE requests for a replication configuration to all S3 on Outposts systems. Therefore, the replication configuration that's returned by a GET request soon after a PUT or DELETE request might return a more recent result than what's on the Outpost. If an Outpost is offline, the delay in updating the replication configuration on that Outpost can be significant. Specify the replication configuration in the request body. In the replication configuration, you provide the following information: The name of the destination bucket or buckets where you want S3 on Outposts to replicate objects The Identity and Access Management (IAM) role that S3 on Outposts can assume to replicate objects on your behalf Other relevant information, such as replication rules A replication configuration must include at least one rule and can contain a maximum of 100. Each rule identifies a subset of objects to replicate by filtering the objects in the source Outposts bucket. To choose additional subsets of objects to replicate, add a rule for each subset. To specify a subset of the objects in the source Outposts bucket to apply a replication rule to, add the Filter element as a child of the Rule element. You can filter objects based on an object key prefix, one or more object tags, or both. When you add the Filter element in the configuration, you must also add the following elements: DeleteMarkerReplication, Status, and Priority. Using PutBucketReplication on Outposts requires that both the source and destination buckets must have versioning enabled. For information about enabling versioning on a bucket, see Managing S3 Versioning for your S3 on Outposts bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsManagingVersioning.html). For information about S3 on Outposts replication failure reasons, see Replication failure reasons (https://docs.aws.amazon.com/AmazonS3/latest/userguide/outposts-replication-eventbridge.html#outposts-replication-failure-codes) in the Amazon S3 User Guide. Handling Replication of Encrypted Objects Outposts buckets are encrypted at all times. All the objects in the source Outposts bucket are encrypted and can be replicated. Also, all the replicas in the destination Outposts bucket are encrypted with the same encryption key as the objects in the source Outposts bucket. Permissions To create a PutBucketReplication request, you must have s3-outposts:PutReplicationConfiguration permissions for the bucket. The Outposts bucket owner has this permission by default and can grant it to others. For more information about permissions, see Setting up IAM with S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsIAM.html) and Managing access to S3 on Outposts buckets (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsBucketPolicy.html). To perform this operation, the user or role must also have the iam:CreateRole and iam:PassRole permissions. For more information, see Granting a user permissions to pass a role to an Amazon Web Services service (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html). All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketReplication.html#API_control_PutBucketReplication_Examples) section. The following operations are related to PutBucketReplication: GetBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketReplication.html) DeleteBucketReplication (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketReplication.html)
#
# PUT /v20180820/bucket/{name}/replication
# operationId: PutBucketReplication
export def "put-bucket-replication" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/bucket/{name}/replication"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action deletes an Amazon S3 on Outposts bucket's tags. To delete an S3 bucket tags, see DeleteBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html) in the Amazon S3 API Reference. Deletes the tags from the Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in Amazon S3 User Guide. To use this action, you must have permission to perform the PutBucketTagging action. By default, the bucket owner has this permission and can grant this permission to others. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketTagging.html#API_control_DeleteBucketTagging_Examples) section. The following actions are related to DeleteBucketTagging: GetBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketTagging.html) PutBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketTagging.html)
#
# DELETE /v20180820/bucket/{name}/tagging
# operationId: DeleteBucketTagging
export def "delete-bucket-tagging" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket tag set to be removed. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/bucket/{name}/tagging"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action gets an Amazon S3 on Outposts bucket's tags. To get an S3 bucket tags, see GetBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html) in the Amazon S3 API Reference. Returns the tag set associated with the Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the GetBucketTagging action. By default, the bucket owner has this permission and can grant this permission to others. GetBucketTagging has the following special error: Error code: NoSuchTagSetError Description: There is no tag set associated with the bucket. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketTagging.html#API_control_GetBucketTagging_Examples) section. The following actions are related to GetBucketTagging: PutBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketTagging.html) DeleteBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketTagging.html)
#
# GET /v20180820/bucket/{name}/tagging
# operationId: GetBucketTagging
export def "get-bucket-tagging" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/bucket/{name}/tagging"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action puts tags on an Amazon S3 on Outposts bucket. To put tags on an S3 bucket, see PutBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html) in the Amazon S3 API Reference. Sets the tags for an S3 on Outposts bucket. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. Use tags to organize your Amazon Web Services bill to reflect your own cost structure. To do this, sign up to get your Amazon Web Services account bill with tag key values included. Then, to see the cost of combined resources, organize your billing information according to resources with the same tag key values. For example, you can tag several resources with a specific application name, and then organize your billing information to see the total cost of that application across several services. For more information, see Cost allocation and tagging (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html). Within a bucket, if you add a tag that has the same key as an existing tag, the new value overwrites the old value. For more information, see Using cost allocation in Amazon S3 bucket tags (https://docs.aws.amazon.com/AmazonS3/latest/userguide/CostAllocTagging.html). To use this action, you must have permissions to perform the s3-outposts:PutBucketTagging action. The Outposts bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see Permissions Related to Bucket Subresource Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources) and Managing access permissions to your Amazon S3 resources (https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html). PutBucketTagging has the following special errors: Error code: InvalidTagError Description: The tag provided was not a valid tag. This error can occur if the tag did not pass input validation. For information about tag restrictions, see User-Defined Tag Restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html) and Amazon Web Services-Generated Cost Allocation Tag Restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/aws-tag-restrictions.html). Error code: MalformedXMLError Description: The XML provided does not match the schema. Error code: OperationAbortedError Description: A conflicting conditional action is currently in progress against this resource. Try again. Error code: InternalError Description: The service was unable to apply the provided tag to the bucket. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketTagging.html#API_control_PutBucketTagging_Examples) section. The following actions are related to PutBucketTagging: GetBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketTagging.html) DeleteBucketTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteBucketTagging.html)
#
# PUT /v20180820/bucket/{name}/tagging
# operationId: PutBucketTagging
export def "put-bucket-tagging" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/bucket/{name}/tagging"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the entire tag set from the specified S3 Batch Operations job. To use the DeleteJobTagging operation, you must have permission to perform the s3:DeleteJobTagging action. For more information, see Controlling access and labeling jobs using tags (https://docs.aws.amazon.com/AmazonS3/latest/dev/batch-ops-managing-jobs.html#batch-ops-job-tags) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) GetJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetJobTagging.html) PutJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutJobTagging.html)
#
# DELETE /v20180820/jobs/{id}/tagging
# operationId: DeleteJobTagging
export def "delete-job-tagging" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/jobs/{id}/tagging"
    path_params: [{name: id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the tags on an S3 Batch Operations job. To use the GetJobTagging operation, you must have permission to perform the s3:GetJobTagging action. For more information, see Controlling access and labeling jobs using tags (https://docs.aws.amazon.com/AmazonS3/latest/dev/batch-ops-managing-jobs.html#batch-ops-job-tags) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) PutJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutJobTagging.html) DeleteJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteJobTagging.html)
#
# GET /v20180820/jobs/{id}/tagging
# operationId: GetJobTagging
export def "get-job-tagging" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/jobs/{id}/tagging"
    path_params: [{name: id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the supplied tag-set on an S3 Batch Operations job. A tag is a key-value pair. You can associate S3 Batch Operations tags with any job by sending a PUT request against the tagging subresource that is associated with the job. To modify the existing tag set, you can either replace the existing tag set entirely, or make changes within the existing tag set by retrieving the existing tag set using GetJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetJobTagging.html), modify that tag set, and use this action to replace the tag set with the one you modified. For more information, see Controlling access and labeling jobs using tags (https://docs.aws.amazon.com/AmazonS3/latest/dev/batch-ops-managing-jobs.html#batch-ops-job-tags) in the Amazon S3 User Guide. If you send this request with an empty tag set, Amazon S3 deletes the existing tag set on the Batch Operations job. If you use this method, you are charged for a Tier 1 Request (PUT). For more information, see Amazon S3 pricing (http://aws.amazon.com/s3/pricing/). For deleting existing tags for your Batch Operations job, a DeleteJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteJobTagging.html) request is preferred because it achieves the same result without incurring charges. A few things to consider about using tags: Amazon S3 limits the maximum number of tags to 50 tags per job. You can associate up to 50 tags with a job as long as they have unique tag keys. A tag key can be up to 128 Unicode characters in length, and tag values can be up to 256 Unicode characters in length. The key and values are case sensitive. For tagging-related restrictions related to characters and encodings, see User-Defined Tag Restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html) in the Billing and Cost Management User Guide. To use the PutJobTagging operation, you must have permission to perform the s3:PutJobTagging action. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) GetJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetJobTagging.html) DeleteJobTagging (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteJobTagging.html)
#
# PUT /v20180820/jobs/{id}/tagging
# operationId: PutJobTagging
export def "put-job-tagging" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/jobs/{id}/tagging"
    path_params: [{name: id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Multi-Region Access Point. This action does not delete the buckets associated with the Multi-Region Access Point, only the Multi-Region Access Point itself. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. This request is asynchronous, meaning that you might receive a response before the command has completed. When this request provides a response, it provides a token that you can use to monitor the status of the request with DescribeMultiRegionAccessPointOperation. The following actions are related to DeleteMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# POST /v20180820/async-requests/mrap/delete
# operationId: DeleteMultiRegionAccessPoint
export def "delete-multi-region-access-point" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/v20180820/async-requests/mrap/delete"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the PublicAccessBlock configuration for an Amazon Web Services account. For more information, see Using Amazon S3 block public access (https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html). Related actions include: GetPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetPublicAccessBlock.html) PutPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutPublicAccessBlock.html)
#
# DELETE /v20180820/configuration/publicAccessBlock
# operationId: DeletePublicAccessBlock
export def "delete-public-access-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the Amazon Web Services account whose PublicAccessBlock configuration you want to remove. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/configuration/publicAccessBlock"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the PublicAccessBlock configuration for an Amazon Web Services account. For more information, see Using Amazon S3 block public access (https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html). Related actions include: DeletePublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeletePublicAccessBlock.html) PutPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutPublicAccessBlock.html)
#
# GET /v20180820/configuration/publicAccessBlock
# operationId: GetPublicAccessBlock
export def "get-public-access-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the Amazon Web Services account whose PublicAccessBlock configuration you want to retrieve. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/configuration/publicAccessBlock"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or modifies the PublicAccessBlock configuration for an Amazon Web Services account. For this operation, users must have the s3:PutAccountPublicAccessBlock permission. For more information, see Using Amazon S3 block public access (https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html). Related actions include: GetPublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetPublicAccessBlock.html) DeletePublicAccessBlock (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeletePublicAccessBlock.html)
#
# PUT /v20180820/configuration/publicAccessBlock
# operationId: PutPublicAccessBlock
export def "put-public-access-block" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the Amazon Web Services account whose PublicAccessBlock configuration you want to set. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/configuration/publicAccessBlock"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:DeleteStorageLensConfiguration action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# DELETE /v20180820/storagelens/{storagelensid}
# operationId: DeleteStorageLensConfiguration
export def "delete-storage-lens-configuration" [
  storagelensid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/storagelens/{storagelensid}"
    path_params: [{name: storagelensid, var: storagelensid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storagelensid: $storagelensid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Amazon S3 Storage Lens configuration. For more information, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. For a complete list of S3 Storage Lens metrics, see S3 Storage Lens metrics glossary (https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage_lens_metrics_glossary.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:GetStorageLensConfiguration action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# GET /v20180820/storagelens/{storagelensid}
# operationId: GetStorageLensConfiguration
export def "get-storage-lens-configuration" [
  storagelensid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/storagelens/{storagelensid}"
    path_params: [{name: storagelensid, var: storagelensid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    storagelensid: $storagelensid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts an Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Working with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. For a complete list of S3 Storage Lens metrics, see S3 Storage Lens metrics glossary (https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage_lens_metrics_glossary.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:PutStorageLensConfiguration action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# PUT /v20180820/storagelens/{storagelensid}
# operationId: PutStorageLensConfiguration
export def "put-storage-lens-configuration" [
  storagelensid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/storagelens/{storagelensid}"
    path_params: [{name: storagelensid, var: storagelensid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storagelensid: $storagelensid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Amazon S3 Storage Lens configuration tags. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:DeleteStorageLensConfigurationTagging action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# DELETE /v20180820/storagelens/{storagelensid}/tagging
# operationId: DeleteStorageLensConfigurationTagging
export def "delete-storage-lens-configuration-tagging" [
  storagelensid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v20180820/storagelens/{storagelensid}/tagging"
    path_params: [{name: storagelensid, var: storagelensid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    storagelensid: $storagelensid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the tags of Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:GetStorageLensConfigurationTagging action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# GET /v20180820/storagelens/{storagelensid}/tagging
# operationId: GetStorageLensConfigurationTagging
export def "get-storage-lens-configuration-tagging" [
  storagelensid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/storagelens/{storagelensid}/tagging"
    path_params: [{name: storagelensid, var: storagelensid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    storagelensid: $storagelensid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Put or replace tags on an existing Amazon S3 Storage Lens configuration. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:PutStorageLensConfigurationTagging action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# PUT /v20180820/storagelens/{storagelensid}/tagging
# operationId: PutStorageLensConfigurationTagging
export def "put-storage-lens-configuration-tagging" [
  storagelensid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/storagelens/{storagelensid}/tagging"
    path_params: [{name: storagelensid, var: storagelensid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    storagelensid: $storagelensid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the configuration parameters and status for a Batch Operations job. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) UpdateJobPriority (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobPriority.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# GET /v20180820/jobs/{id}
# operationId: DescribeJob
export def "describe-job" [
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
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/jobs/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the status of an asynchronous request to manage a Multi-Region Access Point. For more information about managing Multi-Region Access Points and how asynchronous requests work, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# GET /v20180820/async-requests/mrap/{request_token}
# operationId: DescribeMultiRegionAccessPointOperation
export def "describe-multi-region-access-point-operation" [
  request_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/async-requests/mrap/{request_token}"
    path_params: [{name: request_token, var: request_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    request_token: $request_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns configuration for an Object Lambda Access Point. The following actions are related to GetAccessPointConfigurationForObjectLambda: PutAccessPointConfigurationForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutAccessPointConfigurationForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda/{name}/configuration
# operationId: GetAccessPointConfigurationForObjectLambda
export def "get-access-point-configuration-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspointforobjectlambda/{name}/configuration"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces configuration for an Object Lambda Access Point. The following actions are related to PutAccessPointConfigurationForObjectLambda: GetAccessPointConfigurationForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointConfigurationForObjectLambda.html)
#
# PUT /v20180820/accesspointforobjectlambda/{name}/configuration
# operationId: PutAccessPointConfigurationForObjectLambda
export def "put-access-point-configuration-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/accesspointforobjectlambda/{name}/configuration"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see Managing Data Access with Amazon S3 access points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html) in the Amazon S3 User Guide.
#
# GET /v20180820/accesspoint/{name}/policyStatus
# operationId: GetAccessPointPolicyStatus
export def "get-access-point-policy-status" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified access point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspoint/{name}/policyStatus"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the status of the resource policy associated with an Object Lambda Access Point.
#
# GET /v20180820/accesspointforobjectlambda/{name}/policyStatus
# operationId: GetAccessPointPolicyStatusForObjectLambda
export def "get-access-point-policy-status-for-object-lambda" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspointforobjectlambda/{name}/policyStatus"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation returns the versioning state for S3 on Outposts buckets only. To return the versioning state for an S3 bucket, see GetBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html) in the Amazon S3 API Reference. Returns the versioning state for an S3 on Outposts bucket. With S3 Versioning, you can save multiple distinct copies of your objects and recover from unintended user actions and application failures. If you've never set versioning on your bucket, it has no versioning state. In that case, the GetBucketVersioning request does not return a versioning state value. For more information about versioning, see Versioning (https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketVersioning.html#API_control_GetBucketVersioning_Examples) section. The following operations are related to GetBucketVersioning for S3 on Outposts. PutBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketVersioning.html) PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html)
#
# GET /v20180820/bucket/{name}/versioning
# operationId: GetBucketVersioning
export def "get-bucket-versioning" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the S3 on Outposts bucket. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/bucket/{name}/versioning"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation sets the versioning state for S3 on Outposts buckets only. To set the versioning state for an S3 bucket, see PutBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html) in the Amazon S3 API Reference. Sets the versioning state for an S3 on Outposts bucket. With S3 Versioning, you can save multiple distinct copies of your objects and recover from unintended user actions and application failures. You can set the versioning state to one of the following: Enabled - Enables versioning for the objects in the bucket. All objects added to the bucket receive a unique version ID. Suspended - Suspends versioning for the objects in the bucket. All objects added to the bucket receive the version ID null. If you've never set versioning on your bucket, it has no versioning state. In that case, a GetBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketVersioning.html) request does not return a versioning state value. When you enable S3 Versioning, for each object in your bucket, you have a current version and zero or more noncurrent versions. You can configure your bucket S3 Lifecycle rules to expire noncurrent versions after a specified time period. For more information, see Creating and managing a lifecycle configuration for your S3 on Outposts bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3OutpostsLifecycleManaging.html) in the Amazon S3 User Guide. If you have an object expiration lifecycle configuration in your non-versioned bucket and you want to maintain the same permanent delete behavior when you enable versioning, you must add a noncurrent expiration policy. The noncurrent expiration lifecycle configuration will manage the deletes of the noncurrent object versions in the version-enabled bucket. For more information, see Versioning (https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) in the Amazon S3 User Guide. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketVersioning.html#API_control_PutBucketVersioning_Examples) section. The following operations are related to PutBucketVersioning for S3 on Outposts. GetBucketVersioning (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketVersioning.html) PutBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutBucketLifecycleConfiguration.html) GetBucketLifecycleConfiguration (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetBucketLifecycleConfiguration.html)
#
# PUT /v20180820/bucket/{name}/versioning
# operationId: PutBucketVersioning
export def "put-bucket-versioning" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the S3 on Outposts bucket. (required)
  --x-amz-mfa: string # The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/v20180820/bucket/{name}/versioning"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}, {name: x-amz-mfa, var: x_amz_mfa}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, x_amz_mfa: $x_amz_mfa, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns configuration information about the specified Multi-Region Access Point. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) ListMultiRegionAccessPoints (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListMultiRegionAccessPoints.html)
#
# GET /v20180820/mrap/instances/{name}
# operationId: GetMultiRegionAccessPoint
export def "get-multi-region-access-point" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/mrap/instances/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the access control policy of the specified Multi-Region Access Point. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPointPolicy: GetMultiRegionAccessPointPolicyStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicyStatus.html) PutMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutMultiRegionAccessPointPolicy.html)
#
# GET /v20180820/mrap/instances/{name}/policy
# operationId: GetMultiRegionAccessPointPolicy
export def "get-multi-region-access-point-policy" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/mrap/instances/{name}/policy"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Indicates whether the specified Multi-Region Access Point has an access control policy that allows public access. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to GetMultiRegionAccessPointPolicyStatus: GetMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicy.html) PutMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_PutMultiRegionAccessPointPolicy.html)
#
# GET /v20180820/mrap/instances/{name}/policystatus
# operationId: GetMultiRegionAccessPointPolicyStatus
export def "get-multi-region-access-point-policy-status" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/mrap/instances/{name}/policystatus"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the routing configuration for a Multi-Region Access Point, indicating which Regions are active or passive. To obtain routing control changes and failover requests, use the Amazon S3 failover control infrastructure endpoints in these five Amazon Web Services Regions: us-east-1 us-west-2 ap-southeast-2 ap-northeast-1 eu-west-1 Your Amazon S3 bucket does not need to be in these five Regions.
#
# GET /v20180820/mrap/instances/{mrap}/routes
# operationId: GetMultiRegionAccessPointRoutes
export def "get-multi-region-access-point-routes" [
  mrap: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/mrap/instances/{mrap}/routes"
    path_params: [{name: mrap, var: mrap}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    mrap: $mrap, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submits an updated route configuration for a Multi-Region Access Point. This API operation updates the routing status for the specified Regions from active to passive, or from passive to active. A value of 0 indicates a passive status, which means that traffic won't be routed to the specified Region. A value of 100 indicates an active status, which means that traffic will be routed to the specified Region. At least one Region must be active at all times. When the routing configuration is changed, any in-progress operations (uploads, copies, deletes, and so on) to formerly active Regions will continue to run to their final completion state (success or failure). The routing configurations of any Regions that aren’t specified remain unchanged. Updated routing configurations might not be immediately applied. It can take up to 2 minutes for your changes to take effect. To submit routing control changes and failover requests, use the Amazon S3 failover control infrastructure endpoints in these five Amazon Web Services Regions: us-east-1 us-west-2 ap-southeast-2 ap-northeast-1 eu-west-1 Your Amazon S3 bucket does not need to be in these five Regions.
#
# PATCH /v20180820/mrap/instances/{mrap}/routes
# operationId: SubmitMultiRegionAccessPointRoutes
export def "submit-multi-region-access-point-routes" [
  mrap: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v20180820/mrap/instances/{mrap}/routes"
    path_params: [{name: mrap, var: mrap}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    mrap: $mrap, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the access points that are owned by the current account that's associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1,000 access points (or the number specified in maxResults, whichever is less), the response will include a continuation token that you can use to list the additional access points. All Amazon S3 on Outposts REST API requests for this action require an additional parameter of x-amz-outpost-id to be passed with the request. In addition, you must use an S3 on Outposts endpoint hostname prefix instead of s3-control. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and the x-amz-outpost-id derived by using the access point ARN, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html#API_control_GetAccessPoint_Examples) section. The following actions are related to ListAccessPoints: CreateAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPoint.html) DeleteAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPoint.html) GetAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPoint.html)
#
# GET /v20180820/accesspoint
# operationId: ListAccessPoints
export def "list-access-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucket: string # The name of the bucket whose associated access points you want to list. For using this parameter with Amazon S3 on Outposts with the REST API, you must specify the name and the x-amz-outpost-id as well. For using this parameter with S3 on Outposts with the Amazon Web Services SDK and CLI, you must specify the ARN of the bucket accessed in the format arn:aws:s3-outposts:<Region>:<account-id>:outpost/<outpost-id>/bucket/<my-bucket-name>. For example, to access the bucket reports through Outpost my-outpost owned by account 123456789012 in Region us-west-2, use the URL encoding of arn:aws:s3-outposts:us-west-2:123456789012:outpost/my-outpost/bucket/reports. The value must be URL encoded.
  --next-token: string # A continuation token. If a previous call to ListAccessPoints returned a continuation token in the NextToken field, then providing that value here causes Amazon S3 to retrieve the next page of results.
  --max-results: int # The maximum number of access points that you want to include in the list. If the specified bucket has more than this number of access points, then the response will include a continuation token in the NextToken field that you can use to retrieve the next page of access points.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the account that owns the specified access points. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspoint"
    query: [{name: bucket, var: bucket}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    bucket: $bucket, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns some or all (up to 1,000) access points associated with the Object Lambda Access Point per call. If there are more access points than what can be returned in one call, the response will include a continuation token that you can use to list the additional access points. The following actions are related to ListAccessPointsForObjectLambda: CreateAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateAccessPointForObjectLambda.html) DeleteAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteAccessPointForObjectLambda.html) GetAccessPointForObjectLambda (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetAccessPointForObjectLambda.html)
#
# GET /v20180820/accesspointforobjectlambda
# operationId: ListAccessPointsForObjectLambda
export def "list-access-points-for-object-lambda" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # If the list has more access points than can be returned in one call to this API, this field contains a continuation token that you can provide in subsequent calls to this API to retrieve additional access points.
  --max-results: int # The maximum number of access points that you want to include in the list. The response may contain fewer access points but will never contain more. If there are more than this number of access points, then the response will include a continuation token in the NextToken field that you can use to retrieve the next page of access points.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID for the account that owns the specified Object Lambda Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/accesspointforobjectlambda"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the Multi-Region Access Points currently associated with the specified Amazon Web Services account. Each call can return up to 100 Multi-Region Access Points, the maximum number of Multi-Region Access Points that can be associated with a single account. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to ListMultiRegionAccessPoint: CreateMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateMultiRegionAccessPoint.html) DeleteMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DeleteMultiRegionAccessPoint.html) DescribeMultiRegionAccessPointOperation (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeMultiRegionAccessPointOperation.html) GetMultiRegionAccessPoint (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPoint.html)
#
# GET /v20180820/mrap/instances
# operationId: ListMultiRegionAccessPoints
export def "list-multi-region-access-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Not currently used. Do not use this parameter.
  --max-results: int # Not currently used. Do not use this parameter.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/mrap/instances"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all Outposts buckets in an Outpost that are owned by the authenticated sender of the request. For more information, see Using Amazon S3 on Outposts (https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide. For an example of the request syntax for Amazon S3 on Outposts that uses the S3 on Outposts endpoint hostname prefix and x-amz-outpost-id in your request, see the Examples (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListRegionalBuckets.html#API_control_ListRegionalBuckets_Examples) section.
#
# GET /v20180820/bucket
# operationId: ListRegionalBuckets
export def "list-regional-buckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID of the Outposts bucket. (required)
  --x-amz-outpost-id: string # The ID of the Outposts resource. This ID is required by Amazon S3 on Outposts buckets.
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/bucket"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}, {name: x-amz-outpost-id, var: x_amz_outpost_id}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, x_amz_outpost_id: $x_amz_outpost_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of Amazon S3 Storage Lens configurations. For more information about S3 Storage Lens, see Assessing your storage activity and usage with Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens.html) in the Amazon S3 User Guide. To use this action, you must have permission to perform the s3:ListStorageLensConfigurations action. For more information, see Setting permissions to use Amazon S3 Storage Lens (https://docs.aws.amazon.com/AmazonS3/latest/dev/storage_lens_iam_permissions.html) in the Amazon S3 User Guide.
#
# GET /v20180820/storagelens
# operationId: ListStorageLensConfigurations
export def "list-storage-lens-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token to request the next page of results.
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The account ID of the requester. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v20180820/storagelens"
    query: [{name: nextToken, var: next_token}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates an access control policy with the specified Multi-Region Access Point. Each Multi-Region Access Point can have only one policy, so a request made to this action replaces any existing policy that is associated with the specified Multi-Region Access Point. This action will always be routed to the US West (Oregon) Region. For more information about the restrictions around managing Multi-Region Access Points, see Managing Multi-Region Access Points (https://docs.aws.amazon.com/AmazonS3/latest/userguide/ManagingMultiRegionAccessPoints.html) in the Amazon S3 User Guide. The following actions are related to PutMultiRegionAccessPointPolicy: GetMultiRegionAccessPointPolicy (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicy.html) GetMultiRegionAccessPointPolicyStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetMultiRegionAccessPointPolicyStatus.html)
#
# POST /v20180820/async-requests/mrap/put-policy
# operationId: PutMultiRegionAccessPointPolicy
export def "put-multi-region-access-point-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID for the owner of the Multi-Region Access Point. (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/v20180820/async-requests/mrap/put-policy"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing S3 Batch Operations job's priority. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# POST /v20180820/jobs/{id}/priority
# operationId: UpdateJobPriority
export def "update-job-priority" [
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
  --priority: int # The priority you want to assign to this job. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/v20180820/jobs/{id}/priority"
    path_params: [{name: id, var: id}]
    query: [{name: priority, var: priority, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, priority: $priority, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status for the specified job. Use this action to confirm that you want to run a job or to cancel an existing job. For more information, see S3 Batch Operations (https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html) in the Amazon S3 User Guide. Related actions include: CreateJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateJob.html) ListJobs (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_ListJobs.html) DescribeJob (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_DescribeJob.html) UpdateJobStatus (https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_UpdateJobStatus.html)
#
# POST /v20180820/jobs/{id}/status
# operationId: UpdateJobStatus
export def "update-job-status" [
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
  --requested-job-status: string@requested-job-status-completer # The status that you want to move the specified job to. (required)
  --status-update-reason: string # A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-account-id: string # The Amazon Web Services account ID associated with the S3 Batch Operations job. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/v20180820/jobs/{id}/status"
    path_params: [{name: id, var: id}]
    query: [{name: requestedJobStatus, var: requested_job_status, required: true}, {name: statusUpdateReason, var: status_update_reason}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-account-id, var: x_amz_account_id, required: true}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, requested_job_status: $requested_job_status, status_update_reason: $status_update_reason, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_account_id: $x_amz_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
