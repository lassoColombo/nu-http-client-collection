# Auto-generated client for Big Red Cloud API v1
# Source: https://api.apis.guru/v2/specs/bigredcloud.com/v1/openapi.json
# Auth: --token flag or $env.BIG_RED_CLOUD_API_TOKEN

const CLIENT = {
  base_url: "https://app.bigredcloud.com/api"
  token_env_var: "BIG_RED_CLOUD_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://app.bigredcloud.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accounts-get: "record<Count: int, Items: table<accountGroup: string, accountType: string, code: string, description: string, id: int>, NextPageLink: string>"
    analysis-categories-get: "record<Count: int, Items: table<accountCode: string, accountId: int, categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string>"
    bank-accounts-get: "record<Count: int, Items: table<acCode: string, accountName: string, accountNumber: string, address: list, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, sortCode: string, timestamp: string>, NextPageLink: string>"
    bank-accounts-post: "record"
    bank-accounts-process-batch: "record"
    bank-accounts-delete: "record"
    get-v1-bank-accounts-id: "record<acCode: string, accountName: string, accountNumber: string, address: list<string>, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, oBalance: float, sortCode: string, timestamp: string>"
    bank-accounts-put: "record"
    book-tran-types-get: "record<Count: int, Items: table<code: string, description: string, id: int>, NextPageLink: string>"
    cash-payments-get: "record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float, unallocated: float>, NextPageLink: string>"
    cash-payments-post: "record"
    cash-payments-process-batch: "record"
    cash-payments-delete: "record"
    get-v1-cash-payments-id: "record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float>"
    cash-payments-put: "record"
    cash-receipts-get: "record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>"
    cash-receipts-post: "record"
    cash-receipts-process-batch: "record"
    cash-receipts-delete: "record"
    get-v1-cash-receipts-id: "record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int>"
    cash-receipts-put: "record"
    category-types-get: "record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>"
    company-settings-get: "record<Count: int, Items: table<enableVOCRReporting: bool, id: int, useAllocations: bool, value: string, vocrSettingValue: bool>, NextPageLink: string>"
    company-setup-config-get: "record<financialYear: record<firstMonth: int, startMonth: int, startYear: int>, generalDetails: record<companyAddresses: list<string>, companyName: string, currencyCode: string, currencyDescription: string, currencyId: int, currentcySymbol: string, emails: list<string>, faxes: list<string>, phones: list<string>, regionDescription: string, regionId: int, vatReg: string>, options: record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool>, referenceSettings: record<creditorsJournal: bool, debtorsJournal: bool, purchases: bool, sales: bool>>"
    company-setup-config-get-company-options: "record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool>"
    company-setup-config-get-financial-year: "record<firstMonth: int, startMonth: int, startYear: int>"
    customers-get: "record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, delivery: list, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string>"
    customers-post: "record"
    customers-process-batch: "record"
    customers-delete: "record"
    get-v1-customers-id: "record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, delivery: list<string>, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>"
    customers-put: "record"
    customers-get-account-trans: "table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string>"
    customers-get-opening-balance: "record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>"
    customers-get-opening-balance-list: "table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>>"
    customers-get-quotes: "table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list<record>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list<record>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>"
    email-send-email-statement: "record"
    email-send-quote: "record"
    email-send-sales-invoice: "record"
    owner-type-groups-get: "record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>"
    owner-types-get: "record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string>"
    payments-get: "record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float>, NextPageLink: string>"
    payments-post: "record"
    payments-process-batch: "record"
    payments-delete: "record"
    get-v1-payments-id: "record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float>"
    payments-put: "record"
    product-types-get: "record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string>"
    products-get: "record<Count: int, Items: table<details: list, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int>, NextPageLink: string>"
    products-post: "record"
    products-process-batch: "record"
    products-delete: "record"
    get-v1-products-id: "record<details: list<string>, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int>"
    products-put: "record"
    purchases-get: "record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, detailCollection: list, entryDate: string, id: int, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>"
    purchases-post: "record"
    purchases-process-batch: "record"
    purchases-delete: "record"
    get-v1-purchases-id: "record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, entryDate: string, id: int, isDiscrepancyAccepted: bool, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int>"
    purchases-put: "record"
    quote-get: "record<Count: int, Items: table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>, NextPageLink: string>"
    quote-post: "record"
    quote-process-batch: "record"
    quote-close: "record"
    quote-post-create-quote-with-generating-reference: "record"
    quote-post-generate-sale-invoice: "record"
    quote-reopen: "record"
    quote-delete: "record"
    get-v1-quotes-id: "record<acCode: string, closedDate: string, comments: string, companyId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: table<acEntries: list, amount: float, companyId: int, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vatAmount: float, vatAnalysisTypeId: int, vatRateId: int>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>"
    quote-put: "record"
    sales-get: "record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, details: string, entryDate: string, id: int, loType: string, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>"
    sales-credit-notes-get: "record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string>"
    sales-credit-notes-post: "record"
    sales-credit-notes-process-batch: "record"
    sales-credit-notes-delete: "record"
    get-v1-sales-credit-notes-id: "record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>"
    sales-credit-notes-put: "record"
    sales-entries-get: "record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>"
    sales-entries-post: "record"
    sales-entries-process-batch: "record"
    sales-entries-delete: "record"
    get-v1-sales-entries-id: "record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int>"
    sales-entries-put: "record"
    sales-invoices-get: "record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string>"
    sales-invoices-post: "record"
    sales-invoices-process-batch: "record"
    sales-invoices-post-create-sale-invoice-with-generating-reference: "record"
    sales-invoices-delete: "record"
    get-v1-sales-invoices-id: "record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>"
    sales-invoices-put: "record"
    sales-rep-get: "record<Count: int, Items: table<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string>, NextPageLink: string>"
    sales-rep-post: "record"
    sales-rep-process-batch: "record"
    sales-rep-delete: "record"
    get-v1-sales-reps-id: "record<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string>"
    sales-rep-put: "record"
    suppliers-get: "record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string>"
    suppliers-post: "record"
    suppliers-process-batch: "record"
    suppliers-delete: "record"
    get-v1-suppliers-id: "record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>"
    suppliers-put: "record"
    suppliers-get-account-trans: "table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string>"
    suppliers-get-opening-balance: "record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>"
    suppliers-get-opening-balance-list: "table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>>"
    user-defined-fields-get: "record<Count: int, Items: table<categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string>"
    vat-analysis-types-get: "record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>"
    vat-categories-get: "record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>"
    vat-categories-process-vat-rates: "record"
    vat-rates-get: "record<Count: int, Items: table<id: int, isActive: bool, isDefault: bool, orderIndex: int, percentage: float, timestamp: string, vatCategoryId: int>, NextPageLink: string>"
    vat-types-get: "record<Count: int, Items: table<code: string, description: string, id: int, isNotApplicable: bool, isOnlyZero: bool>, NextPageLink: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accounts-get" "analysis-categories-get" "bank-accounts-get" "bank-accounts-post" "bank-accounts-process-batch" "bank-accounts-delete" "get-v1-bank-accounts-id" "bank-accounts-put" "book-tran-types-get" "cash-payments-get" "cash-payments-post" "cash-payments-process-batch" "cash-payments-delete" "get-v1-cash-payments-id" "cash-payments-put" "cash-receipts-get" "cash-receipts-post" "cash-receipts-process-batch" "cash-receipts-delete" "get-v1-cash-receipts-id" "cash-receipts-put" "category-types-get" "company-settings-get" "company-setup-config-get" "company-setup-config-get-company-options" "company-setup-config-get-financial-year" "customers-get" "customers-post" "customers-process-batch" "customers-delete" "get-v1-customers-id" "customers-put" "customers-get-account-trans" "customers-get-opening-balance" "customers-get-opening-balance-list" "customers-get-quotes" "email-send-email-statement" "email-send-quote" "email-send-sales-invoice" "owner-type-groups-get" "owner-types-get" "payments-get" "payments-post" "payments-process-batch" "payments-delete" "get-v1-payments-id" "payments-put" "product-types-get" "products-get" "products-post" "products-process-batch" "products-delete" "get-v1-products-id" "products-put" "purchases-get" "purchases-post" "purchases-process-batch" "purchases-delete" "get-v1-purchases-id" "purchases-put" "quote-get" "quote-post" "quote-process-batch" "quote-close" "quote-post-create-quote-with-generating-reference" "quote-post-generate-sale-invoice" "quote-reopen" "quote-delete" "get-v1-quotes-id" "quote-put" "sales-get" "sales-credit-notes-get" "sales-credit-notes-post" "sales-credit-notes-process-batch" "sales-credit-notes-delete" "get-v1-sales-credit-notes-id" "sales-credit-notes-put" "sales-entries-get" "sales-entries-post" "sales-entries-process-batch" "sales-entries-delete" "get-v1-sales-entries-id" "sales-entries-put" "sales-invoices-get" "sales-invoices-post" "sales-invoices-process-batch" "sales-invoices-post-create-sale-invoice-with-generating-reference" "sales-invoices-delete" "get-v1-sales-invoices-id" "sales-invoices-put" "sales-rep-get" "sales-rep-post" "sales-rep-process-batch" "sales-rep-delete" "get-v1-sales-reps-id" "sales-rep-put" "suppliers-get" "suppliers-post" "suppliers-process-batch" "suppliers-delete" "get-v1-suppliers-id" "suppliers-put" "suppliers-get-account-trans" "suppliers-get-opening-balance" "suppliers-get-opening-balance-list" "user-defined-fields-get" "vat-analysis-types-get" "vat-categories-get" "vat-categories-process-vat-rates" "vat-rates-get" "vat-types-get" "commands"] | sort) } | get name | first)
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

# Returns a list of company's Accounts. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/accounts
# Returns: record<Count: int, Items: table<accountGroup: string, accountType: string, code: string, description: string, id: int>, NextPageLink: string>
# operationId: Accounts_Get
export def "accounts-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Analysis Categories. Supports OData querying protocol. Filtering is allowed by "categoryTypeId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/analysisCategories
# Returns: record<Count: int, Items: table<accountCode: string, accountId: int, categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string>
# operationId: AnalysisCategories_Get
export def "analysis-categories-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/analysisCategories"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Bank Account. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "acCode" fields.
#
# GET /v1/bankAccounts
# Returns: record<Count: int, Items: table<acCode: string, accountName: string, accountNumber: string, address: list, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, sortCode: string, timestamp: string>, NextPageLink: string>
# operationId: BankAccounts_Get
export def "bank-accounts-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bankAccounts"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Bank Account.
#
# POST /v1/bankAccounts
# Returns: record
# operationId: BankAccounts_Post
export def "bank-accounts-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --account-name: string
  --account-number: string
  --address: list<string>
  --bank-feed-source: int # format: int32
  --business-identifier-codes: string
  --category-id: int # format: int64
  --creditor-scheme: string
  --details: string
  --id: int # format: int64
  --international-bank-account-number: string
  --is-default-bank: oneof<nothing, bool>
  --last-chq: string
  --nominal-ac-code: string
  --o-balance: float # format: double
  --sort-code: string
  --timestamp: string # format: byte
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/bankAccounts"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: address, var: address}, {name: bankFeedSource, var: bank_feed_source}, {name: businessIdentifierCodes, var: business_identifier_codes}, {name: categoryId, var: category_id}, {name: creditorScheme, var: creditor_scheme}, {name: details, var: details}, {name: id, var: id}, {name: internationalBankAccountNumber, var: international_bank_account_number}, {name: isDefaultBank, var: is_default_bank}, {name: lastChq, var: last_chq}, {name: nominalAcCode, var: nominal_ac_code}, {name: oBalance, var: o_balance}, {name: sortCode, var: sort_code}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, account_name: $account_name, account_number: $account_number, address: $address, bank_feed_source: $bank_feed_source, business_identifier_codes: $business_identifier_codes, category_id: $category_id, creditor_scheme: $creditor_scheme, details: $details, id: $id, international_bank_account_number: $international_bank_account_number, is_default_bank: $is_default_bank, last_chq: $last_chq, nominal_ac_code: $nominal_ac_code, o_balance: $o_balance, sort_code: $sort_code, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Bank Accounts.
#
# PUT /v1/bankAccounts/batch
# Returns: record
# operationId: BankAccounts_ProcessBatch
export def "bank-accounts-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/bankAccounts/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Bank Account.
#
# DELETE /v1/bankAccounts/{id}
# Returns: record
# operationId: BankAccounts_Delete
export def "bank-accounts-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Bank Account to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/bankAccounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Bank Account.
#
# GET /v1/bankAccounts/{id}
# Returns: record<acCode: string, accountName: string, accountNumber: string, address: list<string>, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, oBalance: float, sortCode: string, timestamp: string>
export def "get-v1-bank-accounts-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bankAccounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Bank Account.
#
# PUT /v1/bankAccounts/{id}
# Returns: record
# operationId: BankAccounts_Put
export def "bank-accounts-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --account-name: string
  --account-number: string
  --address: list<string>
  --bank-feed-source: int # format: int32
  --business-identifier-codes: string
  --category-id: int # format: int64
  --creditor-scheme: string
  --details: string
  --body-id: int # format: int64 (spec name: id)
  --international-bank-account-number: string
  --is-default-bank: oneof<nothing, bool>
  --last-chq: string
  --nominal-ac-code: string
  --o-balance: float # format: double
  --sort-code: string
  --timestamp: string # format: byte
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/bankAccounts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: address, var: address}, {name: bankFeedSource, var: bank_feed_source}, {name: businessIdentifierCodes, var: business_identifier_codes}, {name: categoryId, var: category_id}, {name: creditorScheme, var: creditor_scheme}, {name: details, var: details}, {name: id, var: body_id}, {name: internationalBankAccountNumber, var: international_bank_account_number}, {name: isDefaultBank, var: is_default_bank}, {name: lastChq, var: last_chq}, {name: nominalAcCode, var: nominal_ac_code}, {name: oBalance, var: o_balance}, {name: sortCode, var: sort_code}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, account_name: $account_name, account_number: $account_number, address: $address, bank_feed_source: $bank_feed_source, business_identifier_codes: $business_identifier_codes, category_id: $category_id, creditor_scheme: $creditor_scheme, details: $details, body_id: $body_id, international_bank_account_number: $international_bank_account_number, is_default_bank: $is_default_bank, last_chq: $last_chq, nominal_ac_code: $nominal_ac_code, o_balance: $o_balance, sort_code: $sort_code, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of global Book Transactions' Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/bookTranTypes
# Returns: record<Count: int, Items: table<code: string, description: string, id: int>, NextPageLink: string>
# operationId: BookTranTypes_Get
export def "book-tran-types-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bookTranTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Cash Payments. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/cashPayments
# Returns: record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float, unallocated: float>, NextPageLink: string>
# operationId: CashPayments_Get
export def "cash-payments-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/cashPayments"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Cash Payment.
#
# POST /v1/cashPayments
# Returns: record
# operationId: CashPayments_Post
export def "cash-payments-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --id: int # format: int64
  --ledger: float # format: double
  --lodgement: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/cashPayments"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bankAccountCode, var: bank_account_code}, {name: bankAccountId, var: bank_account_id}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: detailCollection, var: detail_collection}, {name: discount, var: discount}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: ledger, var: ledger}, {name: lodgement, var: lodgement}, {name: note, var: note}, {name: plaidTransactionId, var: plaid_transaction_id}, {name: procDate, var: proc_date}, {name: supplierId, var: supplier_id}, {name: timestamp, var: timestamp}, {name: total, var: total}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, ac_entries: $ac_entries, bank_account_code: $bank_account_code, bank_account_id: $bank_account_id, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, detail_collection: $detail_collection, discount: $discount, entry_date: $entry_date, id: $id, ledger: $ledger, lodgement: $lodgement, note: $note, plaid_transaction_id: $plaid_transaction_id, proc_date: $proc_date, supplier_id: $supplier_id, timestamp: $timestamp, total: $total
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Cash Payments.
#
# PUT /v1/cashPayments/batch
# Returns: record
# operationId: CashPayments_ProcessBatch
export def "cash-payments-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/cashPayments/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Cash Payment.
#
# DELETE /v1/cashPayments/{id}
# Returns: record
# operationId: CashPayments_Delete
export def "cash-payments-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Cash Receipt to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/cashPayments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Cash Payment.
#
# GET /v1/cashPayments/{id}
# Returns: record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float>
export def "get-v1-cash-payments-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/cashPayments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Cash Payment.
#
# PUT /v1/cashPayments/{id}
# Returns: record
# operationId: CashPayments_Put
export def "cash-payments-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --ledger: float # format: double
  --lodgement: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/cashPayments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bankAccountCode, var: bank_account_code}, {name: bankAccountId, var: bank_account_id}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: detailCollection, var: detail_collection}, {name: discount, var: discount}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: ledger, var: ledger}, {name: lodgement, var: lodgement}, {name: note, var: note}, {name: plaidTransactionId, var: plaid_transaction_id}, {name: procDate, var: proc_date}, {name: supplierId, var: supplier_id}, {name: timestamp, var: timestamp}, {name: total, var: total}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, ac_entries: $ac_entries, bank_account_code: $bank_account_code, bank_account_id: $bank_account_id, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, detail_collection: $detail_collection, discount: $discount, entry_date: $entry_date, body_id: $body_id, ledger: $ledger, lodgement: $lodgement, note: $note, plaid_transaction_id: $plaid_transaction_id, proc_date: $proc_date, supplier_id: $supplier_id, timestamp: $timestamp, total: $total
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Cash Receipts. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/cashReceipts
# Returns: record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>
# operationId: CashReceipts_Get
export def "cash-receipts-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/cashReceipts"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Cash Receipt.
#
# POST /v1/cashReceipts
# Returns: record
# operationId: CashReceipts_Post
export def "cash-receipts-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --id: int # format: int64
  --ledger: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --timestamp: string # format: byte
  --total: float # format: double
  --unallocated: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/cashReceipts"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: detailCollection, var: detail_collection}, {name: discount, var: discount}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: ledger, var: ledger}, {name: note, var: note}, {name: plaidTransactionId, var: plaid_transaction_id}, {name: procDate, var: proc_date}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: unallocated, var: unallocated}, {name: vatEntries, var: vat_entries}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, ac_entries: $ac_entries, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, detail_collection: $detail_collection, discount: $discount, entry_date: $entry_date, id: $id, ledger: $ledger, note: $note, plaid_transaction_id: $plaid_transaction_id, proc_date: $proc_date, timestamp: $timestamp, total: $total, unallocated: $unallocated, vat_entries: $vat_entries, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Cash Receipts.
#
# PUT /v1/cashReceipts/batch
# Returns: record
# operationId: CashReceipts_ProcessBatch
export def "cash-receipts-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/cashReceipts/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Cash Receipt.
#
# DELETE /v1/cashReceipts/{id}
# Returns: record
# operationId: CashReceipts_Delete
export def "cash-receipts-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Cash Receipt to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/cashReceipts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Cash Receipt.
#
# GET /v1/cashReceipts/{id}
# Returns: record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int>
export def "get-v1-cash-receipts-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/cashReceipts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Cash Receipt.
#
# PUT /v1/cashReceipts/{id}
# Returns: record
# operationId: CashReceipts_Put
export def "cash-receipts-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --ledger: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --timestamp: string # format: byte
  --total: float # format: double
  --unallocated: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/cashReceipts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: detailCollection, var: detail_collection}, {name: discount, var: discount}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: ledger, var: ledger}, {name: note, var: note}, {name: plaidTransactionId, var: plaid_transaction_id}, {name: procDate, var: proc_date}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: unallocated, var: unallocated}, {name: vatEntries, var: vat_entries}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, ac_entries: $ac_entries, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, detail_collection: $detail_collection, discount: $discount, entry_date: $entry_date, body_id: $body_id, ledger: $ledger, note: $note, plaid_transaction_id: $plaid_transaction_id, proc_date: $proc_date, timestamp: $timestamp, total: $total, unallocated: $unallocated, vat_entries: $vat_entries, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Category Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/categoryTypes
# Returns: record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>
# operationId: CategoryTypes_Get
export def "category-types-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/categoryTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company settings. Supports OData querying protocol. Filtering is forbidden.
#
# GET /v1/companySettings
# Returns: record<Count: int, Items: table<enableVOCRReporting: bool, id: int, useAllocations: bool, value: string, vocrSettingValue: bool>, NextPageLink: string>
# operationId: CompanySettings_Get
export def "company-settings-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/companySettings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the company configuration settings.
#
# GET /v1/companySetupConfig
# Returns: record<financialYear: record<firstMonth: int, startMonth: int, startYear: int>, generalDetails: record<companyAddresses: list<string>, companyName: string, currencyCode: string, currencyDescription: string, currencyId: int, currentcySymbol: string, emails: list<string>, faxes: list<string>, phones: list<string>, regionDescription: string, regionId: int, vatReg: string>, options: record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool>, referenceSettings: record<creditorsJournal: bool, debtorsJournal: bool, purchases: bool, sales: bool>>
# operationId: CompanySetupConfig_Get
export def "company-setup-config-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/companySetupConfig"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the company option setting.
#
# GET /v1/companySetupConfig/getCompanyOptions
# Returns: record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool>
# operationId: CompanySetupConfig_GetCompanyOptions
export def "company-setup-config-get-company-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/companySetupConfig/getCompanyOptions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the financial year.
#
# GET /v1/companySetupConfig/getFinancialYear
# Returns: record<firstMonth: int, startMonth: int, startYear: int>
# operationId: CompanySetupConfig_GetFinancialYear
export def "company-setup-config-get-financial-year" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/companySetupConfig/getFinancialYear"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Customers. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/customers
# Returns: record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, delivery: list, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string>
# operationId: Customers_Get
export def "customers-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/customers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Customer.
#
# POST /v1/customers
# Returns: record
# operationId: Customers_Post
export def "customers-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --delivery: list<string>
  --e-ft-reference: string
  --email: string
  --fax: string
  --id: int # format: int64
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/customers"
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: additionalEmails, var: additional_emails}, {name: address, var: address}, {name: authCode, var: auth_code}, {name: bank, var: bank}, {name: businessIdentifierCode, var: business_identifier_code}, {name: code, var: code}, {name: contact, var: contact}, {name: delivery, var: delivery}, {name: eFTReference, var: e_ft_reference}, {name: email, var: email}, {name: fax, var: fax}, {name: id, var: id}, {name: internationalBankAccountNumber, var: international_bank_account_number}, {name: ledgerBalance, var: ledger_balance}, {name: mobile, var: mobile}, {name: name, var: name}, {name: openingBalance, var: opening_balance}, {name: openingBalances, var: opening_balances}, {name: ourCode, var: our_code}, {name: ownerTypeId, var: owner_type_id}, {name: phone, var: phone}, {name: timestamp, var: timestamp}, {name: vatAnalysisTypeId, var: vat_analysis_type_id}, {name: vatReg, var: vat_reg}, {name: vatType, var: vat_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, account_number: $account_number, additional_emails: $additional_emails, address: $address, auth_code: $auth_code, bank: $bank, business_identifier_code: $business_identifier_code, code: $code, contact: $contact, delivery: $delivery, e_ft_reference: $e_ft_reference, email: $email, fax: $fax, id: $id, international_bank_account_number: $international_bank_account_number, ledger_balance: $ledger_balance, mobile: $mobile, name: $name, opening_balance: $opening_balance, opening_balances: $opening_balances, our_code: $our_code, owner_type_id: $owner_type_id, phone: $phone, timestamp: $timestamp, vat_analysis_type_id: $vat_analysis_type_id, vat_reg: $vat_reg, vat_type: $vat_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Customers.
#
# PUT /v1/customers/batch
# Returns: record
# operationId: Customers_ProcessBatch
export def "customers-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/customers/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Customer.
#
# DELETE /v1/customers/{id}
# Returns: record
# operationId: Customers_Delete
export def "customers-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Customer to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/customers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Customer. You may specify that Customer's ledger balance should be calculated.
#
# GET /v1/customers/{id}
# Returns: record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, delivery: list<string>, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>
export def "get-v1-customers-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --need-balance: oneof<nothing, bool> # If "true" then Customer's ledger balance will be calculated; otherwise balance will be returned as 0.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/customers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: needBalance, var: need_balance}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, need_balance: $need_balance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Customer.
#
# PUT /v1/customers/{id}
# Returns: record
# operationId: Customers_Put
export def "customers-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --delivery: list<string>
  --e-ft-reference: string
  --email: string
  --fax: string
  --body-id: int # format: int64 (spec name: id)
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/customers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: additionalEmails, var: additional_emails}, {name: address, var: address}, {name: authCode, var: auth_code}, {name: bank, var: bank}, {name: businessIdentifierCode, var: business_identifier_code}, {name: code, var: code}, {name: contact, var: contact}, {name: delivery, var: delivery}, {name: eFTReference, var: e_ft_reference}, {name: email, var: email}, {name: fax, var: fax}, {name: id, var: body_id}, {name: internationalBankAccountNumber, var: international_bank_account_number}, {name: ledgerBalance, var: ledger_balance}, {name: mobile, var: mobile}, {name: name, var: name}, {name: openingBalance, var: opening_balance}, {name: openingBalances, var: opening_balances}, {name: ourCode, var: our_code}, {name: ownerTypeId, var: owner_type_id}, {name: phone, var: phone}, {name: timestamp, var: timestamp}, {name: vatAnalysisTypeId, var: vat_analysis_type_id}, {name: vatReg, var: vat_reg}, {name: vatType, var: vat_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, account_name: $account_name, account_number: $account_number, additional_emails: $additional_emails, address: $address, auth_code: $auth_code, bank: $bank, business_identifier_code: $business_identifier_code, code: $code, contact: $contact, delivery: $delivery, e_ft_reference: $e_ft_reference, email: $email, fax: $fax, body_id: $body_id, international_bank_account_number: $international_bank_account_number, ledger_balance: $ledger_balance, mobile: $mobile, name: $name, opening_balance: $opening_balance, opening_balances: $opening_balances, our_code: $our_code, owner_type_id: $owner_type_id, phone: $phone, timestamp: $timestamp, vat_analysis_type_id: $vat_analysis_type_id, vat_reg: $vat_reg, vat_type: $vat_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Customer's account transactions.
#
# GET /v1/customers/{itemId}/accountTrans
# Returns: table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string>
# operationId: Customers_GetAccountTrans
export def "customers-get-account-trans" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/customers/{itemId}/accountTrans"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a Customer's opening balances, calculated for the next periods: current month, one month old, two months old, three and more months old.
#
# GET /v1/customers/{itemId}/openingBalance
# Returns: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>
# operationId: Customers_GetOpeningBalance
export def "customers-get-opening-balance" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/customers/{itemId}/openingBalance"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Customer's opening balance transactions.
#
# GET /v1/customers/{itemId}/openingBalanceList
# Returns: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>>
# operationId: Customers_GetOpeningBalanceList
export def "customers-get-opening-balance-list" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/customers/{itemId}/openingBalanceList"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Customer's quotes.
#
# GET /v1/customers/{itemId}/quotes
# Returns: table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list<record>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list<record>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>
# operationId: Customers_GetQuotes
export def "customers-get-quotes" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/customers/{itemId}/quotes"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a Statement email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Statement Customer's address.
#
# POST /v1/email/sendEmailStatement
# Returns: record
# operationId: Email_SendEmailStatement
export def "email-send-email-statement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bcc-addresses: list<string>
  --customer-id: int # format: int64
  --from-period: string # format: date-time
  --message-body: string
  --minimum-balance: float # format: double
  --to-address: string
  --to-period: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/email/sendEmailStatement"
    body: {content_type: "application/json", kind: json, fields: [{name: bccAddresses, var: bcc_addresses}, {name: customerId, var: customer_id}, {name: fromPeriod, var: from_period}, {name: messageBody, var: message_body}, {name: minimumBalance, var: minimum_balance}, {name: toAddress, var: to_address}, {name: toPeriod, var: to_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bcc_addresses: $bcc_addresses, customer_id: $customer_id, from_period: $from_period, message_body: $message_body, minimum_balance: $minimum_balance, to_address: $to_address, to_period: $to_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a Quote email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Statement Customer's address.
#
# POST /v1/email/sendQuote
# Returns: record
# operationId: Email_SendQuote
export def "email-send-quote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bcc-addresses: list<string>
  --message-body: string
  --quote-id: int # format: int64
  --to-address: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/email/sendQuote"
    body: {content_type: "application/json", kind: json, fields: [{name: bccAddresses, var: bcc_addresses}, {name: messageBody, var: message_body}, {name: quoteId, var: quote_id}, {name: toAddress, var: to_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bcc_addresses: $bcc_addresses, message_body: $message_body, quote_id: $quote_id, to_address: $to_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a Sales Invoice email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Sales Invoice Customer's address.
#
# POST /v1/email/sendSalesInvoice
# Returns: record
# operationId: Email_SendSalesInvoice
export def "email-send-sales-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bcc-addresses: list<string>
  --message-body: string
  --sales-invoice-id: int # format: int64
  --to-address: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/email/sendSalesInvoice"
    body: {content_type: "application/json", kind: json, fields: [{name: bccAddresses, var: bcc_addresses}, {name: messageBody, var: message_body}, {name: salesInvoiceId, var: sales_invoice_id}, {name: toAddress, var: to_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bcc_addresses: $bcc_addresses, message_body: $message_body, sales_invoice_id: $sales_invoice_id, to_address: $to_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of global Owner Type Groups. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/ownerTypeGroups
# Returns: record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>
# operationId: OwnerTypeGroups_Get
export def "owner-type-groups-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/ownerTypeGroups"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of global Owner Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/ownerTypes
# Returns: record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string>
# operationId: OwnerTypes_Get
export def "owner-types-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/ownerTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Payments. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/payments
# Returns: record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float>, NextPageLink: string>
# operationId: Payments_Get
export def "payments-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/payments"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Payment.
#
# POST /v1/payments
# Returns: record
# operationId: Payments_Post
export def "payments-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --id: int # format: int64
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --transfer-bank-code: string
  --transfer-bank-id: int # format: int64
  --unallocated: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/payments"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bankAccountCode, var: bank_account_code}, {name: bankAccountId, var: bank_account_id}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: detailCollection, var: detail_collection}, {name: discount, var: discount}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: note, var: note}, {name: plaidTransactionId, var: plaid_transaction_id}, {name: procDate, var: proc_date}, {name: reference, var: reference}, {name: supplierId, var: supplier_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: transferBankCode, var: transfer_bank_code}, {name: transferBankId, var: transfer_bank_id}, {name: unallocated, var: unallocated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, ac_entries: $ac_entries, bank_account_code: $bank_account_code, bank_account_id: $bank_account_id, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, detail_collection: $detail_collection, discount: $discount, entry_date: $entry_date, id: $id, note: $note, plaid_transaction_id: $plaid_transaction_id, proc_date: $proc_date, reference: $reference, supplier_id: $supplier_id, timestamp: $timestamp, total: $total, transfer_bank_code: $transfer_bank_code, transfer_bank_id: $transfer_bank_id, unallocated: $unallocated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Payments.
#
# PUT /v1/payments/batch
# Returns: record
# operationId: Payments_ProcessBatch
export def "payments-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/payments/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Payment.
#
# DELETE /v1/payments/{id}
# Returns: record
# operationId: Payments_Delete
export def "payments-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Payment to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Payments.
#
# GET /v1/payments/{id}
# Returns: record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float>
export def "get-v1-payments-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/payments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Payment.
#
# PUT /v1/payments/{id}
# Returns: record
# operationId: Payments_Put
export def "payments-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --transfer-bank-code: string
  --transfer-bank-id: int # format: int64
  --unallocated: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/payments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bankAccountCode, var: bank_account_code}, {name: bankAccountId, var: bank_account_id}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: detailCollection, var: detail_collection}, {name: discount, var: discount}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: note, var: note}, {name: plaidTransactionId, var: plaid_transaction_id}, {name: procDate, var: proc_date}, {name: reference, var: reference}, {name: supplierId, var: supplier_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: transferBankCode, var: transfer_bank_code}, {name: transferBankId, var: transfer_bank_id}, {name: unallocated, var: unallocated}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, ac_entries: $ac_entries, bank_account_code: $bank_account_code, bank_account_id: $bank_account_id, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, detail_collection: $detail_collection, discount: $discount, entry_date: $entry_date, body_id: $body_id, note: $note, plaid_transaction_id: $plaid_transaction_id, proc_date: $proc_date, reference: $reference, supplier_id: $supplier_id, timestamp: $timestamp, total: $total, transfer_bank_code: $transfer_bank_code, transfer_bank_id: $transfer_bank_id, unallocated: $unallocated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of global Product Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/productTypes
# Returns: record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string>
# operationId: ProductTypes_Get
export def "product-types-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/productTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Products. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "stockCode" fields.
#
# GET /v1/products
# Returns: record<Count: int, Items: table<details: list, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int>, NextPageLink: string>
# operationId: Products_Get
export def "products-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Product.
#
# POST /v1/products
# Returns: record
# operationId: Products_Post
export def "products-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: list<string>
  --gross-unit-price: oneof<nothing, bool>
  --has-default-vat-rate: oneof<nothing, bool>
  --id: int # format: int64
  --product-type-id: int # format: int64
  --stock-code: string
  --timestamp: string # format: byte
  --unit-price: float # format: double
  --vat-analysis-type-id: int # format: int64
  --vat-rate-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/products"
    body: {content_type: "application/json", kind: json, fields: [{name: details, var: details}, {name: grossUnitPrice, var: gross_unit_price}, {name: hasDefaultVatRate, var: has_default_vat_rate}, {name: id, var: id}, {name: productTypeId, var: product_type_id}, {name: stockCode, var: stock_code}, {name: timestamp, var: timestamp}, {name: unitPrice, var: unit_price}, {name: vatAnalysisTypeId, var: vat_analysis_type_id}, {name: vatRateId, var: vat_rate_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    details: $details, gross_unit_price: $gross_unit_price, has_default_vat_rate: $has_default_vat_rate, id: $id, product_type_id: $product_type_id, stock_code: $stock_code, timestamp: $timestamp, unit_price: $unit_price, vat_analysis_type_id: $vat_analysis_type_id, vat_rate_id: $vat_rate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Products.
#
# PUT /v1/products/batch
# Returns: record
# operationId: Products_ProcessBatch
export def "products-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/products/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Product.
#
# DELETE /v1/products/{id}
# Returns: record
# operationId: Products_Delete
export def "products-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Product to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/products/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Product.
#
# GET /v1/products/{id}
# Returns: record<details: list<string>, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int>
export def "get-v1-products-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Product.
#
# PUT /v1/products/{id}
# Returns: record
# operationId: Products_Put
export def "products-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: list<string>
  --gross-unit-price: oneof<nothing, bool>
  --has-default-vat-rate: oneof<nothing, bool>
  --body-id: int # format: int64 (spec name: id)
  --product-type-id: int # format: int64
  --stock-code: string
  --timestamp: string # format: byte
  --unit-price: float # format: double
  --vat-analysis-type-id: int # format: int64
  --vat-rate-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/products/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: details, var: details}, {name: grossUnitPrice, var: gross_unit_price}, {name: hasDefaultVatRate, var: has_default_vat_rate}, {name: id, var: body_id}, {name: productTypeId, var: product_type_id}, {name: stockCode, var: stock_code}, {name: timestamp, var: timestamp}, {name: unitPrice, var: unit_price}, {name: vatAnalysisTypeId, var: vat_analysis_type_id}, {name: vatRateId, var: vat_rate_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, details: $details, gross_unit_price: $gross_unit_price, has_default_vat_rate: $has_default_vat_rate, body_id: $body_id, product_type_id: $product_type_id, stock_code: $stock_code, timestamp: $timestamp, unit_price: $unit_price, vat_analysis_type_id: $vat_analysis_type_id, vat_rate_id: $vat_rate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Purchases. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/purchases
# Returns: record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, detailCollection: list, entryDate: string, id: int, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>
# operationId: Purchases_Get
export def "purchases-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/purchases"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Purchase.
#
# POST /v1/purchases
# Returns: record
# operationId: Purchases_Post
export def "purchases-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --entry-date: string # format: date-time
  --id: int # format: int64
  --is-discrepancy-accepted: oneof<nothing, bool>
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --postponed-accounting: oneof<nothing, bool>
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unallocated: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/purchases"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: detailCollection, var: detail_collection}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: isDiscrepancyAccepted, var: is_discrepancy_accepted}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: postponedAccounting, var: postponed_accounting}, {name: procDate, var: proc_date}, {name: reference, var: reference}, {name: supplierId, var: supplier_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unallocated, var: unallocated}, {name: unpaid, var: unpaid}, {name: vatEntries, var: vat_entries}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, ac_entries: $ac_entries, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, detail_collection: $detail_collection, entry_date: $entry_date, id: $id, is_discrepancy_accepted: $is_discrepancy_accepted, net_goods: $net_goods, net_services: $net_services, note: $note, postponed_accounting: $postponed_accounting, proc_date: $proc_date, reference: $reference, supplier_id: $supplier_id, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unallocated: $unallocated, unpaid: $unpaid, vat_entries: $vat_entries, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Purchases.
#
# PUT /v1/purchases/batch
# Returns: record
# operationId: Purchases_ProcessBatch
export def "purchases-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/purchases/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Purchase.
#
# DELETE /v1/purchases/{id}
# Returns: record
# operationId: Purchases_Delete
export def "purchases-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Purchase to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/purchases/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Purchases.
#
# GET /v1/purchases/{id}
# Returns: record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, entryDate: string, id: int, isDiscrepancyAccepted: bool, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int>
export def "get-v1-purchases-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/purchases/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Purchase.
#
# PUT /v1/purchases/{id}
# Returns: record
# operationId: Purchases_Put
export def "purchases-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --is-discrepancy-accepted: oneof<nothing, bool>
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --postponed-accounting: oneof<nothing, bool>
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unallocated: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/purchases/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: detailCollection, var: detail_collection}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: isDiscrepancyAccepted, var: is_discrepancy_accepted}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: postponedAccounting, var: postponed_accounting}, {name: procDate, var: proc_date}, {name: reference, var: reference}, {name: supplierId, var: supplier_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unallocated, var: unallocated}, {name: unpaid, var: unpaid}, {name: vatEntries, var: vat_entries}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, ac_entries: $ac_entries, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, detail_collection: $detail_collection, entry_date: $entry_date, body_id: $body_id, is_discrepancy_accepted: $is_discrepancy_accepted, net_goods: $net_goods, net_services: $net_services, note: $note, postponed_accounting: $postponed_accounting, proc_date: $proc_date, reference: $reference, supplier_id: $supplier_id, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unallocated: $unallocated, unpaid: $unpaid, vat_entries: $vat_entries, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Quotes. Filtering is forbidden. Ordering is allowed by "id".
#
# GET /v1/quotes
# Returns: record<Count: int, Items: table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>, NextPageLink: string>
# operationId: Quote_Get
export def "quote-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/quotes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Quote.
#
# POST /v1/quotes
# Returns: record
# operationId: Quote_Post
export def "quote-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --closed-date: string # format: date-time
  --comments: string
  --company-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-owner-id: int # format: int64
  --customer-owner-name: string
  --dd-number: string
  --delivery-list: string
  --delivery-to: list<string>
  --entry-date: string # format: date-time
  --id: int # format: int64
  --layout-type: int # format: int32
  --note: string
  --po-number: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --sale-invoice-id: int # format: int64
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --time-stamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/quotes"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: closedDate, var: closed_date}, {name: comments, var: comments}, {name: companyId, var: company_id}, {name: customFields, var: custom_fields}, {name: customerOwnerId, var: customer_owner_id}, {name: customerOwnerName, var: customer_owner_name}, {name: ddNumber, var: dd_number}, {name: deliveryList, var: delivery_list}, {name: deliveryTo, var: delivery_to}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: layoutType, var: layout_type}, {name: note, var: note}, {name: poNumber, var: po_number}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: reference, var: reference}, {name: saleInvoiceId, var: sale_invoice_id}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timeStamp, var: time_stamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVat, var: total_vat}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, closed_date: $closed_date, comments: $comments, company_id: $company_id, custom_fields: $custom_fields, customer_owner_id: $customer_owner_id, customer_owner_name: $customer_owner_name, dd_number: $dd_number, delivery_list: $delivery_list, delivery_to: $delivery_to, entry_date: $entry_date, id: $id, layout_type: $layout_type, note: $note, po_number: $po_number, proc_date: $proc_date, product_trans: $product_trans, reference: $reference, sale_invoice_id: $sale_invoice_id, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, time_stamp: $time_stamp, total: $total, total_net: $total_net, total_vat: $total_vat, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Quote.
#
# PUT /v1/quotes/batch
# Returns: record
# operationId: Quote_ProcessBatch
export def "quote-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/quotes/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close a Quote.
#
# PUT /v1/quotes/close/{id}
# Returns: record
# operationId: Quote_Close
export def "quote-close" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/v1/quotes/close/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Quote with auto generating reference.
#
# POST /v1/quotes/createQuoteWithGeneratingReference
# Returns: record
# operationId: Quote_Post_CreateQuoteWithGeneratingReference
export def "quote-post-create-quote-with-generating-reference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --closed-date: string # format: date-time
  --comments: string
  --company-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-owner-id: int # format: int64
  --customer-owner-name: string
  --dd-number: string
  --delivery-list: string
  --delivery-to: list<string>
  --entry-date: string # format: date-time
  --id: int # format: int64
  --layout-type: int # format: int32
  --note: string
  --po-number: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --sale-invoice-id: int # format: int64
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --time-stamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/quotes/createQuoteWithGeneratingReference"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: closedDate, var: closed_date}, {name: comments, var: comments}, {name: companyId, var: company_id}, {name: customFields, var: custom_fields}, {name: customerOwnerId, var: customer_owner_id}, {name: customerOwnerName, var: customer_owner_name}, {name: ddNumber, var: dd_number}, {name: deliveryList, var: delivery_list}, {name: deliveryTo, var: delivery_to}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: layoutType, var: layout_type}, {name: note, var: note}, {name: poNumber, var: po_number}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: reference, var: reference}, {name: saleInvoiceId, var: sale_invoice_id}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timeStamp, var: time_stamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVat, var: total_vat}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, closed_date: $closed_date, comments: $comments, company_id: $company_id, custom_fields: $custom_fields, customer_owner_id: $customer_owner_id, customer_owner_name: $customer_owner_name, dd_number: $dd_number, delivery_list: $delivery_list, delivery_to: $delivery_to, entry_date: $entry_date, id: $id, layout_type: $layout_type, note: $note, po_number: $po_number, proc_date: $proc_date, product_trans: $product_trans, reference: $reference, sale_invoice_id: $sale_invoice_id, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, time_stamp: $time_stamp, total: $total, total_net: $total_net, total_vat: $total_vat, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a sale invoice from a Quote. When sale invoice is empty, new sale invoice will be generated from Quote.
#
# POST /v1/quotes/generateSaleInvoice
# Returns: record
# operationId: Quote_Post_GenerateSaleInvoice
export def "quote-post-generate-sale-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: int # format: int64
  --sale-invoice: record # e.g. {acCode: CUS3, bookTranTypeId: 7, customFields: [{description: acudf_1, id: 1, userDefinedFieldId: 1, value: acudfv_1}, {description: acudf_2, id: 2, userDefinedFieldId: 1, value: acudfv_2}], customerId: 70585, deliveryTo: [dt_1, dt_2], details: detail_1, entryDate: 2016-06-01T00:00:00, id: 75813, loType: 1, note: Customer 3, ourReference: ddNumber_1, procDate: 2016-06-24T00:00:00, productTrans: [{acEntries: [{accountCode: SA02, analysisCategoryId: 40889, description: AnCat1, id: 73455, value: -200}], amount: -220, amountNet: -200, id: 51820, percentage: 10, productCode: PRO2, productId: 20108, quantity: -1, tranNotes: [tn_1, tn_2], unitPrice: 200, vat: -20, vatAnalysisTypeId: 0, vatRateId: 30657}], saleRepId: 33110, timestamp: oq6NcBIe2wg=, total: -220, totalNet: -200, totalVAT: -20, unpaid: -220, vatTypeId: 1, yourReference: poNumber_1} — shape: {acCode?: string, bookTranTypeId?: int, customFields?: list, customerId?: int, deliveryTo?: list<string>, details?: string, entryDate?: string, id?: int, loType?: string, netGoods?: float, netServices?: float, note?: string, ourReference?: string, procDate?: string, productTrans?: list, quoteId?: int, reference?: string, saleRepCode?: string, saleRepId?: int, timestamp?: string, total?: float, totalNet?: float, totalVAT?: float, unpaid?: float, vatTypeId?: int, yourReference?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/quotes/generateSaleInvoice"
    body: {content_type: "application/json", kind: json, fields: [{name: quoteId, var: quote_id}, {name: saleInvoice, var: sale_invoice}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, sale_invoice: $sale_invoice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reopen a Quote.
#
# PUT /v1/quotes/reopen/{id}
# Returns: record
# operationId: Quote_Reopen
export def "quote-reopen" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/v1/quotes/reopen/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Quote.
#
# DELETE /v1/quotes/{id}
# Returns: record
# operationId: Quote_Delete
export def "quote-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Quote to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/quotes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Quote.
#
# GET /v1/quotes/{id}
# Returns: record<acCode: string, closedDate: string, comments: string, companyId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: table<acEntries: list, amount: float, companyId: int, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vatAmount: float, vatAnalysisTypeId: int, vatRateId: int>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>
export def "get-v1-quotes-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/quotes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Quote.
#
# PUT /v1/quotes/{id}
# Returns: record
# operationId: Quote_Put
export def "quote-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --closed-date: string # format: date-time
  --comments: string
  --company-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-owner-id: int # format: int64
  --customer-owner-name: string
  --dd-number: string
  --delivery-list: string
  --delivery-to: list<string>
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --layout-type: int # format: int32
  --note: string
  --po-number: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --sale-invoice-id: int # format: int64
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --time-stamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/quotes/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: closedDate, var: closed_date}, {name: comments, var: comments}, {name: companyId, var: company_id}, {name: customFields, var: custom_fields}, {name: customerOwnerId, var: customer_owner_id}, {name: customerOwnerName, var: customer_owner_name}, {name: ddNumber, var: dd_number}, {name: deliveryList, var: delivery_list}, {name: deliveryTo, var: delivery_to}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: layoutType, var: layout_type}, {name: note, var: note}, {name: poNumber, var: po_number}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: reference, var: reference}, {name: saleInvoiceId, var: sale_invoice_id}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timeStamp, var: time_stamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVat, var: total_vat}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, closed_date: $closed_date, comments: $comments, company_id: $company_id, custom_fields: $custom_fields, customer_owner_id: $customer_owner_id, customer_owner_name: $customer_owner_name, dd_number: $dd_number, delivery_list: $delivery_list, delivery_to: $delivery_to, entry_date: $entry_date, body_id: $body_id, layout_type: $layout_type, note: $note, po_number: $po_number, proc_date: $proc_date, product_trans: $product_trans, reference: $reference, sale_invoice_id: $sale_invoice_id, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, time_stamp: $time_stamp, total: $total, total_net: $total_net, total_vat: $total_vat, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Sales Entries, Sales Invoices and Sales Credit Notes. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/sales
# Returns: record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, details: string, entryDate: string, id: int, loType: string, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>
# operationId: Sales_Get
export def "sales-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/sales"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Sales Credit Notes. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesCreditNotes
# Returns: record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string>
# operationId: SalesCreditNotes_Get
export def "sales-credit-notes-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesCreditNotes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Sales Credit Note.
#
# POST /v1/salesCreditNotes
# Returns: record
# operationId: SalesCreditNotes_Post
export def "sales-credit-notes-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/salesCreditNotes"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: deliveryTo, var: delivery_to}, {name: details, var: details}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: loType, var: lo_type}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: ourReference, var: our_reference}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: quoteId, var: quote_id}, {name: reference, var: reference}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unpaid, var: unpaid}, {name: vatTypeId, var: vat_type_id}, {name: yourReference, var: your_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, delivery_to: $delivery_to, details: $details, entry_date: $entry_date, id: $id, lo_type: $lo_type, net_goods: $net_goods, net_services: $net_services, note: $note, our_reference: $our_reference, proc_date: $proc_date, product_trans: $product_trans, quote_id: $quote_id, reference: $reference, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unpaid: $unpaid, vat_type_id: $vat_type_id, your_reference: $your_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Sales Credit Notes.
#
# PUT /v1/salesCreditNotes/batch
# Returns: record
# operationId: SalesCreditNotes_ProcessBatch
export def "sales-credit-notes-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesCreditNotes/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Sales Credit Note.
#
# DELETE /v1/salesCreditNotes/{id}
# Returns: record
# operationId: SalesCreditNotes_Delete
export def "sales-credit-notes-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Credit Note to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/salesCreditNotes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Sales Credit Note.
#
# GET /v1/salesCreditNotes/{id}
# Returns: record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>
export def "get-v1-sales-credit-notes-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesCreditNotes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Sales Credit Note.
#
# PUT /v1/salesCreditNotes/{id}
# Returns: record
# operationId: SalesCreditNotes_Put
export def "sales-credit-notes-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesCreditNotes/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: deliveryTo, var: delivery_to}, {name: details, var: details}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: loType, var: lo_type}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: ourReference, var: our_reference}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: quoteId, var: quote_id}, {name: reference, var: reference}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unpaid, var: unpaid}, {name: vatTypeId, var: vat_type_id}, {name: yourReference, var: your_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, delivery_to: $delivery_to, details: $details, entry_date: $entry_date, body_id: $body_id, lo_type: $lo_type, net_goods: $net_goods, net_services: $net_services, note: $note, our_reference: $our_reference, proc_date: $proc_date, product_trans: $product_trans, quote_id: $quote_id, reference: $reference, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unpaid: $unpaid, vat_type_id: $vat_type_id, your_reference: $your_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Sales Entries. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesEntries
# Returns: record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string>
# operationId: SalesEntries_Get
export def "sales-entries-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesEntries"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Sales Entry.
#
# POST /v1/salesEntries
# Returns: record
# operationId: SalesEntries_Post
export def "sales-entries-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --proc-date: string # format: date-time
  --reference: string
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/salesEntries"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: detailCollection, var: detail_collection}, {name: details, var: details}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: procDate, var: proc_date}, {name: reference, var: reference}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unpaid, var: unpaid}, {name: vatEntries, var: vat_entries}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, ac_entries: $ac_entries, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, detail_collection: $detail_collection, details: $details, entry_date: $entry_date, id: $id, net_goods: $net_goods, net_services: $net_services, note: $note, proc_date: $proc_date, reference: $reference, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unpaid: $unpaid, vat_entries: $vat_entries, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Sales Entries.
#
# PUT /v1/salesEntries/batch
# Returns: record
# operationId: SalesEntries_ProcessBatch
export def "sales-entries-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesEntries/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Sales Entry.
#
# DELETE /v1/salesEntries/{id}
# Returns: record
# operationId: SalesEntries_Delete
export def "sales-entries-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Entry to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/salesEntries/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Sales Entry.
#
# GET /v1/salesEntries/{id}
# Returns: record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int>
export def "get-v1-sales-entries-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesEntries/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Sales Entry.
#
# PUT /v1/salesEntries/{id}
# Returns: record
# operationId: SalesEntries_Put
export def "sales-entries-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --details: string
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --proc-date: string # format: date-time
  --reference: string
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesEntries/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: acEntries, var: ac_entries}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: detailCollection, var: detail_collection}, {name: details, var: details}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: procDate, var: proc_date}, {name: reference, var: reference}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unpaid, var: unpaid}, {name: vatEntries, var: vat_entries}, {name: vatTypeId, var: vat_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, ac_entries: $ac_entries, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, detail_collection: $detail_collection, details: $details, entry_date: $entry_date, body_id: $body_id, net_goods: $net_goods, net_services: $net_services, note: $note, proc_date: $proc_date, reference: $reference, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unpaid: $unpaid, vat_entries: $vat_entries, vat_type_id: $vat_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Sales Invoices. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesInvoices
# Returns: record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string>
# operationId: SalesInvoices_Get
export def "sales-invoices-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesInvoices"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Sales Invoice.
#
# POST /v1/salesInvoices
# Returns: record
# operationId: SalesInvoices_Post
export def "sales-invoices-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/salesInvoices"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: deliveryTo, var: delivery_to}, {name: details, var: details}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: loType, var: lo_type}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: ourReference, var: our_reference}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: quoteId, var: quote_id}, {name: reference, var: reference}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unpaid, var: unpaid}, {name: vatTypeId, var: vat_type_id}, {name: yourReference, var: your_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, delivery_to: $delivery_to, details: $details, entry_date: $entry_date, id: $id, lo_type: $lo_type, net_goods: $net_goods, net_services: $net_services, note: $note, our_reference: $our_reference, proc_date: $proc_date, product_trans: $product_trans, quote_id: $quote_id, reference: $reference, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unpaid: $unpaid, vat_type_id: $vat_type_id, your_reference: $your_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Sales Invoices.
#
# PUT /v1/salesInvoices/batch
# Returns: record
# operationId: SalesInvoices_ProcessBatch
export def "sales-invoices-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesInvoices/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Sale Invoice with auto generating reference.
#
# POST /v1/salesInvoices/createSaleInvoiceWithGeneratingReference
# Returns: record
# operationId: SalesInvoices_Post_CreateSaleInvoiceWithGeneratingReference
export def "sales-invoices-post-create-sale-invoice-with-generating-reference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/salesInvoices/createSaleInvoiceWithGeneratingReference"
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: deliveryTo, var: delivery_to}, {name: details, var: details}, {name: entryDate, var: entry_date}, {name: id, var: id}, {name: loType, var: lo_type}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: ourReference, var: our_reference}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: quoteId, var: quote_id}, {name: reference, var: reference}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unpaid, var: unpaid}, {name: vatTypeId, var: vat_type_id}, {name: yourReference, var: your_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ac_code: $ac_code, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, delivery_to: $delivery_to, details: $details, entry_date: $entry_date, id: $id, lo_type: $lo_type, net_goods: $net_goods, net_services: $net_services, note: $note, our_reference: $our_reference, proc_date: $proc_date, product_trans: $product_trans, quote_id: $quote_id, reference: $reference, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unpaid: $unpaid, vat_type_id: $vat_type_id, your_reference: $your_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Sales Invoice.
#
# DELETE /v1/salesInvoices/{id}
# Returns: record
# operationId: SalesInvoices_Delete
export def "sales-invoices-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Invoice to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/salesInvoices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Sales Invoice.
#
# GET /v1/salesInvoices/{id}
# Returns: record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>
export def "get-v1-sales-invoices-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesInvoices/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Sales Invoice.
#
# PUT /v1/salesInvoices/{id}
# Returns: record
# operationId: SalesInvoices_Put
export def "sales-invoices-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesInvoices/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acCode, var: ac_code}, {name: bookTranTypeId, var: book_tran_type_id}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: deliveryTo, var: delivery_to}, {name: details, var: details}, {name: entryDate, var: entry_date}, {name: id, var: body_id}, {name: loType, var: lo_type}, {name: netGoods, var: net_goods}, {name: netServices, var: net_services}, {name: note, var: note}, {name: ourReference, var: our_reference}, {name: procDate, var: proc_date}, {name: productTrans, var: product_trans}, {name: quoteId, var: quote_id}, {name: reference, var: reference}, {name: saleRepCode, var: sale_rep_code}, {name: saleRepId, var: sale_rep_id}, {name: timestamp, var: timestamp}, {name: total, var: total}, {name: totalNet, var: total_net}, {name: totalVAT, var: total_vat}, {name: unpaid, var: unpaid}, {name: vatTypeId, var: vat_type_id}, {name: yourReference, var: your_reference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ac_code: $ac_code, book_tran_type_id: $book_tran_type_id, custom_fields: $custom_fields, customer_id: $customer_id, delivery_to: $delivery_to, details: $details, entry_date: $entry_date, body_id: $body_id, lo_type: $lo_type, net_goods: $net_goods, net_services: $net_services, note: $note, our_reference: $our_reference, proc_date: $proc_date, product_trans: $product_trans, quote_id: $quote_id, reference: $reference, sale_rep_code: $sale_rep_code, sale_rep_id: $sale_rep_id, timestamp: $timestamp, total: $total, total_net: $total_net, total_vat: $total_vat, unpaid: $unpaid, vat_type_id: $vat_type_id, your_reference: $your_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's SaleRep. Filtering is forbidden. Ordering is allowed by "id".
#
# GET /v1/salesReps
# Returns: record<Count: int, Items: table<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string>, NextPageLink: string>
# operationId: SalesRep_Get
export def "sales-rep-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesReps"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new SaleRep.
#
# POST /v1/salesReps
# Returns: record
# operationId: SalesRep_Post
export def "sales-rep-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --company-id: int # format: int64
  --email: string
  --id: int # format: int64
  --name: string
  --phone: string
  --time-stamp: string # format: byte
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/salesReps"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: companyId, var: company_id}, {name: email, var: email}, {name: id, var: id}, {name: name, var: name}, {name: phone, var: phone}, {name: timeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, company_id: $company_id, email: $email, id: $id, name: $name, phone: $phone, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Sale Rep.
#
# PUT /v1/salesReps/batch
# Returns: record
# operationId: SalesRep_ProcessBatch
export def "sales-rep-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesReps/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Sale Rep.
#
# DELETE /v1/salesReps/{id}
# Returns: record
# operationId: SalesRep_Delete
export def "sales-rep-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sale Rep to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/salesReps/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single SaleRep.
#
# GET /v1/salesReps/{id}
# Returns: record<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string>
export def "get-v1-sales-reps-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/salesReps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Sale Rep.
#
# PUT /v1/salesReps/{id}
# Returns: record
# operationId: SalesRep_Put
export def "sales-rep-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --company-id: int # format: int64
  --email: string
  --body-id: int # format: int64 (spec name: id)
  --name: string
  --phone: string
  --time-stamp: string # format: byte
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/salesReps/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: companyId, var: company_id}, {name: email, var: email}, {name: id, var: body_id}, {name: name, var: name}, {name: phone, var: phone}, {name: timeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, code: $code, company_id: $company_id, email: $email, body_id: $body_id, name: $name, phone: $phone, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Suppliers. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/suppliers
# Returns: record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string>
# operationId: Suppliers_Get
export def "suppliers-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/suppliers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Supplier.
#
# POST /v1/suppliers
# Returns: record
# operationId: Suppliers_Post
export def "suppliers-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --e-ft-reference: string
  --email: string
  --fax: string
  --id: int # format: int64
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --postponed-accounting: oneof<nothing, bool>
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/suppliers"
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: additionalEmails, var: additional_emails}, {name: address, var: address}, {name: authCode, var: auth_code}, {name: bank, var: bank}, {name: businessIdentifierCode, var: business_identifier_code}, {name: code, var: code}, {name: contact, var: contact}, {name: eFTReference, var: e_ft_reference}, {name: email, var: email}, {name: fax, var: fax}, {name: id, var: id}, {name: internationalBankAccountNumber, var: international_bank_account_number}, {name: ledgerBalance, var: ledger_balance}, {name: mobile, var: mobile}, {name: name, var: name}, {name: openingBalance, var: opening_balance}, {name: openingBalances, var: opening_balances}, {name: ourCode, var: our_code}, {name: ownerTypeId, var: owner_type_id}, {name: phone, var: phone}, {name: postponedAccounting, var: postponed_accounting}, {name: timestamp, var: timestamp}, {name: vatAnalysisTypeId, var: vat_analysis_type_id}, {name: vatReg, var: vat_reg}, {name: vatType, var: vat_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, account_number: $account_number, additional_emails: $additional_emails, address: $address, auth_code: $auth_code, bank: $bank, business_identifier_code: $business_identifier_code, code: $code, contact: $contact, e_ft_reference: $e_ft_reference, email: $email, fax: $fax, id: $id, international_bank_account_number: $international_bank_account_number, ledger_balance: $ledger_balance, mobile: $mobile, name: $name, opening_balance: $opening_balance, opening_balances: $opening_balances, our_code: $our_code, owner_type_id: $owner_type_id, phone: $phone, postponed_accounting: $postponed_accounting, timestamp: $timestamp, vat_analysis_type_id: $vat_analysis_type_id, vat_reg: $vat_reg, vat_type: $vat_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Processes a batch of Suppliers.
#
# PUT /v1/suppliers/batch
# Returns: record
# operationId: Suppliers_ProcessBatch
export def "suppliers-process-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/suppliers/batch"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing Supplier.
#
# DELETE /v1/suppliers/{id}
# Returns: record
# operationId: Suppliers_Delete
export def "suppliers-delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Supplier to remove. Should be encoded in Base64. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/suppliers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: timestamp, var: timestamp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a single Supplier. You may specify that Supplier's ledger balance should be calculated.
#
# GET /v1/suppliers/{id}
# Returns: record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>
export def "get-v1-suppliers-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --need-balance: oneof<nothing, bool> # If "true" then Supplier's ledger balance will be calculated; otherwise balance will be returned as 0.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/suppliers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: needBalance, var: need_balance}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, need_balance: $need_balance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Supplier.
#
# PUT /v1/suppliers/{id}
# Returns: record
# operationId: Suppliers_Put
export def "suppliers-put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --e-ft-reference: string
  --email: string
  --fax: string
  --body-id: int # format: int64 (spec name: id)
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --postponed-accounting: oneof<nothing, bool>
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/suppliers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: additionalEmails, var: additional_emails}, {name: address, var: address}, {name: authCode, var: auth_code}, {name: bank, var: bank}, {name: businessIdentifierCode, var: business_identifier_code}, {name: code, var: code}, {name: contact, var: contact}, {name: eFTReference, var: e_ft_reference}, {name: email, var: email}, {name: fax, var: fax}, {name: id, var: body_id}, {name: internationalBankAccountNumber, var: international_bank_account_number}, {name: ledgerBalance, var: ledger_balance}, {name: mobile, var: mobile}, {name: name, var: name}, {name: openingBalance, var: opening_balance}, {name: openingBalances, var: opening_balances}, {name: ourCode, var: our_code}, {name: ownerTypeId, var: owner_type_id}, {name: phone, var: phone}, {name: postponedAccounting, var: postponed_accounting}, {name: timestamp, var: timestamp}, {name: vatAnalysisTypeId, var: vat_analysis_type_id}, {name: vatReg, var: vat_reg}, {name: vatType, var: vat_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, account_name: $account_name, account_number: $account_number, additional_emails: $additional_emails, address: $address, auth_code: $auth_code, bank: $bank, business_identifier_code: $business_identifier_code, code: $code, contact: $contact, e_ft_reference: $e_ft_reference, email: $email, fax: $fax, body_id: $body_id, international_bank_account_number: $international_bank_account_number, ledger_balance: $ledger_balance, mobile: $mobile, name: $name, opening_balance: $opening_balance, opening_balances: $opening_balances, our_code: $our_code, owner_type_id: $owner_type_id, phone: $phone, postponed_accounting: $postponed_accounting, timestamp: $timestamp, vat_analysis_type_id: $vat_analysis_type_id, vat_reg: $vat_reg, vat_type: $vat_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Supplier's account transactions.
#
# GET /v1/suppliers/{itemId}/accountTrans
# Returns: table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string>
# operationId: Suppliers_GetAccountTrans
export def "suppliers-get-account-trans" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/suppliers/{itemId}/accountTrans"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a Supplier's opening balances, calculated for the next periods: current month, one month old, two months old, three and more months old.
#
# GET /v1/suppliers/{itemId}/openingBalance
# Returns: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>
# operationId: Suppliers_GetOpeningBalance
export def "suppliers-get-opening-balance" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/suppliers/{itemId}/openingBalance"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Supplier's opening balance transactions.
#
# GET /v1/suppliers/{itemId}/openingBalanceList
# Returns: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>>
# operationId: Suppliers_GetOpeningBalanceList
export def "suppliers-get-opening-balance-list" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/suppliers/{itemId}/openingBalanceList"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's User Defined Fields. Supports OData querying protocol. Filtering is allowed by "categoryTypeId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/userDefinedFields
# Returns: record<Count: int, Items: table<categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string>
# operationId: UserDefinedFields_Get
export def "user-defined-fields-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userDefinedFields"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of global Vat Analysis Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatAnalysisTypes
# Returns: record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>
# operationId: VatAnalysisTypes_Get
export def "vat-analysis-types-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/vatAnalysisTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of global Vat Categories. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatCategories
# Returns: record<Count: int, Items: table<description: string, id: int>, NextPageLink: string>
# operationId: VatCategories_Get
export def "vat-categories-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/vatCategories"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Process Vat Rates
#
# POST /v1/vatCategories/vatRates
# Returns: record
# operationId: VatCategories_ProcessVatRates
export def "vat-categories-process-vat-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/vatCategories/vatRates"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of company's Vat Rates. Supports OData querying protocol. Filtering is allowed by "vatCategoryId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/vatRates
# Returns: record<Count: int, Items: table<id: int, isActive: bool, isDefault: bool, orderIndex: int, percentage: float, timestamp: string, vatCategoryId: int>, NextPageLink: string>
# operationId: VatRates_Get
export def "vat-rates-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/vatRates"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of global Vat Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatTypes
# Returns: record<Count: int, Items: table<code: string, description: string, id: int, isNotApplicable: bool, isOnlyZero: bool>, NextPageLink: string>
# operationId: VatTypes_Get
export def "vat-types-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/vatTypes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
