# Auto-generated client for Cloud Dataproc API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/dataproc/v1/openapi.json
# Auth: --token flag or $env.CLOUD_DATAPROC_API_TOKEN

const CLIENT = {
  base_url: "https://dataproc.googleapis.com"
  token_env_var: "CLOUD_DATAPROC_API_TOKEN"
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

def base-url-completer [] { ["https://dataproc.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def action-on-failed-primary-workers-completer [] { ["DELETE" "FAILURE_ACTION_UNSPECIFIED" "NO_ACTION"] }
def job-state-matcher-completer [] { ["ACTIVE" "ALL" "NON_ACTIVE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    dataproc-projects-regions-clusters-list: "record<clusters: table<clusterName: string, clusterUuid: string, config: record, labels: record, metrics: record, projectId: string, status: record, statusHistory: list, virtualClusterConfig: record>, nextPageToken: string>"
    dataproc-projects-regions-clusters-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-delete: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-get: "record<clusterName: string, clusterUuid: string, config: record<autoscalingConfig: record<policyUri: string>, auxiliaryNodeGroups: list<record>, configBucket: string, dataprocMetricConfig: record<metrics: list>, encryptionConfig: record<gcePdKmsKeyName: string, kmsKey: string>, endpointConfig: record<enableHttpPortAccess: bool, httpPorts: record>, gceClusterConfig: record<confidentialInstanceConfig: record, internalIpOnly: bool, metadata: record, networkUri: string, nodeGroupAffinity: record, privateIpv6GoogleAccess: string, reservationAffinity: record, serviceAccount: string, serviceAccountScopes: list, shieldedInstanceConfig: record, subnetworkUri: string, tags: list, zoneUri: string>, gkeClusterConfig: record<gkeClusterTarget: string, namespacedGkeDeploymentTarget: record, nodePoolTarget: list>, initializationActions: list<record>, lifecycleConfig: record<autoDeleteTime: string, autoDeleteTtl: string, idleDeleteTtl: string, idleStartTime: string>, masterConfig: record<accelerators: list, diskConfig: record, imageUri: string, instanceNames: list, instanceReferences: list, isPreemptible: bool, machineTypeUri: string, managedGroupConfig: record, minCpuPlatform: string, numInstances: int, preemptibility: string>, metastoreConfig: record<dataprocMetastoreService: string>, secondaryWorkerConfig: record<accelerators: list, diskConfig: record, imageUri: string, instanceNames: list, instanceReferences: list, isPreemptible: bool, machineTypeUri: string, managedGroupConfig: record, minCpuPlatform: string, numInstances: int, preemptibility: string>, securityConfig: record<identityConfig: record, kerberosConfig: record>, softwareConfig: record<imageVersion: string, optionalComponents: list, properties: record>, tempBucket: string, workerConfig: record<accelerators: list, diskConfig: record, imageUri: string, instanceNames: list, instanceReferences: list, isPreemptible: bool, machineTypeUri: string, managedGroupConfig: record, minCpuPlatform: string, numInstances: int, preemptibility: string>>, labels: record, metrics: record<hdfsMetrics: record, yarnMetrics: record>, projectId: string, status: record<detail: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<detail: string, state: string, stateStartTime: string, substate: string>, virtualClusterConfig: record<auxiliaryServicesConfig: record<metastoreConfig: record, sparkHistoryServerConfig: record>, kubernetesClusterConfig: record<gkeClusterConfig: record, kubernetesNamespace: string, kubernetesSoftwareConfig: record>, stagingBucket: string>>"
    dataproc-projects-regions-clusters-patch: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-diagnose: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-repair: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-start: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-stop: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-jobs-list: "record<jobs: table<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record, hadoopJob: record, hiveJob: record, jobUuid: string, labels: record, pigJob: record, placement: record, prestoJob: record, pysparkJob: record, reference: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, status: record, statusHistory: list, trinoJob: record, yarnApplications: list>, nextPageToken: string>"
    dataproc-projects-regions-jobs-delete: "record"
    dataproc-projects-regions-jobs-get: "record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>"
    dataproc-projects-regions-jobs-patch: "record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>"
    dataproc-projects-regions-jobs-cancel: "record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>"
    dataproc-projects-regions-jobs-submit: "record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>"
    dataproc-projects-regions-jobs-submit-as-operation: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-workflow-templates-delete: "record"
    dataproc-projects-regions-workflow-templates-get: "record<createTime: string, dagTimeout: string, id: string, jobs: table<hadoopJob: record, hiveJob: record, labels: record, pigJob: record, prerequisiteStepIds: list, prestoJob: record, pysparkJob: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, stepId: string, trinoJob: record>, labels: record, name: string, parameters: table<description: string, fields: list, name: string, validation: record>, placement: record<clusterSelector: record<clusterLabels: record, zone: string>, managedCluster: record<clusterName: string, config: record, labels: record>>, updateTime: string, version: int>"
    dataproc-projects-regions-workflow-templates-update: "record<createTime: string, dagTimeout: string, id: string, jobs: table<hadoopJob: record, hiveJob: record, labels: record, pigJob: record, prerequisiteStepIds: list, prestoJob: record, pysparkJob: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, stepId: string, trinoJob: record>, labels: record, name: string, parameters: table<description: string, fields: list, name: string, validation: record>, placement: record<clusterSelector: record<clusterLabels: record, zone: string>, managedCluster: record<clusterName: string, config: record, labels: record>>, updateTime: string, version: int>"
    dataproc-projects-regions-operations-cancel: "record"
    dataproc-projects-regions-workflow-templates-instantiate: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-node-groups-resize: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-autoscaling-policies-list: "record<nextPageToken: string, policies: table<basicAlgorithm: record, id: string, labels: record, name: string, secondaryWorkerConfig: record, workerConfig: record>>"
    dataproc-projects-regions-autoscaling-policies-create: "record<basicAlgorithm: record<cooldownPeriod: string, sparkStandaloneConfig: record<gracefulDecommissionTimeout: string, scaleDownFactor: float, scaleDownMinWorkerFraction: float, scaleUpFactor: float, scaleUpMinWorkerFraction: float>, yarnConfig: record<gracefulDecommissionTimeout: string, scaleDownFactor: float, scaleDownMinWorkerFraction: float, scaleUpFactor: float, scaleUpMinWorkerFraction: float>>, id: string, labels: record, name: string, secondaryWorkerConfig: record<maxInstances: int, minInstances: int, weight: int>, workerConfig: record<maxInstances: int, minInstances: int, weight: int>>"
    dataproc-projects-locations-batches-list: "record<batches: table<createTime: string, creator: string, environmentConfig: record, labels: record, name: string, operation: string, pysparkBatch: record, runtimeConfig: record, runtimeInfo: record, sparkBatch: record, sparkRBatch: record, sparkSqlBatch: record, state: string, stateHistory: list, stateMessage: string, stateTime: string, uuid: string>, nextPageToken: string>"
    dataproc-projects-locations-batches-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-node-groups-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-workflow-templates-list: "record<nextPageToken: string, templates: table<createTime: string, dagTimeout: string, id: string, jobs: list, labels: record, name: string, parameters: list, placement: record, updateTime: string, version: int>>"
    dataproc-projects-regions-workflow-templates-create: "record<createTime: string, dagTimeout: string, id: string, jobs: table<hadoopJob: record, hiveJob: record, labels: record, pigJob: record, prerequisiteStepIds: list, prestoJob: record, pysparkJob: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, stepId: string, trinoJob: record>, labels: record, name: string, parameters: table<description: string, fields: list, name: string, validation: record>, placement: record<clusterSelector: record<clusterLabels: record, zone: string>, managedCluster: record<clusterName: string, config: record, labels: record>>, updateTime: string, version: int>"
    dataproc-projects-regions-workflow-templates-instantiate-inline: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-clusters-inject-credentials: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataproc-projects-regions-workflow-templates-get-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    dataproc-projects-regions-workflow-templates-set-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    dataproc-projects-regions-workflow-templates-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["dataproc-projects-regions-clusters-list" "dataproc-projects-regions-clusters-create" "dataproc-projects-regions-clusters-delete" "dataproc-projects-regions-clusters-get" "dataproc-projects-regions-clusters-patch" "dataproc-projects-regions-clusters-diagnose" "dataproc-projects-regions-clusters-repair" "dataproc-projects-regions-clusters-start" "dataproc-projects-regions-clusters-stop" "dataproc-projects-regions-jobs-list" "dataproc-projects-regions-jobs-delete" "dataproc-projects-regions-jobs-get" "dataproc-projects-regions-jobs-patch" "dataproc-projects-regions-jobs-cancel" "dataproc-projects-regions-jobs-submit" "dataproc-projects-regions-jobs-submit-as-operation" "dataproc-projects-regions-workflow-templates-delete" "dataproc-projects-regions-workflow-templates-get" "dataproc-projects-regions-workflow-templates-update" "dataproc-projects-regions-operations-cancel" "dataproc-projects-regions-workflow-templates-instantiate" "dataproc-projects-regions-clusters-node-groups-resize" "dataproc-projects-regions-autoscaling-policies-list" "dataproc-projects-regions-autoscaling-policies-create" "dataproc-projects-locations-batches-list" "dataproc-projects-locations-batches-create" "dataproc-projects-regions-clusters-node-groups-create" "dataproc-projects-regions-workflow-templates-list" "dataproc-projects-regions-workflow-templates-create" "dataproc-projects-regions-workflow-templates-instantiate-inline" "dataproc-projects-regions-clusters-inject-credentials" "dataproc-projects-regions-workflow-templates-get-iam-policy" "dataproc-projects-regions-workflow-templates-set-iam-policy" "dataproc-projects-regions-workflow-templates-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Lists all regions/{region}/clusters in a project alphabetically.
#
# GET /v1/projects/{projectId}/regions/{region}/clusters
# Returns: record<clusters: table<clusterName: string, clusterUuid: string, config: record, labels: record, metrics: record, projectId: string, status: record, statusHistory: list, virtualClusterConfig: record>, nextPageToken: string>
# operationId: dataproc.projects.regions.clusters.list
export def "dataproc-projects-regions-clusters-list" [
  project_id: string
  region: string
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
  --filter: string # Optional. A filter constraining the clusters to list. Filters are case-sensitive and have the following syntax:field = value AND field = value ...where field is one of status.state, clusterName, or labels.[KEY], and [KEY] is a label key. value can be * to match all values. status.state can be one of the following: ACTIVE, INACTIVE, CREATING, RUNNING, ERROR, DELETING, or UPDATING. ACTIVE contains the CREATING, UPDATING, and RUNNING states. INACTIVE contains the DELETING and ERROR states. clusterName is the name of the cluster provided at creation time. Only the logical AND operator is supported; space-separated items are treated as having an implicit AND operator.Example filter:status.state = ACTIVE AND clusterName = mycluster AND labels.env = staging AND labels.starred = *
  --page-size: int # Optional. The standard List page size.
  --page-token: string # Optional. The standard List page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{projectId}/regions/{region}/clusters"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a cluster in a project. The returned Operation.metadata will be ClusterOperationMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#clusteroperationmetadata).
#
# POST /v1/projects/{projectId}/regions/{region}/clusters
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.create
export def "dataproc-projects-regions-clusters-create" [
  project_id: string
  region: string
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
  --action-on-failed-primary-workers: string@action-on-failed-primary-workers-completer # Optional. Failure action when primary worker creation fails.
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two CreateClusterRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.CreateClusterRequest)s with the same id, then the second request will be ignored and the first google.longrunning.Operation created and stored in the backend is returned.It is recommended to always set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
  --cluster-name: string # Required. The cluster name, which must be unique within a project. The name must start with a lowercase letter, and can contain up to 51 lowercase letters, numbers, and hyphens. It cannot end with a hyphen. The name of a deleted cluster can be reused.
  --config: record # The cluster config. — shape: {autoscalingConfig?: record, auxiliaryNodeGroups?: list, configBucket?: string, dataprocMetricConfig?: record, encryptionConfig?: record, endpointConfig?: record, gceClusterConfig?: record, gkeClusterConfig?: record, initializationActions?: list, lifecycleConfig?: record, masterConfig?: record, metastoreConfig?: record, secondaryWorkerConfig?: record, securityConfig?: record, softwareConfig?: record, tempBucket?: string, workerConfig?: record}
  --labels: record # Optional. The labels to associate with this cluster. Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). No more than 32 labels can be associated with a cluster.
  --metrics: record # Contains cluster daemon metrics, such as HDFS and YARN stats.Beta Feature: This report is available for testing purposes only. It may be changed before final release. — shape: {hdfsMetrics?: record, yarnMetrics?: record}
  --body-project-id: string # Required. The Google Cloud Platform project ID that the cluster belongs to. (spec name: projectId)
  --status: record # The status of a cluster and its instances.
  --virtual-cluster-config: record # The Dataproc cluster config for a cluster that does not directly control the underlying compute resources, such as a Dataproc-on-GKE cluster (https://cloud.google.com/dataproc/docs/guides/dpgke/dataproc-gke-overview). — shape: {auxiliaryServicesConfig?: record, kubernetesClusterConfig?: record, stagingBucket?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/clusters"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: actionOnFailedPrimaryWorkers, var: action_on_failed_primary_workers}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterName, var: cluster_name}, {name: config, var: config}, {name: labels, var: labels}, {name: metrics, var: metrics}, {name: projectId, var: body_project_id}, {name: status, var: status}, {name: virtualClusterConfig, var: virtual_cluster_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action_on_failed_primary_workers: $action_on_failed_primary_workers, request_id: $request_id, cluster_name: $cluster_name, config: $config, labels: $labels, metrics: $metrics, body_project_id: $body_project_id, status: $status, virtual_cluster_config: $virtual_cluster_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a cluster in a project. The returned Operation.metadata will be ClusterOperationMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#clusteroperationmetadata).
#
# DELETE /v1/projects/{projectId}/regions/{region}/clusters/{clusterName}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.delete
export def "dataproc-projects-regions-clusters-delete" [
  project_id: string
  region: string
  cluster_name: string
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
  --cluster-uuid: string # Optional. Specifying the cluster_uuid means the RPC should fail (with error NOT_FOUND) if cluster with specified UUID does not exist.
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two DeleteClusterRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.DeleteClusterRequest)s with the same id, then the second request will be ignored and the first google.longrunning.Operation created and stored in the backend is returned.It is recommended to always set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/projects/{projectId}/regions/{region}/clusters/{clusterName}"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: clusterName, var: cluster_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clusterUuid, var: cluster_uuid}, {name: requestId, var: request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, cluster_name: $cluster_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_uuid: $cluster_uuid, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the resource representation for a cluster in a project.
#
# GET /v1/projects/{projectId}/regions/{region}/clusters/{clusterName}
# Returns: record<clusterName: string, clusterUuid: string, config: record<autoscalingConfig: record<policyUri: string>, auxiliaryNodeGroups: list<record>, configBucket: string, dataprocMetricConfig: record<metrics: list>, encryptionConfig: record<gcePdKmsKeyName: string, kmsKey: string>, endpointConfig: record<enableHttpPortAccess: bool, httpPorts: record>, gceClusterConfig: record<confidentialInstanceConfig: record, internalIpOnly: bool, metadata: record, networkUri: string, nodeGroupAffinity: record, privateIpv6GoogleAccess: string, reservationAffinity: record, serviceAccount: string, serviceAccountScopes: list, shieldedInstanceConfig: record, subnetworkUri: string, tags: list, zoneUri: string>, gkeClusterConfig: record<gkeClusterTarget: string, namespacedGkeDeploymentTarget: record, nodePoolTarget: list>, initializationActions: list<record>, lifecycleConfig: record<autoDeleteTime: string, autoDeleteTtl: string, idleDeleteTtl: string, idleStartTime: string>, masterConfig: record<accelerators: list, diskConfig: record, imageUri: string, instanceNames: list, instanceReferences: list, isPreemptible: bool, machineTypeUri: string, managedGroupConfig: record, minCpuPlatform: string, numInstances: int, preemptibility: string>, metastoreConfig: record<dataprocMetastoreService: string>, secondaryWorkerConfig: record<accelerators: list, diskConfig: record, imageUri: string, instanceNames: list, instanceReferences: list, isPreemptible: bool, machineTypeUri: string, managedGroupConfig: record, minCpuPlatform: string, numInstances: int, preemptibility: string>, securityConfig: record<identityConfig: record, kerberosConfig: record>, softwareConfig: record<imageVersion: string, optionalComponents: list, properties: record>, tempBucket: string, workerConfig: record<accelerators: list, diskConfig: record, imageUri: string, instanceNames: list, instanceReferences: list, isPreemptible: bool, machineTypeUri: string, managedGroupConfig: record, minCpuPlatform: string, numInstances: int, preemptibility: string>>, labels: record, metrics: record<hdfsMetrics: record, yarnMetrics: record>, projectId: string, status: record<detail: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<detail: string, state: string, stateStartTime: string, substate: string>, virtualClusterConfig: record<auxiliaryServicesConfig: record<metastoreConfig: record, sparkHistoryServerConfig: record>, kubernetesClusterConfig: record<gkeClusterConfig: record, kubernetesNamespace: string, kubernetesSoftwareConfig: record>, stagingBucket: string>>
# operationId: dataproc.projects.regions.clusters.get
export def "dataproc-projects-regions-clusters-get" [
  project_id: string
  region: string
  cluster_name: string
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
    path: "/v1/projects/{projectId}/regions/{region}/clusters/{clusterName}"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: clusterName, var: cluster_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, cluster_name: $cluster_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a cluster in a project. The returned Operation.metadata will be ClusterOperationMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#clusteroperationmetadata). The cluster must be in a RUNNING state or an error is returned.
#
# PATCH /v1/projects/{projectId}/regions/{region}/clusters/{clusterName}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.patch
export def "dataproc-projects-regions-clusters-patch" [
  project_id: string
  region: string
  cluster_name: string
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
  --graceful-decommission-timeout: string # Optional. Timeout for graceful YARN decommissioning. Graceful decommissioning allows removing nodes from the cluster without interrupting jobs in progress. Timeout specifies how long to wait for jobs in progress to finish before forcefully removing nodes (and potentially interrupting jobs). Default timeout is 0 (for forceful decommission), and the maximum allowed timeout is 1 day. (see JSON representation of Duration (https://developers.google.com/protocol-buffers/docs/proto3#json)).Only supported on Dataproc image versions 1.2 and higher.
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two UpdateClusterRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.UpdateClusterRequest)s with the same id, then the second request will be ignored and the first google.longrunning.Operation created and stored in the backend is returned.It is recommended to always set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
  --update-mask: string # Required. Specifies the path, relative to Cluster, of the field to update. For example, to change the number of workers in a cluster to 5, the update_mask parameter would be specified as config.worker_config.num_instances, and the PATCH request body would specify the new value, as follows: { "config":{ "workerConfig":{ "numInstances":"5" } } } Similarly, to change the number of preemptible workers in a cluster to 5, the update_mask parameter would be config.secondary_worker_config.num_instances, and the PATCH request body would be set as follows: { "config":{ "secondaryWorkerConfig":{ "numInstances":"5" } } } *Note:* Currently, only the following fields can be updated: *Mask* *Purpose* *labels* Update labels *config.worker_config.num_instances* Resize primary worker group *config.secondary_worker_config.num_instances* Resize secondary worker group config.autoscaling_config.policy_uri Use, stop using, or change autoscaling policies
  --body-cluster-name: string # Required. The cluster name, which must be unique within a project. The name must start with a lowercase letter, and can contain up to 51 lowercase letters, numbers, and hyphens. It cannot end with a hyphen. The name of a deleted cluster can be reused. (spec name: clusterName)
  --config: record # The cluster config. — shape: {autoscalingConfig?: record, auxiliaryNodeGroups?: list, configBucket?: string, dataprocMetricConfig?: record, encryptionConfig?: record, endpointConfig?: record, gceClusterConfig?: record, gkeClusterConfig?: record, initializationActions?: list, lifecycleConfig?: record, masterConfig?: record, metastoreConfig?: record, secondaryWorkerConfig?: record, securityConfig?: record, softwareConfig?: record, tempBucket?: string, workerConfig?: record}
  --labels: record # Optional. The labels to associate with this cluster. Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). No more than 32 labels can be associated with a cluster.
  --metrics: record # Contains cluster daemon metrics, such as HDFS and YARN stats.Beta Feature: This report is available for testing purposes only. It may be changed before final release. — shape: {hdfsMetrics?: record, yarnMetrics?: record}
  --body-project-id: string # Required. The Google Cloud Platform project ID that the cluster belongs to. (spec name: projectId)
  --status: record # The status of a cluster and its instances.
  --virtual-cluster-config: record # The Dataproc cluster config for a cluster that does not directly control the underlying compute resources, such as a Dataproc-on-GKE cluster (https://cloud.google.com/dataproc/docs/guides/dpgke/dataproc-gke-overview). — shape: {auxiliaryServicesConfig?: record, kubernetesClusterConfig?: record, stagingBucket?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/projects/{projectId}/regions/{region}/clusters/{clusterName}"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: clusterName, var: cluster_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: gracefulDecommissionTimeout, var: graceful_decommission_timeout}, {name: requestId, var: request_id}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterName, var: body_cluster_name}, {name: config, var: config}, {name: labels, var: labels}, {name: metrics, var: metrics}, {name: projectId, var: body_project_id}, {name: status, var: status}, {name: virtualClusterConfig, var: virtual_cluster_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, cluster_name: $cluster_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, graceful_decommission_timeout: $graceful_decommission_timeout, request_id: $request_id, update_mask: $update_mask, body_cluster_name: $body_cluster_name, config: $config, labels: $labels, metrics: $metrics, body_project_id: $body_project_id, status: $status, virtual_cluster_config: $virtual_cluster_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets cluster diagnostic information. The returned Operation.metadata will be ClusterOperationMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#clusteroperationmetadata). After the operation completes, Operation.response contains DiagnoseClusterResults (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#diagnoseclusterresults).
#
# POST /v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:diagnose
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.diagnose
export def "dataproc-projects-regions-clusters-diagnose" [
  project_id: string
  region: string
  cluster_name: string
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
  --diagnosis-interval: record # Represents a time interval, encoded as a Timestamp start (inclusive) and a Timestamp end (exclusive).The start must be less than or equal to the end. When the start equals the end, the interval is empty (matches no time). When both start and end are unspecified, the interval matches any time. — shape: {endTime?: string, startTime?: string}
  --job: string # Optional. DEPRECATED Specifies the job on which diagnosis is to be performed. Format: projects/{project}/regions/{region}/jobs/{job}
  --jobs: list<string> # Optional. Specifies a list of jobs on which diagnosis is to be performed. Format: projects/{project}/regions/{region}/jobs/{job}
  --yarn-application-id: string # Optional. DEPRECATED Specifies the yarn application on which diagnosis is to be performed.
  --yarn-application-ids: list<string> # Optional. Specifies a list of yarn applications on which diagnosis is to be performed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:diagnose"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: clusterName, var: cluster_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: diagnosisInterval, var: diagnosis_interval}, {name: job, var: job}, {name: jobs, var: jobs}, {name: yarnApplicationId, var: yarn_application_id}, {name: yarnApplicationIds, var: yarn_application_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, cluster_name: $cluster_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, diagnosis_interval: $diagnosis_interval, job: $job, jobs: $jobs, yarn_application_id: $yarn_application_id, yarn_application_ids: $yarn_application_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Repairs a cluster.
#
# POST /v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:repair
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.repair
export def "dataproc-projects-regions-clusters-repair" [
  project_id: string
  region: string
  cluster_name: string
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
  --cluster-uuid: string # Optional. Specifying the cluster_uuid means the RPC will fail (with error NOT_FOUND) if a cluster with the specified UUID does not exist.
  --graceful-decommission-timeout: string # Optional. Timeout for graceful YARN decommissioning. Graceful decommissioning facilitates the removal of cluster nodes without interrupting jobs in progress. The timeout specifies the amount of time to wait for jobs finish before forcefully removing nodes. The default timeout is 0 for forceful decommissioning, and the maximum timeout period is 1 day. (see JSON Mapping—Duration (https://developers.google.com/protocol-buffers/docs/proto3#json)).graceful_decommission_timeout is supported in Dataproc image versions 1.2+. (format: google-duration)
  --node-pools: list # Optional. Node pools and corresponding repair action to be taken. All node pools should be unique in this request. i.e. Multiple entries for the same node pool id are not allowed. — item shape: {id?: string, instanceNames?: list<string>, repairAction?: "REPAIR_ACTION_UNSPECIFIED"|"DELETE"}
  --parent-operation-id: string # Optional. operation id of the parent operation sending the repair request
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two RepairClusterRequests with the same ID, the second request is ignored, and the first google.longrunning.Operation created and stored in the backend is returned.Recommendation: Set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:repair"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: clusterName, var: cluster_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterUuid, var: cluster_uuid}, {name: gracefulDecommissionTimeout, var: graceful_decommission_timeout}, {name: nodePools, var: node_pools}, {name: parentOperationId, var: parent_operation_id}, {name: requestId, var: request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, cluster_name: $cluster_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_uuid: $cluster_uuid, graceful_decommission_timeout: $graceful_decommission_timeout, node_pools: $node_pools, parent_operation_id: $parent_operation_id, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a cluster in a project.
#
# POST /v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:start
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.start
export def "dataproc-projects-regions-clusters-start" [
  project_id: string
  region: string
  cluster_name: string
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
  --cluster-uuid: string # Optional. Specifying the cluster_uuid means the RPC will fail (with error NOT_FOUND) if a cluster with the specified UUID does not exist.
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two StartClusterRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.StartClusterRequest)s with the same id, then the second request will be ignored and the first google.longrunning.Operation created and stored in the backend is returned.Recommendation: Set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:start"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: clusterName, var: cluster_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterUuid, var: cluster_uuid}, {name: requestId, var: request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, cluster_name: $cluster_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_uuid: $cluster_uuid, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a cluster in a project.
#
# POST /v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:stop
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.stop
export def "dataproc-projects-regions-clusters-stop" [
  project_id: string
  region: string
  cluster_name: string
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
  --cluster-uuid: string # Optional. Specifying the cluster_uuid means the RPC will fail (with error NOT_FOUND) if a cluster with the specified UUID does not exist.
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two StopClusterRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.StopClusterRequest)s with the same id, then the second request will be ignored and the first google.longrunning.Operation created and stored in the backend is returned.Recommendation: Set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/clusters/{clusterName}:stop"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: clusterName, var: cluster_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterUuid, var: cluster_uuid}, {name: requestId, var: request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, cluster_name: $cluster_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_uuid: $cluster_uuid, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists regions/{region}/jobs in a project.
#
# GET /v1/projects/{projectId}/regions/{region}/jobs
# Returns: record<jobs: table<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record, hadoopJob: record, hiveJob: record, jobUuid: string, labels: record, pigJob: record, placement: record, prestoJob: record, pysparkJob: record, reference: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, status: record, statusHistory: list, trinoJob: record, yarnApplications: list>, nextPageToken: string>
# operationId: dataproc.projects.regions.jobs.list
export def "dataproc-projects-regions-jobs-list" [
  project_id: string
  region: string
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
  --cluster-name: string # Optional. If set, the returned jobs list includes only jobs that were submitted to the named cluster.
  --filter: string # Optional. A filter constraining the jobs to list. Filters are case-sensitive and have the following syntax:field = value AND field = value ...where field is status.state or labels.[KEY], and [KEY] is a label key. value can be * to match all values. status.state can be either ACTIVE or NON_ACTIVE. Only the logical AND operator is supported; space-separated items are treated as having an implicit AND operator.Example filter:status.state = ACTIVE AND labels.env = staging AND labels.starred = *
  --job-state-matcher: string@job-state-matcher-completer # Optional. Specifies enumerated categories of jobs to list. (default = match ALL jobs).If filter is provided, jobStateMatcher will be ignored.
  --page-size: int # Optional. The number of results to return in each response.
  --page-token: string # Optional. The page token, returned by a previous call, to request the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{projectId}/regions/{region}/jobs"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clusterName, var: cluster_name}, {name: filter, var: filter}, {name: jobStateMatcher, var: job_state_matcher}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_name: $cluster_name, filter: $filter, job_state_matcher: $job_state_matcher, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the job from the project. If the job is active, the delete fails, and the response returns FAILED_PRECONDITION.
#
# DELETE /v1/projects/{projectId}/regions/{region}/jobs/{jobId}
# Returns: record
# operationId: dataproc.projects.regions.jobs.delete
export def "dataproc-projects-regions-jobs-delete" [
  project_id: string
  region: string
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
    method: delete
    path: "/v1/projects/{projectId}/regions/{region}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the resource representation for a job in a project.
#
# GET /v1/projects/{projectId}/regions/{region}/jobs/{jobId}
# Returns: record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>
# operationId: dataproc.projects.regions.jobs.get
export def "dataproc-projects-regions-jobs-get" [
  project_id: string
  region: string
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
    path: "/v1/projects/{projectId}/regions/{region}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a job in a project.
#
# PATCH /v1/projects/{projectId}/regions/{region}/jobs/{jobId}
# Returns: record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>
# operationId: dataproc.projects.regions.jobs.patch
export def "dataproc-projects-regions-jobs-patch" [
  project_id: string
  region: string
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
  --update-mask: string # Required. Specifies the path, relative to Job, of the field to update. For example, to update the labels of a Job the update_mask parameter would be specified as labels, and the PATCH request body would specify the new value. *Note:* Currently, labels is the only field that can be updated.
  --driver-scheduling-config: record # Driver scheduling configuration. — shape: {memoryMb?: int, vcores?: int}
  --hadoop-job: record # A Dataproc job for running Apache Hadoop MapReduce (https://hadoop.apache.org/docs/current/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html) jobs on Apache Hadoop YARN (https://hadoop.apache.org/docs/r2.7.1/hadoop-yarn/hadoop-yarn-site/YARN.html). — shape: {archiveUris?: list<string>, args?: list<string>, fileUris?: list<string>, jarFileUris?: list<string>, loggingConfig?: record, mainClass?: string, mainJarFileUri?: string, properties?: record}
  --hive-job: record # A Dataproc job for running Apache Hive (https://hive.apache.org/) queries on YARN. — shape: {continueOnFailure?: bool, jarFileUris?: list<string>, properties?: record, queryFileUri?: string, queryList?: record, scriptVariables?: record}
  --labels: record # Optional. The labels to associate with this job. Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). No more than 32 labels can be associated with a job.
  --pig-job: record # A Dataproc job for running Apache Pig (https://pig.apache.org/) queries on YARN. — shape: {continueOnFailure?: bool, jarFileUris?: list<string>, loggingConfig?: record, properties?: record, queryFileUri?: string, queryList?: record, scriptVariables?: record}
  --placement: record # Dataproc job config. — shape: {clusterLabels?: record, clusterName?: string}
  --presto-job: record # A Dataproc job for running Presto (https://prestosql.io/) queries. IMPORTANT: The Dataproc Presto Optional Component (https://cloud.google.com/dataproc/docs/concepts/components/presto) must be enabled when the cluster is created to submit a Presto job to the cluster. — shape: {clientTags?: list<string>, continueOnFailure?: bool, loggingConfig?: record, outputFormat?: string, properties?: record, queryFileUri?: string, queryList?: record}
  --pyspark-job: record # A Dataproc job for running Apache PySpark (https://spark.apache.org/docs/0.9.0/python-programming-guide.html) applications on YARN. — shape: {archiveUris?: list<string>, args?: list<string>, fileUris?: list<string>, jarFileUris?: list<string>, loggingConfig?: record, mainPythonFileUri?: string, properties?: record, pythonFileUris?: list<string>}
  --reference: record # Encapsulates the full scoping used to reference a job. — shape: {jobId?: string, projectId?: string}
  --scheduling: record # Job scheduling options. — shape: {maxFailuresPerHour?: int, maxFailuresTotal?: int}
  --spark-job: record # A Dataproc job for running Apache Spark (https://spark.apache.org/) applications on YARN. — shape: {archiveUris?: list<string>, args?: list<string>, fileUris?: list<string>, jarFileUris?: list<string>, loggingConfig?: record, mainClass?: string, mainJarFileUri?: string, properties?: record}
  --spark-r-job: record # A Dataproc job for running Apache SparkR (https://spark.apache.org/docs/latest/sparkr.html) applications on YARN. — shape: {archiveUris?: list<string>, args?: list<string>, fileUris?: list<string>, loggingConfig?: record, mainRFileUri?: string, properties?: record}
  --spark-sql-job: record # A Dataproc job for running Apache Spark SQL (https://spark.apache.org/sql/) queries. — shape: {jarFileUris?: list<string>, loggingConfig?: record, properties?: record, queryFileUri?: string, queryList?: record, scriptVariables?: record}
  --status: record # Dataproc job status.
  --trino-job: record # A Dataproc job for running Trino (https://trino.io/) queries. IMPORTANT: The Dataproc Trino Optional Component (https://cloud.google.com/dataproc/docs/concepts/components/trino) must be enabled when the cluster is created to submit a Trino job to the cluster. — shape: {clientTags?: list<string>, continueOnFailure?: bool, loggingConfig?: record, outputFormat?: string, properties?: record, queryFileUri?: string, queryList?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/projects/{projectId}/regions/{region}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: driverSchedulingConfig, var: driver_scheduling_config}, {name: hadoopJob, var: hadoop_job}, {name: hiveJob, var: hive_job}, {name: labels, var: labels}, {name: pigJob, var: pig_job}, {name: placement, var: placement}, {name: prestoJob, var: presto_job}, {name: pysparkJob, var: pyspark_job}, {name: reference, var: reference}, {name: scheduling, var: scheduling}, {name: sparkJob, var: spark_job}, {name: sparkRJob, var: spark_r_job}, {name: sparkSqlJob, var: spark_sql_job}, {name: status, var: status}, {name: trinoJob, var: trino_job}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, driver_scheduling_config: $driver_scheduling_config, hadoop_job: $hadoop_job, hive_job: $hive_job, labels: $labels, pig_job: $pig_job, placement: $placement, presto_job: $presto_job, pyspark_job: $pyspark_job, reference: $reference, scheduling: $scheduling, spark_job: $spark_job, spark_r_job: $spark_r_job, spark_sql_job: $spark_sql_job, status: $status, trino_job: $trino_job
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a job cancellation request. To access the job resource after cancellation, call regions/{region}/jobs.list (https://cloud.google.com/dataproc/docs/reference/rest/v1/projects.regions.jobs/list) or regions/{region}/jobs.get (https://cloud.google.com/dataproc/docs/reference/rest/v1/projects.regions.jobs/get).
#
# POST /v1/projects/{projectId}/regions/{region}/jobs/{jobId}:cancel
# Returns: record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>
# operationId: dataproc.projects.regions.jobs.cancel
export def "dataproc-projects-regions-jobs-cancel" [
  project_id: string
  region: string
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/jobs/{jobId}:cancel"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}, {name: jobId, var: job_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, job_id: $job_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submits a job to a cluster.
#
# POST /v1/projects/{projectId}/regions/{region}/jobs:submit
# Returns: record<done: bool, driverControlFilesUri: string, driverOutputResourceUri: string, driverSchedulingConfig: record<memoryMb: int, vcores: int>, hadoopJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, hiveJob: record<continueOnFailure: bool, jarFileUris: list<string>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, jobUuid: string, labels: record, pigJob: record<continueOnFailure: bool, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, placement: record<clusterLabels: record, clusterName: string, clusterUuid: string>, prestoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, pysparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainPythonFileUri: string, properties: record, pythonFileUris: list<string>>, reference: record<jobId: string, projectId: string>, scheduling: record<maxFailuresPerHour: int, maxFailuresTotal: int>, sparkJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainClass: string, mainJarFileUri: string, properties: record>, sparkRJob: record<archiveUris: list<string>, args: list<string>, fileUris: list<string>, loggingConfig: record<driverLogLevels: record>, mainRFileUri: string, properties: record>, sparkSqlJob: record<jarFileUris: list<string>, loggingConfig: record<driverLogLevels: record>, properties: record, queryFileUri: string, queryList: record<queries: list>, scriptVariables: record>, status: record<details: string, state: string, stateStartTime: string, substate: string>, statusHistory: table<details: string, state: string, stateStartTime: string, substate: string>, trinoJob: record<clientTags: list<string>, continueOnFailure: bool, loggingConfig: record<driverLogLevels: record>, outputFormat: string, properties: record, queryFileUri: string, queryList: record<queries: list>>, yarnApplications: table<name: string, progress: float, state: string, trackingUrl: string>>
# operationId: dataproc.projects.regions.jobs.submit
export def "dataproc-projects-regions-jobs-submit" [
  project_id: string
  region: string
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
  --job: record # A Dataproc job resource. — shape: {driverSchedulingConfig?: record, hadoopJob?: record, hiveJob?: record, labels?: record, pigJob?: record, placement?: record, prestoJob?: record, pysparkJob?: record, reference?: record, scheduling?: record, sparkJob?: record, sparkRJob?: record, sparkSqlJob?: record, status?: record, trinoJob?: record}
  --request-id: string # Optional. A unique id used to identify the request. If the server receives two SubmitJobRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.SubmitJobRequest)s with the same id, then the second request will be ignored and the first Job created and stored in the backend is returned.It is recommended to always set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The id must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/jobs:submit"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: job, var: job}, {name: requestId, var: request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, job: $job, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submits job to a cluster.
#
# POST /v1/projects/{projectId}/regions/{region}/jobs:submitAsOperation
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.jobs.submitAsOperation
export def "dataproc-projects-regions-jobs-submit-as-operation" [
  project_id: string
  region: string
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
  --job: record # A Dataproc job resource. — shape: {driverSchedulingConfig?: record, hadoopJob?: record, hiveJob?: record, labels?: record, pigJob?: record, placement?: record, prestoJob?: record, pysparkJob?: record, reference?: record, scheduling?: record, sparkJob?: record, sparkRJob?: record, sparkSqlJob?: record, status?: record, trinoJob?: record}
  --request-id: string # Optional. A unique id used to identify the request. If the server receives two SubmitJobRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.SubmitJobRequest)s with the same id, then the second request will be ignored and the first Job created and stored in the backend is returned.It is recommended to always set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The id must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{projectId}/regions/{region}/jobs:submitAsOperation"
    path_params: [{name: projectId, var: project_id}, {name: region, var: region}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: job, var: job}, {name: requestId, var: request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, region: $region, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, job: $job, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a workflow template. It does not cancel in-progress workflows.
#
# DELETE /v1/{name}
# Returns: record
# operationId: dataproc.projects.regions.workflowTemplates.delete
export def "dataproc-projects-regions-workflow-templates-delete" [
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
  --version: int # Optional. The version of workflow template to delete. If specified, will only delete the template if the current server version matches specified version.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the latest workflow template.Can retrieve previously instantiated template by specifying optional version parameter.
#
# GET /v1/{name}
# Returns: record<createTime: string, dagTimeout: string, id: string, jobs: table<hadoopJob: record, hiveJob: record, labels: record, pigJob: record, prerequisiteStepIds: list, prestoJob: record, pysparkJob: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, stepId: string, trinoJob: record>, labels: record, name: string, parameters: table<description: string, fields: list, name: string, validation: record>, placement: record<clusterSelector: record<clusterLabels: record, zone: string>, managedCluster: record<clusterName: string, config: record, labels: record>>, updateTime: string, version: int>
# operationId: dataproc.projects.regions.workflowTemplates.get
export def "dataproc-projects-regions-workflow-templates-get" [
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
  --version: int # Optional. The version of workflow template to retrieve. Only previously instantiated versions can be retrieved.If unspecified, retrieves the current version.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: version, var: version}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, version: $version, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates (replaces) workflow template. The updated template must contain version that matches the current server version.
#
# PUT /v1/{name}
# Returns: record<createTime: string, dagTimeout: string, id: string, jobs: table<hadoopJob: record, hiveJob: record, labels: record, pigJob: record, prerequisiteStepIds: list, prestoJob: record, pysparkJob: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, stepId: string, trinoJob: record>, labels: record, name: string, parameters: table<description: string, fields: list, name: string, validation: record>, placement: record<clusterSelector: record<clusterLabels: record, zone: string>, managedCluster: record<clusterName: string, config: record, labels: record>>, updateTime: string, version: int>
# operationId: dataproc.projects.regions.workflowTemplates.update
export def "dataproc-projects-regions-workflow-templates-update" [
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
  --dag-timeout: string # Optional. Timeout duration for the DAG of jobs, expressed in seconds (see JSON representation of duration (https://developers.google.com/protocol-buffers/docs/proto3#json)). The timeout duration must be from 10 minutes ("600s") to 24 hours ("86400s"). The timer begins when the first job is submitted. If the workflow is running at the end of the timeout period, any remaining jobs are cancelled, the workflow is ended, and if the workflow was running on a managed cluster, the cluster is deleted. (format: google-duration)
  --id: string
  --jobs: list # Required. The Directed Acyclic Graph of Jobs to submit. — item shape: {hadoopJob?: record, hiveJob?: record, labels?: record, pigJob?: record, prerequisiteStepIds?: list<string>, prestoJob?: record, pysparkJob?: record, scheduling?: record, sparkJob?: record, sparkRJob?: record, sparkSqlJob?: record, stepId?: string, trinoJob?: record}
  --labels: record # Optional. The labels to associate with this template. These labels will be propagated to all jobs and clusters created by the workflow instance.Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt).Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt).No more than 32 labels can be associated with a template.
  --parameters: list # Optional. Template parameters whose values are substituted into the template. Values for parameters must be provided when the template is instantiated. — item shape: {description?: string, fields?: list<string>, name?: string, validation?: record}
  --placement: record # Specifies workflow execution target.Either managed_cluster or cluster_selector is required. — shape: {clusterSelector?: record, managedCluster?: record}
  --version: int # Optional. Used to perform a consistent read-modify-write.This field should be left blank for a CreateWorkflowTemplate request. It is required for an UpdateWorkflowTemplate request, and must match the current server version. A typical update template flow would fetch the current template with a GetWorkflowTemplate request, which will return the current template with the version field filled in with the current server version. The user updates other fields in the template, then returns it as part of the UpdateWorkflowTemplate request. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dagTimeout, var: dag_timeout}, {name: id, var: id}, {name: jobs, var: jobs}, {name: labels, var: labels}, {name: parameters, var: parameters}, {name: placement, var: placement}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dag_timeout: $dag_timeout, id: $id, jobs: $jobs, labels: $labels, parameters: $parameters, placement: $placement, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns google.rpc.Code.UNIMPLEMENTED. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to Code.CANCELLED.
#
# POST /v1/{name}:cancel
# Returns: record
# operationId: dataproc.projects.regions.operations.cancel
export def "dataproc-projects-regions-operations-cancel" [
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
    method: post
    path: "/v1/{name}:cancel"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Instantiates a template and begins execution.The returned Operation can be used to track execution of workflow by polling operations.get. The Operation will complete when entire workflow is finished.The running workflow can be aborted via operations.cancel. This will cause any inflight jobs to be cancelled and workflow-owned clusters to be deleted.The Operation.metadata will be WorkflowMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#workflowmetadata). Also see Using WorkflowMetadata (https://cloud.google.com/dataproc/docs/concepts/workflows/debugging#using_workflowmetadata).On successful completion, Operation.response will be Empty.
#
# POST /v1/{name}:instantiate
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.workflowTemplates.instantiate
export def "dataproc-projects-regions-workflow-templates-instantiate" [
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
  --parameters: record # Optional. Map from parameter names to values that should be used for those parameters. Values may not exceed 1000 characters.
  --request-id: string # Optional. A tag that prevents multiple concurrent workflow instances with the same tag from running. This mitigates risk of concurrent instances started due to retries.It is recommended to always set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The tag must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
  --version: int # Optional. The version of workflow template to instantiate. If specified, the workflow will be instantiated only if the current version of the workflow template has the supplied version.This option cannot be used to instantiate a previous version of workflow template. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:instantiate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: parameters, var: parameters}, {name: requestId, var: request_id}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, parameters: $parameters, request_id: $request_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resizes a node group in a cluster. The returned Operation.metadata is NodeGroupOperationMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#nodegroupoperationmetadata).
#
# POST /v1/{name}:resize
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.nodeGroups.resize
export def "dataproc-projects-regions-clusters-node-groups-resize" [
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
  --graceful-decommission-timeout: string # Optional. Timeout for graceful YARN decommissioning. Graceful decommissioning (https://cloud.google.com/dataproc/docs/concepts/configuring-clusters/scaling-clusters#graceful_decommissioning) allows the removal of nodes from the Compute Engine node group without interrupting jobs in progress. This timeout specifies how long to wait for jobs in progress to finish before forcefully removing nodes (and potentially interrupting jobs). Default timeout is 0 (for forceful decommission), and the maximum allowed timeout is 1 day. (see JSON representation of Duration (https://developers.google.com/protocol-buffers/docs/proto3#json)).Only supported on Dataproc image versions 1.2 and higher. (format: google-duration)
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two ResizeNodeGroupRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.ResizeNodeGroupRequests) with the same ID, the second request is ignored and the first google.longrunning.Operation created and stored in the backend is returned.Recommendation: Set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
  --size: int # Required. The number of running instances for the node group to maintain. The group adds or removes instances to maintain the number of instances specified by this parameter. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:resize"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: gracefulDecommissionTimeout, var: graceful_decommission_timeout}, {name: requestId, var: request_id}, {name: size, var: size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, graceful_decommission_timeout: $graceful_decommission_timeout, request_id: $request_id, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists autoscaling policies in the project.
#
# GET /v1/{parent}/autoscalingPolicies
# Returns: record<nextPageToken: string, policies: table<basicAlgorithm: record, id: string, labels: record, name: string, secondaryWorkerConfig: record, workerConfig: record>>
# operationId: dataproc.projects.regions.autoscalingPolicies.list
export def "dataproc-projects-regions-autoscaling-policies-list" [
  parent: string
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
  --page-size: int # Optional. The maximum number of results to return in each response. Must be less than or equal to 1000. Defaults to 100.
  --page-token: string # Optional. The page token, returned by a previous call, to request the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/autoscalingPolicies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new autoscaling policy.
#
# POST /v1/{parent}/autoscalingPolicies
# Returns: record<basicAlgorithm: record<cooldownPeriod: string, sparkStandaloneConfig: record<gracefulDecommissionTimeout: string, scaleDownFactor: float, scaleDownMinWorkerFraction: float, scaleUpFactor: float, scaleUpMinWorkerFraction: float>, yarnConfig: record<gracefulDecommissionTimeout: string, scaleDownFactor: float, scaleDownMinWorkerFraction: float, scaleUpFactor: float, scaleUpMinWorkerFraction: float>>, id: string, labels: record, name: string, secondaryWorkerConfig: record<maxInstances: int, minInstances: int, weight: int>, workerConfig: record<maxInstances: int, minInstances: int, weight: int>>
# operationId: dataproc.projects.regions.autoscalingPolicies.create
export def "dataproc-projects-regions-autoscaling-policies-create" [
  parent: string
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
  --basic-algorithm: record # Basic algorithm for autoscaling. — shape: {cooldownPeriod?: string, sparkStandaloneConfig?: record, yarnConfig?: record}
  --id: string # Required. The policy id.The id must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). Cannot begin or end with underscore or hyphen. Must consist of between 3 and 50 characters.
  --labels: record # Optional. The labels to associate with this autoscaling policy. Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). No more than 32 labels can be associated with an autoscaling policy.
  --secondary-worker-config: record # Configuration for the size bounds of an instance group, including its proportional size to other groups. — shape: {maxInstances?: int, minInstances?: int, weight?: int}
  --worker-config: record # Configuration for the size bounds of an instance group, including its proportional size to other groups. — shape: {maxInstances?: int, minInstances?: int, weight?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/autoscalingPolicies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: basicAlgorithm, var: basic_algorithm}, {name: id, var: id}, {name: labels, var: labels}, {name: secondaryWorkerConfig, var: secondary_worker_config}, {name: workerConfig, var: worker_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, basic_algorithm: $basic_algorithm, id: $id, labels: $labels, secondary_worker_config: $secondary_worker_config, worker_config: $worker_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists batch workloads.
#
# GET /v1/{parent}/batches
# Returns: record<batches: table<createTime: string, creator: string, environmentConfig: record, labels: record, name: string, operation: string, pysparkBatch: record, runtimeConfig: record, runtimeInfo: record, sparkBatch: record, sparkRBatch: record, sparkSqlBatch: record, state: string, stateHistory: list, stateMessage: string, stateTime: string, uuid: string>, nextPageToken: string>
# operationId: dataproc.projects.locations.batches.list
export def "dataproc-projects-locations-batches-list" [
  parent: string
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
  --filter: string # Optional. A filter for the batches to return in the response.A filter is a logical expression constraining the values of various fields in each batch resource. Filters are case sensitive, and may contain multiple clauses combined with logical operators (AND/OR). Supported fields are batch_id, batch_uuid, state, and create_time.e.g. state = RUNNING and create_time < "2023-01-01T00:00:00Z" filters for batches in state RUNNING that were created before 2023-01-01See https://google.aip.dev/assets/misc/ebnf-filtering.txt for a detailed description of the filter syntax and a list of supported comparisons.
  --order-by: string # Optional. Field(s) on which to sort the list of batches.Currently the only supported sort orders are unspecified (empty) and create_time desc to sort by most recently created batches first.See https://google.aip.dev/132#ordering for more details.
  --page-size: int # Optional. The maximum number of batches to return in each response. The service may return fewer than this value. The default page size is 20; the maximum page size is 1000.
  --page-token: string # Optional. A page token received from a previous ListBatches call. Provide this token to retrieve the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/batches"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a batch workload that executes asynchronously.
#
# POST /v1/{parent}/batches
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.locations.batches.create
export def "dataproc-projects-locations-batches-create" [
  parent: string
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
  --batch-id: string # Optional. The ID to use for the batch, which will become the final component of the batch's resource name.This value must be 4-63 characters. Valid characters are /[a-z][0-9]-/.
  --request-id: string # Optional. A unique ID used to identify the request. If the service receives two CreateBatchRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.CreateBatchRequest)s with the same request_id, the second request is ignored and the Operation that corresponds to the first Batch created and stored in the backend is returned.Recommendation: Set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The value must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
  --environment-config: record # Environment configuration for a workload. — shape: {executionConfig?: record, peripheralsConfig?: record}
  --labels: record # Optional. The labels to associate with this batch. Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). No more than 32 labels can be associated with a batch.
  --pyspark-batch: record # A configuration for running an Apache PySpark (https://spark.apache.org/docs/latest/api/python/getting_started/quickstart.html) batch workload. — shape: {archiveUris?: list<string>, args?: list<string>, fileUris?: list<string>, jarFileUris?: list<string>, mainPythonFileUri?: string, pythonFileUris?: list<string>}
  --runtime-config: record # Runtime configuration for a workload. — shape: {containerImage?: string, properties?: record, version?: string}
  --runtime-info: record # Runtime information about workload execution. — shape: {approximateUsage?: record, currentUsage?: record}
  --spark-batch: record # A configuration for running an Apache Spark (https://spark.apache.org/) batch workload. — shape: {archiveUris?: list<string>, args?: list<string>, fileUris?: list<string>, jarFileUris?: list<string>, mainClass?: string, mainJarFileUri?: string}
  --spark-r-batch: record # A configuration for running an Apache SparkR (https://spark.apache.org/docs/latest/sparkr.html) batch workload. — shape: {archiveUris?: list<string>, args?: list<string>, fileUris?: list<string>, mainRFileUri?: string}
  --spark-sql-batch: record # A configuration for running Apache Spark SQL (https://spark.apache.org/sql/) queries as a batch workload. — shape: {jarFileUris?: list<string>, queryFileUri?: string, queryVariables?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/batches"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: batchId, var: batch_id}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentConfig, var: environment_config}, {name: labels, var: labels}, {name: pysparkBatch, var: pyspark_batch}, {name: runtimeConfig, var: runtime_config}, {name: runtimeInfo, var: runtime_info}, {name: sparkBatch, var: spark_batch}, {name: sparkRBatch, var: spark_r_batch}, {name: sparkSqlBatch, var: spark_sql_batch}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, batch_id: $batch_id, request_id: $request_id, environment_config: $environment_config, labels: $labels, pyspark_batch: $pyspark_batch, runtime_config: $runtime_config, runtime_info: $runtime_info, spark_batch: $spark_batch, spark_r_batch: $spark_r_batch, spark_sql_batch: $spark_sql_batch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a node group in a cluster. The returned Operation.metadata is NodeGroupOperationMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#nodegroupoperationmetadata).
#
# POST /v1/{parent}/nodeGroups
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.nodeGroups.create
export def "dataproc-projects-regions-clusters-node-groups-create" [
  parent: string
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
  --node-group-id: string # Optional. An optional node group ID. Generated if not specified.The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). Cannot begin or end with underscore or hyphen. Must consist of from 3 to 33 characters.
  --request-id: string # Optional. A unique ID used to identify the request. If the server receives two CreateNodeGroupRequest (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#google.cloud.dataproc.v1.CreateNodeGroupRequests) with the same ID, the second request is ignored and the first google.longrunning.Operation created and stored in the backend is returned.Recommendation: Set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
  --labels: record # Optional. Node group labels. Label keys must consist of from 1 to 63 characters and conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). Label values can be empty. If specified, they must consist of from 1 to 63 characters and conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt). The node group must have no more than 32 labelsn.
  --name: string # The Node group resource name (https://aip.dev/122).
  --node-group-config: record # The config settings for Compute Engine resources in an instance group, such as a master or worker group. — shape: {accelerators?: list, diskConfig?: record, imageUri?: string, machineTypeUri?: string, managedGroupConfig?: record, minCpuPlatform?: string, numInstances?: int, preemptibility?: "PREEMPTIBILITY_UNSPECIFIED"|"NON_PREEMPTIBLE"|"PREEMPTIBLE"|"SPOT"}
  --roles: list<string> # Required. Node group roles.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/nodeGroups"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: nodeGroupId, var: node_group_id}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}, {name: nodeGroupConfig, var: node_group_config}, {name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, node_group_id: $node_group_id, request_id: $request_id, labels: $labels, name: $name, node_group_config: $node_group_config, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists workflows that match the specified filter in the request.
#
# GET /v1/{parent}/workflowTemplates
# Returns: record<nextPageToken: string, templates: table<createTime: string, dagTimeout: string, id: string, jobs: list, labels: record, name: string, parameters: list, placement: record, updateTime: string, version: int>>
# operationId: dataproc.projects.regions.workflowTemplates.list
export def "dataproc-projects-regions-workflow-templates-list" [
  parent: string
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
  --page-size: int # Optional. The maximum number of results to return in each response.
  --page-token: string # Optional. The page token, returned by a previous call, to request the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/workflowTemplates"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new workflow template.
#
# POST /v1/{parent}/workflowTemplates
# Returns: record<createTime: string, dagTimeout: string, id: string, jobs: table<hadoopJob: record, hiveJob: record, labels: record, pigJob: record, prerequisiteStepIds: list, prestoJob: record, pysparkJob: record, scheduling: record, sparkJob: record, sparkRJob: record, sparkSqlJob: record, stepId: string, trinoJob: record>, labels: record, name: string, parameters: table<description: string, fields: list, name: string, validation: record>, placement: record<clusterSelector: record<clusterLabels: record, zone: string>, managedCluster: record<clusterName: string, config: record, labels: record>>, updateTime: string, version: int>
# operationId: dataproc.projects.regions.workflowTemplates.create
export def "dataproc-projects-regions-workflow-templates-create" [
  parent: string
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
  --dag-timeout: string # Optional. Timeout duration for the DAG of jobs, expressed in seconds (see JSON representation of duration (https://developers.google.com/protocol-buffers/docs/proto3#json)). The timeout duration must be from 10 minutes ("600s") to 24 hours ("86400s"). The timer begins when the first job is submitted. If the workflow is running at the end of the timeout period, any remaining jobs are cancelled, the workflow is ended, and if the workflow was running on a managed cluster, the cluster is deleted. (format: google-duration)
  --id: string
  --jobs: list # Required. The Directed Acyclic Graph of Jobs to submit. — item shape: {hadoopJob?: record, hiveJob?: record, labels?: record, pigJob?: record, prerequisiteStepIds?: list<string>, prestoJob?: record, pysparkJob?: record, scheduling?: record, sparkJob?: record, sparkRJob?: record, sparkSqlJob?: record, stepId?: string, trinoJob?: record}
  --labels: record # Optional. The labels to associate with this template. These labels will be propagated to all jobs and clusters created by the workflow instance.Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt).Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt).No more than 32 labels can be associated with a template.
  --parameters: list # Optional. Template parameters whose values are substituted into the template. Values for parameters must be provided when the template is instantiated. — item shape: {description?: string, fields?: list<string>, name?: string, validation?: record}
  --placement: record # Specifies workflow execution target.Either managed_cluster or cluster_selector is required. — shape: {clusterSelector?: record, managedCluster?: record}
  --version: int # Optional. Used to perform a consistent read-modify-write.This field should be left blank for a CreateWorkflowTemplate request. It is required for an UpdateWorkflowTemplate request, and must match the current server version. A typical update template flow would fetch the current template with a GetWorkflowTemplate request, which will return the current template with the version field filled in with the current server version. The user updates other fields in the template, then returns it as part of the UpdateWorkflowTemplate request. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/workflowTemplates"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dagTimeout, var: dag_timeout}, {name: id, var: id}, {name: jobs, var: jobs}, {name: labels, var: labels}, {name: parameters, var: parameters}, {name: placement, var: placement}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dag_timeout: $dag_timeout, id: $id, jobs: $jobs, labels: $labels, parameters: $parameters, placement: $placement, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Instantiates a template and begins execution.This method is equivalent to executing the sequence CreateWorkflowTemplate, InstantiateWorkflowTemplate, DeleteWorkflowTemplate.The returned Operation can be used to track execution of workflow by polling operations.get. The Operation will complete when entire workflow is finished.The running workflow can be aborted via operations.cancel. This will cause any inflight jobs to be cancelled and workflow-owned clusters to be deleted.The Operation.metadata will be WorkflowMetadata (https://cloud.google.com/dataproc/docs/reference/rpc/google.cloud.dataproc.v1#workflowmetadata). Also see Using WorkflowMetadata (https://cloud.google.com/dataproc/docs/concepts/workflows/debugging#using_workflowmetadata).On successful completion, Operation.response will be Empty.
#
# POST /v1/{parent}/workflowTemplates:instantiateInline
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.workflowTemplates.instantiateInline
export def "dataproc-projects-regions-workflow-templates-instantiate-inline" [
  parent: string
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
  --request-id: string # Optional. A tag that prevents multiple concurrent workflow instances with the same tag from running. This mitigates risk of concurrent instances started due to retries.It is recommended to always set this value to a UUID (https://en.wikipedia.org/wiki/Universally_unique_identifier).The tag must contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and hyphens (-). The maximum length is 40 characters.
  --dag-timeout: string # Optional. Timeout duration for the DAG of jobs, expressed in seconds (see JSON representation of duration (https://developers.google.com/protocol-buffers/docs/proto3#json)). The timeout duration must be from 10 minutes ("600s") to 24 hours ("86400s"). The timer begins when the first job is submitted. If the workflow is running at the end of the timeout period, any remaining jobs are cancelled, the workflow is ended, and if the workflow was running on a managed cluster, the cluster is deleted. (format: google-duration)
  --id: string
  --jobs: list # Required. The Directed Acyclic Graph of Jobs to submit. — item shape: {hadoopJob?: record, hiveJob?: record, labels?: record, pigJob?: record, prerequisiteStepIds?: list<string>, prestoJob?: record, pysparkJob?: record, scheduling?: record, sparkJob?: record, sparkRJob?: record, sparkSqlJob?: record, stepId?: string, trinoJob?: record}
  --labels: record # Optional. The labels to associate with this template. These labels will be propagated to all jobs and clusters created by the workflow instance.Label keys must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt).Label values may be empty, but, if present, must contain 1 to 63 characters, and must conform to RFC 1035 (https://www.ietf.org/rfc/rfc1035.txt).No more than 32 labels can be associated with a template.
  --parameters: list # Optional. Template parameters whose values are substituted into the template. Values for parameters must be provided when the template is instantiated. — item shape: {description?: string, fields?: list<string>, name?: string, validation?: record}
  --placement: record # Specifies workflow execution target.Either managed_cluster or cluster_selector is required. — shape: {clusterSelector?: record, managedCluster?: record}
  --version: int # Optional. Used to perform a consistent read-modify-write.This field should be left blank for a CreateWorkflowTemplate request. It is required for an UpdateWorkflowTemplate request, and must match the current server version. A typical update template flow would fetch the current template with a GetWorkflowTemplate request, which will return the current template with the version field filled in with the current server version. The user updates other fields in the template, then returns it as part of the UpdateWorkflowTemplate request. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/workflowTemplates:instantiateInline"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: requestId, var: request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dagTimeout, var: dag_timeout}, {name: id, var: id}, {name: jobs, var: jobs}, {name: labels, var: labels}, {name: parameters, var: parameters}, {name: placement, var: placement}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, request_id: $request_id, dag_timeout: $dag_timeout, id: $id, jobs: $jobs, labels: $labels, parameters: $parameters, placement: $placement, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inject encrypted credentials into all of the VMs in a cluster.The target cluster must be a personal auth cluster assigned to the user who is issuing the RPC.
#
# POST /v1/{project}/{region}/{cluster}:injectCredentials
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataproc.projects.regions.clusters.injectCredentials
export def "dataproc-projects-regions-clusters-inject-credentials" [
  project: string
  region: string
  cluster: string
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
  --cluster-uuid: string # Required. The cluster UUID.
  --credentials-ciphertext: string # Required. The encrypted credentials being injected in to the cluster.The client is responsible for encrypting the credentials in a way that is supported by the cluster.A wrapped value is used here so that the actual contents of the encrypted credentials are not written to audit logs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{project}/{region}/{cluster}:injectCredentials"
    path_params: [{name: project, var: project}, {name: region, var: region}, {name: cluster, var: cluster}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterUuid, var: cluster_uuid}, {name: credentialsCiphertext, var: credentials_ciphertext}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, region: $region, cluster: $cluster, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_uuid: $cluster_uuid, credentials_ciphertext: $credentials_ciphertext
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# POST /v1/{resource}:getIamPolicy
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: dataproc.projects.regions.workflowTemplates.getIamPolicy
export def "dataproc-projects-regions-workflow-templates-get-iam-policy" [
  resource: string
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
  --options: record # Encapsulates settings provided to GetIamPolicy. — shape: {requestedPolicyVersion?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resource}:getIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: options, var: options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the access control policy on the specified resource. Replaces any existing policy.Can return NOT_FOUND, INVALID_ARGUMENT, and PERMISSION_DENIED errors.
#
# POST /v1/{resource}:setIamPolicy
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: dataproc.projects.regions.workflowTemplates.setIamPolicy
export def "dataproc-projects-regions-workflow-templates-set-iam-policy" [
  resource: string
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
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources.A Policy is a collection of bindings. A binding binds one or more members, or principals, to a single role. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A role is a named list of permissions; each role can be an IAM predefined role or a user-created custom role.For some types of Google Cloud resources, a binding can also specify a condition, which is a logical expression that allows access to a resource only if the expression evaluates to true. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the IAM documentation (https://cloud.google.com/iam/help/conditions/resource-policies).JSON example: { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } YAML example: bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the IAM documentation (https://cloud.google.com/iam/docs/). — shape: {bindings?: list, etag?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resource}:setIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a NOT_FOUND error.Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: dataproc.projects.regions.workflowTemplates.testIamPermissions
export def "dataproc-projects-regions-workflow-templates-test-iam-permissions" [
  resource: string
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
  --permissions: list<string> # The set of permissions to check for the resource. Permissions with wildcards (such as * or storage.*) are not allowed. For more information see IAM Overview (https://cloud.google.com/iam/docs/overview#permissions).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resource}:testIamPermissions"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
