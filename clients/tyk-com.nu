# Auto-generated client for Gateway REST API v1.9
# Source: https://api.apis.guru/v2/specs/tyk.com/1.9/swagger.json
# Auth: --token flag or $env.GATEWAY_REST_API_TOKEN

const CLIENT = {
  base_url: "https://tyk.local"
  token_env_var: "GATEWAY_REST_API_TOKEN"
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

def base-url-completer [] { ["https://tyk.local"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-tyk-apis: "table<api_id: string, auth: record<auth_header_name: string, use_cookie: bool, use_param: bool>, definition: record<key: string, location: string>, enable_jwt: bool, enable_signature_checking: bool, hmac_allowed_clock_skew: float, id: string, jwt_identity_base_field: string, jwt_policy_field_name: string, jwt_signing_method: string, jwt_source: string, name: string, notifications: record<oauth_on_keychange_url: string, shared_secret: string>, oauth_meta: record<allowed_access_types: list, allowed_authorize_types: list, auth_login_redirect: string>, org_id: string, slug: string, uptime_tests: record<CORS: record, active: bool, allowed_ips: list, cache_options: record, check_list: list, config: record, custom_middleware: record, do_not_track: string, domain: string, dont_set_quota_on_create: bool, enable_batch_request_support: bool, enable_ip_whitelisting: bool, event_handlers: record, expire_analytics_after: float, proxy: record, response_processors: list, session_lifetime: float, tags: list>, use_basic_auth: bool, use_keyless: bool, use_oauth2: bool, version_data: record<not_versioned: bool, versions: record>>"
    post-tyk-apis: "record<action: string, key: string, status: string>"
    delete-tyk-apis-api-id: "record<action: string, key: string, status: string>"
    get-tyk-apis-api-id: "record<api_id: string, auth: record<auth_header_name: string, use_cookie: bool, use_param: bool>, definition: record<key: string, location: string>, enable_jwt: bool, enable_signature_checking: bool, hmac_allowed_clock_skew: float, id: string, jwt_identity_base_field: string, jwt_policy_field_name: string, jwt_signing_method: string, jwt_source: string, name: string, notifications: record<oauth_on_keychange_url: string, shared_secret: string>, oauth_meta: record<allowed_access_types: list<string>, allowed_authorize_types: list<string>, auth_login_redirect: string>, org_id: string, slug: string, uptime_tests: record<CORS: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, debug: bool, enable: bool, exposed_headers: list, max_age: float, options_passthrough: bool>, active: bool, allowed_ips: list<string>, cache_options: record<cache_all_safe_requests: bool, cache_timeout: float, enable_cache: bool, enable_upstream_cache_control: bool>, check_list: list<record>, config: record<expire_utime_after: float, recheck_wait: float, service_discovery: record>, custom_middleware: record<post: list, pre: list, response: list>, do_not_track: string, domain: string, dont_set_quota_on_create: bool, enable_batch_request_support: bool, enable_ip_whitelisting: bool, event_handlers: record, expire_analytics_after: float, proxy: record<check_host_against_uptime_tests: bool, enable_load_balancing: bool, listen_path: string, preserve_host_header: bool, service_discovery: record, strip_listen_path: bool, target_list: list, target_url: string>, response_processors: list<record>, session_lifetime: float, tags: list<string>>, use_basic_auth: bool, use_keyless: bool, use_oauth2: bool, version_data: record<not_versioned: bool, versions: record>>"
    put-tyk-apis-api-id: "record<action: string, key: string, status: string>"
    get-tyk-health: "record<average_requests_per_second: float, average_upstream_latency: float, key_failures_per_second: float, quota_violations_per_second: float, throttle_requests_per_second: float>"
    get-tyk-keys: "record<keys: list<string>>"
    post-tyk-keys-create: "record<action: string, key: string, status: string>"
    delete-tyk-keys-key-id: "record<action: string, key: string, status: string>"
    post-tyk-keys-key-id: "record<action: string, key: string, status: string>"
    put-tyk-keys-key-id: "record<action: string, key: string, status: string>"
    post-tyk-oauth-authorize-client: "record<access_token: string, code: string, expires_in: float, redirect_to: string, token_type: string>"
    post-tyk-oauth-clients-create: "record<client_id: string, redirect_uri: string, secret: string>"
    get-tyk-oauth-clients-api-id: "table<client_id: string, redirect_uri: string, secret: string>"
    delete-tyk-oauth-clients-api-id-client-id: "record<action: string, key: string, status: string>"
    delete-tyk-oauth-refresh-key-id: "record<action: string, key: string, status: string>"
    get-tyk-reload: "record<error: string, status: string>"
    get-tyk-reload-group: "record<error: string, status: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-tyk-apis" "post-tyk-apis" "delete-tyk-apis-api-id" "get-tyk-apis-api-id" "put-tyk-apis-api-id" "get-tyk-health" "get-tyk-keys" "post-tyk-keys-create" "delete-tyk-keys-key-id" "post-tyk-keys-key-id" "put-tyk-keys-key-id" "post-tyk-oauth-authorize-client" "post-tyk-oauth-clients-create" "get-tyk-oauth-clients-api-id" "delete-tyk-oauth-clients-api-id-client-id" "delete-tyk-oauth-refresh-key-id" "get-tyk-reload" "get-tyk-reload-group" "commands"] | sort) } | get name | first)
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

# Gets a list of *API Definition* objects that are currently live on the gateway
#
# GET /tyk/apis/
# Returns: table<api_id: string, auth: record<auth_header_name: string, use_cookie: bool, use_param: bool>, definition: record<key: string, location: string>, enable_jwt: bool, enable_signature_checking: bool, hmac_allowed_clock_skew: float, id: string, jwt_identity_base_field: string, jwt_policy_field_name: string, jwt_signing_method: string, jwt_source: string, name: string, notifications: record<oauth_on_keychange_url: string, shared_secret: string>, oauth_meta: record<allowed_access_types: list, allowed_authorize_types: list, auth_login_redirect: string>, org_id: string, slug: string, uptime_tests: record<CORS: record, active: bool, allowed_ips: list, cache_options: record, check_list: list, config: record, custom_middleware: record, do_not_track: string, domain: string, dont_set_quota_on_create: bool, enable_batch_request_support: bool, enable_ip_whitelisting: bool, event_handlers: record, expire_analytics_after: float, proxy: record, response_processors: list, session_lifetime: float, tags: list>, use_basic_auth: bool, use_keyless: bool, use_oauth2: bool, version_data: record<not_versioned: bool, versions: record>>
export def "get-tyk-apis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tyk/apis/"
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an *API Definition* object
#
# POST /tyk/apis/
# Returns: record<action: string, key: string, status: string>
export def "post-tyk-apis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string
  --auth: record # shape: {auth_header_name?: string, use_cookie?: bool, use_param?: bool}
  --definition: record # shape: {key?: string, location?: string}
  --enable-jwt: oneof<nothing, bool>
  --enable-signature-checking: oneof<nothing, bool>
  --hmac-allowed-clock-skew: float
  --id: string
  --jwt-identity-base-field: string
  --jwt-policy-field-name: string
  --jwt-signing-method: string
  --jwt-source: string
  --name: string
  --notifications: record # shape: {oauth_on_keychange_url?: string, shared_secret?: string}
  --oauth-meta: record # shape: {allowed_access_types?: list<string>, allowed_authorize_types?: list<string>, auth_login_redirect?: string}
  --org-id: string
  --slug: string
  --uptime-tests: record # shape: {CORS?: record, active?: bool, allowed_ips?: list<string>, cache_options?: record, check_list?: list, config?: record, custom_middleware?: record, do_not_track?: string, domain?: string, dont_set_quota_on_create?: bool, enable_batch_request_support?: bool, enable_ip_whitelisting?: bool, event_handlers?: record, expire_analytics_after?: float, proxy?: record, response_processors?: list, session_lifetime?: float, tags?: list<string>}
  --use-basic-auth: oneof<nothing, bool>
  --use-keyless: oneof<nothing, bool>
  --use-oauth2: oneof<nothing, bool>
  --version-data: record # shape: {not_versioned?: bool, versions?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tyk/apis/"
    body: {content_type: "application/json", kind: json, fields: [{name: api_id, var: api_id}, {name: auth, var: auth}, {name: definition, var: definition}, {name: enable_jwt, var: enable_jwt}, {name: enable_signature_checking, var: enable_signature_checking}, {name: hmac_allowed_clock_skew, var: hmac_allowed_clock_skew}, {name: id, var: id}, {name: jwt_identity_base_field, var: jwt_identity_base_field}, {name: jwt_policy_field_name, var: jwt_policy_field_name}, {name: jwt_signing_method, var: jwt_signing_method}, {name: jwt_source, var: jwt_source}, {name: name, var: name}, {name: notifications, var: notifications}, {name: oauth_meta, var: oauth_meta}, {name: org_id, var: org_id}, {name: slug, var: slug}, {name: uptime_tests, var: uptime_tests}, {name: use_basic_auth, var: use_basic_auth}, {name: use_keyless, var: use_keyless}, {name: use_oauth2, var: use_oauth2}, {name: version_data, var: version_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, auth: $auth, definition: $definition, enable_jwt: $enable_jwt, enable_signature_checking: $enable_signature_checking, hmac_allowed_clock_skew: $hmac_allowed_clock_skew, id: $id, jwt_identity_base_field: $jwt_identity_base_field, jwt_policy_field_name: $jwt_policy_field_name, jwt_signing_method: $jwt_signing_method, jwt_source: $jwt_source, name: $name, notifications: $notifications, oauth_meta: $oauth_meta, org_id: $org_id, slug: $slug, uptime_tests: $uptime_tests, use_basic_auth: $use_basic_auth, use_keyless: $use_keyless, use_oauth2: $use_oauth2, version_data: $version_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an *API Definition* object, if it exists
#
# DELETE /tyk/apis/{apiID}
# Returns: record<action: string, key: string, status: string>
export def "delete-tyk-apis-api-id" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tyk/apis/{apiID}"
    path_params: [{name: apiID, var: api_id}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an *API Definition* object, if it exists
#
# GET /tyk/apis/{apiID}
# Returns: record<api_id: string, auth: record<auth_header_name: string, use_cookie: bool, use_param: bool>, definition: record<key: string, location: string>, enable_jwt: bool, enable_signature_checking: bool, hmac_allowed_clock_skew: float, id: string, jwt_identity_base_field: string, jwt_policy_field_name: string, jwt_signing_method: string, jwt_source: string, name: string, notifications: record<oauth_on_keychange_url: string, shared_secret: string>, oauth_meta: record<allowed_access_types: list<string>, allowed_authorize_types: list<string>, auth_login_redirect: string>, org_id: string, slug: string, uptime_tests: record<CORS: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, debug: bool, enable: bool, exposed_headers: list, max_age: float, options_passthrough: bool>, active: bool, allowed_ips: list<string>, cache_options: record<cache_all_safe_requests: bool, cache_timeout: float, enable_cache: bool, enable_upstream_cache_control: bool>, check_list: list<record>, config: record<expire_utime_after: float, recheck_wait: float, service_discovery: record>, custom_middleware: record<post: list, pre: list, response: list>, do_not_track: string, domain: string, dont_set_quota_on_create: bool, enable_batch_request_support: bool, enable_ip_whitelisting: bool, event_handlers: record, expire_analytics_after: float, proxy: record<check_host_against_uptime_tests: bool, enable_load_balancing: bool, listen_path: string, preserve_host_header: bool, service_discovery: record, strip_listen_path: bool, target_list: list, target_url: string>, response_processors: list<record>, session_lifetime: float, tags: list<string>>, use_basic_auth: bool, use_keyless: bool, use_oauth2: bool, version_data: record<not_versioned: bool, versions: record>>
export def "get-tyk-apis-api-id" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tyk/apis/{apiID}"
    path_params: [{name: apiID, var: api_id}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an *API Definition* object, if it exists
#
# PUT /tyk/apis/{apiID}
# Returns: record<action: string, key: string, status: string>
export def "put-tyk-apis-api-id" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
  --body-api-id: string # (spec name: api_id)
  --auth: record # shape: {auth_header_name?: string, use_cookie?: bool, use_param?: bool}
  --definition: record # shape: {key?: string, location?: string}
  --enable-jwt: oneof<nothing, bool>
  --enable-signature-checking: oneof<nothing, bool>
  --hmac-allowed-clock-skew: float
  --id: string
  --jwt-identity-base-field: string
  --jwt-policy-field-name: string
  --jwt-signing-method: string
  --jwt-source: string
  --name: string
  --notifications: record # shape: {oauth_on_keychange_url?: string, shared_secret?: string}
  --oauth-meta: record # shape: {allowed_access_types?: list<string>, allowed_authorize_types?: list<string>, auth_login_redirect?: string}
  --org-id: string
  --slug: string
  --uptime-tests: record # shape: {CORS?: record, active?: bool, allowed_ips?: list<string>, cache_options?: record, check_list?: list, config?: record, custom_middleware?: record, do_not_track?: string, domain?: string, dont_set_quota_on_create?: bool, enable_batch_request_support?: bool, enable_ip_whitelisting?: bool, event_handlers?: record, expire_analytics_after?: float, proxy?: record, response_processors?: list, session_lifetime?: float, tags?: list<string>}
  --use-basic-auth: oneof<nothing, bool>
  --use-keyless: oneof<nothing, bool>
  --use-oauth2: oneof<nothing, bool>
  --version-data: record # shape: {not_versioned?: bool, versions?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tyk/apis/{apiID}"
    path_params: [{name: apiID, var: api_id}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: api_id, var: body_api_id}, {name: auth, var: auth}, {name: definition, var: definition}, {name: enable_jwt, var: enable_jwt}, {name: enable_signature_checking, var: enable_signature_checking}, {name: hmac_allowed_clock_skew, var: hmac_allowed_clock_skew}, {name: id, var: id}, {name: jwt_identity_base_field, var: jwt_identity_base_field}, {name: jwt_policy_field_name, var: jwt_policy_field_name}, {name: jwt_signing_method, var: jwt_signing_method}, {name: jwt_source, var: jwt_source}, {name: name, var: name}, {name: notifications, var: notifications}, {name: oauth_meta, var: oauth_meta}, {name: org_id, var: org_id}, {name: slug, var: slug}, {name: uptime_tests, var: uptime_tests}, {name: use_basic_auth, var: use_basic_auth}, {name: use_keyless, var: use_keyless}, {name: use_oauth2, var: use_oauth2}, {name: version_data, var: version_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_tyk_authorization: $x_tyk_authorization, body_api_id: $body_api_id, auth: $auth, definition: $definition, enable_jwt: $enable_jwt, enable_signature_checking: $enable_signature_checking, hmac_allowed_clock_skew: $hmac_allowed_clock_skew, id: $id, jwt_identity_base_field: $jwt_identity_base_field, jwt_policy_field_name: $jwt_policy_field_name, jwt_signing_method: $jwt_signing_method, jwt_source: $jwt_source, name: $name, notifications: $notifications, oauth_meta: $oauth_meta, org_id: $org_id, slug: $slug, uptime_tests: $uptime_tests, use_basic_auth: $use_basic_auth, use_keyless: $use_keyless, use_oauth2: $use_oauth2, version_data: $version_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health check values for an API if it is being recorded
#
# GET /tyk/health/
# Returns: record<average_requests_per_second: float, average_upstream_latency: float, key_failures_per_second: float, quota_violations_per_second: float, throttle_requests_per_second: float>
export def "get-tyk-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # API ID to query (required, format: string)
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tyk/health/"
    query: [{name: api_id, var: api_id, required: true}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of *key* IDs (will only work with non-hashed installations)
#
# GET /tyk/keys/
# Returns: record<keys: list<string>>
export def "get-tyk-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # Back-end to target (required, format: string)
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tyk/keys/"
    query: [{name: api_id, var: api_id, required: true}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new *API token* with the *session object* defined in the body
#
# POST /tyk/keys/create
# Returns: record<action: string, key: string, status: string>
export def "post-tyk-keys-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --suppress-reset: float # Adding the `suppress_reset` parameter and setting it to `1`, will cause Tyk to not reset the quota limit that is in the current live quota manager. By default Tyk will reset the quota in the live quota manager (initialising it) when ADDing a key. Adding the `suppress_reset` flag to the URL parameters will avoid this behaviour. (format: integer)
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
  --access-rights: record
  --allowance: float
  --apply-policy-id: string
  --basic-auth-data: record # shape: {hash_type?: ""|"bcrypt", password?: string}
  --expires: float
  --hmac-enabled: oneof<nothing, bool>
  --hmac-string: string
  --is-inactive: oneof<nothing, bool>
  --jwt-data: record # shape: {secret?: string}
  --meta-data: record
  --monitor: record # shape: {trigger_limits?: list<string>}
  --oauth-client-id: string
  --org-id: string
  --per: float
  --quota-max: float
  --quota-remaining: float
  --quota-renewal-rate: string
  --quota-renews: float
  --rate: float
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tyk/keys/create"
    query: [{name: suppress_reset, var: suppress_reset}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_rights, var: access_rights}, {name: allowance, var: allowance}, {name: apply_policy_id, var: apply_policy_id}, {name: basic_auth_data, var: basic_auth_data}, {name: expires, var: expires}, {name: hmac_enabled, var: hmac_enabled}, {name: hmac_string, var: hmac_string}, {name: is_inactive, var: is_inactive}, {name: jwt_data, var: jwt_data}, {name: meta_data, var: meta_data}, {name: monitor, var: monitor}, {name: oauth_client_id, var: oauth_client_id}, {name: org_id, var: org_id}, {name: per, var: per}, {name: quota_max, var: quota_max}, {name: quota_remaining, var: quota_remaining}, {name: quota_renewal_rate, var: quota_renewal_rate}, {name: quota_renews, var: quota_renews}, {name: rate, var: rate}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    suppress_reset: $suppress_reset, x_tyk_authorization: $x_tyk_authorization, access_rights: $access_rights, allowance: $allowance, apply_policy_id: $apply_policy_id, basic_auth_data: $basic_auth_data, expires: $expires, hmac_enabled: $hmac_enabled, hmac_string: $hmac_string, is_inactive: $is_inactive, jwt_data: $jwt_data, meta_data: $meta_data, monitor: $monitor, oauth_client_id: $oauth_client_id, org_id: $org_id, per: $per, quota_max: $quota_max, quota_remaining: $quota_remaining, quota_renewal_rate: $quota_renewal_rate, quota_renews: $quota_renews, rate: $rate, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove this *API token* from the gateway, this will completely destroy the token and metadata associated with the token and instantly stop access from being granted
#
# DELETE /tyk/keys/{keyId}
# Returns: record<action: string, key: string, status: string>
export def "delete-tyk-keys-key-id" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # Back-end to target (required, format: string)
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tyk/keys/{keyId}"
    path_params: [{name: keyId, var: key_id}]
    query: [{name: api_id, var: api_id, required: true}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_id: $key_id, api_id: $api_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a pre-specified *API token* with the *session object* defined in the body, this operatin creates a custom token that dsoes not use the gateway naming convention for tokens
#
# POST /tyk/keys/{keyId}
# Returns: record<action: string, key: string, status: string>
export def "post-tyk-keys-key-id" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
  --access-rights: record
  --allowance: float
  --apply-policy-id: string
  --basic-auth-data: record # shape: {hash_type?: ""|"bcrypt", password?: string}
  --expires: float
  --hmac-enabled: oneof<nothing, bool>
  --hmac-string: string
  --is-inactive: oneof<nothing, bool>
  --jwt-data: record # shape: {secret?: string}
  --meta-data: record
  --monitor: record # shape: {trigger_limits?: list<string>}
  --oauth-client-id: string
  --org-id: string
  --per: float
  --quota-max: float
  --quota-remaining: float
  --quota-renewal-rate: string
  --quota-renews: float
  --rate: float
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tyk/keys/{keyId}"
    path_params: [{name: keyId, var: key_id}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_rights, var: access_rights}, {name: allowance, var: allowance}, {name: apply_policy_id, var: apply_policy_id}, {name: basic_auth_data, var: basic_auth_data}, {name: expires, var: expires}, {name: hmac_enabled, var: hmac_enabled}, {name: hmac_string, var: hmac_string}, {name: is_inactive, var: is_inactive}, {name: jwt_data, var: jwt_data}, {name: meta_data, var: meta_data}, {name: monitor, var: monitor}, {name: oauth_client_id, var: oauth_client_id}, {name: org_id, var: org_id}, {name: per, var: per}, {name: quota_max, var: quota_max}, {name: quota_remaining, var: quota_remaining}, {name: quota_renewal_rate, var: quota_renewal_rate}, {name: quota_renews, var: quota_renews}, {name: rate, var: rate}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_id: $key_id, x_tyk_authorization: $x_tyk_authorization, access_rights: $access_rights, allowance: $allowance, apply_policy_id: $apply_policy_id, basic_auth_data: $basic_auth_data, expires: $expires, hmac_enabled: $hmac_enabled, hmac_string: $hmac_string, is_inactive: $is_inactive, jwt_data: $jwt_data, meta_data: $meta_data, monitor: $monitor, oauth_client_id: $oauth_client_id, org_id: $org_id, per: $per, quota_max: $quota_max, quota_remaining: $quota_remaining, quota_renewal_rate: $quota_renewal_rate, quota_renews: $quota_renews, rate: $rate, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an *API token* with the *session object* defined in the body, this operatin overwrites the existing object
#
# PUT /tyk/keys/{keyId}
# Returns: record<action: string, key: string, status: string>
export def "put-tyk-keys-key-id" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --suppress-reset: float # Adding the `suppress_reset` parameter and setting it to `1`, will cause Tyk to not reset the quota limit that is in the current live quota manager. By default Tyk will reset the quota in the live quota manager (initialising it) when ADDing a key. Adding the `suppress_reset` flag to the URL parameters will avoid this behaviour. (format: integer)
  --api-id: string # Back-end to target (required, format: string)
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
  --access-rights: record
  --allowance: float
  --apply-policy-id: string
  --basic-auth-data: record # shape: {hash_type?: ""|"bcrypt", password?: string}
  --expires: float
  --hmac-enabled: oneof<nothing, bool>
  --hmac-string: string
  --is-inactive: oneof<nothing, bool>
  --jwt-data: record # shape: {secret?: string}
  --meta-data: record
  --monitor: record # shape: {trigger_limits?: list<string>}
  --oauth-client-id: string
  --org-id: string
  --per: float
  --quota-max: float
  --quota-remaining: float
  --quota-renewal-rate: string
  --quota-renews: float
  --rate: float
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tyk/keys/{keyId}"
    path_params: [{name: keyId, var: key_id}]
    query: [{name: suppress_reset, var: suppress_reset}, {name: api_id, var: api_id, required: true}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_rights, var: access_rights}, {name: allowance, var: allowance}, {name: apply_policy_id, var: apply_policy_id}, {name: basic_auth_data, var: basic_auth_data}, {name: expires, var: expires}, {name: hmac_enabled, var: hmac_enabled}, {name: hmac_string, var: hmac_string}, {name: is_inactive, var: is_inactive}, {name: jwt_data, var: jwt_data}, {name: meta_data, var: meta_data}, {name: monitor, var: monitor}, {name: oauth_client_id, var: oauth_client_id}, {name: org_id, var: org_id}, {name: per, var: per}, {name: quota_max, var: quota_max}, {name: quota_remaining, var: quota_remaining}, {name: quota_renewal_rate, var: quota_renewal_rate}, {name: quota_renews, var: quota_renews}, {name: rate, var: rate}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_id: $key_id, suppress_reset: $suppress_reset, api_id: $api_id, x_tyk_authorization: $x_tyk_authorization, access_rights: $access_rights, allowance: $allowance, apply_policy_id: $apply_policy_id, basic_auth_data: $basic_auth_data, expires: $expires, hmac_enabled: $hmac_enabled, hmac_string: $hmac_string, is_inactive: $is_inactive, jwt_data: $jwt_data, meta_data: $meta_data, monitor: $monitor, oauth_client_id: $oauth_client_id, org_id: $org_id, per: $per, quota_max: $quota_max, quota_remaining: $quota_remaining, quota_renewal_rate: $quota_renewal_rate, quota_renews: $quota_renews, rate: $rate, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The final request from an authorising party for a redirect URI during the Tyk OAuth flow
#
# POST /tyk/oauth/authorize-client/
# Returns: record<access_token: string, code: string, expires_in: float, redirect_to: string, token_type: string>
export def "post-tyk-oauth-authorize-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
  response_type: string # Should be provided by requesting client as part of authorisation request, this should be either `code` or `token` depending on the methods you have specified for the API
  client_id: string # Should be provided by requesting client as part of authorisation request. The Client ID that is making the request
  redirect_uri: string # Should be provided by requesting client as part of authorisation request. Must match with the record stored with Tyk
  key_rules: string # A string representation of a *Session Object (form-encoded)*. This should be provided by your application in order to apply any quotas or rules to the key
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tyk/oauth/authorize-client/"
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: response_type, var: response_type}, {name: client_id, var: client_id}, {name: redirect_uri, var: redirect_uri}, {name: key_rules, var: key_rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_tyk_authorization: $x_tyk_authorization, response_type: $response_type, client_id: $client_id, redirect_uri: $redirect_uri, key_rules: $key_rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new OAuth client
#
# POST /tyk/oauth/clients/create
# Returns: record<client_id: string, redirect_uri: string, secret: string>
export def "post-tyk-oauth-clients-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
  --api-id: string
  --redirect-uri: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tyk/oauth/clients/create"
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: api_id, var: api_id}, {name: redirect_uri, var: redirect_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_tyk_authorization: $x_tyk_authorization, api_id: $api_id, redirect_uri: $redirect_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of OAuth clients bound to this back end
#
# GET /tyk/oauth/clients/{apiId}
# Returns: table<client_id: string, redirect_uri: string, secret: string>
export def "get-tyk-oauth-clients-api-id" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tyk/oauth/clients/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the OAuth client
#
# DELETE /tyk/oauth/clients/{apiId}/{clientId}
# Returns: record<action: string, key: string, status: string>
export def "delete-tyk-oauth-clients-api-id-client-id" [
  api_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tyk/oauth/clients/{apiId}/{clientId}"
    path_params: [{name: apiId, var: api_id}, {name: clientId, var: client_id}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, client_id: $client_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invalidate a refresh token
#
# DELETE /tyk/oauth/refresh/{keyId}
# Returns: record<action: string, key: string, status: string>
export def "delete-tyk-oauth-refresh-key-id" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # API ID (required)
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tyk/oauth/refresh/{keyId}"
    path_params: [{name: keyId, var: key_id}]
    query: [{name: apiID, var: api_id, required: true}]
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_id: $key_id, api_id: $api_id, x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Will reload the targetted gateway
#
# GET /tyk/reload/
# Returns: record<error: string, status: string>
export def "get-tyk-reload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tyk/reload/"
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Will reload the cluster via the targeted gateway
#
# GET /tyk/reload/group
# Returns: record<error: string, status: string>
export def "get-tyk-reload-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-tyk-authorization: string # tyk gateway shared secret (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tyk/reload/group"
    header: [{name: x-tyk-authorization, var: x_tyk_authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_tyk_authorization: $x_tyk_authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
