# Auto-generated client for Dataflow API v1b3
# Source: https://api.apis.guru/v2/specs/googleapis.com/dataflow/v1b3/openapi.json
# Auth: --token flag or $env.DATAFLOW_API_TOKEN

const CLIENT = {
  base_url: "https://dataflow.googleapis.com"
  token_env_var: "DATAFLOW_API_TOKEN"
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

def base-url-completer [] { ["https://dataflow.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def filter-completer [] { ["ACTIVE" "ALL" "TERMINATED" "UNKNOWN"] }
def view-completer [] { ["JOB_VIEW_ALL" "JOB_VIEW_DESCRIPTION" "JOB_VIEW_SUMMARY" "JOB_VIEW_UNKNOWN"] }
def current-state-completer [] { ["JOB_STATE_CANCELLED" "JOB_STATE_CANCELLING" "JOB_STATE_DONE" "JOB_STATE_DRAINED" "JOB_STATE_DRAINING" "JOB_STATE_FAILED" "JOB_STATE_PENDING" "JOB_STATE_QUEUED" "JOB_STATE_RESOURCE_CLEANING_UP" "JOB_STATE_RUNNING" "JOB_STATE_STOPPED" "JOB_STATE_UNKNOWN" "JOB_STATE_UPDATED"] }
def requested-state-completer [] { ["JOB_STATE_CANCELLED" "JOB_STATE_CANCELLING" "JOB_STATE_DONE" "JOB_STATE_DRAINED" "JOB_STATE_DRAINING" "JOB_STATE_FAILED" "JOB_STATE_PENDING" "JOB_STATE_QUEUED" "JOB_STATE_RESOURCE_CLEANING_UP" "JOB_STATE_RUNNING" "JOB_STATE_STOPPED" "JOB_STATE_UNKNOWN" "JOB_STATE_UPDATED"] }
def type-completer [] { ["JOB_TYPE_BATCH" "JOB_TYPE_STREAMING" "JOB_TYPE_UNKNOWN"] }
def data-format-completer [] { ["BROTLI" "DATA_FORMAT_UNSPECIFIED" "JSON" "RAW" "ZLIB"] }
def minimum-importance-completer [] { ["JOB_MESSAGE_BASIC" "JOB_MESSAGE_DEBUG" "JOB_MESSAGE_DETAILED" "JOB_MESSAGE_ERROR" "JOB_MESSAGE_IMPORTANCE_UNKNOWN" "JOB_MESSAGE_WARNING"] }
def view-completer-1 [] { ["METADATA_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    dataflow-projects-worker-messages: "record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>>"
    dataflow-projects-jobs-list: "record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string>"
    dataflow-projects-jobs-create: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-jobs-get: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-jobs-update: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-jobs-debug-get-config: "record<config: string>"
    dataflow-projects-jobs-debug-send-capture: "record"
    dataflow-projects-jobs-messages-list: "record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string>"
    dataflow-projects-jobs-get-metrics: "record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>>"
    dataflow-projects-jobs-work-items-lease: "record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>>"
    dataflow-projects-jobs-work-items-report-status: "record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>>"
    dataflow-projects-jobs-snapshot: "record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>"
    dataflow-projects-jobs-aggregated: "record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string>"
    dataflow-projects-locations-worker-messages: "record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>>"
    dataflow-projects-locations-flex-templates-launch: "record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>>"
    dataflow-projects-locations-jobs-list: "record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string>"
    dataflow-projects-locations-jobs-create: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-locations-jobs-get: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-locations-jobs-update: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-locations-jobs-debug-get-config: "record<config: string>"
    dataflow-projects-locations-jobs-debug-send-capture: "record"
    dataflow-projects-locations-jobs-get-execution-details: "record<nextPageToken: string, stages: table<endTime: string, metrics: list, progress: record, stageId: string, startTime: string, state: string, stragglerSummary: record>>"
    dataflow-projects-locations-jobs-messages-list: "record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string>"
    dataflow-projects-locations-jobs-get-metrics: "record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>>"
    dataflow-projects-locations-jobs-snapshots-list: "record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>>"
    dataflow-projects-locations-jobs-stages-get-execution-details: "record<nextPageToken: string, workers: table<workItems: list, workerName: string>>"
    dataflow-projects-locations-jobs-work-items-lease: "record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>>"
    dataflow-projects-locations-jobs-work-items-report-status: "record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>>"
    dataflow-projects-locations-jobs-snapshot: "record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>"
    dataflow-projects-locations-snapshots-list: "record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>>"
    dataflow-projects-locations-snapshots-delete: "record"
    dataflow-projects-locations-snapshots-get: "record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>"
    dataflow-projects-locations-templates-create: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-locations-templates-get: "record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string>"
    dataflow-projects-locations-templates-launch: "record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>>"
    dataflow-projects-delete-snapshots: "record"
    dataflow-projects-snapshots-list: "record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>>"
    dataflow-projects-snapshots-get: "record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>"
    dataflow-projects-templates-create: "record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>"
    dataflow-projects-templates-get: "record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string>"
    dataflow-projects-templates-launch: "record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["dataflow-projects-worker-messages" "dataflow-projects-jobs-list" "dataflow-projects-jobs-create" "dataflow-projects-jobs-get" "dataflow-projects-jobs-update" "dataflow-projects-jobs-debug-get-config" "dataflow-projects-jobs-debug-send-capture" "dataflow-projects-jobs-messages-list" "dataflow-projects-jobs-get-metrics" "dataflow-projects-jobs-work-items-lease" "dataflow-projects-jobs-work-items-report-status" "dataflow-projects-jobs-snapshot" "dataflow-projects-jobs-aggregated" "dataflow-projects-locations-worker-messages" "dataflow-projects-locations-flex-templates-launch" "dataflow-projects-locations-jobs-list" "dataflow-projects-locations-jobs-create" "dataflow-projects-locations-jobs-get" "dataflow-projects-locations-jobs-update" "dataflow-projects-locations-jobs-debug-get-config" "dataflow-projects-locations-jobs-debug-send-capture" "dataflow-projects-locations-jobs-get-execution-details" "dataflow-projects-locations-jobs-messages-list" "dataflow-projects-locations-jobs-get-metrics" "dataflow-projects-locations-jobs-snapshots-list" "dataflow-projects-locations-jobs-stages-get-execution-details" "dataflow-projects-locations-jobs-work-items-lease" "dataflow-projects-locations-jobs-work-items-report-status" "dataflow-projects-locations-jobs-snapshot" "dataflow-projects-locations-snapshots-list" "dataflow-projects-locations-snapshots-delete" "dataflow-projects-locations-snapshots-get" "dataflow-projects-locations-templates-create" "dataflow-projects-locations-templates-get" "dataflow-projects-locations-templates-launch" "dataflow-projects-delete-snapshots" "dataflow-projects-snapshots-list" "dataflow-projects-snapshots-get" "dataflow-projects-templates-create" "dataflow-projects-templates-get" "dataflow-projects-templates-launch" "commands"] | sort) } | get name | first)
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

# Send a worker_message to the service.
#
# POST /v1b3/projects/{projectId}/WorkerMessages
# Returns: record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>>
# operationId: dataflow.projects.workerMessages
export def "dataflow-projects-worker-messages" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job.
  --worker-messages: list # The WorkerMessages to send. — item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/WorkerMessages"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: workerMessages, var: worker_messages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location, worker_messages: $worker_messages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the jobs of a project. To list the jobs of a project in a region, we recommend using `projects.locations.jobs.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). To list the all jobs across all regions, use `projects.jobs.aggregated`. Using `projects.jobs.list` is not recommended, as you can only get the list of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs
# Returns: record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string>
# operationId: dataflow.projects.jobs.list
export def "dataflow-projects-jobs-list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string@filter-completer # The kind of filter to use.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # Optional. The job name. Optional.
  --page-size: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --page-token: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/jobs"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: location, var: location}, {name: name, var: name}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, location: $location, name: $name, page_size: $page_size, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Cloud Dataflow job. To create a job, we recommend using `projects.locations.jobs.create` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.create` is not recommended, as your job will always start in `us-central1`. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/jobs
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.jobs.create
export def "dataflow-projects-jobs-create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --replace-job-id: string # Deprecated. This field is now in the Job message.
  --view: string@view-completer # The level of information requested in response.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job. (spec name: location)
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to. (spec name: projectId)
  --body-replace-job-id: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job. (spec name: replaceJobId)
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/jobs"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: location, var: location}, {name: replaceJobId, var: replace_job_id}, {name: view, var: view}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientRequestId, var: client_request_id}, {name: createTime, var: create_time}, {name: createdFromSnapshotId, var: created_from_snapshot_id}, {name: currentState, var: current_state}, {name: currentStateTime, var: current_state_time}, {name: environment, var: environment}, {name: executionInfo, var: execution_info}, {name: id, var: id}, {name: jobMetadata, var: job_metadata}, {name: labels, var: labels}, {name: location, var: body_location}, {name: name, var: name}, {name: pipelineDescription, var: pipeline_description}, {name: projectId, var: body_project_id}, {name: replaceJobId, var: body_replace_job_id}, {name: replacedByJobId, var: replaced_by_job_id}, {name: requestedState, var: requested_state}, {name: satisfiesPzs, var: satisfies_pzs}, {name: stageStates, var: stage_states}, {name: startTime, var: start_time}, {name: steps, var: steps}, {name: stepsLocation, var: steps_location}, {name: tempFiles, var: temp_files}, {name: transformNameMapping, var: transform_name_mapping}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location, replace_job_id: $replace_job_id, view: $view, client_request_id: $client_request_id, create_time: $create_time, created_from_snapshot_id: $created_from_snapshot_id, current_state: $current_state, current_state_time: $current_state_time, environment: $environment, execution_info: $execution_info, id: $id, job_metadata: $job_metadata, labels: $labels, body_location: $body_location, name: $name, pipeline_description: $pipeline_description, body_project_id: $body_project_id, body_replace_job_id: $body_replace_job_id, replaced_by_job_id: $replaced_by_job_id, requested_state: $requested_state, satisfies_pzs: $satisfies_pzs, stage_states: $stage_states, start_time: $start_time, steps: $steps, steps_location: $steps_location, temp_files: $temp_files, transform_name_mapping: $transform_name_mapping, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the state of the specified Cloud Dataflow job. To get the state of a job, we recommend using `projects.locations.jobs.get` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.get` is not recommended, as you can only get the state of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.jobs.get
export def "dataflow-projects-jobs-get" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --view: string@view-completer # The level of information requested in response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: location, var: location}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the state of an existing Cloud Dataflow job. To update the state of an existing job, we recommend using `projects.locations.jobs.update` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.update` is not recommended, as you can only update the state of jobs that are running in `us-central1`.
#
# PUT /v1b3/projects/{projectId}/jobs/{jobId}
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.jobs.update
export def "dataflow-projects-jobs-update" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --update-mask: string # The list of fields to update relative to Job. If empty, only RequestedJobState will be considered for update. If the FieldMask is not empty and RequestedJobState is none/empty, The fields specified in the update mask will be the only ones considered for update. If both RequestedJobState and update_mask are specified, we will first handle RequestedJobState and then the update_mask fields.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job. (spec name: location)
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to. (spec name: projectId)
  --replace-job-id: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1b3/projects/{projectId}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: location, var: location}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientRequestId, var: client_request_id}, {name: createTime, var: create_time}, {name: createdFromSnapshotId, var: created_from_snapshot_id}, {name: currentState, var: current_state}, {name: currentStateTime, var: current_state_time}, {name: environment, var: environment}, {name: executionInfo, var: execution_info}, {name: id, var: id}, {name: jobMetadata, var: job_metadata}, {name: labels, var: labels}, {name: location, var: body_location}, {name: name, var: name}, {name: pipelineDescription, var: pipeline_description}, {name: projectId, var: body_project_id}, {name: replaceJobId, var: replace_job_id}, {name: replacedByJobId, var: replaced_by_job_id}, {name: requestedState, var: requested_state}, {name: satisfiesPzs, var: satisfies_pzs}, {name: stageStates, var: stage_states}, {name: startTime, var: start_time}, {name: steps, var: steps}, {name: stepsLocation, var: steps_location}, {name: tempFiles, var: temp_files}, {name: transformNameMapping, var: transform_name_mapping}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location, update_mask: $update_mask, client_request_id: $client_request_id, create_time: $create_time, created_from_snapshot_id: $created_from_snapshot_id, current_state: $current_state, current_state_time: $current_state_time, environment: $environment, execution_info: $execution_info, id: $id, job_metadata: $job_metadata, labels: $labels, body_location: $body_location, name: $name, pipeline_description: $pipeline_description, body_project_id: $body_project_id, replace_job_id: $replace_job_id, replaced_by_job_id: $replaced_by_job_id, requested_state: $requested_state, satisfies_pzs: $satisfies_pzs, stage_states: $stage_states, start_time: $start_time, steps: $steps, steps_location: $steps_location, temp_files: $temp_files, transform_name_mapping: $transform_name_mapping, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get encoded debug configuration for component. Not cacheable.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/debug/getConfig
# Returns: record<config: string>
# operationId: dataflow.projects.jobs.debug.getConfig
export def "dataflow-projects-jobs-debug-get-config" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --component-id: string # The internal component id for which debug configuration is requested.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/jobs/{jobId}/debug/getConfig"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentId, var: component_id}, {name: location, var: location}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, component_id: $component_id, location: $location, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send encoded debug capture data for component.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/debug/sendCapture
# Returns: record
# operationId: dataflow.projects.jobs.debug.sendCapture
export def "dataflow-projects-jobs-debug-send-capture" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --component-id: string # The internal component id for which debug information is sent.
  --data: string # The encoded debug information.
  --data-format: string@data-format-completer # Format for the data field above (id=5).
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/jobs/{jobId}/debug/sendCapture"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentId, var: component_id}, {name: data, var: data}, {name: dataFormat, var: data_format}, {name: location, var: location}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, component_id: $component_id, data: $data, data_format: $data_format, location: $location, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.messages.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.messages.list` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}/messages
# Returns: record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string>
# operationId: dataflow.projects.jobs.messages.list
export def "dataflow-projects-jobs-messages-list" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-time: string # Return only messages with timestamps < end_time. The default is now (i.e. return up to the latest messages available).
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --minimum-importance: string@minimum-importance-completer # Filter to only get messages with importance >= level
  --page-size: int # If specified, determines the maximum number of messages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --start-time: string # If specified, return only messages with timestamps >= start_time. The default is the job creation time (i.e. beginning of messages).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/jobs/{jobId}/messages"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endTime, var: end_time}, {name: location, var: location}, {name: minimumImportance, var: minimum_importance}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: startTime, var: start_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_time: $end_time, location: $location, minimum_importance: $minimum_importance, page_size: $page_size, page_token: $page_token, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.getMetrics` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.getMetrics` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}/metrics
# Returns: record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>>
# operationId: dataflow.projects.jobs.getMetrics
export def "dataflow-projects-jobs-get-metrics" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --start-time: string # Return only metric data that has changed since this time. Default is to return all information about all metrics for the job.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/jobs/{jobId}/metrics"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: location, var: location}, {name: startTime, var: start_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leases a dataflow WorkItem to run.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/workItems:lease
# Returns: record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>>
# operationId: dataflow.projects.jobs.workItems.lease
export def "dataflow-projects-jobs-work-items-lease" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --requested-lease-duration: string # The initial lease period. (format: google-duration)
  --unified-worker-request: record # Untranslated bag-of-bytes WorkRequest from UnifiedWorker.
  --work-item-types: list<string> # Filter for WorkItem type.
  --worker-capabilities: list<string> # Worker capabilities. WorkItems might be limited to workers with specific capabilities.
  --worker-id: string # Identifies the worker leasing work -- typically the ID of the virtual machine running the worker.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/jobs/{jobId}/workItems:lease"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentWorkerTime, var: current_worker_time}, {name: location, var: location}, {name: requestedLeaseDuration, var: requested_lease_duration}, {name: unifiedWorkerRequest, var: unified_worker_request}, {name: workItemTypes, var: work_item_types}, {name: workerCapabilities, var: worker_capabilities}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, current_worker_time: $current_worker_time, location: $location, requested_lease_duration: $requested_lease_duration, unified_worker_request: $unified_worker_request, work_item_types: $work_item_types, worker_capabilities: $worker_capabilities, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reports the status of dataflow WorkItems leased by a worker.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/workItems:reportStatus
# Returns: record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>>
# operationId: dataflow.projects.jobs.workItems.reportStatus
export def "dataflow-projects-jobs-work-items-report-status" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --unified-worker-request: record # Untranslated bag-of-bytes WorkProgressUpdateRequest from UnifiedWorker.
  --work-item-statuses: list # The order is unimportant, except that the order of the WorkItemServiceState messages in the ReportWorkItemStatusResponse corresponds to the order of WorkItemStatus messages here. — item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
  --worker-id: string # The ID of the worker reporting the WorkItem status. If this does not match the ID of the worker which the Dataflow service believes currently has the lease on the WorkItem, the report will be dropped (with an error response).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/jobs/{jobId}/workItems:reportStatus"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentWorkerTime, var: current_worker_time}, {name: location, var: location}, {name: unifiedWorkerRequest, var: unified_worker_request}, {name: workItemStatuses, var: work_item_statuses}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, current_worker_time: $current_worker_time, location: $location, unified_worker_request: $unified_worker_request, work_item_statuses: $work_item_statuses, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Snapshot the state of a streaming job.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}:snapshot
# Returns: record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>
# operationId: dataflow.projects.jobs.snapshot
export def "dataflow-projects-jobs-snapshot" [
  project_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --description: string # User specified description of the snapshot. Maybe empty.
  --location: string # The location that contains this job.
  --snapshot-sources: oneof<nothing, bool> # If true, perform snapshots for sources which support this.
  --ttl: string # TTL for the snapshot. (format: google-duration)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/jobs/{jobId}:snapshot"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: location, var: location}, {name: snapshotSources, var: snapshot_sources}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, location: $location, snapshot_sources: $snapshot_sources, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the jobs of a project across all regions.
#
# GET /v1b3/projects/{projectId}/jobs:aggregated
# Returns: record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string>
# operationId: dataflow.projects.jobs.aggregated
export def "dataflow-projects-jobs-aggregated" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string@filter-completer # The kind of filter to use.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # Optional. The job name. Optional.
  --page-size: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --page-token: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/jobs:aggregated"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: location, var: location}, {name: name, var: name}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, location: $location, name: $name, page_size: $page_size, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a worker_message to the service.
#
# POST /v1b3/projects/{projectId}/locations/{location}/WorkerMessages
# Returns: record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>>
# operationId: dataflow.projects.locations.workerMessages
export def "dataflow-projects-locations-worker-messages" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job. (spec name: location)
  --worker-messages: list # The WorkerMessages to send. — item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/WorkerMessages"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: body_location}, {name: workerMessages, var: worker_messages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_location: $body_location, worker_messages: $worker_messages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Launch a job with a FlexTemplate.
#
# POST /v1b3/projects/{projectId}/locations/{location}/flexTemplates:launch
# Returns: record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>>
# operationId: dataflow.projects.locations.flexTemplates.launch
export def "dataflow-projects-locations-flex-templates-launch" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --launch-parameter: record # Launch FlexTemplate Parameter. — shape: {containerSpec?: record, containerSpecGcsPath?: string, environment?: record, jobName?: string, launchOptions?: record, parameters?: record, transformNameMappings?: record, update?: bool}
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/flexTemplates:launch"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: launchParameter, var: launch_parameter}, {name: validateOnly, var: validate_only}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, launch_parameter: $launch_parameter, validate_only: $validate_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the jobs of a project. To list the jobs of a project in a region, we recommend using `projects.locations.jobs.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). To list the all jobs across all regions, use `projects.jobs.aggregated`. Using `projects.jobs.list` is not recommended, as you can only get the list of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs
# Returns: record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string>
# operationId: dataflow.projects.locations.jobs.list
export def "dataflow-projects-locations-jobs-list" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string@filter-completer # The kind of filter to use.
  --name: string # Optional. The job name. Optional.
  --page-size: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --page-token: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: name, var: name}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, name: $name, page_size: $page_size, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Cloud Dataflow job. To create a job, we recommend using `projects.locations.jobs.create` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.create` is not recommended, as your job will always start in `us-central1`. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.locations.jobs.create
export def "dataflow-projects-locations-jobs-create" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --replace-job-id: string # Deprecated. This field is now in the Job message.
  --view: string@view-completer # The level of information requested in response.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job. (spec name: location)
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to. (spec name: projectId)
  --body-replace-job-id: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job. (spec name: replaceJobId)
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: replaceJobId, var: replace_job_id}, {name: view, var: view}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientRequestId, var: client_request_id}, {name: createTime, var: create_time}, {name: createdFromSnapshotId, var: created_from_snapshot_id}, {name: currentState, var: current_state}, {name: currentStateTime, var: current_state_time}, {name: environment, var: environment}, {name: executionInfo, var: execution_info}, {name: id, var: id}, {name: jobMetadata, var: job_metadata}, {name: labels, var: labels}, {name: location, var: body_location}, {name: name, var: name}, {name: pipelineDescription, var: pipeline_description}, {name: projectId, var: body_project_id}, {name: replaceJobId, var: body_replace_job_id}, {name: replacedByJobId, var: replaced_by_job_id}, {name: requestedState, var: requested_state}, {name: satisfiesPzs, var: satisfies_pzs}, {name: stageStates, var: stage_states}, {name: startTime, var: start_time}, {name: steps, var: steps}, {name: stepsLocation, var: steps_location}, {name: tempFiles, var: temp_files}, {name: transformNameMapping, var: transform_name_mapping}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, replace_job_id: $replace_job_id, view: $view, client_request_id: $client_request_id, create_time: $create_time, created_from_snapshot_id: $created_from_snapshot_id, current_state: $current_state, current_state_time: $current_state_time, environment: $environment, execution_info: $execution_info, id: $id, job_metadata: $job_metadata, labels: $labels, body_location: $body_location, name: $name, pipeline_description: $pipeline_description, body_project_id: $body_project_id, body_replace_job_id: $body_replace_job_id, replaced_by_job_id: $replaced_by_job_id, requested_state: $requested_state, satisfies_pzs: $satisfies_pzs, stage_states: $stage_states, start_time: $start_time, steps: $steps, steps_location: $steps_location, temp_files: $temp_files, transform_name_mapping: $transform_name_mapping, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the state of the specified Cloud Dataflow job. To get the state of a job, we recommend using `projects.locations.jobs.get` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.get` is not recommended, as you can only get the state of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.locations.jobs.get
export def "dataflow-projects-locations-jobs-get" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --view: string@view-completer # The level of information requested in response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the state of an existing Cloud Dataflow job. To update the state of an existing job, we recommend using `projects.locations.jobs.update` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.update` is not recommended, as you can only update the state of jobs that are running in `us-central1`.
#
# PUT /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.locations.jobs.update
export def "dataflow-projects-locations-jobs-update" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # The list of fields to update relative to Job. If empty, only RequestedJobState will be considered for update. If the FieldMask is not empty and RequestedJobState is none/empty, The fields specified in the update mask will be the only ones considered for update. If both RequestedJobState and update_mask are specified, we will first handle RequestedJobState and then the update_mask fields.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job. (spec name: location)
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to. (spec name: projectId)
  --replace-job-id: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientRequestId, var: client_request_id}, {name: createTime, var: create_time}, {name: createdFromSnapshotId, var: created_from_snapshot_id}, {name: currentState, var: current_state}, {name: currentStateTime, var: current_state_time}, {name: environment, var: environment}, {name: executionInfo, var: execution_info}, {name: id, var: id}, {name: jobMetadata, var: job_metadata}, {name: labels, var: labels}, {name: location, var: body_location}, {name: name, var: name}, {name: pipelineDescription, var: pipeline_description}, {name: projectId, var: body_project_id}, {name: replaceJobId, var: replace_job_id}, {name: replacedByJobId, var: replaced_by_job_id}, {name: requestedState, var: requested_state}, {name: satisfiesPzs, var: satisfies_pzs}, {name: stageStates, var: stage_states}, {name: startTime, var: start_time}, {name: steps, var: steps}, {name: stepsLocation, var: steps_location}, {name: tempFiles, var: temp_files}, {name: transformNameMapping, var: transform_name_mapping}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, client_request_id: $client_request_id, create_time: $create_time, created_from_snapshot_id: $created_from_snapshot_id, current_state: $current_state, current_state_time: $current_state_time, environment: $environment, execution_info: $execution_info, id: $id, job_metadata: $job_metadata, labels: $labels, body_location: $body_location, name: $name, pipeline_description: $pipeline_description, body_project_id: $body_project_id, replace_job_id: $replace_job_id, replaced_by_job_id: $replaced_by_job_id, requested_state: $requested_state, satisfies_pzs: $satisfies_pzs, stage_states: $stage_states, start_time: $start_time, steps: $steps, steps_location: $steps_location, temp_files: $temp_files, transform_name_mapping: $transform_name_mapping, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get encoded debug configuration for component. Not cacheable.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/getConfig
# Returns: record<config: string>
# operationId: dataflow.projects.locations.jobs.debug.getConfig
export def "dataflow-projects-locations-jobs-debug-get-config" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --component-id: string # The internal component id for which debug configuration is requested.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id. (spec name: location)
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/getConfig"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentId, var: component_id}, {name: location, var: body_location}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, component_id: $component_id, body_location: $body_location, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send encoded debug capture data for component.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/sendCapture
# Returns: record
# operationId: dataflow.projects.locations.jobs.debug.sendCapture
export def "dataflow-projects-locations-jobs-debug-send-capture" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --component-id: string # The internal component id for which debug information is sent.
  --data: string # The encoded debug information.
  --data-format: string@data-format-completer # Format for the data field above (id=5).
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id. (spec name: location)
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/sendCapture"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentId, var: component_id}, {name: data, var: data}, {name: dataFormat, var: data_format}, {name: location, var: body_location}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, component_id: $component_id, data: $data, data_format: $data_format, body_location: $body_location, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request detailed information about the execution status of the job. EXPERIMENTAL. This API is subject to change or removal without notice.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/executionDetails
# Returns: record<nextPageToken: string, stages: table<endTime: string, metrics: list, progress: record, stageId: string, startTime: string, state: string, stragglerSummary: record>>
# operationId: dataflow.projects.locations.jobs.getExecutionDetails
export def "dataflow-projects-locations-jobs-get-execution-details" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # If specified, determines the maximum number of stages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/executionDetails"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.messages.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.messages.list` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/messages
# Returns: record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string>
# operationId: dataflow.projects.locations.jobs.messages.list
export def "dataflow-projects-locations-jobs-messages-list" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-time: string # Return only messages with timestamps < end_time. The default is now (i.e. return up to the latest messages available).
  --minimum-importance: string@minimum-importance-completer # Filter to only get messages with importance >= level
  --page-size: int # If specified, determines the maximum number of messages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --start-time: string # If specified, return only messages with timestamps >= start_time. The default is the job creation time (i.e. beginning of messages).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/messages"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endTime, var: end_time}, {name: minimumImportance, var: minimum_importance}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: startTime, var: start_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_time: $end_time, minimum_importance: $minimum_importance, page_size: $page_size, page_token: $page_token, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.getMetrics` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.getMetrics` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/metrics
# Returns: record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>>
# operationId: dataflow.projects.locations.jobs.getMetrics
export def "dataflow-projects-locations-jobs-get-metrics" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --start-time: string # Return only metric data that has changed since this time. Default is to return all information about all metrics for the job.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/metrics"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: startTime, var: start_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/snapshots
# Returns: record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>>
# operationId: dataflow.projects.locations.jobs.snapshots.list
export def "dataflow-projects-locations-jobs-snapshots-list" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/snapshots"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request detailed information about the execution status of a stage of the job. EXPERIMENTAL. This API is subject to change or removal without notice.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/stages/{stageId}/executionDetails
# Returns: record<nextPageToken: string, workers: table<workItems: list, workerName: string>>
# operationId: dataflow.projects.locations.jobs.stages.getExecutionDetails
export def "dataflow-projects-locations-jobs-stages-get-execution-details" [
  project_id: string
  location: string
  job_id: string
  stage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-time: string # Upper time bound of work items to include, by start time.
  --page-size: int # If specified, determines the maximum number of work items to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --start-time: string # Lower time bound of work items to include, by start time.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/stages/{stageId}/executionDetails"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}, {name: stageId, var: stage_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endTime, var: end_time}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: startTime, var: start_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, stage_id: $stage_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_time: $end_time, page_size: $page_size, page_token: $page_token, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leases a dataflow WorkItem to run.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:lease
# Returns: record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>>
# operationId: dataflow.projects.locations.jobs.workItems.lease
export def "dataflow-projects-locations-jobs-work-items-lease" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job. (spec name: location)
  --requested-lease-duration: string # The initial lease period. (format: google-duration)
  --unified-worker-request: record # Untranslated bag-of-bytes WorkRequest from UnifiedWorker.
  --work-item-types: list<string> # Filter for WorkItem type.
  --worker-capabilities: list<string> # Worker capabilities. WorkItems might be limited to workers with specific capabilities.
  --worker-id: string # Identifies the worker leasing work -- typically the ID of the virtual machine running the worker.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:lease"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentWorkerTime, var: current_worker_time}, {name: location, var: body_location}, {name: requestedLeaseDuration, var: requested_lease_duration}, {name: unifiedWorkerRequest, var: unified_worker_request}, {name: workItemTypes, var: work_item_types}, {name: workerCapabilities, var: worker_capabilities}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, current_worker_time: $current_worker_time, body_location: $body_location, requested_lease_duration: $requested_lease_duration, unified_worker_request: $unified_worker_request, work_item_types: $work_item_types, worker_capabilities: $worker_capabilities, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reports the status of dataflow WorkItems leased by a worker.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:reportStatus
# Returns: record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>>
# operationId: dataflow.projects.locations.jobs.workItems.reportStatus
export def "dataflow-projects-locations-jobs-work-items-report-status" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job. (spec name: location)
  --unified-worker-request: record # Untranslated bag-of-bytes WorkProgressUpdateRequest from UnifiedWorker.
  --work-item-statuses: list # The order is unimportant, except that the order of the WorkItemServiceState messages in the ReportWorkItemStatusResponse corresponds to the order of WorkItemStatus messages here. — item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
  --worker-id: string # The ID of the worker reporting the WorkItem status. If this does not match the ID of the worker which the Dataflow service believes currently has the lease on the WorkItem, the report will be dropped (with an error response).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:reportStatus"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentWorkerTime, var: current_worker_time}, {name: location, var: body_location}, {name: unifiedWorkerRequest, var: unified_worker_request}, {name: workItemStatuses, var: work_item_statuses}, {name: workerId, var: worker_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, current_worker_time: $current_worker_time, body_location: $body_location, unified_worker_request: $unified_worker_request, work_item_statuses: $work_item_statuses, worker_id: $worker_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Snapshot the state of a streaming job.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}:snapshot
# Returns: record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>
# operationId: dataflow.projects.locations.jobs.snapshot
export def "dataflow-projects-locations-jobs-snapshot" [
  project_id: string
  location: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --description: string # User specified description of the snapshot. Maybe empty.
  --body-location: string # The location that contains this job. (spec name: location)
  --snapshot-sources: oneof<nothing, bool> # If true, perform snapshots for sources which support this.
  --ttl: string # TTL for the snapshot. (format: google-duration)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}:snapshot"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: location, var: body_location}, {name: snapshotSources, var: snapshot_sources}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, body_location: $body_location, snapshot_sources: $snapshot_sources, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/locations/{location}/snapshots
# Returns: record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>>
# operationId: dataflow.projects.locations.snapshots.list
export def "dataflow-projects-locations-snapshots-list" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --job-id: string # If specified, list snapshots created from this job.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/snapshots"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: jobId, var: job_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a snapshot.
#
# DELETE /v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}
# Returns: record
# operationId: dataflow.projects.locations.snapshots.delete
export def "dataflow-projects-locations-snapshots-delete" [
  project_id: string
  location: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: snapshotId, var: snapshot_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, snapshot_id: $snapshot_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a snapshot.
#
# GET /v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}
# Returns: record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>
# operationId: dataflow.projects.locations.snapshots.get
export def "dataflow-projects-locations-snapshots-get" [
  project_id: string
  location: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}, {name: snapshotId, var: snapshot_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, snapshot_id: $snapshot_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Cloud Dataflow job from a template. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/locations/{location}/templates
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.locations.templates.create
export def "dataflow-projects-locations-templates-create" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --job-name: string # Required. The job name to use for the created job.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request. (spec name: location)
  --parameters: record # The runtime parameters to pass to the job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/templates"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: environment, var: environment}, {name: gcsPath, var: gcs_path}, {name: jobName, var: job_name}, {name: location, var: body_location}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, environment: $environment, gcs_path: $gcs_path, job_name: $job_name, body_location: $body_location, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the template associated with a template.
#
# GET /v1b3/projects/{projectId}/locations/{location}/templates:get
# Returns: record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string>
# operationId: dataflow.projects.locations.templates.get
export def "dataflow-projects-locations-templates-get" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --view: string@view-completer-1 # The view to retrieve. Defaults to METADATA_ONLY.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/locations/{location}/templates:get"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: gcsPath, var: gcs_path}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, gcs_path: $gcs_path, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Launch a template.
#
# POST /v1b3/projects/{projectId}/locations/{location}/templates:launch
# Returns: record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>>
# operationId: dataflow.projects.locations.templates.launch
export def "dataflow-projects-locations-templates-launch" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dynamic-template-gcs-path: string # Path to dynamic template spec file on Cloud Storage. The file must be a Json serialized DynamicTemplateFieSpec object.
  --dynamic-template-staging-location: string # Cloud Storage path for staging dependencies. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --gcs-path: string # A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --job-name: string # Required. The job name to use for the created job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --parameters: record # The runtime parameters to pass to the job.
  --transform-name-mapping: record # Only applicable when updating a pipeline. Map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --update: oneof<nothing, bool> # If set, replace the existing pipeline with the name specified by jobName with this pipeline, preserving state.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/locations/{location}/templates:launch"
    path_params: [{name: projectId, var: project_id}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "dynamicTemplate.gcsPath", var: dynamic_template_gcs_path}, {name: "dynamicTemplate.stagingLocation", var: dynamic_template_staging_location}, {name: gcsPath, var: gcs_path}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: environment, var: environment}, {name: jobName, var: job_name}, {name: parameters, var: parameters}, {name: transformNameMapping, var: transform_name_mapping}, {name: update, var: update}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dynamic_template_gcs_path: $dynamic_template_gcs_path, dynamic_template_staging_location: $dynamic_template_staging_location, gcs_path: $gcs_path, validate_only: $validate_only, environment: $environment, job_name: $job_name, parameters: $parameters, transform_name_mapping: $transform_name_mapping, update: $update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a snapshot.
#
# DELETE /v1b3/projects/{projectId}/snapshots
# Returns: record
# operationId: dataflow.projects.deleteSnapshots
export def "dataflow-projects-delete-snapshots" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The location that contains this snapshot.
  --snapshot-id: string # The ID of the snapshot.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1b3/projects/{projectId}/snapshots"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: location, var: location}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/snapshots
# Returns: record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>>
# operationId: dataflow.projects.snapshots.list
export def "dataflow-projects-snapshots-list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --job-id: string # If specified, list snapshots created from this job.
  --location: string # The location to list snapshots in.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/snapshots"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: jobId, var: job_id}, {name: location, var: location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, job_id: $job_id, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a snapshot.
#
# GET /v1b3/projects/{projectId}/snapshots/{snapshotId}
# Returns: record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string>
# operationId: dataflow.projects.snapshots.get
export def "dataflow-projects-snapshots-get" [
  project_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The location that contains this snapshot.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/snapshots/{snapshotId}"
    path_params: [{name: projectId, var: project_id}, {name: snapshotId, var: snapshot_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: location, var: location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, snapshot_id: $snapshot_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Cloud Dataflow job from a template. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/templates
# Returns: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>
# operationId: dataflow.projects.templates.create
export def "dataflow-projects-templates-create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --job-name: string # Required. The job name to use for the created job.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --parameters: record # The runtime parameters to pass to the job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/templates"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: environment, var: environment}, {name: gcsPath, var: gcs_path}, {name: jobName, var: job_name}, {name: location, var: location}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, environment: $environment, gcs_path: $gcs_path, job_name: $job_name, location: $location, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the template associated with a template.
#
# GET /v1b3/projects/{projectId}/templates:get
# Returns: record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string>
# operationId: dataflow.projects.templates.get
export def "dataflow-projects-templates-get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --view: string@view-completer-1 # The view to retrieve. Defaults to METADATA_ONLY.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1b3/projects/{projectId}/templates:get"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: gcsPath, var: gcs_path}, {name: location, var: location}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, gcs_path: $gcs_path, location: $location, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Launch a template.
#
# POST /v1b3/projects/{projectId}/templates:launch
# Returns: record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>>
# operationId: dataflow.projects.templates.launch
export def "dataflow-projects-templates-launch" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dynamic-template-gcs-path: string # Path to dynamic template spec file on Cloud Storage. The file must be a Json serialized DynamicTemplateFieSpec object.
  --dynamic-template-staging-location: string # Cloud Storage path for staging dependencies. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --gcs-path: string # A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --job-name: string # Required. The job name to use for the created job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --parameters: record # The runtime parameters to pass to the job.
  --transform-name-mapping: record # Only applicable when updating a pipeline. Map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --update: oneof<nothing, bool> # If set, replace the existing pipeline with the name specified by jobName with this pipeline, preserving state.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1b3/projects/{projectId}/templates:launch"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "dynamicTemplate.gcsPath", var: dynamic_template_gcs_path}, {name: "dynamicTemplate.stagingLocation", var: dynamic_template_staging_location}, {name: gcsPath, var: gcs_path}, {name: location, var: location}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: environment, var: environment}, {name: jobName, var: job_name}, {name: parameters, var: parameters}, {name: transformNameMapping, var: transform_name_mapping}, {name: update, var: update}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dynamic_template_gcs_path: $dynamic_template_gcs_path, dynamic_template_staging_location: $dynamic_template_staging_location, gcs_path: $gcs_path, location: $location, validate_only: $validate_only, environment: $environment, job_name: $job_name, parameters: $parameters, transform_name_mapping: $transform_name_mapping, update: $update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
