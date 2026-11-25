# Auto-generated client for Bungie.Net API v2.18.0
# Source: https://api.apis.guru/v2/specs/bungie.net/2.18.0/openapi.json
# Auth: --token flag or $env.BUNGIE_NET_API_TOKEN

const CLIENT = {
  base_url: "https://www.bungie.net/Platform"
  token_env_var: "BUNGIE_NET_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-Key, prefix: ""}
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

def base-url-completer [] { ["https://www.bungie.net/Platform"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    app-get-application-api-usage: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<apiCalls: list<record>, throttledRequests: list<record>>, ThrottleSeconds: int>"
    app-get-bungie-applications: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<applicationId: int, creationDate: string, firstPublished: string, link: string, name: string, origin: string, overrideAuthorizeViewName: string, redirectUrl: string, scope: int, status: int, statusChanged: string, team: list>, ThrottleSeconds: int>"
    community-content-get-community-content: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    content-get-content-by-id: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allowComments: bool, author: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, autoEnglishPropertyFallback: bool, cType: string, cmsPath: string, commentSummary: record<commentCount: int, topicId: int>, contentId: int, creationDate: string, hasAgeGate: bool, minimumAge: int, modifyDate: string, properties: record, ratingImagePath: string, representations: list<record>, tags: list<string>>, ThrottleSeconds: int>"
    content-get-content-by-tag-and-type: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allowComments: bool, author: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, autoEnglishPropertyFallback: bool, cType: string, cmsPath: string, commentSummary: record<commentCount: int, topicId: int>, contentId: int, creationDate: string, hasAgeGate: bool, minimumAge: int, modifyDate: string, properties: record, ratingImagePath: string, representations: list<record>, tags: list<string>>, ThrottleSeconds: int>"
    content-get-content-type: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allowComments: bool, autoEnglishPropertyFallback: bool, bindIdentifierToProperty: string, boundRegex: string, bulkUploadable: bool, cType: string, contentDescription: string, forceIdentifierBinding: bool, name: string, previewImage: string, previews: list<record>, priority: int, properties: list<record>, propertySections: list<record>, reminder: string, showInContentEditor: bool, suppressCmsPath: bool, tagMetadata: list<record>, tagMetadataItems: record, typeOf: string, usageExamples: list<string>>, ThrottleSeconds: int>"
    content-rss-news-articles: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<CategoryFilter: string, CurrentPaginationToken: int, NewsArticles: list<record>, NextPaginationToken: int, ResultCountThisPage: int>, ThrottleSeconds: int>"
    content-search-content-with-text: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    content-search-content-by-tag-and-type: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    content-search-help-articles: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-equip-item: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-equip-items: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<equipResults: list<record>>, ThrottleSeconds: int>"
    destiny2-insert-socket-plug: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<addedInventoryItems: list<record>, item: record<characterId: int, instance: record, item: record, objectives: record, perks: record, plugObjectives: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrid: record>, removedInventoryItems: list<record>>, ThrottleSeconds: int>"
    destiny2-insert-socket-plug-free: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<addedInventoryItems: list<record>, item: record<characterId: int, instance: record, item: record, objectives: record, perks: record, plugObjectives: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrid: record>, removedInventoryItems: list<record>>, ThrottleSeconds: int>"
    destiny2-pull-from-postmaster: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-set-item-lock-state: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-set-quest-tracked-state: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-transfer-item: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-clear-loadout: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-equip-loadout: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-snapshot-loadout: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-update-loadout-identifiers: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-search-destiny-entities: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<results: record<hasMore: bool, query: record, replacementContinuationToken: string, results: list, totalResults: int, useTotalResults: bool>, suggestedWords: list<string>>, ThrottleSeconds: int>"
    destiny2-awa-provide-authorization-result: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-awa-get-action-token: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<actionToken: string, developerNote: string, maximumNumberOfUses: int, membershipType: int, responseReason: int, type: int, userSelection: int, validUntil: string>, ThrottleSeconds: int>"
    destiny2-awa-initialize-request: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<correlationId: string, sentToSelf: bool>, ThrottleSeconds: int>"
    destiny2-get-clan-banner-source: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-get-clan-weekly-reward-state: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: list<record>, availableQuests: list<record>, endDate: string, milestoneHash: int, order: int, rewards: list<record>, startDate: string, values: record, vendorHashes: list<int>, vendors: list<record>>, ThrottleSeconds: int>"
    destiny2-get-destiny-manifest: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<iconImagePyramidInfo: list<record>, jsonWorldComponentContentPaths: record, jsonWorldContentPaths: record, mobileAssetContentPath: string, mobileClanBannerDatabasePath: string, mobileGearAssetDataBases: list<record>, mobileGearCDN: record, mobileWorldContentPaths: record, version: string>, ThrottleSeconds: int>"
    destiny2-get-destiny-entity-definition: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hash: int, index: int, redacted: bool>, ThrottleSeconds: int>"
    destiny2-get-public-milestones: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-get-public-milestone-content: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<about: string, itemCategories: list<record>, status: string, tips: list<string>>, ThrottleSeconds: int>"
    destiny2-search-destiny-player-by-bungie-name: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<applicableMembershipTypes: list, bungieGlobalDisplayName: string, bungieGlobalDisplayNameCode: int, crossSaveOverride: int, displayName: string, iconPath: string, isPublic: bool, membershipId: int, membershipType: int, supplementalDisplayName: string>, ThrottleSeconds: int>"
    destiny2-get-clan-aggregate-stats: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<mode: int, statId: string, value: record>, ThrottleSeconds: int>"
    destiny2-get-historical-stats-definition: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-get-clan-leaderboards: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-get-leaderboards-for-character: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-get-post-game-carnage-report: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activityDetails: record<directorActivityHash: int, instanceId: int, isPrivate: bool, membershipType: int, mode: int, modes: list, referenceId: int>, activityWasStartedFromBeginning: bool, entries: list<record>, period: string, startingPhaseIndex: int, teams: list<record>>, ThrottleSeconds: int>"
    destiny2-report-offensive-post-game-carnage-report-player: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    destiny2-get-public-vendors: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: record<data: record, disabled: bool, privacy: int>, sales: record<data: record, disabled: bool, privacy: int>, stringVariables: record<data: record, disabled: bool, privacy: int>, vendorGroups: record<data: record, disabled: bool, privacy: int>, vendors: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>"
    destiny2-get-historical-stats: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-get-activity-history: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: list<record>>, ThrottleSeconds: int>"
    destiny2-get-destiny-aggregate-activity-stats: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: list<record>>, ThrottleSeconds: int>"
    destiny2-get-unique-weapon-history: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<weapons: list<record>>, ThrottleSeconds: int>"
    destiny2-get-historical-stats-for-account: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<characters: list<record>, mergedAllCharacters: record<merged: record, results: record>, mergedDeletedCharacters: record<merged: record, results: record>>, ThrottleSeconds: int>"
    destiny2-get-leaderboards: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    destiny2-get-profile: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<characterActivities: record<data: record, disabled: bool, privacy: int>, characterCollectibles: record<data: record, disabled: bool, privacy: int>, characterCraftables: record<data: record, disabled: bool, privacy: int>, characterCurrencyLookups: record<data: record, disabled: bool, privacy: int>, characterEquipment: record<data: record, disabled: bool, privacy: int>, characterInventories: record<data: record, disabled: bool, privacy: int>, characterKiosks: record<data: record, disabled: bool, privacy: int>, characterLoadouts: record<data: record, disabled: bool, privacy: int>, characterPlugSets: record<data: record, disabled: bool, privacy: int>, characterPresentationNodes: record<data: record, disabled: bool, privacy: int>, characterProgressions: record<data: record, disabled: bool, privacy: int>, characterRecords: record<data: record, disabled: bool, privacy: int>, characterRenderData: record<data: record, disabled: bool, privacy: int>, characterStringVariables: record<data: record, disabled: bool, privacy: int>, characterUninstancedItemComponents: record, characters: record<data: record, disabled: bool, privacy: int>, itemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, metrics: record<data: record, disabled: bool, privacy: int>, platformSilver: record<data: record, disabled: bool, privacy: int>, profile: record<data: record, disabled: bool, privacy: int>, profileCollectibles: record<data: record, disabled: bool, privacy: int>, profileCommendations: record<data: record, disabled: bool, privacy: int>, profileCurrencies: record<data: record, disabled: bool, privacy: int>, profileInventory: record<data: record, disabled: bool, privacy: int>, profileKiosks: record<data: record, disabled: bool, privacy: int>, profilePlugSets: record<data: record, disabled: bool, privacy: int>, profilePresentationNodes: record<data: record, disabled: bool, privacy: int>, profileProgression: record<data: record, disabled: bool, privacy: int>, profileRecords: record<data: record, disabled: bool, privacy: int>, profileStringVariables: record<data: record, disabled: bool, privacy: int>, profileTransitoryData: record<data: record, disabled: bool, privacy: int>, responseMintedTimestamp: string, secondaryComponentsMintedTimestamp: string, vendorReceipts: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>"
    destiny2-get-character: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: record<data: record, disabled: bool, privacy: int>, character: record<data: record, disabled: bool, privacy: int>, collectibles: record<data: record, disabled: bool, privacy: int>, currencyLookups: record<data: record, disabled: bool, privacy: int>, equipment: record<data: record, disabled: bool, privacy: int>, inventory: record<data: record, disabled: bool, privacy: int>, itemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, kiosks: record<data: record, disabled: bool, privacy: int>, loadouts: record<data: record, disabled: bool, privacy: int>, plugSets: record<data: record, disabled: bool, privacy: int>, presentationNodes: record<data: record, disabled: bool, privacy: int>, progressions: record<data: record, disabled: bool, privacy: int>, records: record<data: record, disabled: bool, privacy: int>, renderData: record<data: record, disabled: bool, privacy: int>, uninstancedItemComponents: record<objectives: record, perks: record>>, ThrottleSeconds: int>"
    destiny2-get-collectible-node-details: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<collectibleItemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, collectibles: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>"
    destiny2-get-vendors: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: record<data: record, disabled: bool, privacy: int>, currencyLookups: record<data: record, disabled: bool, privacy: int>, itemComponents: record, sales: record<data: record, disabled: bool, privacy: int>, stringVariables: record<data: record, disabled: bool, privacy: int>, vendorGroups: record<data: record, disabled: bool, privacy: int>, vendors: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>"
    destiny2-get-vendor: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: record<data: record, disabled: bool, privacy: int>, currencyLookups: record<data: record, disabled: bool, privacy: int>, itemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, sales: record<data: record, disabled: bool, privacy: int>, stringVariables: record<data: record, disabled: bool, privacy: int>, vendor: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>"
    destiny2-get-item: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<characterId: int, instance: record<data: record, disabled: bool, privacy: int>, item: record<data: record, disabled: bool, privacy: int>, objectives: record<data: record, disabled: bool, privacy: int>, perks: record<data: record, disabled: bool, privacy: int>, plugObjectives: record<data: record, disabled: bool, privacy: int>, renderData: record<data: record, disabled: bool, privacy: int>, reusablePlugs: record<data: record, disabled: bool, privacy: int>, sockets: record<data: record, disabled: bool, privacy: int>, stats: record<data: record, disabled: bool, privacy: int>, talentGrid: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>"
    destiny2-get-linked-profiles: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<bnetMembership: record<applicableMembershipTypes: list, bungieGlobalDisplayName: string, bungieGlobalDisplayNameCode: int, crossSaveOverride: int, displayName: string, iconPath: string, isPublic: bool, membershipId: int, membershipType: int, supplementalDisplayName: string>, profiles: list<record>, profilesWithErrors: list<record>>, ThrottleSeconds: int>"
    fireteam-get-active-private-clan-fireteam-count: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    fireteam-get-available-clan-fireteams: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    fireteam-get-my-clan-fireteams: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    fireteam-get-clan-fireteam: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<Alternates: list<record>, Members: list<record>, Summary: record<activityType: int, alternateSlotCount: int, availableAlternateSlotCount: int, availablePlayerSlotCount: int, dateCreated: string, dateModified: string, datePlayerModified: string, fireteamId: int, groupId: int, isImmediate: bool, isPublic: bool, isValid: bool, locale: string, ownerCurrentGuardianRankSnapshot: int, ownerHighestLifetimeGuardianRankSnapshot: int, ownerMembershipId: int, ownerTotalCommendationScoreSnapshot: int, platform: int, playerSlotCount: int, scheduledTime: string, title: string, titleBeforeModeration: string>>, ThrottleSeconds: int>"
    fireteam-search-public-available-clan-fireteams: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-core-topics-paged: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-forum-tag-suggestions: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<ignoreStatus: record, tagText: string>, ThrottleSeconds: int>"
    forum-get-post-and-parent: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-post-and-parent-awaiting-approval: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-posts-threaded-paged: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-posts-threaded-paged-from-child: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-topic-for-content: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    forum-get-topics-paged: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-poll: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    forum-get-recruitment-thread-summaries: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<Fireteam: list, approved: bool, conversationId: int, intensity: int, kickedPlayerIds: list, microphoneRequired: bool, playerSlotsRemaining: int, playerSlotsTotal: int, tone: int, topicId: int>, ThrottleSeconds: int>"
    get-available-locales: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    get-global-alerts: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<AlertHtml: string, AlertKey: string, AlertLevel: int, AlertLink: string, AlertTimestamp: string, AlertType: int, StreamInfo: record>, ThrottleSeconds: int>"
    group-v2-get-available-avatars: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    group-v2-get-available-themes: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<description: string, folder: string, name: string>, ThrottleSeconds: int>"
    group-v2-get-user-clan-invite-setting: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    group-v2-get-group-by-name: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allianceStatus: int, alliedIds: list<int>, currentUserMemberMap: record, currentUserMembershipsInactiveForDestiny: bool, currentUserPotentialMemberMap: record, detail: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, founder: record<bungieNetUserInfo: record, destinyUserInfo: record, groupId: int, isOnline: bool, joinDate: string, lastOnlineStatusChange: int, memberType: int>, groupJoinInviteCount: int, parentGroup: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>>, ThrottleSeconds: int>"
    group-v2-get-group-by-name-v2: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allianceStatus: int, alliedIds: list<int>, currentUserMemberMap: record, currentUserMembershipsInactiveForDestiny: bool, currentUserPotentialMemberMap: record, detail: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, founder: record<bungieNetUserInfo: record, destinyUserInfo: record, groupId: int, isOnline: bool, joinDate: string, lastOnlineStatusChange: int, memberType: int>, groupJoinInviteCount: int, parentGroup: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>>, ThrottleSeconds: int>"
    group-v2-get-recommended-groups: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<about: string, avatarPath: string, capabilities: int, clanInfo: record, creationDate: string, groupId: int, groupType: int, locale: string, memberCount: int, membershipOption: int, motto: string, name: string, theme: string>, ThrottleSeconds: int>"
    group-v2-recover-group-for-founder: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-group-search: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-get-potential-groups-for-member: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-get-groups-for-member: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<areAllMembershipsInactive: record, hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-get-group: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allianceStatus: int, alliedIds: list<int>, currentUserMemberMap: record, currentUserMembershipsInactiveForDestiny: bool, currentUserPotentialMemberMap: record, detail: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, founder: record<bungieNetUserInfo: record, destinyUserInfo: record, groupId: int, isOnline: bool, joinDate: string, lastOnlineStatusChange: int, memberType: int>, groupJoinInviteCount: int, parentGroup: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>>, ThrottleSeconds: int>"
    group-v2-abdicate-foundership: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    group-v2-get-admins-and-founder-of-group: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-get-banned-members-of-group: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-edit-group: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    group-v2-edit-clan-banner: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    group-v2-edit-founder-options: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    group-v2-get-members-of-group: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-approve-pending: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    group-v2-approve-all-pending: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>"
    group-v2-approve-pending-for-list: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>"
    group-v2-deny-all-pending: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>"
    group-v2-deny-pending-for-list: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>"
    group-v2-individual-group-invite: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<resolution: int>, ThrottleSeconds: int>"
    group-v2-individual-group-invite-cancel: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<resolution: int>, ThrottleSeconds: int>"
    group-v2-get-invited-individuals: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-get-pending-memberships: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    group-v2-ban-member: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    group-v2-kick-member: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<group: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, groupDeleted: bool>, ThrottleSeconds: int>"
    group-v2-edit-group-membership: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    group-v2-unban-member: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    group-v2-get-group-optional-conversations: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<chatEnabled: bool, chatName: string, chatSecurity: int, conversationId: int, groupId: int>, ThrottleSeconds: int>"
    group-v2-add-optional-conversation: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    group-v2-edit-optional-conversation: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>"
    get-common-settings: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<clanBannerDecalColors: list<record>, clanBannerDecals: list<record>, clanBannerGonfalonColors: list<record>, clanBannerGonfalonDetailColors: list<record>, clanBannerGonfalonDetails: list<record>, clanBannerGonfalons: list<record>, clanBannerStandards: list<record>, defaultGroupTheme: record<childSettings: list, displayName: string, identifier: string, imagePath: string, isDefault: bool, summary: string>, destiny2CoreSettings: record<activeSealsRootNodeHash: int, activeTriumphsRootNodeHash: int, ammoTypeHeavyIcon: string, ammoTypePrimaryIcon: string, ammoTypeSpecialIcon: string, badgesRootNode: int, collectionRootNode: int, craftingRootNodeHash: int, currentRankProgressionHashes: list, currentSeasonHash: int, currentSeasonalArtifactHash: int, exoticCatalystsRootNodeHash: int, futureSeasonHashes: list, guardianRankConstantsHash: int, guardianRanksRootNodeHash: int, insertPlugFreeBlockedSocketTypeHashes: list, insertPlugFreeProtectedPlugItemHashes: list, legacySealsRootNodeHash: int, legacyTriumphsRootNodeHash: int, loadoutConstantsHash: int, loreRootNodeHash: int, medalsRootNode: int, medalsRootNodeHash: int, metricsRootNode: int, pastSeasonHashes: list, recordsRootNode: int, seasonalChallengesPresentationNodeHash: int, undiscoveredCollectibleImage: string>, destinyMembershipTypes: list<record>, emailSettings: record<optInDefinitions: record, subscriptionDefinitions: record, views: record>, environment: string, fireteamActivities: list<record>, forumCategories: list<record>, groupAvatars: list<record>, ignoreReasons: list<record>, recruitmentActivities: list<record>, recruitmentMiscTags: list<record>, recruitmentPlatformTags: list<record>, systemContentLocales: list<record>, systems: record, userContentLocales: list<record>>, ThrottleSeconds: int>"
    social-get-friend-list: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<friends: list<record>>, ThrottleSeconds: int>"
    social-issue-friend-request: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    social-remove-friend: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    social-get-friend-request-list: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<incomingRequests: list<record>, outgoingRequests: list<record>>, ThrottleSeconds: int>"
    social-accept-friend-request: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    social-decline-friend-request: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    social-remove-friend-request: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    social-get-platform-friend-list: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<currentPage: int, hasMore: bool, itemsPerPage: int, platformFriends: list<record>>, ThrottleSeconds: int>"
    tokens-apply-missing-partner-offers-without-claim: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    tokens-claim-partner-offer: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    tokens-force-drops-repair: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>"
    tokens-get-partner-offer-sku-history: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<AllOffersApplied: bool, ClaimDate: string, LocalizedDescription: string, LocalizedName: string, SkuIdentifier: string, SkuOffers: list, TransactionId: string>, ThrottleSeconds: int>"
    tokens-get-partner-reward-history: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<PartnerOffers: list<record>, TwitchDrops: list<record>>, ThrottleSeconds: int>"
    tokens-get-bungie-rewards-list: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    tokens-get-bungie-rewards-for-platform-user: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    tokens-get-bungie-rewards-for-user: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    trending-get-trending-categories: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: list<record>>, ThrottleSeconds: int>"
    trending-get-trending-category: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>"
    trending-get-trending-entry-detail: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<creation: record<author: string, authorMembershipId: int, body: string, media: string, postId: int, title: string, upvotes: int>, destinyActivity: record<activityHash: int, status: record>, destinyItem: record<itemHash: int>, destinyRitual: record<dateEnd: string, dateStart: string, eventContent: record, icon: string, image: string, milestoneDetails: record, subtitle: string, title: string>, entityType: int, identifier: string, news: record<article: record>, support: record<article: record>>, ThrottleSeconds: int>"
    user-get-available-themes: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<userThemeDescription: string, userThemeId: int, userThemeName: string>, ThrottleSeconds: int>"
    user-get-bungie-net-user-by-id: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record<globalIgnoreEndDate: string, ignoreStatus: record, isFollowing: bool>, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, ThrottleSeconds: int>"
    user-get-credential-types-for-target-account: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<credentialAsString: string, credentialDisplayName: string, credentialType: int, isPublic: bool>, ThrottleSeconds: int>"
    user-get-membership-from-hard-linked-credential: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<CrossSaveOverriddenMembershipId: int, CrossSaveOverriddenType: int, membershipId: int, membershipType: int>, ThrottleSeconds: int>"
    user-get-membership-data-by-id: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<bungieNetUser: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, destinyMemberships: list<record>, primaryMembershipId: int>, ThrottleSeconds: int>"
    user-get-membership-data-for-current-user: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<bungieNetUser: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, destinyMemberships: list<record>, primaryMembershipId: int>, ThrottleSeconds: int>"
    user-get-sanitized-platform-display-names: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
    user-search-by-global-name-post: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, page: int, searchResults: list<record>>, ThrottleSeconds: int>"
    user-search-by-global-name-prefix: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, page: int, searchResults: list<record>>, ThrottleSeconds: int>"
    get-user-system-overrides: "record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["app-get-application-api-usage" "app-get-bungie-applications" "community-content-get-community-content" "content-get-content-by-id" "content-get-content-by-tag-and-type" "content-get-content-type" "content-rss-news-articles" "content-search-content-with-text" "content-search-content-by-tag-and-type" "content-search-help-articles" "destiny2-equip-item" "destiny2-equip-items" "destiny2-insert-socket-plug" "destiny2-insert-socket-plug-free" "destiny2-pull-from-postmaster" "destiny2-set-item-lock-state" "destiny2-set-quest-tracked-state" "destiny2-transfer-item" "destiny2-clear-loadout" "destiny2-equip-loadout" "destiny2-snapshot-loadout" "destiny2-update-loadout-identifiers" "destiny2-search-destiny-entities" "destiny2-awa-provide-authorization-result" "destiny2-awa-get-action-token" "destiny2-awa-initialize-request" "destiny2-get-clan-banner-source" "destiny2-get-clan-weekly-reward-state" "destiny2-get-destiny-manifest" "destiny2-get-destiny-entity-definition" "destiny2-get-public-milestones" "destiny2-get-public-milestone-content" "destiny2-search-destiny-player-by-bungie-name" "destiny2-get-clan-aggregate-stats" "destiny2-get-historical-stats-definition" "destiny2-get-clan-leaderboards" "destiny2-get-leaderboards-for-character" "destiny2-get-post-game-carnage-report" "destiny2-report-offensive-post-game-carnage-report-player" "destiny2-get-public-vendors" "destiny2-get-historical-stats" "destiny2-get-activity-history" "destiny2-get-destiny-aggregate-activity-stats" "destiny2-get-unique-weapon-history" "destiny2-get-historical-stats-for-account" "destiny2-get-leaderboards" "destiny2-get-profile" "destiny2-get-character" "destiny2-get-collectible-node-details" "destiny2-get-vendors" "destiny2-get-vendor" "destiny2-get-item" "destiny2-get-linked-profiles" "fireteam-get-active-private-clan-fireteam-count" "fireteam-get-available-clan-fireteams" "fireteam-get-my-clan-fireteams" "fireteam-get-clan-fireteam" "fireteam-search-public-available-clan-fireteams" "forum-get-core-topics-paged" "forum-get-forum-tag-suggestions" "forum-get-post-and-parent" "forum-get-post-and-parent-awaiting-approval" "forum-get-posts-threaded-paged" "forum-get-posts-threaded-paged-from-child" "forum-get-topic-for-content" "forum-get-topics-paged" "forum-get-poll" "forum-get-recruitment-thread-summaries" "get-available-locales" "get-global-alerts" "group-v2-get-available-avatars" "group-v2-get-available-themes" "group-v2-get-user-clan-invite-setting" "group-v2-get-group-by-name" "group-v2-get-group-by-name-v2" "group-v2-get-recommended-groups" "group-v2-recover-group-for-founder" "group-v2-group-search" "group-v2-get-potential-groups-for-member" "group-v2-get-groups-for-member" "group-v2-get-group" "group-v2-abdicate-foundership" "group-v2-get-admins-and-founder-of-group" "group-v2-get-banned-members-of-group" "group-v2-edit-group" "group-v2-edit-clan-banner" "group-v2-edit-founder-options" "group-v2-get-members-of-group" "group-v2-approve-pending" "group-v2-approve-all-pending" "group-v2-approve-pending-for-list" "group-v2-deny-all-pending" "group-v2-deny-pending-for-list" "group-v2-individual-group-invite" "group-v2-individual-group-invite-cancel" "group-v2-get-invited-individuals" "group-v2-get-pending-memberships" "group-v2-ban-member" "group-v2-kick-member" "group-v2-edit-group-membership" "group-v2-unban-member" "group-v2-get-group-optional-conversations" "group-v2-add-optional-conversation" "group-v2-edit-optional-conversation" "get-common-settings" "social-get-friend-list" "social-issue-friend-request" "social-remove-friend" "social-get-friend-request-list" "social-accept-friend-request" "social-decline-friend-request" "social-remove-friend-request" "social-get-platform-friend-list" "tokens-apply-missing-partner-offers-without-claim" "tokens-claim-partner-offer" "tokens-force-drops-repair" "tokens-get-partner-offer-sku-history" "tokens-get-partner-reward-history" "tokens-get-bungie-rewards-list" "tokens-get-bungie-rewards-for-platform-user" "tokens-get-bungie-rewards-for-user" "trending-get-trending-categories" "trending-get-trending-category" "trending-get-trending-entry-detail" "user-get-available-themes" "user-get-bungie-net-user-by-id" "user-get-credential-types-for-target-account" "user-get-membership-from-hard-linked-credential" "user-get-membership-data-by-id" "user-get-membership-data-for-current-user" "user-get-sanitized-platform-display-names" "user-search-by-global-name-post" "user-search-by-global-name-prefix" "get-user-system-overrides" "commands"] | sort) } | get name | first)
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

# Get API usage by application for time frame specified. You can go as far back as 30 days ago, and can ask for up to a 48 hour window of time in a single request. You must be authenticated with at least the ReadUserData permission to access this endpoint.
#
# GET /App/ApiUsage/{applicationId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<apiCalls: list<record>, throttledRequests: list<record>>, ThrottleSeconds: int>
# operationId: App.GetApplicationApiUsage
export def "app-get-application-api-usage" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end: string # End time for query. Goes to now if not specified. (format: date-time)
  --start: string # Start time for query. Goes to 24 hours ago if not specified. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/App/ApiUsage/{applicationId}/"
    path_params: [{name: applicationId, var: application_id}]
    query: [{name: end, var: end}, {name: start, var: start}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    application_id: $application_id, end: $end, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of applications created by Bungie.
#
# GET /App/FirstParty/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<applicationId: int, creationDate: string, firstPublished: string, link: string, name: string, origin: string, overrideAuthorizeViewName: string, redirectUrl: string, scope: int, status: int, statusChanged: string, team: list>, ThrottleSeconds: int>
# operationId: App.GetBungieApplications
export def "app-get-bungie-applications" [
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
    path: "/App/FirstParty/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns community content.
#
# GET /CommunityContent/Get/{sort}/{mediaFilter}/{page}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: CommunityContent.GetCommunityContent
export def "community-content-get-community-content" [
  sort: int
  media_filter: int
  page: int
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
    path: "/CommunityContent/Get/{sort}/{mediaFilter}/{page}/"
    path_params: [{name: sort, var: sort}, {name: mediaFilter, var: media_filter}, {name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    sort: $sort, media_filter: $media_filter, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a content item referenced by id
#
# GET /Content/GetContentById/{id}/{locale}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allowComments: bool, author: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, autoEnglishPropertyFallback: bool, cType: string, cmsPath: string, commentSummary: record<commentCount: int, topicId: int>, contentId: int, creationDate: string, hasAgeGate: bool, minimumAge: int, modifyDate: string, properties: record, ratingImagePath: string, representations: list<record>, tags: list<string>>, ThrottleSeconds: int>
# operationId: Content.GetContentById
export def "content-get-content-by-id" [
  id: int
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --head: oneof<nothing, bool> # false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Content/GetContentById/{id}/{locale}/"
    path_params: [{name: id, var: id}, {name: locale, var: locale}]
    query: [{name: head, var: head}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, locale: $locale, head: $head
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the newest item that matches a given tag and Content Type.
#
# GET /Content/GetContentByTagAndType/{tag}/{type}/{locale}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allowComments: bool, author: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, autoEnglishPropertyFallback: bool, cType: string, cmsPath: string, commentSummary: record<commentCount: int, topicId: int>, contentId: int, creationDate: string, hasAgeGate: bool, minimumAge: int, modifyDate: string, properties: record, ratingImagePath: string, representations: list<record>, tags: list<string>>, ThrottleSeconds: int>
# operationId: Content.GetContentByTagAndType
export def "content-get-content-by-tag-and-type" [
  tag: string
  type: string
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --head: oneof<nothing, bool> # Not used.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Content/GetContentByTagAndType/{tag}/{type}/{locale}/"
    path_params: [{name: tag, var: tag}, {name: type, var: type}, {name: locale, var: locale}]
    query: [{name: head, var: head}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    tag: $tag, type: $type, locale: $locale, head: $head
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an object describing a particular variant of content.
#
# GET /Content/GetContentType/{type}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allowComments: bool, autoEnglishPropertyFallback: bool, bindIdentifierToProperty: string, boundRegex: string, bulkUploadable: bool, cType: string, contentDescription: string, forceIdentifierBinding: bool, name: string, previewImage: string, previews: list<record>, priority: int, properties: list<record>, propertySections: list<record>, reminder: string, showInContentEditor: bool, suppressCmsPath: bool, tagMetadata: list<record>, tagMetadataItems: record, typeOf: string, usageExamples: list<string>>, ThrottleSeconds: int>
# operationId: Content.GetContentType
export def "content-get-content-type" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Content/GetContentType/{type}/"
    path_params: [{name: type, var: type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a JSON string response that is the RSS feed for news articles.
#
# GET /Content/Rss/NewsArticles/{pageToken}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<CategoryFilter: string, CurrentPaginationToken: int, NewsArticles: list<record>, NextPaginationToken: int, ResultCountThisPage: int>, ThrottleSeconds: int>
# operationId: Content.RssNewsArticles
export def "content-rss-news-articles" [
  page_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categoryfilter: string # Optionally filter response to only include news items in a certain category.
  --includebody: oneof<nothing, bool> # Optionally include full content body for each news item.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Content/Rss/NewsArticles/{pageToken}/"
    path_params: [{name: pageToken, var: page_token}]
    query: [{name: categoryfilter, var: categoryfilter}, {name: includebody, var: includebody}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    page_token: $page_token, categoryfilter: $categoryfilter, includebody: $includebody
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets content based on querystring information passed in. Provides basic search and text search capabilities.
#
# GET /Content/Search/{locale}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Content.SearchContentWithText
export def "content-search-content-with-text" [
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ctype: string # Content type tag: Help, News, etc. Supply multiple ctypes separated by space.
  --currentpage: int # Page number for the search results, starting with page 1. (format: int32)
  --head: oneof<nothing, bool> # Not used.
  --searchtext: string # Word or phrase for the search.
  --source: string # For analytics, hint at the part of the app that triggered the search. Optional.
  --tag: string # Tag used on the content to be searched.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Content/Search/{locale}/"
    path_params: [{name: locale, var: locale}]
    query: [{name: ctype, var: ctype}, {name: currentpage, var: currentpage}, {name: head, var: head}, {name: searchtext, var: searchtext}, {name: source, var: source}, {name: tag, var: tag}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    locale: $locale, ctype: $ctype, currentpage: $currentpage, head: $head, searchtext: $searchtext, source: $source, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for Content Items that match the given Tag and Content Type.
#
# GET /Content/SearchContentByTagAndType/{tag}/{type}/{locale}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Content.SearchContentByTagAndType
export def "content-search-content-by-tag-and-type" [
  tag: string
  type: string
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number for the search results starting with page 1. (format: int32)
  --head: oneof<nothing, bool> # Not used.
  --itemsperpage: int # Not used. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Content/SearchContentByTagAndType/{tag}/{type}/{locale}/"
    path_params: [{name: tag, var: tag}, {name: type, var: type}, {name: locale, var: locale}]
    query: [{name: currentpage, var: currentpage}, {name: head, var: head}, {name: itemsperpage, var: itemsperpage}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    tag: $tag, type: $type, locale: $locale, currentpage: $currentpage, head: $head, itemsperpage: $itemsperpage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for Help Articles.
#
# GET /Content/SearchHelpArticles/{searchtext}/{size}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Content.SearchHelpArticles
export def "content-search-help-articles" [
  searchtext: string
  size: string
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
    path: "/Content/SearchHelpArticles/{searchtext}/{size}/"
    path_params: [{name: searchtext, var: searchtext}, {name: size, var: size}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    searchtext: $searchtext, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equip an item. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Items/EquipItem/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.EquipItem
export def "destiny2-equip-item" [
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
    path: "/Destiny2/Actions/Items/EquipItem/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equip a list of items by itemInstanceIds. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline. Any items not found on your character will be ignored.
#
# POST /Destiny2/Actions/Items/EquipItems/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<equipResults: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.EquipItems
export def "destiny2-equip-items" [
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
    path: "/Destiny2/Actions/Items/EquipItems/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert a plug into a socketed item. I know how it sounds, but I assure you it's much more G-rated than you might be guessing. We haven't decided yet whether this will be able to insert plugs that have side effects, but if we do it will require special scope permission for an application attempting to do so. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline. Request must include proof of permission for 'InsertPlugs' from the account owner.
#
# POST /Destiny2/Actions/Items/InsertSocketPlug/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<addedInventoryItems: list<record>, item: record<characterId: int, instance: record, item: record, objectives: record, perks: record, plugObjectives: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrid: record>, removedInventoryItems: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.InsertSocketPlug
export def "destiny2-insert-socket-plug" [
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
    path: "/Destiny2/Actions/Items/InsertSocketPlug/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert a 'free' plug into an item's socket. This does not require 'Advanced Write Action' authorization and is available to 3rd-party apps, but will only work on 'free and reversible' socket actions (Perks, Armor Mods, Shaders, Ornaments, etc.). You must have a valid Destiny Account, and the character must either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Items/InsertSocketPlugFree/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<addedInventoryItems: list<record>, item: record<characterId: int, instance: record, item: record, objectives: record, perks: record, plugObjectives: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrid: record>, removedInventoryItems: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.InsertSocketPlugFree
export def "destiny2-insert-socket-plug-free" [
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
    path: "/Destiny2/Actions/Items/InsertSocketPlugFree/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extract an item from the Postmaster, with whatever implications that may entail. You must have a valid Destiny account. You must also pass BOTH a reference AND an instance ID if it's an instanced item.
#
# POST /Destiny2/Actions/Items/PullFromPostmaster/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.PullFromPostmaster
export def "destiny2-pull-from-postmaster" [
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
    path: "/Destiny2/Actions/Items/PullFromPostmaster/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the Lock State for an instanced item. You must have a valid Destiny Account.
#
# POST /Destiny2/Actions/Items/SetLockState/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.SetItemLockState
export def "destiny2-set-item-lock-state" [
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
    path: "/Destiny2/Actions/Items/SetLockState/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the Tracking State for an instanced item, if that item is a Quest or Bounty. You must have a valid Destiny Account. Yeah, it's an item.
#
# POST /Destiny2/Actions/Items/SetTrackedState/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.SetQuestTrackedState
export def "destiny2-set-quest-tracked-state" [
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
    path: "/Destiny2/Actions/Items/SetTrackedState/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer an item to/from your vault. You must have a valid Destiny account. You must also pass BOTH a reference AND an instance ID if it's an instanced item. itshappening.gif
#
# POST /Destiny2/Actions/Items/TransferItem/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.TransferItem
export def "destiny2-transfer-item" [
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
    path: "/Destiny2/Actions/Items/TransferItem/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear the identifiers and items of a loadout.
#
# POST /Destiny2/Actions/Loadouts/ClearLoadout/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.ClearLoadout
export def "destiny2-clear-loadout" [
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
    path: "/Destiny2/Actions/Loadouts/ClearLoadout/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equip a loadout. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Loadouts/EquipLoadout/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.EquipLoadout
export def "destiny2-equip-loadout" [
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
    path: "/Destiny2/Actions/Loadouts/EquipLoadout/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Snapshot a loadout with the currently equipped items.
#
# POST /Destiny2/Actions/Loadouts/SnapshotLoadout/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.SnapshotLoadout
export def "destiny2-snapshot-loadout" [
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
    path: "/Destiny2/Actions/Loadouts/SnapshotLoadout/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the color, icon, and name of a loadout.
#
# POST /Destiny2/Actions/Loadouts/UpdateLoadoutIdentifiers/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.UpdateLoadoutIdentifiers
export def "destiny2-update-loadout-identifiers" [
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
    path: "/Destiny2/Actions/Loadouts/UpdateLoadoutIdentifiers/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a page list of Destiny items.
#
# GET /Destiny2/Armory/Search/{type}/{searchTerm}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<results: record<hasMore: bool, query: record, replacementContinuationToken: string, results: list, totalResults: int, useTotalResults: bool>, suggestedWords: list<string>>, ThrottleSeconds: int>
# operationId: Destiny2.SearchDestinyEntities
export def "destiny2-search-destiny-entities" [
  type: string
  search_term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number to return, starting with 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/Armory/Search/{type}/{searchTerm}/"
    path_params: [{name: type, var: type}, {name: searchTerm, var: search_term}]
    query: [{name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    type: $type, search_term: $search_term, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provide the result of the user interaction. Called by the Bungie Destiny App to approve or reject a request.
#
# POST /Destiny2/Awa/AwaProvideAuthorizationResult/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.AwaProvideAuthorizationResult
export def "destiny2-awa-provide-authorization-result" [
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
    path: "/Destiny2/Awa/AwaProvideAuthorizationResult/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the action token if user approves the request.
#
# GET /Destiny2/Awa/GetActionToken/{correlationId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<actionToken: string, developerNote: string, maximumNumberOfUses: int, membershipType: int, responseReason: int, type: int, userSelection: int, validUntil: string>, ThrottleSeconds: int>
# operationId: Destiny2.AwaGetActionToken
export def "destiny2-awa-get-action-token" [
  correlation_id: string
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
    path: "/Destiny2/Awa/GetActionToken/{correlationId}/"
    path_params: [{name: correlationId, var: correlation_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    correlation_id: $correlation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initialize a request to perform an advanced write action.
#
# POST /Destiny2/Awa/Initialize/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<correlationId: string, sentToSelf: bool>, ThrottleSeconds: int>
# operationId: Destiny2.AwaInitializeRequest
export def "destiny2-awa-initialize-request" [
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
    path: "/Destiny2/Awa/Initialize/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the dictionary of values for the Clan Banner
#
# GET /Destiny2/Clan/ClanBannerDictionary/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Destiny2.GetClanBannerSource
export def "destiny2-get-clan-banner-source" [
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
    path: "/Destiny2/Clan/ClanBannerDictionary/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information on the weekly clan rewards and if the clan has earned them or not. Note that this will always report rewards as not redeemed.
#
# GET /Destiny2/Clan/{groupId}/WeeklyRewardState/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: list<record>, availableQuests: list<record>, endDate: string, milestoneHash: int, order: int, rewards: list<record>, startDate: string, values: record, vendorHashes: list<int>, vendors: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetClanWeeklyRewardState
export def "destiny2-get-clan-weekly-reward-state" [
  group_id: int
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
    path: "/Destiny2/Clan/{groupId}/WeeklyRewardState/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current version of the manifest as a json object.
#
# GET /Destiny2/Manifest/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<iconImagePyramidInfo: list<record>, jsonWorldComponentContentPaths: record, jsonWorldContentPaths: record, mobileAssetContentPath: string, mobileClanBannerDatabasePath: string, mobileGearAssetDataBases: list<record>, mobileGearCDN: record, mobileWorldContentPaths: record, version: string>, ThrottleSeconds: int>
# operationId: Destiny2.GetDestinyManifest
export def "destiny2-get-destiny-manifest" [
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
    path: "/Destiny2/Manifest/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the static definition of an entity of the given Type and hash identifier. Examine the API Documentation for the Type Names of entities that have their own definitions. Note that the return type will always *inherit from* DestinyDefinition, but the specific type returned will be the requested entity type if it can be found. Please don't use this as a chatty alternative to the Manifest database if you require large sets of data, but for simple and one-off accesses this should be handy.
#
# GET /Destiny2/Manifest/{entityType}/{hashIdentifier}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hash: int, index: int, redacted: bool>, ThrottleSeconds: int>
# operationId: Destiny2.GetDestinyEntityDefinition
export def "destiny2-get-destiny-entity-definition" [
  entity_type: string
  hash_identifier: int
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
    path: "/Destiny2/Manifest/{entityType}/{hashIdentifier}/"
    path_params: [{name: entityType, var: entity_type}, {name: hashIdentifier, var: hash_identifier}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    entity_type: $entity_type, hash_identifier: $hash_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets public information about currently available Milestones.
#
# GET /Destiny2/Milestones/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Destiny2.GetPublicMilestones
export def "destiny2-get-public-milestones" [
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
    path: "/Destiny2/Milestones/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets custom localized content for the milestone of the given hash, if it exists.
#
# GET /Destiny2/Milestones/{milestoneHash}/Content/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<about: string, itemCategories: list<record>, status: string, tips: list<string>>, ThrottleSeconds: int>
# operationId: Destiny2.GetPublicMilestoneContent
export def "destiny2-get-public-milestone-content" [
  milestone_hash: int
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
    path: "/Destiny2/Milestones/{milestoneHash}/Content/"
    path_params: [{name: milestoneHash, var: milestone_hash}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    milestone_hash: $milestone_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Destiny memberships given a global Bungie Display Name. This method will hide overridden memberships due to cross save.
#
# POST /Destiny2/SearchDestinyPlayerByBungieName/{membershipType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<applicableMembershipTypes: list, bungieGlobalDisplayName: string, bungieGlobalDisplayNameCode: int, crossSaveOverride: int, displayName: string, iconPath: string, isPublic: bool, membershipId: int, membershipType: int, supplementalDisplayName: string>, ThrottleSeconds: int>
# operationId: Destiny2.SearchDestinyPlayerByBungieName
export def "destiny2-search-destiny-player-by-bungie-name" [
  membership_type: int
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
    path: "/Destiny2/SearchDestinyPlayerByBungieName/{membershipType}/"
    path_params: [{name: membershipType, var: membership_type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets aggregated stats for a clan using the same categories as the clan leaderboards. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/AggregateClanStats/{groupId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<mode: int, statId: string, value: record>, ThrottleSeconds: int>
# operationId: Destiny2.GetClanAggregateStats
export def "destiny2-get-clan-aggregate-stats" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/Stats/AggregateClanStats/{groupId}/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: modes, var: modes}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id, modes: $modes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets historical stats definitions.
#
# GET /Destiny2/Stats/Definition/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Destiny2.GetHistoricalStatsDefinition
export def "destiny2-get-historical-stats-definition" [
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
    path: "/Destiny2/Stats/Definition/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/Leaderboards/Clans/{groupId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Destiny2.GetClanLeaderboards
export def "destiny2-get-clan-leaderboards" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/Stats/Leaderboards/Clans/{groupId}/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: maxtop, var: maxtop}, {name: modes, var: modes}, {name: statid, var: statid}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id, maxtop: $maxtop, modes: $modes, statid: $statid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/Leaderboards/{membershipType}/{destinyMembershipId}/{characterId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Destiny2.GetLeaderboardsForCharacter
export def "destiny2-get-leaderboards-for-character" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/Stats/Leaderboards/{membershipType}/{destinyMembershipId}/{characterId}/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}]
    query: [{name: maxtop, var: maxtop}, {name: modes, var: modes}, {name: statid, var: statid}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id, maxtop: $maxtop, modes: $modes, statid: $statid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the available post game carnage report for the activity ID.
#
# GET /Destiny2/Stats/PostGameCarnageReport/{activityId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activityDetails: record<directorActivityHash: int, instanceId: int, isPrivate: bool, membershipType: int, mode: int, modes: list, referenceId: int>, activityWasStartedFromBeginning: bool, entries: list<record>, period: string, startingPhaseIndex: int, teams: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetPostGameCarnageReport
export def "destiny2-get-post-game-carnage-report" [
  activity_id: int
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
    path: "/Destiny2/Stats/PostGameCarnageReport/{activityId}/"
    path_params: [{name: activityId, var: activity_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    activity_id: $activity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report a player that you met in an activity that was engaging in ToS-violating activities. Both you and the offending player must have played in the activityId passed in. Please use this judiciously and only when you have strong suspicions of violation, pretty please.
#
# POST /Destiny2/Stats/PostGameCarnageReport/{activityId}/Report/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Destiny2.ReportOffensivePostGameCarnageReportPlayer
export def "destiny2-report-offensive-post-game-carnage-report-player" [
  activity_id: int
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
    path: "/Destiny2/Stats/PostGameCarnageReport/{activityId}/Report/"
    path_params: [{name: activityId, var: activity_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    activity_id: $activity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get items available from vendors where the vendors have items for sale that are common for everyone. If any portion of the Vendor's available inventory is character or account specific, we will be unable to return their data from this endpoint due to the way that available inventory is computed. As I am often guilty of saying: 'It's a long story...'
#
# GET /Destiny2/Vendors/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: record<data: record, disabled: bool, privacy: int>, sales: record<data: record, disabled: bool, privacy: int>, stringVariables: record<data: record, disabled: bool, privacy: int>, vendorGroups: record<data: record, disabled: bool, privacy: int>, vendors: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>
# operationId: Destiny2.GetPublicVendors
export def "destiny2-get-public-vendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/Vendors/"
    query: [{name: components, var: components, style: csv}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    components: $components
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets historical stats for indicated character.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Destiny2.GetHistoricalStats
export def "destiny2-get-historical-stats" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dayend: string # Last day to return when daily stats are requested. Use the format YYYY-MM-DD. Currently, we cannot allow more than 31 days of daily data to be requested in a single request. (format: date-time)
  --daystart: string # First day to return when daily stats are requested. Use the format YYYY-MM-DD. Currently, we cannot allow more than 31 days of daily data to be requested in a single request. (format: date-time)
  --groups: list<int> # Group of stats to include, otherwise only general stats are returned. Comma separated list is allowed. Values: General, Weapons, Medals
  --modes: list<int> # Game modes to return. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --period-type: int # Indicates a specific period type to return. Optional. May be: Daily, AllTime, or Activity (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}]
    query: [{name: dayend, var: dayend}, {name: daystart, var: daystart}, {name: groups, var: groups, style: csv}, {name: modes, var: modes, style: csv}, {name: periodType, var: period_type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id, dayend: $dayend, daystart: $daystart, groups: $groups, modes: $modes, period_type: $period_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets activity history stats for indicated character.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/Activities/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetActivityHistory
export def "destiny2-get-activity-history" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of rows to return (format: int32)
  --mode: int # A filter for the activity mode to be returned. None returns all activities. See the documentation for DestinyActivityModeType for valid values, and pass in string representation. (format: int32)
  --page: int # Page number to return, starting with 0. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/Activities/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}]
    query: [{name: count, var: count}, {name: mode, var: mode}, {name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id, count: $count, mode: $mode, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all activities the character has participated in together with aggregate statistics for those activities.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/AggregateActivityStats/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetDestinyAggregateActivityStats
export def "destiny2-get-destiny-aggregate-activity-stats" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
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
    path: "/Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/AggregateActivityStats/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details about unique weapon usage, including all exotic weapons.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/UniqueWeapons/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<weapons: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetUniqueWeaponHistory
export def "destiny2-get-unique-weapon-history" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
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
    path: "/Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/UniqueWeapons/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets aggregate historical stats organized around each character for a given account.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<characters: list<record>, mergedAllCharacters: record<merged: record, results: record>, mergedDeletedCharacters: record<merged: record, results: record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetHistoricalStatsForAccount
export def "destiny2-get-historical-stats-for-account" [
  membership_type: int
  destiny_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<int> # Groups of stats to include, otherwise only general stats are returned. Comma separated list is allowed. Values: General, Weapons, Medals.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}]
    query: [{name: groups, var: groups, style: csv}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, groups: $groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint has not yet been implemented. It is being returned for a preview of future functionality, and for public comment/suggestion/preparation.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/Leaderboards/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Destiny2.GetLeaderboards
export def "destiny2-get-leaderboards" [
  membership_type: int
  destiny_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/Leaderboards/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}]
    query: [{name: maxtop, var: maxtop}, {name: modes, var: modes}, {name: statid, var: statid}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, maxtop: $maxtop, modes: $modes, statid: $statid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Destiny Profile information for the supplied membership.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<characterActivities: record<data: record, disabled: bool, privacy: int>, characterCollectibles: record<data: record, disabled: bool, privacy: int>, characterCraftables: record<data: record, disabled: bool, privacy: int>, characterCurrencyLookups: record<data: record, disabled: bool, privacy: int>, characterEquipment: record<data: record, disabled: bool, privacy: int>, characterInventories: record<data: record, disabled: bool, privacy: int>, characterKiosks: record<data: record, disabled: bool, privacy: int>, characterLoadouts: record<data: record, disabled: bool, privacy: int>, characterPlugSets: record<data: record, disabled: bool, privacy: int>, characterPresentationNodes: record<data: record, disabled: bool, privacy: int>, characterProgressions: record<data: record, disabled: bool, privacy: int>, characterRecords: record<data: record, disabled: bool, privacy: int>, characterRenderData: record<data: record, disabled: bool, privacy: int>, characterStringVariables: record<data: record, disabled: bool, privacy: int>, characterUninstancedItemComponents: record, characters: record<data: record, disabled: bool, privacy: int>, itemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, metrics: record<data: record, disabled: bool, privacy: int>, platformSilver: record<data: record, disabled: bool, privacy: int>, profile: record<data: record, disabled: bool, privacy: int>, profileCollectibles: record<data: record, disabled: bool, privacy: int>, profileCommendations: record<data: record, disabled: bool, privacy: int>, profileCurrencies: record<data: record, disabled: bool, privacy: int>, profileInventory: record<data: record, disabled: bool, privacy: int>, profileKiosks: record<data: record, disabled: bool, privacy: int>, profilePlugSets: record<data: record, disabled: bool, privacy: int>, profilePresentationNodes: record<data: record, disabled: bool, privacy: int>, profileProgression: record<data: record, disabled: bool, privacy: int>, profileRecords: record<data: record, disabled: bool, privacy: int>, profileStringVariables: record<data: record, disabled: bool, privacy: int>, profileTransitoryData: record<data: record, disabled: bool, privacy: int>, responseMintedTimestamp: string, secondaryComponentsMintedTimestamp: string, vendorReceipts: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>
# operationId: Destiny2.GetProfile
export def "destiny2-get-profile" [
  membership_type: int
  destiny_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Profile/{destinyMembershipId}/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}]
    query: [{name: components, var: components, style: csv}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, components: $components
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns character information for the supplied character.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<activities: record<data: record, disabled: bool, privacy: int>, character: record<data: record, disabled: bool, privacy: int>, collectibles: record<data: record, disabled: bool, privacy: int>, currencyLookups: record<data: record, disabled: bool, privacy: int>, equipment: record<data: record, disabled: bool, privacy: int>, inventory: record<data: record, disabled: bool, privacy: int>, itemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, kiosks: record<data: record, disabled: bool, privacy: int>, loadouts: record<data: record, disabled: bool, privacy: int>, plugSets: record<data: record, disabled: bool, privacy: int>, presentationNodes: record<data: record, disabled: bool, privacy: int>, progressions: record<data: record, disabled: bool, privacy: int>, records: record<data: record, disabled: bool, privacy: int>, renderData: record<data: record, disabled: bool, privacy: int>, uninstancedItemComponents: record<objectives: record, perks: record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetCharacter
export def "destiny2-get-character" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}]
    query: [{name: components, var: components, style: csv}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id, components: $components
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a Presentation Node that has Collectibles as direct descendants, this will return item details about those descendants in the context of the requesting character.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Collectibles/{collectiblePresentationNodeHash}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<collectibleItemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, collectibles: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>
# operationId: Destiny2.GetCollectibleNodeDetails
export def "destiny2-get-collectible-node-details" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  collectible_presentation_node_hash: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Collectibles/{collectiblePresentationNodeHash}/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}, {name: collectiblePresentationNodeHash, var: collectible_presentation_node_hash}]
    query: [{name: components, var: components, style: csv}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id, collectible_presentation_node_hash: $collectible_presentation_node_hash, components: $components
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get currently available vendors from the list of vendors that can possibly have rotating inventory. Note that this does not include things like preview vendors and vendors-as-kiosks, neither of whom have rotating/dynamic inventories. Use their definitions as-is for those.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: record<data: record, disabled: bool, privacy: int>, currencyLookups: record<data: record, disabled: bool, privacy: int>, itemComponents: record, sales: record<data: record, disabled: bool, privacy: int>, stringVariables: record<data: record, disabled: bool, privacy: int>, vendorGroups: record<data: record, disabled: bool, privacy: int>, vendors: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>
# operationId: Destiny2.GetVendors
export def "destiny2-get-vendors" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
  --filter: int # The filter of what vendors and items to return, if any. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}]
    query: [{name: components, var: components, style: csv}, {name: filter, var: filter}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id, components: $components, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of a specific Vendor.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/{vendorHash}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: record<data: record, disabled: bool, privacy: int>, currencyLookups: record<data: record, disabled: bool, privacy: int>, itemComponents: record<instances: record, objectives: record, perks: record, plugObjectives: record, plugStates: record, renderData: record, reusablePlugs: record, sockets: record, stats: record, talentGrids: record>, sales: record<data: record, disabled: bool, privacy: int>, stringVariables: record<data: record, disabled: bool, privacy: int>, vendor: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>
# operationId: Destiny2.GetVendor
export def "destiny2-get-vendor" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  vendor_hash: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/{vendorHash}/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: characterId, var: character_id}, {name: vendorHash, var: vendor_hash}]
    query: [{name: components, var: components, style: csv}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, character_id: $character_id, vendor_hash: $vendor_hash, components: $components
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the details of an instanced Destiny Item. An instanced Destiny item is one with an ItemInstanceId. Non-instanced items, such as materials, have no useful instance-specific details and thus are not queryable here.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Item/{itemInstanceId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<characterId: int, instance: record<data: record, disabled: bool, privacy: int>, item: record<data: record, disabled: bool, privacy: int>, objectives: record<data: record, disabled: bool, privacy: int>, perks: record<data: record, disabled: bool, privacy: int>, plugObjectives: record<data: record, disabled: bool, privacy: int>, renderData: record<data: record, disabled: bool, privacy: int>, reusablePlugs: record<data: record, disabled: bool, privacy: int>, sockets: record<data: record, disabled: bool, privacy: int>, stats: record<data: record, disabled: bool, privacy: int>, talentGrid: record<data: record, disabled: bool, privacy: int>>, ThrottleSeconds: int>
# operationId: Destiny2.GetItem
export def "destiny2-get-item" [
  membership_type: int
  destiny_membership_id: int
  item_instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Profile/{destinyMembershipId}/Item/{itemInstanceId}/"
    path_params: [{name: membershipType, var: membership_type}, {name: destinyMembershipId, var: destiny_membership_id}, {name: itemInstanceId, var: item_instance_id}]
    query: [{name: components, var: components, style: csv}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, destiny_membership_id: $destiny_membership_id, item_instance_id: $item_instance_id, components: $components
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a summary information about all profiles linked to the requesting membership type/membership ID that have valid Destiny information. The passed-in Membership Type/Membership ID may be a Bungie.Net membership or a Destiny membership. It only returns the minimal amount of data to begin making more substantive requests, but will hopefully serve as a useful alternative to UserServices for people who just care about Destiny data. Note that it will only return linked accounts whose linkages you are allowed to view.
#
# GET /Destiny2/{membershipType}/Profile/{membershipId}/LinkedProfiles/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<bnetMembership: record<applicableMembershipTypes: list, bungieGlobalDisplayName: string, bungieGlobalDisplayNameCode: int, crossSaveOverride: int, displayName: string, iconPath: string, isPublic: bool, membershipId: int, membershipType: int, supplementalDisplayName: string>, profiles: list<record>, profilesWithErrors: list<record>>, ThrottleSeconds: int>
# operationId: Destiny2.GetLinkedProfiles
export def "destiny2-get-linked-profiles" [
  membership_type: int
  membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --get-all-memberships: oneof<nothing, bool> # (optional) if set to 'true', all memberships regardless of whether they're obscured by overrides will be returned. Normal privacy restrictions on account linking will still apply no matter what.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Destiny2/{membershipType}/Profile/{membershipId}/LinkedProfiles/"
    path_params: [{name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}]
    query: [{name: getAllMemberships, var: get_all_memberships}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, membership_id: $membership_id, get_all_memberships: $get_all_memberships
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a count of all active non-public fireteams for the specified clan. Maximum value returned is 25.
#
# GET /Fireteam/Clan/{groupId}/ActiveCount/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Fireteam.GetActivePrivateClanFireteamCount
export def "fireteam-get-active-private-clan-fireteam-count" [
  group_id: int
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
    path: "/Fireteam/Clan/{groupId}/ActiveCount/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a listing of all of this clan's fireteams that are have available slots. Caller is not checked for join criteria so caching is maximized.
#
# GET /Fireteam/Clan/{groupId}/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{publicOnly}/{page}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Fireteam.GetAvailableClanFireteams
export def "fireteam-get-available-clan-fireteams" [
  group_id: int
  platform: int
  activity_type: int
  date_range: int
  slot_filter: int
  public_only: int
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-immediate: oneof<nothing, bool> # If you wish the result to exclude immediate fireteams, set this to true. Immediate-only can be forced using the dateRange enum.
  --lang-filter: string # An optional language filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Fireteam/Clan/{groupId}/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{publicOnly}/{page}/"
    path_params: [{name: groupId, var: group_id}, {name: platform, var: platform}, {name: activityType, var: activity_type}, {name: dateRange, var: date_range}, {name: slotFilter, var: slot_filter}, {name: publicOnly, var: public_only}, {name: page, var: page}]
    query: [{name: excludeImmediate, var: exclude_immediate}, {name: langFilter, var: lang_filter}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, platform: $platform, activity_type: $activity_type, date_range: $date_range, slot_filter: $slot_filter, public_only: $public_only, page: $page, exclude_immediate: $exclude_immediate, lang_filter: $lang_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a listing of all fireteams that caller is an applicant, a member, or an alternate of.
#
# GET /Fireteam/Clan/{groupId}/My/{platform}/{includeClosed}/{page}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Fireteam.GetMyClanFireteams
export def "fireteam-get-my-clan-fireteams" [
  group_id: int
  platform: int
  include_closed: bool
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-filter: oneof<nothing, bool> # If true, filter by clan. Otherwise, ignore the clan and show all of the user's fireteams.
  --lang-filter: string # An optional language filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Fireteam/Clan/{groupId}/My/{platform}/{includeClosed}/{page}/"
    path_params: [{name: groupId, var: group_id}, {name: platform, var: platform}, {name: includeClosed, var: include_closed}, {name: page, var: page}]
    query: [{name: groupFilter, var: group_filter}, {name: langFilter, var: lang_filter}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, platform: $platform, include_closed: $include_closed, page: $page, group_filter: $group_filter, lang_filter: $lang_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specific fireteam.
#
# GET /Fireteam/Clan/{groupId}/Summary/{fireteamId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<Alternates: list<record>, Members: list<record>, Summary: record<activityType: int, alternateSlotCount: int, availableAlternateSlotCount: int, availablePlayerSlotCount: int, dateCreated: string, dateModified: string, datePlayerModified: string, fireteamId: int, groupId: int, isImmediate: bool, isPublic: bool, isValid: bool, locale: string, ownerCurrentGuardianRankSnapshot: int, ownerHighestLifetimeGuardianRankSnapshot: int, ownerMembershipId: int, ownerTotalCommendationScoreSnapshot: int, platform: int, playerSlotCount: int, scheduledTime: string, title: string, titleBeforeModeration: string>>, ThrottleSeconds: int>
# operationId: Fireteam.GetClanFireteam
export def "fireteam-get-clan-fireteam" [
  group_id: int
  fireteam_id: int
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
    path: "/Fireteam/Clan/{groupId}/Summary/{fireteamId}/"
    path_params: [{name: groupId, var: group_id}, {name: fireteamId, var: fireteam_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, fireteam_id: $fireteam_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a listing of all public fireteams starting now with open slots. Caller is not checked for join criteria so caching is maximized.
#
# GET /Fireteam/Search/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{page}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Fireteam.SearchPublicAvailableClanFireteams
export def "fireteam-search-public-available-clan-fireteams" [
  platform: int
  activity_type: int
  date_range: int
  slot_filter: int
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-immediate: oneof<nothing, bool> # If you wish the result to exclude immediate fireteams, set this to true. Immediate-only can be forced using the dateRange enum.
  --lang-filter: string # An optional language filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Fireteam/Search/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{page}/"
    path_params: [{name: platform, var: platform}, {name: activityType, var: activity_type}, {name: dateRange, var: date_range}, {name: slotFilter, var: slot_filter}, {name: page, var: page}]
    query: [{name: excludeImmediate, var: exclude_immediate}, {name: langFilter, var: lang_filter}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, activity_type: $activity_type, date_range: $date_range, slot_filter: $slot_filter, page: $page, exclude_immediate: $exclude_immediate, lang_filter: $lang_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a listing of all topics marked as part of the core group.
#
# GET /Forum/GetCoreTopicsPaged/{page}/{sort}/{quickDate}/{categoryFilter}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Forum.GetCoreTopicsPaged
export def "forum-get-core-topics-paged" [
  page: int
  sort: int
  quick_date: int
  category_filter: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locales: string # Comma seperated list of locales posts must match to return in the result list. Default 'en'
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Forum/GetCoreTopicsPaged/{page}/{sort}/{quickDate}/{categoryFilter}/"
    path_params: [{name: page, var: page}, {name: sort, var: sort}, {name: quickDate, var: quick_date}, {name: categoryFilter, var: category_filter}]
    query: [{name: locales, var: locales}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    page: $page, sort: $sort, quick_date: $quick_date, category_filter: $category_filter, locales: $locales
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets tag suggestions based on partial text entry, matching them with other tags previously used in the forums.
#
# GET /Forum/GetForumTagSuggestions/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<ignoreStatus: record, tagText: string>, ThrottleSeconds: int>
# operationId: Forum.GetForumTagSuggestions
export def "forum-get-forum-tag-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partialtag: string # The partial tag input to generate suggestions from.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Forum/GetForumTagSuggestions/"
    query: [{name: partialtag, var: partialtag}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    partialtag: $partialtag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the post specified and its immediate parent.
#
# GET /Forum/GetPostAndParent/{childPostId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Forum.GetPostAndParent
export def "forum-get-post-and-parent" [
  child_post_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Forum/GetPostAndParent/{childPostId}/"
    path_params: [{name: childPostId, var: child_post_id}]
    query: [{name: showbanned, var: showbanned}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    child_post_id: $child_post_id, showbanned: $showbanned
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the post specified and its immediate parent of posts that are awaiting approval.
#
# GET /Forum/GetPostAndParentAwaitingApproval/{childPostId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Forum.GetPostAndParentAwaitingApproval
export def "forum-get-post-and-parent-awaiting-approval" [
  child_post_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Forum/GetPostAndParentAwaitingApproval/{childPostId}/"
    path_params: [{name: childPostId, var: child_post_id}]
    query: [{name: showbanned, var: showbanned}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    child_post_id: $child_post_id, showbanned: $showbanned
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a thread of posts at the given parent, optionally returning replies to those posts as well as the original parent.
#
# GET /Forum/GetPostsThreadedPaged/{parentPostId}/{page}/{pageSize}/{replySize}/{getParentPost}/{rootThreadMode}/{sortMode}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Forum.GetPostsThreadedPaged
export def "forum-get-posts-threaded-paged" [
  parent_post_id: int
  page: int
  page_size: int
  reply_size: int
  get_parent_post: bool
  root_thread_mode: bool
  sort_mode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Forum/GetPostsThreadedPaged/{parentPostId}/{page}/{pageSize}/{replySize}/{getParentPost}/{rootThreadMode}/{sortMode}/"
    path_params: [{name: parentPostId, var: parent_post_id}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: replySize, var: reply_size}, {name: getParentPost, var: get_parent_post}, {name: rootThreadMode, var: root_thread_mode}, {name: sortMode, var: sort_mode}]
    query: [{name: showbanned, var: showbanned}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    parent_post_id: $parent_post_id, page: $page, page_size: $page_size, reply_size: $reply_size, get_parent_post: $get_parent_post, root_thread_mode: $root_thread_mode, sort_mode: $sort_mode, showbanned: $showbanned
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a thread of posts starting at the topicId of the input childPostId, optionally returning replies to those posts as well as the original parent.
#
# GET /Forum/GetPostsThreadedPagedFromChild/{childPostId}/{page}/{pageSize}/{replySize}/{rootThreadMode}/{sortMode}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Forum.GetPostsThreadedPagedFromChild
export def "forum-get-posts-threaded-paged-from-child" [
  child_post_id: int
  page: int
  page_size: int
  reply_size: int
  root_thread_mode: bool
  sort_mode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Forum/GetPostsThreadedPagedFromChild/{childPostId}/{page}/{pageSize}/{replySize}/{rootThreadMode}/{sortMode}/"
    path_params: [{name: childPostId, var: child_post_id}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: replySize, var: reply_size}, {name: rootThreadMode, var: root_thread_mode}, {name: sortMode, var: sort_mode}]
    query: [{name: showbanned, var: showbanned}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    child_post_id: $child_post_id, page: $page, page_size: $page_size, reply_size: $reply_size, root_thread_mode: $root_thread_mode, sort_mode: $sort_mode, showbanned: $showbanned
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the post Id for the given content item's comments, if it exists.
#
# GET /Forum/GetTopicForContent/{contentId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: Forum.GetTopicForContent
export def "forum-get-topic-for-content" [
  content_id: int
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
    path: "/Forum/GetTopicForContent/{contentId}/"
    path_params: [{name: contentId, var: content_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    content_id: $content_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get topics from any forum.
#
# GET /Forum/GetTopicsPaged/{page}/{pageSize}/{group}/{sort}/{quickDate}/{categoryFilter}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Forum.GetTopicsPaged
export def "forum-get-topics-paged" [
  page: int
  page_size: int
  group: int
  sort: int
  quick_date: int
  category_filter: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locales: string # Comma seperated list of locales posts must match to return in the result list. Default 'en'
  --tagstring: string # The tags to search, if any.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Forum/GetTopicsPaged/{page}/{pageSize}/{group}/{sort}/{quickDate}/{categoryFilter}/"
    path_params: [{name: page, var: page}, {name: pageSize, var: page_size}, {name: group, var: group}, {name: sort, var: sort}, {name: quickDate, var: quick_date}, {name: categoryFilter, var: category_filter}]
    query: [{name: locales, var: locales}, {name: tagstring, var: tagstring}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    page: $page, page_size: $page_size, group: $group, sort: $sort, quick_date: $quick_date, category_filter: $category_filter, locales: $locales, tagstring: $tagstring
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified forum poll.
#
# GET /Forum/Poll/{topicId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<authors: list<record>, availablePages: int, groups: list<record>, hasMore: bool, polls: list<record>, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, recruitmentDetails: list<record>, relatedPosts: list<record>, replacementContinuationToken: string, results: list<record>, searchedTags: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Forum.GetPoll
export def "forum-get-poll" [
  topic_id: int
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
    path: "/Forum/Poll/{topicId}/"
    path_params: [{name: topicId, var: topic_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    topic_id: $topic_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the caller to get a list of to 25 recruitment thread summary information objects.
#
# POST /Forum/Recruit/Summaries/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<Fireteam: list, approved: bool, conversationId: int, intensity: int, kickedPlayerIds: list, microphoneRequired: bool, playerSlotsRemaining: int, playerSlotsTotal: int, tone: int, topicId: int>, ThrottleSeconds: int>
# operationId: Forum.GetRecruitmentThreadSummaries
export def "forum-get-recruitment-thread-summaries" [
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
    path: "/Forum/Recruit/Summaries/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of available localization cultures
#
# GET /GetAvailableLocales/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: .GetAvailableLocales
export def "get-available-locales" [
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
    path: "/GetAvailableLocales/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets any active global alert for display in the forum banners, help pages, etc. Usually used for DOC alerts.
#
# GET /GlobalAlerts/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<AlertHtml: string, AlertKey: string, AlertLevel: int, AlertLink: string, AlertTimestamp: string, AlertType: int, StreamInfo: record>, ThrottleSeconds: int>
# operationId: .GetGlobalAlerts
export def "get-global-alerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --includestreaming: oneof<nothing, bool> # Determines whether Streaming Alerts are included in results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/GlobalAlerts/"
    query: [{name: includestreaming, var: includestreaming}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    includestreaming: $includestreaming
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all available group avatars for the signed-in user.
#
# GET /GroupV2/GetAvailableAvatars/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: GroupV2.GetAvailableAvatars
export def "group-v2-get-available-avatars" [
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
    path: "/GroupV2/GetAvailableAvatars/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all available group themes.
#
# GET /GroupV2/GetAvailableThemes/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<description: string, folder: string, name: string>, ThrottleSeconds: int>
# operationId: GroupV2.GetAvailableThemes
export def "group-v2-get-available-themes" [
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
    path: "/GroupV2/GetAvailableThemes/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the state of the user's clan invite preferences for a particular membership type - true if they wish to be invited to clans, false otherwise.
#
# GET /GroupV2/GetUserClanInviteSetting/{mType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: GroupV2.GetUserClanInviteSetting
export def "group-v2-get-user-clan-invite-setting" [
  m_type: int
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
    path: "/GroupV2/GetUserClanInviteSetting/{mType}/"
    path_params: [{name: mType, var: m_type}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    m_type: $m_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a specific group with the given name and type.
#
# GET /GroupV2/Name/{groupName}/{groupType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allianceStatus: int, alliedIds: list<int>, currentUserMemberMap: record, currentUserMembershipsInactiveForDestiny: bool, currentUserPotentialMemberMap: record, detail: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, founder: record<bungieNetUserInfo: record, destinyUserInfo: record, groupId: int, isOnline: bool, joinDate: string, lastOnlineStatusChange: int, memberType: int>, groupJoinInviteCount: int, parentGroup: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>>, ThrottleSeconds: int>
# operationId: GroupV2.GetGroupByName
export def "group-v2-get-group-by-name" [
  group_name: string
  group_type: int
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
    path: "/GroupV2/Name/{groupName}/{groupType}/"
    path_params: [{name: groupName, var: group_name}, {name: groupType, var: group_type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_name: $group_name, group_type: $group_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a specific group with the given name and type. The POST version.
#
# POST /GroupV2/NameV2/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allianceStatus: int, alliedIds: list<int>, currentUserMemberMap: record, currentUserMembershipsInactiveForDestiny: bool, currentUserPotentialMemberMap: record, detail: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, founder: record<bungieNetUserInfo: record, destinyUserInfo: record, groupId: int, isOnline: bool, joinDate: string, lastOnlineStatusChange: int, memberType: int>, groupJoinInviteCount: int, parentGroup: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>>, ThrottleSeconds: int>
# operationId: GroupV2.GetGroupByNameV2
export def "group-v2-get-group-by-name-v2" [
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
    path: "/GroupV2/NameV2/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets groups recommended for you based on the groups to whom those you follow belong.
#
# POST /GroupV2/Recommended/{groupType}/{createDateRange}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<about: string, avatarPath: string, capabilities: int, clanInfo: record, creationDate: string, groupId: int, groupType: int, locale: string, memberCount: int, membershipOption: int, motto: string, name: string, theme: string>, ThrottleSeconds: int>
# operationId: GroupV2.GetRecommendedGroups
export def "group-v2-get-recommended-groups" [
  group_type: int
  create_date_range: int
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
    path: "/GroupV2/Recommended/{groupType}/{createDateRange}/"
    path_params: [{name: groupType, var: group_type}, {name: createDateRange, var: create_date_range}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_type: $group_type, create_date_range: $create_date_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows a founder to manually recover a group they can see in game but not on bungie.net
#
# GET /GroupV2/Recover/{membershipType}/{membershipId}/{groupType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.RecoverGroupForFounder
export def "group-v2-recover-group-for-founder" [
  membership_type: int
  membership_id: int
  group_type: int
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
    path: "/GroupV2/Recover/{membershipType}/{membershipId}/{groupType}/"
    path_params: [{name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}, {name: groupType, var: group_type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, membership_id: $membership_id, group_type: $group_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for Groups.
#
# POST /GroupV2/Search/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GroupSearch
export def "group-v2-group-search" [
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
    path: "/GroupV2/Search/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about the groups that a given member has applied to or been invited to.
#
# GET /GroupV2/User/Potential/{membershipType}/{membershipId}/{filter}/{groupType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GetPotentialGroupsForMember
export def "group-v2-get-potential-groups-for-member" [
  membership_type: int
  membership_id: int
  filter: int
  group_type: int
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
    path: "/GroupV2/User/Potential/{membershipType}/{membershipId}/{filter}/{groupType}/"
    path_params: [{name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}, {name: filter, var: filter}, {name: groupType, var: group_type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, membership_id: $membership_id, filter: $filter, group_type: $group_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about the groups that a given member has joined.
#
# GET /GroupV2/User/{membershipType}/{membershipId}/{filter}/{groupType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<areAllMembershipsInactive: record, hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GetGroupsForMember
export def "group-v2-get-groups-for-member" [
  membership_type: int
  membership_id: int
  filter: int
  group_type: int
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
    path: "/GroupV2/User/{membershipType}/{membershipId}/{filter}/{groupType}/"
    path_params: [{name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}, {name: filter, var: filter}, {name: groupType, var: group_type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_type: $membership_type, membership_id: $membership_id, filter: $filter, group_type: $group_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a specific group of the given ID.
#
# GET /GroupV2/{groupId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<allianceStatus: int, alliedIds: list<int>, currentUserMemberMap: record, currentUserMembershipsInactiveForDestiny: bool, currentUserPotentialMemberMap: record, detail: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, founder: record<bungieNetUserInfo: record, destinyUserInfo: record, groupId: int, isOnline: bool, joinDate: string, lastOnlineStatusChange: int, memberType: int>, groupJoinInviteCount: int, parentGroup: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>>, ThrottleSeconds: int>
# operationId: GroupV2.GetGroup
export def "group-v2-get-group" [
  group_id: int
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
    path: "/GroupV2/{groupId}/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An administrative method to allow the founder of a group or clan to give up their position to another admin permanently.
#
# POST /GroupV2/{groupId}/Admin/AbdicateFoundership/{membershipType}/{founderIdNew}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: GroupV2.AbdicateFoundership
export def "group-v2-abdicate-foundership" [
  group_id: int
  membership_type: int
  founder_id_new: int
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
    path: "/GroupV2/{groupId}/Admin/AbdicateFoundership/{membershipType}/{founderIdNew}/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: founderIdNew, var: founder_id_new}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id, membership_type: $membership_type, founder_id_new: $founder_id_new
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of members in a given group who are of admin level or higher.
#
# GET /GroupV2/{groupId}/AdminsAndFounder/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GetAdminsAndFounderOfGroup
export def "group-v2-get-admins-and-founder-of-group" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/GroupV2/{groupId}/AdminsAndFounder/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: currentpage, var: currentpage, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id, currentpage: $currentpage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of banned members in a given group. Only accessible to group Admins and above. Not applicable to all groups. Check group features.
#
# GET /GroupV2/{groupId}/Banned/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GetBannedMembersOfGroup
export def "group-v2-get-banned-members-of-group" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 entries. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/GroupV2/{groupId}/Banned/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: currentpage, var: currentpage, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, currentpage: $currentpage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an existing group. You must have suitable permissions in the group to perform this operation. This latest revision will only edit the fields you pass in - pass null for properties you want to leave unaltered.
#
# POST /GroupV2/{groupId}/Edit/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.EditGroup
export def "group-v2-edit-group" [
  group_id: int
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
    path: "/GroupV2/{groupId}/Edit/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an existing group's clan banner. You must have suitable permissions in the group to perform this operation. All fields are required.
#
# POST /GroupV2/{groupId}/EditClanBanner/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.EditClanBanner
export def "group-v2-edit-clan-banner" [
  group_id: int
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
    path: "/GroupV2/{groupId}/EditClanBanner/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit group options only available to a founder. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/EditFounderOptions/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.EditFounderOptions
export def "group-v2-edit-founder-options" [
  group_id: int
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
    path: "/GroupV2/{groupId}/EditFounderOptions/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of members in a given group.
#
# GET /GroupV2/{groupId}/Members/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GetMembersOfGroup
export def "group-v2-get-members-of-group" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (required, format: int32)
  --member-type: int # Filter out other member types. Use None for all members. (format: int32)
  --name-search: string # The name fragment upon which a search should be executed for members with matching display or unique names.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/GroupV2/{groupId}/Members/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: currentpage, var: currentpage, required: true}, {name: memberType, var: member_type}, {name: nameSearch, var: name_search}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id, currentpage: $currentpage, member_type: $member_type, name_search: $name_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve the given membershipId to join the group/clan as long as they have applied.
#
# POST /GroupV2/{groupId}/Members/Approve/{membershipType}/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: GroupV2.ApprovePending
export def "group-v2-approve-pending" [
  group_id: int
  membership_type: int
  membership_id: int
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
    path: "/GroupV2/{groupId}/Members/Approve/{membershipType}/{membershipId}/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, membership_type: $membership_type, membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/ApproveAll/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>
# operationId: GroupV2.ApproveAllPending
export def "group-v2-approve-all-pending" [
  group_id: int
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
    path: "/GroupV2/{groupId}/Members/ApproveAll/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/ApproveList/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>
# operationId: GroupV2.ApprovePendingForList
export def "group-v2-approve-pending-for-list" [
  group_id: int
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
    path: "/GroupV2/{groupId}/Members/ApproveList/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deny all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/DenyAll/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>
# operationId: GroupV2.DenyAllPending
export def "group-v2-deny-all-pending" [
  group_id: int
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
    path: "/GroupV2/{groupId}/Members/DenyAll/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deny all of the pending users for the given group that match the passed-in .
#
# POST /GroupV2/{groupId}/Members/DenyList/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<entityId: int, result: int>, ThrottleSeconds: int>
# operationId: GroupV2.DenyPendingForList
export def "group-v2-deny-pending-for-list" [
  group_id: int
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
    path: "/GroupV2/{groupId}/Members/DenyList/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite a user to join this group.
#
# POST /GroupV2/{groupId}/Members/IndividualInvite/{membershipType}/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<resolution: int>, ThrottleSeconds: int>
# operationId: GroupV2.IndividualGroupInvite
export def "group-v2-individual-group-invite" [
  group_id: int
  membership_type: int
  membership_id: int
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
    path: "/GroupV2/{groupId}/Members/IndividualInvite/{membershipType}/{membershipId}/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, membership_type: $membership_type, membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a pending invitation to join a group.
#
# POST /GroupV2/{groupId}/Members/IndividualInviteCancel/{membershipType}/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<resolution: int>, ThrottleSeconds: int>
# operationId: GroupV2.IndividualGroupInviteCancel
export def "group-v2-individual-group-invite-cancel" [
  group_id: int
  membership_type: int
  membership_id: int
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
    path: "/GroupV2/{groupId}/Members/IndividualInviteCancel/{membershipType}/{membershipId}/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, membership_type: $membership_type, membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of users who have been invited into the group.
#
# GET /GroupV2/{groupId}/Members/InvitedIndividuals/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GetInvitedIndividuals
export def "group-v2-get-invited-individuals" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/GroupV2/{groupId}/Members/InvitedIndividuals/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: currentpage, var: currentpage, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, currentpage: $currentpage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of users who are awaiting a decision on their application to join a given group. Modified to include application info.
#
# GET /GroupV2/{groupId}/Members/Pending/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: GroupV2.GetPendingMemberships
export def "group-v2-get-pending-memberships" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/GroupV2/{groupId}/Members/Pending/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: currentpage, var: currentpage, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, currentpage: $currentpage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bans the requested member from the requested group for the specified period of time.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Ban/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.BanMember
export def "group-v2-ban-member" [
  group_id: int
  membership_type: int
  membership_id: int
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
    path: "/GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Ban/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, membership_type: $membership_type, membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kick a member from the given group, forcing them to reapply if they wish to re-join the group. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Kick/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<group: record<about: string, allowChat: bool, avatarImageIndex: int, avatarPath: string, banExpireDate: string, bannerPath: string, chatSecurity: int, clanInfo: record, conversationId: int, creationDate: string, defaultPublicity: int, enableInvitationMessagingForAdmins: bool, features: record, groupId: int, groupType: int, homepage: int, isDefaultPostPublic: bool, isPublic: bool, isPublicTopicAdminOnly: bool, locale: string, memberCount: int, membershipIdCreated: int, membershipOption: int, modificationDate: string, motto: string, name: string, tags: list, theme: string>, groupDeleted: bool>, ThrottleSeconds: int>
# operationId: GroupV2.KickMember
export def "group-v2-kick-member" [
  group_id: int
  membership_type: int
  membership_id: int
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
    path: "/GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Kick/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, membership_type: $membership_type, membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit the membership type of a given member. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/SetMembershipType/{memberType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.EditGroupMembership
export def "group-v2-edit-group-membership" [
  group_id: int
  membership_type: int
  membership_id: int
  member_type: int
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
    path: "/GroupV2/{groupId}/Members/{membershipType}/{membershipId}/SetMembershipType/{memberType}/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}, {name: memberType, var: member_type}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, membership_type: $membership_type, membership_id: $membership_id, member_type: $member_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unbans the requested member, allowing them to re-apply for membership.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Unban/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.UnbanMember
export def "group-v2-unban-member" [
  group_id: int
  membership_type: int
  membership_id: int
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
    path: "/GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Unban/"
    path_params: [{name: groupId, var: group_id}, {name: membershipType, var: membership_type}, {name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, membership_type: $membership_type, membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of available optional conversation channels and their settings.
#
# GET /GroupV2/{groupId}/OptionalConversations/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<chatEnabled: bool, chatName: string, chatSecurity: int, conversationId: int, groupId: int>, ThrottleSeconds: int>
# operationId: GroupV2.GetGroupOptionalConversations
export def "group-v2-get-group-optional-conversations" [
  group_id: int
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
    path: "/GroupV2/{groupId}/OptionalConversations/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new optional conversation/chat channel. Requires admin permissions to the group.
#
# POST /GroupV2/{groupId}/OptionalConversations/Add/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.AddOptionalConversation
export def "group-v2-add-optional-conversation" [
  group_id: int
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
    path: "/GroupV2/{groupId}/OptionalConversations/Add/"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit the settings of an optional conversation/chat channel. Requires admin permissions to the group.
#
# POST /GroupV2/{groupId}/OptionalConversations/Edit/{conversationId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: int, ThrottleSeconds: int>
# operationId: GroupV2.EditOptionalConversation
export def "group-v2-edit-optional-conversation" [
  group_id: int
  conversation_id: int
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
    path: "/GroupV2/{groupId}/OptionalConversations/Edit/{conversationId}/"
    path_params: [{name: groupId, var: group_id}, {name: conversationId, var: conversation_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, conversation_id: $conversation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the common settings used by the Bungie.Net environment.
#
# GET /Settings/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<clanBannerDecalColors: list<record>, clanBannerDecals: list<record>, clanBannerGonfalonColors: list<record>, clanBannerGonfalonDetailColors: list<record>, clanBannerGonfalonDetails: list<record>, clanBannerGonfalons: list<record>, clanBannerStandards: list<record>, defaultGroupTheme: record<childSettings: list, displayName: string, identifier: string, imagePath: string, isDefault: bool, summary: string>, destiny2CoreSettings: record<activeSealsRootNodeHash: int, activeTriumphsRootNodeHash: int, ammoTypeHeavyIcon: string, ammoTypePrimaryIcon: string, ammoTypeSpecialIcon: string, badgesRootNode: int, collectionRootNode: int, craftingRootNodeHash: int, currentRankProgressionHashes: list, currentSeasonHash: int, currentSeasonalArtifactHash: int, exoticCatalystsRootNodeHash: int, futureSeasonHashes: list, guardianRankConstantsHash: int, guardianRanksRootNodeHash: int, insertPlugFreeBlockedSocketTypeHashes: list, insertPlugFreeProtectedPlugItemHashes: list, legacySealsRootNodeHash: int, legacyTriumphsRootNodeHash: int, loadoutConstantsHash: int, loreRootNodeHash: int, medalsRootNode: int, medalsRootNodeHash: int, metricsRootNode: int, pastSeasonHashes: list, recordsRootNode: int, seasonalChallengesPresentationNodeHash: int, undiscoveredCollectibleImage: string>, destinyMembershipTypes: list<record>, emailSettings: record<optInDefinitions: record, subscriptionDefinitions: record, views: record>, environment: string, fireteamActivities: list<record>, forumCategories: list<record>, groupAvatars: list<record>, ignoreReasons: list<record>, recruitmentActivities: list<record>, recruitmentMiscTags: list<record>, recruitmentPlatformTags: list<record>, systemContentLocales: list<record>, systems: record, userContentLocales: list<record>>, ThrottleSeconds: int>
# operationId: .GetCommonSettings
export def "get-common-settings" [
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
    path: "/Settings/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns your Bungie Friend list
#
# GET /Social/Friends/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<friends: list<record>>, ThrottleSeconds: int>
# operationId: Social.GetFriendList
export def "social-get-friend-list" [
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
    path: "/Social/Friends/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a friend relationship with the target user. Any of the target user's linked membership ids are valid inputs.
#
# POST /Social/Friends/Add/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Social.IssueFriendRequest
export def "social-issue-friend-request" [
  membership_id: string
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
    path: "/Social/Friends/Add/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a friend relationship with the target user. The user must be on your friend list, though no error will occur if they are not.
#
# POST /Social/Friends/Remove/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Social.RemoveFriend
export def "social-remove-friend" [
  membership_id: string
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
    path: "/Social/Friends/Remove/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns your friend request queue.
#
# GET /Social/Friends/Requests/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<incomingRequests: list<record>, outgoingRequests: list<record>>, ThrottleSeconds: int>
# operationId: Social.GetFriendRequestList
export def "social-get-friend-request-list" [
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
    path: "/Social/Friends/Requests/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts a friend relationship with the target user. The user must be on your incoming friend request list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Accept/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Social.AcceptFriendRequest
export def "social-accept-friend-request" [
  membership_id: string
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
    path: "/Social/Friends/Requests/Accept/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Declines a friend relationship with the target user. The user must be on your incoming friend request list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Decline/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Social.DeclineFriendRequest
export def "social-decline-friend-request" [
  membership_id: string
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
    path: "/Social/Friends/Requests/Decline/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a friend relationship with the target user. The user must be on your outgoing request friend list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Remove/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Social.RemoveFriendRequest
export def "social-remove-friend-request" [
  membership_id: string
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
    path: "/Social/Friends/Requests/Remove/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the platform friend of the requested type, with additional information if they have Bungie accounts. Must have a recent login session with said platform.
#
# GET /Social/PlatformFriends/{friendPlatform}/{page}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<currentPage: int, hasMore: bool, itemsPerPage: int, platformFriends: list<record>>, ThrottleSeconds: int>
# operationId: Social.GetPlatformFriendList
export def "social-get-platform-friend-list" [
  friend_platform: int
  page: string
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
    path: "/Social/PlatformFriends/{friendPlatform}/{page}/"
    path_params: [{name: friendPlatform, var: friend_platform}, {name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    friend_platform: $friend_platform, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply a partner offer to the targeted user. This endpoint does not claim a new offer, but any already claimed offers will be applied to the game if not already.
#
# POST /Tokens/Partner/ApplyMissingOffers/{partnerApplicationId}/{targetBnetMembershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Tokens.ApplyMissingPartnerOffersWithoutClaim
export def "tokens-apply-missing-partner-offers-without-claim" [
  partner_application_id: int
  target_bnet_membership_id: int
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
    path: "/Tokens/Partner/ApplyMissingOffers/{partnerApplicationId}/{targetBnetMembershipId}/"
    path_params: [{name: partnerApplicationId, var: partner_application_id}, {name: targetBnetMembershipId, var: target_bnet_membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    partner_application_id: $partner_application_id, target_bnet_membership_id: $target_bnet_membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claim a partner offer as the authenticated user.
#
# POST /Tokens/Partner/ClaimOffer/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Tokens.ClaimPartnerOffer
export def "tokens-claim-partner-offer" [
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
    path: "/Tokens/Partner/ClaimOffer/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Twitch Drops self-repair function - scans twitch for drops not marked as fulfilled and resyncs them.
#
# POST /Tokens/Partner/ForceDropsRepair/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: bool, ThrottleSeconds: int>
# operationId: Tokens.ForceDropsRepair
export def "tokens-force-drops-repair" [
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
    path: "/Tokens/Partner/ForceDropsRepair/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the partner sku and offer history of the targeted user. Elevated permissions are required to see users that are not yourself.
#
# GET /Tokens/Partner/History/{partnerApplicationId}/{targetBnetMembershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<AllOffersApplied: bool, ClaimDate: string, LocalizedDescription: string, LocalizedName: string, SkuIdentifier: string, SkuOffers: list, TransactionId: string>, ThrottleSeconds: int>
# operationId: Tokens.GetPartnerOfferSkuHistory
export def "tokens-get-partner-offer-sku-history" [
  partner_application_id: int
  target_bnet_membership_id: int
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
    path: "/Tokens/Partner/History/{partnerApplicationId}/{targetBnetMembershipId}/"
    path_params: [{name: partnerApplicationId, var: partner_application_id}, {name: targetBnetMembershipId, var: target_bnet_membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    partner_application_id: $partner_application_id, target_bnet_membership_id: $target_bnet_membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the partner rewards history of the targeted user, both partner offers and Twitch drops.
#
# GET /Tokens/Partner/History/{targetBnetMembershipId}/Application/{partnerApplicationId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<PartnerOffers: list<record>, TwitchDrops: list<record>>, ThrottleSeconds: int>
# operationId: Tokens.GetPartnerRewardHistory
export def "tokens-get-partner-reward-history" [
  target_bnet_membership_id: int
  partner_application_id: int
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
    path: "/Tokens/Partner/History/{targetBnetMembershipId}/Application/{partnerApplicationId}/"
    path_params: [{name: targetBnetMembershipId, var: target_bnet_membership_id}, {name: partnerApplicationId, var: partner_application_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    target_bnet_membership_id: $target_bnet_membership_id, partner_application_id: $partner_application_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the current bungie rewards
#
# GET /Tokens/Rewards/BungieRewards/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Tokens.GetBungieRewardsList
export def "tokens-get-bungie-rewards-list" [
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
    path: "/Tokens/Rewards/BungieRewards/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the bungie rewards for the targeted user when a platform membership Id and Type are used.
#
# GET /Tokens/Rewards/GetRewardsForPlatformUser/{membershipId}/{membershipType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Tokens.GetBungieRewardsForPlatformUser
export def "tokens-get-bungie-rewards-for-platform-user" [
  membership_id: int
  membership_type: int
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
    path: "/Tokens/Rewards/GetRewardsForPlatformUser/{membershipId}/{membershipType}/"
    path_params: [{name: membershipId, var: membership_id}, {name: membershipType, var: membership_type}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    membership_id: $membership_id, membership_type: $membership_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the bungie rewards for the targeted user.
#
# GET /Tokens/Rewards/GetRewardsForUser/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: Tokens.GetBungieRewardsForUser
export def "tokens-get-bungie-rewards-for-user" [
  membership_id: int
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
    path: "/Tokens/Rewards/GetRewardsForUser/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns trending items for Bungie.net, collapsed into the first page of items per category. For pagination within a category, call GetTrendingCategory.
#
# GET /Trending/Categories/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<categories: list<record>>, ThrottleSeconds: int>
# operationId: Trending.GetTrendingCategories
export def "trending-get-trending-categories" [
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
    path: "/Trending/Categories/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns paginated lists of trending items for a category.
#
# GET /Trending/Categories/{categoryId}/{pageNumber}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, query: record<currentPage: int, itemsPerPage: int, requestContinuationToken: string>, replacementContinuationToken: string, results: list<record>, totalResults: int, useTotalResults: bool>, ThrottleSeconds: int>
# operationId: Trending.GetTrendingCategory
export def "trending-get-trending-category" [
  category_id: string
  page_number: int
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
    path: "/Trending/Categories/{categoryId}/{pageNumber}/"
    path_params: [{name: categoryId, var: category_id}, {name: pageNumber, var: page_number}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    category_id: $category_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the detailed results for a specific trending entry. Note that trending entries are uniquely identified by a combination of *both* the TrendingEntryType *and* the identifier: the identifier alone is not guaranteed to be globally unique.
#
# GET /Trending/Details/{trendingEntryType}/{identifier}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<creation: record<author: string, authorMembershipId: int, body: string, media: string, postId: int, title: string, upvotes: int>, destinyActivity: record<activityHash: int, status: record>, destinyItem: record<itemHash: int>, destinyRitual: record<dateEnd: string, dateStart: string, eventContent: record, icon: string, image: string, milestoneDetails: record, subtitle: string, title: string>, entityType: int, identifier: string, news: record<article: record>, support: record<article: record>>, ThrottleSeconds: int>
# operationId: Trending.GetTrendingEntryDetail
export def "trending-get-trending-entry-detail" [
  trending_entry_type: int
  identifier: string
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
    path: "/Trending/Details/{trendingEntryType}/{identifier}/"
    path_params: [{name: trendingEntryType, var: trending_entry_type}, {name: identifier, var: identifier}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    trending_entry_type: $trending_entry_type, identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all available user themes.
#
# GET /User/GetAvailableThemes/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<userThemeDescription: string, userThemeId: int, userThemeName: string>, ThrottleSeconds: int>
# operationId: User.GetAvailableThemes
export def "user-get-available-themes" [
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
    path: "/User/GetAvailableThemes/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Loads a bungienet user by membership id.
#
# GET /User/GetBungieNetUserById/{id}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record<globalIgnoreEndDate: string, ignoreStatus: record, isFollowing: bool>, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, ThrottleSeconds: int>
# operationId: User.GetBungieNetUserById
export def "user-get-bungie-net-user-by-id" [
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
    path: "/User/GetBungieNetUserById/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of credential types attached to the requested account
#
# GET /User/GetCredentialTypesForTargetAccount/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: table<credentialAsString: string, credentialDisplayName: string, credentialType: int, isPublic: bool>, ThrottleSeconds: int>
# operationId: User.GetCredentialTypesForTargetAccount
export def "user-get-credential-types-for-target-account" [
  membership_id: int
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
    path: "/User/GetCredentialTypesForTargetAccount/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets any hard linked membership given a credential. Only works for credentials that are public (just SteamID64 right now). Cross Save aware.
#
# GET /User/GetMembershipFromHardLinkedCredential/{crType}/{credential}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<CrossSaveOverriddenMembershipId: int, CrossSaveOverriddenType: int, membershipId: int, membershipType: int>, ThrottleSeconds: int>
# operationId: User.GetMembershipFromHardLinkedCredential
export def "user-get-membership-from-hard-linked-credential" [
  cr_type: int
  credential: string
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
    path: "/User/GetMembershipFromHardLinkedCredential/{crType}/{credential}/"
    path_params: [{name: crType, var: cr_type}, {name: credential, var: credential}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    cr_type: $cr_type, credential: $credential
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of accounts associated with the supplied membership ID and membership type. This will include all linked accounts (even when hidden) if supplied credentials permit it.
#
# GET /User/GetMembershipsById/{membershipId}/{membershipType}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<bungieNetUser: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, destinyMemberships: list<record>, primaryMembershipId: int>, ThrottleSeconds: int>
# operationId: User.GetMembershipDataById
export def "user-get-membership-data-by-id" [
  membership_id: int
  membership_type: int
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
    path: "/User/GetMembershipsById/{membershipId}/{membershipType}/"
    path_params: [{name: membershipId, var: membership_id}, {name: membershipType, var: membership_type}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_id: $membership_id, membership_type: $membership_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of accounts associated with signed in user. This is useful for OAuth implementations that do not give you access to the token response.
#
# GET /User/GetMembershipsForCurrentUser/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<bungieNetUser: record<about: string, blizzardDisplayName: string, cachedBungieGlobalDisplayName: string, cachedBungieGlobalDisplayNameCode: int, context: record, displayName: string, egsDisplayName: string, fbDisplayName: string, firstAccess: string, isDeleted: bool, lastBanReportId: int, lastUpdate: string, legacyPortalUID: int, locale: string, localeInheritDefault: bool, membershipId: int, normalizedName: string, profileBanExpire: string, profilePicture: int, profilePicturePath: string, profilePictureWidePath: string, profileTheme: int, profileThemeName: string, psnDisplayName: string, showActivity: bool, showGroupMessaging: bool, stadiaDisplayName: string, statusDate: string, statusText: string, steamDisplayName: string, successMessageFlags: int, twitchDisplayName: string, uniqueName: string, userTitle: int, userTitleDisplay: string, xboxDisplayName: string>, destinyMemberships: list<record>, primaryMembershipId: int>, ThrottleSeconds: int>
# operationId: User.GetMembershipDataForCurrentUser
export def "user-get-membership-data-for-current-user" [
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
    path: "/User/GetMembershipsForCurrentUser/"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all display names linked to this membership id but sanitized (profanity filtered). Obeys all visibility rules of calling user and is heavily cached.
#
# GET /User/GetSanitizedPlatformDisplayNames/{membershipId}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: User.GetSanitizedPlatformDisplayNames
export def "user-get-sanitized-platform-display-names" [
  membership_id: int
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
    path: "/User/GetSanitizedPlatformDisplayNames/{membershipId}/"
    path_params: [{name: membershipId, var: membership_id}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    membership_id: $membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given the prefix of a global display name, returns all users who share that name.
#
# POST /User/Search/GlobalName/{page}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, page: int, searchResults: list<record>>, ThrottleSeconds: int>
# operationId: User.SearchByGlobalNamePost
export def "user-search-by-global-name-post" [
  page: int
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
    path: "/User/Search/GlobalName/{page}/"
    path_params: [{name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [OBSOLETE] Do not use this to search users, use SearchByGlobalNamePost instead.
#
# GET /User/Search/Prefix/{displayNamePrefix}/{page}/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record<hasMore: bool, page: int, searchResults: list<record>>, ThrottleSeconds: int>
# operationId: User.SearchByGlobalNamePrefix
export def "user-search-by-global-name-prefix" [
  display_name_prefix: string
  page: int
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
    path: "/User/Search/Prefix/{displayNamePrefix}/{page}/"
    path_params: [{name: displayNamePrefix, var: display_name_prefix}, {name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    display_name_prefix: $display_name_prefix, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the user-specific system overrides that should be respected alongside common systems.
#
# GET /UserSystemOverrides/
# Returns: record<DetailedErrorTrace: string, ErrorCode: int, ErrorStatus: string, Message: string, MessageData: record, Response: record, ThrottleSeconds: int>
# operationId: .GetUserSystemOverrides
export def "get-user-system-overrides" [
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
    path: "/UserSystemOverrides/"
    accept: ["*/*"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
