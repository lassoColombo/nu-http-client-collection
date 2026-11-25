# Auto-generated client for KumpeApps API v5.0.0
# Source: https://api.apis.guru/v2/specs/kumpeapps.com/5.0.0/openapi.json
# Auth: --token flag or $env.KUMPEAPPS_API_TOKEN

const CLIENT = {
  base_url: "https://restapi.kumpeapps.com/v5"
  token_env_var: "KUMPEAPPS_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-auth, in: header, header_name: X-Auth, prefix: ""}
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

def base-url-completer [] { ["https://restapi.kumpeapps.com/v5" "https://restapi.preprod.kumpeapps.com/v5"] }
def auth-scheme-completer [] { ["x-auth" "none"] }

# Completers for enum parameters
def transaction-type-completer [] { ["Add" "Subtract"] }
def tool-completer [] { ["register" "send" "subscribe" "unsubscribe"] }
def section-completer [] { ["Allowance" "Allowance-New" "Chores" "Chores-New" "Chores-Reminders" "WishList"] }
def priority-completer [] { ["active" "critical" "passive" "time-sensitive"] }
def day-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Tuesday" "Wednesday" "Weekly"] }
def day-completer-1 [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Today" "Tuesday" "Wednesday" "Weekly"] }
def where-day-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Today" "Tuesday" "Wednesday" "Weekly"] }
def link-completer [] { ["https://khome.kumpeapps.com/portal/chores-today.php" "https://khome.kumpeapps.com/portal/wish-list.php"] }
def scope-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }
def scope2-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }
def scope3-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }
def scope4-completer [] { ["Chores" "ChoresAdmin" "WishList" "WishListAdmin"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    appkey-patch: "record<success: bool>"
    appkey-post: "record<app_key: string, success: bool>"
    appkey-put: "record<success: bool>"
    auth-appkey-patch: "record<success: bool>"
    auth-appkey-post: "record<app_key: string, success: bool>"
    auth-appkey-put: "record<success: bool>"
    auth-authkey-get: "record<auth_key: string, success: bool>"
    auth-authkey-patch: "record<success: bool>"
    auth-authkey-post: "record<auth_key: string, success: bool>"
    auth-authkey-put: "record<success: bool>"
    authkey-get: "record<auth_key: string, success: bool>"
    authkey-patch: "record<success: bool>"
    authkey-post: "record<auth_key: string, success: bool>"
    authkey-put: "record<success: bool>"
    kkid-allowance-get: "record<allowanceTransaction: table<amount: int, date: string, transactionDescription: string, transactionId: int, transactionType: string, userId: int>, balance: int, id: int, lastUpdated: string, success: int>"
    kkid-allowance-post: "record<message: string, success: bool>"
    kkid-apns-post: "record<message: string, success: bool>"
    kkid-chorelist-delete: "record<message: string, success: bool>"
    kkid-chorelist-get: "record<chore: table<aiIcon: string, altitude: int, blockDash: bool, choreDescription: string, choreName: string, choreNumber: int, day: string, extraAllowance: int, idChoreList: int, isCalendar: bool, kid: string, latitude: int, longitude: int, nfcTag: string, notes: string, oneTime: bool, optional: bool, reassignable: bool, reassigned: bool, requireObjectDetection: string, startDate: string, status: string, stolen: bool, stolenBy: string, updated: string, updatedBy: string>, success: int>"
    kkid-chorelist-post: "record<message: string, success: bool>"
    kkid-chorelist-put: "record<message: string, success: bool>"
    kkid-masteruser-post: "record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string>"
    kkid-share-get: "record<auth_link: string, success: bool>"
    kkid-user-get: "record<success: bool, user: table<email: string, emoji: string, enableAllowance: bool, enableBehaviorChart: bool, enableChores: bool, enableNoAds: bool, enableObjectDetection: bool, enableTmdb: bool, firstName: string, homeId: int, isActive: bool, isAdmin: bool, isBanned: bool, isChild: bool, isDisabled: bool, isLocked: bool, isMaster: bool, lastName: string, masterId: int, pushAllowance: bool, pushAllowanceNew: bool, pushChores: bool, pushChoresNew: bool, pushChoresReminders: bool, tmdbKey: string, userId: int, username: string, weeklyAllowance: int>>"
    kkid-userlist-get: "record<success: bool, user: table<email: string, emoji: string, enableAllowance: bool, enableBehaviorChart: bool, enableChores: bool, enableNoAds: bool, enableObjectDetection: bool, enableTmdb: bool, firstName: string, homeId: int, isActive: bool, isAdmin: bool, isBanned: bool, isChild: bool, isDisabled: bool, isLocked: bool, isMaster: bool, lastName: string, masterId: int, pushAllowance: bool, pushAllowanceNew: bool, pushChores: bool, pushChoresNew: bool, pushChoresReminders: bool, tmdbKey: string, userId: int, username: string, weeklyAllowance: int>>"
    kkid-userlist-post: "record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string>"
    kkid-userlist-put: "record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string>"
    kkid-wishlist-delete: "record<message: string, success: bool>"
    kkid-wishlist-get: "record<success: bool, wish: table<description: string, id: int, link: string, master_id: int, priority: int, title: string, user_id: int>>"
    kkid-wishlist-post: "record<message: string, success: bool>"
    kkid-wishlist-put: "record<message: string, success: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["appkey-patch" "appkey-post" "appkey-put" "auth-appkey-patch" "auth-appkey-post" "auth-appkey-put" "auth-authkey-get" "auth-authkey-patch" "auth-authkey-post" "auth-authkey-put" "auth-verifyotp-get" "authkey-get" "authkey-patch" "authkey-post" "authkey-put" "kkid-allowance-get" "kkid-allowance-post" "kkid-apns-post" "kkid-chorelist-delete" "kkid-chorelist-get" "kkid-chorelist-post" "kkid-chorelist-put" "kkid-masteruser-post" "kkid-share-get" "kkid-user-get" "kkid-userlist-delete" "kkid-userlist-get" "kkid-userlist-post" "kkid-userlist-put" "kkid-wishlist-delete" "kkid-wishlist-get" "kkid-wishlist-post" "kkid-wishlist-put" "commands"] | sort) } | get name | first)
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

# Compromise app key
#
# PATCH /appkey
# DEPRECATED
# Returns: record<success: bool>
# operationId: appkey_patch
@deprecated
export def "appkey-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # compromised app key (required)
  --comments: string # Comments (like how was this compromised)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/appkey"
    query: [{name: app_key, var: app_key, required: true}, {name: comments, var: comments}]
    accept: ["application/json"]
    ok: [202]
    auth: none
  } {
    app_key: $app_key, comments: $comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request app key
#
# POST /appkey
# DEPRECATED
# Returns: record<app_key: string, success: bool>
# operationId: appkey_post
@deprecated
export def "appkey-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username assigned to your app (required)
  --password: string # Password assigned to your app (required, format: password)
  --supports-yubikey: oneof<nothing, bool> # App supports YubiKey OTP (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/appkey"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: supportsYubikey, var: supports_yubikey, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    username: $username, password: $password, supports_yubikey: $supports_yubikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate app key
#
# PUT /appkey
# DEPRECATED
# Returns: record<success: bool>
# operationId: appkey_put
@deprecated
export def "appkey-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # app key to deactivate (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/appkey"
    query: [{name: app_key, var: app_key, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: x-auth
  } {
    app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compromise app key
#
# PATCH /authentication/appkey
# Returns: record<success: bool>
# operationId: auth_appkey_patch
export def "auth-appkey-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # compromised app key (required)
  --comments: string # Comments (like how was this compromised)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/authentication/appkey"
    query: [{name: app_key, var: app_key, required: true}, {name: comments, var: comments}]
    accept: ["application/json"]
    ok: [202]
    auth: none
  } {
    app_key: $app_key, comments: $comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request app key
#
# POST /authentication/appkey
# Returns: record<app_key: string, success: bool>
# operationId: auth_appkey_post
export def "auth-appkey-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username assigned to your app (required)
  --password: string # Password assigned to your app (required, format: password)
  --supports-yubikey: oneof<nothing, bool> # App supports YubiKey OTP (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/authentication/appkey"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: supportsYubikey, var: supports_yubikey, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    username: $username, password: $password, supports_yubikey: $supports_yubikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate app key
#
# PUT /authentication/appkey
# Returns: record<success: bool>
# operationId: auth_appkey_put
export def "auth-appkey-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-key: string # app key to deactivate (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/authentication/appkey"
    query: [{name: app_key, var: app_key, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: x-auth
  } {
    app_key: $app_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request auth key for user (login user)
#
# GET /authentication/authkey
# Returns: record<auth_key: string, success: bool>
# operationId: auth_authkey_get
export def "auth-authkey-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username (required)
  --password: string # Authenticated password (required, format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
  --device-name: string # User's device name
  --identifier-for-vendor: string # identifierForVendor for User's Device (if app is iOS)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authentication/authkey"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: otp, var: otp}, {name: deviceName, var: device_name}, {name: identifierForVendor, var: identifier_for_vendor}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    username: $username, password: $password, otp: $otp, device_name: $device_name, identifier_for_vendor: $identifier_for_vendor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compromise auth key
#
# PATCH /authentication/authkey
# Returns: record<success: bool>
# operationId: auth_authkey_patch
export def "auth-authkey-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to mark as compromised (required, format: password)
  --comments: string # Comments (like how was this compromised)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/authentication/authkey"
    query: [{name: auth_key, var: auth_key, required: true}, {name: comments, var: comments}]
    accept: ["application/json"]
    ok: [202]
    auth: none
  } {
    auth_key: $auth_key, comments: $comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request auth key for user (login user)
#
# POST /authentication/authkey
# Returns: record<auth_key: string, success: bool>
# operationId: auth_authkey_post
export def "auth-authkey-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username (required)
  --password: string # Authenticated password (required, format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/authentication/authkey"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: otp, var: otp}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    username: $username, password: $password, otp: $otp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate auth key (logout)
#
# PUT /authentication/authkey
# Returns: record<success: bool>
# operationId: auth_authkey_put
export def "auth-authkey-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to logout (required, format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/authentication/authkey"
    query: [{name: auth_key, var: auth_key, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: x-auth
  } {
    auth_key: $auth_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verifies YubiKey OTP for authenticated user
#
# GET /authentication/verifyotp
# operationId: auth_verifyotp_get
export def "auth-verifyotp-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --otp: string # YubiKey OTP code (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/authentication/verifyotp"
    query: [{name: otp, var: otp, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    otp: $otp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request auth key for user (login user)
#
# GET /authkey
# DEPRECATED
# Returns: record<auth_key: string, success: bool>
# operationId: authkey_get
@deprecated
export def "authkey-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username (required)
  --password: string # Authenticated password (required, format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authkey"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: otp, var: otp}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    username: $username, password: $password, otp: $otp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compromise auth key
#
# PATCH /authkey
# DEPRECATED
# Returns: record<success: bool>
# operationId: authkey_patch
@deprecated
export def "authkey-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to mark as compromised (required, format: password)
  --comments: string # Comments (like how was this compromised)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/authkey"
    query: [{name: auth_key, var: auth_key, required: true}, {name: comments, var: comments}]
    accept: ["application/json"]
    ok: [202]
    auth: none
  } {
    auth_key: $auth_key, comments: $comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request auth key for user (login user)
#
# POST /authkey
# DEPRECATED
# Returns: record<auth_key: string, success: bool>
# operationId: authkey_post
@deprecated
export def "authkey-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Authenticated username (required)
  --password: string # Authenticated password (required, format: password)
  --otp: string # YubiKey OTP (if configured for user) (format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/authkey"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: otp, var: otp}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    username: $username, password: $password, otp: $otp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate auth key (logout)
#
# PUT /authkey
# DEPRECATED
# Returns: record<success: bool>
# operationId: authkey_put
@deprecated
export def "authkey-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-key: string # auth key to logout (required, format: password)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/authkey"
    query: [{name: auth_key, var: auth_key, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: x-auth
  } {
    auth_key: $auth_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns allowance balance and allowance transactions
#
# GET /kkid/allowance
# Returns: record<allowanceTransaction: table<amount: int, date: string, transactionDescription: string, transactionId: int, transactionType: string, userId: int>, balance: int, id: int, lastUpdated: string, success: int>
# operationId: kkid_allowance_get
export def "kkid-allowance-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid (required)
  --transaction-days: int # number of days you wish to search allowance transactions (default is 90 days)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kkid/allowance"
    query: [{name: kidUserId, var: kid_user_id, required: true}, {name: transactionDays, var: transaction_days}]
    accept: ["application/json"]
    ok: [200, 202, 206]
    auth: x-auth
  } {
    kid_user_id: $kid_user_id, transaction_days: $transaction_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# adds new allowance transaction to kidUserID
#
# POST /kkid/allowance
# Returns: record<message: string, success: bool>
# operationId: kkid_allowance_post
export def "kkid-allowance-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid (required)
  --amount: float # amount you wish to Add/Subtract (subtract value should be a negative value) (required)
  --description: string # Description (reason) of allowance transaction (required)
  --transaction-type: string@transaction-type-completer # Transaction Type (Add/Subtract) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/kkid/allowance"
    query: [{name: kidUserId, var: kid_user_id, required: true}, {name: amount, var: amount, required: true}, {name: description, var: description, required: true}, {name: transactionType, var: transaction_type, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 206]
    auth: x-auth
  } {
    kid_user_id: $kid_user_id, amount: $amount, description: $description, transaction_type: $transaction_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# subscribes/unsubscribes/registers for apns push notifications
#
# POST /kkid/apns
# Returns: record<message: string, success: bool>
# operationId: kkid_apns_post
export def "kkid-apns-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid (required)
  --tool: string@tool-completer # tool you wish to talk to (required)
  --qp-token: string # device APNS token (required for register) (spec name: token)
  --devicename: string # Name of device to associate to token (required for register)
  --title: string # title of APNS message (required for send)
  --message: string # APNS message body (required for send)
  --badge: int # Number for badge icon (optional for send)
  --sound: string # Name of sound file to play for send notification (optional for send)
  --section: string@section-completer # Notification section name (required for send/subscribe/unsubscribe)
  --priority: string@priority-completer # Notification section name (optional for send, default is active)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/kkid/apns"
    query: [{name: kidUserId, var: kid_user_id, required: true}, {name: tool, var: tool, required: true}, {name: token, var: qp_token}, {name: devicename, var: devicename}, {name: title, var: title}, {name: message, var: message}, {name: badge, var: badge}, {name: sound, var: sound}, {name: section, var: section}, {name: priority, var: priority}]
    accept: ["application/json"]
    ok: [200, 202, 206]
    auth: x-auth
  } {
    kid_user_id: $kid_user_id, tool: $tool, qp_token: $qp_token, devicename: $devicename, title: $title, message: $message, badge: $badge, sound: $sound, section: $section, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes chore for given chore id
#
# DELETE /kkid/chorelist
# Returns: record<message: string, success: bool>
# operationId: kkid_chorelist_delete
export def "kkid-chorelist-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-chore-list: int # id of the chore you wish to delete (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/kkid/chorelist"
    query: [{name: idChoreList, var: id_chore_list, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 206]
    auth: x-auth
  } {
    id_chore_list: $id_chore_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns list of chores for given user
#
# GET /kkid/chorelist
# Returns: record<chore: table<aiIcon: string, altitude: int, blockDash: bool, choreDescription: string, choreName: string, choreNumber: int, day: string, extraAllowance: int, idChoreList: int, isCalendar: bool, kid: string, latitude: int, longitude: int, nfcTag: string, notes: string, oneTime: bool, optional: bool, reassignable: bool, reassigned: bool, requireObjectDetection: string, startDate: string, status: string, stolen: bool, stolenBy: string, updated: string, updatedBy: string>, success: int>
# operationId: kkid_chorelist_get
export def "kkid-chorelist-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-username: string # Username of kid you wish to search
  --day: string@day-completer # Day of week for chores (Weekly for weekly chores)
  --status: string # Status of Chore to search
  --block-dash: oneof<nothing, bool> # Filter results by blockDash parameter
  --optional: oneof<nothing, bool> # Filter results by optional parameter
  --can-steal: oneof<nothing, bool> # Filter results by canSteal parameter
  --include-calendar: oneof<nothing, bool> # include calendar notations (default is false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kkid/chorelist"
    query: [{name: kidUsername, var: kid_username}, {name: day, var: day}, {name: status, var: status}, {name: blockDash, var: block_dash}, {name: optional, var: optional}, {name: canSteal, var: can_steal}, {name: includeCalendar, var: include_calendar}]
    accept: ["application/json"]
    ok: [200, 202, 206]
    auth: x-auth
  } {
    kid_username: $kid_username, day: $day, status: $status, block_dash: $block_dash, optional: $optional, can_steal: $can_steal, include_calendar: $include_calendar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# adds chore for given user
#
# POST /kkid/chorelist
# Returns: record<message: string, success: bool>
# operationId: kkid_chorelist_post
export def "kkid-chorelist-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-username: string # username of kid to assign the chore to. (required)
  --day: string@day-completer-1 # day of week (Monday, Tuesday....) for the chore. For weekly chores put Weekly or leave blank
  --nfc-tag: string # text field of nfc tag required to check off chore
  --status: string # status of chore (default is todo)
  --chore-name: string # name of chore (required)
  --chore-description: string # optional chore description
  --chore-number: int # number priority of chore (default is 5)
  --block-dash: oneof<nothing, bool> # block dash option on this chore
  --one-time: oneof<nothing, bool> # mark as one time chore (does not repeat each week)
  --extra-allowance: int # ammount of allowance added at end of week for completing this chore
  --optional: oneof<nothing, bool> # mark as optional chore
  --reassignable: oneof<nothing, bool> # mark as reassignable (default is true)
  --can-steal: oneof<nothing, bool> # mark as sibling can steal chore
  --start-date: string # date (yyyy-mm-dd) that you wish the chore to start showing up. (default is today)
  --notes: string # notes added to chore (visable only on reports, kids do not see this note, this is mostly just for the developer)
  --require-object-detection: oneof<nothing, bool> # require use of camera to detect object detection tag order to check off chore
  --object-detection-tag: string # tag for object detection to search for (required if requireObjectDetection is true)
  --updated-by-automation: oneof<nothing, bool> # true if chore updated via API from an Automation System
  --ai-icon: string # Notes if AI Icons should be used (n for no, y for yes, e for yes- error)
  --is-calendar: oneof<nothing, bool> # True if this is a calendar note instead of a chore.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/kkid/chorelist"
    query: [{name: kidUsername, var: kid_username, required: true}, {name: day, var: day}, {name: nfcTag, var: nfc_tag}, {name: status, var: status}, {name: choreName, var: chore_name, required: true}, {name: choreDescription, var: chore_description}, {name: choreNumber, var: chore_number}, {name: blockDash, var: block_dash}, {name: oneTime, var: one_time}, {name: extraAllowance, var: extra_allowance}, {name: optional, var: optional}, {name: reassignable, var: reassignable}, {name: canSteal, var: can_steal}, {name: startDate, var: start_date}, {name: notes, var: notes}, {name: requireObjectDetection, var: require_object_detection}, {name: objectDetectionTag, var: object_detection_tag}, {name: updatedByAutomation, var: updated_by_automation}, {name: aiIcon, var: ai_icon}, {name: isCalendar, var: is_calendar}]
    accept: ["application/json"]
    ok: [200, 202, 206]
    auth: x-auth
  } {
    kid_username: $kid_username, day: $day, nfc_tag: $nfc_tag, status: $status, chore_name: $chore_name, chore_description: $chore_description, chore_number: $chore_number, block_dash: $block_dash, one_time: $one_time, extra_allowance: $extra_allowance, optional: $optional, reassignable: $reassignable, can_steal: $can_steal, start_date: $start_date, notes: $notes, require_object_detection: $require_object_detection, object_detection_tag: $object_detection_tag, updated_by_automation: $updated_by_automation, ai_icon: $ai_icon, is_calendar: $is_calendar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updates chore for given chore id
#
# PUT /kkid/chorelist
# Returns: record<message: string, success: bool>
# operationId: kkid_chorelist_put
export def "kkid-chorelist-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-chore-list: int # id number of chore you wish to update (required)
  --status: string # new status of chore
  --stolen: oneof<nothing, bool> # mark chore as stolen by sibling
  --stolen-by: string # username of sibling that stole the chore (required if stolen is true)
  --nfc-tag: string # text field of NFC tag that is required to be scanned to check off this chore (normally null)
  --notes: string # notes field for chore
  --latitude: int # GPS latitude of where the chore was marked
  --longitude: int # GPS longitude of where the chore was marked
  --altitude: int # GPS altitude of where the chore was marked
  --updated-by-automation: oneof<nothing, bool> # true if updated via API by automation system
  --where-day: string@where-day-completer # Where day equals...
  --where-status: string # Where status equals...
  --where-name: string # Where chore name equals...
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/kkid/chorelist"
    query: [{name: idChoreList, var: id_chore_list, required: true}, {name: status, var: status}, {name: stolen, var: stolen}, {name: stolenBy, var: stolen_by}, {name: nfcTag, var: nfc_tag}, {name: notes, var: notes}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: altitude, var: altitude}, {name: updatedByAutomation, var: updated_by_automation}, {name: whereDay, var: where_day}, {name: whereStatus, var: where_status}, {name: whereName, var: where_name}]
    accept: ["application/json"]
    ok: [200, 202, 206]
    auth: x-auth
  } {
    id_chore_list: $id_chore_list, status: $status, stolen: $stolen, stolen_by: $stolen_by, nfc_tag: $nfc_tag, notes: $notes, latitude: $latitude, longitude: $longitude, altitude: $altitude, updated_by_automation: $updated_by_automation, where_day: $where_day, where_status: $where_status, where_name: $where_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# adds new master user account
#
# POST /kkid/masteruser
# Returns: record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string>
# operationId: kkid_masteruser_post
export def "kkid-masteruser-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username of user to create (required)
  --password: string # password of user to create (required, format: password)
  --email: string # email address of user to create (required)
  --first-name: string # First Name of user to create (required)
  --last-name: string # Last Name of user to create (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/kkid/masteruser"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: email, var: email, required: true}, {name: firstName, var: first_name, required: true}, {name: lastName, var: last_name, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: x-auth
  } {
    username: $username, password: $password, email: $email, first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Share Link
#
# GET /kkid/share
# Returns: record<auth_link: string, success: bool>
# operationId: kkid_share_get
export def "kkid-share-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --link-user-id: string # User ID that the link should be authenticated to (required)
  --link: string@link-completer # Link to share (required)
  --scope: string@scope-completer # Authentication scope for link (required)
  --scope2: string@scope2-completer # Authentication scope for link
  --scope3: string@scope3-completer # Authentication scope for link
  --scope4: string@scope4-completer # Authentication scope for link
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kkid/share"
    query: [{name: linkUserId, var: link_user_id, required: true}, {name: link, var: link, required: true}, {name: scope, var: scope, required: true}, {name: scope2, var: scope2}, {name: scope3, var: scope3}, {name: scope4, var: scope4}]
    accept: ["application/json"]
    ok: [201]
    auth: x-auth
  } {
    link_user_id: $link_user_id, link: $link, scope: $scope, scope2: $scope2, scope3: $scope3, scope4: $scope4
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets user info
#
# GET /kkid/user
# Returns: record<success: bool, user: table<email: string, emoji: string, enableAllowance: bool, enableBehaviorChart: bool, enableChores: bool, enableNoAds: bool, enableObjectDetection: bool, enableTmdb: bool, firstName: string, homeId: int, isActive: bool, isAdmin: bool, isBanned: bool, isChild: bool, isDisabled: bool, isLocked: bool, isMaster: bool, lastName: string, masterId: int, pushAllowance: bool, pushAllowanceNew: bool, pushChores: bool, pushChoresNew: bool, pushChoresReminders: bool, tmdbKey: string, userId: int, username: string, weeklyAllowance: int>>
# operationId: kkid_user_get
export def "kkid-user-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enable-bool: oneof<nothing, bool> # Use bool values instead of Int 0/1
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kkid/user"
    query: [{name: enableBool, var: enable_bool}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    enable_bool: $enable_bool
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes user
#
# DELETE /kkid/userlist
# operationId: kkid_userlist_delete
export def "kkid-userlist-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # userID of the user you wish to delete (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/kkid/userlist"
    query: [{name: userID, var: user_id, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: x-auth
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns list of users
#
# GET /kkid/userlist
# Returns: record<success: bool, user: table<email: string, emoji: string, enableAllowance: bool, enableBehaviorChart: bool, enableChores: bool, enableNoAds: bool, enableObjectDetection: bool, enableTmdb: bool, firstName: string, homeId: int, isActive: bool, isAdmin: bool, isBanned: bool, isChild: bool, isDisabled: bool, isLocked: bool, isMaster: bool, lastName: string, masterId: int, pushAllowance: bool, pushAllowanceNew: bool, pushChores: bool, pushChoresNew: bool, pushChoresReminders: bool, tmdbKey: string, userId: int, username: string, weeklyAllowance: int>>
# operationId: kkid_userlist_get
export def "kkid-userlist-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-child: oneof<nothing, bool> # Filter Search by isChild flag
  --is-active: oneof<nothing, bool> # Filter Search by isActive flag
  --is-admin: oneof<nothing, bool> # Filter Search by isAdmin flag
  --enable-allowance: oneof<nothing, bool> # Filter Search by enableAllowance flag
  --enable-chores: oneof<nothing, bool> # Filter Search by enableChores flag
  --user-id: int # userID of user to search
  --username: string # Username of user to search
  --email: string # Email address of user to search
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kkid/userlist"
    query: [{name: isChild, var: is_child}, {name: isActive, var: is_active}, {name: isAdmin, var: is_admin}, {name: enableAllowance, var: enable_allowance}, {name: enableChores, var: enable_chores}, {name: userID, var: user_id}, {name: username, var: username}, {name: email, var: email}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: x-auth
  } {
    is_child: $is_child, is_active: $is_active, is_admin: $is_admin, enable_allowance: $enable_allowance, enable_chores: $enable_chores, user_id: $user_id, username: $username, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# adds new child user
#
# POST /kkid/userlist
# Returns: record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string>
# operationId: kkid_userlist_post
export def "kkid-userlist-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # username of user to create (required)
  --password: string # password of user to create (required, format: password)
  --email: string # email address of user to create (required)
  --first-name: string # First Name of user to create (required)
  --last-name: string # Last Name of user to create (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/kkid/userlist"
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}, {name: email, var: email, required: true}, {name: firstName, var: first_name, required: true}, {name: lastName, var: last_name, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: x-auth
  } {
    username: $username, password: $password, email: $email, first_name: $first_name, last_name: $last_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updates user
#
# PUT /kkid/userlist
# Returns: record<added: string, aff_added: string, aff_id: string, aff_payout_type: string, avatar: string, city: string, comment: string, country: string, disable_lock_until: string, email: string, i_agree: string, is_affiliate: string, is_locked: string, lang: string, last_login: string, login: string, name_f: string, name_l: string, pass: string, pass_dattm: string, phone: string, pin: string, plain_password: string, remember_key: string, remote_addr: string, require_consent: string, reseller_id: string, saved_form_id: string, state: string, status: string, street: string, street2: string, subusers_parent_id: string, tax_id: string, unsubscribed: string, user_agent: string, user_id: int, zip: string>
# operationId: kkid_userlist_put
export def "kkid-userlist-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # userID of the user you wish to update (required)
  --username: string # username of user to create (required)
  --email: string # email address of user to create (required)
  --first-name: string # First Name of user to create (required)
  --last-name: string # Last Name of user to create (required)
  --emoji: string # emoji character for user
  --tmdb-key: string # User's TMdB Session Key
  --enable-wish-list: oneof<nothing, bool> # set status of Wish List module enabled
  --enable-chores: oneof<nothing, bool> # set status of chores module enabled
  --enable-allowance: oneof<nothing, bool> # set status of allowance module enabled
  --enable-admin: oneof<nothing, bool> # set status of isAdmin
  --enable-tmdb: oneof<nothing, bool> # set status of enableTmdb (movie and tv search)
  --enable-object-detection: oneof<nothing, bool> # set status of enableObjectDetection
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/kkid/userlist"
    query: [{name: userID, var: user_id, required: true}, {name: username, var: username, required: true}, {name: email, var: email, required: true}, {name: firstName, var: first_name, required: true}, {name: lastName, var: last_name, required: true}, {name: emoji, var: emoji}, {name: tmdbKey, var: tmdb_key}, {name: enableWishList, var: enable_wish_list}, {name: enableChores, var: enable_chores}, {name: enableAllowance, var: enable_allowance}, {name: enableAdmin, var: enable_admin}, {name: enableTmdb, var: enable_tmdb}, {name: enableObjectDetection, var: enable_object_detection}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: x-auth
  } {
    user_id: $user_id, username: $username, email: $email, first_name: $first_name, last_name: $last_name, emoji: $emoji, tmdb_key: $tmdb_key, enable_wish_list: $enable_wish_list, enable_chores: $enable_chores, enable_allowance: $enable_allowance, enable_admin: $enable_admin, enable_tmdb: $enable_tmdb, enable_object_detection: $enable_object_detection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete item from wishlist
#
# DELETE /kkid/wishlist
# Returns: record<message: string, success: bool>
# operationId: kkid_wishlist_delete
export def "kkid-wishlist-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wish-id: int # ID of wishlist item to delete (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/kkid/wishlist"
    query: [{name: wishId, var: wish_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    wish_id: $wish_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of wishlist items
#
# GET /kkid/wishlist
# Returns: record<success: bool, wish: table<description: string, id: int, link: string, master_id: int, priority: int, title: string, user_id: int>>
# operationId: kkid_wishlist_get
export def "kkid-wishlist-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kkid/wishlist"
    query: [{name: kidUserId, var: kid_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth
  } {
    kid_user_id: $kid_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add item to kid's wishlist
#
# POST /kkid/wishlist
# Returns: record<message: string, success: bool>
# operationId: kkid_wishlist_post
export def "kkid-wishlist-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kid-user-id: int # userID of the kid (required)
  --title: string # Item title (required)
  --description: string # Item Description
  --priority: int # Item Priority
  --link: string # URL Link to item
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/kkid/wishlist"
    query: [{name: kidUserId, var: kid_user_id, required: true}, {name: title, var: title, required: true}, {name: description, var: description}, {name: priority, var: priority}, {name: link, var: link}]
    accept: ["application/json"]
    ok: [201]
    auth: x-auth
  } {
    kid_user_id: $kid_user_id, title: $title, description: $description, priority: $priority, link: $link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update item on kid's wishlist
#
# PUT /kkid/wishlist
# Returns: record<message: string, success: bool>
# operationId: kkid_wishlist_put
export def "kkid-wishlist-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wish-id: int # Wish list item ID to update (required)
  --title: string # Item title
  --description: string # Item Description
  --priority: int # Item Priority
  --link: string # URL Link to item
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/kkid/wishlist"
    query: [{name: wishId, var: wish_id, required: true}, {name: title, var: title}, {name: description, var: description}, {name: priority, var: priority}, {name: link, var: link}]
    accept: ["application/json"]
    ok: [201]
    auth: x-auth
  } {
    wish_id: $wish_id, title: $title, description: $description, priority: $priority, link: $link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
