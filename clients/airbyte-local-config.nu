# Auto-generated client for Airbyte Configuration API v1.0.0
# Source: https://api.apis.guru/v2/specs/airbyte.local/config/1.0.0/openapi.json
# Auth: --token flag or $env.AIRBYTE_CONFIGURATION_API_TOKEN

const CLIENT = {
  base_url: "http://airbyte.local"
  token_env_var: "AIRBYTE_CONFIGURATION_API_TOKEN"
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

def base-url-completer [] { ["http://airbyte.local" "http://localhost:8000/api"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def geography-completer [] { ["auto" "eu" "us"] }
def namespace-definition-completer [] { ["customformat" "destination" "source"] }
def non-breaking-changes-preference-completer [] { ["disable" "ignore"] }
def schedule-type-completer [] { ["basic" "cron" "manual"] }
def status-completer [] { ["active" "deprecated" "inactive"] }
def log-type-completer [] { ["scheduler" "server"] }
def notification-type-completer [] { ["customerio" "slack"] }
def operator-type-completer [] { ["dbt" "normalization" "webhook"] }
def default-geography-completer [] { ["auto" "eu" "us"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    save-stats: "record<succeeded: bool>"
    save-sync-config: "record<succeeded: bool>"
    set-workflow-in-attempt: "record<succeeded: bool>"
    create-connection: "record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>"
    get-connection: "record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>"
    list-connections-for-workspace: "record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>>"
    list-all-connections-for-workspace: "record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>>"
    reset-connection: "record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>"
    search-connections: "record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>>"
    sync-connection: "record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>"
    update-connection: "record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>"
    get-destination-definition-specification: "record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: any, destinationDefinitionId: string, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, supportedDestinationSyncModes: list<string>>"
    create-custom-destination-definition: "record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>"
    get-destination-definition: "record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>"
    get-destination-definition-for-workspace: "record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>"
    grant-destination-definition-to-workspace: "record<destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, supportsDbt: bool>, granted: bool>"
    list-destination-definitions: "record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>>"
    list-destination-definitions-for-workspace: "record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>>"
    list-latest-destination-definitions: "record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>>"
    list-private-destination-definitions: "record<destinationDefinitions: table<destinationDefinition: record, granted: bool>>"
    update-destination-definition: "record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>"
    complete-destination-o-auth: "record"
    get-destination-o-auth-consent: "record<consentUrl: string>"
    check-connection-to-destination: "record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>"
    check-connection-to-destination-for-update: "record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>"
    clone-destination: "record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>"
    create-destination: "record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>"
    get-destination: "record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>"
    list-destinations-for-workspace: "record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>>"
    search-destinations: "record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>>"
    update-destination: "record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>"
    get-health-check: "record<available: bool>"
    cancel-job: "record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>"
    get-job-info: "record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>"
    get-job-debug-info: "record<attempts: table<attempt: record, logs: record>, job: record<airbyteVersion: string, configId: string, configType: string, destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>, id: int, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>, status: string>, workflowState: record<running: bool>>"
    get-last-replication-job: "record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>"
    get-job-info-light: "record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>"
    get-attempt-normalization-statuses-for-job: "record<attemptNormalizationStatuses: table<attemptNumber: int, hasNormalizationFailed: bool, hasRecordsCommitted: bool, recordsCommitted: int>>"
    list-jobs-for: "record<jobs: table<attempts: list, job: record>, totalJobCount: int>"
    get-logs: "binary"
    try-notification-config: "record<message: string, status: string>"
    get-open-api-spec: "binary"
    check-operation: "record<message: string, status: string>"
    create-operation: "record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string>"
    get-operation: "record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string>"
    list-operations-for-connection: "record<operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>>"
    update-operation: "record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string>"
    execute-destination-check-connection: "record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>"
    execute-source-check-connection: "record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>"
    execute-source-discover-schema: "record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>>"
    get-source-definition-specification: "record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: record, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, sourceDefinitionId: string>"
    create-custom-source-definition: "record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>"
    get-source-definition: "record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>"
    get-source-definition-for-workspace: "record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>"
    grant-source-definition-to-workspace: "record<granted: bool, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, sourceDefinitionId: string, sourceType: string>>"
    list-source-definitions: "record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>>"
    list-source-definitions-for-workspace: "record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>>"
    list-latest-source-definitions: "record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>>"
    list-private-source-definitions: "record<sourceDefinitions: table<granted: bool, sourceDefinition: record>>"
    update-source-definition: "record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>"
    complete-source-o-auth: "record"
    get-source-o-auth-consent: "record<consentUrl: string>"
    check-connection-to-source: "record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>"
    check-connection-to-source-for-update: "record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>"
    clone-source: "record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>"
    create-source: "record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>"
    discover-schema-for-source: "record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>>"
    get-source: "record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>"
    list-sources-for-workspace: "record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>>"
    get-most-recent-source-actor-catalog: "record<catalog: record, updatedAt: int>"
    search-sources: "record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>>"
    update-source: "record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>"
    write-discover-catalog-result: "record<catalogId: string>"
    create-or-update-state: "record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>>"
    get-state: "record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>>"
    web-backend-check-updates: "record<destinationDefinitions: int, sourceDefinitions: int>"
    web-backend-create-connection: "record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>"
    web-backend-get-connection: "record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>"
    web-backend-list-connections-for-workspace: "record<connections: table<connectionId: string, destination: record, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, scheduleData: record, scheduleType: string, schemaChange: string, source: record, status: string>>"
    web-backend-update-connection: "record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>"
    web-backend-list-geographies: "record<geographies: list<string>>"
    get-state-type: "string"
    web-backend-get-workspace-state: "record<hasConnections: bool, hasDestinations: bool, hasSources: bool>"
    create-workspace: "record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>"
    get-workspace: "record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>"
    get-workspace-by-connection-id: "record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>"
    get-workspace-by-slug: "record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>"
    list-workspaces: "record<workspaces: table<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: list, securityUpdates: bool, slug: string, webhookConfigs: list, workspaceId: string>>"
    update-workspace: "record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>"
    update-workspace-name: "record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["save-stats" "save-sync-config" "set-workflow-in-attempt" "create-connection" "delete-connection" "get-connection" "list-connections-for-workspace" "list-all-connections-for-workspace" "reset-connection" "search-connections" "sync-connection" "update-connection" "get-destination-definition-specification" "create-custom-destination-definition" "delete-destination-definition" "get-destination-definition" "get-destination-definition-for-workspace" "grant-destination-definition-to-workspace" "list-destination-definitions" "list-destination-definitions-for-workspace" "list-latest-destination-definitions" "list-private-destination-definitions" "revoke-destination-definition-from-workspace" "update-destination-definition" "complete-destination-o-auth" "get-destination-o-auth-consent" "set-instancewide-destination-oauth-params" "check-connection-to-destination" "check-connection-to-destination-for-update" "clone-destination" "create-destination" "delete-destination" "get-destination" "list-destinations-for-workspace" "search-destinations" "update-destination" "get-health-check" "cancel-job" "get-job-info" "get-job-debug-info" "get-last-replication-job" "get-job-info-light" "get-attempt-normalization-statuses-for-job" "list-jobs-for" "get-logs" "try-notification-config" "get-open-api-spec" "check-operation" "create-operation" "delete-operation" "get-operation" "list-operations-for-connection" "update-operation" "execute-destination-check-connection" "execute-source-check-connection" "execute-source-discover-schema" "get-source-definition-specification" "create-custom-source-definition" "delete-source-definition" "get-source-definition" "get-source-definition-for-workspace" "grant-source-definition-to-workspace" "list-source-definitions" "list-source-definitions-for-workspace" "list-latest-source-definitions" "list-private-source-definitions" "revoke-source-definition-from-workspace" "update-source-definition" "complete-source-o-auth" "get-source-o-auth-consent" "set-instancewide-source-oauth-params" "check-connection-to-source" "check-connection-to-source-for-update" "clone-source" "create-source" "delete-source" "discover-schema-for-source" "get-source" "list-sources-for-workspace" "get-most-recent-source-actor-catalog" "search-sources" "update-source" "write-discover-catalog-result" "create-or-update-state" "get-state" "web-backend-check-updates" "web-backend-create-connection" "web-backend-get-connection" "web-backend-list-connections-for-workspace" "web-backend-update-connection" "web-backend-list-geographies" "get-state-type" "web-backend-get-workspace-state" "create-workspace" "delete-workspace" "get-workspace" "get-workspace-by-connection-id" "get-workspace-by-slug" "list-workspaces" "update-workspace-feedback" "update-workspace" "update-workspace-name" "commands"] | sort) } | get name | first)
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

# For worker to set sync stats of a running attempt.
#
# POST /v1/attempt/save_stats
# Returns: record<succeeded: bool>
# operationId: saveStats
export def "save-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attempt_number: int # format: int32
  job_id: int # format: int64
  stats: record # shape: {bytesEmitted?: int, estimatedBytes?: int, estimatedRecords?: int, recordsCommitted?: int, recordsEmitted?: int, stateMessagesEmitted?: int}
  --stream-stats: list # item shape: {stats: record, streamName: string, streamNamespace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/attempt/save_stats"
    body: {content_type: "application/json", kind: json, fields: [{name: attemptNumber, var: attempt_number}, {name: jobId, var: job_id}, {name: stats, var: stats}, {name: streamStats, var: stream_stats}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attempt_number: $attempt_number, job_id: $job_id, stats: $stats, stream_stats: $stream_stats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For worker to save the AttemptSyncConfig for an attempt.
#
# POST /v1/attempt/save_sync_config
# Returns: record<succeeded: bool>
# operationId: saveSyncConfig
export def "save-sync-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attempt_number: int # format: int32
  job_id: int # format: int64
  sync_config: record # shape: {destinationConfiguration: any, sourceConfiguration: any, state?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/attempt/save_sync_config"
    body: {content_type: "application/json", kind: json, fields: [{name: attemptNumber, var: attempt_number}, {name: jobId, var: job_id}, {name: syncConfig, var: sync_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attempt_number: $attempt_number, job_id: $job_id, sync_config: $sync_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For worker to register the workflow id in attempt.
#
# POST /v1/attempt/set_workflow_in_attempt
# Returns: record<succeeded: bool>
# operationId: setWorkflowInAttempt
export def "set-workflow-in-attempt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attempt_number: int # format: int32
  job_id: int # format: int64
  --processing-task-queue: string # default: ""
  workflow_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/attempt/set_workflow_in_attempt"
    body: {content_type: "application/json", kind: json, fields: [{name: attemptNumber, var: attempt_number}, {name: jobId, var: job_id}, {name: processingTaskQueue, var: processing_task_queue}, {name: workflowId, var: workflow_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attempt_number: $attempt_number, job_id: $job_id, processing_task_queue: $processing_task_queue, workflow_id: $workflow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a connection between a source and a destination
#
# POST /v1/connections/create
# Returns: record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>
# operationId: createConnection
export def "create-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Optional name of the connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --notify-schema-changes: oneof<nothing, bool>
  --operation-ids: list<string>
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --source-catalog-id: string # format: uuid
  source_id: string # format: uuid
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/create"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationId, var: destination_id}, {name: geography, var: geography}, {name: name, var: name}, {name: namespaceDefinition, var: namespace_definition}, {name: namespaceFormat, var: namespace_format}, {name: nonBreakingChangesPreference, var: non_breaking_changes_preference}, {name: notifySchemaChanges, var: notify_schema_changes}, {name: operationIds, var: operation_ids}, {name: prefix, var: prefix}, {name: resourceRequirements, var: resource_requirements}, {name: schedule, var: schedule}, {name: scheduleData, var: schedule_data}, {name: scheduleType, var: schedule_type}, {name: sourceCatalogId, var: source_catalog_id}, {name: sourceId, var: source_id}, {name: status, var: status}, {name: syncCatalog, var: sync_catalog}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_id: $destination_id, geography: $geography, name: $name, namespace_definition: $namespace_definition, namespace_format: $namespace_format, non_breaking_changes_preference: $non_breaking_changes_preference, notify_schema_changes: $notify_schema_changes, operation_ids: $operation_ids, prefix: $prefix, resource_requirements: $resource_requirements, schedule: $schedule, schedule_data: $schedule_data, schedule_type: $schedule_type, source_catalog_id: $source_catalog_id, source_id: $source_id, status: $status, sync_catalog: $sync_catalog
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a connection
#
# POST /v1/connections/delete
# operationId: deleteConnection
export def "delete-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/connections/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a connection
#
# POST /v1/connections/get
# Returns: record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>
# operationId: getConnection
export def "get-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/get"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all connections for a workspace.
#
# POST /v1/connections/list
# Returns: record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>>
# operationId: listConnectionsForWorkspace
export def "list-connections-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/list"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all connections for a workspace, including deleted connections.
#
# POST /v1/connections/list_all
# Returns: record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>>
# operationId: listAllConnectionsForWorkspace
export def "list-all-connections-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/list_all"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the data for the connection. Deletes data generated by the connection in the destination. Resets any cursors back to initial state.
#
# POST /v1/connections/reset
# Returns: record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>
# operationId: resetConnection
export def "reset-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/reset"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search connections
#
# POST /v1/connections/search
# Returns: record<connections: table<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list, prefix: string, resourceRequirements: record, schedule: record, scheduleData: record, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record>>
# operationId: searchConnections
export def "search-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # format: uuid
  --destination: record # shape: {connectionConfiguration?: any, destinationDefinitionId?: string, destinationId?: string, destinationName?: string, name?: string, workspaceId?: string}
  --destination-id: string # format: uuid
  --name: string
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --source: record # shape: {connectionConfiguration?: any, name?: string, sourceDefinitionId?: string, sourceId?: string, sourceName?: string, workspaceId?: string}
  --source-id: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/search"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: destination, var: destination}, {name: destinationId, var: destination_id}, {name: name, var: name}, {name: namespaceDefinition, var: namespace_definition}, {name: namespaceFormat, var: namespace_format}, {name: prefix, var: prefix}, {name: schedule, var: schedule}, {name: scheduleData, var: schedule_data}, {name: scheduleType, var: schedule_type}, {name: source, var: source}, {name: sourceId, var: source_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, destination: $destination, destination_id: $destination_id, name: $name, namespace_definition: $namespace_definition, namespace_format: $namespace_format, prefix: $prefix, schedule: $schedule, schedule_data: $schedule_data, schedule_type: $schedule_type, source: $source, source_id: $source_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a manual sync of the connection
#
# POST /v1/connections/sync
# Returns: record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>
# operationId: syncConnection
export def "sync-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/sync"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a connection
#
# POST /v1/connections/update
# Returns: record<breakingChange: bool, connectionId: string, destinationId: string, geography: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, sourceCatalogId: string, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>
# operationId: updateConnection
export def "update-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --breaking-change: oneof<nothing, bool>
  connection_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Name that will be set to this connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --notify-schema-changes: oneof<nothing, bool>
  --operation-ids: list<string>
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --source-catalog-id: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/connections/update"
    body: {content_type: "application/json", kind: json, fields: [{name: breakingChange, var: breaking_change}, {name: connectionId, var: connection_id}, {name: geography, var: geography}, {name: name, var: name}, {name: namespaceDefinition, var: namespace_definition}, {name: namespaceFormat, var: namespace_format}, {name: nonBreakingChangesPreference, var: non_breaking_changes_preference}, {name: notifySchemaChanges, var: notify_schema_changes}, {name: operationIds, var: operation_ids}, {name: prefix, var: prefix}, {name: resourceRequirements, var: resource_requirements}, {name: schedule, var: schedule}, {name: scheduleData, var: schedule_data}, {name: scheduleType, var: schedule_type}, {name: sourceCatalogId, var: source_catalog_id}, {name: status, var: status}, {name: syncCatalog, var: sync_catalog}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    breaking_change: $breaking_change, connection_id: $connection_id, geography: $geography, name: $name, namespace_definition: $namespace_definition, namespace_format: $namespace_format, non_breaking_changes_preference: $non_breaking_changes_preference, notify_schema_changes: $notify_schema_changes, operation_ids: $operation_ids, prefix: $prefix, resource_requirements: $resource_requirements, schedule: $schedule, schedule_data: $schedule_data, schedule_type: $schedule_type, source_catalog_id: $source_catalog_id, status: $status, sync_catalog: $sync_catalog
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specification for a destinationDefinition
#
# POST /v1/destination_definition_specifications/get
# Returns: record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: any, destinationDefinitionId: string, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, supportedDestinationSyncModes: list<string>>
# operationId: getDestinationDefinitionSpecification
export def "get-destination-definition-specification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definition_specifications/get"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom destinationDefinition for the given workspace
#
# POST /v1/destination_definitions/create_custom
# Returns: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>
# operationId: createCustomDestinationDefinition
export def "create-custom-destination-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition: record # shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/create_custom"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinition, var: destination_definition}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition: $destination_definition, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a destination definition
#
# POST /v1/destination_definitions/delete
# operationId: deleteDestinationDefinition
export def "delete-destination-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get destinationDefinition
#
# POST /v1/destination_definitions/get
# Returns: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>
# operationId: getDestinationDefinition
export def "get-destination-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/get"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a destinationDefinition that is configured for the given workspace
#
# POST /v1/destination_definitions/get_for_workspace
# Returns: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>
# operationId: getDestinationDefinitionForWorkspace
export def "get-destination-definition-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/get_for_workspace"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# grant a private, non-custom destinationDefinition to a given workspace
#
# POST /v1/destination_definitions/grant_definition
# Returns: record<destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, supportsDbt: bool>, granted: bool>
# operationId: grantDestinationDefinitionToWorkspace
export def "grant-destination-definition-to-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/grant_definition"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the destinationDefinitions the current Airbyte deployment is configured to use
#
# POST /v1/destination_definitions/list
# Returns: record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>>
# operationId: listDestinationDefinitions
export def "list-destination-definitions" [
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
    path: "/v1/destination_definitions/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the destinationDefinitions the given workspace is configured to use
#
# POST /v1/destination_definitions/list_for_workspace
# Returns: record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>>
# operationId: listDestinationDefinitionsForWorkspace
export def "list-destination-definitions-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/list_for_workspace"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the latest destinationDefinitions Airbyte supports
#
# POST /v1/destination_definitions/list_latest
# Returns: record<destinationDefinitions: table<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>>
# operationId: listLatestDestinationDefinitions
export def "list-latest-destination-definitions" [
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
    path: "/v1/destination_definitions/list_latest"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all private, non-custom destinationDefinitions, and for each indicate whether the given workspace has a grant for using the definition. Used by admins to view and modify a given workspace's grants.
#
# POST /v1/destination_definitions/list_private
# Returns: record<destinationDefinitions: table<destinationDefinition: record, granted: bool>>
# operationId: listPrivateDestinationDefinitions
export def "list-private-destination-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/list_private"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# revoke a grant to a private, non-custom destinationDefinition from a given workspace
#
# POST /v1/destination_definitions/revoke_definition
# operationId: revokeDestinationDefinitionFromWorkspace
export def "revoke-destination-definition-from-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/revoke_definition"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update destinationDefinition
#
# POST /v1/destination_definitions/update
# Returns: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record<normalizationIntegrationType: string, normalizationRepository: string, normalizationTag: string, supported: bool>, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, supportsDbt: bool>
# operationId: updateDestinationDefinition
export def "update-destination-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  --docker-image-tag: string
  --resource-requirements: record # actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_definitions/update"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: dockerImageTag, var: docker_image_tag}, {name: resourceRequirements, var: resource_requirements}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, docker_image_tag: $docker_image_tag, resource_requirements: $resource_requirements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a destination def ID generate an access/refresh token etc.
#
# POST /v1/destination_oauths/complete_oauth
# Returns: record
# operationId: completeDestinationOAuth
export def "complete-destination-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  --destination-id: string # format: uuid
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --query-params: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --redirect-url: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_oauths/complete_oauth"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: destinationId, var: destination_id}, {name: oAuthInputConfiguration, var: o_auth_input_configuration}, {name: queryParams, var: query_params}, {name: redirectUrl, var: redirect_url}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, destination_id: $destination_id, o_auth_input_configuration: $o_auth_input_configuration, query_params: $query_params, redirect_url: $redirect_url, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a destination connector definition ID, return the URL to the consent screen where to redirect the user to.
#
# POST /v1/destination_oauths/get_consent_url
# Returns: record<consentUrl: string>
# operationId: getDestinationOAuthConsent
export def "get-destination-o-auth-consent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  --destination-id: string # format: uuid
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  redirect_url: string # The url to redirect to after getting the user consent
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destination_oauths/get_consent_url"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: destinationId, var: destination_id}, {name: oAuthInputConfiguration, var: o_auth_input_configuration}, {name: redirectUrl, var: redirect_url}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, destination_id: $destination_id, o_auth_input_configuration: $o_auth_input_configuration, redirect_url: $redirect_url, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets instancewide variables to be used for the oauth flow when creating this destination. When set, these variables will be injected into a connector's configuration before any interaction with the connector image itself. This enables running oauth flows with consistent variables e.g: the company's Google Ads developer_token, client_id, and client_secret without the user having to know about these variables.
#
# POST /v1/destination_oauths/oauth_params/create
# operationId: setInstancewideDestinationOauthParams
export def "set-instancewide-destination-oauth-params" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_definition_id: string # format: uuid
  params: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/destination_oauths/oauth_params/create"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationDefinitionId, var: destination_definition_id}, {name: params, var: params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_definition_id: $destination_definition_id, params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check connection to the destination
#
# POST /v1/destinations/check_connection
# Returns: record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>
# operationId: checkConnectionToDestination
export def "check-connection-to-destination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/check_connection"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationId, var: destination_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_id: $destination_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check connection for a proposed update to a destination
#
# POST /v1/destinations/check_connection_for_update
# Returns: record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>
# operationId: checkConnectionToDestinationForUpdate
export def "check-connection-to-destination-for-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_id: string # format: uuid
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/check_connection_for_update"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: destinationId, var: destination_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, destination_id: $destination_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clone destination
#
# POST /v1/destinations/clone
# Returns: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>
# operationId: cloneDestination
export def "clone-destination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_clone_id: string # format: uuid
  --destination-configuration: record # shape: {connectionConfiguration?: any, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/clone"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationCloneId, var: destination_clone_id}, {name: destinationConfiguration, var: destination_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_clone_id: $destination_clone_id, destination_configuration: $destination_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a destination
#
# POST /v1/destinations/create
# Returns: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>
# operationId: createDestination
export def "create-destination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_definition_id: string # format: uuid
  name: string
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/create"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: destinationDefinitionId, var: destination_definition_id}, {name: name, var: name}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, destination_definition_id: $destination_definition_id, name: $name, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the destination
#
# POST /v1/destinations/delete
# operationId: deleteDestination
export def "delete-destination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/destinations/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationId, var: destination_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    destination_id: $destination_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configured destination
#
# POST /v1/destinations/get
# Returns: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>
# operationId: getDestination
export def "get-destination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/get"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationId, var: destination_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_id: $destination_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List configured destinations for a workspace
#
# POST /v1/destinations/list
# Returns: record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>>
# operationId: listDestinationsForWorkspace
export def "list-destinations-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/list"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search destinations
#
# POST /v1/destinations/search
# Returns: record<destinations: table<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>>
# operationId: searchDestinations
export def "search-destinations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  --destination-definition-id: string # format: uuid
  --destination-id: string # format: uuid
  --destination-name: string
  --name: string
  --workspace-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/search"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: destinationDefinitionId, var: destination_definition_id}, {name: destinationId, var: destination_id}, {name: destinationName, var: destination_name}, {name: name, var: name}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, destination_definition_id: $destination_definition_id, destination_id: $destination_id, destination_name: $destination_name, name: $name, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a destination
#
# POST /v1/destinations/update
# Returns: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>
# operationId: updateDestination
export def "update-destination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_id: string # format: uuid
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/destinations/update"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: destinationId, var: destination_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, destination_id: $destination_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Health Check
#
# GET /v1/health
# Returns: record<available: bool>
# operationId: getHealthCheck
export def "get-health-check" [
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
    path: "/v1/health"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a job
#
# POST /v1/jobs/cancel
# Returns: record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>
# operationId: cancelJob
export def "cancel-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jobs/cancel"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a job
#
# POST /v1/jobs/get
# Returns: record<attempts: table<attempt: record, logs: record>, job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>
# operationId: getJobInfo
export def "get-job-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jobs/get"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all information needed to debug this job
#
# POST /v1/jobs/get_debug_info
# Returns: record<attempts: table<attempt: record, logs: record>, job: record<airbyteVersion: string, configId: string, configType: string, destinationDefinition: record<destinationDefinitionId: string, dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, normalizationConfig: record, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, supportsDbt: bool>, id: int, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>, status: string>, workflowState: record<running: bool>>
# operationId: getJobDebugInfo
export def "get-job-debug-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jobs/get_debug_info"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/jobs/get_last_replication_job
#
# Returns: record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>
# operationId: getLastReplicationJob
export def "get-last-replication-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jobs/get_last_replication_job"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a job excluding attempt info and logs
#
# POST /v1/jobs/get_light
# Returns: record<job: record<configId: string, configType: string, createdAt: int, id: int, resetConfig: record<streamsToReset: list>, startedAt: int, status: string, updatedAt: int>>
# operationId: getJobInfoLight
export def "get-job-info-light" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jobs/get_light"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get normalization status to determine if we can bypass normalization phase
#
# POST /v1/jobs/get_normalization_status
# Returns: record<attemptNormalizationStatuses: table<attemptNumber: int, hasNormalizationFailed: bool, hasRecordsCommitted: bool, recordsCommitted: int>>
# operationId: getAttemptNormalizationStatusesForJob
export def "get-attempt-normalization-statuses-for-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jobs/get_normalization_status"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns recent jobs for a connection. Jobs are returned in descending order by createdAt.
#
# POST /v1/jobs/list
# Returns: record<jobs: table<attempts: list, job: record>, totalJobCount: int>
# operationId: listJobsFor
export def "list-jobs-for" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config_id: string
  config_types: list<string>
  --including-job-id: int # format: int64
  --pagination: record # shape: {pageSize?: int, rowOffset?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jobs/list"
    body: {content_type: "application/json", kind: json, fields: [{name: configId, var: config_id}, {name: configTypes, var: config_types}, {name: includingJobId, var: including_job_id}, {name: pagination, var: pagination}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    config_id: $config_id, config_types: $config_types, including_job_id: $including_job_id, pagination: $pagination
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get logs
#
# POST /v1/logs/get
# Returns: binary
# operationId: getLogs
export def "get-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  log_type: string@log-type-completer # type/source of logs produced
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/logs/get"
    body: {content_type: "application/json", kind: json, fields: [{name: logType, var: log_type}]}
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    log_type: $log_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Try sending a notifications
#
# POST /v1/notifications/try
# Returns: record<message: string, status: string>
# operationId: tryNotificationConfig
export def "try-notification-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customerio-configuration: record
  notification_type: string@notification-type-completer
  --send-on-failure: oneof<nothing, bool> # default: true
  --send-on-success: oneof<nothing, bool> # default: false
  --slack-configuration: record # shape: {webhook: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/notifications/try"
    body: {content_type: "application/json", kind: json, fields: [{name: customerioConfiguration, var: customerio_configuration}, {name: notificationType, var: notification_type}, {name: sendOnFailure, var: send_on_failure, required: true}, {name: sendOnSuccess, var: send_on_success, required: true}, {name: slackConfiguration, var: slack_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customerio_configuration: $customerio_configuration, notification_type: $notification_type, send_on_failure: $send_on_failure, send_on_success: $send_on_success, slack_configuration: $slack_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the openapi specification
#
# GET /v1/openapi
# Returns: binary
# operationId: getOpenApiSpec
export def "get-open-api-spec" [
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
    path: "/v1/openapi"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if an operation to be created is valid
#
# POST /v1/operations/check
# Returns: record<message: string, status: string>
# operationId: checkOperation
export def "check-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbt: record # shape: {dbtArguments?: string, dockerImage?: string, gitRepoBranch?: string, gitRepoUrl: string}
  --normalization: record # shape: {option?: "basic"}
  operator_type: string@operator-type-completer
  --webhook: record # shape: {dbtCloud?: record, executionBody?: string, executionUrl?: string, webhookConfigId?: string, webhookType?: "dbtCloud"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/operations/check"
    body: {content_type: "application/json", kind: json, fields: [{name: dbt, var: dbt}, {name: normalization, var: normalization}, {name: operatorType, var: operator_type}, {name: webhook, var: webhook}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dbt: $dbt, normalization: $normalization, operator_type: $operator_type, webhook: $webhook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an operation to be applied as part of a connection pipeline
#
# POST /v1/operations/create
# Returns: record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string>
# operationId: createOperation
export def "create-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  operator_configuration: record # shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/operations/create"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: operatorConfiguration, var: operator_configuration}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, operator_configuration: $operator_configuration, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an operation
#
# POST /v1/operations/delete
# operationId: deleteOperation
export def "delete-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  operation_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/operations/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: operationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an operation
#
# POST /v1/operations/get
# Returns: record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string>
# operationId: getOperation
export def "get-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  operation_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/operations/get"
    body: {content_type: "application/json", kind: json, fields: [{name: operationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all operations for a connection.
#
# POST /v1/operations/list
# Returns: record<operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>>
# operationId: listOperationsForConnection
export def "list-operations-for-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/operations/list"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an operation
#
# POST /v1/operations/update
# Returns: record<name: string, operationId: string, operatorConfiguration: record<dbt: record<dbtArguments: string, dockerImage: string, gitRepoBranch: string, gitRepoUrl: string>, normalization: record<option: string>, operatorType: string, webhook: record<dbtCloud: record, executionBody: string, executionUrl: string, webhookConfigId: string, webhookType: string>>, workspaceId: string>
# operationId: updateOperation
export def "update-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  operation_id: string # format: uuid
  operator_configuration: record # shape: {dbt?: record, normalization?: record, operatorType: "normalization"|"dbt"|"webhook", webhook?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/operations/update"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: operationId, var: operation_id}, {name: operatorConfiguration, var: operator_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, operation_id: $operation_id, operator_configuration: $operator_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run check connection for a given destination configuration
#
# POST /v1/scheduler/destinations/check_connection
# Returns: record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>
# operationId: executeDestinationCheckConnection
export def "execute-destination-check-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the destination. The schema for this must match the schema return by destination_definition_specifications/get for the destinationDefinition. (e.g. {user: charles})
  destination_definition_id: string # format: uuid
  --destination-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/scheduler/destinations/check_connection"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: destinationDefinitionId, var: destination_definition_id}, {name: destinationId, var: destination_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, destination_definition_id: $destination_definition_id, destination_id: $destination_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run check connection for a given source configuration
#
# POST /v1/scheduler/sources/check_connection
# Returns: record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>
# operationId: executeSourceCheckConnection
export def "execute-source-check-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/scheduler/sources/check_connection"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: sourceDefinitionId, var: source_definition_id}, {name: sourceId, var: source_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, source_definition_id: $source_definition_id, source_id: $source_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run discover schema for a given source a source configuration
#
# POST /v1/scheduler/sources/discover_schema
# Returns: record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>>
# operationId: executeSourceDiscoverSchema
export def "execute-source-discover-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/scheduler/sources/discover_schema"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: sourceDefinitionId, var: source_definition_id}, {name: sourceId, var: source_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, source_definition_id: $source_definition_id, source_id: $source_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specification for a SourceDefinition.
#
# POST /v1/source_definition_specifications/get
# Returns: record<advancedAuth: record<authFlowType: string, oauthConfigSpecification: record<completeOAuthOutputSpecification: any, completeOAuthServerInputSpecification: any, completeOAuthServerOutputSpecification: any, oauthUserInputFromConnectorConfigSpecification: any>, predicateKey: list<string>, predicateValue: string>, authSpecification: record<auth_type: string, oauth2Specification: record<oauthFlowInitParameters: list, oauthFlowOutputParameters: list, rootObject: list>>, connectionSpecification: record, documentationUrl: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, sourceDefinitionId: string>
# operationId: getSourceDefinitionSpecification
export def "get-source-definition-specification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definition_specifications/get"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceDefinitionId, var: source_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_definition_id: $source_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom sourceDefinition for the given workspace
#
# POST /v1/source_definitions/create_custom
# Returns: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>
# operationId: createCustomSourceDefinition
export def "create-custom-source-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition: record # shape: {dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon?: string, name: string, resourceRequirements?: record}
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/create_custom"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceDefinition, var: source_definition}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_definition: $source_definition, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a source definition
#
# POST /v1/source_definitions/delete
# operationId: deleteSourceDefinition
export def "delete-source-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceDefinitionId, var: source_definition_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_definition_id: $source_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get source
#
# POST /v1/source_definitions/get
# Returns: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>
# operationId: getSourceDefinition
export def "get-source-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/get"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceDefinitionId, var: source_definition_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_definition_id: $source_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a sourceDefinition that is configured for the given workspace
#
# POST /v1/source_definitions/get_for_workspace
# Returns: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>
# operationId: getSourceDefinitionForWorkspace
export def "get-source-definition-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/get_for_workspace"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceDefinitionId, var: source_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_definition_id: $source_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# grant a private, non-custom sourceDefinition to a given workspace
#
# POST /v1/source_definitions/grant_definition
# Returns: record<granted: bool, sourceDefinition: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record, jobSpecific: list>, sourceDefinitionId: string, sourceType: string>>
# operationId: grantSourceDefinitionToWorkspace
export def "grant-source-definition-to-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/grant_definition"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceDefinitionId, var: source_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_definition_id: $source_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the sourceDefinitions the current Airbyte deployment is configured to use
#
# POST /v1/source_definitions/list
# Returns: record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>>
# operationId: listSourceDefinitions
export def "list-source-definitions" [
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
    path: "/v1/source_definitions/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the sourceDefinitions the given workspace is configured to use
#
# POST /v1/source_definitions/list_for_workspace
# Returns: record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>>
# operationId: listSourceDefinitionsForWorkspace
export def "list-source-definitions-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/list_for_workspace"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the latest sourceDefinitions Airbyte supports
#
# POST /v1/source_definitions/list_latest
# Returns: record<sourceDefinitions: table<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record, sourceDefinitionId: string, sourceType: string>>
# operationId: listLatestSourceDefinitions
export def "list-latest-source-definitions" [
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
    path: "/v1/source_definitions/list_latest"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all private, non-custom sourceDefinitions, and for each indicate whether the given workspace has a grant for using the definition. Used by admins to view and modify a given workspace's grants.
#
# POST /v1/source_definitions/list_private
# Returns: record<sourceDefinitions: table<granted: bool, sourceDefinition: record>>
# operationId: listPrivateSourceDefinitions
export def "list-private-source-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/list_private"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# revoke a grant to a private, non-custom sourceDefinition from a given workspace
#
# POST /v1/source_definitions/revoke_definition
# operationId: revokeSourceDefinitionFromWorkspace
export def "revoke-source-definition-from-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/revoke_definition"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceDefinitionId, var: source_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_definition_id: $source_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a sourceDefinition
#
# POST /v1/source_definitions/update
# Returns: record<dockerImageTag: string, dockerRepository: string, documentationUrl: string, icon: string, name: string, protocolVersion: string, releaseDate: string, releaseStage: string, resourceRequirements: record<default: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, jobSpecific: list<record>>, sourceDefinitionId: string, sourceType: string>
# operationId: updateSourceDefinition
export def "update-source-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  docker_image_tag: string
  --resource-requirements: record # actor definition specific resource requirements. if default is set, these are the requirements that should be set for ALL jobs run for this actor definition. it is overriden by the job type specific configurations. if not set, the platform will use defaults. these values will be overriden by configuration at the connection level. — shape: {default?: record, jobSpecific?: list}
  source_definition_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_definitions/update"
    body: {content_type: "application/json", kind: json, fields: [{name: dockerImageTag, var: docker_image_tag}, {name: resourceRequirements, var: resource_requirements}, {name: sourceDefinitionId, var: source_definition_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    docker_image_tag: $docker_image_tag, resource_requirements: $resource_requirements, source_definition_id: $source_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a source def ID generate an access/refresh token etc.
#
# POST /v1/source_oauths/complete_oauth
# Returns: record
# operationId: completeSourceOAuth
export def "complete-source-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  --query-params: record # The query parameters present in the redirect URL after a user granted consent e.g auth code
  --redirect-url: string # When completing OAuth flow to gain an access token, some API sometimes requires to verify that the app re-send the redirectUrl that was used when consent was given.
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_oauths/complete_oauth"
    body: {content_type: "application/json", kind: json, fields: [{name: oAuthInputConfiguration, var: o_auth_input_configuration}, {name: queryParams, var: query_params}, {name: redirectUrl, var: redirect_url}, {name: sourceDefinitionId, var: source_definition_id}, {name: sourceId, var: source_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    o_auth_input_configuration: $o_auth_input_configuration, query_params: $query_params, redirect_url: $redirect_url, source_definition_id: $source_definition_id, source_id: $source_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a source connector definition ID, return the URL to the consent screen where to redirect the user to.
#
# POST /v1/source_oauths/get_consent_url
# Returns: record<consentUrl: string>
# operationId: getSourceOAuthConsent
export def "get-source-o-auth-consent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --o-auth-input-configuration: any # The values required to configure OAuth flows. The schema for this must match the `OAuthConfigSpecification.oauthUserInputFromConnectorConfigSpecification` schema.
  redirect_url: string # The url to redirect to after getting the user consent
  source_definition_id: string # format: uuid
  --source-id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/source_oauths/get_consent_url"
    body: {content_type: "application/json", kind: json, fields: [{name: oAuthInputConfiguration, var: o_auth_input_configuration}, {name: redirectUrl, var: redirect_url}, {name: sourceDefinitionId, var: source_definition_id}, {name: sourceId, var: source_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    o_auth_input_configuration: $o_auth_input_configuration, redirect_url: $redirect_url, source_definition_id: $source_definition_id, source_id: $source_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets instancewide variables to be used for the oauth flow when creating this source. When set, these variables will be injected into a connector's configuration before any interaction with the connector image itself. This enables running oauth flows with consistent variables e.g: the company's Google Ads developer_token, client_id, and client_secret without the user having to know about these variables.
#
# POST /v1/source_oauths/oauth_params/create
# operationId: setInstancewideSourceOauthParams
export def "set-instancewide-source-oauth-params" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  params: record
  source_definition_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/source_oauths/oauth_params/create"
    body: {content_type: "application/json", kind: json, fields: [{name: params, var: params}, {name: sourceDefinitionId, var: source_definition_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    params: $params, source_definition_id: $source_definition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check connection to the source
#
# POST /v1/sources/check_connection
# Returns: record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>
# operationId: checkConnectionToSource
export def "check-connection-to-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/check_connection"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check connection for a proposed update to a source
#
# POST /v1/sources/check_connection_for_update
# Returns: record<jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>, message: string, status: string>
# operationId: checkConnectionToSourceForUpdate
export def "check-connection-to-source-for-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  source_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/check_connection_for_update"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: name, var: name}, {name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, name: $name, source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clone source
#
# POST /v1/sources/clone
# Returns: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>
# operationId: cloneSource
export def "clone-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_clone_id: string # format: uuid
  --source-configuration: record # shape: {connectionConfiguration?: any, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/clone"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceCloneId, var: source_clone_id}, {name: sourceConfiguration, var: source_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_clone_id: $source_clone_id, source_configuration: $source_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a source
#
# POST /v1/sources/create
# Returns: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>
# operationId: createSource
export def "create-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  source_definition_id: string # format: uuid
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/create"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: name, var: name}, {name: sourceDefinitionId, var: source_definition_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, name: $name, source_definition_id: $source_definition_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a source
#
# POST /v1/sources/delete
# operationId: deleteSource
export def "delete-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/sources/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Discover the schema catalog of the source
#
# POST /v1/sources/discover_schema
# Returns: record<breakingChange: bool, catalog: record<streams: list<record>>, catalogDiff: record<transforms: list<record>>, catalogId: string, connectionStatus: string, jobInfo: record<configId: string, configType: string, connectorConfigurationUpdated: bool, createdAt: int, endedAt: int, id: string, logs: record<logLines: list>, succeeded: bool>>
# operationId: discoverSchemaForSource
export def "discover-schema-for-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # format: uuid
  --disable-cache: oneof<nothing, bool>
  --notify-schema-change: oneof<nothing, bool>
  source_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/discover_schema"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: disable_cache, var: disable_cache}, {name: notifySchemaChange, var: notify_schema_change}, {name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, disable_cache: $disable_cache, notify_schema_change: $notify_schema_change, source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get source
#
# POST /v1/sources/get
# Returns: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>
# operationId: getSource
export def "get-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/get"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sources for workspace
#
# POST /v1/sources/list
# Returns: record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>>
# operationId: listSourcesForWorkspace
export def "list-sources-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/list"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get most recent ActorCatalog for source
#
# POST /v1/sources/most_recent_source_actor_catalog
# Returns: record<catalog: record, updatedAt: int>
# operationId: getMostRecentSourceActorCatalog
export def "get-most-recent-source-actor-catalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/most_recent_source_actor_catalog"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search sources
#
# POST /v1/sources/search
# Returns: record<sources: table<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>>
# operationId: searchSources
export def "search-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  --name: string
  --source-definition-id: string # format: uuid
  --source-id: string # format: uuid
  --source-name: string
  --workspace-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/search"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: name, var: name}, {name: sourceDefinitionId, var: source_definition_id}, {name: sourceId, var: source_id}, {name: sourceName, var: source_name}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, name: $name, source_definition_id: $source_definition_id, source_id: $source_id, source_name: $source_name, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a source
#
# POST /v1/sources/update
# Returns: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>
# operationId: updateSource
export def "update-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_configuration: any # The values required to configure the source. The schema for this must match the schema return by source_definition_specifications/get for the source. (e.g. {user: charles})
  name: string
  source_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/update"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionConfiguration, var: connection_configuration}, {name: name, var: name}, {name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_configuration: $connection_configuration, name: $name, source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Should only called from worker, to write result from discover activity back to DB.
#
# POST /v1/sources/write_discover_catalog_result
# Returns: record<catalogId: string>
# operationId: writeDiscoverCatalogResult
export def "write-discover-catalog-result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  catalog: record # describes the available schema (catalog). — shape: {streams: list}
  --configuration-hash: string
  --connector-version: string
  --source-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/sources/write_discover_catalog_result"
    body: {content_type: "application/json", kind: json, fields: [{name: catalog, var: catalog}, {name: configurationHash, var: configuration_hash}, {name: connectorVersion, var: connector_version}, {name: sourceId, var: source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    catalog: $catalog, configuration_hash: $configuration_hash, connector_version: $connector_version, source_id: $source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update the state for a connection.
#
# POST /v1/state/create_or_update
# Returns: record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>>
# operationId: createOrUpdateState
export def "create-or-update-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
  connection_state: record # Contains the state for a connection. The stateType field identifies what type of state it is. Only the field corresponding to that type will be set, the rest will be null. If stateType=not_set, then none of the fields will be set. — shape: {connectionId: string, globalState?: record, state?: record, stateType: "global"|"stream"|"legacy"|"not_set", streamState?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/state/create_or_update"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: connectionState, var: connection_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, connection_state: $connection_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the current state for a connection.
#
# POST /v1/state/get
# Returns: record<connectionId: string, globalState: record<shared_state: record, streamStates: list<record>>, state: record, stateType: string, streamState: table<streamDescriptor: record, streamState: record>>
# operationId: getState
export def "get-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/state/get"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a summary of source and destination definitions that could be updated.
#
# POST /v1/web_backend/check_updates
# Returns: record<destinationDefinitions: int, sourceDefinitions: int>
# operationId: webBackendCheckUpdates
export def "web-backend-check-updates" [
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
    path: "/v1/web_backend/check_updates"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a connection
#
# POST /v1/web_backend/connections/create
# Returns: record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>
# operationId: webBackendCreateConnection
export def "web-backend-create-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Optional name of the connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --operation-ids: list<string>
  --operations: list # item shape: {name: string, operatorConfiguration: record, workspaceId: string}
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --source-catalog-id: string # format: uuid
  source_id: string # format: uuid
  status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/web_backend/connections/create"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationId, var: destination_id}, {name: geography, var: geography}, {name: name, var: name}, {name: namespaceDefinition, var: namespace_definition}, {name: namespaceFormat, var: namespace_format}, {name: nonBreakingChangesPreference, var: non_breaking_changes_preference}, {name: operationIds, var: operation_ids}, {name: operations, var: operations}, {name: prefix, var: prefix}, {name: resourceRequirements, var: resource_requirements}, {name: schedule, var: schedule}, {name: scheduleData, var: schedule_data}, {name: scheduleType, var: schedule_type}, {name: sourceCatalogId, var: source_catalog_id}, {name: sourceId, var: source_id}, {name: status, var: status}, {name: syncCatalog, var: sync_catalog}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_id: $destination_id, geography: $geography, name: $name, namespace_definition: $namespace_definition, namespace_format: $namespace_format, non_breaking_changes_preference: $non_breaking_changes_preference, operation_ids: $operation_ids, operations: $operations, prefix: $prefix, resource_requirements: $resource_requirements, schedule: $schedule, schedule_data: $schedule_data, schedule_type: $schedule_type, source_catalog_id: $source_catalog_id, source_id: $source_id, status: $status, sync_catalog: $sync_catalog
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a connection
#
# POST /v1/web_backend/connections/get
# Returns: record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>
# operationId: webBackendGetConnection
export def "web-backend-get-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
  --with-refreshed-catalog: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/web_backend/connections/get"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: withRefreshedCatalog, var: with_refreshed_catalog}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, with_refreshed_catalog: $with_refreshed_catalog
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all non-deleted connections for a workspace.
#
# POST /v1/web_backend/connections/list
# Returns: record<connections: table<connectionId: string, destination: record, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, scheduleData: record, scheduleType: string, schemaChange: string, source: record, status: string>>
# operationId: webBackendListConnectionsForWorkspace
export def "web-backend-list-connections-for-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination-id: list<string>
  --source-id: list<string>
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/web_backend/connections/list"
    body: {content_type: "application/json", kind: json, fields: [{name: destinationId, var: destination_id}, {name: sourceId, var: source_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination_id: $destination_id, source_id: $source_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a connection
#
# POST /v1/web_backend/connections/update
# Returns: record<catalogDiff: record<transforms: list<record>>, catalogId: string, connectionId: string, destination: record<connectionConfiguration: any, destinationDefinitionId: string, destinationId: string, destinationName: string, icon: string, name: string, workspaceId: string>, destinationId: string, geography: string, isSyncing: bool, latestSyncJobCreatedAt: int, latestSyncJobStatus: string, name: string, namespaceDefinition: string, namespaceFormat: string, nonBreakingChangesPreference: string, notifySchemaChanges: bool, operationIds: list<string>, operations: table<name: string, operationId: string, operatorConfiguration: record, workspaceId: string>, prefix: string, resourceRequirements: record<cpu_limit: string, cpu_request: string, memory_limit: string, memory_request: string>, schedule: record<timeUnit: string, units: int>, scheduleData: record<basicSchedule: record<timeUnit: string, units: int>, cron: record<cronExpression: string, cronTimeZone: string>>, scheduleType: string, schemaChange: string, source: record<connectionConfiguration: any, icon: string, name: string, sourceDefinitionId: string, sourceId: string, sourceName: string, workspaceId: string>, sourceId: string, status: string, syncCatalog: record<streams: list<record>>>
# operationId: webBackendUpdateConnection
export def "web-backend-update-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
  --geography: string@geography-completer
  --name: string # Name that will be set to the connection
  --namespace-definition: string@namespace-definition-completer # Method used for computing final namespace in destination
  --namespace-format: string # Used when namespaceDefinition is 'customformat'. If blank then behaves like namespaceDefinition = 'destination'. If "${SOURCE_NAMESPACE}" then behaves like namespaceDefinition = 'source'. (e.g. ${SOURCE_NAMESPACE})
  --non-breaking-changes-preference: string@non-breaking-changes-preference-completer
  --notify-schema-changes: oneof<nothing, bool>
  --operations: list # item shape: {name: string, operationId?: string, operatorConfiguration: record, workspaceId: string}
  --prefix: string # Prefix that will be prepended to the name of each stream when it is written to the destination.
  --resource-requirements: record # optional resource requirements to run workers (blank for unbounded allocations) — shape: {cpu_limit?: string, cpu_request?: string, memory_limit?: string, memory_request?: string}
  --schedule: record # if null, then no schedule is set. — shape: {timeUnit: "minutes"|"hours"|"days"|"weeks"|"months", units: int}
  --schedule-data: record # schedule for when the the connection should run, per the schedule type — shape: {basicSchedule?: record, cron?: record}
  --schedule-type: string@schedule-type-completer # determine how the schedule data should be interpreted
  --skip-reset: oneof<nothing, bool>
  --source-catalog-id: string # format: uuid
  --status: string@status-completer # Active means that data is flowing through the connection. Inactive means it is not. Deprecated means the connection is off and cannot be re-activated. the schema field describes the elements of the schema that will be synced.
  --sync-catalog: record # describes the available schema (catalog). — shape: {streams: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/web_backend/connections/update"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: geography, var: geography}, {name: name, var: name}, {name: namespaceDefinition, var: namespace_definition}, {name: namespaceFormat, var: namespace_format}, {name: nonBreakingChangesPreference, var: non_breaking_changes_preference}, {name: notifySchemaChanges, var: notify_schema_changes}, {name: operations, var: operations}, {name: prefix, var: prefix}, {name: resourceRequirements, var: resource_requirements}, {name: schedule, var: schedule}, {name: scheduleData, var: schedule_data}, {name: scheduleType, var: schedule_type}, {name: skipReset, var: skip_reset}, {name: sourceCatalogId, var: source_catalog_id}, {name: status, var: status}, {name: syncCatalog, var: sync_catalog}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, geography: $geography, name: $name, namespace_definition: $namespace_definition, namespace_format: $namespace_format, non_breaking_changes_preference: $non_breaking_changes_preference, notify_schema_changes: $notify_schema_changes, operations: $operations, prefix: $prefix, resource_requirements: $resource_requirements, schedule: $schedule, schedule_data: $schedule_data, schedule_type: $schedule_type, skip_reset: $skip_reset, source_catalog_id: $source_catalog_id, status: $status, sync_catalog: $sync_catalog
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns available geographies can be selected to run data syncs in a particular geography. The 'auto' entry indicates that the sync will be automatically assigned to a geography according to the platform default behavior. Entries other than 'auto' are two-letter country codes that follow the ISO 3166-1 alpha-2 standard.
#
# POST /v1/web_backend/geographies/list
# Returns: record<geographies: list<string>>
# operationId: webBackendListGeographies
export def "web-backend-list-geographies" [
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
    path: "/v1/web_backend/geographies/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the current state type for a connection.
#
# POST /v1/web_backend/state/get_type
# Returns: string
# operationId: getStateType
export def "get-state-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/web_backend/state/get_type"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current state of a workspace
#
# POST /v1/web_backend/workspace/state
# Returns: record<hasConnections: bool, hasDestinations: bool, hasSources: bool>
# operationId: webBackendGetWorkspaceState
export def "web-backend-get-workspace-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/web_backend/workspace/state"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a workspace
#
# POST /v1/workspaces/create
# Returns: record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>
# operationId: createWorkspace
export def "create-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --anonymous-data-collection: oneof<nothing, bool>
  --default-geography: string@default-geography-completer
  --display-setup-wizard: oneof<nothing, bool>
  --email: string # format: email
  name: string
  --news: oneof<nothing, bool>
  --notifications: list # item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
  --security-updates: oneof<nothing, bool>
  --webhook-configs: list # item shape: {authToken?: string, name?: string, validationUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workspaces/create"
    body: {content_type: "application/json", kind: json, fields: [{name: anonymousDataCollection, var: anonymous_data_collection}, {name: defaultGeography, var: default_geography}, {name: displaySetupWizard, var: display_setup_wizard}, {name: email, var: email}, {name: name, var: name}, {name: news, var: news}, {name: notifications, var: notifications}, {name: securityUpdates, var: security_updates}, {name: webhookConfigs, var: webhook_configs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    anonymous_data_collection: $anonymous_data_collection, default_geography: $default_geography, display_setup_wizard: $display_setup_wizard, email: $email, name: $name, news: $news, notifications: $notifications, security_updates: $security_updates, webhook_configs: $webhook_configs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a workspace
#
# POST /v1/workspaces/delete
# operationId: deleteWorkspace
export def "delete-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/workspaces/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find workspace by ID
#
# POST /v1/workspaces/get
# Returns: record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>
# operationId: getWorkspace
export def "get-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workspaces/get"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find workspace by connection id
#
# POST /v1/workspaces/get_by_connection_id
# Returns: record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>
# operationId: getWorkspaceByConnectionId
export def "get-workspace-by-connection-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workspaces/get_by_connection_id"
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find workspace by slug
#
# POST /v1/workspaces/get_by_slug
# Returns: record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>
# operationId: getWorkspaceBySlug
export def "get-workspace-by-slug" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workspaces/get_by_slug"
    body: {content_type: "application/json", kind: json, fields: [{name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all workspaces registered in the current Airbyte deployment
#
# POST /v1/workspaces/list
# Returns: record<workspaces: table<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: list, securityUpdates: bool, slug: string, webhookConfigs: list, workspaceId: string>>
# operationId: listWorkspaces
export def "list-workspaces" [
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
    path: "/v1/workspaces/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update workspace feedback state
#
# POST /v1/workspaces/tag_feedback_status_as_done
# operationId: updateWorkspaceFeedback
export def "update-workspace-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  workspace_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/workspaces/tag_feedback_status_as_done"
    body: {content_type: "application/json", kind: json, fields: [{name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update workspace state
#
# POST /v1/workspaces/update
# Returns: record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>
# operationId: updateWorkspace
export def "update-workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --anonymous-data-collection: oneof<nothing, bool>
  --default-geography: string@default-geography-completer
  --display-setup-wizard: oneof<nothing, bool>
  --email: string # format: email
  --initial-setup-complete: oneof<nothing, bool>
  --news: oneof<nothing, bool>
  --notifications: list # item shape: {customerioConfiguration?: record, notificationType: "slack"|"customerio", sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration?: record}
  --security-updates: oneof<nothing, bool>
  --webhook-configs: list # item shape: {authToken?: string, name?: string, validationUrl?: string}
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workspaces/update"
    body: {content_type: "application/json", kind: json, fields: [{name: anonymousDataCollection, var: anonymous_data_collection}, {name: defaultGeography, var: default_geography}, {name: displaySetupWizard, var: display_setup_wizard}, {name: email, var: email}, {name: initialSetupComplete, var: initial_setup_complete}, {name: news, var: news}, {name: notifications, var: notifications}, {name: securityUpdates, var: security_updates}, {name: webhookConfigs, var: webhook_configs}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    anonymous_data_collection: $anonymous_data_collection, default_geography: $default_geography, display_setup_wizard: $display_setup_wizard, email: $email, initial_setup_complete: $initial_setup_complete, news: $news, notifications: $notifications, security_updates: $security_updates, webhook_configs: $webhook_configs, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update workspace name
#
# POST /v1/workspaces/update_name
# Returns: record<anonymousDataCollection: bool, customerId: string, defaultGeography: string, displaySetupWizard: bool, email: string, feedbackDone: bool, firstCompletedSync: bool, initialSetupComplete: bool, name: string, news: bool, notifications: table<customerioConfiguration: record, notificationType: string, sendOnFailure: bool, sendOnSuccess: bool, slackConfiguration: record>, securityUpdates: bool, slug: string, webhookConfigs: table<id: string, name: string>, workspaceId: string>
# operationId: updateWorkspaceName
export def "update-workspace-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  workspace_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workspaces/update_name"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
