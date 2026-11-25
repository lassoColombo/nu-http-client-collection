# Auto-generated client for AI Platform Training & Prediction API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/ml/v1/openapi.json
# Auth: --token flag or $env.AI_PLATFORM_TRAINING_PREDICTION_API_TOKEN

const CLIENT = {
  base_url: "https://ml.googleapis.com"
  token_env_var: "AI_PLATFORM_TRAINING_PREDICTION_API_TOKEN"
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

def base-url-completer [] { ["https://ml.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def framework-completer [] { ["FRAMEWORK_UNSPECIFIED" "SCIKIT_LEARN" "TENSORFLOW" "XGBOOST"] }
def state-completer [] { ["CREATING" "DELETING" "FAILED" "READY" "UNKNOWN" "UPDATING"] }
def state-completer-1 [] { ["CANCELLED" "CANCELLING" "FAILED" "PREPARING" "QUEUED" "RUNNING" "STATE_UNSPECIFIED" "SUCCEEDED"] }
def state-completer-2 [] { ["ACTIVE" "COMPLETED" "REQUESTED" "STATE_UNSPECIFIED" "STOPPING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    ml-projects-models-versions-delete: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    ml-projects-operations-get: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    ml-projects-models-versions-patch: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    ml-projects-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    ml-projects-locations-studies-trials-add-measurement: "record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>"
    ml-projects-operations-cancel: "record"
    ml-projects-locations-studies-trials-check-early-stopping-state: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    ml-projects-locations-studies-trials-complete: "record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>"
    ml-projects-explain: "record<contentType: string, data: string, extensions: list<record>>"
    ml-projects-get-config: "record<config: record<tpuServiceAccount: string>, serviceAccount: string, serviceAccountProject: string>"
    ml-projects-predict: "record<contentType: string, data: string, extensions: list<record>>"
    ml-projects-models-versions-set-default: "record<acceleratorConfig: record<count: string, type: string>, autoScaling: record<maxNodes: int, metrics: list<record>, minNodes: int>, container: record<args: list<string>, command: list<string>, env: list<record>, image: string, ports: list<record>>, createTime: string, deploymentUri: string, description: string, errorMessage: string, etag: string, explanationConfig: record<integratedGradientsAttribution: record<numIntegralSteps: int>, sampledShapleyAttribution: record<numPaths: int>, xraiAttribution: record<numIntegralSteps: int>>, framework: string, isDefault: bool, labels: record, lastMigrationModelId: string, lastMigrationTime: string, lastUseTime: string, machineType: string, manualScaling: record<nodes: int>, name: string, packageUris: list<string>, predictionClass: string, pythonVersion: string, requestLoggingConfig: record<bigqueryTableName: string, samplingPercentage: float>, routes: record<health: string, predict: string>, runtimeVersion: string, serviceAccount: string, state: string>"
    ml-projects-locations-studies-trials-stop: "record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>"
    ml-projects-jobs-list: "record<jobs: table<createTime: string, endTime: string, errorMessage: string, etag: string, jobId: string, jobPosition: string, labels: record, predictionInput: record, predictionOutput: record, startTime: string, state: string, trainingInput: record, trainingOutput: record>, nextPageToken: string>"
    ml-projects-jobs-create: "record<createTime: string, endTime: string, errorMessage: string, etag: string, jobId: string, jobPosition: string, labels: record, predictionInput: record<batchSize: string, dataFormat: string, inputPaths: list<string>, maxWorkerCount: string, modelName: string, outputDataFormat: string, outputPath: string, region: string, runtimeVersion: string, signatureName: string, uri: string, versionName: string>, predictionOutput: record<errorCount: string, nodeHours: float, outputPath: string, predictionCount: string>, startTime: string, state: string, trainingInput: record<args: list<string>, enableWebAccess: bool, encryptionConfig: record<kmsKeyName: string>, evaluatorConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, evaluatorCount: string, evaluatorType: string, hyperparameters: record<algorithm: string, enableTrialEarlyStopping: bool, goal: string, hyperparameterMetricTag: string, maxFailedTrials: int, maxParallelTrials: int, maxTrials: int, params: list, resumePreviousJobId: string>, jobDir: string, masterConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, masterType: string, network: string, packageUris: list<string>, parameterServerConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, parameterServerCount: string, parameterServerType: string, pythonModule: string, pythonVersion: string, region: string, runtimeVersion: string, scaleTier: string, scheduling: record<maxRunningTime: string, maxWaitTime: string, priority: int>, serviceAccount: string, useChiefInTfConfig: bool, workerConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, workerCount: string, workerType: string>, trainingOutput: record<builtInAlgorithmOutput: record<framework: string, modelPath: string, pythonVersion: string, runtimeVersion: string>, completedTrialCount: string, consumedMLUnits: float, hyperparameterMetricTag: string, isBuiltInAlgorithmJob: bool, isHyperparameterTuningJob: bool, trials: list<record>, webAccessUris: record>>"
    ml-projects-locations-list: "record<locations: table<capabilities: list, name: string>, nextPageToken: string>"
    ml-projects-models-list: "record<models: table<defaultVersion: record, description: string, etag: string, labels: record, name: string, onlinePredictionConsoleLogging: bool, onlinePredictionLogging: bool, regions: list>, nextPageToken: string>"
    ml-projects-models-create: "record<defaultVersion: record<acceleratorConfig: record<count: string, type: string>, autoScaling: record<maxNodes: int, metrics: list, minNodes: int>, container: record<args: list, command: list, env: list, image: string, ports: list>, createTime: string, deploymentUri: string, description: string, errorMessage: string, etag: string, explanationConfig: record<integratedGradientsAttribution: record, sampledShapleyAttribution: record, xraiAttribution: record>, framework: string, isDefault: bool, labels: record, lastMigrationModelId: string, lastMigrationTime: string, lastUseTime: string, machineType: string, manualScaling: record<nodes: int>, name: string, packageUris: list<string>, predictionClass: string, pythonVersion: string, requestLoggingConfig: record<bigqueryTableName: string, samplingPercentage: float>, routes: record<health: string, predict: string>, runtimeVersion: string, serviceAccount: string, state: string>, description: string, etag: string, labels: record, name: string, onlinePredictionConsoleLogging: bool, onlinePredictionLogging: bool, regions: list<string>>"
    ml-projects-locations-studies-list: "record<studies: table<createTime: string, inactiveReason: string, name: string, state: string, studyConfig: record>>"
    ml-projects-locations-studies-create: "record<createTime: string, inactiveReason: string, name: string, state: string, studyConfig: record<algorithm: string, automatedStoppingConfig: record<decayCurveStoppingConfig: record, medianAutomatedStoppingConfig: record>, metrics: list<record>, parameters: list<record>>>"
    ml-projects-locations-studies-trials-list: "record<trials: table<clientId: string, endTime: string, finalMeasurement: record, infeasibleReason: string, measurements: list, name: string, parameters: list, startTime: string, state: string, trialInfeasible: bool>>"
    ml-projects-locations-studies-trials-create: "record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>"
    ml-projects-locations-studies-trials-list-optimal-trials: "record<trials: table<clientId: string, endTime: string, finalMeasurement: record, infeasibleReason: string, measurements: list, name: string, parameters: list, startTime: string, state: string, trialInfeasible: bool>>"
    ml-projects-locations-studies-trials-suggest: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    ml-projects-models-versions-list: "record<nextPageToken: string, versions: table<acceleratorConfig: record, autoScaling: record, container: record, createTime: string, deploymentUri: string, description: string, errorMessage: string, etag: string, explanationConfig: record, framework: string, isDefault: bool, labels: record, lastMigrationModelId: string, lastMigrationTime: string, lastUseTime: string, machineType: string, manualScaling: record, name: string, packageUris: list, predictionClass: string, pythonVersion: string, requestLoggingConfig: record, routes: record, runtimeVersion: string, serviceAccount: string, state: string>>"
    ml-projects-models-versions-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    ml-projects-models-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    ml-projects-models-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    ml-projects-models-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["ml-projects-models-versions-delete" "ml-projects-operations-get" "ml-projects-models-versions-patch" "ml-projects-operations-list" "ml-projects-locations-studies-trials-add-measurement" "ml-projects-operations-cancel" "ml-projects-locations-studies-trials-check-early-stopping-state" "ml-projects-locations-studies-trials-complete" "ml-projects-explain" "ml-projects-get-config" "ml-projects-predict" "ml-projects-models-versions-set-default" "ml-projects-locations-studies-trials-stop" "ml-projects-jobs-list" "ml-projects-jobs-create" "ml-projects-locations-list" "ml-projects-models-list" "ml-projects-models-create" "ml-projects-locations-studies-list" "ml-projects-locations-studies-create" "ml-projects-locations-studies-trials-list" "ml-projects-locations-studies-trials-create" "ml-projects-locations-studies-trials-list-optimal-trials" "ml-projects-locations-studies-trials-suggest" "ml-projects-models-versions-list" "ml-projects-models-versions-create" "ml-projects-models-get-iam-policy" "ml-projects-models-set-iam-policy" "ml-projects-models-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Deletes a model version. Each model can have multiple versions deployed and in use at any given time. Use this method to remove a single version. Note: You cannot delete the version that is set as the default version of the model unless it is the only remaining version.
#
# DELETE /v1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: ml.projects.models.versions.delete
export def "ml-projects-models-versions-delete" [
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
    method: delete
    path: "/v1/{name}"
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

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: ml.projects.operations.get
export def "ml-projects-operations-get" [
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
    method: get
    path: "/v1/{name}"
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

# Updates the specified Version resource. Currently the only update-able fields are `description`, `requestLoggingConfig`, `autoScaling.minNodes`, and `manualScaling.nodes`.
#
# PATCH /v1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: ml.projects.models.versions.patch
export def "ml-projects-models-versions-patch" [
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
  --update-mask: string # Required. Specifies the path, relative to `Version`, of the field to update. Must be present and non-empty. For example, to change the description of a version to "foo", the `update_mask` parameter would be specified as `description`, and the `PATCH` request body would specify the new value, as follows: ``` { "description": "foo" } ``` Currently the only supported update mask fields are `description`, `requestLoggingConfig`, `autoScaling.minNodes`, and `manualScaling.nodes`. However, you can only update `manualScaling.nodes` if the version uses a [Compute Engine (N1) machine type](/ml-engine/docs/machine-types-online-prediction).
  --accelerator-config: record # Represents a hardware accelerator request config. Note that the AcceleratorConfig can be used in both Jobs and Versions. Learn more about [accelerators for training](/ml-engine/docs/using-gpus) and [accelerators for online prediction](/ml-engine/docs/machine-types-online-prediction#gpus). — shape: {count?: string, type?: "ACCELERATOR_TYPE_UNSPECIFIED"|"NVIDIA_TESLA_K80"|"NVIDIA_TESLA_P100"|"NVIDIA_TESLA_V100"|"NVIDIA_TESLA_P4"|"NVIDIA_TESLA_T4"|"NVIDIA_TESLA_A100"|"TPU_V2"|"TPU_V3"|"TPU_V2_POD"|"TPU_V3_POD"|"TPU_V4_POD"}
  --auto-scaling: record # Options for automatically scaling a model. — shape: {maxNodes?: int, metrics?: list, minNodes?: int}
  --container: record # Specification of a custom container for serving predictions. This message is a subset of the [Kubernetes Container v1 core specification](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#container-v1-core). — shape: {args?: list<string>, command?: list<string>, env?: list, image?: string, ports?: list}
  --create-time: string # Output only. The time the version was created. (format: google-datetime)
  --deployment-uri: string # The Cloud Storage URI of a directory containing trained model artifacts to be used to create the model version. See the [guide to deploying models](/ai-platform/prediction/docs/deploying-models) for more information. The total number of files under this directory must not exceed 1000. During projects.models.versions.create, AI Platform Prediction copies all files from the specified directory to a location managed by the service. From then on, AI Platform Prediction uses these copies of the model artifacts to serve predictions, not the original files in Cloud Storage, so this location is useful only as a historical record. If you specify container, then this field is optional. Otherwise, it is required. Learn [how to use this field with a custom container](/ai-platform/prediction/docs/custom-container-requirements#artifacts).
  --description: string # Optional. The description specified for the version when it was created.
  --error-message: string # Output only. The details of a failure or a cancellation.
  --etag: string # `etag` is used for optimistic concurrency control as a way to help prevent simultaneous updates of a model from overwriting each other. It is strongly suggested that systems make use of the `etag` in the read-modify-write cycle to perform model updates in order to avoid race conditions: An `etag` is returned in the response to `GetVersion`, and systems are expected to put that etag in the request to `UpdateVersion` to ensure that their change will be applied to the model as intended. (format: byte)
  --explanation-config: record # Message holding configuration options for explaining model predictions. There are three feature attribution methods supported for TensorFlow models: integrated gradients, sampled Shapley, and XRAI. [Learn more about feature attributions.](/ai-platform/prediction/docs/ai-explanations/overview) — shape: {integratedGradientsAttribution?: record, sampledShapleyAttribution?: record, xraiAttribution?: record}
  --framework: string@framework-completer # Optional. The machine learning framework AI Platform uses to train this version of the model. Valid values are `TENSORFLOW`, `SCIKIT_LEARN`, `XGBOOST`. If you do not specify a framework, AI Platform will analyze files in the deployment_uri to determine a framework. If you choose `SCIKIT_LEARN` or `XGBOOST`, you must also set the runtime version of the model to 1.4 or greater. Do **not** specify a framework if you're deploying a [custom prediction routine](/ai-platform/prediction/docs/custom-prediction-routines) or if you're using a [custom container](/ai-platform/prediction/docs/use-custom-container).
  --is-default: oneof<nothing, bool> # Output only. If true, this version will be used to handle prediction requests that do not specify a version. You can change the default version by calling projects.methods.versions.setDefault.
  --labels: record # Optional. One or more labels that you can add, to organize your model versions. Each label is a key-value pair, where both the key and the value are arbitrary strings that you supply. For more information, see the documentation on using labels. Note that this field is not updatable for mls1* models.
  --last-use-time: string # Output only. The time the version was last used for prediction. (format: google-datetime)
  --machine-type: string # Optional. The type of machine on which to serve the model. Currently only applies to online prediction service. To learn about valid values for this field, read [Choosing a machine type for online prediction](/ai-platform/prediction/docs/machine-types-online-prediction). If this field is not specified and you are using a [regional endpoint](/ai-platform/prediction/docs/regional-endpoints), then the machine type defaults to `n1-standard-2`. If this field is not specified and you are using the global endpoint (`ml.googleapis.com`), then the machine type defaults to `mls1-c1-m2`.
  --manual-scaling: record # Options for manually scaling a model. — shape: {nodes?: int}
  --body-name: string # Required. The name specified for the version when it was created. The version name must be unique within the model it is created in. (spec name: name)
  --package-uris: list<string> # Optional. Cloud Storage paths (`gs://…`) of packages for [custom prediction routines](/ml-engine/docs/tensorflow/custom-prediction-routines) or [scikit-learn pipelines with custom code](/ml-engine/docs/scikit/exporting-for-prediction#custom-pipeline-code). For a custom prediction routine, one of these packages must contain your Predictor class (see [`predictionClass`](#Version.FIELDS.prediction_class)). Additionally, include any dependencies used by your Predictor or scikit-learn pipeline uses that are not already included in your selected [runtime version](/ml-engine/docs/tensorflow/runtime-version-list). If you specify this field, you must also set [`runtimeVersion`](#Version.FIELDS.runtime_version) to 1.4 or greater.
  --prediction-class: string # Optional. The fully qualified name (module_name.class_name) of a class that implements the Predictor interface described in this reference field. The module containing this class should be included in a package provided to the [`packageUris` field](#Version.FIELDS.package_uris). Specify this field if and only if you are deploying a [custom prediction routine (beta)](/ml-engine/docs/tensorflow/custom-prediction-routines). If you specify this field, you must set [`runtimeVersion`](#Version.FIELDS.runtime_version) to 1.4 or greater and you must set `machineType` to a [legacy (MLS1) machine type](/ml-engine/docs/machine-types-online-prediction). The following code sample provides the Predictor interface: class Predictor(object): """Interface for constructing custom predictors.""" def predict(self, instances, **kwargs): """Performs custom prediction. Instances are the decoded values from the request. They have already been deserialized from JSON. Args: instances: A list of prediction input instances. **kwargs: A dictionary of keyword args provided as additional fields on the predict request body. Returns: A list of outputs containing the prediction results. This list must be JSON serializable. """ raise NotImplementedError() @classmethod def from_path(cls, model_dir): """Creates an instance of Predictor using the given path. Loading of the predictor should be done in this method. Args: model_dir: The local directory that contains the exported model file along with any additional files uploaded when creating the version resource. Returns: An instance implementing this Predictor class. """ raise NotImplementedError() Learn more about [the Predictor interface and custom prediction routines](/ml-engine/docs/tensorflow/custom-prediction-routines).
  --python-version: string # Required. The version of Python used in prediction. The following Python versions are available: * Python '3.7' is available when `runtime_version` is set to '1.15' or later. * Python '3.5' is available when `runtime_version` is set to a version from '1.4' to '1.14'. * Python '2.7' is available when `runtime_version` is set to '1.15' or earlier. Read more about the Python versions available for [each runtime version](/ml-engine/docs/runtime-version-list).
  --request-logging-config: record # Configuration for logging request-response pairs to a BigQuery table. Online prediction requests to a model version and the responses to these requests are converted to raw strings and saved to the specified BigQuery table. Logging is constrained by [BigQuery quotas and limits](/bigquery/quotas). If your project exceeds BigQuery quotas or limits, AI Platform Prediction does not log request-response pairs, but it continues to serve predictions. If you are using [continuous evaluation](/ml-engine/docs/continuous-evaluation/), you do not need to specify this configuration manually. Setting up continuous evaluation automatically enables logging of request-response pairs. — shape: {bigqueryTableName?: string, samplingPercentage?: float}
  --routes: record # Specifies HTTP paths served by a custom container. AI Platform Prediction sends requests to these paths on the container; the custom container must run an HTTP server that responds to these requests with appropriate responses. Read [Custom container requirements](/ai-platform/prediction/docs/custom-container-requirements) for details on how to create your container image to meet these requirements. — shape: {health?: string, predict?: string}
  --runtime-version: string # Required. The AI Platform runtime version to use for this deployment. For more information, see the [runtime version list](/ml-engine/docs/runtime-version-list) and [how to manage runtime versions](/ml-engine/docs/versioning).
  --service-account: string # Optional. Specifies the service account for resource access control. If you specify this field, then you must also specify either the `containerSpec` or the `predictionClass` field. Learn more about [using a custom service account](/ai-platform/prediction/docs/custom-service-account).
  --state: string@state-completer # Output only. The state of a version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceleratorConfig, var: accelerator_config}, {name: autoScaling, var: auto_scaling}, {name: container, var: container}, {name: createTime, var: create_time}, {name: deploymentUri, var: deployment_uri}, {name: description, var: description}, {name: errorMessage, var: error_message}, {name: etag, var: etag}, {name: explanationConfig, var: explanation_config}, {name: framework, var: framework}, {name: isDefault, var: is_default}, {name: labels, var: labels}, {name: lastUseTime, var: last_use_time}, {name: machineType, var: machine_type}, {name: manualScaling, var: manual_scaling}, {name: name, var: body_name}, {name: packageUris, var: package_uris}, {name: predictionClass, var: prediction_class}, {name: pythonVersion, var: python_version}, {name: requestLoggingConfig, var: request_logging_config}, {name: routes, var: routes}, {name: runtimeVersion, var: runtime_version}, {name: serviceAccount, var: service_account}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, accelerator_config: $accelerator_config, auto_scaling: $auto_scaling, container: $container, create_time: $create_time, deployment_uri: $deployment_uri, description: $description, error_message: $error_message, etag: $etag, explanation_config: $explanation_config, framework: $framework, is_default: $is_default, labels: $labels, last_use_time: $last_use_time, machine_type: $machine_type, manual_scaling: $manual_scaling, body_name: $body_name, package_uris: $package_uris, prediction_class: $prediction_class, python_version: $python_version, request_logging_config: $request_logging_config, routes: $routes, runtime_version: $runtime_version, service_account: $service_account, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v1/{name}/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: ml.projects.operations.list
export def "ml-projects-operations-list" [
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
  --filter: string # The standard list filter.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}/operations"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a measurement of the objective metrics to a trial. This measurement is assumed to have been taken before the trial is complete.
#
# POST /v1/{name}:addMeasurement
# Returns: record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>
# operationId: ml.projects.locations.studies.trials.addMeasurement
export def "ml-projects-locations-studies-trials-add-measurement" [
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
  --measurement: record # A message representing a measurement. — shape: {elapsedTime?: string, metrics?: list, stepCount?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:addMeasurement"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: measurement, var: measurement}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, measurement: $measurement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
#
# POST /v1/{name}:cancel
# Returns: record
# operationId: ml.projects.operations.cancel
export def "ml-projects-operations-cancel" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:cancel"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether a trial should stop or not. Returns a long-running operation. When the operation is successful, it will contain a CheckTrialEarlyStoppingStateResponse.
#
# POST /v1/{name}:checkEarlyStoppingState
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: ml.projects.locations.studies.trials.checkEarlyStoppingState
export def "ml-projects-locations-studies-trials-check-early-stopping-state" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:checkEarlyStoppingState"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks a trial as complete.
#
# POST /v1/{name}:complete
# Returns: record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>
# operationId: ml.projects.locations.studies.trials.complete
export def "ml-projects-locations-studies-trials-complete" [
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
  --final-measurement: record # A message representing a measurement. — shape: {elapsedTime?: string, metrics?: list, stepCount?: string}
  --infeasible-reason: string # Optional. A human readable reason why the trial was infeasible. This should only be provided if `trial_infeasible` is true.
  --trial-infeasible: oneof<nothing, bool> # Optional. True if the trial cannot be run with the given Parameter, and final_measurement will be ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:complete"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: finalMeasurement, var: final_measurement}, {name: infeasibleReason, var: infeasible_reason}, {name: trialInfeasible, var: trial_infeasible}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, final_measurement: $final_measurement, infeasible_reason: $infeasible_reason, trial_infeasible: $trial_infeasible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs explanation on the data in the request. {% dynamic include "/ai-platform/includes/___explain-request" %}
#
# POST /v1/{name}:explain
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: ml.projects.explain
export def "ml-projects-explain" [
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
  --http-body: record # Message that represents an arbitrary HTTP body. It should only be used for payload formats that can't be represented as JSON, such as raw binary or an HTML page. This message can be used both in streaming and non-streaming API methods in the request as well as the response. It can be used as a top-level request field, which is convenient if one wants to extract parameters from either the URL or HTTP template into the request fields and also want access to the raw HTTP body. Example: message GetResourceRequest { // A unique request id. string request_id = 1; // The raw HTTP body is bound to this field. google.api.HttpBody http_body = 2; } service ResourceService { rpc GetResource(GetResourceRequest) returns (google.api.HttpBody); rpc UpdateResource(google.api.HttpBody) returns (google.protobuf.Empty); } Example with streaming methods: service CaldavService { rpc GetCalendar(stream google.api.HttpBody) returns (stream google.api.HttpBody); rpc UpdateCalendar(stream google.api.HttpBody) returns (stream google.api.HttpBody); } Use of this type only changes how the request and response bodies are handled, all other features will continue to work unchanged. — shape: {contentType?: string, data?: string, extensions?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:explain"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: httpBody, var: http_body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, http_body: $http_body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the service account information associated with your project. You need this information in order to grant the service account permissions for the Google Cloud Storage location where you put your model training code for training the model with Google Cloud Machine Learning.
#
# GET /v1/{name}:getConfig
# Returns: record<config: record<tpuServiceAccount: string>, serviceAccount: string, serviceAccountProject: string>
# operationId: ml.projects.getConfig
export def "ml-projects-get-config" [
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
    method: get
    path: "/v1/{name}:getConfig"
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

# Performs online prediction on the data in the request. {% dynamic include "/ai-platform/includes/___predict-request" %}
#
# POST /v1/{name}:predict
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: ml.projects.predict
export def "ml-projects-predict" [
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
  --http-body: record # Message that represents an arbitrary HTTP body. It should only be used for payload formats that can't be represented as JSON, such as raw binary or an HTML page. This message can be used both in streaming and non-streaming API methods in the request as well as the response. It can be used as a top-level request field, which is convenient if one wants to extract parameters from either the URL or HTTP template into the request fields and also want access to the raw HTTP body. Example: message GetResourceRequest { // A unique request id. string request_id = 1; // The raw HTTP body is bound to this field. google.api.HttpBody http_body = 2; } service ResourceService { rpc GetResource(GetResourceRequest) returns (google.api.HttpBody); rpc UpdateResource(google.api.HttpBody) returns (google.protobuf.Empty); } Example with streaming methods: service CaldavService { rpc GetCalendar(stream google.api.HttpBody) returns (stream google.api.HttpBody); rpc UpdateCalendar(stream google.api.HttpBody) returns (stream google.api.HttpBody); } Use of this type only changes how the request and response bodies are handled, all other features will continue to work unchanged. — shape: {contentType?: string, data?: string, extensions?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:predict"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: httpBody, var: http_body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, http_body: $http_body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Designates a version to be the default for the model. The default version is used for prediction requests made against the model that don't specify a version. The first version to be created for a model is automatically set as the default. You must make any subsequent changes to the default version setting manually using this method.
#
# POST /v1/{name}:setDefault
# Returns: record<acceleratorConfig: record<count: string, type: string>, autoScaling: record<maxNodes: int, metrics: list<record>, minNodes: int>, container: record<args: list<string>, command: list<string>, env: list<record>, image: string, ports: list<record>>, createTime: string, deploymentUri: string, description: string, errorMessage: string, etag: string, explanationConfig: record<integratedGradientsAttribution: record<numIntegralSteps: int>, sampledShapleyAttribution: record<numPaths: int>, xraiAttribution: record<numIntegralSteps: int>>, framework: string, isDefault: bool, labels: record, lastMigrationModelId: string, lastMigrationTime: string, lastUseTime: string, machineType: string, manualScaling: record<nodes: int>, name: string, packageUris: list<string>, predictionClass: string, pythonVersion: string, requestLoggingConfig: record<bigqueryTableName: string, samplingPercentage: float>, routes: record<health: string, predict: string>, runtimeVersion: string, serviceAccount: string, state: string>
# operationId: ml.projects.models.versions.setDefault
export def "ml-projects-models-versions-set-default" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:setDefault"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a trial.
#
# POST /v1/{name}:stop
# Returns: record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>
# operationId: ml.projects.locations.studies.trials.stop
export def "ml-projects-locations-studies-trials-stop" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:stop"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the jobs in the project. If there are no jobs that match the request parameters, the list request returns an empty response body: {}.
#
# GET /v1/{parent}/jobs
# Returns: record<jobs: table<createTime: string, endTime: string, errorMessage: string, etag: string, jobId: string, jobPosition: string, labels: record, predictionInput: record, predictionOutput: record, startTime: string, state: string, trainingInput: record, trainingOutput: record>, nextPageToken: string>
# operationId: ml.projects.jobs.list
export def "ml-projects-jobs-list" [
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
  --filter: string # Optional. Specifies the subset of jobs to retrieve. You can filter on the value of one or more attributes of the job object. For example, retrieve jobs with a job identifier that starts with 'census': gcloud ai-platform jobs list --filter='jobId:census*' List all failed jobs with names that start with 'rnn': gcloud ai-platform jobs list --filter='jobId:rnn* AND state:FAILED' For more examples, see the guide to monitoring jobs.
  --page-size: int # Optional. The number of jobs to retrieve per "page" of results. If there are more remaining results than this number, the response message will contain a valid value in the `next_page_token` field. The default value is 20, and the maximum page size is 100.
  --page-token: string # Optional. A page token to request the next page of results. You get the token from the `next_page_token` field of the response from the previous call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/jobs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a training or a batch prediction job.
#
# POST /v1/{parent}/jobs
# Returns: record<createTime: string, endTime: string, errorMessage: string, etag: string, jobId: string, jobPosition: string, labels: record, predictionInput: record<batchSize: string, dataFormat: string, inputPaths: list<string>, maxWorkerCount: string, modelName: string, outputDataFormat: string, outputPath: string, region: string, runtimeVersion: string, signatureName: string, uri: string, versionName: string>, predictionOutput: record<errorCount: string, nodeHours: float, outputPath: string, predictionCount: string>, startTime: string, state: string, trainingInput: record<args: list<string>, enableWebAccess: bool, encryptionConfig: record<kmsKeyName: string>, evaluatorConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, evaluatorCount: string, evaluatorType: string, hyperparameters: record<algorithm: string, enableTrialEarlyStopping: bool, goal: string, hyperparameterMetricTag: string, maxFailedTrials: int, maxParallelTrials: int, maxTrials: int, params: list, resumePreviousJobId: string>, jobDir: string, masterConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, masterType: string, network: string, packageUris: list<string>, parameterServerConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, parameterServerCount: string, parameterServerType: string, pythonModule: string, pythonVersion: string, region: string, runtimeVersion: string, scaleTier: string, scheduling: record<maxRunningTime: string, maxWaitTime: string, priority: int>, serviceAccount: string, useChiefInTfConfig: bool, workerConfig: record<acceleratorConfig: record, containerArgs: list, containerCommand: list, diskConfig: record, imageUri: string, tpuTfVersion: string>, workerCount: string, workerType: string>, trainingOutput: record<builtInAlgorithmOutput: record<framework: string, modelPath: string, pythonVersion: string, runtimeVersion: string>, completedTrialCount: string, consumedMLUnits: float, hyperparameterMetricTag: string, isBuiltInAlgorithmJob: bool, isHyperparameterTuningJob: bool, trials: list<record>, webAccessUris: record>>
# operationId: ml.projects.jobs.create
export def "ml-projects-jobs-create" [
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
  --create-time: string # Output only. When the job was created. (format: google-datetime)
  --end-time: string # Output only. When the job processing was completed. (format: google-datetime)
  --error-message: string # Output only. The details of a failure or a cancellation.
  --etag: string # `etag` is used for optimistic concurrency control as a way to help prevent simultaneous updates of a job from overwriting each other. It is strongly suggested that systems make use of the `etag` in the read-modify-write cycle to perform job updates in order to avoid race conditions: An `etag` is returned in the response to `GetJob`, and systems are expected to put that etag in the request to `UpdateJob` to ensure that their change will be applied to the same version of the job. (format: byte)
  --job-id: string # Required. The user-specified id of the job.
  --labels: record # Optional. One or more labels that you can add, to organize your jobs. Each label is a key-value pair, where both the key and the value are arbitrary strings that you supply. For more information, see the documentation on using labels.
  --prediction-input: record # Represents input parameters for a prediction job. — shape: {batchSize?: string, dataFormat?: "DATA_FORMAT_UNSPECIFIED"|"JSON"|"TEXT"|"TF_RECORD"|"TF_RECORD_GZIP"|"CSV", inputPaths?: list<string>, maxWorkerCount?: string, modelName?: string, outputDataFormat?: "DATA_FORMAT_UNSPECIFIED"|"JSON"|"TEXT"|"TF_RECORD"|"TF_RECORD_GZIP"|"CSV", outputPath?: string, region?: string, runtimeVersion?: string, signatureName?: string, uri?: string, versionName?: string}
  --prediction-output: record # Represents results of a prediction job. — shape: {errorCount?: string, nodeHours?: float, outputPath?: string, predictionCount?: string}
  --start-time: string # Output only. When the job processing was started. (format: google-datetime)
  --state: string@state-completer-1 # Output only. The detailed state of a job.
  --training-input: record # Represents input parameters for a training job. When using the gcloud command to submit your training job, you can specify the input parameters as command-line arguments and/or in a YAML configuration file referenced from the --config command-line argument. For details, see the guide to [submitting a training job](/ai-platform/training/docs/training-jobs). — shape: {args?: list<string>, enableWebAccess?: bool, encryptionConfig?: record, evaluatorConfig?: record, evaluatorCount?: string, evaluatorType?: string, hyperparameters?: record, jobDir?: string, masterConfig?: record, masterType?: string, network?: string, packageUris?: list<string>, parameterServerConfig?: record, parameterServerCount?: string, parameterServerType?: string, pythonModule?: string, pythonVersion?: string, region?: string, runtimeVersion?: string, ... (7 more fields)}
  --training-output: record # Represents results of a training job. Output only. — shape: {builtInAlgorithmOutput?: record, completedTrialCount?: string, consumedMLUnits?: float, hyperparameterMetricTag?: string, isBuiltInAlgorithmJob?: bool, isHyperparameterTuningJob?: bool, trials?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/jobs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: createTime, var: create_time}, {name: endTime, var: end_time}, {name: errorMessage, var: error_message}, {name: etag, var: etag}, {name: jobId, var: job_id}, {name: labels, var: labels}, {name: predictionInput, var: prediction_input}, {name: predictionOutput, var: prediction_output}, {name: startTime, var: start_time}, {name: state, var: state}, {name: trainingInput, var: training_input}, {name: trainingOutput, var: training_output}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, create_time: $create_time, end_time: $end_time, error_message: $error_message, etag: $etag, job_id: $job_id, labels: $labels, prediction_input: $prediction_input, prediction_output: $prediction_output, start_time: $start_time, state: $state, training_input: $training_input, training_output: $training_output
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all locations that provides at least one type of CMLE capability.
#
# GET /v1/{parent}/locations
# Returns: record<locations: table<capabilities: list, name: string>, nextPageToken: string>
# operationId: ml.projects.locations.list
export def "ml-projects-locations-list" [
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
  --page-size: int # Optional. The number of locations to retrieve per "page" of results. If there are more remaining results than this number, the response message will contain a valid value in the `next_page_token` field. The default value is 20, and the maximum page size is 100.
  --page-token: string # Optional. A page token to request the next page of results. You get the token from the `next_page_token` field of the response from the previous call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/locations"
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

# Lists the models in a project. Each project can contain multiple models, and each model can have multiple versions. If there are no models that match the request parameters, the list request returns an empty response body: {}.
#
# GET /v1/{parent}/models
# Returns: record<models: table<defaultVersion: record, description: string, etag: string, labels: record, name: string, onlinePredictionConsoleLogging: bool, onlinePredictionLogging: bool, regions: list>, nextPageToken: string>
# operationId: ml.projects.models.list
export def "ml-projects-models-list" [
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
  --filter: string # Optional. Specifies the subset of models to retrieve.
  --page-size: int # Optional. The number of models to retrieve per "page" of results. If there are more remaining results than this number, the response message will contain a valid value in the `next_page_token` field. The default value is 20, and the maximum page size is 100.
  --page-token: string # Optional. A page token to request the next page of results. You get the token from the `next_page_token` field of the response from the previous call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/models"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a model which will later contain one or more versions. You must add at least one version before you can request predictions from the model. Add versions by calling projects.models.versions.create.
#
# POST /v1/{parent}/models
# Returns: record<defaultVersion: record<acceleratorConfig: record<count: string, type: string>, autoScaling: record<maxNodes: int, metrics: list, minNodes: int>, container: record<args: list, command: list, env: list, image: string, ports: list>, createTime: string, deploymentUri: string, description: string, errorMessage: string, etag: string, explanationConfig: record<integratedGradientsAttribution: record, sampledShapleyAttribution: record, xraiAttribution: record>, framework: string, isDefault: bool, labels: record, lastMigrationModelId: string, lastMigrationTime: string, lastUseTime: string, machineType: string, manualScaling: record<nodes: int>, name: string, packageUris: list<string>, predictionClass: string, pythonVersion: string, requestLoggingConfig: record<bigqueryTableName: string, samplingPercentage: float>, routes: record<health: string, predict: string>, runtimeVersion: string, serviceAccount: string, state: string>, description: string, etag: string, labels: record, name: string, onlinePredictionConsoleLogging: bool, onlinePredictionLogging: bool, regions: list<string>>
# operationId: ml.projects.models.create
export def "ml-projects-models-create" [
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
  --default-version: record # Represents a version of the model. Each version is a trained model deployed in the cloud, ready to handle prediction requests. A model can have multiple versions. You can get information about all of the versions of a given model by calling projects.models.versions.list. — shape: {acceleratorConfig?: record, autoScaling?: record, container?: record, createTime?: string, deploymentUri?: string, description?: string, errorMessage?: string, etag?: string, explanationConfig?: record, framework?: "FRAMEWORK_UNSPECIFIED"|"TENSORFLOW"|"SCIKIT_LEARN"|"XGBOOST", isDefault?: bool, labels?: record, lastUseTime?: string, machineType?: string, manualScaling?: record, name?: string, packageUris?: list<string>, predictionClass?: string, pythonVersion?: string, ... (5 more fields)}
  --description: string # Optional. The description specified for the model when it was created.
  --etag: string # `etag` is used for optimistic concurrency control as a way to help prevent simultaneous updates of a model from overwriting each other. It is strongly suggested that systems make use of the `etag` in the read-modify-write cycle to perform model updates in order to avoid race conditions: An `etag` is returned in the response to `GetModel`, and systems are expected to put that etag in the request to `UpdateModel` to ensure that their change will be applied to the model as intended. (format: byte)
  --labels: record # Optional. One or more labels that you can add, to organize your models. Each label is a key-value pair, where both the key and the value are arbitrary strings that you supply. For more information, see the documentation on using labels. Note that this field is not updatable for mls1* models.
  --name: string # Required. The name specified for the model when it was created. The model name must be unique within the project it is created in.
  --online-prediction-console-logging: oneof<nothing, bool> # Optional. If true, online prediction nodes send `stderr` and `stdout` streams to Cloud Logging. These can be more verbose than the standard access logs (see `onlinePredictionLogging`) and can incur higher cost. However, they are helpful for debugging. Note that [logs may incur a cost](/stackdriver/pricing), especially if your project receives prediction requests at a high QPS. Estimate your costs before enabling this option. Default is false.
  --online-prediction-logging: oneof<nothing, bool> # Optional. If true, online prediction access logs are sent to Cloud Logging. These logs are like standard server access logs, containing information like timestamp and latency for each request. Note that [logs may incur a cost](/stackdriver/pricing), especially if your project receives prediction requests at a high queries per second rate (QPS). Estimate your costs before enabling this option. Default is false.
  --regions: list<string> # Optional. The list of regions where the model is going to be deployed. Only one region per model is supported. Defaults to 'us-central1' if nothing is set. See the available regions for AI Platform services. Note: * No matter where a model is deployed, it can always be accessed by users from anywhere, both for online and batch prediction. * The region for a batch prediction job is set by the region field when submitting the batch prediction job and does not take its value from this field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/models"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultVersion, var: default_version}, {name: description, var: description}, {name: etag, var: etag}, {name: labels, var: labels}, {name: name, var: name}, {name: onlinePredictionConsoleLogging, var: online_prediction_console_logging}, {name: onlinePredictionLogging, var: online_prediction_logging}, {name: regions, var: regions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, default_version: $default_version, description: $description, etag: $etag, labels: $labels, name: $name, online_prediction_console_logging: $online_prediction_console_logging, online_prediction_logging: $online_prediction_logging, regions: $regions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the studies in a region for an associated project.
#
# GET /v1/{parent}/studies
# Returns: record<studies: table<createTime: string, inactiveReason: string, name: string, state: string, studyConfig: record>>
# operationId: ml.projects.locations.studies.list
export def "ml-projects-locations-studies-list" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/studies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a study.
#
# POST /v1/{parent}/studies
# Returns: record<createTime: string, inactiveReason: string, name: string, state: string, studyConfig: record<algorithm: string, automatedStoppingConfig: record<decayCurveStoppingConfig: record, medianAutomatedStoppingConfig: record>, metrics: list<record>, parameters: list<record>>>
# operationId: ml.projects.locations.studies.create
export def "ml-projects-locations-studies-create" [
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
  --study-id: string # Required. The ID to use for the study, which will become the final component of the study's resource name.
  --study-config: record # Represents configuration of a study. — shape: {algorithm?: "ALGORITHM_UNSPECIFIED"|"GAUSSIAN_PROCESS_BANDIT"|"GRID_SEARCH"|"RANDOM_SEARCH", automatedStoppingConfig?: record, metrics?: list, parameters?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/studies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: studyId, var: study_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: studyConfig, var: study_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, study_id: $study_id, study_config: $study_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the trials associated with a study.
#
# GET /v1/{parent}/trials
# Returns: record<trials: table<clientId: string, endTime: string, finalMeasurement: record, infeasibleReason: string, measurements: list, name: string, parameters: list, startTime: string, state: string, trialInfeasible: bool>>
# operationId: ml.projects.locations.studies.trials.list
export def "ml-projects-locations-studies-trials-list" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/trials"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user provided trial to a study.
#
# POST /v1/{parent}/trials
# Returns: record<clientId: string, endTime: string, finalMeasurement: record<elapsedTime: string, metrics: list<record>, stepCount: string>, infeasibleReason: string, measurements: table<elapsedTime: string, metrics: list, stepCount: string>, name: string, parameters: table<floatValue: float, intValue: string, parameter: string, stringValue: string>, startTime: string, state: string, trialInfeasible: bool>
# operationId: ml.projects.locations.studies.trials.create
export def "ml-projects-locations-studies-trials-create" [
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
  --final-measurement: record # A message representing a measurement. — shape: {elapsedTime?: string, metrics?: list, stepCount?: string}
  --measurements: list # A list of measurements that are strictly lexicographically ordered by their induced tuples (steps, elapsed_time). These are used for early stopping computations. — item shape: {elapsedTime?: string, metrics?: list, stepCount?: string}
  --parameters: list # The parameters of the trial. — item shape: {floatValue?: float, intValue?: string, parameter?: string, stringValue?: string}
  --state: string@state-completer-2 # The detailed state of a trial.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/trials"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: finalMeasurement, var: final_measurement}, {name: measurements, var: measurements}, {name: parameters, var: parameters}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, final_measurement: $final_measurement, measurements: $measurements, parameters: $parameters, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the pareto-optimal trials for multi-objective study or the optimal trials for single-objective study. The definition of pareto-optimal can be checked in wiki page. https://en.wikipedia.org/wiki/Pareto_efficiency
#
# POST /v1/{parent}/trials:listOptimalTrials
# Returns: record<trials: table<clientId: string, endTime: string, finalMeasurement: record, infeasibleReason: string, measurements: list, name: string, parameters: list, startTime: string, state: string, trialInfeasible: bool>>
# operationId: ml.projects.locations.studies.trials.listOptimalTrials
export def "ml-projects-locations-studies-trials-list-optimal-trials" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/trials:listOptimalTrials"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more trials to a study, with parameter values suggested by AI Platform Vizier. Returns a long-running operation associated with the generation of trial suggestions. When this long-running operation succeeds, it will contain a SuggestTrialsResponse.
#
# POST /v1/{parent}/trials:suggest
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: ml.projects.locations.studies.trials.suggest
export def "ml-projects-locations-studies-trials-suggest" [
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
  --client-id: string # Required. The identifier of the client that is requesting the suggestion. If multiple SuggestTrialsRequests have the same `client_id`, the service will return the identical suggested trial if the trial is pending, and provide a new trial if the last suggested trial was completed.
  --suggestion-count: int # Required. The number of suggestions requested. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/trials:suggest"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: suggestionCount, var: suggestion_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_id: $client_id, suggestion_count: $suggestion_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets basic information about all the versions of a model. If you expect that a model has many versions, or if you need to handle only a limited number of results at a time, you can request that the list be retrieved in batches (called pages). If there are no versions that match the request parameters, the list request returns an empty response body: {}.
#
# GET /v1/{parent}/versions
# Returns: record<nextPageToken: string, versions: table<acceleratorConfig: record, autoScaling: record, container: record, createTime: string, deploymentUri: string, description: string, errorMessage: string, etag: string, explanationConfig: record, framework: string, isDefault: bool, labels: record, lastMigrationModelId: string, lastMigrationTime: string, lastUseTime: string, machineType: string, manualScaling: record, name: string, packageUris: list, predictionClass: string, pythonVersion: string, requestLoggingConfig: record, routes: record, runtimeVersion: string, serviceAccount: string, state: string>>
# operationId: ml.projects.models.versions.list
export def "ml-projects-models-versions-list" [
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
  --filter: string # Optional. Specifies the subset of versions to retrieve.
  --page-size: int # Optional. The number of versions to retrieve per "page" of results. If there are more remaining results than this number, the response message will contain a valid value in the `next_page_token` field. The default value is 20, and the maximum page size is 100.
  --page-token: string # Optional. A page token to request the next page of results. You get the token from the `next_page_token` field of the response from the previous call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/versions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of a model from a trained TensorFlow model. If the version created in the cloud by this call is the first deployed version of the specified model, it will be made the default version of the model. When you add a version to a model that already has one or more versions, the default version does not automatically change. If you want a new version to be the default, you must call projects.models.versions.setDefault.
#
# POST /v1/{parent}/versions
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: ml.projects.models.versions.create
export def "ml-projects-models-versions-create" [
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
  --accelerator-config: record # Represents a hardware accelerator request config. Note that the AcceleratorConfig can be used in both Jobs and Versions. Learn more about [accelerators for training](/ml-engine/docs/using-gpus) and [accelerators for online prediction](/ml-engine/docs/machine-types-online-prediction#gpus). — shape: {count?: string, type?: "ACCELERATOR_TYPE_UNSPECIFIED"|"NVIDIA_TESLA_K80"|"NVIDIA_TESLA_P100"|"NVIDIA_TESLA_V100"|"NVIDIA_TESLA_P4"|"NVIDIA_TESLA_T4"|"NVIDIA_TESLA_A100"|"TPU_V2"|"TPU_V3"|"TPU_V2_POD"|"TPU_V3_POD"|"TPU_V4_POD"}
  --auto-scaling: record # Options for automatically scaling a model. — shape: {maxNodes?: int, metrics?: list, minNodes?: int}
  --container: record # Specification of a custom container for serving predictions. This message is a subset of the [Kubernetes Container v1 core specification](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#container-v1-core). — shape: {args?: list<string>, command?: list<string>, env?: list, image?: string, ports?: list}
  --create-time: string # Output only. The time the version was created. (format: google-datetime)
  --deployment-uri: string # The Cloud Storage URI of a directory containing trained model artifacts to be used to create the model version. See the [guide to deploying models](/ai-platform/prediction/docs/deploying-models) for more information. The total number of files under this directory must not exceed 1000. During projects.models.versions.create, AI Platform Prediction copies all files from the specified directory to a location managed by the service. From then on, AI Platform Prediction uses these copies of the model artifacts to serve predictions, not the original files in Cloud Storage, so this location is useful only as a historical record. If you specify container, then this field is optional. Otherwise, it is required. Learn [how to use this field with a custom container](/ai-platform/prediction/docs/custom-container-requirements#artifacts).
  --description: string # Optional. The description specified for the version when it was created.
  --error-message: string # Output only. The details of a failure or a cancellation.
  --etag: string # `etag` is used for optimistic concurrency control as a way to help prevent simultaneous updates of a model from overwriting each other. It is strongly suggested that systems make use of the `etag` in the read-modify-write cycle to perform model updates in order to avoid race conditions: An `etag` is returned in the response to `GetVersion`, and systems are expected to put that etag in the request to `UpdateVersion` to ensure that their change will be applied to the model as intended. (format: byte)
  --explanation-config: record # Message holding configuration options for explaining model predictions. There are three feature attribution methods supported for TensorFlow models: integrated gradients, sampled Shapley, and XRAI. [Learn more about feature attributions.](/ai-platform/prediction/docs/ai-explanations/overview) — shape: {integratedGradientsAttribution?: record, sampledShapleyAttribution?: record, xraiAttribution?: record}
  --framework: string@framework-completer # Optional. The machine learning framework AI Platform uses to train this version of the model. Valid values are `TENSORFLOW`, `SCIKIT_LEARN`, `XGBOOST`. If you do not specify a framework, AI Platform will analyze files in the deployment_uri to determine a framework. If you choose `SCIKIT_LEARN` or `XGBOOST`, you must also set the runtime version of the model to 1.4 or greater. Do **not** specify a framework if you're deploying a [custom prediction routine](/ai-platform/prediction/docs/custom-prediction-routines) or if you're using a [custom container](/ai-platform/prediction/docs/use-custom-container).
  --is-default: oneof<nothing, bool> # Output only. If true, this version will be used to handle prediction requests that do not specify a version. You can change the default version by calling projects.methods.versions.setDefault.
  --labels: record # Optional. One or more labels that you can add, to organize your model versions. Each label is a key-value pair, where both the key and the value are arbitrary strings that you supply. For more information, see the documentation on using labels. Note that this field is not updatable for mls1* models.
  --last-use-time: string # Output only. The time the version was last used for prediction. (format: google-datetime)
  --machine-type: string # Optional. The type of machine on which to serve the model. Currently only applies to online prediction service. To learn about valid values for this field, read [Choosing a machine type for online prediction](/ai-platform/prediction/docs/machine-types-online-prediction). If this field is not specified and you are using a [regional endpoint](/ai-platform/prediction/docs/regional-endpoints), then the machine type defaults to `n1-standard-2`. If this field is not specified and you are using the global endpoint (`ml.googleapis.com`), then the machine type defaults to `mls1-c1-m2`.
  --manual-scaling: record # Options for manually scaling a model. — shape: {nodes?: int}
  --name: string # Required. The name specified for the version when it was created. The version name must be unique within the model it is created in.
  --package-uris: list<string> # Optional. Cloud Storage paths (`gs://…`) of packages for [custom prediction routines](/ml-engine/docs/tensorflow/custom-prediction-routines) or [scikit-learn pipelines with custom code](/ml-engine/docs/scikit/exporting-for-prediction#custom-pipeline-code). For a custom prediction routine, one of these packages must contain your Predictor class (see [`predictionClass`](#Version.FIELDS.prediction_class)). Additionally, include any dependencies used by your Predictor or scikit-learn pipeline uses that are not already included in your selected [runtime version](/ml-engine/docs/tensorflow/runtime-version-list). If you specify this field, you must also set [`runtimeVersion`](#Version.FIELDS.runtime_version) to 1.4 or greater.
  --prediction-class: string # Optional. The fully qualified name (module_name.class_name) of a class that implements the Predictor interface described in this reference field. The module containing this class should be included in a package provided to the [`packageUris` field](#Version.FIELDS.package_uris). Specify this field if and only if you are deploying a [custom prediction routine (beta)](/ml-engine/docs/tensorflow/custom-prediction-routines). If you specify this field, you must set [`runtimeVersion`](#Version.FIELDS.runtime_version) to 1.4 or greater and you must set `machineType` to a [legacy (MLS1) machine type](/ml-engine/docs/machine-types-online-prediction). The following code sample provides the Predictor interface: class Predictor(object): """Interface for constructing custom predictors.""" def predict(self, instances, **kwargs): """Performs custom prediction. Instances are the decoded values from the request. They have already been deserialized from JSON. Args: instances: A list of prediction input instances. **kwargs: A dictionary of keyword args provided as additional fields on the predict request body. Returns: A list of outputs containing the prediction results. This list must be JSON serializable. """ raise NotImplementedError() @classmethod def from_path(cls, model_dir): """Creates an instance of Predictor using the given path. Loading of the predictor should be done in this method. Args: model_dir: The local directory that contains the exported model file along with any additional files uploaded when creating the version resource. Returns: An instance implementing this Predictor class. """ raise NotImplementedError() Learn more about [the Predictor interface and custom prediction routines](/ml-engine/docs/tensorflow/custom-prediction-routines).
  --python-version: string # Required. The version of Python used in prediction. The following Python versions are available: * Python '3.7' is available when `runtime_version` is set to '1.15' or later. * Python '3.5' is available when `runtime_version` is set to a version from '1.4' to '1.14'. * Python '2.7' is available when `runtime_version` is set to '1.15' or earlier. Read more about the Python versions available for [each runtime version](/ml-engine/docs/runtime-version-list).
  --request-logging-config: record # Configuration for logging request-response pairs to a BigQuery table. Online prediction requests to a model version and the responses to these requests are converted to raw strings and saved to the specified BigQuery table. Logging is constrained by [BigQuery quotas and limits](/bigquery/quotas). If your project exceeds BigQuery quotas or limits, AI Platform Prediction does not log request-response pairs, but it continues to serve predictions. If you are using [continuous evaluation](/ml-engine/docs/continuous-evaluation/), you do not need to specify this configuration manually. Setting up continuous evaluation automatically enables logging of request-response pairs. — shape: {bigqueryTableName?: string, samplingPercentage?: float}
  --routes: record # Specifies HTTP paths served by a custom container. AI Platform Prediction sends requests to these paths on the container; the custom container must run an HTTP server that responds to these requests with appropriate responses. Read [Custom container requirements](/ai-platform/prediction/docs/custom-container-requirements) for details on how to create your container image to meet these requirements. — shape: {health?: string, predict?: string}
  --runtime-version: string # Required. The AI Platform runtime version to use for this deployment. For more information, see the [runtime version list](/ml-engine/docs/runtime-version-list) and [how to manage runtime versions](/ml-engine/docs/versioning).
  --service-account: string # Optional. Specifies the service account for resource access control. If you specify this field, then you must also specify either the `containerSpec` or the `predictionClass` field. Learn more about [using a custom service account](/ai-platform/prediction/docs/custom-service-account).
  --state: string@state-completer # Output only. The state of a version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/versions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceleratorConfig, var: accelerator_config}, {name: autoScaling, var: auto_scaling}, {name: container, var: container}, {name: createTime, var: create_time}, {name: deploymentUri, var: deployment_uri}, {name: description, var: description}, {name: errorMessage, var: error_message}, {name: etag, var: etag}, {name: explanationConfig, var: explanation_config}, {name: framework, var: framework}, {name: isDefault, var: is_default}, {name: labels, var: labels}, {name: lastUseTime, var: last_use_time}, {name: machineType, var: machine_type}, {name: manualScaling, var: manual_scaling}, {name: name, var: name}, {name: packageUris, var: package_uris}, {name: predictionClass, var: prediction_class}, {name: pythonVersion, var: python_version}, {name: requestLoggingConfig, var: request_logging_config}, {name: routes, var: routes}, {name: runtimeVersion, var: runtime_version}, {name: serviceAccount, var: service_account}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, accelerator_config: $accelerator_config, auto_scaling: $auto_scaling, container: $container, create_time: $create_time, deployment_uri: $deployment_uri, description: $description, error_message: $error_message, etag: $etag, explanation_config: $explanation_config, framework: $framework, is_default: $is_default, labels: $labels, last_use_time: $last_use_time, machine_type: $machine_type, manual_scaling: $manual_scaling, name: $name, package_uris: $package_uris, prediction_class: $prediction_class, python_version: $python_version, request_logging_config: $request_logging_config, routes: $routes, runtime_version: $runtime_version, service_account: $service_account, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# GET /v1/{resource}:getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: ml.projects.models.getIamPolicy
export def "ml-projects-models-get-iam-policy" [
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
  --options-requested-policy-version: int # Optional. The maximum policy version that will be used to format the policy. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional role bindings must specify version 3. Policies with no conditional role bindings may specify any valid value or leave the field unset. The policy in the response might use the policy version that you specified, or it might use a lower policy version. For example, if you specify version 3, but the policy has no conditional role bindings, the response uses version 1. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{resource}:getIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "options.requestedPolicyVersion", var: options_requested_policy_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, options_requested_policy_version: $options_requested_policy_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`, and `PERMISSION_DENIED` errors.
#
# POST /v1/{resource}:setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: ml.projects.models.setIamPolicy
export def "ml-projects-models-set-iam-policy" [
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
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resource}:setIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}, {name: updateMask, var: update_mask}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, policy: $policy, update_mask: $update_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: ml.projects.models.testIamPermissions
export def "ml-projects-models-test-iam-permissions" [
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
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
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
