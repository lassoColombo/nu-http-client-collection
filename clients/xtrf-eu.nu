# Auto-generated client for XTRF Home Portal API v2.0
# Source: https://api.apis.guru/v2/specs/xtrf.eu/2.0/openapi.json
# Auth: --token flag or $env.XTRF_HOME_PORTAL_API_TOKEN

const CLIENT = {
  base_url: "https://presentation.s.xtrf.eu/home-api"
  token_env_var: "XTRF_HOME_PORTAL_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-auth-access-token, in: header, header_name: X-AUTH-ACCESS-TOKEN, prefix: ""}
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

def base-url-completer [] { ["https://presentation.s.xtrf.eu/home-api"] }
def auth-scheme-completer [] { ["x-auth-access-token"] }

# Completers for enum parameters
def type-completer [] { ["CREDIT_NOTE" "DRAFT" "FINAL"] }
def status-completer [] { ["BILL_CREATED" "CONFIRMED" "POSTPONED" "SENT" "TO_BE_SENT"] }
def status-completer-1 [] { ["ACTIVE" "INACTIVE" "POTENTIAL"] }
def gender-completer [] { ["FEMALE" "MALE"] }
def type-completer-1 [] { ["CHECKBOX" "DATE" "DATE_AND_TIME" "MULTI_SELECTION" "NUMBER" "SELECTION" "TEXT"] }
def category-completer [] { ["DICTIONARY" "LOG_FILE" "REF" "TM" "WORKFILE"] }
def rate-origin-completer [] { ["AUTOCALCULATED" "FILLED_MANUALLY" "PRICE_LIST" "PRICE_PROFILE"] }
def type-completer-2 [] { ["CAT" "SIMPLE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-all: "table<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record, finalDate: record, invoiceDate: record, paymentDueDate: record>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: list<record>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>"
    create-1: "record<invoiceUrl: string, invoicesIds: list<int>>"
    download-documents: "record<url: string>"
    get-all-ids: "list<int>"
    send-reminders: "record<numberOfSentEmails: int>"
    get-by-id: "record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>"
    get-dates: "record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>"
    get-document: "record<url: string>"
    duplicate: "record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>"
    duplicate-as-pro-forma: "record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>"
    get-payment-terms: "record<description: string, name: string>"
    get-payments: "table<amount: float, notes: string, paymentDate: record<value: int>, paymentMethodId: int>"
    get-all-2: "table<currencyId: int, dates: record<draftDate: record, finalDate: record, invoiceUploadedDate: record, paymentDueDate: record>, draftNumber: string, finalNumber: string, id: int, internalNumber: string, jobsNetValue: float, notesFromProvider: string, paymentStatus: string, providerId: int, status: string, totalGross: float, totalGrossInWords: string, totalNetto: float>"
    create-4: "record<invoiceUrl: string, invoicesIds: list<int>>"
    get-all-ids-3: "list<int>"
    get-by-id-3: "record<currencyId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceUploadedDate: record<value: int>, paymentDueDate: record<value: int>>, draftNumber: string, finalNumber: string, id: int, internalNumber: string, jobsNetValue: float, notesFromProvider: string, paymentStatus: string, providerId: int, status: string, totalGross: float, totalGrossInWords: string, totalNetto: float>"
    get-document-1: "record<url: string>"
    get-payments-1: "table<amount: float, notes: string, paymentDate: record<value: int>, paymentMethodId: int>"
    browse-json: "record"
    browse-csv: "record"
    get-current-view-details: "record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int>"
    get-view-details: "record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int>"
    select-view-and-get-its-details: "record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int>"
    get-views-brief: "record<access: record<change: bool, delete: bool>, list: table<access: record, current: bool, id: int, lastModification: record, mine: bool, name: string, owner: string>>"
    create: "record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>, viewId: int>"
    get-browser-views-view-id: "record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>>"
    put-browser-views-view-id: "record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>>"
    get-columns: "table<name: string, settings: record>"
    update-columns: "table<name: string, settings: record>"
    delete-column: "table<name: string, settings: record>"
    get-column-settings: "record"
    update-column-settings: "record"
    get-filter: "record<properties: list<record>>"
    update-filter: "record<properties: list<record>>"
    update-filter-property: "record"
    get-order: "record<column: string, type: string>"
    update-order: "record<column: string, type: string>"
    get-permissions: "record<sharedGroups: list<int>>"
    update-permissions: "record<sharedGroups: list<int>>"
    get-settings: "record<local: record<maxLinesInRow: int, maxRows: int>, name: string>"
    update-settings: "record<local: record<maxLinesInRow: int, maxRows: int>, name: string>"
    get-local-settings: "record<maxLinesInRow: int, maxRows: int>"
    update-local-settings: "record<maxLinesInRow: int, maxRows: int>"
    get-all-names-with-ids: "table<id: int, name: string>"
    create-3: "record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string>"
    get-all-ids-2: "list<int>"
    create-2: "record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>"
    generate-single-use-sign-in-token: "record<token: string, url: string>"
    get-all-ids-1: "list<int>"
    get-by-id-1: "record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>"
    update-1: "record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>"
    get-contact: "record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string>"
    update-contact: "record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string>"
    get-custom-fields: "table<key: string, name: string, type: string, value: record>"
    update-custom-fields: "table<key: string, name: string, type: string, value: record>"
    get-by-id-2: "record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string>"
    update-2: "record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string>"
    get-address: "record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>"
    update-address: "record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>"
    get-categories: "list<int>"
    update-categories: "list<int>"
    get-contact-1: "record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>"
    update-contact-1: "record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>"
    get-correspondence-address: "record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>"
    update-correspondence-address: "record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>"
    get-custom-fields-1: "table<key: string, name: string, type: string, value: record>"
    update-custom-fields-1: "table<key: string, name: string, type: string, value: record>"
    get-custom-field: "record<key: string, name: string, type: string, value: record>"
    update-custom-field: "record<key: string, name: string, type: string, value: record>"
    get-industries: "list<int>"
    update-industries: "list<int>"
    get-active: "record<calculationUnit: table<active: bool, canBeUsedInCatAnalysis: bool, catQuantityConversionExpression: string, default: bool, exchangeRatio: float, fileStatsConversionExpression: string, id: int, jobTypeIds: list, name: string, preferred: bool, symbol: string, timeToQuantityConversionExpression: string, type: string>, category: table<active: bool, default: bool, id: int, name: string, preferred: bool, supportedClasses: list>, country: table<active: bool, default: bool, id: int, name: string, preferred: bool, symbol: string>, currency: table<active: bool, default: bool, id: int, isoCode: string, name: string, preferred: bool, symbol: string>, industry: table<active: bool, default: bool, id: int, name: string, preferred: bool>, jobType: table<active: bool, calculationUnitIds: list, default: bool, filesNeeded: bool, id: int, name: string, preferred: bool, providedByClient: bool, relationToLanguage: string, vendorProductivity: float, vendorProductivityCalculationUnitId: int>, language: table<active: bool, default: bool, id: int, iso6391: string, iso6392: string, name: string, preferred: bool, symbol: string>, leadSource: table<active: bool, availableForCustomer: bool, availableForProvider: bool, default: bool, id: int, name: string, preferred: bool>, personDepartment: table<active: bool, default: bool, id: int, name: string, preferred: bool>, personPosition: table<active: bool, default: bool, id: int, name: string, preferred: bool>, province: table<active: bool, countryId: int, default: bool, id: int, name: string, preferred: bool>, specialization: table<active: bool, default: bool, id: int, name: string, preferred: bool>>"
    get-all-1: "record<calculationUnit: table<active: bool, canBeUsedInCatAnalysis: bool, catQuantityConversionExpression: string, default: bool, exchangeRatio: float, fileStatsConversionExpression: string, id: int, jobTypeIds: list, name: string, preferred: bool, symbol: string, timeToQuantityConversionExpression: string, type: string>, category: table<active: bool, default: bool, id: int, name: string, preferred: bool, supportedClasses: list>, country: table<active: bool, default: bool, id: int, name: string, preferred: bool, symbol: string>, currency: table<active: bool, default: bool, id: int, isoCode: string, name: string, preferred: bool, symbol: string>, industry: table<active: bool, default: bool, id: int, name: string, preferred: bool>, jobType: table<active: bool, calculationUnitIds: list, default: bool, filesNeeded: bool, id: int, name: string, preferred: bool, providedByClient: bool, relationToLanguage: string, vendorProductivity: float, vendorProductivityCalculationUnitId: int>, language: table<active: bool, default: bool, id: int, iso6391: string, iso6392: string, name: string, preferred: bool, symbol: string>, leadSource: table<active: bool, availableForCustomer: bool, availableForProvider: bool, default: bool, id: int, name: string, preferred: bool>, personDepartment: table<active: bool, default: bool, id: int, name: string, preferred: bool>, personPosition: table<active: bool, default: bool, id: int, name: string, preferred: bool>, province: table<active: bool, countryId: int, default: bool, id: int, name: string, preferred: bool>, specialization: table<active: bool, default: bool, id: int, name: string, preferred: bool>>"
    get-by-iso-code: "record<dateFrom: record<value: int>, exchangeRate: string, lastModification: record<value: int>, originDetails: string, publicationDate: record<value: int>>"
    get-active-by-type: "record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int>"
    get-all-by-type: "record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int>"
    get-by-type-and-id: "record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int>"
    get-job-details: "record<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list<string>, sharedReferenceFiles: list<string>, sharedWorkFiles: list<string>>, id: string, idNumber: string, languages: table<sourceLanguageId: int, specializationId: int, targetLanguageId: int>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record<canVerifyFiles: bool, isScripted: bool>>, vendorId: int, vendorPriceProfileId: int>"
    get-job-files: "record<inputFiles: table<content: string, name: string, token: string, url: string>, outputFiles: table<content: string, name: string, token: string, url: string>>"
    get-job-files-1: "record<categoryKey: string, id: int, lastModifiedOn: int, name: string, size: int>"
    get-license: "record<clientId: string, parameters: record>"
    post-macros-macro-id-run: "record<actionId: string, resultUrl: string, statusUrl: string>"
    create-5: "record<categoriesIds: list<int>, contactPersonId: int, contacts: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicProject: bool, name: string, projectId: string, projectManagerId: int, specializationId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>>"
    get-all-ids-6: "list<int>"
    get-by-id-7: "record<categoriesIds: list<int>, contactPersonId: int, contacts: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicProject: bool, name: string, projectId: string, projectManagerId: int, specializationId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>>"
    get-contacts: "record<additionalIds: list<int>, primaryId: int, sendBackToId: int>"
    update-contacts: "record<additionalIds: list<int>, primaryId: int, sendBackToId: int>"
    get-custom-fields-5: "table<key: string, name: string, type: string, value: record>"
    update-custom-fields-3: "table<key: string, name: string, type: string, value: record>"
    get-dates-1: "record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>"
    update-dates-1: "record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>"
    get-finance: "record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>"
    create-payable: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    update-payable: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    create-receivable: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    update-receivable: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    get-instructions: "record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>"
    update-instructions-1: "record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>"
    create-language-combination: "record<sourceLanguageId: int, targetLanguageId: int>"
    create-task: "record<clientTaskPONumber: string, customFields: table<key: string, name: string, type: string, value: record>, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<invoiceable: bool>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, jobs: record<jobCount: int, jobIds: list<int>>, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, name: string, people: record<customerContacts: record<additionalIds: list, primaryId: int, sendBackToId: int>, responsiblePersons: record<projectCoordinatorId: int, projectManagerId: int>>, projectId: int, quoteId: int>"
    get-all-ids-5: "list<int>"
    get-all-ids-4: "list<int>"
    get-by-id-4: "record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, gender: string, id: int, lastName: string, motherTonguesIds: list<int>, name: string, positionId: int, providerId: int>"
    get-contact-2: "record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string>"
    get-custom-fields-2: "table<key: string, name: string, type: string, value: record>"
    send-invitations: "record<alreadyRegisteredPersonsCount: int, invitedPersonsCount: int, providersWithAlreadyRegisteredPersonCount: int, providersWithInvitedPersonCount: int, providersWithoutPersonCount: int>"
    get-by-id-5: "record<billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, competencies: record<languageCombinations: list<record>>, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, leadSourceId: int, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, gender: string, id: int, lastName: string, motherTonguesIds: list, name: string, positionId: int, providerId: int>, status: string>"
    get-address-1: "record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>"
    get-competencies: "record<languageCombinations: table<sourceLanguageId: int, targetLanguageId: int>>"
    get-contact-3: "record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>"
    get-correspondence-address-1: "record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>"
    get-custom-fields-3: "table<key: string, name: string, type: string, value: record>"
    send-invitations-1: "record<alreadyRegisteredPersonsCount: int, invitedPersonsCount: int, providersWithAlreadyRegisteredPersonCount: int, providersWithInvitedPersonCount: int, providersWithoutPersonCount: int>"
    get-all-ids-7: "list<int>"
    get-by-id-8: "record<automaticallyAcceptSentQuote: bool, categoriesIds: list<int>, contactPersonId: int, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<createdOn: record<value: int>, deadline: record<value: int>, offerExpiry: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicQuote: bool, name: string, quoteId: string, salesPersonId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>>"
    get-custom-fields-6: "table<key: string, name: string, type: string, value: record>"
    update-custom-fields-4: "table<key: string, name: string, type: string, value: record>"
    get-dates-2: "record<createdOn: record<value: int>, deadline: record<value: int>, offerExpiry: record<value: int>, startDate: record<value: int>>"
    get-finance-1: "record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>"
    create-payable-1: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    update-payable-1: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    create-receivable-1: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    update-receivable-1: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    get-instructions-1: "record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>"
    update-instructions-2: "record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>"
    create-language-combination-1: "record<sourceLanguageId: int, targetLanguageId: int>"
    create-task-1: "record<clientTaskPONumber: string, customFields: table<key: string, name: string, type: string, value: record>, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<invoiceable: bool>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, jobs: record<jobCount: int, jobIds: list<int>>, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, name: string, people: record<customerContacts: record<additionalIds: list, primaryId: int, sendBackToId: int>, responsiblePersons: record<projectCoordinatorId: int, projectManagerId: int>>, projectId: int, quoteId: int>"
    export-to-xml: "record<url: string>"
    import-from-xml: "record<currentSystemVersion: string, importedReportsNames: list<string>, invalidReportsNames: list<string>, targetSystemVersion: string>"
    generate-csv: "record<url: string>"
    generate-printer-friendly: "record<url: string>"
    get-all-active: "record<active: bool, default: bool, id: int, name: string, preferred: bool>"
    get-all-3: "record<active: bool, default: bool, id: int, name: string, preferred: bool>"
    get-all-4: "table<embed: string, event: string, filter: string, subscriptionId: string, url: string>"
    subscribe: "string"
    are-hooks-supported: "bool"
    update-client-task-po-number: "record<value: string>"
    get-contacts-1: "record<additionalIds: list<int>, primaryId: int, sendBackToId: int>"
    update-contacts-1: "record<additionalIds: list<int>, primaryId: int, sendBackToId: int>"
    get-custom-fields-7: "table<key: string, name: string, type: string, value: record>"
    update-custom-fields-5: "table<key: string, name: string, type: string, value: record>"
    get-dates-3: "record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>"
    update-dates-2: "record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>"
    get-task-files: "record<bundles: record, inputFiles: record<logFiles: list<record>, referenceFiles: list<record>, terminology: list<record>, tm: list<record>, workFiles: list<record>>, jobs: table<files: record, id: int, idNumber: string, name: string>, outputFiles: table<content: string, name: string, token: string, url: string>>"
    get-instructions-2: "record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>"
    update-instructions-3: "record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>"
    update-name: "record<value: string>"
    get-progress: "record<phase: string, status: string>"
    get-all-names-with-ids-1: "table<id: int, name: string>"
    get-me: "record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string>"
    get-time-zone: "record<displayName: string, id: string, offset: int>"
    get-by-id-6: "record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string>"
    update-3: "record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string>"
    get-custom-fields-4: "table<key: string, name: string, type: string, value: record>"
    update-custom-fields-2: "table<key: string, name: string, type: string, value: record>"
    get-custom-field-1: "record<key: string, name: string, type: string, value: record>"
    update-custom-field-1: "record<key: string, name: string, type: string, value: record>"
    get-file-by-id-1: "record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    get-delivered-files: "table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    add-file-links: "record<files: list<string>>"
    upload-file-1: "record<fileId: string>"
    get-shared-reference-files: "table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    share-as-reference-files: "record<statuses: table<fileId: string, message: string, successful: bool>>"
    get-shared-work-files: "table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    share-as-work-files: "record<statuses: table<fileId: string, message: string, successful: bool>>"
    stop-sharing: "record<statuses: table<fileId: string, message: string, successful: bool>>"
    create-6: "record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>"
    archive: "record<archiveUrl: string>"
    get-file-by-id-2: "record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    get-by-external-id-1: "record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>"
    get-by-id-9: "record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>"
    add-job-to-process: "record<projectCreatedInCatToolOrCreationIsQueued: bool>"
    get-cat-tool-project-info: "record<projectCreatedInCatToolOrCreationIsQueued: bool>"
    get-contacts-2: "record<additionalIds: list<int>, primaryId: int>"
    update-contacts-2: "record<additionalIds: list<int>, primaryId: int>"
    get-custom-fields-8: "table<key: string, name: string, type: string, value: record>"
    get-files: "table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    add-file-links-1: "record<files: list<string>>"
    get-deliverable-files: "table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    upload-file-2: "record<fileId: string>"
    get-finance-2: "record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>"
    create-payable-2: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    update-payable-2: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    create-receivable-2: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    update-receivable-2: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    get-jobs: "table<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list, sharedReferenceFiles: list, sharedWorkFiles: list>, id: string, idNumber: string, languages: list<record>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record>, vendorId: int, vendorPriceProfileId: int>"
    get-process-id: "record<projectCreatedInCatToolOrCreationIsQueued: bool>"
    create-7: "record<budgetCode: string, businessDays: int, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, createdOn: int, documents: record<projectConfirmationStatus: string>, expectedDeliveryDate: int, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicQuote: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, origin: string, people: record<projectManagerId: int>, quoteExpiry: int, quoteId: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>"
    archive-1: "record<archiveUrl: string>"
    get-file-by-id-3: "record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    get-by-id-10: "record<budgetCode: string, businessDays: int, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, createdOn: int, documents: record<projectConfirmationStatus: string>, expectedDeliveryDate: int, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicQuote: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, origin: string, people: record<projectManagerId: int>, quoteExpiry: int, quoteId: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>"
    get-contacts-3: "record<additionalIds: list<int>, primaryId: int>"
    update-contacts-3: "record<additionalIds: list<int>, primaryId: int>"
    get-custom-fields-9: "table<key: string, name: string, type: string, value: record>"
    get-files-1: "table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>"
    upload-file-3: "record<fileId: string>"
    get-finance-3: "record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>"
    create-payable-3: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    update-payable-3: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>"
    create-receivable-3: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    update-receivable-3: "record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>"
    get-jobs-1: "table<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list, sharedReferenceFiles: list, sharedWorkFiles: list>, id: string, idNumber: string, languages: list<record>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record>, vendorId: int, vendorPriceProfileId: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-all" "create-1" "download-documents" "get-all-ids" "send-reminders" "delete-1" "get-by-id" "get-dates" "get-document" "duplicate" "duplicate-as-pro-forma" "get-payment-terms" "get-payments" "create-payment" "send-reminder" "delete-2" "get-all-2" "create-4" "get-all-ids-3" "delete-6" "get-by-id-3" "get-document-1" "get-payments-1" "create-payment-1" "send" "set-status" "delete-7" "browse-json" "browse-csv" "get-current-view-details" "get-view-details" "select-view-and-get-its-details" "get-views-brief" "create" "delete" "get-browser-views-view-id" "put-browser-views-view-id" "get-columns" "update-columns" "delete-column" "get-column-settings" "update-column-settings" "get-filter" "update-filter" "update-filter-property" "get-order" "update-order" "get-permissions" "update-permissions" "get-settings" "update-settings" "get-local-settings" "update-local-settings" "get-all-names-with-ids" "create-3" "get-all-ids-2" "create-2" "generate-single-use-sign-in-token" "get-all-ids-1" "delete-3" "get-by-id-1" "update-1" "get-contact" "update-contact" "get-custom-fields" "update-custom-fields" "delete-4" "delete-5" "get-by-id-2" "update-2" "get-address" "update-address" "get-categories" "update-categories" "get-contact-1" "update-contact-1" "get-correspondence-address" "update-correspondence-address" "get-custom-fields-1" "update-custom-fields-1" "get-custom-field" "update-custom-field" "get-industries" "update-industries" "get-active" "get-all-1" "get-by-iso-code" "create-exchange-rate" "get-active-by-type" "get-all-by-type" "get-by-type-and-id" "upload-file" "get-job-details" "update-dates" "get-job-files" "assign-file-to-job-output" "get-job-files-1" "update-instructions" "change-status" "assign-vendor" "get-license" "refresh" "post-macros-macro-id-run" "create-5" "get-file-by-id" "get-all-ids-6" "delete-12" "get-by-id-7" "get-contacts" "update-contacts" "get-custom-fields-5" "update-custom-fields-3" "get-dates-1" "update-dates-1" "get-finance" "create-payable" "delete-payable" "update-payable" "create-receivable" "delete-receivable" "update-receivable" "get-instructions" "update-instructions-1" "create-language-combination" "create-task" "get-all-ids-5" "get-all-ids-4" "delete-8" "get-by-id-4" "get-contact-2" "get-custom-fields-2" "send-invitations" "delete-9" "delete-10" "get-by-id-5" "get-address-1" "get-competencies" "get-contact-3" "get-correspondence-address-1" "get-custom-fields-3" "send-invitations-1" "get-all-ids-7" "delete-13" "get-by-id-8" "send-1" "get-custom-fields-6" "update-custom-fields-4" "get-dates-2" "get-finance-1" "create-payable-1" "delete-payable-1" "update-payable-1" "create-receivable-1" "delete-receivable-1" "update-receivable-1" "get-instructions-1" "update-instructions-2" "create-language-combination-1" "post-quotes-quote-id-start" "create-task-1" "export-to-xml" "import-from-xml" "delete-11" "duplicate-1" "set-preferred" "generate-csv" "generate-printer-friendly" "get-all-active" "get-all-3" "get-all-4" "subscribe" "are-hooks-supported" "unsubscribe" "delete-14" "update-client-task-po-number" "get-contacts-1" "update-contacts-1" "get-custom-fields-7" "update-custom-fields-5" "get-dates-3" "update-dates-2" "get-task-files" "add-file" "get-instructions-2" "update-instructions-3" "update-name" "get-progress" "start-1" "get-all-names-with-ids-1" "get-me" "get-time-zone" "get-by-id-6" "update-3" "get-custom-fields-4" "update-custom-fields-2" "get-custom-field-1" "update-custom-field-1" "change-password" "get-by-external-id" "get-file-by-id-1" "change-dates" "add-external-file-link" "get-delivered-files" "add-files" "add-file-links" "upload-file-1" "get-shared-reference-files" "share-as-reference-files" "get-shared-work-files" "share-as-work-files" "stop-sharing" "update-instructions-4" "change-status-1" "assign-vendor-1" "create-6" "archive" "get-file-by-id-2" "get-file-content-by-id" "get-by-external-id-1" "get-by-id-9" "add-job-to-process" "get-cat-tool-project-info" "get-contacts-2" "update-contacts-2" "update-client-deadline" "update-client-notes" "update-client-reference-number" "get-custom-fields-8" "update-custom-field-2" "get-files" "add-files-1" "add-external-file-links" "add-file-links-1" "get-deliverable-files" "upload-file-2" "get-finance-2" "create-payable-2" "delete-payable-2" "update-payable-2" "create-receivable-2" "delete-receivable-2" "update-receivable-2" "update-internal-notes" "get-jobs" "update-ordered-on" "get-process-id" "update-source-language" "update-specialization" "change-status-2" "update-target-languages" "update-vendor-instructions" "update-volume" "create-7" "archive-1" "get-file-by-id-3" "get-file-content-by-id-1" "get-by-id-10" "update-business-days" "get-contacts-3" "update-contacts-3" "update-client-notes-1" "update-client-reference-number-1" "get-custom-fields-9" "update-custom-field-3" "update-expected-delivery-date" "get-files-1" "add-files-2" "upload-file-3" "get-finance-3" "create-payable-3" "delete-payable-3" "update-payable-3" "create-receivable-3" "delete-receivable-3" "update-receivable-3" "update-internal-notes-1" "get-jobs-1" "update-quote-expiry" "update-source-language-1" "update-specialization-1" "change-status-3" "update-target-languages-1" "update-vendor-instructions-1" "update-volume-1" "commands"] | sort) } | get name | first)
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

# Lists all client invoices in all statuses (including not ready and drafts) that have been updated since a specific date.
#
# GET /accounting/customers/invoices
# Returns: table<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record, finalDate: record, invoiceDate: record, paymentDueDate: record>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: list<record>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>
# operationId: getAll
export def "get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/customers/invoices"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new invoice.
#
# POST /accounting/customers/invoices
# Returns: record<invoiceUrl: string, invoicesIds: list<int>>
# operationId: create_1
export def "create-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --prepayments-ids: list<int>
  --tasks-ids: list<int>
  --type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/customers/invoices"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: prepaymentsIds, var: prepayments_ids}, {name: tasksIds, var: tasks_ids}, {name: type, var: type}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    prepayments_ids: $prepayments_ids, tasks_ids: $tasks_ids, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates client invoices' documents.
#
# POST /accounting/customers/invoices/documents
# Returns: record<url: string>
# operationId: downloadDocuments
export def "download-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/customers/invoices/documents"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns client invoices' internal identifiers.
#
# GET /accounting/customers/invoices/ids
# Returns: list<int>
# operationId: getAllIds
export def "get-all-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/customers/invoices/ids"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends reminders. Returns number of sent e-mails.
#
# POST /accounting/customers/invoices/sendReminders
# Returns: record<numberOfSentEmails: int>
# operationId: sendReminders
export def "send-reminders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/customers/invoices/sendReminders"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a client invoice.
#
# DELETE /accounting/customers/invoices/{invoiceId}
# operationId: delete_1
export def "delete-1" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounting/customers/invoices/{invoiceId}"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns client invoice details.
#
# GET /accounting/customers/invoices/{invoiceId}
# Returns: record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>
# operationId: getById
export def "get-by-id" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. tasks)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/customers/invoices/{invoiceId}"
    path_params: [{name: invoiceId, var: invoice_id}]
    query: [{name: embed, var: embed}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id, embed: $embed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns dates of a given client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/dates
# Returns: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>
# operationId: getDates
export def "get-dates" [
  invoice_id: int
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
    path: "/accounting/customers/invoices/{invoiceId}/dates"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates client invoice document (PDF).
#
# GET /accounting/customers/invoices/{invoiceId}/document
# Returns: record<url: string>
# operationId: getDocument
export def "get-document" [
  invoice_id: int
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
    path: "/accounting/customers/invoices/{invoiceId}/document"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate client invoice.
#
# POST /accounting/customers/invoices/{invoiceId}/duplicate
# Returns: record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>
# operationId: duplicate
export def "duplicate" [
  invoice_id: int
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
    method: post
    path: "/accounting/customers/invoices/{invoiceId}/duplicate"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate client invoice as pro forma.
#
# POST /accounting/customers/invoices/{invoiceId}/duplicate/proForma
# Returns: record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string>
# operationId: duplicateAsProForma
export def "duplicate-as-pro-forma" [
  invoice_id: int
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
    method: post
    path: "/accounting/customers/invoices/{invoiceId}/duplicate/proForma"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns payment terms of a given client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/paymentTerms
# Returns: record<description: string, name: string>
# operationId: getPaymentTerms
export def "get-payment-terms" [
  invoice_id: int
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
    path: "/accounting/customers/invoices/{invoiceId}/paymentTerms"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all payments for the client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/payments
# Returns: table<amount: float, notes: string, paymentDate: record<value: int>, paymentMethodId: int>
# operationId: getPayments
export def "get-payments" [
  invoice_id: int
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
    path: "/accounting/customers/invoices/{invoiceId}/payments"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new payment to the client invoice. The invoice payment status (Not Paid, Partially Paid, Fully Paid) is automatically recalculated.
#
# POST /accounting/customers/invoices/{invoiceId}/payments
# operationId: createPayment
export def "create-payment" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float
  --notes: string
  --payment-date: record # shape: {value?: int}
  --payment-method-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounting/customers/invoices/{invoiceId}/payments"
    path_params: [{name: invoiceId, var: invoice_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: amount, var: amount}, {name: notes, var: notes}, {name: paymentDate, var: payment_date}, {name: paymentMethodId, var: payment_method_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id, amount: $amount, notes: $notes, payment_date: $payment_date, payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends reminder.
#
# POST /accounting/customers/invoices/{invoiceId}/sendReminder
# operationId: sendReminder
export def "send-reminder" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/accounting/customers/invoices/{invoiceId}/sendReminder"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a customer payment.
#
# DELETE /accounting/customers/payments/{paymentId}
# operationId: delete_2
export def "delete-2" [
  payment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounting/customers/payments/{paymentId}"
    path_params: [{name: paymentId, var: payment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all vendor invoices in all statuses (including not ready and drafts) that have been updated since a specific date.
#
# GET /accounting/providers/invoices
# Returns: table<currencyId: int, dates: record<draftDate: record, finalDate: record, invoiceUploadedDate: record, paymentDueDate: record>, draftNumber: string, finalNumber: string, id: int, internalNumber: string, jobsNetValue: float, notesFromProvider: string, paymentStatus: string, providerId: int, status: string, totalGross: float, totalGrossInWords: string, totalNetto: float>
# operationId: getAll_2
export def "get-all-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/providers/invoices"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new invoice.
#
# POST /accounting/providers/invoices
# Returns: record<invoiceUrl: string, invoicesIds: list<int>>
# operationId: create_4
export def "create-4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jobs-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/providers/invoices"
    body: {content_type: "application/json", kind: json, fields: [{name: jobsIds, var: jobs_ids}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    jobs_ids: $jobs_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns vendor invoices' internal identifiers.
#
# GET /accounting/providers/invoices/ids
# Returns: list<int>
# operationId: getAllIds_3
export def "get-all-ids-3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/providers/invoices/ids"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a provider invoice.
#
# DELETE /accounting/providers/invoices/{invoiceId}
# operationId: delete_6
export def "delete-6" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounting/providers/invoices/{invoiceId}"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns provider invoice details.
#
# GET /accounting/providers/invoices/{invoiceId}
# Returns: record<currencyId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceUploadedDate: record<value: int>, paymentDueDate: record<value: int>>, draftNumber: string, finalNumber: string, id: int, internalNumber: string, jobsNetValue: float, notesFromProvider: string, paymentStatus: string, providerId: int, status: string, totalGross: float, totalGrossInWords: string, totalNetto: float>
# operationId: getById_3
export def "get-by-id-3" [
  invoice_id: int
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
    path: "/accounting/providers/invoices/{invoiceId}"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates provider invoice document (PDF).
#
# GET /accounting/providers/invoices/{invoiceId}/document
# Returns: record<url: string>
# operationId: getDocument_1
export def "get-document-1" [
  invoice_id: int
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
    path: "/accounting/providers/invoices/{invoiceId}/document"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all payments for the vendor invoice.
#
# GET /accounting/providers/invoices/{invoiceId}/payments
# Returns: table<amount: float, notes: string, paymentDate: record<value: int>, paymentMethodId: int>
# operationId: getPayments_1
export def "get-payments-1" [
  invoice_id: int
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
    path: "/accounting/providers/invoices/{invoiceId}/payments"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new payment on the vendor account and assigns the payment to the invoice.
#
# POST /accounting/providers/invoices/{invoiceId}/payments
# operationId: createPayment_1
export def "create-payment-1" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float
  --notes: string
  --payment-date: record # shape: {value?: int}
  --payment-method-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounting/providers/invoices/{invoiceId}/payments"
    path_params: [{name: invoiceId, var: invoice_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: amount, var: amount}, {name: notes, var: notes}, {name: paymentDate, var: payment_date}, {name: paymentMethodId, var: payment_method_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id, amount: $amount, notes: $notes, payment_date: $payment_date, payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a provider invoice.
#
# POST /accounting/providers/invoices/{invoiceId}/send
# operationId: send
export def "send" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/accounting/providers/invoices/{invoiceId}/send"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes invoice status to given status.
#
# POST /accounting/providers/invoices/{invoiceId}/status
# operationId: setStatus
export def "set-status" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounting/providers/invoices/{invoiceId}/status"
    path_params: [{name: invoiceId, var: invoice_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    invoice_id: $invoice_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a provider payment.
#
# DELETE /accounting/providers/payments/{paymentId}
# operationId: delete_7
export def "delete-7" [
  payment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounting/providers/payments/{paymentId}"
    path_params: [{name: paymentId, var: payment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for data (ie. customer, task, etc) and returns it in a tabular form.
#
# GET /browser
# Returns: record
# operationId: browseJSON
export def "browse-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: int # view's identifier (format: int64)
  --page: int # format: int32, default: 0
  --additional-order: string
  --use-deferred-columns: string
  --max-rows: int # overrides view's default rows limit, supported values 10 to 1000 (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browser"
    query: [{name: viewId, var: view_id}, {name: page, var: page}, {name: additionalOrder, var: additional_order}, {name: useDeferredColumns, var: use_deferred_columns}, {name: maxRows, var: max_rows}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, page: $page, additional_order: $additional_order, use_deferred_columns: $use_deferred_columns, max_rows: $max_rows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for data (ie. customer, task, etc) and returns it in a CSV form.
#
# GET /browser/csv
# Returns: record
# operationId: browseCSV
export def "browse-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: int # view's identifier (format: int64)
  --separator: string # csv field separator
  --secondary-separator: string # secondary csv field separator
  --additional-order: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browser/csv"
    query: [{name: viewId, var: view_id}, {name: separator, var: separator}, {name: secondarySeparator, var: secondary_separator}, {name: additionalOrder, var: additional_order}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, separator: $separator, secondary_separator: $secondary_separator, additional_order: $additional_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current view's detailed information, suitable for browser.
#
# GET /browser/views/details/for/{className}
# Returns: record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int>
# operationId: getCurrentViewDetails
export def "get-current-view-details" [
  class_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browser/views/details/for/{className}"
    path_params: [{name: className, var: class_name}]
    query: [{name: placeName, var: place_name}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    class_name: $class_name, place_name: $place_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns view's detailed information, suitable for browser.
#
# GET /browser/views/details/for/{className}/{viewId}
# Returns: record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int>
# operationId: getViewDetails
export def "get-view-details" [
  class_name: string
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browser/views/details/for/{className}/{viewId}"
    path_params: [{name: className, var: class_name}, {name: viewId, var: view_id}]
    query: [{name: placeName, var: place_name}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    class_name: $class_name, view_id: $view_id, place_name: $place_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Selects given view as current and returns its detailed information, suitable for browser.
#
# POST /browser/views/details/for/{className}/{viewId}
# Returns: record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int>
# operationId: selectViewAndGetItsDetails
export def "select-view-and-get-its-details" [
  class_name: string
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name-denotes-specific-place-in-system-with-the-table: string # default: default
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/browser/views/details/for/{className}/{viewId}"
    path_params: [{name: className, var: class_name}, {name: viewId, var: view_id}]
    query: [{name: "place name (denotes specific place in system with the table)", var: place_name_denotes_specific_place_in_system_with_the_table}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    class_name: $class_name, view_id: $view_id, place_name_denotes_specific_place_in_system_with_the_table: $place_name_denotes_specific_place_in_system_with_the_table
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns views' brief.
#
# GET /browser/views/for/{className}
# Returns: record<access: record<change: bool, delete: bool>, list: table<access: record, current: bool, id: int, lastModification: record, mine: bool, name: string, owner: string>>
# operationId: getViewsBrief
export def "get-views-brief" [
  class_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browser/views/for/{className}"
    path_params: [{name: className, var: class_name}]
    query: [{name: placeName, var: place_name}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    class_name: $class_name, place_name: $place_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates view for given class.
#
# POST /browser/views/for/{className}
# Returns: record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>, viewId: int>
# operationId: create
export def "create" [
  class_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # item shape: {name?: string, settings?: record}
  --order: record # shape: {column?: string, type?: string}
  --permissions: record # shape: {sharedGroups?: list<int>}
  --settings: record # shape: {local?: record, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/browser/views/for/{className}"
    path_params: [{name: className, var: class_name}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: columns, var: columns}, {name: order, var: order}, {name: permissions, var: permissions}, {name: settings, var: settings}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    class_name: $class_name, columns: $columns, order: $order, permissions: $permissions, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a view.
#
# DELETE /browser/views/{viewId}
# operationId: delete
export def "delete" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/browser/views/{viewId}"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all view's information.
#
# GET /browser/views/{viewId}
# Returns: record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>>
# operationId: get
export def "get-browser-views-view-id" [
  view_id: int
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
    path: "/browser/views/{viewId}"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates all view's information.
#
# PUT /browser/views/{viewId}
# Returns: record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>>
# operationId: update
export def "put-browser-views-view-id" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # item shape: {name?: string, settings?: record}
  --order: record # shape: {column?: string, type?: string}
  --permissions: record # shape: {sharedGroups?: list<int>}
  --settings: record # shape: {local?: record, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}"
    path_params: [{name: viewId, var: view_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: columns, var: columns}, {name: order, var: order}, {name: permissions, var: permissions}, {name: settings, var: settings}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, columns: $columns, order: $order, permissions: $permissions, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns columns defined in view.
#
# GET /browser/views/{viewId}/columns
# Returns: table<name: string, settings: record>
# operationId: getColumns
export def "get-columns" [
  view_id: int
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
    path: "/browser/views/{viewId}/columns"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates columns in view.
#
# PUT /browser/views/{viewId}/columns
# Returns: table<name: string, settings: record>
# operationId: updateColumns
export def "update-columns" [
  view_id: int
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}/columns"
    path_params: [{name: viewId, var: view_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, accepts: scalar}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single column from view.
#
# DELETE /browser/views/{viewId}/columns/{columnName}
# Returns: table<name: string, settings: record>
# operationId: deleteColumn
export def "delete-column" [
  view_id: int
  column_name: string
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
    method: delete
    path: "/browser/views/{viewId}/columns/{columnName}"
    path_params: [{name: viewId, var: view_id}, {name: columnName, var: column_name}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, column_name: $column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns column's specific settings.
#
# GET /browser/views/{viewId}/columns/{columnName}/settings
# Returns: record
# operationId: getColumnSettings
export def "get-column-settings" [
  view_id: int
  column_name: string
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
    path: "/browser/views/{viewId}/columns/{columnName}/settings"
    path_params: [{name: viewId, var: view_id}, {name: columnName, var: column_name}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, column_name: $column_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates column's specific settings.
#
# PUT /browser/views/{viewId}/columns/{columnName}/settings
# Returns: record
# operationId: updateColumnSettings
export def "update-column-settings" [
  view_id: int
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}/columns/{columnName}/settings"
    path_params: [{name: viewId, var: view_id}, {name: columnName, var: column_name}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, column_name: $column_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns view's filter.
#
# GET /browser/views/{viewId}/filter
# Returns: record<properties: list<record>>
# operationId: getFilter
export def "get-filter" [
  view_id: int
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
    path: "/browser/views/{viewId}/filter"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates view's filter.
#
# PUT /browser/views/{viewId}/filter
# Returns: record<properties: list<record>>
# operationId: updateFilter
export def "update-filter" [
  view_id: int
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
    path: "/browser/views/{viewId}/filter"
    path_params: [{name: viewId, var: view_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, accepts: scalar}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates view's filter property.
#
# PUT /browser/views/{viewId}/filter/{filterProperty}
# Returns: record
# operationId: updateFilterProperty
export def "update-filter-property" [
  view_id: int
  filter_property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --settings: record
  --settings-present: oneof<nothing, bool>
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}/filter/{filterProperty}"
    path_params: [{name: viewId, var: view_id}, {name: filterProperty, var: filter_property}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: settings, var: settings}, {name: settingsPresent, var: settings_present}, {name: type, var: type}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, filter_property: $filter_property, name: $name, settings: $settings, settings_present: $settings_present, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns view's order settings.
#
# GET /browser/views/{viewId}/order
# Returns: record<column: string, type: string>
# operationId: getOrder
export def "get-order" [
  view_id: int
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
    path: "/browser/views/{viewId}/order"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates view's order settings.
#
# PUT /browser/views/{viewId}/order
# Returns: record<column: string, type: string>
# operationId: updateOrder
export def "update-order" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}/order"
    path_params: [{name: viewId, var: view_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: column, var: column}, {name: type, var: type}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, column: $column, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns view's permissions.
#
# GET /browser/views/{viewId}/permissions
# Returns: record<sharedGroups: list<int>>
# operationId: getPermissions
export def "get-permissions" [
  view_id: int
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
    path: "/browser/views/{viewId}/permissions"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates view's permissions.
#
# PUT /browser/views/{viewId}/permissions
# Returns: record<sharedGroups: list<int>>
# operationId: updatePermissions
export def "update-permissions" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shared-groups: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}/permissions"
    path_params: [{name: viewId, var: view_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sharedGroups, var: shared_groups}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, shared_groups: $shared_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns view's settings.
#
# GET /browser/views/{viewId}/settings
# Returns: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>
# operationId: getSettings
export def "get-settings" [
  view_id: int
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
    path: "/browser/views/{viewId}/settings"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates view's settings.
#
# PUT /browser/views/{viewId}/settings
# Returns: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>
# operationId: updateSettings
export def "update-settings" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: record # shape: {maxLinesInRow?: int, maxRows?: int}
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}/settings"
    path_params: [{name: viewId, var: view_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: local, var: local}, {name: name, var: name}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, local: $local, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns view's local settings (for current user).
#
# GET /browser/views/{viewId}/settings/local
# Returns: record<maxLinesInRow: int, maxRows: int>
# operationId: getLocalSettings
export def "get-local-settings" [
  view_id: int
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
    path: "/browser/views/{viewId}/settings/local"
    path_params: [{name: viewId, var: view_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates view's local settings (for current user).
#
# PUT /browser/views/{viewId}/settings/local
# Returns: record<maxLinesInRow: int, maxRows: int>
# operationId: updateLocalSettings
export def "update-local-settings" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-lines-in-row: int # format: int32
  --max-rows: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/browser/views/{viewId}/settings/local"
    path_params: [{name: viewId, var: view_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxLinesInRow, var: max_lines_in_row}, {name: maxRows, var: max_rows}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    view_id: $view_id, max_lines_in_row: $max_lines_in_row, max_rows: $max_rows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of simple clients representations
#
# GET /customers
# Returns: table<id: int, name: string>
# operationId: getAllNamesWithIds
export def "get-all-names-with-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only clients modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new client.
#
# POST /customers
# Returns: record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string>
# operationId: create_3
export def "create-3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-on-customer-server: string
  --accounting: record # shape: {taxNumbers?: list}
  --billing-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --branch-id: int # format: int64
  --categories-ids: list<int>
  --client-first-project-date: string # format: date-time
  --client-first-quote-date: string # format: date-time
  --client-last-project-date: string # format: date-time
  --client-last-quote-date: string # format: date-time
  --client-number-of-projects: int # format: int32
  --client-number-of-quotes: int # format: int32
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string, websites?: list<string>}
  --contract-number: string
  --correspondence-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --full-name: string
  --id: int # format: int64
  --id-number: string
  --industries-ids: list<int>
  --lead-source-id: int # format: int64
  --limit-access-to-people-responsible: oneof<nothing, bool>
  --name: string
  --notes: string
  --persons: list # item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list<int>, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
  --responsible-persons: record # shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
  --sales-notes: string
  --status: string@status-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers"
    body: {content_type: "application/json", kind: json, fields: [{name: accountOnCustomerServer, var: account_on_customer_server}, {name: accounting, var: accounting}, {name: billingAddress, var: billing_address}, {name: branchId, var: branch_id}, {name: categoriesIds, var: categories_ids}, {name: clientFirstProjectDate, var: client_first_project_date}, {name: clientFirstQuoteDate, var: client_first_quote_date}, {name: clientLastProjectDate, var: client_last_project_date}, {name: clientLastQuoteDate, var: client_last_quote_date}, {name: clientNumberOfProjects, var: client_number_of_projects}, {name: clientNumberOfQuotes, var: client_number_of_quotes}, {name: contact, var: contact}, {name: contractNumber, var: contract_number}, {name: correspondenceAddress, var: correspondence_address}, {name: customFields, var: custom_fields}, {name: fullName, var: full_name}, {name: id, var: id}, {name: idNumber, var: id_number}, {name: industriesIds, var: industries_ids}, {name: leadSourceId, var: lead_source_id}, {name: limitAccessToPeopleResponsible, var: limit_access_to_people_responsible}, {name: name, var: name}, {name: notes, var: notes}, {name: persons, var: persons}, {name: responsiblePersons, var: responsible_persons}, {name: salesNotes, var: sales_notes}, {name: status, var: status}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    account_on_customer_server: $account_on_customer_server, accounting: $accounting, billing_address: $billing_address, branch_id: $branch_id, categories_ids: $categories_ids, client_first_project_date: $client_first_project_date, client_first_quote_date: $client_first_quote_date, client_last_project_date: $client_last_project_date, client_last_quote_date: $client_last_quote_date, client_number_of_projects: $client_number_of_projects, client_number_of_quotes: $client_number_of_quotes, contact: $contact, contract_number: $contract_number, correspondence_address: $correspondence_address, custom_fields: $custom_fields, full_name: $full_name, id: $id, id_number: $id_number, industries_ids: $industries_ids, lead_source_id: $lead_source_id, limit_access_to_people_responsible: $limit_access_to_people_responsible, name: $name, notes: $notes, persons: $persons, responsible_persons: $responsible_persons, sales_notes: $sales_notes, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns clients' internal identifiers.
#
# GET /customers/ids
# Returns: list<int>
# operationId: getAllIds_2
export def "get-all-ids-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only clients modified since this timestamp (format: int64)
  --name-equals: string # exact name of client
  --email-equals: string # exact email of client
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers/ids"
    query: [{name: updatedSince, var: updated_since}, {name: nameEquals, var: name_equals}, {name: emailEquals, var: email_equals}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since, name_equals: $name_equals, email_equals: $email_equals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new person.
#
# POST /customers/persons
# Returns: record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>
# operationId: create_2
export def "create-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --customer-id: int # format: int64
  --first-project-date: string # format: date-time
  --first-quote-date: string # format: date-time
  --gender: string@gender-completer
  --id: int # format: int64
  --last-name: string
  --last-project-date: string # format: date-time
  --last-quote-date: string # format: date-time
  --mother-tongues-ids: list<int>
  --name: string
  --number-of-projects: int # format: int32
  --number-of-quotes: int # format: int32
  --position-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers/persons"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: active, var: active}, {name: contact, var: contact}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: firstProjectDate, var: first_project_date}, {name: firstQuoteDate, var: first_quote_date}, {name: gender, var: gender}, {name: id, var: id}, {name: lastName, var: last_name}, {name: lastProjectDate, var: last_project_date}, {name: lastQuoteDate, var: last_quote_date}, {name: motherTonguesIds, var: mother_tongues_ids}, {name: name, var: name}, {name: numberOfProjects, var: number_of_projects}, {name: numberOfQuotes, var: number_of_quotes}, {name: positionId, var: position_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    active: $active, contact: $contact, custom_fields: $custom_fields, customer_id: $customer_id, first_project_date: $first_project_date, first_quote_date: $first_quote_date, gender: $gender, id: $id, last_name: $last_name, last_project_date: $last_project_date, last_quote_date: $last_quote_date, mother_tongues_ids: $mother_tongues_ids, name: $name, number_of_projects: $number_of_projects, number_of_quotes: $number_of_quotes, position_id: $position_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a single use sign-in token.
#
# POST /customers/persons/accessToken
# Returns: record<token: string, url: string>
# operationId: generateSingleUseSignInToken
export def "generate-single-use-sign-in-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login-or-email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers/persons/accessToken"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: loginOrEmail, var: login_or_email}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    login_or_email: $login_or_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns persons' internal identifiers.
#
# GET /customers/persons/ids
# Returns: list<int>
# operationId: getAllIds_1
export def "get-all-ids-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only persons modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers/persons/ids"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a person.
#
# DELETE /customers/persons/{personId}
# operationId: delete_3
export def "delete-3" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/persons/{personId}"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns person details.
#
# GET /customers/persons/{personId}
# Returns: record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>
# operationId: getById_1
export def "get-by-id-1" [
  person_id: int
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
    path: "/customers/persons/{personId}"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing person.
#
# PUT /customers/persons/{personId}
# Returns: record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>
# operationId: update_1
export def "update-1" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --customer-id: int # format: int64
  --first-project-date: string # format: date-time
  --first-quote-date: string # format: date-time
  --gender: string@gender-completer
  --id: int # format: int64
  --last-name: string
  --last-project-date: string # format: date-time
  --last-quote-date: string # format: date-time
  --mother-tongues-ids: list<int>
  --name: string
  --number-of-projects: int # format: int32
  --number-of-quotes: int # format: int32
  --position-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/persons/{personId}"
    path_params: [{name: personId, var: person_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: active, var: active}, {name: contact, var: contact}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: firstProjectDate, var: first_project_date}, {name: firstQuoteDate, var: first_quote_date}, {name: gender, var: gender}, {name: id, var: id}, {name: lastName, var: last_name}, {name: lastProjectDate, var: last_project_date}, {name: lastQuoteDate, var: last_quote_date}, {name: motherTonguesIds, var: mother_tongues_ids}, {name: name, var: name}, {name: numberOfProjects, var: number_of_projects}, {name: numberOfQuotes, var: number_of_quotes}, {name: positionId, var: position_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id, active: $active, contact: $contact, custom_fields: $custom_fields, customer_id: $customer_id, first_project_date: $first_project_date, first_quote_date: $first_quote_date, gender: $gender, id: $id, last_name: $last_name, last_project_date: $last_project_date, last_quote_date: $last_quote_date, mother_tongues_ids: $mother_tongues_ids, name: $name, number_of_projects: $number_of_projects, number_of_quotes: $number_of_quotes, position_id: $position_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns contact of a given person.
#
# GET /customers/persons/{personId}/contact
# Returns: record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string>
# operationId: getContact
export def "get-contact" [
  person_id: int
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
    path: "/customers/persons/{personId}/contact"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates contact of a given person.
#
# PUT /customers/persons/{personId}/contact
# Returns: record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string>
# operationId: updateContact
export def "update-contact" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: record # emails — shape: {additional?: list<string>, primary: string}
  --fax: string # fax number
  --phones: list<string> # phones' numbers
  --sms: string # mobile phone for which SMS notifications will be sent (if configured)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/persons/{personId}/contact"
    path_params: [{name: personId, var: person_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: emails, var: emails}, {name: fax, var: fax}, {name: phones, var: phones}, {name: sms, var: sms}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id, emails: $emails, fax: $fax, phones: $phones, sms: $sms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given person.
#
# GET /customers/persons/{personId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields
export def "get-custom-fields" [
  person_id: int
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
    path: "/customers/persons/{personId}/customFields"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates custom fields of a given person.
#
# PUT /customers/persons/{personId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: updateCustomFields
export def "update-custom-fields" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/persons/{personId}/customFields"
    path_params: [{name: personId, var: person_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, accepts: scalar, fields: [{name: customFields, var: custom_fields}, {name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id, custom_fields: $custom_fields, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a customer price list.
#
# DELETE /customers/priceLists/{priceListId}
# operationId: delete_4
export def "delete-4" [
  price_list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/priceLists/{priceListId}"
    path_params: [{name: priceListId, var: price_list_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    price_list_id: $price_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a client.
#
# DELETE /customers/{customerId}
# operationId: delete_5
export def "delete-5" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/{customerId}"
    path_params: [{name: customerId, var: customer_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns client details.
#
# GET /customers/{customerId}
# Returns: record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string>
# operationId: getById_2
export def "get-by-id-2" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of additional fields which should be embedded in the response (available options: persons)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{customerId}"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: embed, var: embed}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, embed: $embed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing client.
#
# PUT /customers/{customerId}
# Returns: record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string>
# operationId: update_2
export def "update-2" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-on-customer-server: string
  --accounting: record # shape: {taxNumbers?: list}
  --billing-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --branch-id: int # format: int64
  --categories-ids: list<int>
  --client-first-project-date: string # format: date-time
  --client-first-quote-date: string # format: date-time
  --client-last-project-date: string # format: date-time
  --client-last-quote-date: string # format: date-time
  --client-number-of-projects: int # format: int32
  --client-number-of-quotes: int # format: int32
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string, websites?: list<string>}
  --contract-number: string
  --correspondence-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --full-name: string
  --id: int # format: int64
  --id-number: string
  --industries-ids: list<int>
  --lead-source-id: int # format: int64
  --limit-access-to-people-responsible: oneof<nothing, bool>
  --name: string
  --notes: string
  --persons: list # item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list<int>, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
  --responsible-persons: record # shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
  --sales-notes: string
  --status: string@status-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}"
    path_params: [{name: customerId, var: customer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountOnCustomerServer, var: account_on_customer_server}, {name: accounting, var: accounting}, {name: billingAddress, var: billing_address}, {name: branchId, var: branch_id}, {name: categoriesIds, var: categories_ids}, {name: clientFirstProjectDate, var: client_first_project_date}, {name: clientFirstQuoteDate, var: client_first_quote_date}, {name: clientLastProjectDate, var: client_last_project_date}, {name: clientLastQuoteDate, var: client_last_quote_date}, {name: clientNumberOfProjects, var: client_number_of_projects}, {name: clientNumberOfQuotes, var: client_number_of_quotes}, {name: contact, var: contact}, {name: contractNumber, var: contract_number}, {name: correspondenceAddress, var: correspondence_address}, {name: customFields, var: custom_fields}, {name: fullName, var: full_name}, {name: id, var: id}, {name: idNumber, var: id_number}, {name: industriesIds, var: industries_ids}, {name: leadSourceId, var: lead_source_id}, {name: limitAccessToPeopleResponsible, var: limit_access_to_people_responsible}, {name: name, var: name}, {name: notes, var: notes}, {name: persons, var: persons}, {name: responsiblePersons, var: responsible_persons}, {name: salesNotes, var: sales_notes}, {name: status, var: status}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, account_on_customer_server: $account_on_customer_server, accounting: $accounting, billing_address: $billing_address, branch_id: $branch_id, categories_ids: $categories_ids, client_first_project_date: $client_first_project_date, client_first_quote_date: $client_first_quote_date, client_last_project_date: $client_last_project_date, client_last_quote_date: $client_last_quote_date, client_number_of_projects: $client_number_of_projects, client_number_of_quotes: $client_number_of_quotes, contact: $contact, contract_number: $contract_number, correspondence_address: $correspondence_address, custom_fields: $custom_fields, full_name: $full_name, id: $id, id_number: $id_number, industries_ids: $industries_ids, lead_source_id: $lead_source_id, limit_access_to_people_responsible: $limit_access_to_people_responsible, name: $name, notes: $notes, persons: $persons, responsible_persons: $responsible_persons, sales_notes: $sales_notes, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address of a given client.
#
# GET /customers/{customerId}/address
# Returns: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>
# operationId: getAddress
export def "get-address" [
  customer_id: int
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
    path: "/customers/{customerId}/address"
    path_params: [{name: customerId, var: customer_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates address of a given client.
#
# PUT /customers/{customerId}/address
# Returns: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>
# operationId: updateAddress
export def "update-address" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # first line of address
  --address-line2: string # second line of address
  --city: string # city
  --country-id: int # country (format: int64)
  --postal-code: string # postal code
  --province-id: int # province (format: int64)
  --same-as-billing-address: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}/address"
    path_params: [{name: customerId, var: customer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addressLine1, var: address_line1}, {name: addressLine2, var: address_line2}, {name: city, var: city}, {name: countryId, var: country_id}, {name: postalCode, var: postal_code}, {name: provinceId, var: province_id}, {name: sameAsBillingAddress, var: same_as_billing_address}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, address_line1: $address_line1, address_line2: $address_line2, city: $city, country_id: $country_id, postal_code: $postal_code, province_id: $province_id, same_as_billing_address: $same_as_billing_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns categories of a given client.
#
# GET /customers/{customerId}/categories
# Returns: list<int>
# operationId: getCategories
export def "get-categories" [
  customer_id: int
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
    path: "/customers/{customerId}/categories"
    path_params: [{name: customerId, var: customer_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates categories of a given client.
#
# PUT /customers/{customerId}/categories
# Returns: list<int>
# operationId: updateCategories
export def "update-categories" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}/categories"
    path_params: [{name: customerId, var: customer_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns contact of a given client.
#
# GET /customers/{customerId}/contact
# Returns: record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>
# operationId: getContact_1
export def "get-contact-1" [
  customer_id: int
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
    path: "/customers/{customerId}/contact"
    path_params: [{name: customerId, var: customer_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates contact of a given client.
#
# PUT /customers/{customerId}/contact
# Returns: record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>
# operationId: updateContact_1
export def "update-contact-1" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: record # emails — shape: {additional?: list<string>, cc?: list<string>, primary: string}
  --fax: string # fax number
  --phones: list<string> # phones' numbers
  --sms: string # mobile phone for which SMS notifications will be sent (if configured)
  --websites: list<string> # websites
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}/contact"
    path_params: [{name: customerId, var: customer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}, {name: fax, var: fax}, {name: phones, var: phones}, {name: sms, var: sms}, {name: websites, var: websites}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, emails: $emails, fax: $fax, phones: $phones, sms: $sms, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns correspondence address of a given client.
#
# GET /customers/{customerId}/correspondenceAddress
# Returns: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>
# operationId: getCorrespondenceAddress
export def "get-correspondence-address" [
  customer_id: int
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
    path: "/customers/{customerId}/correspondenceAddress"
    path_params: [{name: customerId, var: customer_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates correspondence address of a given client.
#
# PUT /customers/{customerId}/correspondenceAddress
# Returns: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>
# operationId: updateCorrespondenceAddress
export def "update-correspondence-address" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # first line of address
  --address-line2: string # second line of address
  --city: string # city
  --country-id: int # country (format: int64)
  --postal-code: string # postal code
  --province-id: int # province (format: int64)
  --same-as-billing-address: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}/correspondenceAddress"
    path_params: [{name: customerId, var: customer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addressLine1, var: address_line1}, {name: addressLine2, var: address_line2}, {name: city, var: city}, {name: countryId, var: country_id}, {name: postalCode, var: postal_code}, {name: provinceId, var: province_id}, {name: sameAsBillingAddress, var: same_as_billing_address}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, address_line1: $address_line1, address_line2: $address_line2, city: $city, country_id: $country_id, postal_code: $postal_code, province_id: $province_id, same_as_billing_address: $same_as_billing_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given client.
#
# GET /customers/{customerId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_1
export def "get-custom-fields-1" [
  customer_id: int
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
    path: "/customers/{customerId}/customFields"
    path_params: [{name: customerId, var: customer_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates custom fields of a given client.
#
# PUT /customers/{customerId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: updateCustomFields_1
export def "update-custom-fields-1" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}/customFields"
    path_params: [{name: customerId, var: customer_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: customFields, var: custom_fields}, {name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, custom_fields: $custom_fields, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom field of a given client.
#
# GET /customers/{customerId}/customFields/{customFieldKey}
# Returns: record<key: string, name: string, type: string, value: record>
# operationId: getCustomField
export def "get-custom-field" [
  customer_id: int
  custom_field_key: string
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
    path: "/customers/{customerId}/customFields/{customFieldKey}"
    path_params: [{name: customerId, var: customer_id}, {name: customFieldKey, var: custom_field_key}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, custom_field_key: $custom_field_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates given custom field of a given client.
#
# PUT /customers/{customerId}/customFields/{customFieldKey}
# Returns: record<key: string, name: string, type: string, value: record>
# operationId: updateCustomField
export def "update-custom-field" [
  customer_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --type: string@type-completer-1
  --value: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}/customFields/{customFieldKey}"
    path_params: [{name: customerId, var: customer_id}, {name: customFieldKey, var: custom_field_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, custom_field_key: $custom_field_key, key: $key, name: $name, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns industries of a given client.
#
# GET /customers/{customerId}/industries
# Returns: list<int>
# operationId: getIndustries
export def "get-industries" [
  customer_id: int
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
    path: "/customers/{customerId}/industries"
    path_params: [{name: customerId, var: customer_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates industries of a given client.
#
# PUT /customers/{customerId}/industries
# Returns: list<int>
# operationId: updateIndustries
export def "update-industries" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{customerId}/industries"
    path_params: [{name: customerId, var: customer_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    customer_id: $customer_id, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns active dictionary entities for all types.
#
# GET /dictionaries/active
# Returns: record<calculationUnit: table<active: bool, canBeUsedInCatAnalysis: bool, catQuantityConversionExpression: string, default: bool, exchangeRatio: float, fileStatsConversionExpression: string, id: int, jobTypeIds: list, name: string, preferred: bool, symbol: string, timeToQuantityConversionExpression: string, type: string>, category: table<active: bool, default: bool, id: int, name: string, preferred: bool, supportedClasses: list>, country: table<active: bool, default: bool, id: int, name: string, preferred: bool, symbol: string>, currency: table<active: bool, default: bool, id: int, isoCode: string, name: string, preferred: bool, symbol: string>, industry: table<active: bool, default: bool, id: int, name: string, preferred: bool>, jobType: table<active: bool, calculationUnitIds: list, default: bool, filesNeeded: bool, id: int, name: string, preferred: bool, providedByClient: bool, relationToLanguage: string, vendorProductivity: float, vendorProductivityCalculationUnitId: int>, language: table<active: bool, default: bool, id: int, iso6391: string, iso6392: string, name: string, preferred: bool, symbol: string>, leadSource: table<active: bool, availableForCustomer: bool, availableForProvider: bool, default: bool, id: int, name: string, preferred: bool>, personDepartment: table<active: bool, default: bool, id: int, name: string, preferred: bool>, personPosition: table<active: bool, default: bool, id: int, name: string, preferred: bool>, province: table<active: bool, countryId: int, default: bool, id: int, name: string, preferred: bool>, specialization: table<active: bool, default: bool, id: int, name: string, preferred: bool>>
# operationId: getActive
export def "get-active" [
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
    path: "/dictionaries/active"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns dictionary entities for all types. Both active and not active ones.
#
# GET /dictionaries/all
# Returns: record<calculationUnit: table<active: bool, canBeUsedInCatAnalysis: bool, catQuantityConversionExpression: string, default: bool, exchangeRatio: float, fileStatsConversionExpression: string, id: int, jobTypeIds: list, name: string, preferred: bool, symbol: string, timeToQuantityConversionExpression: string, type: string>, category: table<active: bool, default: bool, id: int, name: string, preferred: bool, supportedClasses: list>, country: table<active: bool, default: bool, id: int, name: string, preferred: bool, symbol: string>, currency: table<active: bool, default: bool, id: int, isoCode: string, name: string, preferred: bool, symbol: string>, industry: table<active: bool, default: bool, id: int, name: string, preferred: bool>, jobType: table<active: bool, calculationUnitIds: list, default: bool, filesNeeded: bool, id: int, name: string, preferred: bool, providedByClient: bool, relationToLanguage: string, vendorProductivity: float, vendorProductivityCalculationUnitId: int>, language: table<active: bool, default: bool, id: int, iso6391: string, iso6392: string, name: string, preferred: bool, symbol: string>, leadSource: table<active: bool, availableForCustomer: bool, availableForProvider: bool, default: bool, id: int, name: string, preferred: bool>, personDepartment: table<active: bool, default: bool, id: int, name: string, preferred: bool>, personPosition: table<active: bool, default: bool, id: int, name: string, preferred: bool>, province: table<active: bool, countryId: int, default: bool, id: int, name: string, preferred: bool>, specialization: table<active: bool, default: bool, id: int, name: string, preferred: bool>>
# operationId: getAll_1
export def "get-all-1" [
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
    path: "/dictionaries/all"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns currency exchange rates.
#
# GET /dictionaries/currency/{isoCode}/exchangeRate
# Returns: record<dateFrom: record<value: int>, exchangeRate: string, lastModification: record<value: int>, originDetails: string, publicationDate: record<value: int>>
# operationId: getByIsoCode
export def "get-by-iso-code" [
  iso_code: string
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
    path: "/dictionaries/currency/{isoCode}/exchangeRate"
    path_params: [{name: isoCode, var: iso_code}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    iso_code: $iso_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adding currency exchange rates.
#
# POST /dictionaries/currency/{isoCode}/exchangeRate
# operationId: createExchangeRate
export def "create-exchange-rate" [
  iso_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: record # shape: {value?: int}
  --exchange-rate: string
  --last-modification: record # shape: {value?: int}
  --origin-details: string
  --publication-date: record # shape: {value?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/dictionaries/currency/{isoCode}/exchangeRate"
    path_params: [{name: isoCode, var: iso_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: dateFrom, var: date_from}, {name: exchangeRate, var: exchange_rate}, {name: lastModification, var: last_modification}, {name: originDetails, var: origin_details}, {name: publicationDate, var: publication_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    iso_code: $iso_code, date_from: $date_from, exchange_rate: $exchange_rate, last_modification: $last_modification, origin_details: $origin_details, publication_date: $publication_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns active values from a given dictionary.
#
# GET /dictionaries/{type}/active
# Returns: record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int>
# operationId: getActiveByType
export def "get-active-by-type" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dictionaries/{type}/active"
    path_params: [{name: type, var: type}]
    query: [{name: nameEquals, var: name_equals}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    type: $type, name_equals: $name_equals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all values (both active and not active) from a given dictionary.
#
# GET /dictionaries/{type}/all
# Returns: record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int>
# operationId: getAllByType
export def "get-all-by-type" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dictionaries/{type}/all"
    path_params: [{name: type, var: type}]
    query: [{name: nameEquals, var: name_equals}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    type: $type, name_equals: $name_equals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns specific value from a given dictionary.
#
# GET /dictionaries/{type}/{id}
# Returns: record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int>
# operationId: getByTypeAndId
export def "get-by-type-and-id" [
  type: string
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
    path: "/dictionaries/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    type: $type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a temporary file (ie. for XML import). Returns token which can be used in other API calls.
#
# POST /files
# operationId: uploadFile
export def "upload-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/files"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns job details by jobId.
#
# GET /jobs/{jobId}
# Returns: record<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list<string>, sharedReferenceFiles: list<string>, sharedWorkFiles: list<string>>, id: string, idNumber: string, languages: table<sourceLanguageId: int, specializationId: int, targetLanguageId: int>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record<canVerifyFiles: bool, isScripted: bool>>, vendorId: int, vendorPriceProfileId: int>
# operationId: getJobDetails
export def "get-job-details" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates dates of a given job.
#
# PUT /jobs/{jobId}/dates
# operationId: updateDates
export def "update-dates" [
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
  --actual-end-date: int # format: int64
  --actual-start-date: int # format: int64
  --deadline: int # format: int64
  --start-date: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}/dates"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actualEndDate, var: actual_end_date}, {name: actualStartDate, var: actual_start_date}, {name: deadline, var: deadline}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, actual_end_date: $actual_end_date, actual_start_date: $actual_start_date, deadline: $deadline, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of input and output files of a job.
#
# GET /jobs/{jobId}/files
# Returns: record<inputFiles: table<content: string, name: string, token: string, url: string>, outputFiles: table<content: string, name: string, token: string, url: string>>
# operationId: getJobFiles
export def "get-job-files" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/files"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /jobs/{jobId}/files/output
#
# operationId: assignFileToJobOutput
export def "assign-file-to-job-output" [
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
  --category: string@category-completer # file category
  --content: string
  --name: string
  --body-token: string # (spec name: token)
  --url: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/jobs/{jobId}/files/output"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: category, var: category}, {name: content, var: content}, {name: name, var: name}, {name: token, var: body_token}, {name: url, var: url}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id, category: $category, content: $content, name: $name, body_token: $body_token, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns file metadata.
#
# GET /jobs/{jobId}/files/{fileId}
# Returns: record<categoryKey: string, id: int, lastModifiedOn: int, name: string, size: int>
# operationId: getJobFiles_1
export def "get-job-files-1" [
  job_id: string
  file_id: int
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
    path: "/jobs/{jobId}/files/{fileId}"
    path_params: [{name: jobId, var: job_id}, {name: fileId, var: file_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    job_id: $job_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates instructions for a job.
#
# PUT /jobs/{jobId}/instructions
# operationId: updateInstructions
export def "update-instructions" [
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
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}/instructions"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: forProvider, var: for_provider}, {name: fromCustomer, var: from_customer}, {name: internal, var: internal}, {name: notes, var: notes}, {name: paymentNoteForCustomer, var: payment_note_for_customer}, {name: paymentNoteForVendor, var: payment_note_for_vendor}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, for_provider: $for_provider, from_customer: $from_customer, internal: $internal, notes: $notes, payment_note_for_customer: $payment_note_for_customer, payment_note_for_vendor: $payment_note_for_vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes job status if possible (400 Bad Request is returned otherwise).
#
# PUT /jobs/{jobId}/status
# operationId: changeStatus
export def "change-status" [
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
  --external-id: string
  --status: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}/status"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalId, var: external_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, external_id: $external_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns vendor to a job in a project.
#
# PUT /jobs/{jobId}/vendor
# operationId: assignVendor
export def "assign-vendor" [
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
  --recalculate-rates: oneof<nothing, bool>
  --vendor-price-profile-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}/vendor"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: recalculateRates, var: recalculate_rates}, {name: vendorPriceProfileId, var: vendor_price_profile_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, recalculate_rates: $recalculate_rates, vendor_price_profile_id: $vendor_price_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns license content.
#
# GET /license
# Returns: record<clientId: string, parameters: record>
# operationId: getLicense
export def "get-license" [
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
    path: "/license"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refreshes license content.
#
# POST /license/refresh
# operationId: refresh
export def "refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/license/refresh"
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes a macro.
#
# POST /macros/{macroId}/run
# Returns: record<actionId: string, resultUrl: string, statusUrl: string>
# operationId: run
export def "post-macros-macro-id-run" [
  macro_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # indicates whether the macro should be executed asynchronously or synchronously (default: false)
  --ids: list<int> # list of internal identifiers of elements to be processed by the macro, can be empty for certain macros
  --params: record # map of custom key-value pairs that can optionally parametrize the macro execution
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/macros/{macroId}/run"
    path_params: [{name: macroId, var: macro_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: async, var: async}, {name: ids, var: ids}, {name: params, var: params}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    macro_id: $macro_id, async: $async, ids: $ids, params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Classic Project.
#
# POST /projects
# Returns: record<categoriesIds: list<int>, contactPersonId: int, contacts: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicProject: bool, name: string, projectId: string, projectManagerId: int, specializationId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>>
# operationId: create_5
export def "create-5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories-ids: list<int> # list of language categories
  customer_id: int # format: int64
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --input-files: list # input files — item shape: {category?: "WORKFILE"|"TM"|"DICTIONARY"|"REF"|"LOG_FILE", content?: string, name?: string, token?: string, url?: string}
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --name: string
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  service_id: int # format: int64
  --source-language-id: int # format: int64
  specialization_id: int # format: int64
  --target-languages-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: categoriesIds, var: categories_ids}, {name: customerId, var: customer_id}, {name: dates, var: dates}, {name: inputFiles, var: input_files}, {name: instructions, var: instructions}, {name: name, var: name}, {name: people, var: people}, {name: serviceId, var: service_id}, {name: sourceLanguageId, var: source_language_id}, {name: specializationId, var: specialization_id}, {name: targetLanguagesIds, var: target_languages_ids}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    categories_ids: $categories_ids, customer_id: $customer_id, dates: $dates, input_files: $input_files, instructions: $instructions, name: $name, people: $people, service_id: $service_id, source_language_id: $source_language_id, specialization_id: $specialization_id, target_languages_ids: $target_languages_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads a file.
#
# GET /projects/files/{fileId}/download
# operationId: getFileById
export def "get-file-by-id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/files/{fileId}/download"
    path_params: [{name: fileId, var: file_id}]
    accept: ["multipart/form-data"]
    ok: []
    auth: x-auth-access-token
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns projects' internal identifiers.
#
# GET /projects/ids
# Returns: list<int>
# operationId: getAllIds_6
export def "get-all-ids-6" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only projects modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/ids"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a project.
#
# DELETE /projects/{projectId}
# operationId: delete_12
export def "delete-12" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns project details.
#
# GET /projects/{projectId}
# Returns: record<categoriesIds: list<int>, contactPersonId: int, contacts: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicProject: bool, name: string, projectId: string, projectManagerId: int, specializationId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>>
# operationId: getById_7
export def "get-by-id-7" [
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
  --embed: string # list of additional fields which should be embedded in the response (available options: tasks)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: embed, var: embed}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, embed: $embed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns contacts of a given project.
#
# GET /projects/{projectId}/contacts
# Returns: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>
# operationId: getContacts
export def "get-contacts" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/contacts"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates contacts of a given project.
#
# PUT /projects/{projectId}/contacts
# Returns: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>
# operationId: updateContacts
export def "update-contacts" [
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
  --additional-ids: list<int>
  --primary-id: int # format: int64
  --send-back-to-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/contacts"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalIds, var: additional_ids}, {name: primaryId, var: primary_id}, {name: sendBackToId, var: send_back_to_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, additional_ids: $additional_ids, primary_id: $primary_id, send_back_to_id: $send_back_to_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given project.
#
# GET /projects/{projectId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_5
export def "get-custom-fields-5" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/customFields"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates custom fields of a given project.
#
# PUT /projects/{projectId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: updateCustomFields_3
export def "update-custom-fields-3" [
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
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/customFields"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: customFields, var: custom_fields}, {name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, custom_fields: $custom_fields, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns dates of a given project.
#
# GET /projects/{projectId}/dates
# Returns: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>
# operationId: getDates_1
export def "get-dates-1" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/dates"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates dates of a given project.
#
# PUT /projects/{projectId}/dates
# Returns: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>
# operationId: updateDates_1
export def "update-dates-1" [
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
  --actual-delivery-date: record # shape: {value?: int}
  --actual-start-date: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --start-date: record # shape: {value?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/dates"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actualDeliveryDate, var: actual_delivery_date}, {name: actualStartDate, var: actual_start_date}, {name: deadline, var: deadline}, {name: startDate, var: start_date}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, actual_delivery_date: $actual_delivery_date, actual_start_date: $actual_start_date, deadline: $deadline, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns finance of a given project.
#
# GET /projects/{projectId}/finance
# Returns: record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>
# operationId: getFinance
export def "get-finance" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/finance"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a payable to a project.
#
# POST /projects/{projectId}/finance/payables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: createPayable
export def "create-payable" [
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
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/finance/payables"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a payable.
#
# DELETE /projects/{projectId}/finance/payables/{payableId}
# operationId: deletePayable
export def "delete-payable" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/finance/payables/{payableId}"
    path_params: [{name: projectId, var: project_id}, {name: payableId, var: payable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, payable_id: $payable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a payable.
#
# PUT /projects/{projectId}/finance/payables/{payableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: updatePayable
export def "update-payable" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/finance/payables/{payableId}"
    path_params: [{name: projectId, var: project_id}, {name: payableId, var: payable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, payable_id: $payable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a receivable to a project.
#
# POST /projects/{projectId}/finance/receivables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: createReceivable
export def "create-receivable" [
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
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/finance/receivables"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a receivable.
#
# DELETE /projects/{projectId}/finance/receivables/{receivableId}
# operationId: deleteReceivable
export def "delete-receivable" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/finance/receivables/{receivableId}"
    path_params: [{name: projectId, var: project_id}, {name: receivableId, var: receivable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, receivable_id: $receivable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a receivable.
#
# PUT /projects/{projectId}/finance/receivables/{receivableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: updateReceivable
export def "update-receivable" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/finance/receivables/{receivableId}"
    path_params: [{name: projectId, var: project_id}, {name: receivableId, var: receivable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, receivable_id: $receivable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns instructions of a given project.
#
# GET /projects/{projectId}/instructions
# Returns: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>
# operationId: getInstructions
export def "get-instructions" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/instructions"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates instructions of a given project.
#
# PUT /projects/{projectId}/instructions
# Returns: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>
# operationId: updateInstructions_1
export def "update-instructions-1" [
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
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/instructions"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: forProvider, var: for_provider}, {name: fromCustomer, var: from_customer}, {name: internal, var: internal}, {name: notes, var: notes}, {name: paymentNoteForCustomer, var: payment_note_for_customer}, {name: paymentNoteForVendor, var: payment_note_for_vendor}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, for_provider: $for_provider, from_customer: $from_customer, internal: $internal, notes: $notes, payment_note_for_customer: $payment_note_for_customer, payment_note_for_vendor: $payment_note_for_vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new language combination for a given project without creating a task.
#
# POST /projects/{projectId}/languageCombinations
# Returns: record<sourceLanguageId: int, targetLanguageId: int>
# operationId: createLanguageCombination
export def "create-language-combination" [
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
  --source-language-id: int # format: int64
  --target-language-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/languageCombinations"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceLanguageId, var: source_language_id}, {name: targetLanguageId, var: target_language_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, source_language_id: $source_language_id, target_language_id: $target_language_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new task for a given project.
#
# POST /projects/{projectId}/tasks
# Returns: record<clientTaskPONumber: string, customFields: table<key: string, name: string, type: string, value: record>, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<invoiceable: bool>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, jobs: record<jobCount: int, jobIds: list<int>>, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, name: string, people: record<customerContacts: record<additionalIds: list, primaryId: int, sendBackToId: int>, responsiblePersons: record<projectCoordinatorId: int, projectManagerId: int>>, projectId: int, quoteId: int>
# operationId: createTask
export def "create-task" [
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
  --client-task-po-number: string # client task PO number
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --files: list # files — item shape: {category?: "WORKFILE"|"TM"|"DICTIONARY"|"REF"|"LOG_FILE", content?: string, name?: string, token?: string, url?: string}
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --language-combination: record # language combination (ie. PL -> EN) — shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --name: string # name
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  --specialization-id: int # specialization (format: int64)
  --workflow-id: int # workflow (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/tasks"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientTaskPONumber, var: client_task_po_number}, {name: dates, var: dates}, {name: files, var: files}, {name: instructions, var: instructions}, {name: languageCombination, var: language_combination}, {name: name, var: name}, {name: people, var: people}, {name: specializationId, var: specialization_id}, {name: workflowId, var: workflow_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, client_task_po_number: $client_task_po_number, dates: $dates, files: $files, instructions: $instructions, language_combination: $language_combination, name: $name, people: $people, specialization_id: $specialization_id, workflow_id: $workflow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns providers' internal identifiers.
#
# GET /providers/ids
# Returns: list<int>
# operationId: getAllIds_5
export def "get-all-ids-5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only providers modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/providers/ids"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns persons' internal identifiers.
#
# GET /providers/persons/ids
# Returns: list<int>
# operationId: getAllIds_4
export def "get-all-ids-4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only persons modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/providers/persons/ids"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a person.
#
# DELETE /providers/persons/{personId}
# operationId: delete_8
export def "delete-8" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/persons/{personId}"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [204]
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns person details.
#
# GET /providers/persons/{personId}
# Returns: record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, gender: string, id: int, lastName: string, motherTonguesIds: list<int>, name: string, positionId: int, providerId: int>
# operationId: getById_4
export def "get-by-id-4" [
  person_id: int
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
    path: "/providers/persons/{personId}"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns contact of a given person.
#
# GET /providers/persons/{personId}/contact
# Returns: record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string>
# operationId: getContact_2
export def "get-contact-2" [
  person_id: int
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
    path: "/providers/persons/{personId}/contact"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given person.
#
# GET /providers/persons/{personId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_2
export def "get-custom-fields-2" [
  person_id: int
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
    path: "/providers/persons/{personId}/customFields"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends invitation to Vendor Portal.
#
# POST /providers/persons/{personId}/notification/invitation
# Returns: record<alreadyRegisteredPersonsCount: int, invitedPersonsCount: int, providersWithAlreadyRegisteredPersonCount: int, providersWithInvitedPersonCount: int, providersWithoutPersonCount: int>
# operationId: sendInvitations
export def "send-invitations" [
  person_id: int
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
    method: post
    path: "/providers/persons/{personId}/notification/invitation"
    path_params: [{name: personId, var: person_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a provider price list.
#
# DELETE /providers/priceLists/{priceListId}
# operationId: delete_9
export def "delete-9" [
  price_list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/priceLists/{priceListId}"
    path_params: [{name: priceListId, var: price_list_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    price_list_id: $price_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a provider.
#
# DELETE /providers/{providerId}
# operationId: delete_10
export def "delete-10" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/{providerId}"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns provider details.
#
# GET /providers/{providerId}
# Returns: record<billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, competencies: record<languageCombinations: list<record>>, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, leadSourceId: int, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, gender: string, id: int, lastName: string, motherTonguesIds: list, name: string, positionId: int, providerId: int>, status: string>
# operationId: getById_5
export def "get-by-id-5" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. persons)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{providerId}"
    path_params: [{name: providerId, var: provider_id}]
    query: [{name: embed, var: embed}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    provider_id: $provider_id, embed: $embed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns address of a given provider.
#
# GET /providers/{providerId}/address
# Returns: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>
# operationId: getAddress_1
export def "get-address-1" [
  provider_id: int
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
    path: "/providers/{providerId}/address"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns competencies of a given provider.
#
# GET /providers/{providerId}/competencies
# Returns: record<languageCombinations: table<sourceLanguageId: int, targetLanguageId: int>>
# operationId: getCompetencies
export def "get-competencies" [
  provider_id: int
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
    path: "/providers/{providerId}/competencies"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns contact of a given provider.
#
# GET /providers/{providerId}/contact
# Returns: record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>
# operationId: getContact_3
export def "get-contact-3" [
  provider_id: int
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
    path: "/providers/{providerId}/contact"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns correspondence address of a given provider.
#
# GET /providers/{providerId}/correspondenceAddress
# Returns: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>
# operationId: getCorrespondenceAddress_1
export def "get-correspondence-address-1" [
  provider_id: int
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
    path: "/providers/{providerId}/correspondenceAddress"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given provider.
#
# GET /providers/{providerId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_3
export def "get-custom-fields-3" [
  provider_id: int
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
    path: "/providers/{providerId}/customFields"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends invitations to Vendor Portal.
#
# POST /providers/{providerId}/notification/invitation
# Returns: record<alreadyRegisteredPersonsCount: int, invitedPersonsCount: int, providersWithAlreadyRegisteredPersonCount: int, providersWithInvitedPersonCount: int, providersWithoutPersonCount: int>
# operationId: sendInvitations_1
export def "send-invitations-1" [
  provider_id: int
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
    method: post
    path: "/providers/{providerId}/notification/invitation"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns quotes' internal identifiers.
#
# GET /quotes/ids
# Returns: list<int>
# operationId: getAllIds_7
export def "get-all-ids-7" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only quotes modified since this timestamp (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/quotes/ids"
    query: [{name: updatedSince, var: updated_since}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    updated_since: $updated_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a quote.
#
# DELETE /quotes/{quoteId}
# operationId: delete_13
export def "delete-13" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/quotes/{quoteId}"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns quote details.
#
# GET /quotes/{quoteId}
# Returns: record<automaticallyAcceptSentQuote: bool, categoriesIds: list<int>, contactPersonId: int, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<createdOn: record<value: int>, deadline: record<value: int>, offerExpiry: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicQuote: bool, name: string, quoteId: string, salesPersonId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>>
# operationId: getById_8
export def "get-by-id-8" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. tasks)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/quotes/{quoteId}"
    path_params: [{name: quoteId, var: quote_id}]
    query: [{name: embed, var: embed}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, embed: $embed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a quote for customer confirmation.
#
# POST /quotes/{quoteId}/confirmation/send
# operationId: send_1
export def "send-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/quotes/{quoteId}/confirmation/send"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given quote.
#
# GET /quotes/{quoteId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_6
export def "get-custom-fields-6" [
  quote_id: string
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
    path: "/quotes/{quoteId}/customFields"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates custom fields of a given quote.
#
# PUT /quotes/{quoteId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: updateCustomFields_4
export def "update-custom-fields-4" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/quotes/{quoteId}/customFields"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: customFields, var: custom_fields}, {name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, custom_fields: $custom_fields, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns dates of a given quote.
#
# GET /quotes/{quoteId}/dates
# Returns: record<createdOn: record<value: int>, deadline: record<value: int>, offerExpiry: record<value: int>, startDate: record<value: int>>
# operationId: getDates_2
export def "get-dates-2" [
  quote_id: string
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
    path: "/quotes/{quoteId}/dates"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns finance of a given quote.
#
# GET /quotes/{quoteId}/finance
# Returns: record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>
# operationId: getFinance_1
export def "get-finance-1" [
  quote_id: string
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
    path: "/quotes/{quoteId}/finance"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a payable.
#
# POST /quotes/{quoteId}/finance/payables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: createPayable_1
export def "create-payable-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/quotes/{quoteId}/finance/payables"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a payable.
#
# DELETE /quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_1
export def "delete-payable-1" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/quotes/{quoteId}/finance/payables/{payableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: payableId, var: payable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, payable_id: $payable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a payable.
#
# PUT /quotes/{quoteId}/finance/payables/{payableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: updatePayable_1
export def "update-payable-1" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/quotes/{quoteId}/finance/payables/{payableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: payableId, var: payable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, payable_id: $payable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a receivable.
#
# POST /quotes/{quoteId}/finance/receivables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: createReceivable_1
export def "create-receivable-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/quotes/{quoteId}/finance/receivables"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a receivable.
#
# DELETE /quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_1
export def "delete-receivable-1" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/quotes/{quoteId}/finance/receivables/{receivableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: receivableId, var: receivable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, receivable_id: $receivable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a receivable.
#
# PUT /quotes/{quoteId}/finance/receivables/{receivableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: updateReceivable_1
export def "update-receivable-1" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/quotes/{quoteId}/finance/receivables/{receivableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: receivableId, var: receivable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, receivable_id: $receivable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns instructions of a given quote.
#
# GET /quotes/{quoteId}/instructions
# Returns: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>
# operationId: getInstructions_1
export def "get-instructions-1" [
  quote_id: string
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
    path: "/quotes/{quoteId}/instructions"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates instructions of a given quote.
#
# PUT /quotes/{quoteId}/instructions
# Returns: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>
# operationId: updateInstructions_2
export def "update-instructions-2" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/quotes/{quoteId}/instructions"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: forProvider, var: for_provider}, {name: fromCustomer, var: from_customer}, {name: internal, var: internal}, {name: notes, var: notes}, {name: paymentNoteForCustomer, var: payment_note_for_customer}, {name: paymentNoteForVendor, var: payment_note_for_vendor}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, for_provider: $for_provider, from_customer: $from_customer, internal: $internal, notes: $notes, payment_note_for_customer: $payment_note_for_customer, payment_note_for_vendor: $payment_note_for_vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new language combination for a given quote without creating a task.
#
# POST /quotes/{quoteId}/languageCombinations
# Returns: record<sourceLanguageId: int, targetLanguageId: int>
# operationId: createLanguageCombination_1
export def "create-language-combination-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
  --target-language-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/quotes/{quoteId}/languageCombinations"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceLanguageId, var: source_language_id}, {name: targetLanguageId, var: target_language_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, source_language_id: $source_language_id, target_language_id: $target_language_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a quote.
#
# POST /quotes/{quoteId}/start
# operationId: start
export def "post-quotes-quote-id-start" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/quotes/{quoteId}/start"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new task for a given quote.
#
# POST /quotes/{quoteId}/tasks
# Returns: record<clientTaskPONumber: string, customFields: table<key: string, name: string, type: string, value: record>, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<invoiceable: bool>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, jobs: record<jobCount: int, jobIds: list<int>>, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, name: string, people: record<customerContacts: record<additionalIds: list, primaryId: int, sendBackToId: int>, responsiblePersons: record<projectCoordinatorId: int, projectManagerId: int>>, projectId: int, quoteId: int>
# operationId: createTask_1
export def "create-task-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-task-po-number: string # client task PO number
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --finance: record # finance — shape: {invoiceable?: bool}
  --id: int # internal identifier (format: int64)
  --id-number: string # identifier
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --jobs: record # shape: {jobCount?: int, jobIds?: list<int>}
  --language-combination: record # language combination (ie. PL -> EN) — shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --name: string # name
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  --project-id: int # project's internal identifier (format: int64)
  --body-quote-id: int # quote's internal identifier (format: int64) (spec name: quoteId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/quotes/{quoteId}/tasks"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientTaskPONumber, var: client_task_po_number}, {name: customFields, var: custom_fields}, {name: dates, var: dates}, {name: finance, var: finance}, {name: id, var: id}, {name: idNumber, var: id_number}, {name: instructions, var: instructions}, {name: jobs, var: jobs}, {name: languageCombination, var: language_combination}, {name: name, var: name}, {name: people, var: people}, {name: projectId, var: project_id}, {name: quoteId, var: body_quote_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, client_task_po_number: $client_task_po_number, custom_fields: $custom_fields, dates: $dates, finance: $finance, id: $id, id_number: $id_number, instructions: $instructions, jobs: $jobs, language_combination: $language_combination, name: $name, people: $people, project_id: $project_id, body_quote_id: $body_quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports reports definition to XML.
#
# POST /reports/export/xml
# Returns: record<url: string>
# operationId: exportToXML
export def "export-to-xml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/export/xml"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports reports definition from XML.
#
# POST /reports/import/xml
# Returns: record<currentSystemVersion: string, importedReportsNames: list<string>, invalidReportsNames: list<string>, targetSystemVersion: string>
# operationId: importFromXML
export def "import-from-xml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-token: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/import/xml"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: fileToken, var: file_token}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    file_token: $file_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a report.
#
# DELETE /reports/{reportId}
# operationId: delete_11
export def "delete-11" [
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/reports/{reportId}"
    path_params: [{name: reportId, var: report_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicates a report.
#
# POST /reports/{reportId}/duplicate
# operationId: duplicate_1
export def "duplicate-1" [
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/reports/{reportId}/duplicate"
    path_params: [{name: reportId, var: report_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks report as preferred or not.
#
# PUT /reports/{reportId}/preferred
# operationId: setPreferred
export def "set-preferred" [
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferred: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/reports/{reportId}/preferred"
    path_params: [{name: reportId, var: report_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: preferred, var: preferred}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    report_id: $report_id, preferred: $preferred
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates CSV content for a report.
#
# GET /reports/{reportId}/result/csv
# Returns: record<url: string>
# operationId: generateCSV
export def "generate-csv" [
  report_id: int
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
    path: "/reports/{reportId}/result/csv"
    path_params: [{name: reportId, var: report_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates printer friendly content for a report.
#
# GET /reports/{reportId}/result/printerFriendly
# Returns: record<url: string>
# operationId: generatePrinterFriendly
export def "generate-printer-friendly" [
  report_id: int
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
    path: "/reports/{reportId}/result/printerFriendly"
    path_params: [{name: reportId, var: report_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns active services list
#
# GET /services/active
# Returns: record<active: bool, default: bool, id: int, name: string, preferred: bool>
# operationId: getAllActive
export def "get-all-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/services/active"
    query: [{name: nameEquals, var: name_equals}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    name_equals: $name_equals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns services list
#
# GET /services/all
# Returns: record<active: bool, default: bool, id: int, name: string, preferred: bool>
# operationId: getAll_3
export def "get-all-3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/services/all"
    query: [{name: nameEquals, var: name_equals}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    name_equals: $name_equals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all subscriptions
#
# GET /subscription
# Returns: table<embed: string, event: string, filter: string, subscriptionId: string, url: string>
# operationId: getAll_4
export def "get-all-4" [
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
    path: "/subscription"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to event
#
# POST /subscription
# Returns: string
# operationId: subscribe
export def "subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # additional fields which should be embedded in the event
  --event: string # event to which you want to subscribe
  --filter: string # filter expression in the form 'attribute=value'
  --url: string # url that will be invoked by XTRF on event
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscription"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: embed, var: embed}, {name: event, var: event}, {name: filter, var: filter}, {name: url, var: url}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [201]
    auth: x-auth-access-token
  } {
    embed: $embed, event: $event, filter: $filter, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method can be used to determine if hooks are supported.
#
# GET /subscription/supports
# Returns: bool
# operationId: areHooksSupported
export def "are-hooks-supported" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/subscription/supports"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from event
#
# DELETE /subscription/{subscriptionId}
# operationId: unsubscribe
export def "unsubscribe" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscription/{subscriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-access-token
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a task.
#
# DELETE /tasks/{taskId}
# operationId: delete_14
export def "delete-14" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remove-files-from-disc: oneof<nothing, bool> # remove files from disc
  --remove-external-projects: oneof<nothing, bool> # remove external projects (ie. from CAT Tool)
  --force-jobs-removal: oneof<nothing, bool> # force jobs removal (ie. started or ready)
]: nothing -> any {
  http-request {
    method: delete
    path: "/tasks/{taskId}"
    path_params: [{name: taskId, var: task_id}]
    query: [{name: removeFilesFromDisc, var: remove_files_from_disc}, {name: removeExternalProjects, var: remove_external_projects}, {name: forceJobsRemoval, var: force_jobs_removal}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    task_id: $task_id, remove_files_from_disc: $remove_files_from_disc, remove_external_projects: $remove_external_projects, force_jobs_removal: $force_jobs_removal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Task PO Number of a given task.
#
# PUT /tasks/{taskId}/clientTaskPONumber
# Returns: record<value: string>
# operationId: updateClientTaskPONumber
export def "update-client-task-po-number" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{taskId}/clientTaskPONumber"
    path_params: [{name: taskId, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns contacts of a given task.
#
# GET /tasks/{taskId}/contacts
# Returns: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>
# operationId: getContacts_1
export def "get-contacts-1" [
  task_id: string
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
    path: "/tasks/{taskId}/contacts"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates contacts of a given task.
#
# PUT /tasks/{taskId}/contacts
# Returns: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>
# operationId: updateContacts_1
export def "update-contacts-1" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
  --send-back-to-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{taskId}/contacts"
    path_params: [{name: taskId, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalIds, var: additional_ids}, {name: primaryId, var: primary_id}, {name: sendBackToId, var: send_back_to_id}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id, additional_ids: $additional_ids, primary_id: $primary_id, send_back_to_id: $send_back_to_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given task.
#
# GET /tasks/{taskId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_7
export def "get-custom-fields-7" [
  task_id: string
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
    path: "/tasks/{taskId}/customFields"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates custom fields of a given task.
#
# PUT /tasks/{taskId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: updateCustomFields_5
export def "update-custom-fields-5" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{taskId}/customFields"
    path_params: [{name: taskId, var: task_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: customFields, var: custom_fields}, {name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id, custom_fields: $custom_fields, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns dates of a given task.
#
# GET /tasks/{taskId}/dates
# Returns: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>
# operationId: getDates_3
export def "get-dates-3" [
  task_id: string
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
    path: "/tasks/{taskId}/dates"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates dates of a given task.
#
# PUT /tasks/{taskId}/dates
# Returns: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>
# operationId: updateDates_2
export def "update-dates-2" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-delivery-date: record # shape: {value?: int}
  --actual-start-date: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --start-date: record # shape: {value?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{taskId}/dates"
    path_params: [{name: taskId, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actualDeliveryDate, var: actual_delivery_date}, {name: actualStartDate, var: actual_start_date}, {name: deadline, var: deadline}, {name: startDate, var: start_date}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id, actual_delivery_date: $actual_delivery_date, actual_start_date: $actual_start_date, deadline: $deadline, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns lists of files of a given task.
#
# GET /tasks/{taskId}/files
# Returns: record<bundles: record, inputFiles: record<logFiles: list<record>, referenceFiles: list<record>, terminology: list<record>, tm: list<record>, workFiles: list<record>>, jobs: table<files: record, id: int, idNumber: string, name: string>, outputFiles: table<content: string, name: string, token: string, url: string>>
# operationId: getTaskFiles
export def "get-task-files" [
  task_id: string
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
    path: "/tasks/{taskId}/files"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds files to a given task.
#
# POST /tasks/{taskId}/files/input
# operationId: addFile
export def "add-file" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string
  --name: string
  --body-token: string # (spec name: token)
  --url: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/tasks/{taskId}/files/input"
    path_params: [{name: taskId, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: name, var: name}, {name: token, var: body_token}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    task_id: $task_id, content: $content, name: $name, body_token: $body_token, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns instructions of a given task.
#
# GET /tasks/{taskId}/instructions
# Returns: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>
# operationId: getInstructions_2
export def "get-instructions-2" [
  task_id: string
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
    path: "/tasks/{taskId}/instructions"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates instructions of a given task.
#
# PUT /tasks/{taskId}/instructions
# Returns: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>
# operationId: updateInstructions_3
export def "update-instructions-3" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{taskId}/instructions"
    path_params: [{name: taskId, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: forProvider, var: for_provider}, {name: fromCustomer, var: from_customer}, {name: internal, var: internal}, {name: notes, var: notes}, {name: paymentNoteForCustomer, var: payment_note_for_customer}, {name: paymentNoteForVendor, var: payment_note_for_vendor}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id, for_provider: $for_provider, from_customer: $from_customer, internal: $internal, notes: $notes, payment_note_for_customer: $payment_note_for_customer, payment_note_for_vendor: $payment_note_for_vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates name of a given task.
#
# PUT /tasks/{taskId}/name
# Returns: record<value: string>
# operationId: updateName
export def "update-name" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{taskId}/name"
    path_params: [{name: taskId, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns progress of a given task.
#
# GET /tasks/{taskId}/progress
# Returns: record<phase: string, status: string>
# operationId: getProgress
export def "get-progress" [
  task_id: string
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
    path: "/tasks/{taskId}/progress"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: [200]
    auth: x-auth-access-token
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a task.
#
# POST /tasks/{taskId}/start
# operationId: start_1
export def "start-1" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/tasks/{taskId}/start"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of simple users representations
#
# GET /users
# Returns: table<id: int, name: string>
# operationId: getAllNamesWithIds_1
export def "get-all-names-with-ids-1" [
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
    path: "/users"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns currently signed in user details.
#
# GET /users/me
# Returns: record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string>
# operationId: getMe
export def "get-me" [
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
    path: "/users/me"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns time zone preferred by user currently signed in.
#
# GET /users/me/timeZone
# Returns: record<displayName: string, id: string, offset: int>
# operationId: getTimeZone
export def "get-time-zone" [
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
    path: "/users/me/timeZone"
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns user details.
#
# GET /users/{userId}
# Returns: record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string>
# operationId: getById_6
export def "get-by-id-6" [
  user_id: int
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
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing user.
#
# PUT /users/{userId}
# Returns: record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string>
# operationId: update_3
export def "update-3" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --email: string
  --first-name: string
  --gender: string
  --id: int # format: int64
  --last-name: string
  --login: string
  --mobile-phone: string
  --phone: string
  --position-name: string
  --time-zone-id: string
  --user-group-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFields, var: custom_fields}, {name: email, var: email}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: id, var: id}, {name: lastName, var: last_name}, {name: login, var: login}, {name: mobilePhone, var: mobile_phone}, {name: phone, var: phone}, {name: positionName, var: position_name}, {name: timeZoneId, var: time_zone_id}, {name: userGroupName, var: user_group_name}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    user_id: $user_id, custom_fields: $custom_fields, email: $email, first_name: $first_name, gender: $gender, id: $id, last_name: $last_name, login: $login, mobile_phone: $mobile_phone, phone: $phone, position_name: $position_name, time_zone_id: $time_zone_id, user_group_name: $user_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom fields of a given user.
#
# GET /users/{userId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_4
export def "get-custom-fields-4" [
  user_id: int
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
    path: "/users/{userId}/customFields"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates custom fields of a given user.
#
# PUT /users/{userId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: updateCustomFields_2
export def "update-custom-fields-2" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{userId}/customFields"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: customFields, var: custom_fields}, {name: empty, var: empty}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    user_id: $user_id, custom_fields: $custom_fields, empty: $empty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns custom field of a given user.
#
# GET /users/{userId}/customFields/{customFieldKey}
# Returns: record<key: string, name: string, type: string, value: record>
# operationId: getCustomField_1
export def "get-custom-field-1" [
  user_id: int
  custom_field_key: string
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
    path: "/users/{userId}/customFields/{customFieldKey}"
    path_params: [{name: userId, var: user_id}, {name: customFieldKey, var: custom_field_key}]
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    user_id: $user_id, custom_field_key: $custom_field_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates given custom field of a given user.
#
# PUT /users/{userId}/customFields/{customFieldKey}
# Returns: record<key: string, name: string, type: string, value: record>
# operationId: updateCustomField_1
export def "update-custom-field-1" [
  user_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --type: string@type-completer-1
  --value: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{userId}/customFields/{customFieldKey}"
    path_params: [{name: userId, var: user_id}, {name: customFieldKey, var: custom_field_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/vnd.xtrf-v1+json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    user_id: $user_id, custom_field_key: $custom_field_key, key: $key, name: $name, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets user's password to a new value.
#
# PUT /users/{userId}/password
# operationId: changePassword
export def "change-password" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # new password
  --old-password: string # old password
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{userId}/password"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    user_id: $user_id, new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v2/jobs/for-external-id
#
# operationId: getByExternalId
export def "get-by-external-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-project-id: string # job's externalProjectId
  --external-id: string # job's external identifier
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/jobs/for-external-id"
    query: [{name: externalProjectId, var: external_project_id}, {name: externalId, var: external_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    external_project_id: $external_project_id, external_id: $external_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details for a job.
#
# GET /v2/jobs/{jobId}
# Returns: record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getFileById_1
export def "get-file-by-id-1" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates dates of a given job.
#
# PUT /v2/jobs/{jobId}/dates
# operationId: changeDates
export def "change-dates" [
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
  --actual-end-date: int # format: int64
  --actual-start-date: int # format: int64
  --deadline: int # format: int64
  --start-date: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/dates"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actualEndDate, var: actual_end_date}, {name: actualStartDate, var: actual_start_date}, {name: deadline, var: deadline}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, actual_end_date: $actual_end_date, actual_start_date: $actual_start_date, deadline: $deadline, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v2/jobs/{jobId}/files/addExternalLink
#
# operationId: addExternalFileLink
export def "add-external-file-link" [
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
  --category: string
  --external-info: record
  --filename: string
  --language-combination-ids: list # item shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-ids: list<int>
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/jobs/{jobId}/files/addExternalLink"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: externalInfo, var: external_info}, {name: filename, var: filename}, {name: languageCombinationIds, var: language_combination_ids}, {name: languageIds, var: language_ids}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id, category: $category, external_info: $external_info, filename: $filename, language_combination_ids: $language_combination_ids, language_ids: $language_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of files delivered in the job.
#
# GET /v2/jobs/{jobId}/files/delivered
# Returns: table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getDeliveredFiles
export def "get-delivered-files" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/jobs/{jobId}/files/delivered"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds files to the project as delivered in the job.
#
# PUT /v2/jobs/{jobId}/files/delivered/add
# operationId: addFiles
export def "add-files" [
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
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/files/delivered/add"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds file link to the project as a link delivered in the job.
#
# POST /v2/jobs/{jobId}/files/delivered/addLink
# Returns: record<files: list<string>>
# operationId: addFileLinks
export def "add-file-links" [
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
  --file-links: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/jobs/{jobId}/files/delivered/addLink"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileLinks, var: file_links}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id, file_links: $file_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads file to the project as a file delivered in the job.
#
# POST /v2/jobs/{jobId}/files/delivered/upload
# Returns: record<fileId: string>
# operationId: uploadFile_1
export def "upload-file-1" [
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
  --file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/jobs/{jobId}/files/delivered/upload"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of files shared with the job as Reference Files.
#
# GET /v2/jobs/{jobId}/files/sharedReferenceFiles
# Returns: table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getSharedReferenceFiles
export def "get-shared-reference-files" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/jobs/{jobId}/files/sharedReferenceFiles"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shares selected files as Reference Files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/sharedReferenceFiles/share
# Returns: record<statuses: table<fileId: string, message: string, successful: bool>>
# operationId: shareAsReferenceFiles
export def "share-as-reference-files" [
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
  --files: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/files/sharedReferenceFiles/share"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of files shared with the job as Work Files.
#
# GET /v2/jobs/{jobId}/files/sharedWorkFiles
# Returns: table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getSharedWorkFiles
export def "get-shared-work-files" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/jobs/{jobId}/files/sharedWorkFiles"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shares selected files as Work Files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/sharedWorkFiles/share
# Returns: record<statuses: table<fileId: string, message: string, successful: bool>>
# operationId: shareAsWorkFiles
export def "share-as-work-files" [
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
  --files: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/files/sharedWorkFiles/share"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops sharing selected files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/stopSharing
# Returns: record<statuses: table<fileId: string, message: string, successful: bool>>
# operationId: stopSharing
export def "stop-sharing" [
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
  --files: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/files/stopSharing"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    job_id: $job_id, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates instructions for a job.
#
# PUT /v2/jobs/{jobId}/instructions
# operationId: updateInstructions_4
export def "update-instructions-4" [
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
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/instructions"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes job status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/jobs/{jobId}/status
# operationId: changeStatus_1
export def "change-status-1" [
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
  --external-id: string
  --status: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/status"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalId, var: external_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, external_id: $external_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns vendor to a job in a project.
#
# PUT /v2/jobs/{jobId}/vendor
# operationId: assignVendor_1
export def "assign-vendor-1" [
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
  --vendor-price-profile-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/jobs/{jobId}/vendor"
    path_params: [{name: jobId, var: job_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: vendorPriceProfileId, var: vendor_price_profile_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    job_id: $job_id, vendor_price_profile_id: $vendor_price_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Smart Project.
#
# POST /v2/projects
# Returns: record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>
# operationId: create_6
export def "create-6" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: int # format: int64
  --external-id: string
  --name: string
  --service-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: externalId, var: external_id}, {name: name, var: name}, {name: serviceId, var: service_id}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: x-auth-access-token
  } {
    client_id: $client_id, external_id: $external_id, name: $name, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Prepares a ZIP archive that contains the specified files.
#
# POST /v2/projects/files/archive
# Returns: record<archiveUrl: string>
# operationId: archive
export def "archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/projects/files/archive"
    body: {content_type: "application/json", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details of a file.
#
# GET /v2/projects/files/{fileId}
# Returns: record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getFileById_2
export def "get-file-by-id-2" [
  file_id: string
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
    path: "/v2/projects/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads a file content.
#
# GET /v2/projects/files/{fileId}/download/{fileName}
# operationId: getFileContentById
export def "get-file-content-by-id" [
  file_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/projects/files/{fileId}/download/{fileName}"
    path_params: [{name: fileId, var: file_id}, {name: fileName, var: file_name}]
    accept: ["multipart/form-data"]
    ok: []
    auth: x-auth-access-token
  } {
    file_id: $file_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns project details.
#
# GET /v2/projects/for-external-id/{externalProjectId}
# Returns: record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>
# operationId: getByExternalId_1
export def "get-by-external-id-1" [
  external_project_id: string
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
    path: "/v2/projects/for-external-id/{externalProjectId}"
    path_params: [{name: externalProjectId, var: external_project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    external_project_id: $external_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns project details.
#
# GET /v2/projects/{projectId}
# Returns: record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>
# operationId: getById_9
export def "get-by-id-9" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns process id.
#
# POST /v2/projects/{projectId}/addJob
# Returns: record<projectCreatedInCatToolOrCreationIsQueued: bool>
# operationId: addJobToProcess
export def "add-job-to-process" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v2/projects/{projectId}/addJob"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns if cat tool project is created or queued.
#
# GET /v2/projects/{projectId}/catToolProject
# Returns: record<projectCreatedInCatToolOrCreationIsQueued: bool>
# operationId: getCATToolProjectInfo
export def "get-cat-tool-project-info" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/catToolProject"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Client Contacts information for a project.
#
# GET /v2/projects/{projectId}/clientContacts
# Returns: record<additionalIds: list<int>, primaryId: int>
# operationId: getContacts_2
export def "get-contacts-2" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/clientContacts"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Contacts for a project.
#
# PUT /v2/projects/{projectId}/clientContacts
# Returns: record<additionalIds: list<int>, primaryId: int>
# operationId: updateContacts_2
export def "update-contacts-2" [
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
  --additional-ids: list<int>
  --primary-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/clientContacts"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalIds, var: additional_ids}, {name: primaryId, var: primary_id}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, additional_ids: $additional_ids, primary_id: $primary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Deadline for a project.
#
# PUT /v2/projects/{projectId}/clientDeadline
# operationId: updateClientDeadline
export def "update-client-deadline" [
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
  --value: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/clientDeadline"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Notes for a project.
#
# PUT /v2/projects/{projectId}/clientNotes
# operationId: updateClientNotes
export def "update-client-notes" [
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
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/clientNotes"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Reference Number for a project.
#
# PUT /v2/projects/{projectId}/clientReferenceNumber
# operationId: updateClientReferenceNumber
export def "update-client-reference-number" [
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
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/clientReferenceNumber"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/projects/{projectId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_8
export def "get-custom-fields-8" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/customFields"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a custom field with a specified key in a project
#
# PUT /v2/projects/{projectId}/customFields/{key}
# operationId: updateCustomField_2
export def "update-custom-field-2" [
  project_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/customFields/{key}"
    path_params: [{name: projectId, var: project_id}, {name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of files in a project.
#
# GET /v2/projects/{projectId}/files
# Returns: table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getFiles
export def "get-files" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/files"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds files to the project as added by PM.
#
# PUT /v2/projects/{projectId}/files/add
# operationId: addFiles_1
export def "add-files-1" [
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
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/files/add"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v2/projects/{projectId}/files/addExternalLink
#
# operationId: addExternalFileLinks
export def "add-external-file-links" [
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
  --category: string
  --external-info: record
  --filename: string
  --language-combination-ids: list # item shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-ids: list<int>
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/projects/{projectId}/files/addExternalLink"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: externalInfo, var: external_info}, {name: filename, var: filename}, {name: languageCombinationIds, var: language_combination_ids}, {name: languageIds, var: language_ids}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, category: $category, external_info: $external_info, filename: $filename, language_combination_ids: $language_combination_ids, language_ids: $language_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds file links to the project as added by PM.
#
# POST /v2/projects/{projectId}/files/addLink
# Returns: record<files: list<string>>
# operationId: addFileLinks_1
export def "add-file-links-1" [
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
  --file-links: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/projects/{projectId}/files/addLink"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileLinks, var: file_links}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, file_links: $file_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of files in a project, that are ready to be delivered to client.
#
# GET /v2/projects/{projectId}/files/deliverable
# Returns: table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getDeliverableFiles
export def "get-deliverable-files" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/files/deliverable"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads file to the project as a file uploaded by PM.
#
# POST /v2/projects/{projectId}/files/upload
# Returns: record<fileId: string>
# operationId: uploadFile_2
export def "upload-file-2" [
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
  --file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/projects/{projectId}/files/upload"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns finance information for a project.
#
# GET /v2/projects/{projectId}/finance
# Returns: record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>
# operationId: getFinance_2
export def "get-finance-2" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/finance"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a payable to a project.
#
# POST /v2/projects/{projectId}/finance/payables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: createPayable_2
export def "create-payable-2" [
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
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/projects/{projectId}/finance/payables"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a payable.
#
# DELETE /v2/projects/{projectId}/finance/payables/{payableId}
# operationId: deletePayable_2
export def "delete-payable-2" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/projects/{projectId}/finance/payables/{payableId}"
    path_params: [{name: projectId, var: project_id}, {name: payableId, var: payable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, payable_id: $payable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a payable.
#
# PUT /v2/projects/{projectId}/finance/payables/{payableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: updatePayable_2
export def "update-payable-2" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/finance/payables/{payableId}"
    path_params: [{name: projectId, var: project_id}, {name: payableId, var: payable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, payable_id: $payable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a receivable to a project.
#
# POST /v2/projects/{projectId}/finance/receivables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: createReceivable_2
export def "create-receivable-2" [
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
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/projects/{projectId}/finance/receivables"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a receivable.
#
# DELETE /v2/projects/{projectId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_2
export def "delete-receivable-2" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/projects/{projectId}/finance/receivables/{receivableId}"
    path_params: [{name: projectId, var: project_id}, {name: receivableId, var: receivable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, receivable_id: $receivable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a receivable.
#
# PUT /v2/projects/{projectId}/finance/receivables/{receivableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: updateReceivable_2
export def "update-receivable-2" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/finance/receivables/{receivableId}"
    path_params: [{name: projectId, var: project_id}, {name: receivableId, var: receivable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id, receivable_id: $receivable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Internal Notes for a project.
#
# PUT /v2/projects/{projectId}/internalNotes
# operationId: updateInternalNotes
export def "update-internal-notes" [
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
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/internalNotes"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of jobs in a project.
#
# GET /v2/projects/{projectId}/jobs
# Returns: table<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list, sharedReferenceFiles: list, sharedWorkFiles: list>, id: string, idNumber: string, languages: list<record>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record>, vendorId: int, vendorPriceProfileId: int>
# operationId: getJobs
export def "get-jobs" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/jobs"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Order Date for a project.
#
# PUT /v2/projects/{projectId}/orderDate
# operationId: updateOrderedOn
export def "update-ordered-on" [
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
  --value: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/orderDate"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns process id.
#
# GET /v2/projects/{projectId}/process
# Returns: record<projectCreatedInCatToolOrCreationIsQueued: bool>
# operationId: getProcessId
export def "get-process-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/projects/{projectId}/process"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates source language for a project.
#
# PUT /v2/projects/{projectId}/sourceLanguage
# operationId: updateSourceLanguage
export def "update-source-language" [
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
  --source-language-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/sourceLanguage"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceLanguageId, var: source_language_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, source_language_id: $source_language_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates specialization for a project.
#
# PUT /v2/projects/{projectId}/specialization
# operationId: updateSpecialization
export def "update-specialization" [
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
  --specialization-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/specialization"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: specializationId, var: specialization_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, specialization_id: $specialization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes project status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/projects/{projectId}/status
# operationId: changeStatus_2
export def "change-status-2" [
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
  --status: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/status"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates target languages for a project.
#
# PUT /v2/projects/{projectId}/targetLanguages
# operationId: updateTargetLanguages
export def "update-target-languages" [
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
  --target-language-ids: list<int>
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/targetLanguages"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetLanguageIds, var: target_language_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, target_language_ids: $target_language_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates instructions for all vendors performing the jobs in a project.
#
# PUT /v2/projects/{projectId}/vendorInstructions
# operationId: updateVendorInstructions
export def "update-vendor-instructions" [
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
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/vendorInstructions"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates volume for a project.
#
# PUT /v2/projects/{projectId}/volume
# operationId: updateVolume
export def "update-volume" [
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
  --value: float
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/projects/{projectId}/volume"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Smart Quote.
#
# POST /v2/quotes
# Returns: record<budgetCode: string, businessDays: int, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, createdOn: int, documents: record<projectConfirmationStatus: string>, expectedDeliveryDate: int, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicQuote: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, origin: string, people: record<projectManagerId: int>, quoteExpiry: int, quoteId: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>
# operationId: create_7
export def "create-7" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: int # format: int64
  --name: string
  --opportunity-offer-id: int # format: int64
  --service-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/quotes"
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: name, var: name}, {name: opportunityOfferId, var: opportunity_offer_id}, {name: serviceId, var: service_id}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: x-auth-access-token
  } {
    client_id: $client_id, name: $name, opportunity_offer_id: $opportunity_offer_id, service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Prepares a ZIP archive that contains the specified files.
#
# POST /v2/quotes/files/archive
# Returns: record<archiveUrl: string>
# operationId: archive_1
export def "archive-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/quotes/files/archive"
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details of a file.
#
# GET /v2/quotes/files/{fileId}
# Returns: record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getFileById_3
export def "get-file-by-id-3" [
  file_id: string
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
    path: "/v2/quotes/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads a file content.
#
# GET /v2/quotes/files/{fileId}/download/{fileName}
# operationId: getFileContentById_1
export def "get-file-content-by-id-1" [
  file_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/quotes/files/{fileId}/download/{fileName}"
    path_params: [{name: fileId, var: file_id}, {name: fileName, var: file_name}]
    accept: ["multipart/form-data"]
    ok: []
    auth: x-auth-access-token
  } {
    file_id: $file_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns quote details.
#
# GET /v2/quotes/{quoteId}
# Returns: record<budgetCode: string, businessDays: int, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, createdOn: int, documents: record<projectConfirmationStatus: string>, expectedDeliveryDate: int, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicQuote: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, origin: string, people: record<projectManagerId: int>, quoteExpiry: int, quoteId: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>>
# operationId: getById_10
export def "get-by-id-10" [
  quote_id: string
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
    path: "/v2/quotes/{quoteId}"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Business Days for a quote.
#
# PUT /v2/quotes/{quoteId}/businessDays
# operationId: updateBusinessDays
export def "update-business-days" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: int
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/businessDays"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Client Contacts information for a quote.
#
# GET /v2/quotes/{quoteId}/clientContacts
# Returns: record<additionalIds: list<int>, primaryId: int>
# operationId: getContacts_3
export def "get-contacts-3" [
  quote_id: string
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
    path: "/v2/quotes/{quoteId}/clientContacts"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Contacts for a quote.
#
# PUT /v2/quotes/{quoteId}/clientContacts
# Returns: record<additionalIds: list<int>, primaryId: int>
# operationId: updateContacts_3
export def "update-contacts-3" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/clientContacts"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json;charset=UTF-8", kind: json, fields: [{name: additionalIds, var: additional_ids}, {name: primaryId, var: primary_id}]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, additional_ids: $additional_ids, primary_id: $primary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/clientNotes
# operationId: updateClientNotes_1
export def "update-client-notes-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/clientNotes"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Client Reference Number for a quote.
#
# PUT /v2/quotes/{quoteId}/clientReferenceNumber
# operationId: updateClientReferenceNumber_1
export def "update-client-reference-number-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/clientReferenceNumber"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/quotes/{quoteId}/customFields
# Returns: table<key: string, name: string, type: string, value: record>
# operationId: getCustomFields_9
export def "get-custom-fields-9" [
  quote_id: string
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
    path: "/v2/quotes/{quoteId}/customFields"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a custom field with a specified key in a quote.
#
# PUT /v2/quotes/{quoteId}/customFields/{key}
# operationId: updateCustomField_3
export def "update-custom-field-3" [
  quote_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/customFields/{key}"
    path_params: [{name: quoteId, var: quote_id}, {name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Expected Delivery Date for a quote.
#
# PUT /v2/quotes/{quoteId}/expectedDeliveryDate
# operationId: updateExpectedDeliveryDate
export def "update-expected-delivery-date" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/expectedDeliveryDate"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of files in a quote.
#
# GET /v2/quotes/{quoteId}/files
# Returns: table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string>
# operationId: getFiles_1
export def "get-files-1" [
  quote_id: string
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
    path: "/v2/quotes/{quoteId}/files"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds files to the quote as added by PM.
#
# PUT /v2/quotes/{quoteId}/files/add
# operationId: addFiles_2
export def "add-files-2" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/files/add"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads file to the quote as a file uploaded by PM.
#
# POST /v2/quotes/{quoteId}/files/upload
# Returns: record<fileId: string>
# operationId: uploadFile_3
export def "upload-file-3" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/quotes/{quoteId}/files/upload"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns finance information for a quote.
#
# GET /v2/quotes/{quoteId}/finance
# Returns: record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float>
# operationId: getFinance_3
export def "get-finance-3" [
  quote_id: string
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
    path: "/v2/quotes/{quoteId}/finance"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a payable to a quote.
#
# POST /v2/quotes/{quoteId}/finance/payables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: createPayable_3
export def "create-payable-3" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/quotes/{quoteId}/finance/payables"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a payable.
#
# DELETE /v2/quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_3
export def "delete-payable-3" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/quotes/{quoteId}/finance/payables/{payableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: payableId, var: payable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, payable_id: $payable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a payable.
#
# PUT /v2/quotes/{quoteId}/finance/payables/{payableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string>
# operationId: updatePayable_3
export def "update-payable-3" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/finance/payables/{payableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: payableId, var: payable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobId, var: job_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, payable_id: $payable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_id: $job_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a receivable to a quote.
#
# POST /v2/quotes/{quoteId}/finance/receivables
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: createReceivable_3
export def "create-receivable-3" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/quotes/{quoteId}/finance/receivables"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: catLogFile, var: cat_log_file}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, calculation_unit_id: $calculation_unit_id, cat_log_file: $cat_log_file, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a receivable.
#
# DELETE /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_3
export def "delete-receivable-3" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/quotes/{quoteId}/finance/receivables/{receivableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: receivableId, var: receivable_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, receivable_id: $receivable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a receivable.
#
# PUT /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# Returns: record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string>
# operationId: updateReceivable_3
export def "update-receivable-3" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/finance/receivables/{receivableId}"
    path_params: [{name: quoteId, var: quote_id}, {name: receivableId, var: receivable_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calculationUnitId, var: calculation_unit_id}, {name: currencyId, var: currency_id}, {name: description, var: description}, {name: id, var: id}, {name: ignoreMinimumCharge, var: ignore_minimum_charge}, {name: invoiceId, var: invoice_id}, {name: jobTypeId, var: job_type_id}, {name: languageCombination, var: language_combination}, {name: languageCombinationIdNumber, var: language_combination_id_number}, {name: minimumCharge, var: minimum_charge}, {name: quantity, var: quantity}, {name: rate, var: rate}, {name: rateOrigin, var: rate_origin}, {name: taskId, var: task_id}, {name: total, var: total}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, receivable_id: $receivable_id, calculation_unit_id: $calculation_unit_id, currency_id: $currency_id, description: $description, id: $id, ignore_minimum_charge: $ignore_minimum_charge, invoice_id: $invoice_id, job_type_id: $job_type_id, language_combination: $language_combination, language_combination_id_number: $language_combination_id_number, minimum_charge: $minimum_charge, quantity: $quantity, rate: $rate, rate_origin: $rate_origin, task_id: $task_id, total: $total, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Internal Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/internalNotes
# operationId: updateInternalNotes_1
export def "update-internal-notes-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/internalNotes"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of jobs in a quote.
#
# GET /v2/quotes/{quoteId}/jobs
# Returns: table<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list, sharedReferenceFiles: list, sharedWorkFiles: list>, id: string, idNumber: string, languages: list<record>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record>, vendorId: int, vendorPriceProfileId: int>
# operationId: getJobs_1
export def "get-jobs-1" [
  quote_id: string
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
    path: "/v2/quotes/{quoteId}/jobs"
    path_params: [{name: quoteId, var: quote_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: []
    auth: x-auth-access-token
  } {
    quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Quote Expiry Date for a quote.
#
# PUT /v2/quotes/{quoteId}/quoteExpiry
# operationId: updateQuoteExpiry
export def "update-quote-expiry" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/quoteExpiry"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates source language for a quote.
#
# PUT /v2/quotes/{quoteId}/sourceLanguage
# operationId: updateSourceLanguage_1
export def "update-source-language-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/sourceLanguage"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceLanguageId, var: source_language_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, source_language_id: $source_language_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates specialization for a quote.
#
# PUT /v2/quotes/{quoteId}/specialization
# operationId: updateSpecialization_1
export def "update-specialization-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --specialization-id: int # format: int64
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/specialization"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: specializationId, var: specialization_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, specialization_id: $specialization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes quote status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/quotes/{quoteId}/status
# operationId: changeStatus_3
export def "change-status-3" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/status"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates target languages for a quote.
#
# PUT /v2/quotes/{quoteId}/targetLanguages
# operationId: updateTargetLanguages_1
export def "update-target-languages-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-language-ids: list<int>
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/targetLanguages"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetLanguageIds, var: target_language_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, target_language_ids: $target_language_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates instructions for all vendors performing the jobs in a quote.
#
# PUT /v2/quotes/{quoteId}/vendorInstructions
# operationId: updateVendorInstructions_1
export def "update-vendor-instructions-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/vendorInstructions"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates volume for a quote.
#
# PUT /v2/quotes/{quoteId}/volume
# operationId: updateVolume_1
export def "update-volume-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/quotes/{quoteId}/volume"
    path_params: [{name: quoteId, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-auth-access-token
  } {
    quote_id: $quote_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
