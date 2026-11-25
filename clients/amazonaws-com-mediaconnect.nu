# Auto-generated client for AWS MediaConnect v2018-11-14
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mediaconnect/2018-11-14/openapi.json
# Auth: --token flag or $env.AWS_MEDIACONNECT_TOKEN

const CLIENT = {
  base_url: "http://mediaconnect.us-east-1.amazonaws.com"
  token_env_var: "AWS_MEDIACONNECT_TOKEN"
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

def base-url-completer [] { ["http://mediaconnect.us-east-1.amazonaws.com" "http://mediaconnect.us-east-2.amazonaws.com" "http://mediaconnect.us-west-1.amazonaws.com" "http://mediaconnect.us-west-2.amazonaws.com" "http://mediaconnect.us-gov-west-1.amazonaws.com" "http://mediaconnect.us-gov-east-1.amazonaws.com" "http://mediaconnect.ca-central-1.amazonaws.com" "http://mediaconnect.eu-north-1.amazonaws.com" "http://mediaconnect.eu-west-1.amazonaws.com" "http://mediaconnect.eu-west-2.amazonaws.com" "http://mediaconnect.eu-west-3.amazonaws.com" "http://mediaconnect.eu-central-1.amazonaws.com" "http://mediaconnect.eu-south-1.amazonaws.com" "http://mediaconnect.af-south-1.amazonaws.com" "http://mediaconnect.ap-northeast-1.amazonaws.com" "http://mediaconnect.ap-northeast-2.amazonaws.com" "http://mediaconnect.ap-northeast-3.amazonaws.com" "http://mediaconnect.ap-southeast-1.amazonaws.com" "http://mediaconnect.ap-southeast-2.amazonaws.com" "http://mediaconnect.ap-east-1.amazonaws.com" "http://mediaconnect.ap-south-1.amazonaws.com" "http://mediaconnect.sa-east-1.amazonaws.com" "http://mediaconnect.me-south-1.amazonaws.com" "https://mediaconnect.us-east-1.amazonaws.com" "https://mediaconnect.us-east-2.amazonaws.com" "https://mediaconnect.us-west-1.amazonaws.com" "https://mediaconnect.us-west-2.amazonaws.com" "https://mediaconnect.us-gov-west-1.amazonaws.com" "https://mediaconnect.us-gov-east-1.amazonaws.com" "https://mediaconnect.ca-central-1.amazonaws.com" "https://mediaconnect.eu-north-1.amazonaws.com" "https://mediaconnect.eu-west-1.amazonaws.com" "https://mediaconnect.eu-west-2.amazonaws.com" "https://mediaconnect.eu-west-3.amazonaws.com" "https://mediaconnect.eu-central-1.amazonaws.com" "https://mediaconnect.eu-south-1.amazonaws.com" "https://mediaconnect.af-south-1.amazonaws.com" "https://mediaconnect.ap-northeast-1.amazonaws.com" "https://mediaconnect.ap-northeast-2.amazonaws.com" "https://mediaconnect.ap-northeast-3.amazonaws.com" "https://mediaconnect.ap-southeast-1.amazonaws.com" "https://mediaconnect.ap-southeast-2.amazonaws.com" "https://mediaconnect.ap-east-1.amazonaws.com" "https://mediaconnect.ap-south-1.amazonaws.com" "https://mediaconnect.sa-east-1.amazonaws.com" "https://mediaconnect.me-south-1.amazonaws.com" "http://mediaconnect.cn-north-1.amazonaws.com.cn" "http://mediaconnect.cn-northwest-1.amazonaws.com.cn" "https://mediaconnect.cn-north-1.amazonaws.com.cn" "https://mediaconnect.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bridge-placement-completer [] { ["AVAILABLE" "LOCKED"] }
def media-stream-type-completer [] { ["ancillary-data" "audio" "video"] }
def protocol-completer [] { ["cdi" "fujitsu-qos" "rist" "rtp" "rtp-fec" "srt-caller" "srt-listener" "st2110-jpegxs" "udp" "zixi-pull" "zixi-push"] }
def entitlement-status-completer [] { ["DISABLED" "ENABLED"] }
def desired-state-completer [] { ["ACTIVE" "DELETED" "STANDBY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-bridge-outputs: "record<BridgeArn: string, Outputs: table<FlowOutput: record, NetworkOutput: record>>"
    add-bridge-sources: "record<BridgeArn: string, Sources: table<FlowSource: record, NetworkSource: record>>"
    add-flow-media-streams: "record<FlowArn: string, MediaStreams: table<Attributes: record, ClockRate: int, Description: string, Fmt: int, MediaStreamId: int, MediaStreamName: string, MediaStreamType: string, VideoFormat: string>>"
    add-flow-outputs: "record<FlowArn: string, Outputs: table<DataTransferSubscriberFeePercent: int, Description: string, Destination: string, Encryption: record, EntitlementArn: string, ListenerAddress: string, MediaLiveInputArn: string, MediaStreamOutputConfigurations: list, Name: string, OutputArn: string, Port: int, Transport: record, VpcInterfaceAttachment: record, BridgeArn: string, BridgePorts: list>>"
    add-flow-sources: "record<FlowArn: string, Sources: table<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>>"
    add-flow-vpc-interfaces: "record<FlowArn: string, VpcInterfaces: table<Name: string, NetworkInterfaceIds: list, NetworkInterfaceType: string, RoleArn: string, SecurityGroupIds: list, SubnetId: string>>"
    create-bridge: "record<Bridge: record<BridgeArn: string, BridgeMessages: list<record>, BridgeState: string, EgressGatewayBridge: record<InstanceId: string, MaxBitrate: int>, IngressGatewayBridge: record<InstanceId: string, MaxBitrate: int, MaxOutputs: int>, Name: string, Outputs: list<record>, PlacementArn: string, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>>>"
    list-bridges: "record<Bridges: table<BridgeArn: string, BridgeState: string, BridgeType: string, Name: string, PlacementArn: string>, NextToken: string>"
    create-flow: "record<Flow: record<AvailabilityZone: string, Description: string, EgressIp: string, Entitlements: list<record>, FlowArn: string, MediaStreams: list<record>, Name: string, Outputs: list<record>, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>, Status: string, VpcInterfaces: list<record>, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartHour: string>>>"
    list-flows: "record<Flows: table<AvailabilityZone: string, Description: string, FlowArn: string, Name: string, SourceType: string, Status: string, Maintenance: record>, NextToken: string>"
    create-gateway: "record<Gateway: record<EgressCidrBlocks: list<string>, GatewayArn: string, GatewayMessages: list<record>, GatewayState: string, Name: string, Networks: list<record>>>"
    list-gateways: "record<Gateways: table<GatewayArn: string, GatewayState: string, Name: string>, NextToken: string>"
    delete-bridge: "record<BridgeArn: string>"
    describe-bridge: "record<Bridge: record<BridgeArn: string, BridgeMessages: list<record>, BridgeState: string, EgressGatewayBridge: record<InstanceId: string, MaxBitrate: int>, IngressGatewayBridge: record<InstanceId: string, MaxBitrate: int, MaxOutputs: int>, Name: string, Outputs: list<record>, PlacementArn: string, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>>>"
    update-bridge: "record<Bridge: record<BridgeArn: string, BridgeMessages: list<record>, BridgeState: string, EgressGatewayBridge: record<InstanceId: string, MaxBitrate: int>, IngressGatewayBridge: record<InstanceId: string, MaxBitrate: int, MaxOutputs: int>, Name: string, Outputs: list<record>, PlacementArn: string, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>>>"
    delete-flow: "record<FlowArn: string, Status: string>"
    describe-flow: "record<Flow: record<AvailabilityZone: string, Description: string, EgressIp: string, Entitlements: list<record>, FlowArn: string, MediaStreams: list<record>, Name: string, Outputs: list<record>, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>, Status: string, VpcInterfaces: list<record>, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartHour: string>>, Messages: record<Errors: list<string>>>"
    update-flow: "record<Flow: record<AvailabilityZone: string, Description: string, EgressIp: string, Entitlements: list<record>, FlowArn: string, MediaStreams: list<record>, Name: string, Outputs: list<record>, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>, Status: string, VpcInterfaces: list<record>, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartHour: string>>>"
    delete-gateway: "record<GatewayArn: string>"
    describe-gateway: "record<Gateway: record<EgressCidrBlocks: list<string>, GatewayArn: string, GatewayMessages: list<record>, GatewayState: string, Name: string, Networks: list<record>>>"
    deregister-gateway-instance: "record<GatewayInstanceArn: string, InstanceState: string>"
    describe-gateway-instance: "record<GatewayInstance: record<BridgePlacement: string, ConnectionStatus: string, GatewayArn: string, GatewayInstanceArn: string, InstanceId: string, InstanceMessages: list<record>, InstanceState: string, RunningBridgeCount: int>>"
    update-gateway-instance: "record<BridgePlacement: string, GatewayInstanceArn: string>"
    describe-offering: "record<Offering: record<CurrencyCode: string, Duration: int, DurationUnits: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ResourceSpecification: record<ReservedBitrate: int, ResourceType: string>>>"
    purchase-offering: "record<Reservation: record<CurrencyCode: string, Duration: int, DurationUnits: string, End: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ReservationArn: string, ReservationName: string, ReservationState: string, ResourceSpecification: record<ReservedBitrate: int, ResourceType: string>, Start: string>>"
    describe-reservation: "record<Reservation: record<CurrencyCode: string, Duration: int, DurationUnits: string, End: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ReservationArn: string, ReservationName: string, ReservationState: string, ResourceSpecification: record<ReservedBitrate: int, ResourceType: string>, Start: string>>"
    grant-flow-entitlements: "record<Entitlements: table<DataTransferSubscriberFeePercent: int, Description: string, Encryption: record, EntitlementArn: string, EntitlementStatus: string, Name: string, Subscribers: list>, FlowArn: string>"
    list-entitlements: "record<Entitlements: table<DataTransferSubscriberFeePercent: int, EntitlementArn: string, EntitlementName: string>, NextToken: string>"
    list-gateway-instances: "record<Instances: table<GatewayArn: string, GatewayInstanceArn: string, InstanceId: string, InstanceState: string>, NextToken: string>"
    list-offerings: "record<NextToken: string, Offerings: table<CurrencyCode: string, Duration: int, DurationUnits: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ResourceSpecification: record>>"
    list-reservations: "record<NextToken: string, Reservations: table<CurrencyCode: string, Duration: int, DurationUnits: string, End: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ReservationArn: string, ReservationName: string, ReservationState: string, ResourceSpecification: record, Start: string>>"
    list-tags-for-resource: "record<Tags: record>"
    remove-bridge-output: "record<BridgeArn: string, OutputName: string>"
    update-bridge-output: "record<BridgeArn: string, Output: record<FlowOutput: record<FlowArn: string, FlowSourceArn: string, Name: string>, NetworkOutput: record<IpAddress: string, Name: string, NetworkName: string, Port: int, Protocol: string, Ttl: int>>>"
    remove-bridge-source: "record<BridgeArn: string, SourceName: string>"
    update-bridge-source: "record<BridgeArn: string, Source: record<FlowSource: record<FlowArn: string, FlowVpcInterfaceAttachment: record, Name: string, OutputArn: string>, NetworkSource: record<MulticastIp: string, Name: string, NetworkName: string, Port: int, Protocol: string>>>"
    remove-flow-media-stream: "record<FlowArn: string, MediaStreamName: string>"
    update-flow-media-stream: "record<FlowArn: string, MediaStream: record<Attributes: record<Fmtp: record, Lang: string>, ClockRate: int, Description: string, Fmt: int, MediaStreamId: int, MediaStreamName: string, MediaStreamType: string, VideoFormat: string>>"
    remove-flow-output: "record<FlowArn: string, OutputArn: string>"
    update-flow-output: "record<FlowArn: string, Output: record<DataTransferSubscriberFeePercent: int, Description: string, Destination: string, Encryption: record<Algorithm: string, ConstantInitializationVector: string, DeviceId: string, KeyType: string, Region: string, ResourceId: string, RoleArn: string, SecretArn: string, Url: string>, EntitlementArn: string, ListenerAddress: string, MediaLiveInputArn: string, MediaStreamOutputConfigurations: list<record>, Name: string, OutputArn: string, Port: int, Transport: record<CidrAllowList: list, MaxBitrate: int, MaxLatency: int, MaxSyncBuffer: int, MinLatency: int, Protocol: string, RemoteId: string, SenderControlPort: int, SenderIpAddress: string, SmoothingLatency: int, SourceListenerAddress: string, SourceListenerPort: int, StreamId: string>, VpcInterfaceAttachment: record<VpcInterfaceName: string>, BridgeArn: string, BridgePorts: list<int>>>"
    remove-flow-source: "record<FlowArn: string, SourceArn: string>"
    update-flow-source: "record<FlowArn: string, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record<Algorithm: string, ConstantInitializationVector: string, DeviceId: string, KeyType: string, Region: string, ResourceId: string, RoleArn: string, SecretArn: string, Url: string>, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list<record>, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record<CidrAllowList: list, MaxBitrate: int, MaxLatency: int, MaxSyncBuffer: int, MinLatency: int, Protocol: string, RemoteId: string, SenderControlPort: int, SenderIpAddress: string, SmoothingLatency: int, SourceListenerAddress: string, SourceListenerPort: int, StreamId: string>, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record<BridgeArn: string, VpcInterfaceAttachment: record>>>"
    remove-flow-vpc-interface: "record<FlowArn: string, NonDeletedNetworkInterfaceIds: list<string>, VpcInterfaceName: string>"
    revoke-flow-entitlement: "record<EntitlementArn: string, FlowArn: string>"
    update-flow-entitlement: "record<Entitlement: record<DataTransferSubscriberFeePercent: int, Description: string, Encryption: record<Algorithm: string, ConstantInitializationVector: string, DeviceId: string, KeyType: string, Region: string, ResourceId: string, RoleArn: string, SecretArn: string, Url: string>, EntitlementArn: string, EntitlementStatus: string, Name: string, Subscribers: list<string>>, FlowArn: string>"
    start-flow: "record<FlowArn: string, Status: string>"
    stop-flow: "record<FlowArn: string, Status: string>"
    update-bridge-state: "record<BridgeArn: string, DesiredState: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-bridge-outputs" "add-bridge-sources" "add-flow-media-streams" "add-flow-outputs" "add-flow-sources" "add-flow-vpc-interfaces" "create-bridge" "list-bridges" "create-flow" "list-flows" "create-gateway" "list-gateways" "delete-bridge" "describe-bridge" "update-bridge" "delete-flow" "describe-flow" "update-flow" "delete-gateway" "describe-gateway" "deregister-gateway-instance" "describe-gateway-instance" "update-gateway-instance" "describe-offering" "purchase-offering" "describe-reservation" "grant-flow-entitlements" "list-entitlements" "list-gateway-instances" "list-offerings" "list-reservations" "list-tags-for-resource" "tag-resource" "remove-bridge-output" "update-bridge-output" "remove-bridge-source" "update-bridge-source" "remove-flow-media-stream" "update-flow-media-stream" "remove-flow-output" "update-flow-output" "remove-flow-source" "update-flow-source" "remove-flow-vpc-interface" "revoke-flow-entitlement" "update-flow-entitlement" "start-flow" "stop-flow" "untag-resource" "update-bridge-state" "commands"] | sort) } | get name | first)
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

# Adds outputs to an existing bridge.
#
# POST /v1/bridges/{bridgeArn}/outputs
# Returns: record<BridgeArn: string, Outputs: table<FlowOutput: record, NetworkOutput: record>>
# operationId: AddBridgeOutputs
export def "add-bridge-outputs" [
  bridge_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  outputs: list # The outputs that you want to add to this bridge. — item shape: {NetworkOutput?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/bridges/{bridgeArn}/outputs"
    path_params: [{name: bridgeArn, var: bridge_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: outputs, var: outputs}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, outputs: $outputs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds sources to an existing bridge.
#
# POST /v1/bridges/{bridgeArn}/sources
# Returns: record<BridgeArn: string, Sources: table<FlowSource: record, NetworkSource: record>>
# operationId: AddBridgeSources
export def "add-bridge-sources" [
  bridge_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  sources: list # The sources that you want to add to this bridge. — item shape: {FlowSource?: record, NetworkSource?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/bridges/{bridgeArn}/sources"
    path_params: [{name: bridgeArn, var: bridge_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sources, var: sources}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds media streams to an existing flow. After you add a media stream to a flow, you can associate it with a source and/or an output that uses the ST 2110 JPEG XS or CDI protocol.
#
# POST /v1/flows/{flowArn}/mediaStreams
# Returns: record<FlowArn: string, MediaStreams: table<Attributes: record, ClockRate: int, Description: string, Fmt: int, MediaStreamId: int, MediaStreamName: string, MediaStreamType: string, VideoFormat: string>>
# operationId: AddFlowMediaStreams
export def "add-flow-media-streams" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  media_streams: list # The media streams that you want to add to the flow. — item shape: {Attributes?: record, ClockRate?: int, Description?: string, MediaStreamId: int, MediaStreamName: string, MediaStreamType: "video"|"audio"|"ancillary-data", VideoFormat?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/flows/{flowArn}/mediaStreams"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: mediaStreams, var: media_streams}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, media_streams: $media_streams
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds outputs to an existing flow. You can create up to 50 outputs per flow.
#
# POST /v1/flows/{flowArn}/outputs
# Returns: record<FlowArn: string, Outputs: table<DataTransferSubscriberFeePercent: int, Description: string, Destination: string, Encryption: record, EntitlementArn: string, ListenerAddress: string, MediaLiveInputArn: string, MediaStreamOutputConfigurations: list, Name: string, OutputArn: string, Port: int, Transport: record, VpcInterfaceAttachment: record, BridgeArn: string, BridgePorts: list>>
# operationId: AddFlowOutputs
export def "add-flow-outputs" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  outputs: list # A list of outputs that you want to add. — item shape: {CidrAllowList?: list<string>, Description?: string, Destination?: string, Encryption?: record, MaxLatency?: int, MediaStreamOutputConfigurations?: list, MinLatency?: int, Name?: string, Port?: int, Protocol: "zixi-push"|"rtp-fec"|"rtp"|"zixi-pull"|"rist"|"st2110-jpegxs"|"cdi"|"srt-listener"|"srt-caller"|"fujitsu-qos"|"udp", RemoteId?: string, SenderControlPort?: int, SmoothingLatency?: int, StreamId?: string, VpcInterfaceAttachment?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/flows/{flowArn}/outputs"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: outputs, var: outputs}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, outputs: $outputs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds Sources to flow
#
# POST /v1/flows/{flowArn}/source
# Returns: record<FlowArn: string, Sources: table<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>>
# operationId: AddFlowSources
export def "add-flow-sources" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  sources: list # A list of sources that you want to add. — item shape: {Decryption?: record, Description?: string, EntitlementArn?: string, IngestPort?: int, MaxBitrate?: int, MaxLatency?: int, MaxSyncBuffer?: int, MediaStreamSourceConfigurations?: list, MinLatency?: int, Name?: string, Protocol?: "zixi-push"|"rtp-fec"|"rtp"|"zixi-pull"|"rist"|"st2110-jpegxs"|"cdi"|"srt-listener"|"srt-caller"|"fujitsu-qos"|"udp", SenderControlPort?: int, SenderIpAddress?: string, SourceListenerAddress?: string, SourceListenerPort?: int, StreamId?: string, VpcInterfaceName?: string, ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/flows/{flowArn}/source"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sources, var: sources}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds VPC interfaces to flow
#
# POST /v1/flows/{flowArn}/vpcInterfaces
# Returns: record<FlowArn: string, VpcInterfaces: table<Name: string, NetworkInterfaceIds: list, NetworkInterfaceType: string, RoleArn: string, SecurityGroupIds: list, SubnetId: string>>
# operationId: AddFlowVpcInterfaces
export def "add-flow-vpc-interfaces" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  vpc_interfaces: list # A list of VPC interfaces that you want to add. — item shape: {Name: string, NetworkInterfaceType?: "ena"|"efa", RoleArn: string, SecurityGroupIds: list<string>, SubnetId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/flows/{flowArn}/vpcInterfaces"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: vpcInterfaces, var: vpc_interfaces}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, vpc_interfaces: $vpc_interfaces
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new bridge. The request must include one source.
#
# POST /v1/bridges
# Returns: record<Bridge: record<BridgeArn: string, BridgeMessages: list<record>, BridgeState: string, EgressGatewayBridge: record<InstanceId: string, MaxBitrate: int>, IngressGatewayBridge: record<InstanceId: string, MaxBitrate: int, MaxOutputs: int>, Name: string, Outputs: list<record>, PlacementArn: string, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>>>
# operationId: CreateBridge
export def "create-bridge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --egress-gateway-bridge: record # Create a bridge with the egress bridge type. An egress bridge is a cloud-to-ground bridge. The content comes from an existing MediaConnect flow and is delivered to your premises. — shape: {MaxBitrate?: int}
  --ingress-gateway-bridge: record # Create a bridge with the ingress bridge type. An ingress bridge is a ground-to-cloud bridge. The content originates at your premises and is delivered to the cloud. — shape: {MaxBitrate?: int, MaxOutputs?: int}
  name: string # The name of the bridge. This name can not be modified after the bridge is created.
  --outputs: list # The outputs that you want to add to this bridge. — item shape: {NetworkOutput?: record}
  placement_arn: string # The bridge placement Amazon Resource Number (ARN).
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: "MERGE"|"FAILOVER", RecoveryWindow?: int, SourcePriority?: record, State?: "ENABLED"|"DISABLED"}
  sources: list # The sources that you want to add to this bridge. — item shape: {FlowSource?: record, NetworkSource?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/bridges"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: egressGatewayBridge, var: egress_gateway_bridge}, {name: ingressGatewayBridge, var: ingress_gateway_bridge}, {name: name, var: name}, {name: outputs, var: outputs}, {name: placementArn, var: placement_arn}, {name: sourceFailoverConfig, var: source_failover_config}, {name: sources, var: sources}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, egress_gateway_bridge: $egress_gateway_bridge, ingress_gateway_bridge: $ingress_gateway_bridge, name: $name, outputs: $outputs, placement_arn: $placement_arn, source_failover_config: $source_failover_config, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of bridges that are associated with this account and an optionally specified Arn. This request returns a paginated result.
#
# GET /v1/bridges
# Returns: record<Bridges: table<BridgeArn: string, BridgeState: string, BridgeType: string, Name: string, PlacementArn: string>, NextToken: string>
# operationId: ListBridges
export def "list-bridges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-arn: string # Filter the list results to display only the bridges associated with the selected Amazon Resource Name (ARN).
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListBridges request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListBridges request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListBridges request a second time and specify the NextToken value.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/v1/bridges"
    query: [{name: filterArn, var: filter_arn}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_arn: $filter_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new flow. The request must include one source. The request optionally can include outputs (up to 50) and entitlements (up to 50).
#
# POST /v1/flows
# Returns: record<Flow: record<AvailabilityZone: string, Description: string, EgressIp: string, Entitlements: list<record>, FlowArn: string, MediaStreams: list<record>, Name: string, Outputs: list<record>, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>, Status: string, VpcInterfaces: list<record>, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartHour: string>>>
# operationId: CreateFlow
export def "create-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --availability-zone: string # The Availability Zone that you want to create the flow in. These options are limited to the Availability Zones within the current AWS Region.
  --entitlements: list # The entitlements that you want to grant on a flow. — item shape: {DataTransferSubscriberFeePercent?: int, Description?: string, Encryption?: record, EntitlementStatus?: "ENABLED"|"DISABLED", Name?: string, Subscribers: list<string>}
  --media-streams: list # The media streams that you want to add to the flow. You can associate these media streams with sources and outputs on the flow. — item shape: {Attributes?: record, ClockRate?: int, Description?: string, MediaStreamId: int, MediaStreamName: string, MediaStreamType: "video"|"audio"|"ancillary-data", VideoFormat?: string}
  name: string # The name of the flow.
  --outputs: list # The outputs that you want to add to this flow. — item shape: {CidrAllowList?: list<string>, Description?: string, Destination?: string, Encryption?: record, MaxLatency?: int, MediaStreamOutputConfigurations?: list, MinLatency?: int, Name?: string, Port?: int, Protocol: "zixi-push"|"rtp-fec"|"rtp"|"zixi-pull"|"rist"|"st2110-jpegxs"|"cdi"|"srt-listener"|"srt-caller"|"fujitsu-qos"|"udp", RemoteId?: string, SenderControlPort?: int, SmoothingLatency?: int, StreamId?: string, VpcInterfaceAttachment?: record}
  --source: record # The settings for the source of the flow. — shape: {Decryption?: record, Description?: string, EntitlementArn?: string, IngestPort?: int, MaxBitrate?: int, MaxLatency?: int, MaxSyncBuffer?: int, MediaStreamSourceConfigurations?: list, MinLatency?: int, Name?: string, Protocol?: "zixi-push"|"rtp-fec"|"rtp"|"zixi-pull"|"rist"|"st2110-jpegxs"|"cdi"|"srt-listener"|"srt-caller"|"fujitsu-qos"|"udp", SenderControlPort?: int, SenderIpAddress?: string, SourceListenerAddress?: string, SourceListenerPort?: int, StreamId?: string, VpcInterfaceName?: string, ... (2 more fields)}
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: "MERGE"|"FAILOVER", RecoveryWindow?: int, SourcePriority?: record, State?: "ENABLED"|"DISABLED"}
  --sources: list # item shape: {Decryption?: record, Description?: string, EntitlementArn?: string, IngestPort?: int, MaxBitrate?: int, MaxLatency?: int, MaxSyncBuffer?: int, MediaStreamSourceConfigurations?: list, MinLatency?: int, Name?: string, Protocol?: "zixi-push"|"rtp-fec"|"rtp"|"zixi-pull"|"rist"|"st2110-jpegxs"|"cdi"|"srt-listener"|"srt-caller"|"fujitsu-qos"|"udp", SenderControlPort?: int, SenderIpAddress?: string, SourceListenerAddress?: string, SourceListenerPort?: int, StreamId?: string, VpcInterfaceName?: string, ... (2 more fields)}
  --vpc-interfaces: list # The VPC interfaces you want on the flow. — item shape: {Name: string, NetworkInterfaceType?: "ena"|"efa", RoleArn: string, SecurityGroupIds: list<string>, SubnetId: string}
  --maintenance: record # Create maintenance setting for a flow — shape: {MaintenanceDay?: "Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday"|"Sunday", MaintenanceStartHour?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/flows"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: availabilityZone, var: availability_zone}, {name: entitlements, var: entitlements}, {name: mediaStreams, var: media_streams}, {name: name, var: name}, {name: outputs, var: outputs}, {name: source, var: source}, {name: sourceFailoverConfig, var: source_failover_config}, {name: sources, var: sources}, {name: vpcInterfaces, var: vpc_interfaces}, {name: maintenance, var: maintenance}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, availability_zone: $availability_zone, entitlements: $entitlements, media_streams: $media_streams, name: $name, outputs: $outputs, source: $source, source_failover_config: $source_failover_config, sources: $sources, vpc_interfaces: $vpc_interfaces, maintenance: $maintenance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of flows that are associated with this account. This request returns a paginated result.
#
# GET /v1/flows
# Returns: record<Flows: table<AvailabilityZone: string, Description: string, FlowArn: string, Name: string, SourceType: string, Status: string, Maintenance: record>, NextToken: string>
# operationId: ListFlows
export def "list-flows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListFlows request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListFlows request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListFlows request a second time and specify the NextToken value.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/v1/flows"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new gateway. The request must include at least one network (up to 4).
#
# POST /v1/gateways
# Returns: record<Gateway: record<EgressCidrBlocks: list<string>, GatewayArn: string, GatewayMessages: list<record>, GatewayState: string, Name: string, Networks: list<record>>>
# operationId: CreateGateway
export def "create-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  egress_cidr_blocks: list<string> # The range of IP addresses that are allowed to contribute content or initiate output requests for flows communicating with this gateway. These IP addresses should be in the form of a Classless Inter-Domain Routing (CIDR) block; for example, 10.0.0.0/16.
  name: string # The name of the gateway. This name can not be modified after the gateway is created.
  networks: list # The list of networks that you want to add. — item shape: {CidrBlock: string, Name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/gateways"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: egressCidrBlocks, var: egress_cidr_blocks}, {name: name, var: name}, {name: networks, var: networks}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, egress_cidr_blocks: $egress_cidr_blocks, name: $name, networks: $networks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of gateways that are associated with this account. This request returns a paginated result.
#
# GET /v1/gateways
# Returns: record<Gateways: table<GatewayArn: string, GatewayState: string, Name: string>, NextToken: string>
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
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListGateways request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListGateways request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListGateways request a second time and specify the NextToken value.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/v1/gateways"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a bridge. Before you can delete a bridge, you must stop the bridge.
#
# DELETE /v1/bridges/{bridgeArn}
# Returns: record<BridgeArn: string>
# operationId: DeleteBridge
export def "delete-bridge" [
  bridge_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/bridges/{bridgeArn}"
    path_params: [{name: bridgeArn, var: bridge_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the details of a bridge.
#
# GET /v1/bridges/{bridgeArn}
# Returns: record<Bridge: record<BridgeArn: string, BridgeMessages: list<record>, BridgeState: string, EgressGatewayBridge: record<InstanceId: string, MaxBitrate: int>, IngressGatewayBridge: record<InstanceId: string, MaxBitrate: int, MaxOutputs: int>, Name: string, Outputs: list<record>, PlacementArn: string, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>>>
# operationId: DescribeBridge
export def "describe-bridge" [
  bridge_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/bridges/{bridgeArn}"
    path_params: [{name: bridgeArn, var: bridge_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the bridge
#
# PUT /v1/bridges/{bridgeArn}
# Returns: record<Bridge: record<BridgeArn: string, BridgeMessages: list<record>, BridgeState: string, EgressGatewayBridge: record<InstanceId: string, MaxBitrate: int>, IngressGatewayBridge: record<InstanceId: string, MaxBitrate: int, MaxOutputs: int>, Name: string, Outputs: list<record>, PlacementArn: string, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>>>
# operationId: UpdateBridge
export def "update-bridge" [
  bridge_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --egress-gateway-bridge: record # shape: {MaxBitrate?: int}
  --ingress-gateway-bridge: record # shape: {MaxBitrate?: int, MaxOutputs?: int}
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: "MERGE"|"FAILOVER", RecoveryWindow?: int, SourcePriority?: record, State?: "ENABLED"|"DISABLED"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/bridges/{bridgeArn}"
    path_params: [{name: bridgeArn, var: bridge_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: egressGatewayBridge, var: egress_gateway_bridge}, {name: ingressGatewayBridge, var: ingress_gateway_bridge}, {name: sourceFailoverConfig, var: source_failover_config}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, egress_gateway_bridge: $egress_gateway_bridge, ingress_gateway_bridge: $ingress_gateway_bridge, source_failover_config: $source_failover_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a flow. Before you can delete a flow, you must stop the flow.
#
# DELETE /v1/flows/{flowArn}
# Returns: record<FlowArn: string, Status: string>
# operationId: DeleteFlow
export def "delete-flow" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/flows/{flowArn}"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
#
# GET /v1/flows/{flowArn}
# Returns: record<Flow: record<AvailabilityZone: string, Description: string, EgressIp: string, Entitlements: list<record>, FlowArn: string, MediaStreams: list<record>, Name: string, Outputs: list<record>, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>, Status: string, VpcInterfaces: list<record>, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartHour: string>>, Messages: record<Errors: list<string>>>
# operationId: DescribeFlow
export def "describe-flow" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/flows/{flowArn}"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates flow
#
# PUT /v1/flows/{flowArn}
# Returns: record<Flow: record<AvailabilityZone: string, Description: string, EgressIp: string, Entitlements: list<record>, FlowArn: string, MediaStreams: list<record>, Name: string, Outputs: list<record>, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: string, RecoveryWindow: int, SourcePriority: record, State: string>, Sources: list<record>, Status: string, VpcInterfaces: list<record>, Maintenance: record<MaintenanceDay: string, MaintenanceDeadline: string, MaintenanceScheduledDate: string, MaintenanceStartHour: string>>>
# operationId: UpdateFlow
export def "update-flow" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: "MERGE"|"FAILOVER", RecoveryWindow?: int, SourcePriority?: record, State?: "ENABLED"|"DISABLED"}
  --maintenance: record # Update maintenance setting for a flow — shape: {MaintenanceDay?: "Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday"|"Sunday", MaintenanceScheduledDate?: string, MaintenanceStartHour?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/flows/{flowArn}"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceFailoverConfig, var: source_failover_config}, {name: maintenance, var: maintenance}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_failover_config: $source_failover_config, maintenance: $maintenance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a gateway. Before you can delete a gateway, you must deregister its instances and delete its bridges.
#
# DELETE /v1/gateways/{gatewayArn}
# Returns: record<GatewayArn: string>
# operationId: DeleteGateway
export def "delete-gateway" [
  gateway_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/gateways/{gatewayArn}"
    path_params: [{name: gatewayArn, var: gateway_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_arn: $gateway_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the details of a gateway. The response includes the gateway ARN, name, and CIDR blocks, as well as details about the networks.
#
# GET /v1/gateways/{gatewayArn}
# Returns: record<Gateway: record<EgressCidrBlocks: list<string>, GatewayArn: string, GatewayMessages: list<record>, GatewayState: string, Name: string, Networks: list<record>>>
# operationId: DescribeGateway
export def "describe-gateway" [
  gateway_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/gateways/{gatewayArn}"
    path_params: [{name: gatewayArn, var: gateway_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_arn: $gateway_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters an instance. Before you deregister an instance, all bridges running on the instance must be stopped. If you want to deregister an instance without stopping the bridges, you must use the --force option.
#
# DELETE /v1/gateway-instances/{gatewayInstanceArn}
# Returns: record<GatewayInstanceArn: string, InstanceState: string>
# operationId: DeregisterGatewayInstance
export def "deregister-gateway-instance" [
  gateway_instance_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force the deregistration of an instance. Force will deregister an instance, even if there are bridges running on it.
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
    path: "/v1/gateway-instances/{gatewayInstanceArn}"
    path_params: [{name: gatewayInstanceArn, var: gateway_instance_arn}]
    query: [{name: force, var: force}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    gateway_instance_arn: $gateway_instance_arn, force: $force, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the details of an instance.
#
# GET /v1/gateway-instances/{gatewayInstanceArn}
# Returns: record<GatewayInstance: record<BridgePlacement: string, ConnectionStatus: string, GatewayArn: string, GatewayInstanceArn: string, InstanceId: string, InstanceMessages: list<record>, InstanceState: string, RunningBridgeCount: int>>
# operationId: DescribeGatewayInstance
export def "describe-gateway-instance" [
  gateway_instance_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/gateway-instances/{gatewayInstanceArn}"
    path_params: [{name: gatewayInstanceArn, var: gateway_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_instance_arn: $gateway_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of an existing Gateway Instance.
#
# PUT /v1/gateway-instances/{gatewayInstanceArn}
# Returns: record<BridgePlacement: string, GatewayInstanceArn: string>
# operationId: UpdateGatewayInstance
export def "update-gateway-instance" [
  gateway_instance_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bridge-placement: string@bridge-placement-completer # The availability of the instance to host new bridges. The bridgePlacement property can be LOCKED or AVAILABLE. If it is LOCKED, no new bridges can be deployed to this instance. If it is AVAILABLE, new bridges can be added to this instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/gateway-instances/{gatewayInstanceArn}"
    path_params: [{name: gatewayInstanceArn, var: gateway_instance_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: bridgePlacement, var: bridge_placement}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_instance_arn: $gateway_instance_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, bridge_placement: $bridge_placement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the details of an offering. The response includes the offering description, duration, outbound bandwidth, price, and Amazon Resource Name (ARN).
#
# GET /v1/offerings/{offeringArn}
# Returns: record<Offering: record<CurrencyCode: string, Duration: int, DurationUnits: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ResourceSpecification: record<ReservedBitrate: int, ResourceType: string>>>
# operationId: DescribeOffering
export def "describe-offering" [
  offering_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/offerings/{offeringArn}"
    path_params: [{name: offeringArn, var: offering_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_arn: $offering_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submits a request to purchase an offering. If you already have an active reservation, you can't purchase another offering.
#
# POST /v1/offerings/{offeringArn}
# Returns: record<Reservation: record<CurrencyCode: string, Duration: int, DurationUnits: string, End: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ReservationArn: string, ReservationName: string, ReservationState: string, ResourceSpecification: record<ReservedBitrate: int, ResourceType: string>, Start: string>>
# operationId: PurchaseOffering
export def "purchase-offering" [
  offering_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  reservation_name: string # The name that you want to use for the reservation.
  start: string # The date and time that you want the reservation to begin, in Coordinated Universal Time (UTC). You can specify any date and time between 12:00am on the first day of the current month to the current time on today's date, inclusive. Specify the start in a 24-hour notation. Use the following format: YYYY-MM-DDTHH:mm:SSZ, where T and Z are literal characters. For example, to specify 11:30pm on March 5, 2020, enter 2020-03-05T23:30:00Z.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/offerings/{offeringArn}"
    path_params: [{name: offeringArn, var: offering_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: reservationName, var: reservation_name}, {name: start, var: start}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    offering_arn: $offering_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, reservation_name: $reservation_name, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the details of a reservation. The response includes the reservation name, state, start date and time, and the details of the offering that make up the rest of the reservation (such as price, duration, and outbound bandwidth).
#
# GET /v1/reservations/{reservationArn}
# Returns: record<Reservation: record<CurrencyCode: string, Duration: int, DurationUnits: string, End: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ReservationArn: string, ReservationName: string, ReservationState: string, ResourceSpecification: record<ReservedBitrate: int, ResourceType: string>, Start: string>>
# operationId: DescribeReservation
export def "describe-reservation" [
  reservation_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/reservations/{reservationArn}"
    path_params: [{name: reservationArn, var: reservation_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reservation_arn: $reservation_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Grants entitlements to an existing flow.
#
# POST /v1/flows/{flowArn}/entitlements
# Returns: record<Entitlements: table<DataTransferSubscriberFeePercent: int, Description: string, Encryption: record, EntitlementArn: string, EntitlementStatus: string, Name: string, Subscribers: list>, FlowArn: string>
# operationId: GrantFlowEntitlements
export def "grant-flow-entitlements" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entitlements: list # The list of entitlements that you want to grant. — item shape: {DataTransferSubscriberFeePercent?: int, Description?: string, Encryption?: record, EntitlementStatus?: "ENABLED"|"DISABLED", Name?: string, Subscribers: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/flows/{flowArn}/entitlements"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: entitlements, var: entitlements}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entitlements: $entitlements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
#
# GET /v1/entitlements
# Returns: record<Entitlements: table<DataTransferSubscriberFeePercent: int, EntitlementArn: string, EntitlementName: string>, NextToken: string>
# operationId: ListEntitlements
export def "list-entitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListEntitlements request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 20 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListEntitlements request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListEntitlements request a second time and specify the NextToken value.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/v1/entitlements"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of instances associated with the AWS account. This request returns a paginated result. You can use the filterArn property to display only the instances associated with the selected Gateway Amazon Resource Name (ARN).
#
# GET /v1/gateway-instances
# Returns: record<Instances: table<GatewayArn: string, GatewayInstanceArn: string, InstanceId: string, InstanceState: string>, NextToken: string>
# operationId: ListGatewayInstances
export def "list-gateway-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-arn: string # Filter the list results to display only the instances associated with the selected Gateway Amazon Resource Name (ARN).
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListInstances request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListInstances request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListInstances request a second time and specify the NextToken value.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/v1/gateway-instances"
    query: [{name: filterArn, var: filter_arn}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_arn: $filter_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of all offerings that are available to this account in the current AWS Region. If you have an active reservation (which means you've purchased an offering that has already started and hasn't expired yet), your account isn't eligible for other offerings.
#
# GET /v1/offerings
# Returns: record<NextToken: string, Offerings: table<CurrencyCode: string, Duration: int, DurationUnits: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ResourceSpecification: record>>
# operationId: ListOfferings
export def "list-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListOfferings request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListOfferings request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListOfferings request a second time and specify the NextToken value.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/v1/offerings"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of all reservations that have been purchased by this account in the current AWS Region. This list includes all reservations in all states (such as active and expired).
#
# GET /v1/reservations
# Returns: record<NextToken: string, Reservations: table<CurrencyCode: string, Duration: int, DurationUnits: string, End: string, OfferingArn: string, OfferingDescription: string, PricePerUnit: string, PriceUnits: string, ReservationArn: string, ReservationName: string, ReservationState: string, ResourceSpecification: record, Start: string>>
# operationId: ListReservations
export def "list-reservations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListReservations request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListReservations request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListOfferings request a second time and specify the NextToken value.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/v1/reservations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all tags on an AWS Elemental MediaConnect resource
#
# GET /tags/{resourceArn}
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
#
# POST /tags/{resourceArn}
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
  tags: record # A map from tag keys to values. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters.
]: any -> any {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an output from a bridge.
#
# DELETE /v1/bridges/{bridgeArn}/outputs/{outputName}
# Returns: record<BridgeArn: string, OutputName: string>
# operationId: RemoveBridgeOutput
export def "remove-bridge-output" [
  bridge_arn: string
  output_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/bridges/{bridgeArn}/outputs/{outputName}"
    path_params: [{name: bridgeArn, var: bridge_arn}, {name: outputName, var: output_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, output_name: $output_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing bridge output.
#
# PUT /v1/bridges/{bridgeArn}/outputs/{outputName}
# Returns: record<BridgeArn: string, Output: record<FlowOutput: record<FlowArn: string, FlowSourceArn: string, Name: string>, NetworkOutput: record<IpAddress: string, Name: string, NetworkName: string, Port: int, Protocol: string, Ttl: int>>>
# operationId: UpdateBridgeOutput
export def "update-bridge-output" [
  bridge_arn: string
  output_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --network-output: record # Update an existing network output. — shape: {IpAddress?: string, NetworkName?: string, Port?: int, Protocol?: "zixi-push"|"rtp-fec"|"rtp"|"zixi-pull"|"rist"|"st2110-jpegxs"|"cdi"|"srt-listener"|"srt-caller"|"fujitsu-qos"|"udp", Ttl?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/bridges/{bridgeArn}/outputs/{outputName}"
    path_params: [{name: bridgeArn, var: bridge_arn}, {name: outputName, var: output_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: networkOutput, var: network_output}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, output_name: $output_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, network_output: $network_output
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a source from a bridge.
#
# DELETE /v1/bridges/{bridgeArn}/sources/{sourceName}
# Returns: record<BridgeArn: string, SourceName: string>
# operationId: RemoveBridgeSource
export def "remove-bridge-source" [
  bridge_arn: string
  source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/bridges/{bridgeArn}/sources/{sourceName}"
    path_params: [{name: bridgeArn, var: bridge_arn}, {name: sourceName, var: source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, source_name: $source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing bridge source.
#
# PUT /v1/bridges/{bridgeArn}/sources/{sourceName}
# Returns: record<BridgeArn: string, Source: record<FlowSource: record<FlowArn: string, FlowVpcInterfaceAttachment: record, Name: string, OutputArn: string>, NetworkSource: record<MulticastIp: string, Name: string, NetworkName: string, Port: int, Protocol: string>>>
# operationId: UpdateBridgeSource
export def "update-bridge-source" [
  bridge_arn: string
  source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --flow-source: record # Update the flow source of the bridge. — shape: {FlowArn?: string, FlowVpcInterfaceAttachment?: record}
  --network-source: record # Update the network source of the bridge. — shape: {MulticastIp?: string, NetworkName?: string, Port?: int, Protocol?: "zixi-push"|"rtp-fec"|"rtp"|"zixi-pull"|"rist"|"st2110-jpegxs"|"cdi"|"srt-listener"|"srt-caller"|"fujitsu-qos"|"udp"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/bridges/{bridgeArn}/sources/{sourceName}"
    path_params: [{name: bridgeArn, var: bridge_arn}, {name: sourceName, var: source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowSource, var: flow_source}, {name: networkSource, var: network_source}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, source_name: $source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_source: $flow_source, network_source: $network_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a media stream from a flow. This action is only available if the media stream is not associated with a source or output.
#
# DELETE /v1/flows/{flowArn}/mediaStreams/{mediaStreamName}
# Returns: record<FlowArn: string, MediaStreamName: string>
# operationId: RemoveFlowMediaStream
export def "remove-flow-media-stream" [
  flow_arn: string
  media_stream_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/flows/{flowArn}/mediaStreams/{mediaStreamName}"
    path_params: [{name: flowArn, var: flow_arn}, {name: mediaStreamName, var: media_stream_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    flow_arn: $flow_arn, media_stream_name: $media_stream_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing media stream.
#
# PUT /v1/flows/{flowArn}/mediaStreams/{mediaStreamName}
# Returns: record<FlowArn: string, MediaStream: record<Attributes: record<Fmtp: record, Lang: string>, ClockRate: int, Description: string, Fmt: int, MediaStreamId: int, MediaStreamName: string, MediaStreamType: string, VideoFormat: string>>
# operationId: UpdateFlowMediaStream
export def "update-flow-media-stream" [
  flow_arn: string
  media_stream_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --attributes: record # Attributes that are related to the media stream. — shape: {Fmtp?: record, Lang?: string}
  --clock-rate: int # The sample rate (in Hz) for the stream. If the media stream type is video or ancillary data, set this value to 90000. If the media stream type is audio, set this value to either 48000 or 96000.
  --description: string # Description
  --media-stream-type: string@media-stream-type-completer # The type of media stream.
  --video-format: string # The resolution of the video.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/flows/{flowArn}/mediaStreams/{mediaStreamName}"
    path_params: [{name: flowArn, var: flow_arn}, {name: mediaStreamName, var: media_stream_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: clockRate, var: clock_rate}, {name: description, var: description}, {name: mediaStreamType, var: media_stream_type}, {name: videoFormat, var: video_format}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, media_stream_name: $media_stream_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, attributes: $attributes, clock_rate: $clock_rate, description: $description, media_stream_type: $media_stream_type, video_format: $video_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
#
# DELETE /v1/flows/{flowArn}/outputs/{outputArn}
# Returns: record<FlowArn: string, OutputArn: string>
# operationId: RemoveFlowOutput
export def "remove-flow-output" [
  flow_arn: string
  output_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/flows/{flowArn}/outputs/{outputArn}"
    path_params: [{name: flowArn, var: flow_arn}, {name: outputArn, var: output_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, output_arn: $output_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing flow output.
#
# PUT /v1/flows/{flowArn}/outputs/{outputArn}
# Returns: record<FlowArn: string, Output: record<DataTransferSubscriberFeePercent: int, Description: string, Destination: string, Encryption: record<Algorithm: string, ConstantInitializationVector: string, DeviceId: string, KeyType: string, Region: string, ResourceId: string, RoleArn: string, SecretArn: string, Url: string>, EntitlementArn: string, ListenerAddress: string, MediaLiveInputArn: string, MediaStreamOutputConfigurations: list<record>, Name: string, OutputArn: string, Port: int, Transport: record<CidrAllowList: list, MaxBitrate: int, MaxLatency: int, MaxSyncBuffer: int, MinLatency: int, Protocol: string, RemoteId: string, SenderControlPort: int, SenderIpAddress: string, SmoothingLatency: int, SourceListenerAddress: string, SourceListenerPort: int, StreamId: string>, VpcInterfaceAttachment: record<VpcInterfaceName: string>, BridgeArn: string, BridgePorts: list<int>>>
# operationId: UpdateFlowOutput
export def "update-flow-output" [
  flow_arn: string
  output_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --cidr-allow-list: list<string> # The range of IP addresses that should be allowed to initiate output requests to this flow. These IP addresses should be in the form of a Classless Inter-Domain Routing (CIDR) block; for example, 10.0.0.0/16.
  --description: string # A description of the output. This description appears only on the AWS Elemental MediaConnect console and will not be seen by the end user.
  --destination: string # The IP address where you want to send the output.
  --encryption: record # Information about the encryption of the flow. — shape: {Algorithm?: "aes128"|"aes192"|"aes256", ConstantInitializationVector?: string, DeviceId?: string, KeyType?: "speke"|"static-key"|"srt-password", Region?: string, ResourceId?: string, RoleArn?: string, SecretArn?: string, Url?: string}
  --max-latency: int # The maximum latency in milliseconds. This parameter applies only to RIST-based, Zixi-based, and Fujitsu-based streams.
  --media-stream-output-configurations: list # The media streams that are associated with the output, and the parameters for those associations. — item shape: {DestinationConfigurations?: list, EncodingName: "jxsv"|"raw"|"smpte291"|"pcm", EncodingParameters?: record, MediaStreamName: string}
  --min-latency: int # The minimum latency in milliseconds for SRT-based streams. In streams that use the SRT protocol, this value that you set on your MediaConnect source or output represents the minimal potential latency of that connection. The latency of the stream is set to the highest number between the sender’s minimum latency and the receiver’s minimum latency.
  --port: int # The port to use when content is distributed to this output.
  --protocol: string@protocol-completer # The protocol to use for the output.
  --remote-id: string # The remote ID for the Zixi-pull stream.
  --sender-control-port: int # The port that the flow uses to send outbound requests to initiate connection with the sender.
  --sender-ip-address: string # The IP address that the flow communicates with to initiate connection with the sender.
  --smoothing-latency: int # The smoothing latency in milliseconds for RIST, RTP, and RTP-FEC streams.
  --stream-id: string # The stream ID that you want to use for this transport. This parameter applies only to Zixi and SRT caller-based streams.
  --vpc-interface-attachment: record # The settings for attaching a VPC interface to an resource. — shape: {VpcInterfaceName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/flows/{flowArn}/outputs/{outputArn}"
    path_params: [{name: flowArn, var: flow_arn}, {name: outputArn, var: output_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: cidrAllowList, var: cidr_allow_list}, {name: description, var: description}, {name: destination, var: destination}, {name: encryption, var: encryption}, {name: maxLatency, var: max_latency}, {name: mediaStreamOutputConfigurations, var: media_stream_output_configurations}, {name: minLatency, var: min_latency}, {name: port, var: port}, {name: protocol, var: protocol}, {name: remoteId, var: remote_id}, {name: senderControlPort, var: sender_control_port}, {name: senderIpAddress, var: sender_ip_address}, {name: smoothingLatency, var: smoothing_latency}, {name: streamId, var: stream_id}, {name: vpcInterfaceAttachment, var: vpc_interface_attachment}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, output_arn: $output_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, cidr_allow_list: $cidr_allow_list, description: $description, destination: $destination, encryption: $encryption, max_latency: $max_latency, media_stream_output_configurations: $media_stream_output_configurations, min_latency: $min_latency, port: $port, protocol: $protocol, remote_id: $remote_id, sender_control_port: $sender_control_port, sender_ip_address: $sender_ip_address, smoothing_latency: $smoothing_latency, stream_id: $stream_id, vpc_interface_attachment: $vpc_interface_attachment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a source from an existing flow. This request can be made only if there is more than one source on the flow.
#
# DELETE /v1/flows/{flowArn}/source/{sourceArn}
# Returns: record<FlowArn: string, SourceArn: string>
# operationId: RemoveFlowSource
export def "remove-flow-source" [
  flow_arn: string
  source_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/flows/{flowArn}/source/{sourceArn}"
    path_params: [{name: flowArn, var: flow_arn}, {name: sourceArn, var: source_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, source_arn: $source_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the source of a flow.
#
# PUT /v1/flows/{flowArn}/source/{sourceArn}
# Returns: record<FlowArn: string, Source: record<DataTransferSubscriberFeePercent: int, Decryption: record<Algorithm: string, ConstantInitializationVector: string, DeviceId: string, KeyType: string, Region: string, ResourceId: string, RoleArn: string, SecretArn: string, Url: string>, Description: string, EntitlementArn: string, IngestIp: string, IngestPort: int, MediaStreamSourceConfigurations: list<record>, Name: string, SenderControlPort: int, SenderIpAddress: string, SourceArn: string, Transport: record<CidrAllowList: list, MaxBitrate: int, MaxLatency: int, MaxSyncBuffer: int, MinLatency: int, Protocol: string, RemoteId: string, SenderControlPort: int, SenderIpAddress: string, SmoothingLatency: int, SourceListenerAddress: string, SourceListenerPort: int, StreamId: string>, VpcInterfaceName: string, WhitelistCidr: string, GatewayBridgeSource: record<BridgeArn: string, VpcInterfaceAttachment: record>>>
# operationId: UpdateFlowSource
export def "update-flow-source" [
  flow_arn: string
  source_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --decryption: record # Information about the encryption of the flow. — shape: {Algorithm?: "aes128"|"aes192"|"aes256", ConstantInitializationVector?: string, DeviceId?: string, KeyType?: "speke"|"static-key"|"srt-password", Region?: string, ResourceId?: string, RoleArn?: string, SecretArn?: string, Url?: string}
  --description: string # A description for the source. This value is not used or seen outside of the current AWS Elemental MediaConnect account.
  --entitlement-arn: string # The ARN of the entitlement that allows you to subscribe to this flow. The entitlement is set by the flow originator, and the ARN is generated as part of the originator's flow.
  --ingest-port: int # The port that the flow will be listening on for incoming content.
  --max-bitrate: int # The smoothing max bitrate (in bps) for RIST, RTP, and RTP-FEC streams.
  --max-latency: int # The maximum latency in milliseconds. This parameter applies only to RIST-based, Zixi-based, and Fujitsu-based streams.
  --max-sync-buffer: int # The size of the buffer (in milliseconds) to use to sync incoming source data.
  --media-stream-source-configurations: list # The media streams that are associated with the source, and the parameters for those associations. — item shape: {EncodingName: "jxsv"|"raw"|"smpte291"|"pcm", InputConfigurations?: list, MediaStreamName: string}
  --min-latency: int # The minimum latency in milliseconds for SRT-based streams. In streams that use the SRT protocol, this value that you set on your MediaConnect source or output represents the minimal potential latency of that connection. The latency of the stream is set to the highest number between the sender’s minimum latency and the receiver’s minimum latency.
  --protocol: string@protocol-completer # The protocol that is used by the source.
  --sender-control-port: int # The port that the flow uses to send outbound requests to initiate connection with the sender.
  --sender-ip-address: string # The IP address that the flow communicates with to initiate connection with the sender.
  --source-listener-address: string # Source IP or domain name for SRT-caller protocol.
  --source-listener-port: int # Source port for SRT-caller protocol.
  --stream-id: string # The stream ID that you want to use for this transport. This parameter applies only to Zixi and SRT caller-based streams.
  --vpc-interface-name: string # The name of the VPC interface to use for this source.
  --whitelist-cidr: string # The range of IP addresses that should be allowed to contribute content to your source. These IP addresses should be in the form of a Classless Inter-Domain Routing (CIDR) block; for example, 10.0.0.0/16.
  --gateway-bridge-source: record # The source configuration for cloud flows receiving a stream from a bridge. — shape: {BridgeArn?: string, VpcInterfaceAttachment?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/flows/{flowArn}/source/{sourceArn}"
    path_params: [{name: flowArn, var: flow_arn}, {name: sourceArn, var: source_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: decryption, var: decryption}, {name: description, var: description}, {name: entitlementArn, var: entitlement_arn}, {name: ingestPort, var: ingest_port}, {name: maxBitrate, var: max_bitrate}, {name: maxLatency, var: max_latency}, {name: maxSyncBuffer, var: max_sync_buffer}, {name: mediaStreamSourceConfigurations, var: media_stream_source_configurations}, {name: minLatency, var: min_latency}, {name: protocol, var: protocol}, {name: senderControlPort, var: sender_control_port}, {name: senderIpAddress, var: sender_ip_address}, {name: sourceListenerAddress, var: source_listener_address}, {name: sourceListenerPort, var: source_listener_port}, {name: streamId, var: stream_id}, {name: vpcInterfaceName, var: vpc_interface_name}, {name: whitelistCidr, var: whitelist_cidr}, {name: gatewayBridgeSource, var: gateway_bridge_source}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, source_arn: $source_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, decryption: $decryption, description: $description, entitlement_arn: $entitlement_arn, ingest_port: $ingest_port, max_bitrate: $max_bitrate, max_latency: $max_latency, max_sync_buffer: $max_sync_buffer, media_stream_source_configurations: $media_stream_source_configurations, min_latency: $min_latency, protocol: $protocol, sender_control_port: $sender_control_port, sender_ip_address: $sender_ip_address, source_listener_address: $source_listener_address, source_listener_port: $source_listener_port, stream_id: $stream_id, vpc_interface_name: $vpc_interface_name, whitelist_cidr: $whitelist_cidr, gateway_bridge_source: $gateway_bridge_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a VPC Interface from an existing flow. This request can be made only on a VPC interface that does not have a Source or Output associated with it. If the VPC interface is referenced by a Source or Output, you must first delete or update the Source or Output to no longer reference the VPC interface.
#
# DELETE /v1/flows/{flowArn}/vpcInterfaces/{vpcInterfaceName}
# Returns: record<FlowArn: string, NonDeletedNetworkInterfaceIds: list<string>, VpcInterfaceName: string>
# operationId: RemoveFlowVpcInterface
export def "remove-flow-vpc-interface" [
  flow_arn: string
  vpc_interface_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/flows/{flowArn}/vpcInterfaces/{vpcInterfaceName}"
    path_params: [{name: flowArn, var: flow_arn}, {name: vpcInterfaceName, var: vpc_interface_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    flow_arn: $flow_arn, vpc_interface_name: $vpc_interface_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
#
# DELETE /v1/flows/{flowArn}/entitlements/{entitlementArn}
# Returns: record<EntitlementArn: string, FlowArn: string>
# operationId: RevokeFlowEntitlement
export def "revoke-flow-entitlement" [
  flow_arn: string
  entitlement_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/flows/{flowArn}/entitlements/{entitlementArn}"
    path_params: [{name: flowArn, var: flow_arn}, {name: entitlementArn, var: entitlement_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, entitlement_arn: $entitlement_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
#
# PUT /v1/flows/{flowArn}/entitlements/{entitlementArn}
# Returns: record<Entitlement: record<DataTransferSubscriberFeePercent: int, Description: string, Encryption: record<Algorithm: string, ConstantInitializationVector: string, DeviceId: string, KeyType: string, Region: string, ResourceId: string, RoleArn: string, SecretArn: string, Url: string>, EntitlementArn: string, EntitlementStatus: string, Name: string, Subscribers: list<string>>, FlowArn: string>
# operationId: UpdateFlowEntitlement
export def "update-flow-entitlement" [
  flow_arn: string
  entitlement_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the entitlement. This description appears only on the AWS Elemental MediaConnect console and will not be seen by the subscriber or end user.
  --encryption: record # Information about the encryption of the flow. — shape: {Algorithm?: "aes128"|"aes192"|"aes256", ConstantInitializationVector?: string, DeviceId?: string, KeyType?: "speke"|"static-key"|"srt-password", Region?: string, ResourceId?: string, RoleArn?: string, SecretArn?: string, Url?: string}
  --entitlement-status: string@entitlement-status-completer # An indication of whether you want to enable the entitlement to allow access, or disable it to stop streaming content to the subscriber’s flow temporarily. If you don’t specify the entitlementStatus field in your request, MediaConnect leaves the value unchanged.
  --subscribers: list<string> # The AWS account IDs that you want to share your content with. The receiving accounts (subscribers) will be allowed to create their own flow using your content as the source.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/flows/{flowArn}/entitlements/{entitlementArn}"
    path_params: [{name: flowArn, var: flow_arn}, {name: entitlementArn, var: entitlement_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: encryption, var: encryption}, {name: entitlementStatus, var: entitlement_status}, {name: subscribers, var: subscribers}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, entitlement_arn: $entitlement_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, encryption: $encryption, entitlement_status: $entitlement_status, subscribers: $subscribers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a flow.
#
# POST /v1/flows/start/{flowArn}
# Returns: record<FlowArn: string, Status: string>
# operationId: StartFlow
export def "start-flow" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    method: post
    path: "/v1/flows/start/{flowArn}"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a flow.
#
# POST /v1/flows/stop/{flowArn}
# Returns: record<FlowArn: string, Status: string>
# operationId: StopFlow
export def "stop-flow" [
  flow_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    method: post
    path: "/v1/flows/stop/{flowArn}"
    path_params: [{name: flowArn, var: flow_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    flow_arn: $flow_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes specified tags from a resource.
#
# DELETE /tags/{resourceArn}
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
  --tag-keys: list<string> # The keys of the tags to be removed. (required)
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
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

# Updates the bridge state
#
# PUT /v1/bridges/{bridgeArn}/state
# Returns: record<BridgeArn: string, DesiredState: string>
# operationId: UpdateBridgeState
export def "update-bridge-state" [
  bridge_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  desired_state: string@desired-state-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/bridges/{bridgeArn}/state"
    path_params: [{name: bridgeArn, var: bridge_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: desiredState, var: desired_state}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    bridge_arn: $bridge_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, desired_state: $desired_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
