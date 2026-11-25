# Auto-generated client for Cloud AutoML API v1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/automl/v1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_AUTOML_API_TOKEN

const CLIENT = {
  base_url: "https://automl.googleapis.com"
  token_env_var: "CLOUD_AUTOML_API_TOKEN"
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

def base-url-completer [] { ["https://automl.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def deployment-state-completer [] { ["DEPLOYED" "DEPLOYMENT_STATE_UNSPECIFIED" "UNDEPLOYED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    automl-projects-locations-operations-delete: "record"
    automl-projects-locations-operations-get: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-datasets-table-specs-column-specs-patch: "record<dataStats: record<arrayStats: record<memberStats: any>, categoryStats: record<topCategoryStats: list>, distinctValueCount: string, float64Stats: record<histogramBuckets: list, mean: float, quantiles: list, standardDeviation: float>, nullValueCount: string, stringStats: record<topUnigramStats: list>, structStats: record<fieldStats: record>, timestampStats: record<granularStats: record>, validValueCount: string>, dataType: record<listElementType: any, nullable: bool, structType: record<fields: record>, timeFormat: string, typeCode: string>, displayName: string, etag: string, name: string, topCorrelatedColumns: table<columnSpecId: string, correlationStats: record>>"
    automl-projects-locations-list: "record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>"
    automl-projects-locations-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    automl-projects-locations-models-batch-predict: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-operations-cancel: "record"
    automl-projects-locations-models-deploy: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-models-export: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-datasets-export-data: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-models-export-evaluated-examples: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-datasets-import-data: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-models-predict: "record<metadata: record, payload: table<annotationSpecId: string, classification: record, displayName: string, imageObjectDetection: record, tables: record, textExtraction: record, textSentiment: record, translation: record, videoClassification: record, videoObjectTracking: record>, preprocessedInput: record<document: record<documentDimensions: record, documentText: record, inputConfig: record, layout: list, pageCount: int>, image: record<imageBytes: string, inputConfig: record, thumbnailUri: string>, row: record<columnSpecIds: list, values: list>, textSnippet: record<content: string, contentUri: string, mimeType: string>>>"
    automl-projects-locations-models-undeploy: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-operations-wait: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-datasets-table-specs-column-specs-list: "record<columnSpecs: table<dataStats: record, dataType: record, displayName: string, etag: string, name: string, topCorrelatedColumns: list>, nextPageToken: string>"
    automl-projects-locations-datasets-list: "record<datasets: table<createTime: string, description: string, displayName: string, etag: string, exampleCount: int, imageClassificationDatasetMetadata: record, imageObjectDetectionDatasetMetadata: record, name: string, tablesDatasetMetadata: record, textClassificationDatasetMetadata: record, textExtractionDatasetMetadata: record, textSentimentDatasetMetadata: record, translationDatasetMetadata: record, videoClassificationDatasetMetadata: record, videoObjectTrackingDatasetMetadata: record>, nextPageToken: string>"
    automl-projects-locations-datasets-create: "record<createTime: string, description: string, displayName: string, etag: string, exampleCount: int, imageClassificationDatasetMetadata: record<classificationType: string>, imageObjectDetectionDatasetMetadata: record, name: string, tablesDatasetMetadata: record<mlUseColumnSpecId: string, primaryTableSpecId: string, statsUpdateTime: string, targetColumnCorrelations: record, targetColumnSpecId: string, weightColumnSpecId: string>, textClassificationDatasetMetadata: record<classificationType: string>, textExtractionDatasetMetadata: record, textSentimentDatasetMetadata: record<sentimentMax: int>, translationDatasetMetadata: record<sourceLanguageCode: string, targetLanguageCode: string>, videoClassificationDatasetMetadata: record, videoObjectTrackingDatasetMetadata: record>"
    automl-projects-locations-models-model-evaluations-list: "record<modelEvaluation: table<annotationSpecId: string, classificationEvaluationMetrics: record, createTime: string, displayName: string, evaluatedExampleCount: int, imageObjectDetectionEvaluationMetrics: record, name: string, regressionEvaluationMetrics: record, textExtractionEvaluationMetrics: record, textSentimentEvaluationMetrics: record, translationEvaluationMetrics: record, videoObjectTrackingEvaluationMetrics: record>, nextPageToken: string>"
    automl-projects-locations-models-list: "record<model: table<createTime: string, datasetId: string, deploymentState: string, displayName: string, imageClassificationModelMetadata: record, imageObjectDetectionModelMetadata: record, name: string, tablesModelMetadata: record, textClassificationModelMetadata: record, textExtractionModelMetadata: record, textSentimentModelMetadata: record, trainExampleCount: int, translationModelMetadata: record, updateTime: string, validateExampleCount: int, videoClassificationModelMetadata: record, videoObjectTrackingModelMetadata: record>, nextPageToken: string>"
    automl-projects-locations-models-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    automl-projects-locations-datasets-table-specs-list: "record<nextPageToken: string, tableSpecs: table<columnCount: string, etag: string, inputConfigs: list, name: string, rowCount: string, timeColumnSpecId: string, validRowCount: string>>"
    automl-projects-locations-models-get-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    automl-projects-locations-models-set-iam-policy: "record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    automl-projects-locations-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["automl-projects-locations-operations-delete" "automl-projects-locations-operations-get" "automl-projects-locations-datasets-table-specs-column-specs-patch" "automl-projects-locations-list" "automl-projects-locations-operations-list" "automl-projects-locations-models-batch-predict" "automl-projects-locations-operations-cancel" "automl-projects-locations-models-deploy" "automl-projects-locations-models-export" "automl-projects-locations-datasets-export-data" "automl-projects-locations-models-export-evaluated-examples" "automl-projects-locations-datasets-import-data" "automl-projects-locations-models-predict" "automl-projects-locations-models-undeploy" "automl-projects-locations-operations-wait" "automl-projects-locations-datasets-table-specs-column-specs-list" "automl-projects-locations-datasets-list" "automl-projects-locations-datasets-create" "automl-projects-locations-models-model-evaluations-list" "automl-projects-locations-models-list" "automl-projects-locations-models-create" "automl-projects-locations-datasets-table-specs-list" "automl-projects-locations-models-get-iam-policy" "automl-projects-locations-models-set-iam-policy" "automl-projects-locations-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Deletes a long-running operation. This method indicates that the client is no longer interested in the operation result. It does not cancel the operation. If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`.
#
# DELETE /v1beta1/{name}
# Returns: record
# operationId: automl.projects.locations.operations.delete
export def "automl-projects-locations-operations-delete" [
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
    path: "/v1beta1/{name}"
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
# GET /v1beta1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.operations.get
export def "automl-projects-locations-operations-get" [
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
  --field-mask: string # Mask specifying which fields to read.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fieldMask, var: field_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, field_mask: $field_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a column spec.
#
# PATCH /v1beta1/{name}
# Returns: record<dataStats: record<arrayStats: record<memberStats: any>, categoryStats: record<topCategoryStats: list>, distinctValueCount: string, float64Stats: record<histogramBuckets: list, mean: float, quantiles: list, standardDeviation: float>, nullValueCount: string, stringStats: record<topUnigramStats: list>, structStats: record<fieldStats: record>, timestampStats: record<granularStats: record>, validValueCount: string>, dataType: record<listElementType: any, nullable: bool, structType: record<fields: record>, timeFormat: string, typeCode: string>, displayName: string, etag: string, name: string, topCorrelatedColumns: table<columnSpecId: string, correlationStats: record>>
# operationId: automl.projects.locations.datasets.tableSpecs.columnSpecs.patch
export def "automl-projects-locations-datasets-table-specs-column-specs-patch" [
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
  --update-mask: string # The update mask applies to the resource.
  --data-stats: record # The data statistics of a series of values that share the same DataType. — shape: {arrayStats?: record, categoryStats?: record, distinctValueCount?: string, float64Stats?: record, nullValueCount?: string, stringStats?: record, structStats?: record, timestampStats?: record, validValueCount?: string}
  --data-type: record # Indicated the type of data that can be stored in a structured data entity (e.g. a table). — shape: {listElementType?: record, nullable?: bool, structType?: record, timeFormat?: string, typeCode?: "TYPE_CODE_UNSPECIFIED"|"FLOAT64"|"TIMESTAMP"|"STRING"|"ARRAY"|"STRUCT"|"CATEGORY"}
  --display-name: string # Output only. The name of the column to show in the interface. The name can be up to 100 characters long and can consist only of ASCII Latin letters A-Z and a-z, ASCII digits 0-9, underscores(_), and forward slashes(/), and must start with a letter or a digit.
  --etag: string # Used to perform consistent read-modify-write updates. If not set, a blind "overwrite" update happens.
  --body-name: string # Output only. The resource name of the column specs. Form: `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/tableSpecs/{table_spec_id}/columnSpecs/{column_spec_id}` (spec name: name)
  --top-correlated-columns: list # Deprecated. — item shape: {columnSpecId?: string, correlationStats?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataStats, var: data_stats}, {name: dataType, var: data_type}, {name: displayName, var: display_name}, {name: etag, var: etag}, {name: name, var: body_name}, {name: topCorrelatedColumns, var: top_correlated_columns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, data_stats: $data_stats, data_type: $data_type, display_name: $display_name, etag: $etag, body_name: $body_name, top_correlated_columns: $top_correlated_columns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about the supported locations for this service.
#
# GET /v1beta1/{name}/locations
# Returns: record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>
# operationId: automl.projects.locations.list
export def "automl-projects-locations-list" [
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
  --filter: string # A filter to narrow down results to a preferred subset. The filtering language accepts strings like `"displayName=tokyo"`, and is documented in more detail in [AIP-160](https://google.aip.dev/160).
  --page-size: int # The maximum number of results to return. If not set, the service selects a default.
  --page-token: string # A page token received from the `next_page_token` field in the response. Send that page token to receive the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/locations"
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

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v1beta1/{name}/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: automl.projects.locations.operations.list
export def "automl-projects-locations-operations-list" [
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
  --filter: string # An expression for filtering the results of the request. * `operation_id` - for = or !=. * `done` - for = or !=. * `works_on` - for = or !=. Some examples of using the filter are: * `done=true` --> The operation has finished running. * `works_on = projects/my-project/locations/us-central1/datasets/5` --> The operation works on a dataset with ID 5. * `works_on = projects/my-project/locations/us-central1/models/15` --> The operation works on a model with ID 15.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/operations"
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

# Perform a batch prediction. Unlike the online Predict, batch prediction result won't be immediately available in the response. Instead, a long running operation object is returned. User can poll the operation result via GetOperation method. Once the operation is done, BatchPredictResult is returned in the response field. Available for following ML problems: * Image Classification * Image Object Detection * Video Classification * Video Object Tracking * Text Extraction * Tables
#
# POST /v1beta1/{name}:batchPredict
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.models.batchPredict
export def "automl-projects-locations-models-batch-predict" [
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
  --input-config: record # Input configuration for BatchPredict Action. The format of input depends on the ML problem of the model used for prediction. As input source the gcs_source is expected, unless specified otherwise. The formats are represented in EBNF with commas being literal and with non-terminal symbols defined near the end of this comment. The formats are: * For Image Classification: CSV file(s) with each line having just a single column: GCS_FILE_PATH which leads to image of up to 30MB in size. Supported extensions: .JPEG, .GIF, .PNG. This path is treated as the ID in the Batch predict output. Three sample rows: gs://folder/image1.jpeg gs://folder/image2.gif gs://folder/image3.png * For Image Object Detection: CSV file(s) with each line having just a single column: GCS_FILE_PATH which leads to image of up to 30MB in size. Supported extensions: .JPEG, .GIF, .PNG. This path is treated as the ID in the Batch predict output. Three sample rows: gs://folder/image1.jpeg gs://folder/image2.gif gs://folder/image3.png * For Video Classification: CSV file(s) with each line in format: GCS_FILE_PATH,TIME_SEGMENT_START,TIME_SEGMENT_END GCS_FILE_PATH leads to video of up to 50GB in size and up to 3h duration. Supported extensions: .MOV, .MPEG4, .MP4, .AVI. TIME_SEGMENT_START and TIME_SEGMENT_END must be within the length of the video, and end has to be after the start. Three sample rows: gs://folder/video1.mp4,10,40 gs://folder/video1.mp4,20,60 gs://folder/vid2.mov,0,inf * For Video Object Tracking: CSV file(s) with each line in format: GCS_FILE_PATH,TIME_SEGMENT_START,TIME_SEGMENT_END GCS_FILE_PATH leads to video of up to 50GB in size and up to 3h duration. Supported extensions: .MOV, .MPEG4, .MP4, .AVI. TIME_SEGMENT_START and TIME_SEGMENT_END must be within the length of the video, and end has to be after the start. Three sample rows: gs://folder/video1.mp4,10,240 gs://folder/video1.mp4,300,360 gs://folder/vid2.mov,0,inf * For Text Classification: CSV file(s) with each line having just a single column: GCS_FILE_PATH | TEXT_SNIPPET Any given text file can have size upto 128kB. Any given text snippet content must have 60,000 characters or less. Three sample rows: gs://folder/text1.txt "Some text content to predict" gs://folder/text3.pdf Supported file extensions: .txt, .pdf * For Text Sentiment: CSV file(s) with each line having just a single column: GCS_FILE_PATH | TEXT_SNIPPET Any given text file can have size upto 128kB. Any given text snippet content must have 500 characters or less. Three sample rows: gs://folder/text1.txt "Some text content to predict" gs://folder/text3.pdf Supported file extensions: .txt, .pdf * For Text Extraction .JSONL (i.e. JSON Lines) file(s) which either provide text in-line or as documents (for a single BatchPredict call only one of the these formats may be used). The in-line .JSONL file(s) contain per line a proto that wraps a temporary user-assigned TextSnippet ID (string up to 2000 characters long) called "id", a TextSnippet proto (in json representation) and zero or more TextFeature protos. Any given text snippet content must have 30,000 characters or less, and also be UTF-8 NFC encoded (ASCII already is). The IDs provided should be unique. The document .JSONL file(s) contain, per line, a proto that wraps a Document proto with input_config set. Only PDF documents are supported now, and each document must be up to 2MB large. Any given .JSONL file must be 100MB or smaller, and no more than 20 files may be given. Sample in-line JSON Lines file (presented here with artificial line breaks, but the only actual line break is denoted by \n): { "id": "my_first_id", "text_snippet": { "content": "dog car cat"}, "text_features": [ { "text_segment": {"start_offset": 4, "end_offset": 6}, "structural_type": PARAGRAPH, "bounding_poly": { "normalized_vertices": [ {"x": 0.1, "y": 0.1}, {"x": 0.1, "y": 0.3}, {"x": 0.3, "y": 0.3}, {"x": 0.3, "y": 0.1}, ] }, } ], }\n { "id": "2", "text_snippet": { "content": "An elaborate content", "mime_type": "text/plain" } } Sample document JSON Lines file (presented here with artificial line breaks, but the only actual line break is denoted by \n).: { "document": { "input_config": { "gcs_source": { "input_uris": [ "gs://folder/document1.pdf" ] } } } }\n { "document": { "input_config": { "gcs_source": { "input_uris": [ "gs://folder/document2.pdf" ] } } } } * For Tables: Either gcs_source or bigquery_source. GCS case: CSV file(s), each by itself 10GB or smaller and total size must be 100GB or smaller, where first file must have a header containing column names. If the first row of a subsequent file is the same as the header, then it is also treated as a header. All other rows contain values for the corresponding columns. The column names must contain the model's input_feature_column_specs' display_name-s (order doesn't matter). The columns corresponding to the model's input feature column specs must contain values compatible with the column spec's data types. Prediction on all the rows, i.e. the CSV lines, will be attempted. For FORECASTING prediction_type: all columns having TIME_SERIES_AVAILABLE_PAST_ONLY type will be ignored. First three sample rows of a CSV file: "First Name","Last Name","Dob","Addresses" "John","Doe","1968-01-22","[{"status":"current","address":"123_First_Avenue","city":"Seattle","state":"WA","zip":"11111","numberOfYears":"1"},{"status":"previous","address":"456_Main_Street","city":"Portland","state":"OR","zip":"22222","numberOfYears":"5"}]" "Jane","Doe","1980-10-16","[{"status":"current","address":"789_Any_Avenue","city":"Albany","state":"NY","zip":"33333","numberOfYears":"2"},{"status":"previous","address":"321_Main_Street","city":"Hoboken","state":"NJ","zip":"44444","numberOfYears":"3"}]} BigQuery case: An URI of a BigQuery table. The user data size of the BigQuery table must be 100GB or smaller. The column names must contain the model's input_feature_column_specs' display_name-s (order doesn't matter). The columns corresponding to the model's input feature column specs must contain values compatible with the column spec's data types. Prediction on all the rows of the table will be attempted. For FORECASTING prediction_type: all columns having TIME_SERIES_AVAILABLE_PAST_ONLY type will be ignored. Definitions: GCS_FILE_PATH = A path to file on GCS, e.g. "gs://folder/video.avi". TEXT_SNIPPET = A content of a text snippet, UTF-8 encoded, enclosed within double quotes ("") TIME_SEGMENT_START = TIME_OFFSET Expresses a beginning, inclusive, of a time segment within an example that has a time dimension (e.g. video). TIME_SEGMENT_END = TIME_OFFSET Expresses an end, exclusive, of a time segment within an example that has a time dimension (e.g. video). TIME_OFFSET = A number of seconds as measured from the start of an example (e.g. video). Fractions are allowed, up to a microsecond precision. "inf" is allowed and it means the end of the example. Errors: If any of the provided CSV files can't be parsed or if more than certain percent of CSV rows cannot be processed then the operation fails and prediction does not happen. Regardless of overall success or failure the per-row failures, up to a certain count cap, will be listed in Operation.metadata.partial_failures. — shape: {bigquerySource?: record, gcsSource?: record}
  --output-config: record # Output configuration for BatchPredict Action. As destination the gcs_destination must be set unless specified otherwise for a domain. If gcs_destination is set then in the given directory a new directory is created. Its name will be "prediction--", where timestamp is in YYYY-MM-DDThh:mm:ss.sssZ ISO-8601 format. The contents of it depends on the ML problem the predictions are made for. * For Image Classification: In the created directory files `image_classification_1.jsonl`, `image_classification_2.jsonl`,...,`image_classification_N.jsonl` will be created, where N may be 1, and depends on the total number of the successfully predicted images and annotations. A single image will be listed only once with all its annotations, and its annotations will never be split across files. Each .JSONL file will contain, per line, a JSON representation of a proto that wraps image's "ID" : "" followed by a list of zero or more AnnotationPayload protos (called annotations), which have classification detail populated. If prediction for any image failed (partially or completely), then an additional `errors_1.jsonl`, `errors_2.jsonl`,..., `errors_N.jsonl` files will be created (N depends on total number of failed predictions). These files will have a JSON representation of a proto that wraps the same "ID" : "" but here followed by exactly one [`google.rpc.Status`](https: //github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) containing only `code` and `message`fields. * For Image Object Detection: In the created directory files `image_object_detection_1.jsonl`, `image_object_detection_2.jsonl`,...,`image_object_detection_N.jsonl` will be created, where N may be 1, and depends on the total number of the successfully predicted images and annotations. Each .JSONL file will contain, per line, a JSON representation of a proto that wraps image's "ID" : "" followed by a list of zero or more AnnotationPayload protos (called annotations), which have image_object_detection detail populated. A single image will be listed only once with all its annotations, and its annotations will never be split across files. If prediction for any image failed (partially or completely), then additional `errors_1.jsonl`, `errors_2.jsonl`,..., `errors_N.jsonl` files will be created (N depends on total number of failed predictions). These files will have a JSON representation of a proto that wraps the same "ID" : "" but here followed by exactly one [`google.rpc.Status`](https: //github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) containing only `code` and `message`fields. * For Video Classification: In the created directory a video_classification.csv file, and a .JSON file per each video classification requested in the input (i.e. each line in given CSV(s)), will be created. The format of video_classification.csv is: GCS_FILE_PATH,TIME_SEGMENT_START,TIME_SEGMENT_END,JSON_FILE_NAME,STATUS where: GCS_FILE_PATH,TIME_SEGMENT_START,TIME_SEGMENT_END = matches 1 to 1 the prediction input lines (i.e. video_classification.csv has precisely the same number of lines as the prediction input had.) JSON_FILE_NAME = Name of .JSON file in the output directory, which contains prediction responses for the video time segment. STATUS = "OK" if prediction completed successfully, or an error code with message otherwise. If STATUS is not "OK" then the .JSON file for that line may not exist or be empty. Each .JSON file, assuming STATUS is "OK", will contain a list of AnnotationPayload protos in JSON format, which are the predictions for the video time segment the file is assigned to in the video_classification.csv. All AnnotationPayload protos will have video_classification field set, and will be sorted by video_classification.type field (note that the returned types are governed by `classifaction_types` parameter in PredictService.BatchPredictRequest.params). * For Video Object Tracking: In the created directory a video_object_tracking.csv file will be created, and multiple files video_object_trackinng_1.json, video_object_trackinng_2.json,..., video_object_trackinng_N.json, where N is the number of requests in the input (i.e. the number of lines in given CSV(s)). The format of video_object_tracking.csv is: GCS_FILE_PATH,TIME_SEGMENT_START,TIME_SEGMENT_END,JSON_FILE_NAME,STATUS where: GCS_FILE_PATH,TIME_SEGMENT_START,TIME_SEGMENT_END = matches 1 to 1 the prediction input lines (i.e. video_object_tracking.csv has precisely the same number of lines as the prediction input had.) JSON_FILE_NAME = Name of .JSON file in the output directory, which contains prediction responses for the video time segment. STATUS = "OK" if prediction completed successfully, or an error code with message otherwise. If STATUS is not "OK" then the .JSON file for that line may not exist or be empty. Each .JSON file, assuming STATUS is "OK", will contain a list of AnnotationPayload protos in JSON format, which are the predictions for each frame of the video time segment the file is assigned to in video_object_tracking.csv. All AnnotationPayload protos will have video_object_tracking field set. * For Text Classification: In the created directory files `text_classification_1.jsonl`, `text_classification_2.jsonl`,...,`text_classification_N.jsonl` will be created, where N may be 1, and depends on the total number of inputs and annotations found. Each .JSONL file will contain, per line, a JSON representation of a proto that wraps input text snippet or input text file and a list of zero or more AnnotationPayload protos (called annotations), which have classification detail populated. A single text snippet or file will be listed only once with all its annotations, and its annotations will never be split across files. If prediction for any text snippet or file failed (partially or completely), then additional `errors_1.jsonl`, `errors_2.jsonl`,..., `errors_N.jsonl` files will be created (N depends on total number of failed predictions). These files will have a JSON representation of a proto that wraps input text snippet or input text file followed by exactly one [`google.rpc.Status`](https: //github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) containing only `code` and `message`. * For Text Sentiment: In the created directory files `text_sentiment_1.jsonl`, `text_sentiment_2.jsonl`,...,`text_sentiment_N.jsonl` will be created, where N may be 1, and depends on the total number of inputs and annotations found. Each .JSONL file will contain, per line, a JSON representation of a proto that wraps input text snippet or input text file and a list of zero or more AnnotationPayload protos (called annotations), which have text_sentiment detail populated. A single text snippet or file will be listed only once with all its annotations, and its annotations will never be split across files. If prediction for any text snippet or file failed (partially or completely), then additional `errors_1.jsonl`, `errors_2.jsonl`,..., `errors_N.jsonl` files will be created (N depends on total number of failed predictions). These files will have a JSON representation of a proto that wraps input text snippet or input text file followed by exactly one [`google.rpc.Status`](https: //github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) containing only `code` and `message`. * For Text Extraction: In the created directory files `text_extraction_1.jsonl`, `text_extraction_2.jsonl`,...,`text_extraction_N.jsonl` will be created, where N may be 1, and depends on the total number of inputs and annotations found. The contents of these .JSONL file(s) depend on whether the input used inline text, or documents. If input was inline, then each .JSONL file will contain, per line, a JSON representation of a proto that wraps given in request text snippet's "id" (if specified), followed by input text snippet, and a list of zero or more AnnotationPayload protos (called annotations), which have text_extraction detail populated. A single text snippet will be listed only once with all its annotations, and its annotations will never be split across files. If input used documents, then each .JSONL file will contain, per line, a JSON representation of a proto that wraps given in request document proto, followed by its OCR-ed representation in the form of a text snippet, finally followed by a list of zero or more AnnotationPayload protos (called annotations), which have text_extraction detail populated and refer, via their indices, to the OCR-ed text snippet. A single document (and its text snippet) will be listed only once with all its annotations, and its annotations will never be split across files. If prediction for any text snippet failed (partially or completely), then additional `errors_1.jsonl`, `errors_2.jsonl`,..., `errors_N.jsonl` files will be created (N depends on total number of failed predictions). These files will have a JSON representation of a proto that wraps either the "id" : "" (in case of inline) or the document proto (in case of document) but here followed by exactly one [`google.rpc.Status`](https: //github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) containing only `code` and `message`. * For Tables: Output depends on whether gcs_destination or bigquery_destination is set (either is allowed). GCS case: In the created directory files `tables_1.csv`, `tables_2.csv`,..., `tables_N.csv` will be created, where N may be 1, and depends on the total number of the successfully predicted rows. For all CLASSIFICATION prediction_type-s: Each .csv file will contain a header, listing all columns' display_name-s given on input followed by M target column names in the format of "__score" where M is the number of distinct target values, i.e. number of distinct values in the target column of the table used to train the model. Subsequent lines will contain the respective values of successfully predicted rows, with the last, i.e. the target, columns having the corresponding prediction scores. For REGRESSION and FORECASTING prediction_type-s: Each .csv file will contain a header, listing all columns' display_name-s given on input followed by the predicted target column with name in the format of "predicted_" Subsequent lines will contain the respective values of successfully predicted rows, with the last, i.e. the target, column having the predicted target value. If prediction for any rows failed, then an additional `errors_1.csv`, `errors_2.csv`,..., `errors_N.csv` will be created (N depends on total number of failed rows). These files will have analogous format as `tables_*.csv`, but always with a single target column having [`google.rpc.Status`](https: //github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) represented as a JSON string, and containing only `code` and `message`. BigQuery case: bigquery_destination pointing to a BigQuery project must be set. In the given project a new dataset will be created with name `prediction__` where will be made BigQuery-dataset-name compatible (e.g. most special characters will become underscores), and timestamp will be in YYYY_MM_DDThh_mm_ss_sssZ "based on ISO-8601" format. In the dataset two tables will be created, `predictions`, and `errors`. The `predictions` table's column names will be the input columns' display_name-s followed by the target column with name in the format of "predicted_" The input feature columns will contain the respective values of successfully predicted rows, with the target column having an ARRAY of AnnotationPayloads, represented as STRUCT-s, containing TablesAnnotation. The `errors` table contains rows for which the prediction has failed, it has analogous input columns while the target column name is in the format of "errors_", and as a value has [`google.rpc.Status`](https: //github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) represented as a STRUCT, and containing only `code` and `message`. — shape: {bigqueryDestination?: record, gcsDestination?: record}
  --params: record # Required. Additional domain-specific parameters for the predictions, any string must be up to 25000 characters long. * For Text Classification: `score_threshold` - (float) A value from 0.0 to 1.0. When the model makes predictions for a text snippet, it will only produce results that have at least this confidence score. The default is 0.5. * For Image Classification: `score_threshold` - (float) A value from 0.0 to 1.0. When the model makes predictions for an image, it will only produce results that have at least this confidence score. The default is 0.5. * For Image Object Detection: `score_threshold` - (float) When Model detects objects on the image, it will only produce bounding boxes which have at least this confidence score. Value in 0 to 1 range, default is 0.5. `max_bounding_box_count` - (int64) No more than this number of bounding boxes will be produced per image. Default is 100, the requested value may be limited by server. * For Video Classification : `score_threshold` - (float) A value from 0.0 to 1.0. When the model makes predictions for a video, it will only produce results that have at least this confidence score. The default is 0.5. `segment_classification` - (boolean) Set to true to request segment-level classification. AutoML Video Intelligence returns labels and their confidence scores for the entire segment of the video that user specified in the request configuration. The default is "true". `shot_classification` - (boolean) Set to true to request shot-level classification. AutoML Video Intelligence determines the boundaries for each camera shot in the entire segment of the video that user specified in the request configuration. AutoML Video Intelligence then returns labels and their confidence scores for each detected shot, along with the start and end time of the shot. WARNING: Model evaluation is not done for this classification type, the quality of it depends on training data, but there are no metrics provided to describe that quality. The default is "false". `1s_interval_classification` - (boolean) Set to true to request classification for a video at one-second intervals. AutoML Video Intelligence returns labels and their confidence scores for each second of the entire segment of the video that user specified in the request configuration. WARNING: Model evaluation is not done for this classification type, the quality of it depends on training data, but there are no metrics provided to describe that quality. The default is "false". * For Tables: feature_importance - (boolean) Whether feature importance should be populated in the returned TablesAnnotations. The default is false. * For Video Object Tracking: `score_threshold` - (float) When Model detects objects on video frames, it will only produce bounding boxes which have at least this confidence score. Value in 0 to 1 range, default is 0.5. `max_bounding_box_count` - (int64) No more than this number of bounding boxes will be returned per frame. Default is 100, the requested value may be limited by server. `min_bounding_box_size` - (float) Only bounding boxes with shortest edge at least that long as a relative value of video frame size will be returned. Value in 0 to 1 range. Default is 0.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:batchPredict"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: inputConfig, var: input_config}, {name: outputConfig, var: output_config}, {name: params, var: params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, input_config: $input_config, output_config: $output_config, params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
#
# POST /v1beta1/{name}:cancel
# Returns: record
# operationId: automl.projects.locations.operations.cancel
export def "automl-projects-locations-operations-cancel" [
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
    path: "/v1beta1/{name}:cancel"
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

# Deploys a model. If a model is already deployed, deploying it with the same parameters has no effect. Deploying with different parametrs (as e.g. changing node_number) will reset the deployment state without pausing the model's availability. Only applicable for Text Classification, Image Object Detection , Tables, and Image Segmentation; all other domains manage deployment automatically. Returns an empty response in the response field when it completes.
#
# POST /v1beta1/{name}:deploy
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.models.deploy
export def "automl-projects-locations-models-deploy" [
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
  --image-classification-model-deployment-metadata: record # Model deployment metadata specific to Image Classification. — shape: {nodeCount?: string}
  --image-object-detection-model-deployment-metadata: record # Model deployment metadata specific to Image Object Detection. — shape: {nodeCount?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:deploy"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageClassificationModelDeploymentMetadata, var: image_classification_model_deployment_metadata}, {name: imageObjectDetectionModelDeploymentMetadata, var: image_object_detection_model_deployment_metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, image_classification_model_deployment_metadata: $image_classification_model_deployment_metadata, image_object_detection_model_deployment_metadata: $image_object_detection_model_deployment_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports a trained, "export-able", model to a user specified Google Cloud Storage location. A model is considered export-able if and only if it has an export format defined for it in ModelExportOutputConfig. Returns an empty response in the response field when it completes.
#
# POST /v1beta1/{name}:export
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.models.export
export def "automl-projects-locations-models-export" [
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
  --output-config: record # Output configuration for ModelExport Action. — shape: {gcrDestination?: record, gcsDestination?: record, modelFormat?: string, params?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:export"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: outputConfig, var: output_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, output_config: $output_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports dataset's data to the provided output location. Returns an empty response in the response field when it completes.
#
# POST /v1beta1/{name}:exportData
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.datasets.exportData
export def "automl-projects-locations-datasets-export-data" [
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
  --output-config: record # * For Translation: CSV file `translation.csv`, with each line in format: ML_USE,GCS_FILE_PATH GCS_FILE_PATH leads to a .TSV file which describes examples that have given ML_USE, using the following row format per line: TEXT_SNIPPET (in source language) \t TEXT_SNIPPET (in target language) * For Tables: Output depends on whether the dataset was imported from GCS or BigQuery. GCS case: gcs_destination must be set. Exported are CSV file(s) `tables_1.csv`, `tables_2.csv`,...,`tables_N.csv` with each having as header line the table's column names, and all other lines contain values for the header columns. BigQuery case: bigquery_destination pointing to a BigQuery project must be set. In the given project a new dataset will be created with name `export_data__` where will be made BigQuery-dataset-name compatible (e.g. most special characters will become underscores), and timestamp will be in YYYY_MM_DDThh_mm_ss_sssZ "based on ISO-8601" format. In that dataset a new table called `primary_table` will be created, and filled with precisely the same data as this obtained on import. — shape: {bigqueryDestination?: record, gcsDestination?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:exportData"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: outputConfig, var: output_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, output_config: $output_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports examples on which the model was evaluated (i.e. which were in the TEST set of the dataset the model was created from), together with their ground truth annotations and the annotations created (predicted) by the model. The examples, ground truth and predictions are exported in the state they were at the moment the model was evaluated. This export is available only for 30 days since the model evaluation is created. Currently only available for Tables. Returns an empty response in the response field when it completes.
#
# POST /v1beta1/{name}:exportEvaluatedExamples
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.models.exportEvaluatedExamples
export def "automl-projects-locations-models-export-evaluated-examples" [
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
  --output-config: record # Output configuration for ExportEvaluatedExamples Action. Note that this call is available only for 30 days since the moment the model was evaluated. The output depends on the domain, as follows (note that only examples from the TEST set are exported): * For Tables: bigquery_destination pointing to a BigQuery project must be set. In the given project a new dataset will be created with name `export_evaluated_examples__` where will be made BigQuery-dataset-name compatible (e.g. most special characters will become underscores), and timestamp will be in YYYY_MM_DDThh_mm_ss_sssZ "based on ISO-8601" format. In the dataset an `evaluated_examples` table will be created. It will have all the same columns as the primary_table of the dataset from which the model was created, as they were at the moment of model's evaluation (this includes the target column with its ground truth), followed by a column called "predicted_". That last column will contain the model's prediction result for each respective row, given as ARRAY of AnnotationPayloads, represented as STRUCT-s, containing TablesAnnotation. — shape: {bigqueryDestination?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:exportEvaluatedExamples"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: outputConfig, var: output_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, output_config: $output_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports data into a dataset. For Tables this method can only be called on an empty Dataset. For Tables: * A schema_inference_version parameter must be explicitly set. Returns an empty response in the response field when it completes.
#
# POST /v1beta1/{name}:importData
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.datasets.importData
export def "automl-projects-locations-datasets-import-data" [
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
  --input-config: record # Input configuration for ImportData Action. The format of input depends on dataset_metadata the Dataset into which the import is happening has. As input source the gcs_source is expected, unless specified otherwise. Additionally any input .CSV file by itself must be 100MB or smaller, unless specified otherwise. If an "example" file (that is, image, video etc.) with identical content (even if it had different GCS_FILE_PATH) is mentioned multiple times, then its label, bounding boxes etc. are appended. The same file should be always provided with the same ML_USE and GCS_FILE_PATH, if it is not, then these values are nondeterministically selected from the given ones. The formats are represented in EBNF with commas being literal and with non-terminal symbols defined near the end of this comment. The formats are: * For Image Classification: CSV file(s) with each line in format: ML_USE,GCS_FILE_PATH,LABEL,LABEL,... GCS_FILE_PATH leads to image of up to 30MB in size. Supported extensions: .JPEG, .GIF, .PNG, .WEBP, .BMP, .TIFF, .ICO For MULTICLASS classification type, at most one LABEL is allowed per image. If an image has not yet been labeled, then it should be mentioned just once with no LABEL. Some sample rows: TRAIN,gs://folder/image1.jpg,daisy TEST,gs://folder/image2.jpg,dandelion,tulip,rose UNASSIGNED,gs://folder/image3.jpg,daisy UNASSIGNED,gs://folder/image4.jpg * For Image Object Detection: CSV file(s) with each line in format: ML_USE,GCS_FILE_PATH,(LABEL,BOUNDING_BOX | ,,,,,,,) GCS_FILE_PATH leads to image of up to 30MB in size. Supported extensions: .JPEG, .GIF, .PNG. Each image is assumed to be exhaustively labeled. The minimum allowed BOUNDING_BOX edge length is 0.01, and no more than 500 BOUNDING_BOX-es per image are allowed (one BOUNDING_BOX is defined per line). If an image has not yet been labeled, then it should be mentioned just once with no LABEL and the ",,,,,,," in place of the BOUNDING_BOX. For images which are known to not contain any bounding boxes, they should be labelled explictly as "NEGATIVE_IMAGE", followed by ",,,,,,," in place of the BOUNDING_BOX. Sample rows: TRAIN,gs://folder/image1.png,car,0.1,0.1,,,0.3,0.3,, TRAIN,gs://folder/image1.png,bike,.7,.6,,,.8,.9,, UNASSIGNED,gs://folder/im2.png,car,0.1,0.1,0.2,0.1,0.2,0.3,0.1,0.3 TEST,gs://folder/im3.png,,,,,,,,, TRAIN,gs://folder/im4.png,NEGATIVE_IMAGE,,,,,,,,, * For Video Classification: CSV file(s) with each line in format: ML_USE,GCS_FILE_PATH where ML_USE VALIDATE value should not be used. The GCS_FILE_PATH should lead to another .csv file which describes examples that have given ML_USE, using the following row format: GCS_FILE_PATH,(LABEL,TIME_SEGMENT_START,TIME_SEGMENT_END | ,,) Here GCS_FILE_PATH leads to a video of up to 50GB in size and up to 3h duration. Supported extensions: .MOV, .MPEG4, .MP4, .AVI. TIME_SEGMENT_START and TIME_SEGMENT_END must be within the length of the video, and end has to be after the start. Any segment of a video which has one or more labels on it, is considered a hard negative for all other labels. Any segment with no labels on it is considered to be unknown. If a whole video is unknown, then it shuold be mentioned just once with ",," in place of LABEL, TIME_SEGMENT_START,TIME_SEGMENT_END. Sample top level CSV file: TRAIN,gs://folder/train_videos.csv TEST,gs://folder/test_videos.csv UNASSIGNED,gs://folder/other_videos.csv Sample rows of a CSV file for a particular ML_USE: gs://folder/video1.avi,car,120,180.000021 gs://folder/video1.avi,bike,150,180.000021 gs://folder/vid2.avi,car,0,60.5 gs://folder/vid3.avi,,, * For Video Object Tracking: CSV file(s) with each line in format: ML_USE,GCS_FILE_PATH where ML_USE VALIDATE value should not be used. The GCS_FILE_PATH should lead to another .csv file which describes examples that have given ML_USE, using one of the following row format: GCS_FILE_PATH,LABEL,[INSTANCE_ID],TIMESTAMP,BOUNDING_BOX or GCS_FILE_PATH,,,,,,,,,, Here GCS_FILE_PATH leads to a video of up to 50GB in size and up to 3h duration. Supported extensions: .MOV, .MPEG4, .MP4, .AVI. Providing INSTANCE_IDs can help to obtain a better model. When a specific labeled entity leaves the video frame, and shows up afterwards it is not required, albeit preferable, that the same INSTANCE_ID is given to it. TIMESTAMP must be within the length of the video, the BOUNDING_BOX is assumed to be drawn on the closest video's frame to the TIMESTAMP. Any mentioned by the TIMESTAMP frame is expected to be exhaustively labeled and no more than 500 BOUNDING_BOX-es per frame are allowed. If a whole video is unknown, then it should be mentioned just once with ",,,,,,,,,," in place of LABEL, [INSTANCE_ID],TIMESTAMP,BOUNDING_BOX. Sample top level CSV file: TRAIN,gs://folder/train_videos.csv TEST,gs://folder/test_videos.csv UNASSIGNED,gs://folder/other_videos.csv Seven sample rows of a CSV file for a particular ML_USE: gs://folder/video1.avi,car,1,12.10,0.8,0.8,0.9,0.8,0.9,0.9,0.8,0.9 gs://folder/video1.avi,car,1,12.90,0.4,0.8,0.5,0.8,0.5,0.9,0.4,0.9 gs://folder/video1.avi,car,2,12.10,.4,.2,.5,.2,.5,.3,.4,.3 gs://folder/video1.avi,car,2,12.90,.8,.2,,,.9,.3,, gs://folder/video1.avi,bike,,12.50,.45,.45,,,.55,.55,, gs://folder/video2.avi,car,1,0,.1,.9,,,.9,.1,, gs://folder/video2.avi,,,,,,,,,,, * For Text Extraction: CSV file(s) with each line in format: ML_USE,GCS_FILE_PATH GCS_FILE_PATH leads to a .JSONL (that is, JSON Lines) file which either imports text in-line or as documents. Any given .JSONL file must be 100MB or smaller. The in-line .JSONL file contains, per line, a proto that wraps a TextSnippet proto (in json representation) followed by one or more AnnotationPayload protos (called annotations), which have display_name and text_extraction detail populated. The given text is expected to be annotated exhaustively, for example, if you look for animals and text contains "dolphin" that is not labeled, then "dolphin" is assumed to not be an animal. Any given text snippet content must be 10KB or smaller, and also be UTF-8 NFC encoded (ASCII already is). The document .JSONL file contains, per line, a proto that wraps a Document proto. The Document proto must have either document_text or input_config set. In document_text case, the Document proto may also contain the spatial information of the document, including layout, document dimension and page number. In input_config case, only PDF documents are supported now, and each document may be up to 2MB large. Currently, annotations on documents cannot be specified at import. Three sample CSV rows: TRAIN,gs://folder/file1.jsonl VALIDATE,gs://folder/file2.jsonl TEST,gs://folder/file3.jsonl Sample in-line JSON Lines file for entity extraction (presented here with artificial line breaks, but the only actual line break is denoted by \n).: { "document": { "document_text": {"content": "dog cat"} "layout": [ { "text_segment": { "start_offset": 0, "end_offset": 3, }, "page_number": 1, "bounding_poly": { "normalized_vertices": [ {"x": 0.1, "y": 0.1}, {"x": 0.1, "y": 0.3}, {"x": 0.3, "y": 0.3}, {"x": 0.3, "y": 0.1}, ], }, "text_segment_type": TOKEN, }, { "text_segment": { "start_offset": 4, "end_offset": 7, }, "page_number": 1, "bounding_poly": { "normalized_vertices": [ {"x": 0.4, "y": 0.1}, {"x": 0.4, "y": 0.3}, {"x": 0.8, "y": 0.3}, {"x": 0.8, "y": 0.1}, ], }, "text_segment_type": TOKEN, } ], "document_dimensions": { "width": 8.27, "height": 11.69, "unit": INCH, } "page_count": 1, }, "annotations": [ { "display_name": "animal", "text_extraction": {"text_segment": {"start_offset": 0, "end_offset": 3}} }, { "display_name": "animal", "text_extraction": {"text_segment": {"start_offset": 4, "end_offset": 7}} } ], }\n { "text_snippet": { "content": "This dog is good." }, "annotations": [ { "display_name": "animal", "text_extraction": { "text_segment": {"start_offset": 5, "end_offset": 8} } } ] } Sample document JSON Lines file (presented here with artificial line breaks, but the only actual line break is denoted by \n).: { "document": { "input_config": { "gcs_source": { "input_uris": [ "gs://folder/document1.pdf" ] } } } }\n { "document": { "input_config": { "gcs_source": { "input_uris": [ "gs://folder/document2.pdf" ] } } } } * For Text Classification: CSV file(s) with each line in format: ML_USE,(TEXT_SNIPPET | GCS_FILE_PATH),LABEL,LABEL,... TEXT_SNIPPET and GCS_FILE_PATH are distinguished by a pattern. If the column content is a valid gcs file path, i.e. prefixed by "gs://", it will be treated as a GCS_FILE_PATH, else if the content is enclosed within double quotes (""), it is treated as a TEXT_SNIPPET. In the GCS_FILE_PATH case, the path must lead to a .txt file with UTF-8 encoding, for example, "gs://folder/content.txt", and the content in it is extracted as a text snippet. In TEXT_SNIPPET case, the column content excluding quotes is treated as to be imported text snippet. In both cases, the text snippet/file size must be within 128kB. Maximum 100 unique labels are allowed per CSV row. Sample rows: TRAIN,"They have bad food and very rude",RudeService,BadFood TRAIN,gs://folder/content.txt,SlowService TEST,"Typically always bad service there.",RudeService VALIDATE,"Stomach ache to go.",BadFood * For Text Sentiment: CSV file(s) with each line in format: ML_USE,(TEXT_SNIPPET | GCS_FILE_PATH),SENTIMENT TEXT_SNIPPET and GCS_FILE_PATH are distinguished by a pattern. If the column content is a valid gcs file path, that is, prefixed by "gs://", it is treated as a GCS_FILE_PATH, otherwise it is treated as a TEXT_SNIPPET. In the GCS_FILE_PATH case, the path must lead to a .txt file with UTF-8 encoding, for example, "gs://folder/content.txt", and the content in it is extracted as a text snippet. In TEXT_SNIPPET case, the column content itself is treated as to be imported text snippet. In both cases, the text snippet must be up to 500 characters long. Sample rows: TRAIN,"@freewrytin this is way too good for your product",2 TRAIN,"I need this product so bad",3 TEST,"Thank you for this product.",4 VALIDATE,gs://folder/content.txt,2 * For Tables: Either gcs_source or bigquery_source can be used. All inputs is concatenated into a single primary_table For gcs_source: CSV file(s), where the first row of the first file is the header, containing unique column names. If the first row of a subsequent file is the same as the header, then it is also treated as a header. All other rows contain values for the corresponding columns. Each .CSV file by itself must be 10GB or smaller, and their total size must be 100GB or smaller. First three sample rows of a CSV file: "Id","First Name","Last Name","Dob","Addresses" "1","John","Doe","1968-01-22","[{"status":"current","address":"123_First_Avenue","city":"Seattle","state":"WA","zip":"11111","numberOfYears":"1"},{"status":"previous","address":"456_Main_Street","city":"Portland","state":"OR","zip":"22222","numberOfYears":"5"}]" "2","Jane","Doe","1980-10-16","[{"status":"current","address":"789_Any_Avenue","city":"Albany","state":"NY","zip":"33333","numberOfYears":"2"},{"status":"previous","address":"321_Main_Street","city":"Hoboken","state":"NJ","zip":"44444","numberOfYears":"3"}]} For bigquery_source: An URI of a BigQuery table. The user data size of the BigQuery table must be 100GB or smaller. An imported table must have between 2 and 1,000 columns, inclusive, and between 1000 and 100,000,000 rows, inclusive. There are at most 5 import data running in parallel. Definitions: ML_USE = "TRAIN" | "VALIDATE" | "TEST" | "UNASSIGNED" Describes how the given example (file) should be used for model training. "UNASSIGNED" can be used when user has no preference. GCS_FILE_PATH = A path to file on GCS, e.g. "gs://folder/image1.png". LABEL = A display name of an object on an image, video etc., e.g. "dog". Must be up to 32 characters long and can consist only of ASCII Latin letters A-Z and a-z, underscores(_), and ASCII digits 0-9. For each label an AnnotationSpec is created which display_name becomes the label; AnnotationSpecs are given back in predictions. INSTANCE_ID = A positive integer that identifies a specific instance of a labeled entity on an example. Used e.g. to track two cars on a video while being able to tell apart which one is which. BOUNDING_BOX = VERTEX,VERTEX,VERTEX,VERTEX | VERTEX,,,VERTEX,, A rectangle parallel to the frame of the example (image, video). If 4 vertices are given they are connected by edges in the order provided, if 2 are given they are recognized as diagonally opposite vertices of the rectangle. VERTEX = COORDINATE,COORDINATE First coordinate is horizontal (x), the second is vertical (y). COORDINATE = A float in 0 to 1 range, relative to total length of image or video in given dimension. For fractions the leading non-decimal 0 can be omitted (i.e. 0.3 = .3). Point 0,0 is in top left. TIME_SEGMENT_START = TIME_OFFSET Expresses a beginning, inclusive, of a time segment within an example that has a time dimension (e.g. video). TIME_SEGMENT_END = TIME_OFFSET Expresses an end, exclusive, of a time segment within an example that has a time dimension (e.g. video). TIME_OFFSET = A number of seconds as measured from the start of an example (e.g. video). Fractions are allowed, up to a microsecond precision. "inf" is allowed, and it means the end of the example. TEXT_SNIPPET = A content of a text snippet, UTF-8 encoded, enclosed within double quotes (""). SENTIMENT = An integer between 0 and Dataset.text_sentiment_dataset_metadata.sentiment_max (inclusive). Describes the ordinal of the sentiment - higher value means a more positive sentiment. All the values are completely relative, i.e. neither 0 needs to mean a negative or neutral sentiment nor sentiment_max needs to mean a positive one - it is just required that 0 is the least positive sentiment in the data, and sentiment_max is the most positive one. The SENTIMENT shouldn't be confused with "score" or "magnitude" from the previous Natural Language Sentiment Analysis API. All SENTIMENT values between 0 and sentiment_max must be represented in the imported data. On prediction the same 0 to sentiment_max range will be used. The difference between neighboring sentiment values needs not to be uniform, e.g. 1 and 2 may be similar whereas the difference between 2 and 3 may be huge. Errors: If any of the provided CSV files can't be parsed or if more than certain percent of CSV rows cannot be processed then the operation fails and nothing is imported. Regardless of overall success or failure the per-row failures, up to a certain count cap, is listed in Operation.metadata.partial_failures. — shape: {bigquerySource?: record, gcsSource?: record, params?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:importData"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: inputConfig, var: input_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, input_config: $input_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform an online prediction. The prediction result will be directly returned in the response. Available for following ML problems, and their expected request payloads: * Image Classification - Image in .JPEG, .GIF or .PNG format, image_bytes up to 30MB. * Image Object Detection - Image in .JPEG, .GIF or .PNG format, image_bytes up to 30MB. * Text Classification - TextSnippet, content up to 60,000 characters, UTF-8 encoded. * Text Extraction - TextSnippet, content up to 30,000 characters, UTF-8 NFC encoded. * Translation - TextSnippet, content up to 25,000 characters, UTF-8 encoded. * Tables - Row, with column values matching the columns of the model, up to 5MB. Not available for FORECASTING prediction_type. * Text Sentiment - TextSnippet, content up 500 characters, UTF-8 encoded.
#
# POST /v1beta1/{name}:predict
# Returns: record<metadata: record, payload: table<annotationSpecId: string, classification: record, displayName: string, imageObjectDetection: record, tables: record, textExtraction: record, textSentiment: record, translation: record, videoClassification: record, videoObjectTracking: record>, preprocessedInput: record<document: record<documentDimensions: record, documentText: record, inputConfig: record, layout: list, pageCount: int>, image: record<imageBytes: string, inputConfig: record, thumbnailUri: string>, row: record<columnSpecIds: list, values: list>, textSnippet: record<content: string, contentUri: string, mimeType: string>>>
# operationId: automl.projects.locations.models.predict
export def "automl-projects-locations-models-predict" [
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
  --params: record # Additional domain-specific parameters, any string must be up to 25000 characters long. * For Image Classification: `score_threshold` - (float) A value from 0.0 to 1.0. When the model makes predictions for an image, it will only produce results that have at least this confidence score. The default is 0.5. * For Image Object Detection: `score_threshold` - (float) When Model detects objects on the image, it will only produce bounding boxes which have at least this confidence score. Value in 0 to 1 range, default is 0.5. `max_bounding_box_count` - (int64) No more than this number of bounding boxes will be returned in the response. Default is 100, the requested value may be limited by server. * For Tables: feature_importance - (boolean) Whether feature importance should be populated in the returned TablesAnnotation. The default is false.
  --payload: record # Example data used for training or prediction. — shape: {document?: record, image?: record, row?: record, textSnippet?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:predict"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: params, var: params}, {name: payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, params: $params, payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undeploys a model. If the model is not deployed this method has no effect. Only applicable for Text Classification, Image Object Detection and Tables; all other domains manage deployment automatically. Returns an empty response in the response field when it completes.
#
# POST /v1beta1/{name}:undeploy
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.models.undeploy
export def "automl-projects-locations-models-undeploy" [
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
    path: "/v1beta1/{name}:undeploy"
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

# Waits until the specified long-running operation is done or reaches at most a specified timeout, returning the latest state. If the operation is already done, the latest state is immediately returned. If the timeout specified is greater than the default HTTP/RPC timeout, the HTTP/RPC timeout is used. If the server does not support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Note that this method is on a best-effort basis. It may return the latest state before the specified timeout (including immediately), meaning even an immediate response is no guarantee that the operation is done.
#
# POST /v1beta1/{name}:wait
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.operations.wait
export def "automl-projects-locations-operations-wait" [
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
  --timeout: string # The maximum duration to wait before timing out. If left blank, the wait will be at most the time permitted by the underlying HTTP/RPC protocol. If RPC context deadline is also specified, the shorter one will be used. (format: google-duration)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:wait"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: timeout, var: timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists column specs in a table spec.
#
# GET /v1beta1/{parent}/columnSpecs
# Returns: record<columnSpecs: table<dataStats: record, dataType: record, displayName: string, etag: string, name: string, topCorrelatedColumns: list>, nextPageToken: string>
# operationId: automl.projects.locations.datasets.tableSpecs.columnSpecs.list
export def "automl-projects-locations-datasets-table-specs-column-specs-list" [
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
  --field-mask: string # Mask specifying which fields to read.
  --filter: string # Filter expression, see go/filtering.
  --page-size: int # Requested page size. The server can return fewer results than requested. If unspecified, the server will pick a default size.
  --page-token: string # A token identifying a page of results for the server to return. Typically obtained from the ListColumnSpecsResponse.next_page_token field of the previous AutoMl.ListColumnSpecs call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/columnSpecs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fieldMask, var: field_mask}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, field_mask: $field_mask, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists datasets in a project.
#
# GET /v1beta1/{parent}/datasets
# Returns: record<datasets: table<createTime: string, description: string, displayName: string, etag: string, exampleCount: int, imageClassificationDatasetMetadata: record, imageObjectDetectionDatasetMetadata: record, name: string, tablesDatasetMetadata: record, textClassificationDatasetMetadata: record, textExtractionDatasetMetadata: record, textSentimentDatasetMetadata: record, translationDatasetMetadata: record, videoClassificationDatasetMetadata: record, videoObjectTrackingDatasetMetadata: record>, nextPageToken: string>
# operationId: automl.projects.locations.datasets.list
export def "automl-projects-locations-datasets-list" [
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
  --filter: string # An expression for filtering the results of the request. * `dataset_metadata` - for existence of the case (e.g. `image_classification_dataset_metadata:*`). Some examples of using the filter are: * `translation_dataset_metadata:*` --> The dataset has `translation_dataset_metadata`.
  --page-size: int # Requested page size. Server may return fewer results than requested. If unspecified, server will pick a default size.
  --page-token: string # A token identifying a page of results for the server to return Typically obtained via ListDatasetsResponse.next_page_token of the previous AutoMl.ListDatasets call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/datasets"
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

# Creates a dataset.
#
# POST /v1beta1/{parent}/datasets
# Returns: record<createTime: string, description: string, displayName: string, etag: string, exampleCount: int, imageClassificationDatasetMetadata: record<classificationType: string>, imageObjectDetectionDatasetMetadata: record, name: string, tablesDatasetMetadata: record<mlUseColumnSpecId: string, primaryTableSpecId: string, statsUpdateTime: string, targetColumnCorrelations: record, targetColumnSpecId: string, weightColumnSpecId: string>, textClassificationDatasetMetadata: record<classificationType: string>, textExtractionDatasetMetadata: record, textSentimentDatasetMetadata: record<sentimentMax: int>, translationDatasetMetadata: record<sourceLanguageCode: string, targetLanguageCode: string>, videoClassificationDatasetMetadata: record, videoObjectTrackingDatasetMetadata: record>
# operationId: automl.projects.locations.datasets.create
export def "automl-projects-locations-datasets-create" [
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
  --create-time: string # Output only. Timestamp when this dataset was created. (format: google-datetime)
  --description: string # User-provided description of the dataset. The description can be up to 25000 characters long.
  --display-name: string # Required. The name of the dataset to show in the interface. The name can be up to 32 characters long and can consist only of ASCII Latin letters A-Z and a-z, underscores (_), and ASCII digits 0-9.
  --etag: string # Used to perform consistent read-modify-write updates. If not set, a blind "overwrite" update happens.
  --example-count: int # Output only. The number of examples in the dataset. (format: int32)
  --image-classification-dataset-metadata: record # Dataset metadata that is specific to image classification. — shape: {classificationType?: "CLASSIFICATION_TYPE_UNSPECIFIED"|"MULTICLASS"|"MULTILABEL"}
  --image-object-detection-dataset-metadata: record # Dataset metadata specific to image object detection.
  --name: string # Output only. The resource name of the dataset. Form: `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}`
  --tables-dataset-metadata: record # Metadata for a dataset used for AutoML Tables. — shape: {mlUseColumnSpecId?: string, primaryTableSpecId?: string, statsUpdateTime?: string, targetColumnCorrelations?: record, targetColumnSpecId?: string, weightColumnSpecId?: string}
  --text-classification-dataset-metadata: record # Dataset metadata for classification. — shape: {classificationType?: "CLASSIFICATION_TYPE_UNSPECIFIED"|"MULTICLASS"|"MULTILABEL"}
  --text-extraction-dataset-metadata: record # Dataset metadata that is specific to text extraction
  --text-sentiment-dataset-metadata: record # Dataset metadata for text sentiment. — shape: {sentimentMax?: int}
  --translation-dataset-metadata: record # Dataset metadata that is specific to translation. — shape: {sourceLanguageCode?: string, targetLanguageCode?: string}
  --video-classification-dataset-metadata: record # Dataset metadata specific to video classification. All Video Classification datasets are treated as multi label.
  --video-object-tracking-dataset-metadata: record # Dataset metadata specific to video object tracking.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/datasets"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: createTime, var: create_time}, {name: description, var: description}, {name: displayName, var: display_name}, {name: etag, var: etag}, {name: exampleCount, var: example_count}, {name: imageClassificationDatasetMetadata, var: image_classification_dataset_metadata}, {name: imageObjectDetectionDatasetMetadata, var: image_object_detection_dataset_metadata}, {name: name, var: name}, {name: tablesDatasetMetadata, var: tables_dataset_metadata}, {name: textClassificationDatasetMetadata, var: text_classification_dataset_metadata}, {name: textExtractionDatasetMetadata, var: text_extraction_dataset_metadata}, {name: textSentimentDatasetMetadata, var: text_sentiment_dataset_metadata}, {name: translationDatasetMetadata, var: translation_dataset_metadata}, {name: videoClassificationDatasetMetadata, var: video_classification_dataset_metadata}, {name: videoObjectTrackingDatasetMetadata, var: video_object_tracking_dataset_metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, create_time: $create_time, description: $description, display_name: $display_name, etag: $etag, example_count: $example_count, image_classification_dataset_metadata: $image_classification_dataset_metadata, image_object_detection_dataset_metadata: $image_object_detection_dataset_metadata, name: $name, tables_dataset_metadata: $tables_dataset_metadata, text_classification_dataset_metadata: $text_classification_dataset_metadata, text_extraction_dataset_metadata: $text_extraction_dataset_metadata, text_sentiment_dataset_metadata: $text_sentiment_dataset_metadata, translation_dataset_metadata: $translation_dataset_metadata, video_classification_dataset_metadata: $video_classification_dataset_metadata, video_object_tracking_dataset_metadata: $video_object_tracking_dataset_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists model evaluations.
#
# GET /v1beta1/{parent}/modelEvaluations
# Returns: record<modelEvaluation: table<annotationSpecId: string, classificationEvaluationMetrics: record, createTime: string, displayName: string, evaluatedExampleCount: int, imageObjectDetectionEvaluationMetrics: record, name: string, regressionEvaluationMetrics: record, textExtractionEvaluationMetrics: record, textSentimentEvaluationMetrics: record, translationEvaluationMetrics: record, videoObjectTrackingEvaluationMetrics: record>, nextPageToken: string>
# operationId: automl.projects.locations.models.modelEvaluations.list
export def "automl-projects-locations-models-model-evaluations-list" [
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
  --filter: string # An expression for filtering the results of the request. * `annotation_spec_id` - for =, != or existence. See example below for the last. Some examples of using the filter are: * `annotation_spec_id!=4` --> The model evaluation was done for annotation spec with ID different than 4. * `NOT annotation_spec_id:*` --> The model evaluation was done for aggregate of all annotation specs.
  --page-size: int # Requested page size.
  --page-token: string # A token identifying a page of results for the server to return. Typically obtained via ListModelEvaluationsResponse.next_page_token of the previous AutoMl.ListModelEvaluations call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/modelEvaluations"
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

# Lists models.
#
# GET /v1beta1/{parent}/models
# Returns: record<model: table<createTime: string, datasetId: string, deploymentState: string, displayName: string, imageClassificationModelMetadata: record, imageObjectDetectionModelMetadata: record, name: string, tablesModelMetadata: record, textClassificationModelMetadata: record, textExtractionModelMetadata: record, textSentimentModelMetadata: record, trainExampleCount: int, translationModelMetadata: record, updateTime: string, validateExampleCount: int, videoClassificationModelMetadata: record, videoObjectTrackingModelMetadata: record>, nextPageToken: string>
# operationId: automl.projects.locations.models.list
export def "automl-projects-locations-models-list" [
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
  --filter: string # An expression for filtering the results of the request. * `model_metadata` - for existence of the case (e.g. `video_classification_model_metadata:*`). * `dataset_id` - for = or !=. Some examples of using the filter are: * `image_classification_model_metadata:*` --> The model has `image_classification_model_metadata`. * `dataset_id=5` --> The model was created from a dataset with ID 5.
  --page-size: int # Requested page size.
  --page-token: string # A token identifying a page of results for the server to return Typically obtained via ListModelsResponse.next_page_token of the previous AutoMl.ListModels call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/models"
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

# Creates a model. Returns a Model in the response field when it completes. When you create a model, several model evaluations are created for it: a global evaluation, and one evaluation for each annotation spec.
#
# POST /v1beta1/{parent}/models
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: automl.projects.locations.models.create
export def "automl-projects-locations-models-create" [
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
  --create-time: string # Output only. Timestamp when the model training finished and can be used for prediction. (format: google-datetime)
  --dataset-id: string # Required. The resource ID of the dataset used to create the model. The dataset must come from the same ancestor project and location.
  --deployment-state: string@deployment-state-completer # Output only. Deployment state of the model. A model can only serve prediction requests after it gets deployed.
  --display-name: string # Required. The name of the model to show in the interface. The name can be up to 32 characters long and can consist only of ASCII Latin letters A-Z and a-z, underscores (_), and ASCII digits 0-9. It must start with a letter.
  --image-classification-model-metadata: record # Model metadata for image classification. — shape: {baseModelId?: string, modelType?: string, nodeCount?: string, nodeQps?: float, stopReason?: string, trainBudget?: string, trainCost?: string}
  --image-object-detection-model-metadata: record # Model metadata specific to image object detection. — shape: {modelType?: string, nodeCount?: string, nodeQps?: float, stopReason?: string, trainBudgetMilliNodeHours?: string, trainCostMilliNodeHours?: string}
  --name: string # Output only. Resource name of the model. Format: `projects/{project_id}/locations/{location_id}/models/{model_id}`
  --tables-model-metadata: record # Model metadata specific to AutoML Tables. — shape: {disableEarlyStopping?: bool, inputFeatureColumnSpecs?: list, optimizationObjective?: string, optimizationObjectivePrecisionValue?: float, optimizationObjectiveRecallValue?: float, tablesModelColumnInfo?: list, targetColumnSpec?: record, trainBudgetMilliNodeHours?: string, trainCostMilliNodeHours?: string}
  --text-classification-model-metadata: record # Model metadata that is specific to text classification. — shape: {classificationType?: "CLASSIFICATION_TYPE_UNSPECIFIED"|"MULTICLASS"|"MULTILABEL"}
  --text-extraction-model-metadata: record # Model metadata that is specific to text extraction. — shape: {modelHint?: string}
  --text-sentiment-model-metadata: record # Model metadata that is specific to text sentiment.
  --translation-model-metadata: record # Model metadata that is specific to translation. — shape: {baseModel?: string, sourceLanguageCode?: string, targetLanguageCode?: string}
  --update-time: string # Output only. Timestamp when this model was last updated. (format: google-datetime)
  --video-classification-model-metadata: record # Model metadata specific to video classification.
  --video-object-tracking-model-metadata: record # Model metadata specific to video object tracking.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/models"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: createTime, var: create_time}, {name: datasetId, var: dataset_id}, {name: deploymentState, var: deployment_state}, {name: displayName, var: display_name}, {name: imageClassificationModelMetadata, var: image_classification_model_metadata}, {name: imageObjectDetectionModelMetadata, var: image_object_detection_model_metadata}, {name: name, var: name}, {name: tablesModelMetadata, var: tables_model_metadata}, {name: textClassificationModelMetadata, var: text_classification_model_metadata}, {name: textExtractionModelMetadata, var: text_extraction_model_metadata}, {name: textSentimentModelMetadata, var: text_sentiment_model_metadata}, {name: translationModelMetadata, var: translation_model_metadata}, {name: updateTime, var: update_time}, {name: videoClassificationModelMetadata, var: video_classification_model_metadata}, {name: videoObjectTrackingModelMetadata, var: video_object_tracking_model_metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, create_time: $create_time, dataset_id: $dataset_id, deployment_state: $deployment_state, display_name: $display_name, image_classification_model_metadata: $image_classification_model_metadata, image_object_detection_model_metadata: $image_object_detection_model_metadata, name: $name, tables_model_metadata: $tables_model_metadata, text_classification_model_metadata: $text_classification_model_metadata, text_extraction_model_metadata: $text_extraction_model_metadata, text_sentiment_model_metadata: $text_sentiment_model_metadata, translation_model_metadata: $translation_model_metadata, update_time: $update_time, video_classification_model_metadata: $video_classification_model_metadata, video_object_tracking_model_metadata: $video_object_tracking_model_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists table specs in a dataset.
#
# GET /v1beta1/{parent}/tableSpecs
# Returns: record<nextPageToken: string, tableSpecs: table<columnCount: string, etag: string, inputConfigs: list, name: string, rowCount: string, timeColumnSpecId: string, validRowCount: string>>
# operationId: automl.projects.locations.datasets.tableSpecs.list
export def "automl-projects-locations-datasets-table-specs-list" [
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
  --field-mask: string # Mask specifying which fields to read.
  --filter: string # Filter expression, see go/filtering.
  --page-size: int # Requested page size. The server can return fewer results than requested. If unspecified, the server will pick a default size.
  --page-token: string # A token identifying a page of results for the server to return. Typically obtained from the ListTableSpecsResponse.next_page_token field of the previous AutoMl.ListTableSpecs call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/tableSpecs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fieldMask, var: field_mask}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, field_mask: $field_mask, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# GET /v1beta1/{resource}:getIamPolicy
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: automl.projects.locations.models.getIamPolicy
export def "automl-projects-locations-models-get-iam-policy" [
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
    path: "/v1beta1/{resource}:getIamPolicy"
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
# POST /v1beta1/{resource}:setIamPolicy
# Returns: record<bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: automl.projects.locations.models.setIamPolicy
export def "automl-projects-locations-models-set-iam-policy" [
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
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {bindings?: list, etag?: string, version?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{resource}:setIamPolicy"
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

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1beta1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: automl.projects.locations.testIamPermissions
export def "automl-projects-locations-test-iam-permissions" [
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
    path: "/v1beta1/{resource}:testIamPermissions"
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
