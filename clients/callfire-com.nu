# Auto-generated client for CallFire API Documentation V2
# Source: https://api.apis.guru/v2/specs/callfire.com/V2/openapi.json
# Auth: --token flag or $env.CALLFIRE_API_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://api.callfire.com/v2"
  token_env_var: "CALLFIRE_API_DOCUMENTATION_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://api.callfire.com/v2"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def default-voice-completer [] { ["FEMALE1" "FEMALE2" "FRENCHCANADIAN1" "MALE1" "SPANISH1"] }
def answering-machine-config-completer [] { ["AM_AND_LIVE" "AM_ONLY" "LIVE_IMMEDIATE" "LIVE_WITH_AMD"] }
def status-completer [] { ["ACTIVE" "ERRORS" "NEW" "SOURCE_ERROR" "VALIDATING"] }
def voice-completer [] { ["FEMALE1" "FEMALE2" "FRENCHCANADIAN1" "MALE1" "SPANISH1"] }
def status-completer-1 [] { ["ACTIVE" "PENDING" "RELEASED" "UNAVAILABLE"] }
def type-completer [] { ["EXTRA" "PLAN"] }
def accept-completer [] { ["audio/m4a" "audio/mp3" "audio/wav" "image/gif" "image/jpeg" "image/png" "image/x-bmp" "video/3gpp" "video/mp4"] }
def config-type-completer [] { ["IVR" "TRACKING"] }
def call-feature-status-completer [] { ["DISABLED" "ENABLED" "PENDING" "UNSUPPORTED"] }
def text-feature-status-completer [] { ["DISABLED" "ENABLED" "PENDING" "UNSUPPORTED"] }
def delivery-category-completer [] { ["BOUNCED" "DELIVERED" "NO_CREDITS" "NO_DATA" "OPTED_OUT"] }
def delivery-state-completer [] { ["BUFFERED" "CARRIER_REJECTED" "DELIVERED" "DUPE" "FORWARDED" "GATEWAY_REJECTED" "NOT_DELIVERED" "NOT_GIVEN" "ORIGINAL" "ORIGINATED" "QUEUED" "QUEUED_TRANSCODE" "RATE_LIMIT_EXCEEDED" "REQUEUED_RATE_LIMITED" "REQUEUED_RECOVERABLE_ERROR" "RETRY_MMS_AS_SMS" "SEND_MMS_AS_SMS" "SEND_WITH_ADDITIONAL_SPID" "SERVICE_UNAVAILABLE" "SPAM_DETECTED" "SUBMITTED" "TRUNCATED" "UNKNOWN" "UNSENT_ALREADY_SCRUBBED" "UNSENT_BAD_DATA" "UNSENT_DAILY_LIMIT_REACHED" "UNSENT_FORCE_STOPPED" "UNSENT_FREE_TRIAL" "UNSENT_INTERNATIONAL" "UNSENT_INVALID_NUMBER" "UNSENT_INVALID_TIMEZONE_OR_DNC" "UNSENT_MESSAGE_BLOCKED" "UNSENT_MESSAGE_TOO_LONG" "UNSENT_NO_CREDITS" "UNSENT_NO_GATEWAY" "UNSENT_NO_WIRELESS_CARRIER" "UNSENT_OPTED_OUT_GLOBAL" "UNSENT_OPTED_OUT_LOCAL" "UNSENT_PERIOD_LIMIT" "UNSENT_QUEUE_LIMIT_REACHED" "UNSENT_SCHEDULER_CAPACITY_EXCEEDED" "UNSENT_SYSTEM_ERROR" "UNSENT_TIME_LIMIT_REACHED" "UNSENT_TOKEN_LIMIT_REACHED"] }
def big-message-strategy-completer [] { ["DO_NOT_SEND" "MMS" "SEND_MULTIPLE" "TRIM"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    find-calls: "record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>"
    send-calls: "record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>>"
    find-call-broadcasts: "record<items: table<answeringMachineConfig: string, dialplanXml: string, fromNumber: string, id: int, labels: list, lastModified: int, localTimeRestriction: record, maxActive: int, maxActiveTransfers: int, name: string, recipients: list, resumeNextDay: bool, retryConfig: record, schedules: list, sounds: record, status: string>, limit: int, offset: int, totalCount: int>"
    create-call-broadcast: "record<id: int>"
    get-call-broadcast: "record<answeringMachineConfig: string, dialplanXml: string, fromNumber: string, id: int, labels: list<string>, lastModified: int, localTimeRestriction: record<beginHour: int, beginMinute: int, enabled: bool, endHour: int, endMinute: int>, maxActive: int, maxActiveTransfers: int, name: string, recipients: table<attributes: record, contactId: int, fromNumber: string, phoneNumber: string>, resumeNextDay: bool, retryConfig: record<maxAttempts: int, minutesBetweenAttempts: int, retryPhoneTypes: list<string>, retryResults: list<string>>, schedules: table<campaignId: int, daysOfWeek: list, id: int, startDate: record, startTimeOfDay: record, stopDate: record, stopTimeOfDay: record, timeZone: string>, sounds: record<dncDigit: string, dncSoundId: int, dncSoundText: string, dncSoundTextVoice: string, liveSoundId: int, liveSoundText: string, liveSoundTextVoice: string, machineSoundId: int, machineSoundText: string, machineSoundTextVoice: string, transferDigit: string, transferNumber: string, transferSoundId: int, transferSoundText: string, transferSoundTextVoice: string>, status: string>"
    get-call-broadcast-batches: "record<items: table<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>, limit: int, offset: int, totalCount: int>"
    add-call-broadcast-batch: "record<id: int>"
    get-call-broadcast-calls: "record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>"
    add-call-broadcast-recipients: "record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>>"
    get-call-broadcast-stats: "record<answeringMachineCount: int, billedAmount: float, billedDuration: int, busyCount: int, callsAttempted: int, callsAwaitingRedial: int, callsDuration: int, callsLiveAnswer: int, callsPlaced: int, callsRemaining: int, dialedCount: int, doNotCallCount: int, errorCount: int, liveCount: int, miscCount: int, noAnswerCount: int, remainingOutboundCount: int, responseRatePercent: int, totalCount: int, totalOutboundCount: int, transferCount: int>"
    get-call-recording: "record<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string>"
    get-call-recording-mp3: "record"
    get-call: "record<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list<string>, modified: int, notes: table<created: int, text: string>, records: table<answerTime: int, billedAmount: float, callerName: string, duration: int, finishTime: int, id: int, labels: list, notes: list, originateTime: int, questionResponses: list, recordings: list, result: string, switchId: string, toNumber: string>, state: string, toNumber: string>"
    get-call-recordings: "record<items: table<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string>>"
    get-call-recording-by-name: "record<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string>"
    get-call-recording-mp3-by-name: "record"
    get-campaign-batch: "record<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>"
    find-campaign-sounds: "record<items: table<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>, limit: int, offset: int, totalCount: int>"
    post-call-campaign-sound: "record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>"
    post-file-campaign-sound: "record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>"
    post-tts-campaign-sound: "record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>"
    get-campaign-sound: "record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>"
    get-campaign-sound-data-mp3: "record"
    get-campaign-sound-data-wav: "record"
    find-contacts: "record<items: table<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, limit: int, offset: int, totalCount: int>"
    create-contacts: "record<items: table<id: int>>"
    find-do-not-contacts: "record<items: table<call: bool, campaignId: int, created: int, inboundCall: bool, inboundText: bool, number: string, source: string, text: bool>, limit: int, offset: int, totalCount: int>"
    get-universal-do-not-contacts: "record<items: table<fromNumber: string, inboundCall: bool, inboundText: bool, outboundCall: bool, outboundText: bool, toNumber: string>>"
    get-do-not-contact: "record<call: bool, campaignId: int, created: int, inboundCall: bool, inboundText: bool, number: string, source: string, text: bool>"
    find-contact-lists: "record<items: table<created: int, id: int, name: string, size: int, status: string>, limit: int, offset: int, totalCount: int>"
    create-contact-list: "record<created: int, id: int, name: string, size: int, status: string>"
    create-contact-list-from-file: "record<id: int>"
    get-contact-list: "record<created: int, id: int, name: string, size: int, status: string>"
    get-contact-list-items: "record<items: table<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, limit: int, offset: int, totalCount: int>"
    get-contact: "record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>"
    get-contact-history: "record<calls: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, id: int, texts: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>>"
    find-keywords: "record<items: table<keyword: string, number: string, shortCode: string>>"
    find-keyword-leases: "record<items: table<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string>, limit: int, offset: int, totalCount: int>"
    find-keyword-lease-configs: "record<items: list<record>, limit: int, offset: int, totalCount: int>"
    get-keyword-lease-config: "record<keyword: string, textInboundConfig: record<forwardEnabled: bool, forwardNumber: string>>"
    get-keyword-lease-by-id: "record<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list<string>, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string>"
    get-keyword-lease: "record<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list<string>, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string>"
    is-keyword-available: "bool"
    get-account: "record<active: bool, address: string, age: record<millis: int, standardDays: int, standardHours: int, standardMinutes: int, standardSeconds: int>, agencyManagedAccounts: bool, allowedToCreateCampaign: bool, apiCallLimit: int, archived: bool, autoAddDoNotContact: bool, brand: string, canceled: bool, canceledOrArchived: bool, city: string, companyName: string, country: string, countryOrDefault: string, created: string, dateTimeZone: record<fixed: bool, id: string>, defaultNotificationTtlMillis: int, defaultNumberId: int, ein: string, entityType: string, ez: bool, failedVerificationAttempts: int, fromNumberPool: string, id: int, industry: string, industryName: string, key: string, localTimeZoneRestriction: record<enabled: bool, startTime: string, stopTime: string>, locale: record<country: string, displayCountry: string, displayLanguage: string, displayName: string, displayScript: string, displayVariant: string, extensionKeys: list<string>, iso3Country: string, iso3Language: string, language: string, script: string, unicodeLocaleAttributes: list<string>, unicodeLocaleKeys: list<string>, variant: string>, maxAgents: int, messageClass: string, messageFlows: list<string>, name: string, outboundThreshold: int, receiverPeriodCall: int, receiverPeriodEnabled: bool, receiverPeriodGlobal: int, receiverPeriodText: int, receiverPeriodTimeUnit: string, retainOnlyMetadata: bool, retainOnlyMetadataLastDetailRecordId: int, retainOnlyMetadataLastModified: string, scrub: bool, sharedShortCodeAllowed: bool, sharedShortCodeId: int, soaAccount: any, startCapable: bool, state: string, status: string, textOutboundThreshold: int, timeZone: record<displayName: string, dstsavings: int, id: string, rawOffset: int>, timeZoneId: record<id: string, rules: record<fixedOffset: bool, transitionRules: list, transitions: list>>, trustLevel: string, tsrAgreement: string, tsrInitials: string, uiContext: string, universal: bool, website: string, zipcode: string>"
    find-api-credentials: "record<items: table<enabled: bool, id: int, name: string, password: string, username: string>, limit: int, offset: int, totalCount: int>"
    create-api-credential: "record<enabled: bool, id: int, name: string, password: string, username: string>"
    get-api-credential: "record<enabled: bool, id: int, name: string, password: string, username: string>"
    get-credit-usage: "record<callsDurationMinutes: int, creditsUsed: float, intervalBegin: int, intervalEnd: int, textsSent: int>"
    get-billing-plan-usage: "record<intervalEnd: int, intervalStart: int, remainingPayAsYouGoCredits: float, remainingPlanCredits: float, totalRemainingCredits: float>"
    get-caller-ids: "record<items: table<phoneNumber: string>>"
    verify-caller-id: "bool"
    find-media: "record<items: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, limit: int, offset: int, totalCount: int>"
    create-media: "record<id: int>"
    get-media-data-by-key: "record"
    get-media: "record<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>"
    get-media-data: "record"
    get-media-data-binary: "record"
    find-number-leases: "record<items: table<autoRenew: bool, callFeatureStatus: string, labels: list, leaseBegin: int, leaseEnd: int, nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, status: string, textFeatureStatus: string, tollFree: bool, type: string>, limit: int, offset: int, totalCount: int>"
    find-number-lease-configs: "record<items: table<callTrackingConfig: record, configType: string, ivrInboundConfig: record, number: string, textInboundConfig: record>, limit: int, offset: int, totalCount: int>"
    get-number-lease-config: "record<callTrackingConfig: record<failedTransferSoundId: int, googleAnalytics: record<category: string, domain: string, googleAccountId: string>, introSoundId: int, recorded: bool, screen: bool, transferNumbers: list<string>, voicemail: bool, voicemailSoundId: int, weeklySchedule: record<daysOfWeek: list, startTimeOfDay: record, stopTimeOfDay: record, timeZone: string>, whisperSoundId: int>, configType: string, ivrInboundConfig: record<dialplanXml: string>, number: string, textInboundConfig: record<forwardEnabled: bool, forwardNumber: string>>"
    get-number-lease: "record<autoRenew: bool, callFeatureStatus: string, labels: list<string>, leaseBegin: int, leaseEnd: int, nationalFormat: string, number: string, region: record<city: string, country: string, latitude: float, longitude: float, prefix: string, state: string, timeZone: string, zipcode: string>, sendEmailOnCreate: bool, status: string, textFeatureStatus: string, tollFree: bool, type: string>"
    find-numbers-local: "record<items: table<nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, tollFree: bool>>"
    find-number-regions: "record<items: table<city: string, country: string, latitude: float, longitude: float, prefix: string, state: string, timeZone: string, zipcode: string>, limit: int, offset: int, totalCount: int>"
    find-numbers-tollfree: "record<items: table<nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, tollFree: bool>>"
    find-orders: "record<items: table<created: int, id: int, keywords: record, localNumbers: record, salesTax: float, status: string, summary: float, tollFreeNumbers: record, total: float, totalCost: float>, limit: int, offset: int, totalCount: int>"
    order-keywords: "record<id: int>"
    order-numbers: "record<id: int>"
    get-order: "record<created: int, id: int, keywords: record<fulfilled: list<string>, ordered: int, unitCost: float>, localNumbers: record<fulfilled: list<string>, ordered: int, unitCost: float>, salesTax: float, status: string, summary: float, tollFreeNumbers: record<fulfilled: list<string>, ordered: int, unitCost: float>, total: float, totalCost: float>"
    get-delivery-reports: "record<items: table<campaignId: int, carrier: string, deliveryCategory: string, deliveryState: string, fromNumber: string, messageText: string, toNumber: string, updated: string>, limit: int, offset: int, totalCount: int>"
    find-texts: "record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>"
    send-texts: "record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>>"
    find-text-auto-replys: "record<items: table<id: int, keyword: string, match: string, message: string, number: string>, limit: int, offset: int, totalCount: int>"
    create-text-auto-reply: "record<id: int>"
    get-text-auto-reply: "record<id: int, keyword: string, match: string, message: string, number: string>"
    find-text-broadcasts: "record<items: table<bigMessageStrategy: string, fromNumber: string, id: int, labels: list, lastModified: int, localTimeRestriction: record, maxActive: int, media: list, message: string, name: string, recipients: list, resumeNextDay: bool, schedules: list, status: string>, limit: int, offset: int, totalCount: int>"
    create-text-broadcast: "record<id: int>"
    get-text-broadcast: "record<bigMessageStrategy: string, fromNumber: string, id: int, labels: list<string>, lastModified: int, localTimeRestriction: record<beginHour: int, beginMinute: int, enabled: bool, endHour: int, endMinute: int>, maxActive: int, media: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, message: string, name: string, recipients: table<attributes: record, contactId: int, fromNumber: string, media: list, message: string, phoneNumber: string>, resumeNextDay: bool, schedules: table<campaignId: int, daysOfWeek: list, id: int, startDate: record, startTimeOfDay: record, stopDate: record, stopTimeOfDay: record, timeZone: string>, status: string>"
    update-text-broadcast: "record<id: int>"
    get-text-broadcast-batches: "record<items: table<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>, limit: int, offset: int, totalCount: int>"
    add-text-broadcast-batch: "record<id: int>"
    add-text-broadcast-recipients: "record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>>"
    get-text-broadcast-stats: "record<billedAmount: float, doNotTextCount: int, errorCount: int, recievedCount: int, remainingOutboundCount: int, sentCount: int, tooBigCount: int, totalOutboundCount: int, unsentCount: int>"
    get-text-broadcast-texts: "record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>"
    get-text: "record<attributes: record, batchId: int, campaignId: int, contact: record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list<string>, media: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, message: string, modified: int, records: table<billedAmount: float, callerName: string, finishTime: int, id: int, labels: list, message: string, switchId: string, textResult: string, toNumber: string>, state: string, toNumber: string>"
    find-webhooks: "record<items: table<callback: string, createdAt: int, enabled: bool, events: list, expiresAt: int, fields: string, id: int, name: string, nonStrictSsl: bool, resource: string, secret: string, singleUse: bool, updatedAt: int>, limit: int, offset: int, totalCount: int>"
    create-webhook: "record<id: int>"
    find-webhook-resources: "record<items: table<resource: string, supportedEvents: list>>"
    get-webhook-resource: "record<resource: string, supportedEvents: list<string>>"
    get-webhook: "record<callback: string, createdAt: int, enabled: bool, events: list<string>, expiresAt: int, fields: string, id: int, name: string, nonStrictSsl: bool, resource: string, secret: string, singleUse: bool, updatedAt: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["find-calls" "send-calls" "find-call-broadcasts" "create-call-broadcast" "get-call-broadcast" "update-call-broadcast" "archive-voice-broadcast" "get-call-broadcast-batches" "add-call-broadcast-batch" "get-call-broadcast-calls" "add-call-broadcast-recipients" "start-voice-broadcast" "get-call-broadcast-stats" "stop-voice-broadcast" "toggle-call-broadcast-recipients-status" "get-call-recording" "get-call-recording-mp3" "get-call" "get-call-recordings" "get-call-recording-by-name" "get-call-recording-mp3-by-name" "get-campaign-batch" "update-campaign-batch" "find-campaign-sounds" "post-call-campaign-sound" "post-file-campaign-sound" "post-tts-campaign-sound" "delete-campaign-sound" "get-campaign-sound" "get-campaign-sound-data-mp3" "get-campaign-sound-data-wav" "find-contacts" "create-contacts" "find-do-not-contacts" "add-do-not-contacts" "delete-do-not-contacts-by-source" "get-universal-do-not-contacts" "delete-do-not-contact" "get-do-not-contact" "update-do-not-contact" "find-contact-lists" "create-contact-list" "create-contact-list-from-file" "delete-contact-list" "get-contact-list" "update-contact-list" "remove-contact-list-items" "get-contact-list-items" "add-contact-list-items" "remove-contact-list-item" "delete-contact" "get-contact" "update-contact" "get-contact-history" "find-keywords" "find-keyword-leases" "find-keyword-lease-configs" "get-keyword-lease-config" "update-keyword-lease-config" "get-keyword-lease-by-id" "get-keyword-lease" "update-keyword-lease" "is-keyword-available" "get-account" "find-api-credentials" "create-api-credential" "delete-api-credential" "get-api-credential" "disable-api-credentials" "enable-api-credentials" "get-credit-usage" "get-billing-plan-usage" "get-caller-ids" "send-verification-code-to-caller-id" "verify-caller-id" "find-media" "create-media" "get-media-data-by-key" "get-media" "get-media-data" "get-media-data-binary" "find-number-leases" "find-number-lease-configs" "get-number-lease-config" "update-number-lease-config" "get-number-lease" "update-number-lease" "find-numbers-local" "find-number-regions" "find-numbers-tollfree" "find-orders" "order-keywords" "order-numbers" "get-order" "get-delivery-reports" "find-texts" "send-texts" "find-text-auto-replys" "create-text-auto-reply" "delete-text-auto-reply" "get-text-auto-reply" "find-text-broadcasts" "create-text-broadcast" "get-text-broadcast" "update-text-broadcast" "archive-text-broadcast" "get-text-broadcast-batches" "add-text-broadcast-batch" "add-text-broadcast-recipients" "start-text-broadcast" "get-text-broadcast-stats" "stop-text-broadcast" "get-text-broadcast-texts" "toggle-text-broadcast-recipients-status" "get-text" "find-webhooks" "create-webhook" "find-webhook-resources" "get-webhook-resource" "delete-webhook" "get-webhook" "update-webhook" "commands"] | sort) } | get name | first)
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

# Find calls
#
# GET /calls
# Returns: record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>
# operationId: findCalls
export def "find-calls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --id: list<int> # Lists the Call ids to search for. If calls ids are specified then other query parameters can be ignored
  --campaign-id: int # An id of a campaign, queries for calls included to a particular campaign. Specify null for all campaigns and 0 for default campaign (format: int64)
  --batch-id: int # An id of a contact batch, queries for calls of a particular contact batch (format: int64)
  --from-number: string # Phone number in E.164 format (11-digit) that call was from. Example: 12132000384
  --to-number: string # Phone number in E.164 format (11-digit) that call was sent to. Example: 12132000384
  --label: string # A label for a specific call
  --states: string # Searches for all calls which correspond to statuses listed in a comma separated string. Available values: READY, SELECTED, CALLBACK, FINISHED, DISABLED, DNC, DUP, INVALID, TIMEOUT, PERIOD_LIMIT. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --results: string # Searches for all calls with statuses listed in a comma separated string. Available values: SENT, RECEIVED, DNT, TOO_BIG, INTERNAL_ERROR, CARRIER_ERROR, CARRIER_TEMP_ERROR, UNDIALED. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --inbound: oneof<nothing, bool> # Filters inbound calls for "true" value and outbound calls for "false" value
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls"
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: id, var: id, style: multi}, {name: campaignId, var: campaign_id}, {name: batchId, var: batch_id}, {name: fromNumber, var: from_number}, {name: toNumber, var: to_number}, {name: label, var: label}, {name: states, var: states}, {name: results, var: results}, {name: inbound, var: inbound}, {name: intervalBegin, var: interval_begin}, {name: intervalEnd, var: interval_end}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, limit: $limit, offset: $offset, id: $id, campaign_id: $campaign_id, batch_id: $batch_id, from_number: $from_number, to_number: $to_number, label: $label, states: $states, results: $results, inbound: $inbound, interval_begin: $interval_begin, interval_end: $interval_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send calls
#
# POST /calls
# Returns: record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>>
# operationId: sendCalls
export def "send-calls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --campaign-id: int # Specifies a campaignId to send calls quickly on a previously created campaign (format: int64)
  --default-live-message: string # Text to be turned into a sound, this text will be played when the phone is answered. Parameter can be overridden for any particular CallRecipient
  --default-machine-message: string # Text to be turned into a sound, this text will be played when answering machine is detected. Parameter can be overridden for any particular CallRecipient
  --default-live-message-sound-id: int # Id of sound file to play if phone is answered. Parameter can be overridden for any particular CallRecipient (format: int64)
  --default-machine-message-sound-id: int # An id of a sound file to play if answering machine is detected. Parameter can be overridden for any particular CallRecipient (format: int64)
  --default-voice: string@default-voice-completer # The voice set by default for all text-to-speech messages defined in CallRecipient objects or as default *Message properties
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls"
    query: [{name: fields, var: fields}, {name: campaignId, var: campaign_id}, {name: defaultLiveMessage, var: default_live_message}, {name: defaultMachineMessage, var: default_machine_message}, {name: defaultLiveMessageSoundId, var: default_live_message_sound_id}, {name: defaultMachineMessageSoundId, var: default_machine_message_sound_id}, {name: defaultVoice, var: default_voice}, {name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, campaign_id: $campaign_id, default_live_message: $default_live_message, default_machine_message: $default_machine_message, default_live_message_sound_id: $default_live_message_sound_id, default_machine_message_sound_id: $default_machine_message_sound_id, default_voice: $default_voice, strict_validation: $strict_validation, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find call broadcasts
#
# GET /calls/broadcasts
# Returns: record<items: table<answeringMachineConfig: string, dialplanXml: string, fromNumber: string, id: int, labels: list, lastModified: int, localTimeRestriction: record, maxActive: int, maxActiveTransfers: int, name: string, recipients: list, resumeNextDay: bool, retryConfig: record, schedules: list, sounds: record, status: string>, limit: int, offset: int, totalCount: int>
# operationId: findCallBroadcasts
export def "find-call-broadcasts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 10)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --label: string # A label of a voice broadcast
  --name: string # A name of voice broadcast
  --running: oneof<nothing, bool> # Specify whether the campaigns should be running or not
  --scheduled: oneof<nothing, bool> # Specify whether the campaigns should be scheduled or not
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/broadcasts"
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: label, var: label}, {name: name, var: name}, {name: running, var: running}, {name: scheduled, var: scheduled}, {name: intervalBegin, var: interval_begin}, {name: intervalEnd, var: interval_end}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, limit: $limit, offset: $offset, label: $label, name: $name, running: $running, scheduled: $scheduled, interval_begin: $interval_begin, interval_end: $interval_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a call broadcast
#
# POST /calls/broadcasts
# Returns: record<id: int>
# operationId: createCallBroadcast
export def "create-call-broadcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: oneof<nothing, bool> # Specify whether to immediately start this campaign (not required)
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --answering-machine-config: string@answering-machine-config-completer # Specifies which action should be taken if answering machine was detected, default value: AM_AND_LIVE. Available values: AM_ONLY - run AMD (Answering Machine Detection), hang up if LA (Live Answer); AM_AND_LIVE - run AMD, play separate live vs. machine sound; LIVE_WITH_AMD, run AMD, hang up if machine answers; LIVE_IMMEDIATE - no AMD, play live sound immediately
  --dialplan-xml: string # IVR xml is a document which describes the dialplan to setup the IVR broadcast
  --from-number: string # Phone number in E.164 format (11-digit) or short code for text. Example: 12132000384, 67076
  --id: int # A unique id of broadcast (readonly) (format: int64)
  --labels: list<string> # Labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # Sets a maximum number of calls to be dialed by CallFire at once (format: int32)
  --max-active-transfers: int # A maximum number of active transfers (format: int32)
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a call broadcast, can be either existing contacts or a new ones — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # If true resumes the unfinished campaign to the next day
  --retry-config: record # Retry configuration will help you to resend a call or text if it was not delivered first time — shape: {maxAttempts?: int, minutesBetweenAttempts?: int, retryPhoneTypes?: list<string>, retryResults?: list<string>}
  --schedules: list # A list of schedule objects which specifies a range of time when broadcast should be started and stopped. Supports the scheduling per day of week — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
  --sounds: record # A set of sounds assigned to a voice broadcast to play according to an answering machine configuration. You can add the existing sounds from the account's sound library or to provide a text which will be converted into a speech. There are four sound options available for a Voice Broadcast campaign — shape: {dncDigit?: string, dncSoundId?: int, dncSoundText?: string, dncSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", liveSoundId?: int, liveSoundText?: string, liveSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", machineSoundId?: int, machineSoundText?: string, machineSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", transferDigit?: string, transferNumber?: string, transferSoundId?: int, transferSoundText?: string, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/broadcasts"
    query: [{name: start, var: start}, {name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: answeringMachineConfig, var: answering_machine_config}, {name: dialplanXml, var: dialplan_xml}, {name: fromNumber, var: from_number}, {name: id, var: id}, {name: labels, var: labels}, {name: localTimeRestriction, var: local_time_restriction}, {name: maxActive, var: max_active}, {name: maxActiveTransfers, var: max_active_transfers}, {name: name, var: name}, {name: recipients, var: recipients}, {name: resumeNextDay, var: resume_next_day}, {name: retryConfig, var: retry_config}, {name: schedules, var: schedules}, {name: sounds, var: sounds}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    start: $start, strict_validation: $strict_validation, answering_machine_config: $answering_machine_config, dialplan_xml: $dialplan_xml, from_number: $from_number, id: $id, labels: $labels, local_time_restriction: $local_time_restriction, max_active: $max_active, max_active_transfers: $max_active_transfers, name: $name, recipients: $recipients, resume_next_day: $resume_next_day, retry_config: $retry_config, schedules: $schedules, sounds: $sounds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific call broadcast
#
# GET /calls/broadcasts/{id}
# Returns: record<answeringMachineConfig: string, dialplanXml: string, fromNumber: string, id: int, labels: list<string>, lastModified: int, localTimeRestriction: record<beginHour: int, beginMinute: int, enabled: bool, endHour: int, endMinute: int>, maxActive: int, maxActiveTransfers: int, name: string, recipients: table<attributes: record, contactId: int, fromNumber: string, phoneNumber: string>, resumeNextDay: bool, retryConfig: record<maxAttempts: int, minutesBetweenAttempts: int, retryPhoneTypes: list<string>, retryResults: list<string>>, schedules: table<campaignId: int, daysOfWeek: list, id: int, startDate: record, startTimeOfDay: record, stopDate: record, stopTimeOfDay: record, timeZone: string>, sounds: record<dncDigit: string, dncSoundId: int, dncSoundText: string, dncSoundTextVoice: string, liveSoundId: int, liveSoundText: string, liveSoundTextVoice: string, machineSoundId: int, machineSoundText: string, machineSoundTextVoice: string, transferDigit: string, transferNumber: string, transferSoundId: int, transferSoundText: string, transferSoundTextVoice: string>, status: string>
# operationId: getCallBroadcast
export def "get-call-broadcast" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/broadcasts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a call broadcast
#
# PUT /calls/broadcasts/{id}
# operationId: updateCallBroadcast
export def "update-call-broadcast" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --answering-machine-config: string@answering-machine-config-completer # Specifies which action should be taken if answering machine was detected, default value: AM_AND_LIVE. Available values: AM_ONLY - run AMD (Answering Machine Detection), hang up if LA (Live Answer); AM_AND_LIVE - run AMD, play separate live vs. machine sound; LIVE_WITH_AMD, run AMD, hang up if machine answers; LIVE_IMMEDIATE - no AMD, play live sound immediately
  --dialplan-xml: string # IVR xml is a document which describes the dialplan to setup the IVR broadcast
  --from-number: string # Phone number in E.164 format (11-digit) or short code for text. Example: 12132000384, 67076
  --body-id: int # A unique id of broadcast (readonly) (format: int64) (spec name: id)
  --labels: list<string> # Labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # Sets a maximum number of calls to be dialed by CallFire at once (format: int32)
  --max-active-transfers: int # A maximum number of active transfers (format: int32)
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a call broadcast, can be either existing contacts or a new ones — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # If true resumes the unfinished campaign to the next day
  --retry-config: record # Retry configuration will help you to resend a call or text if it was not delivered first time — shape: {maxAttempts?: int, minutesBetweenAttempts?: int, retryPhoneTypes?: list<string>, retryResults?: list<string>}
  --schedules: list # A list of schedule objects which specifies a range of time when broadcast should be started and stopped. Supports the scheduling per day of week — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
  --sounds: record # A set of sounds assigned to a voice broadcast to play according to an answering machine configuration. You can add the existing sounds from the account's sound library or to provide a text which will be converted into a speech. There are four sound options available for a Voice Broadcast campaign — shape: {dncDigit?: string, dncSoundId?: int, dncSoundText?: string, dncSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", liveSoundId?: int, liveSoundText?: string, liveSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", machineSoundId?: int, machineSoundText?: string, machineSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", transferDigit?: string, transferNumber?: string, transferSoundId?: int, transferSoundText?: string, ... (1 more fields)}
]: any -> any {
  $in | http-request {
    method: put
    path: "/calls/broadcasts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: answeringMachineConfig, var: answering_machine_config}, {name: dialplanXml, var: dialplan_xml}, {name: fromNumber, var: from_number}, {name: id, var: body_id}, {name: labels, var: labels}, {name: localTimeRestriction, var: local_time_restriction}, {name: maxActive, var: max_active}, {name: maxActiveTransfers, var: max_active_transfers}, {name: name, var: name}, {name: recipients, var: recipients}, {name: resumeNextDay, var: resume_next_day}, {name: retryConfig, var: retry_config}, {name: schedules, var: schedules}, {name: sounds, var: sounds}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, strict_validation: $strict_validation, answering_machine_config: $answering_machine_config, dialplan_xml: $dialplan_xml, from_number: $from_number, body_id: $body_id, labels: $labels, local_time_restriction: $local_time_restriction, max_active: $max_active, max_active_transfers: $max_active_transfers, name: $name, recipients: $recipients, resume_next_day: $resume_next_day, retry_config: $retry_config, schedules: $schedules, sounds: $sounds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive voice broadcast
#
# POST /calls/broadcasts/{id}/archive
# operationId: archiveVoiceBroadcast
export def "archive-voice-broadcast" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/calls/broadcasts/{id}/archive"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find batches in a call broadcast
#
# GET /calls/broadcasts/{id}/batches
# Returns: record<items: table<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>, limit: int, offset: int, totalCount: int>
# operationId: getCallBroadcastBatches
export def "get-call-broadcast-batches" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/broadcasts/{id}/batches"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add batches to a call broadcast
#
# POST /calls/broadcasts/{id}/batches
# Returns: record<id: int>
# operationId: addCallBroadcastBatch
export def "add-call-broadcast-batch" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --contact-list-id: int # An id of existing contact list (format: int64)
  --name: string # A name of batch
  --recipients: list # A list of Recipient objects. For each recipient you can set its phone number or existing contact id to use contact which already exists in account — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --scrub-duplicates: oneof<nothing, bool> # Removes duplicate recipients from batch if true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/broadcasts/{id}/batches"
    path_params: [{name: id, var: id}]
    query: [{name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactListId, var: contact_list_id}, {name: name, var: name}, {name: recipients, var: recipients}, {name: scrubDuplicates, var: scrub_duplicates}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    id: $id, strict_validation: $strict_validation, contact_list_id: $contact_list_id, name: $name, recipients: $recipients, scrub_duplicates: $scrub_duplicates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find calls in a call broadcast
#
# GET /calls/broadcasts/{id}/calls
# Returns: record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>
# operationId: getCallBroadcastCalls
export def "get-call-broadcast-calls" [
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
  --batch-id: int # An id of a particular batch associated with broadcast (format: int64)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/broadcasts/{id}/calls"
    path_params: [{name: id, var: id}]
    query: [{name: batchId, var: batch_id}, {name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, batch_id: $batch_id, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add recipients to a call broadcast
#
# POST /calls/broadcasts/{id}/recipients
# Returns: record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>>
# operationId: addCallBroadcastRecipients
export def "add-call-broadcast-recipients" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calls/broadcasts/{id}/recipients"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields, strict_validation: $strict_validation, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start voice broadcast
#
# POST /calls/broadcasts/{id}/start
# operationId: startVoiceBroadcast
export def "start-voice-broadcast" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/calls/broadcasts/{id}/start"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get statistics on call broadcast
#
# GET /calls/broadcasts/{id}/stats
# Returns: record<answeringMachineCount: int, billedAmount: float, billedDuration: int, busyCount: int, callsAttempted: int, callsAwaitingRedial: int, callsDuration: int, callsLiveAnswer: int, callsPlaced: int, callsRemaining: int, dialedCount: int, doNotCallCount: int, errorCount: int, liveCount: int, miscCount: int, noAnswerCount: int, remainingOutboundCount: int, responseRatePercent: int, totalCount: int, totalOutboundCount: int, transferCount: int>
# operationId: getCallBroadcastStats
export def "get-call-broadcast-stats" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --begin: int # Start of the search time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --end: int # End of the search time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/broadcasts/{id}/stats"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: begin, var: begin}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields, begin: $begin, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop voice broadcast
#
# POST /calls/broadcasts/{id}/stop
# operationId: stopVoiceBroadcast
export def "stop-voice-broadcast" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/calls/broadcasts/{id}/stop"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable/enable undialed recipients in broadcast
#
# POST /calls/broadcasts/{id}/toggleRecipientsStatus
# operationId: toggleCallBroadcastRecipientsStatus
export def "toggle-call-broadcast-recipients-status" [
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
  --enable: oneof<nothing, bool> # Flag which indicate what to do with calls (true will enable call in DISABLED status and vice versa) (default: false)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/calls/broadcasts/{id}/toggleRecipientsStatus"
    path_params: [{name: id, var: id}]
    query: [{name: enable, var: enable}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, enable: $enable, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get call recording by id
#
# GET /calls/recordings/{id}
# Returns: record<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string>
# operationId: getCallRecording
export def "get-call-recording" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/recordings/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get call recording in mp3 format
#
# GET /calls/recordings/{id}.mp3
# Returns: record
# operationId: getCallRecordingMp3
export def "get-call-recording-mp3" [
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
    path: "/calls/recordings/{id}.mp3"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific call
#
# GET /calls/{id}
# Returns: record<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list<string>, modified: int, notes: table<created: int, text: string>, records: table<answerTime: int, billedAmount: float, callerName: string, duration: int, finishTime: int, id: int, labels: list, notes: list, originateTime: int, questionResponses: list, recordings: list, result: string, switchId: string, toNumber: string>, state: string, toNumber: string>
# operationId: getCall
export def "get-call" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get call recordings for a call
#
# GET /calls/{id}/recordings
# Returns: record<items: table<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string>>
# operationId: getCallRecordings
export def "get-call-recordings" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/{id}/recordings"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get call recording by name
#
# GET /calls/{id}/recordings/{name}
# Returns: record<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string>
# operationId: getCallRecordingByName
export def "get-call-recording-by-name" [
  id: int
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/{id}/recordings/{name}"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, name: $name, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get call mp3 recording by name
#
# GET /calls/{id}/recordings/{name}.mp3
# Returns: record
# operationId: getCallRecordingMp3ByName
export def "get-call-recording-mp3-by-name" [
  id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calls/{id}/recordings/{name}.mp3"
    path_params: [{name: id, var: id}, {name: name, var: name}]
    accept: ["audio/mpeg"]
    ok: [200]
    auth: basic
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific batch
#
# GET /campaigns/batches/{id}
# Returns: record<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>
# operationId: getCampaignBatch
export def "get-campaign-batch" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/campaigns/batches/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a batch
#
# PUT /campaigns/batches/{id}
# operationId: updateCampaignBatch
export def "update-campaign-batch" [
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
  --broadcast-id: int # An id of broadcast which batch belongs to (format: int64)
  --enabled: oneof<nothing, bool> # An enabled batch. If batch is disabled its contacts remain undialed/untexted
  --body-id: int # A id of a batch (format: int64) (spec name: id)
  --name: string # A batch name
  --status: string@status-completer # A status of batch (NEW, VALIDATING, ERRORS, SOURCE_ERROR, ACTIVE). NEW - batch is queued for validation; VALIDATING - batch is currently validating; ERRORS - batch is processed, some validation errors occurred; SOURCE_ERROR - if contact source is contact list in CallFire system and it has an error; ACTIVE - batch is processed and ready
]: any -> any {
  $in | http-request {
    method: put
    path: "/campaigns/batches/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: broadcastId, var: broadcast_id}, {name: enabled, var: enabled}, {name: id, var: body_id}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, broadcast_id: $broadcast_id, enabled: $enabled, body_id: $body_id, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find sounds
#
# GET /campaigns/sounds
# Returns: record<items: table<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>, limit: int, offset: int, totalCount: int>
# operationId: findCampaignSounds
export def "find-campaign-sounds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # value to filter file names again; this value is used to check if the filename contains the filter value.
  --include-archived: oneof<nothing, bool> # Includes ARCHIVED sounds for "true" value
  --include-pending: oneof<nothing, bool> # Includes UPLOAD/RECORDING sounds for "true" value
  --include-scrubbed: oneof<nothing, bool> # Includes SCRUBBED sounds for "true" value
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/campaigns/sounds"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: includeArchived, var: include_archived}, {name: includePending, var: include_pending}, {name: includeScrubbed, var: include_scrubbed}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, filter: $filter, include_archived: $include_archived, include_pending: $include_pending, include_scrubbed: $include_scrubbed, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add sound via call
#
# POST /campaigns/sounds/calls
# Returns: record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>
# operationId: postCallCampaignSound
export def "post-call-campaign-sound" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --name: string # Name of a sound to create
  --to-number: string # Phone number in E.164 11-digit format to call to record a sound. Example: 12132000384
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns/sounds/calls"
    query: [{name: fields, var: fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: toNumber, var: to_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, name: $name, to_number: $to_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add sound via file
#
# POST /campaigns/sounds/files
# Returns: record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>
# operationId: postFileCampaignSound
export def "post-file-campaign-sound" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  file: string # A sound file encoded in binary form (format: binary)
  --name: string # Optional name of a sound file, if the name is empty than it will be taken from a file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns/sounds/files"
    query: [{name: fields, var: fields}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: name, var: name}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, file: $file, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add sound via text-to-speech
#
# POST /campaigns/sounds/tts
# Returns: record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>
# operationId: postTTSCampaignSound
export def "post-tts-campaign-sound" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --message: string # A text to be turned into sound
  --voice: string@voice-completer # A voice to be used. Available values: MALE1, FEMALE1 , FEMALE2, SPANISH1, FRENCHCANADIAN1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns/sounds/tts"
    query: [{name: fields, var: fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: voice, var: voice}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, message: $message, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific sound
#
# DELETE /campaigns/sounds/{id}
# operationId: deleteCampaignSound
export def "delete-campaign-sound" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/campaigns/sounds/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific sound
#
# GET /campaigns/sounds/{id}
# Returns: record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>
# operationId: getCampaignSound
export def "get-campaign-sound" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/campaigns/sounds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a MP3 sound
#
# GET /campaigns/sounds/{id}.mp3
# Returns: record
# operationId: getCampaignSoundDataMp3
export def "get-campaign-sound-data-mp3" [
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
    path: "/campaigns/sounds/{id}.mp3"
    path_params: [{name: id, var: id}]
    accept: ["audio/mpeg"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a WAV sound
#
# GET /campaigns/sounds/{id}.wav
# Returns: record
# operationId: getCampaignSoundDataWav
export def "get-campaign-sound-data-wav" [
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
    path: "/campaigns/sounds/{id}.wav"
    path_params: [{name: id, var: id}]
    accept: ["audio/wav"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find contacts
#
# GET /contacts
# Returns: record<items: table<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, limit: int, offset: int, totalCount: int>
# operationId: findContacts
export def "find-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --id: list<int> # A list of contact IDs. If the id parameter is included, the other query parameters are ignored.
  --number: list<string> # Multiple contact numbers can be specified. If the number parameter is included, the other query parameters are ignored.
  --contact-list-id: int # Filters contacts by a particular contact list (format: int64)
  --property-name: string # Name of a contact property to search by
  --property-value: string # Value of a contact property to search by
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts"
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: id, var: id, style: multi}, {name: number, var: number, style: multi}, {name: contactListId, var: contact_list_id}, {name: propertyName, var: property_name}, {name: propertyValue, var: property_value}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, limit: $limit, offset: $offset, id: $id, number: $number, contact_list_id: $contact_list_id, property_name: $property_name, property_value: $property_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create contacts
#
# POST /contacts
# Returns: record<items: table<id: int>>
# operationId: createContacts
export def "create-contacts" [
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
    path: "/contacts"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find do not contact (dnc) items
#
# GET /contacts/dncs
# Returns: record<items: table<call: bool, campaignId: int, created: int, inboundCall: bool, inboundText: bool, number: string, source: string, text: bool>, limit: int, offset: int, totalCount: int>
# operationId: findDoNotContacts
export def "find-do-not-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # Prefix (1-10 digits) of phone numbers
  --campaign-id: int # A campaign id which was used to send a message to a DNC number (format: int64)
  --source: string # A DNC source name to search for DNCs
  --call: oneof<nothing, bool> # Show only Do-Not-Call numbers
  --text: oneof<nothing, bool> # Show only Do-Not-Text numbers
  --inbound-call: oneof<nothing, bool> # ~
  --inbound-text: oneof<nothing, bool> # ~
  --number: list<string> # ~
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/dncs"
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: prefix, var: prefix}, {name: campaignId, var: campaign_id}, {name: source, var: source}, {name: call, var: call}, {name: text, var: text}, {name: inboundCall, var: inbound_call}, {name: inboundText, var: inbound_text}, {name: number, var: number, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, limit: $limit, offset: $offset, prefix: $prefix, campaign_id: $campaign_id, source: $source, call: $call, text: $text, inbound_call: $inbound_call, inbound_text: $inbound_text, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add do not contact (dnc) numbers
#
# POST /contacts/dncs
# operationId: addDoNotContacts
export def "add-do-not-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: oneof<nothing, bool> # If set to true add all given numbers to Do-Not-Call list. Default value: true
  --inbound-call: oneof<nothing, bool> # ~
  --inbound-text: oneof<nothing, bool> # ~
  --numbers: list<string> # A list of phone numbers in E.164 format (11-digit), example: 12132000384, 14142777322
  --source: string # A list of new contact objects which need to be added. Default value: Api V2
  --text: oneof<nothing, bool> # If set to true add all given numbers to Do-Not-Text list. Default value: true
]: any -> any {
  $in | http-request {
    method: post
    path: "/contacts/dncs"
    body: {content_type: "application/json", kind: json, fields: [{name: call, var: call}, {name: inboundCall, var: inbound_call}, {name: inboundText, var: inbound_text}, {name: numbers, var: numbers}, {name: source, var: source}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    call: $call, inbound_call: $inbound_call, inbound_text: $inbound_text, numbers: $numbers, source: $source, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete do not contact (dnc) numbers contained in source.
#
# DELETE /contacts/dncs/sources/{source}
# operationId: deleteDoNotContactsBySource
export def "delete-do-not-contacts-by-source" [
  source: string
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
    path: "/contacts/dncs/sources/{source}"
    path_params: [{name: source, var: source}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find universal do not contacts (udnc) associated with toNumber
#
# GET /contacts/dncs/universals/{toNumber}
# Returns: record<items: table<fromNumber: string, inboundCall: bool, inboundText: bool, outboundCall: bool, outboundText: bool, toNumber: string>>
# operationId: getUniversalDoNotContacts
export def "get-universal-do-not-contacts" [
  to_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-number: string # An optional destination/source number for DNC, specified in E.164 format (11-digit). Example: 12132000384
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/dncs/universals/{toNumber}"
    path_params: [{name: toNumber, var: to_number}]
    query: [{name: fromNumber, var: from_number}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    to_number: $to_number, from_number: $from_number, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete do not contact (dnc) number. If number contains commas treat as list of numbers
#
# DELETE /contacts/dncs/{number}
# operationId: deleteDoNotContact
export def "delete-do-not-contact" [
  number: string
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
    path: "/contacts/dncs/{number}"
    path_params: [{name: number, var: number}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get do not contact (dnc)
#
# GET /contacts/dncs/{number}
# Returns: record<call: bool, campaignId: int, created: int, inboundCall: bool, inboundText: bool, number: string, source: string, text: bool>
# operationId: getDoNotContact
export def "get-do-not-contact" [
  number: string
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
    path: "/contacts/dncs/{number}"
    path_params: [{name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an individual do not contact (dnc) number
#
# PUT /contacts/dncs/{number}
# operationId: updateDoNotContact
export def "update-do-not-contact" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: oneof<nothing, bool> # A number on Do-Not-Call list
  --inbound-call: oneof<nothing, bool> # ~
  --inbound-text: oneof<nothing, bool> # ~
  --body-number: string # A single DNC number in E.164 format (11-digit). Example: 12132000384 (spec name: number)
  --source: string # The name of DNC source (can be the name of DNC list that user uploads to CallFire)
  --text: oneof<nothing, bool> # A number on Do-Not-Text list
]: any -> any {
  $in | http-request {
    method: put
    path: "/contacts/dncs/{number}"
    path_params: [{name: number, var: number}]
    body: {content_type: "application/json", kind: json, fields: [{name: call, var: call}, {name: inboundCall, var: inbound_call}, {name: inboundText, var: inbound_text}, {name: number, var: body_number}, {name: source, var: source}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    number: $number, call: $call, inbound_call: $inbound_call, inbound_text: $inbound_text, body_number: $body_number, source: $source, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find contact lists
#
# GET /contacts/lists
# Returns: record<items: table<created: int, id: int, name: string, size: int, status: string>, limit: int, offset: int, totalCount: int>
# operationId: findContactLists
export def "find-contact-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --name: string # A name or a partial name of a contact list
  --exact-match: oneof<nothing, bool> # ~
  --contact-count: int # ~ (format: int32)
  --order-by: string # ~
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/lists"
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}, {name: exactMatch, var: exact_match}, {name: contactCount, var: contact_count}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, limit: $limit, offset: $offset, name: $name, exact_match: $exact_match, contact_count: $contact_count, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create contact lists
#
# POST /contacts/lists
# Returns: record<created: int, id: int, name: string, size: int, status: string>
# operationId: createContactList
export def "create-contact-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --contact-ids: list<int> # A list of ids of existing contacts in CallFire system
  --contact-numbers: list<string> # List of numbers in E.164 format (11-digit). Example: 12132000384
  --contact-numbers-field: string # A type of a phone number (homePhone, workPhone, mobilePhone). This parameter is used with contactNumbers and specifies which types of phone numbers are included to a contact list
  --contacts: list # A list of new contact objects to be added — item shape: {deleted?: bool, externalId?: string, externalSystem?: string, extraPhone1?: string, extraPhone2?: string, extraPhone3?: string, firstName?: string, homePhone?: string, id?: int, lastName?: string, mobilePhone?: string, properties?: record, workPhone?: string, zipcode?: string}
  --name: string # A name of a contact list
  --use-custom-fields: oneof<nothing, bool> # A flag to indicate how to define property names for contacts. If true, uses the field and property names exactly as defined. If false will assign custom properties and fields to A, B, C, etc
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts/lists"
    query: [{name: fields, var: fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactIds, var: contact_ids}, {name: contactNumbers, var: contact_numbers}, {name: contactNumbersField, var: contact_numbers_field}, {name: contacts, var: contacts}, {name: name, var: name}, {name: useCustomFields, var: use_custom_fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, contact_ids: $contact_ids, contact_numbers: $contact_numbers, contact_numbers_field: $contact_numbers_field, contacts: $contacts, name: $name, use_custom_fields: $use_custom_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create contact list from file
#
# POST /contacts/lists/upload
# Returns: record<id: int>
# operationId: createContactListFromFile
export def "create-contact-list-from-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # CSV file to be uploaded (format: binary)
  --name: string # A name of a contact list
  --use-custom-fields: oneof<nothing, bool> # A flag to indicate how to define property names for contacts. If true, uses the field and property names exactly as defined. If false will assign custom properties and fields to A, B, C, etc
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts/lists/upload"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: name, var: name}, {name: useCustomFields, var: use_custom_fields}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    file: $file, name: $name, use_custom_fields: $use_custom_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact list
#
# DELETE /contacts/lists/{id}
# operationId: deleteContactList
export def "delete-contact-list" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/contacts/lists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific contact list
#
# GET /contacts/lists/{id}
# Returns: record<created: int, id: int, name: string, size: int, status: string>
# operationId: getContactList
export def "get-contact-list" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/lists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a contact list
#
# PUT /contacts/lists/{id}
# operationId: updateContactList
export def "update-contact-list" [
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
  --name: string # A name of a contact list
]: any -> any {
  $in | http-request {
    method: put
    path: "/contacts/lists/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete contacts from a contact list
#
# DELETE /contacts/lists/{id}/items
# operationId: removeContactListItems
export def "remove-contact-list-items" [
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
  --contact-id: list<int> # An id of a contact entity in the CallFire system
]: nothing -> any {
  http-request {
    method: delete
    path: "/contacts/lists/{id}/items"
    path_params: [{name: id, var: id}]
    query: [{name: contactId, var: contact_id, style: multi}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find contacts in a contact list
#
# GET /contacts/lists/{id}/items
# Returns: record<items: table<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, limit: int, offset: int, totalCount: int>
# operationId: getContactListItems
export def "get-contact-list-items" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/lists/{id}/items"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add contacts to a contact list
#
# POST /contacts/lists/{id}/items
# operationId: addContactListItems
export def "add-contact-list-items" [
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
  --contact-ids: list<int> # A list of ids of existing contacts in CallFire system
  --contact-numbers: list<string> # A phone number in E.164 format (11-digit). Examples: 12132000384
  --contact-numbers-field: string # A type of phone number (homePhone, workPhone, mobilePhone). This parameter works together with contactNumbers and specifies which types of numbers are included to a list
  --contacts: list # A list of new contact objects which need to be added — item shape: {deleted?: bool, externalId?: string, externalSystem?: string, extraPhone1?: string, extraPhone2?: string, extraPhone3?: string, firstName?: string, homePhone?: string, id?: int, lastName?: string, mobilePhone?: string, properties?: record, workPhone?: string, zipcode?: string}
  --use-custom-fields: oneof<nothing, bool> # A flag to indicate how to define property names for contacts. If true, uses the field and property names exactly as defined. If false will assign custom properties and fields to A, B, C, etc
]: any -> any {
  $in | http-request {
    method: post
    path: "/contacts/lists/{id}/items"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactIds, var: contact_ids}, {name: contactNumbers, var: contact_numbers}, {name: contactNumbersField, var: contact_numbers_field}, {name: contacts, var: contacts}, {name: useCustomFields, var: use_custom_fields}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, contact_ids: $contact_ids, contact_numbers: $contact_numbers, contact_numbers_field: $contact_numbers_field, contacts: $contacts, use_custom_fields: $use_custom_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact from a contact list
#
# DELETE /contacts/lists/{id}/items/{contactId}
# operationId: removeContactListItem
export def "remove-contact-list-item" [
  id: int
  contact_id: int
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
    path: "/contacts/lists/{id}/items/{contactId}"
    path_params: [{name: id, var: id}, {name: contactId, var: contact_id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact
#
# DELETE /contacts/{id}
# operationId: deleteContact
export def "delete-contact" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific contact
#
# GET /contacts/{id}
# Returns: record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>
# operationId: getContact
export def "get-contact" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a contact
#
# PUT /contacts/{id}
# operationId: updateContact
export def "update-contact" [
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
  --deleted: oneof<nothing, bool> # A deleted contact, deleted contacts are hidden from search results
  --external-id: string # An external id of a contact for syncing with external sources
  --external-system: string # External system that external id refers to
  --extra-phone1: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --extra-phone2: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --extra-phone3: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --first-name: string # A first name of a contact
  --home-phone: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --body-id: int # An id of a contact (format: int64) (spec name: id)
  --last-name: string # A last name of a contact
  --mobile-phone: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --properties: record # Map of user-defined string properties for contact
  --work-phone: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --zipcode: string # A Zip code of a contact
]: any -> any {
  $in | http-request {
    method: put
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: deleted, var: deleted}, {name: externalId, var: external_id}, {name: externalSystem, var: external_system}, {name: extraPhone1, var: extra_phone1}, {name: extraPhone2, var: extra_phone2}, {name: extraPhone3, var: extra_phone3}, {name: firstName, var: first_name}, {name: homePhone, var: home_phone}, {name: id, var: body_id}, {name: lastName, var: last_name}, {name: mobilePhone, var: mobile_phone}, {name: properties, var: properties}, {name: workPhone, var: work_phone}, {name: zipcode, var: zipcode}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, deleted: $deleted, external_id: $external_id, external_system: $external_system, extra_phone1: $extra_phone1, extra_phone2: $extra_phone2, extra_phone3: $extra_phone3, first_name: $first_name, home_phone: $home_phone, body_id: $body_id, last_name: $last_name, mobile_phone: $mobile_phone, properties: $properties, work_phone: $work_phone, zipcode: $zipcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a contact's history
#
# GET /contacts/{id}/history
# Returns: record<calls: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, id: int, texts: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>>
# operationId: getContactHistory
export def "get-contact-history" [
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
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/{id}/history"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, limit: $limit, offset: $offset, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find keywords
#
# GET /keywords
# Returns: record<items: table<keyword: string, number: string, shortCode: string>>
# operationId: findKeywords
export def "find-keywords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keywords: list<string> # A keyword to search for
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keywords"
    query: [{name: keywords, var: keywords, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    keywords: $keywords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find keyword leases
#
# GET /keywords/leases
# Returns: record<items: table<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string>, limit: int, offset: int, totalCount: int>
# operationId: findKeywordLeases
export def "find-keyword-leases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # Filter by part of Keyword name or Label name of Keyword
  --label-name: string # An exact label name to search by
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keywords/leases"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: labelName, var: label_name}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, filter: $filter, label_name: $label_name, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find keyword lease configs
#
# GET /keywords/leases/configs
# Returns: record<items: list<record>, limit: int, offset: int, totalCount: int>
# operationId: findKeywordLeaseConfigs
export def "find-keyword-lease-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 20)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # Filter by part of Keyword name or Label name of Keyword
  --label-name: string # An exact label name to search by
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keywords/leases/configs"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: labelName, var: label_name}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, filter: $filter, label_name: $label_name, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific keyword lease config
#
# GET /keywords/leases/configs/{keyword}
# Returns: record<keyword: string, textInboundConfig: record<forwardEnabled: bool, forwardNumber: string>>
# operationId: getKeywordLeaseConfig
export def "get-keyword-lease-config" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keywords/leases/configs/{keyword}"
    path_params: [{name: keyword, var: keyword}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    keyword: $keyword, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a keyword lease config
#
# PUT /keywords/leases/configs/{keyword}
# operationId: updateKeywordLeaseConfig
export def "update-keyword-lease-config" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-keyword: string # ~ (spec name: keyword)
  --text-inbound-config: record # ~ — shape: {forwardEnabled?: bool, forwardNumber?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/keywords/leases/configs/{keyword}"
    path_params: [{name: keyword, var: keyword}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyword, var: body_keyword}, {name: textInboundConfig, var: text_inbound_config}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    keyword: $keyword, body_keyword: $body_keyword, text_inbound_config: $text_inbound_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a keyword by id
#
# GET /keywords/leases/id/{id}
# Returns: record<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list<string>, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string>
# operationId: getKeywordLeaseById
export def "get-keyword-lease-by-id" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keywords/leases/id/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific lease
#
# GET /keywords/leases/{keyword}
# Returns: record<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list<string>, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string>
# operationId: getKeywordLease
export def "get-keyword-lease" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keywords/leases/{keyword}"
    path_params: [{name: keyword, var: keyword}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    keyword: $keyword, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a lease
#
# PUT /keywords/leases/{keyword}
# operationId: updateKeywordLease
export def "update-keyword-lease" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-renew: oneof<nothing, bool> # Enables the auto renewal of a keyword lease at the end of each billing cycle
  --contact-list-id: int # Existing contact list ID (format: int64)
  --double-opt-in-enabled: oneof<nothing, bool> # Enable/disable double opt in feature
  --body-keyword: string # A text used as a keyword (spec name: keyword)
  --labels: list<string> # ~
  --lease-begin: int # A time of a lease timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --lease-end: int # A date and time when the keyword lease is finishes. Timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 (format: int64)
  --number: string # A number assigned to keyword. Example: 12132212344
  --opt-in-confirmation-message: string # Opt in confirmation message
  --short-code: string # A short code assigned to keyword. Example: 67076 (Deprecated - please use number instead)
  --status: string@status-completer-1 # A lease status. Available values: PENDING, ACTIVE, RELEASED, UNAVAILABLE
  --type: string@type-completer # ~
]: any -> any {
  $in | http-request {
    method: put
    path: "/keywords/leases/{keyword}"
    path_params: [{name: keyword, var: keyword}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoRenew, var: auto_renew}, {name: contactListId, var: contact_list_id}, {name: doubleOptInEnabled, var: double_opt_in_enabled}, {name: keyword, var: body_keyword}, {name: labels, var: labels}, {name: leaseBegin, var: lease_begin}, {name: leaseEnd, var: lease_end}, {name: number, var: number}, {name: optInConfirmationMessage, var: opt_in_confirmation_message}, {name: shortCode, var: short_code}, {name: status, var: status}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    keyword: $keyword, auto_renew: $auto_renew, contact_list_id: $contact_list_id, double_opt_in_enabled: $double_opt_in_enabled, body_keyword: $body_keyword, labels: $labels, lease_begin: $lease_begin, lease_end: $lease_end, number: $number, opt_in_confirmation_message: $opt_in_confirmation_message, short_code: $short_code, status: $status, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check for a specific keyword
#
# GET /keywords/{keyword}/available
# Returns: bool
# operationId: isKeywordAvailable
export def "is-keyword-available" [
  keyword: string
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
    path: "/keywords/{keyword}/available"
    path_params: [{name: keyword, var: keyword}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    keyword: $keyword
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find account details
#
# GET /me/account
# Returns: record<active: bool, address: string, age: record<millis: int, standardDays: int, standardHours: int, standardMinutes: int, standardSeconds: int>, agencyManagedAccounts: bool, allowedToCreateCampaign: bool, apiCallLimit: int, archived: bool, autoAddDoNotContact: bool, brand: string, canceled: bool, canceledOrArchived: bool, city: string, companyName: string, country: string, countryOrDefault: string, created: string, dateTimeZone: record<fixed: bool, id: string>, defaultNotificationTtlMillis: int, defaultNumberId: int, ein: string, entityType: string, ez: bool, failedVerificationAttempts: int, fromNumberPool: string, id: int, industry: string, industryName: string, key: string, localTimeZoneRestriction: record<enabled: bool, startTime: string, stopTime: string>, locale: record<country: string, displayCountry: string, displayLanguage: string, displayName: string, displayScript: string, displayVariant: string, extensionKeys: list<string>, iso3Country: string, iso3Language: string, language: string, script: string, unicodeLocaleAttributes: list<string>, unicodeLocaleKeys: list<string>, variant: string>, maxAgents: int, messageClass: string, messageFlows: list<string>, name: string, outboundThreshold: int, receiverPeriodCall: int, receiverPeriodEnabled: bool, receiverPeriodGlobal: int, receiverPeriodText: int, receiverPeriodTimeUnit: string, retainOnlyMetadata: bool, retainOnlyMetadataLastDetailRecordId: int, retainOnlyMetadataLastModified: string, scrub: bool, sharedShortCodeAllowed: bool, sharedShortCodeId: int, soaAccount: any, startCapable: bool, state: string, status: string, textOutboundThreshold: int, timeZone: record<displayName: string, dstsavings: int, id: string, rawOffset: int>, timeZoneId: record<id: string, rules: record<fixedOffset: bool, transitionRules: list, transitions: list>>, trustLevel: string, tsrAgreement: string, tsrInitials: string, uiContext: string, universal: bool, website: string, zipcode: string>
# operationId: getAccount
export def "get-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/account"
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find api credentials
#
# GET /me/api/credentials
# Returns: record<items: table<enabled: bool, id: int, name: string, password: string, username: string>, limit: int, offset: int, totalCount: int>
# operationId: findApiCredentials
export def "find-api-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter by name
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/api/credentials"
    query: [{name: name, var: name}, {name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    name: $name, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create api credentials
#
# POST /me/api/credentials
# Returns: record<enabled: bool, id: int, name: string, password: string, username: string>
# operationId: createApiCredential
export def "create-api-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Is credential enabled
  --id: int # An id of an API credential (format: int64)
  --name: string # A name of an API credential
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me/api/credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    enabled: $enabled, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete api credentials
#
# DELETE /me/api/credentials/{id}
# operationId: deleteApiCredential
export def "delete-api-credential" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/me/api/credentials/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific api credential
#
# GET /me/api/credentials/{id}
# Returns: record<enabled: bool, id: int, name: string, password: string, username: string>
# operationId: getApiCredential
export def "get-api-credential" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/api/credentials/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable specified API credentials
#
# POST /me/api/credentials/{id}/disable
# operationId: disableApiCredentials
export def "disable-api-credentials" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/me/api/credentials/{id}/disable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable specified API credentials
#
# POST /me/api/credentials/{id}/enable
# operationId: enableApiCredentials
export def "enable-api-credentials" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/me/api/credentials/{id}/enable"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find credit usage
#
# GET /me/billing/credit-usage
# Returns: record<callsDurationMinutes: int, creditsUsed: float, intervalBegin: int, intervalEnd: int, textsSent: int>
# operationId: getCreditUsage
export def "get-credit-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval-begin: int # Beginning of usage period formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --interval-end: int # End of usage period formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/billing/credit-usage"
    query: [{name: intervalBegin, var: interval_begin}, {name: intervalEnd, var: interval_end}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    interval_begin: $interval_begin, interval_end: $interval_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find plan usage
#
# GET /me/billing/plan-usage
# Returns: record<intervalEnd: int, intervalStart: int, remainingPayAsYouGoCredits: float, remainingPlanCredits: float, totalRemainingCredits: float>
# operationId: getBillingPlanUsage
export def "get-billing-plan-usage" [
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
    path: "/me/billing/plan-usage"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find caller ids
#
# GET /me/callerids
# Returns: record<items: table<phoneNumber: string>>
# operationId: getCallerIds
export def "get-caller-ids" [
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
    path: "/me/callerids"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a caller id
#
# POST /me/callerids/{callerid}
# operationId: sendVerificationCodeToCallerId
export def "send-verification-code-to-caller-id" [
  callerid: string
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
    path: "/me/callerids/{callerid}"
    path_params: [{name: callerid, var: callerid}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    callerid: $callerid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify a caller id
#
# POST /me/callerids/{callerid}/verification-code
# Returns: bool
# operationId: verifyCallerId
export def "verify-caller-id" [
  callerid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verification-code: string # The code used to verify a caller id number
]: any -> any {
  $in | http-request {
    method: post
    path: "/me/callerids/{callerid}/verification-code"
    path_params: [{name: callerid, var: callerid}]
    body: {content_type: "application/json", kind: json, fields: [{name: verificationCode, var: verification_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    callerid: $callerid, verification_code: $verification_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find media
#
# GET /media
# Returns: record<items: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, limit: int, offset: int, totalCount: int>
# operationId: findMedia
export def "find-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # value to filter file names again; this value is used to check if the filename contains the filter value.
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/media"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, filter: $filter, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create media
#
# POST /media
# Returns: record<id: int>
# operationId: createMedia
export def "create-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Binary media file (format: binary)
  --name: string # A name of a media file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/media"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: name, var: name}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    file: $file, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download media by extension
#
# GET /media/public/{key}.{extension}
# Returns: record
# operationId: getMediaDataByKey
export def "get-media-data-by-key" [
  key: string
  extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/media/public/{key}.{extension}"
    path_params: [{name: key, var: key}, {name: extension, var: extension}]
    accept: ["audio/m4a", "audio/mp3", "audio/wav", "image/gif", "image/jpeg", "image/png", "image/x-bmp", "video/3gpp", "video/mp4"]
    ok: [200]
    auth: basic
  } {
    key: $key, extension: $extension
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific media
#
# GET /media/{id}
# Returns: record<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>
# operationId: getMedia
export def "get-media" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/media/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download media by extension
#
# GET /media/{id}.{extension}
# Returns: record
# operationId: getMediaData
export def "get-media-data" [
  id: int
  extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/media/{id}.{extension}"
    path_params: [{name: id, var: id}, {name: extension, var: extension}]
    accept: ["audio/m4a", "audio/mp3", "audio/wav", "image/gif", "image/jpeg", "image/png", "image/x-bmp", "video/3gpp", "video/mp4"]
    ok: [200]
    auth: basic
  } {
    id: $id, extension: $extension
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Download a MP3 media
#
# GET /media/{id}/file
# Returns: record
# operationId: getMediaDataBinary
export def "get-media-data-binary" [
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
    path: "/media/{id}/file"
    path_params: [{name: id, var: id}]
    accept: ["application/binary"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find leases
#
# GET /numbers/leases
# Returns: record<items: table<autoRenew: bool, callFeatureStatus: string, labels: list, leaseBegin: int, leaseEnd: int, nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, status: string, textFeatureStatus: string, tollFree: bool, type: string>, limit: int, offset: int, totalCount: int>
# operationId: findNumberLeases
export def "find-number-leases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --label-name: string # A label name
  --toll-free: oneof<nothing, bool> # ~
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/numbers/leases"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: prefix, var: prefix}, {name: city, var: city}, {name: state, var: state}, {name: zipcode, var: zipcode}, {name: labelName, var: label_name}, {name: tollFree, var: toll_free}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, prefix: $prefix, city: $city, state: $state, zipcode: $zipcode, label_name: $label_name, toll_free: $toll_free, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find lease configs
#
# GET /numbers/leases/configs
# Returns: record<items: table<callTrackingConfig: record, configType: string, ivrInboundConfig: record, number: string, textInboundConfig: record>, limit: int, offset: int, totalCount: int>
# operationId: findNumberLeaseConfigs
export def "find-number-lease-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --label-name: string # A label name
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/numbers/leases/configs"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: prefix, var: prefix}, {name: city, var: city}, {name: state, var: state}, {name: zipcode, var: zipcode}, {name: labelName, var: label_name}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, prefix: $prefix, city: $city, state: $state, zipcode: $zipcode, label_name: $label_name, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific lease config
#
# GET /numbers/leases/configs/{number}
# Returns: record<callTrackingConfig: record<failedTransferSoundId: int, googleAnalytics: record<category: string, domain: string, googleAccountId: string>, introSoundId: int, recorded: bool, screen: bool, transferNumbers: list<string>, voicemail: bool, voicemailSoundId: int, weeklySchedule: record<daysOfWeek: list, startTimeOfDay: record, stopTimeOfDay: record, timeZone: string>, whisperSoundId: int>, configType: string, ivrInboundConfig: record<dialplanXml: string>, number: string, textInboundConfig: record<forwardEnabled: bool, forwardNumber: string>>
# operationId: getNumberLeaseConfig
export def "get-number-lease-config" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/numbers/leases/configs/{number}"
    path_params: [{name: number, var: number}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    number: $number, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a lease config
#
# PUT /numbers/leases/configs/{number}
# operationId: updateNumberLeaseConfig
export def "update-number-lease-config" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-tracking-config: record # Call tracking configuration allows you track incoming calls, analyze, respond to customers using sms or voice replies. For more information see [call tracking page](https://www.callfire.com/products/call-tracking) — shape: {failedTransferSoundId?: int, googleAnalytics?: record, introSoundId?: int, recorded?: bool, screen?: bool, transferNumbers?: list<string>, voicemail?: bool, voicemailSoundId?: int, weeklySchedule?: record, whisperSoundId?: int}
  --config-type: string@config-type-completer # A type of config. Available values: TRACKING, IVR
  --ivr-inbound-config: record # ~ — shape: {dialplanXml?: string}
  --body-number: string # Phone number in E.164 format (11-digit). Example: 12132000384 (spec name: number)
  --text-inbound-config: record # ~ — shape: {forwardEnabled?: bool, forwardNumber?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/numbers/leases/configs/{number}"
    path_params: [{name: number, var: number}]
    body: {content_type: "application/json", kind: json, fields: [{name: callTrackingConfig, var: call_tracking_config}, {name: configType, var: config_type}, {name: ivrInboundConfig, var: ivr_inbound_config}, {name: number, var: body_number}, {name: textInboundConfig, var: text_inbound_config}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    number: $number, call_tracking_config: $call_tracking_config, config_type: $config_type, ivr_inbound_config: $ivr_inbound_config, body_number: $body_number, text_inbound_config: $text_inbound_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific lease
#
# GET /numbers/leases/{number}
# Returns: record<autoRenew: bool, callFeatureStatus: string, labels: list<string>, leaseBegin: int, leaseEnd: int, nationalFormat: string, number: string, region: record<city: string, country: string, latitude: float, longitude: float, prefix: string, state: string, timeZone: string, zipcode: string>, sendEmailOnCreate: bool, status: string, textFeatureStatus: string, tollFree: bool, type: string>
# operationId: getNumberLease
export def "get-number-lease" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/numbers/leases/{number}"
    path_params: [{name: number, var: number}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    number: $number, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a lease
#
# PUT /numbers/leases/{number}
# operationId: updateNumberLease
export def "update-number-lease" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-renew: oneof<nothing, bool> # Enables the auto renewal of number lease at end of each billing cycle
  --call-feature-status: string@call-feature-status-completer # A status of a call feature. Available values: DISABLED, ENABLED
  --labels: list<string> # ~
  --lease-begin: int # A date and time of a lease start. Timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 (format: int64)
  --lease-end: int # A data and time of a lease finish. Timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 (format: int64)
  --national-format: string # Formatted number with a country code
  --body-number: string # A phone number in E.164 format (11-digit). Example: 12132000384 (spec name: number)
  --region: record # Every local number associated with a region. You can query regions to use them in subsequent purchase requests — shape: {city?: string, country?: string, latitude?: float, longitude?: float, prefix?: string, state?: string, timeZone?: string, zipcode?: string}
  --send-email-on-create: oneof<nothing, bool> # ~
  --text-feature-status: string@text-feature-status-completer # A status of a text feature. Available values: DISABLED, ENABLED
  --toll-free: oneof<nothing, bool> # A toll-free number
  --type: string@type-completer # ~
]: any -> any {
  $in | http-request {
    method: put
    path: "/numbers/leases/{number}"
    path_params: [{name: number, var: number}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoRenew, var: auto_renew}, {name: callFeatureStatus, var: call_feature_status}, {name: labels, var: labels}, {name: leaseBegin, var: lease_begin}, {name: leaseEnd, var: lease_end}, {name: nationalFormat, var: national_format}, {name: number, var: body_number}, {name: region, var: region}, {name: sendEmailOnCreate, var: send_email_on_create}, {name: textFeatureStatus, var: text_feature_status}, {name: tollFree, var: toll_free}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    number: $number, auto_renew: $auto_renew, call_feature_status: $call_feature_status, labels: $labels, lease_begin: $lease_begin, lease_end: $lease_end, national_format: $national_format, body_number: $body_number, region: $region, send_email_on_create: $send_email_on_create, text_feature_status: $text_feature_status, toll_free: $toll_free, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find local numbers
#
# GET /numbers/local
# Returns: record<items: table<nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, tollFree: bool>>
# operationId: findNumbersLocal
export def "find-numbers-local" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/numbers/local"
    query: [{name: limit, var: limit}, {name: prefix, var: prefix}, {name: city, var: city}, {name: state, var: state}, {name: zipcode, var: zipcode}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, prefix: $prefix, city: $city, state: $state, zipcode: $zipcode, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find number regions
#
# GET /numbers/regions
# Returns: record<items: table<city: string, country: string, latitude: float, longitude: float, prefix: string, state: string, timeZone: string, zipcode: string>, limit: int, offset: int, totalCount: int>
# operationId: findNumberRegions
export def "find-number-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --city-prefix: string # ~
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --country: string # ~
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/numbers/regions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: prefix, var: prefix}, {name: city, var: city}, {name: cityPrefix, var: city_prefix}, {name: state, var: state}, {name: zipcode, var: zipcode}, {name: country, var: country}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, prefix: $prefix, city: $city, city_prefix: $city_prefix, state: $state, zipcode: $zipcode, country: $country, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find tollfree numbers
#
# GET /numbers/tollfree
# Returns: record<items: table<nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, tollFree: bool>>
# operationId: findNumbersTollfree
export def "find-numbers-tollfree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pattern: string # Filter toll free numbers by prefix, pattern must be 3 char long and should end with '*'. Examples: 8**, 85*, 87* (but 855 will fail because pattern must end with '*').
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/numbers/tollfree"
    query: [{name: pattern, var: pattern}, {name: limit, var: limit}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pattern: $pattern, limit: $limit, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find orders
#
# GET /orders
# Returns: record<items: table<created: int, id: int, keywords: record, localNumbers: record, salesTax: float, status: string, summary: float, tollFreeNumbers: record, total: float, totalCost: float>, limit: int, offset: int, totalCount: int>
# operationId: findOrders
export def "find-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 20)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --status: list<string> # Filter by order status, accepts multiple values in comma separated string, available values: [PROCESSING, FINISHED, PAYMENT_ERROR, VOID, WAIT_FOR_PAYMENT, PARTIALLY_ADJUSTED, ADJUSTED]
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: fields, var: fields}, {name: status, var: status, style: multi}, {name: intervalBegin, var: interval_begin}, {name: intervalEnd, var: interval_end}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, fields: $fields, status: $status, interval_begin: $interval_begin, interval_end: $interval_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase keywords
#
# POST /orders/keywords
# Returns: record<id: int>
# operationId: orderKeywords
export def "order-keywords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --keywords: list<string> # A list of keywords
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/keywords"
    query: [{name: fields, var: fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: keywords, var: keywords}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    fields: $fields, keywords: $keywords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase numbers
#
# POST /orders/numbers
# Returns: record<id: int>
# operationId: orderNumbers
export def "order-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --city: string # City of requested numbers
  --local-count: int # Total count of local numbers requested (format: int32)
  --numbers: list<string> # A list of phone numbers in E.164 format (11-digit) to buy. Example: 12132000384
  --prefix: string # Country prefix of requested numbers
  --promo: string # ~
  --state: string # A two-letter state code of requested numbers
  --toll-free-count: int # Total count of toll-free numbers requested (format: int32)
  --zipcode: string # A five-digit Zip code of requested numbers
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/numbers"
    query: [{name: fields, var: fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: localCount, var: local_count}, {name: numbers, var: numbers}, {name: prefix, var: prefix}, {name: promo, var: promo}, {name: state, var: state}, {name: tollFreeCount, var: toll_free_count}, {name: zipcode, var: zipcode}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    fields: $fields, city: $city, local_count: $local_count, numbers: $numbers, prefix: $prefix, promo: $promo, state: $state, toll_free_count: $toll_free_count, zipcode: $zipcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific order
#
# GET /orders/{id}
# Returns: record<created: int, id: int, keywords: record<fulfilled: list<string>, ordered: int, unitCost: float>, localNumbers: record<fulfilled: list<string>, ordered: int, unitCost: float>, salesTax: float, status: string, summary: float, tollFreeNumbers: record<fulfilled: list<string>, ordered: int, unitCost: float>, total: float, totalCost: float>
# operationId: getOrder
export def "get-order" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get delivery reports by ad hoc criteria
#
# GET /reports/delivery
# Returns: record<items: table<campaignId: int, carrier: string, deliveryCategory: string, deliveryState: string, fromNumber: string, messageText: string, toNumber: string, updated: string>, limit: int, offset: int, totalCount: int>
# operationId: getDeliveryReports
export def "get-delivery-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # ~
  --end-date: string # ~
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --campaign-id: int # ~ (format: int64)
  --from-number: string # ~
  --to-number: string # ~
  --delivery-category: string@delivery-category-completer # ~
  --delivery-state: string@delivery-state-completer # ~
  --carrier: string # ~
  --message-text: string # ~
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reports/delivery"
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: campaignId, var: campaign_id}, {name: fromNumber, var: from_number}, {name: toNumber, var: to_number}, {name: deliveryCategory, var: delivery_category}, {name: deliveryState, var: delivery_state}, {name: carrier, var: carrier}, {name: messageText, var: message_text}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    start_date: $start_date, end_date: $end_date, limit: $limit, offset: $offset, campaign_id: $campaign_id, from_number: $from_number, to_number: $to_number, delivery_category: $delivery_category, delivery_state: $delivery_state, carrier: $carrier, message_text: $message_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find texts
#
# GET /texts
# Returns: record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>
# operationId: findTexts
export def "find-texts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<int> # List of Text ids to search for, if ids specified other query params ignored
  --campaign-id: int # An id of a campaign, queries for texts inside a particular campaign. Specify null to list texts of all campaigns or 0 for a default campaign (format: int64)
  --batch-id: int # An Id of a contact batch, queries for texts which are used in the particular contact batch (format: int64)
  --from-number: string # A phone number in E.164 format (11-digit). Example: 12132000384, 67076
  --to-number: string # A phone number in E.164 format (11-digit). Example: 12132000384, 67076
  --label: string # A label of a text message
  --states: string # Expected text statuses in comma separated string, available values: READY, SELECTED, CALLBACK, FINISHED, DISABLED, DNC, DUP, INVALID, TIMEOUT, PERIOD_LIMIT. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --results: string # Expected text results in comma separated string, available values: SENT, RECEIVED, DNT, TOO_BIG, INTERNAL_ERROR, CARRIER_ERROR, CARRIER_TEMP_ERROR, UNDIALED. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --inbound: oneof<nothing, bool> # Specify true for inbound or false for outbounds. Do not specify this parameter if you need to get both inbound and outbound texts listed in response
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 10)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts"
    query: [{name: id, var: id, style: multi}, {name: campaignId, var: campaign_id}, {name: batchId, var: batch_id}, {name: fromNumber, var: from_number}, {name: toNumber, var: to_number}, {name: label, var: label}, {name: states, var: states}, {name: results, var: results}, {name: inbound, var: inbound}, {name: intervalBegin, var: interval_begin}, {name: intervalEnd, var: interval_end}, {name: limit, var: limit}, {name: offset, var: offset}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, campaign_id: $campaign_id, batch_id: $batch_id, from_number: $from_number, to_number: $to_number, label: $label, states: $states, results: $results, inbound: $inbound, interval_begin: $interval_begin, interval_end: $interval_end, limit: $limit, offset: $offset, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send texts
#
# POST /texts
# Returns: record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>>
# operationId: sendTexts
export def "send-texts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --campaign-id: int # Specifies a campaignId to send texts through a previously created campaign (format: int64)
  --default-message: string # Text message can be overridden by TextRecipient.message field. If multiple recipients have the same text message to a different recipients it is better to specify a single default message and do not duplicate it in each recipient.
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/texts"
    query: [{name: fields, var: fields}, {name: campaignId, var: campaign_id}, {name: defaultMessage, var: default_message}, {name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, campaign_id: $campaign_id, default_message: $default_message, strict_validation: $strict_validation, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find auto replies
#
# GET /texts/auto-replys
# Returns: record<items: table<id: int, keyword: string, match: string, message: string, number: string>, limit: int, offset: int, totalCount: int>
# operationId: findTextAutoReplys
export def "find-text-auto-replys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --number: string # Phone number in E.164 format (11-digit) which contains a TextAutoReply. Example: 12132000384. If number is empty then operator returns all autoreplies configured for the user's account
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/auto-replys"
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, limit: $limit, offset: $offset, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an auto reply
#
# POST /texts/auto-replys
# Returns: record<id: int>
# operationId: createTextAutoReply
export def "create-text-auto-reply" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # An id of a text auto reply (format: int64)
  --keyword: string # Setup autoreply for a given keyword
  --match: string # Text to match. If it is set then autoreply will be sent to a person who texted message with matched text. Case insensitive, if parameter is not specified then all texts will be matched
  --message: string # A text message to return as an auto reply
  --number: string # Setup autoreply for a given phone number, E.164 format (11-digit). Example: 12132000384
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/texts/auto-replys"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: keyword, var: keyword}, {name: match, var: match}, {name: message, var: message}, {name: number, var: number}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    id: $id, keyword: $keyword, match: $match, message: $message, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an auto reply
#
# DELETE /texts/auto-replys/{id}
# operationId: deleteTextAutoReply
export def "delete-text-auto-reply" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/texts/auto-replys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific auto reply
#
# GET /texts/auto-replys/{id}
# Returns: record<id: int, keyword: string, match: string, message: string, number: string>
# operationId: getTextAutoReply
export def "get-text-auto-reply" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/auto-replys/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find text broadcasts
#
# GET /texts/broadcasts
# Returns: record<items: table<bigMessageStrategy: string, fromNumber: string, id: int, labels: list, lastModified: int, localTimeRestriction: record, maxActive: int, media: list, message: string, name: string, recipients: list, resumeNextDay: bool, schedules: list, status: string>, limit: int, offset: int, totalCount: int>
# operationId: findTextBroadcasts
export def "find-text-broadcasts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A name of text broadcast
  --label: string # A label of a text broadcast
  --running: oneof<nothing, bool> # Returns broadcasts only in running state.
  --scheduled: oneof<nothing, bool> # Specify whether the campaigns should be scheduled or not
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 10)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/broadcasts"
    query: [{name: name, var: name}, {name: label, var: label}, {name: running, var: running}, {name: scheduled, var: scheduled}, {name: intervalBegin, var: interval_begin}, {name: intervalEnd, var: interval_end}, {name: limit, var: limit}, {name: offset, var: offset}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    name: $name, label: $label, running: $running, scheduled: $scheduled, interval_begin: $interval_begin, interval_end: $interval_end, limit: $limit, offset: $offset, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a text broadcast
#
# POST /texts/broadcasts
# Returns: record<id: int>
# operationId: createTextBroadcast
export def "create-text-broadcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: oneof<nothing, bool> # If true then starts the campaign immediately (not required).
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --big-message-strategy: string@big-message-strategy-completer # If message length exceeds 160 characters, multiple messages will be sent, SEND_MULTIPLE strategy is chosen by default. Available values: SEND_MULTIPLE - send text as multiple messages, DO_NOT_SEND - do not send text if it exceeds 160 characters, TRIM - trims text message to 160 characters
  --from-number: string # A phone number in E.164 format (11-digit) or short code. Example: 12132000384, 67076, etc
  --id: int # A unique id of a broadcast (format: int64)
  --labels: list<string> # A labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # A maximum number of texts that CallFire dials at once (format: int32)
  --media: list # ~ — item shape: {accountId?: int, created?: int, id?: int, lengthInBytes?: int, mediaType?: string, name?: string, publicUrl?: string}
  --message: string # A text message
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a text campaign, can be an existing contacts or a new one — item shape: {attributes?: record, contactId?: int, fromNumber?: string, media?: list, message?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # ~
  --schedules: list # ~ — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/texts/broadcasts"
    query: [{name: start, var: start}, {name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: bigMessageStrategy, var: big_message_strategy}, {name: fromNumber, var: from_number}, {name: id, var: id}, {name: labels, var: labels}, {name: localTimeRestriction, var: local_time_restriction}, {name: maxActive, var: max_active}, {name: media, var: media}, {name: message, var: message}, {name: name, var: name}, {name: recipients, var: recipients}, {name: resumeNextDay, var: resume_next_day}, {name: schedules, var: schedules}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    start: $start, strict_validation: $strict_validation, big_message_strategy: $big_message_strategy, from_number: $from_number, id: $id, labels: $labels, local_time_restriction: $local_time_restriction, max_active: $max_active, media: $media, message: $message, name: $name, recipients: $recipients, resume_next_day: $resume_next_day, schedules: $schedules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific text broadcast
#
# GET /texts/broadcasts/{id}
# Returns: record<bigMessageStrategy: string, fromNumber: string, id: int, labels: list<string>, lastModified: int, localTimeRestriction: record<beginHour: int, beginMinute: int, enabled: bool, endHour: int, endMinute: int>, maxActive: int, media: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, message: string, name: string, recipients: table<attributes: record, contactId: int, fromNumber: string, media: list, message: string, phoneNumber: string>, resumeNextDay: bool, schedules: table<campaignId: int, daysOfWeek: list, id: int, startDate: record, startTimeOfDay: record, stopDate: record, stopTimeOfDay: record, timeZone: string>, status: string>
# operationId: getTextBroadcast
export def "get-text-broadcast" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/broadcasts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a text broadcast
#
# PUT /texts/broadcasts/{id}
# Returns: record<id: int>
# operationId: updateTextBroadcast
export def "update-text-broadcast" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --big-message-strategy: string@big-message-strategy-completer # If message length exceeds 160 characters, multiple messages will be sent, SEND_MULTIPLE strategy is chosen by default. Available values: SEND_MULTIPLE - send text as multiple messages, DO_NOT_SEND - do not send text if it exceeds 160 characters, TRIM - trims text message to 160 characters
  --from-number: string # A phone number in E.164 format (11-digit) or short code. Example: 12132000384, 67076, etc
  --body-id: int # A unique id of a broadcast (format: int64) (spec name: id)
  --labels: list<string> # A labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # A maximum number of texts that CallFire dials at once (format: int32)
  --media: list # ~ — item shape: {accountId?: int, created?: int, id?: int, lengthInBytes?: int, mediaType?: string, name?: string, publicUrl?: string}
  --message: string # A text message
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a text campaign, can be an existing contacts or a new one — item shape: {attributes?: record, contactId?: int, fromNumber?: string, media?: list, message?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # ~
  --schedules: list # ~ — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/texts/broadcasts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: bigMessageStrategy, var: big_message_strategy}, {name: fromNumber, var: from_number}, {name: id, var: body_id}, {name: labels, var: labels}, {name: localTimeRestriction, var: local_time_restriction}, {name: maxActive, var: max_active}, {name: media, var: media}, {name: message, var: message}, {name: name, var: name}, {name: recipients, var: recipients}, {name: resumeNextDay, var: resume_next_day}, {name: schedules, var: schedules}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, strict_validation: $strict_validation, big_message_strategy: $big_message_strategy, from_number: $from_number, body_id: $body_id, labels: $labels, local_time_restriction: $local_time_restriction, max_active: $max_active, media: $media, message: $message, name: $name, recipients: $recipients, resume_next_day: $resume_next_day, schedules: $schedules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive text broadcast
#
# POST /texts/broadcasts/{id}/archive
# operationId: archiveTextBroadcast
export def "archive-text-broadcast" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/texts/broadcasts/{id}/archive"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find batches in a text broadcast
#
# GET /texts/broadcasts/{id}/batches
# Returns: record<items: table<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>, limit: int, offset: int, totalCount: int>
# operationId: getTextBroadcastBatches
export def "get-text-broadcast-batches" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/broadcasts/{id}/batches"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add batches to a text broadcast
#
# POST /texts/broadcasts/{id}/batches
# Returns: record<id: int>
# operationId: addTextBroadcastBatch
export def "add-text-broadcast-batch" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --contact-list-id: int # An id of existing contact list (format: int64)
  --name: string # A name of batch
  --recipients: list # A list of Recipient objects. For each recipient you can set its phone number or existing contact id to use contact which already exists in account — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --scrub-duplicates: oneof<nothing, bool> # Removes duplicate recipients from batch if true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/texts/broadcasts/{id}/batches"
    path_params: [{name: id, var: id}]
    query: [{name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactListId, var: contact_list_id}, {name: name, var: name}, {name: recipients, var: recipients}, {name: scrubDuplicates, var: scrub_duplicates}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    id: $id, strict_validation: $strict_validation, contact_list_id: $contact_list_id, name: $name, recipients: $recipients, scrub_duplicates: $scrub_duplicates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add recipients to a text broadcast
#
# POST /texts/broadcasts/{id}/recipients
# Returns: record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>>
# operationId: addTextBroadcastRecipients
export def "add-text-broadcast-recipients" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/texts/broadcasts/{id}/recipients"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: strictValidation, var: strict_validation}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields, strict_validation: $strict_validation, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start text broadcast
#
# POST /texts/broadcasts/{id}/start
# operationId: startTextBroadcast
export def "start-text-broadcast" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/texts/broadcasts/{id}/start"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get statistics on text broadcast
#
# GET /texts/broadcasts/{id}/stats
# Returns: record<billedAmount: float, doNotTextCount: int, errorCount: int, recievedCount: int, remainingOutboundCount: int, sentCount: int, tooBigCount: int, totalOutboundCount: int, unsentCount: int>
# operationId: getTextBroadcastStats
export def "get-text-broadcast-stats" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --begin: int # Start of a search find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --end: int # End of a search time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/broadcasts/{id}/stats"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}, {name: begin, var: begin}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields, begin: $begin, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop text broadcast
#
# POST /texts/broadcasts/{id}/stop
# operationId: stopTextBroadcast
export def "stop-text-broadcast" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/texts/broadcasts/{id}/stop"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find texts in a text broadcast
#
# GET /texts/broadcasts/{id}/texts
# Returns: record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int>
# operationId: getTextBroadcastTexts
export def "get-text-broadcast-texts" [
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
  --batch-id: int # ~ (format: int64)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/broadcasts/{id}/texts"
    path_params: [{name: id, var: id}]
    query: [{name: batchId, var: batch_id}, {name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, batch_id: $batch_id, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable/enable undialed recipients in broadcast
#
# POST /texts/broadcasts/{id}/toggleRecipientsStatus
# operationId: toggleTextBroadcastRecipientsStatus
export def "toggle-text-broadcast-recipients-status" [
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
  --enable: oneof<nothing, bool> # Flag which indicate what to do with texts (true will enable texts in DISABLED status and vice versa) (default: false)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/texts/broadcasts/{id}/toggleRecipientsStatus"
    path_params: [{name: id, var: id}]
    query: [{name: enable, var: enable}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, enable: $enable, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific text
#
# GET /texts/{id}
# Returns: record<attributes: record, batchId: int, campaignId: int, contact: record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list<string>, media: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, message: string, modified: int, records: table<billedAmount: float, callerName: string, finishTime: int, id: int, labels: list, message: string, switchId: string, textResult: string, toNumber: string>, state: string, toNumber: string>
# operationId: getText
export def "get-text" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/texts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find webhooks
#
# GET /webhooks
# Returns: record<items: table<callback: string, createdAt: int, enabled: bool, events: list, expiresAt: int, fields: string, id: int, name: string, nonStrictSsl: bool, resource: string, secret: string, singleUse: bool, updatedAt: int>, limit: int, offset: int, totalCount: int>
# operationId: findWebhooks
export def "find-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --name: string # A name of a webhook
  --resource: string # A name of a resource, available values: 'CccCampaign', 'CallBroadcast', 'TextBroadcast', 'OutboundCall', 'OutboundText', 'InboundCall', 'InboundText', 'ContactList'
  --event: string # A name of event, available values: 'started', 'stopped', 'finished'
  --callback: string # A callback URL
  --enabled: oneof<nothing, bool> # Specifies whether webhook is enabled
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: name, var: name}, {name: resource, var: resource}, {name: event, var: event}, {name: callback, var: callback}, {name: enabled, var: enabled}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields, limit: $limit, offset: $offset, name: $name, resource: $resource, event: $event, callback: $callback, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a webhook
#
# POST /webhooks
# Returns: record<id: int>
# operationId: createWebhook
export def "create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # URL that webhook will send POST to on resource event trigger
  --enabled: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --events: list<string> # Comma separated list of events on resource that will trigger callbacks (ex: STARTED, STOPPED, FINISHED, etc...).
  --expires-at: int # ~ (format: int64)
  --fields: string # A limit callback response to a particular fields
  --id: int # An id of a webhook (format: int64)
  --name: string # A name of a webhook
  --non-strict-ssl: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --resource: string # A resource name that webhook is watching events on. Use GET /webhooks/resources to determine resources and events available (ex: InboundCall, OutboundCall, InboundText, OutboundText, CallBroadcast, TextBroadcast, etc...)
  --secret: string # Webhook secret token which is used as a signing key to HmacSHA1 hash of json payload which is returned in 'X-CallFire-Signature' header. This header can be used to verify callback POST is coming from CallFire. See [security guide](https://developers.callfire.com/security-guide.html)
  --single-use: oneof<nothing, bool> # If true is set then webhook triggers only once. Afterwards the webhook will be deleted
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: callback, var: callback}, {name: enabled, var: enabled}, {name: events, var: events}, {name: expiresAt, var: expires_at}, {name: fields, var: fields}, {name: id, var: id}, {name: name, var: name}, {name: nonStrictSsl, var: non_strict_ssl}, {name: resource, var: resource}, {name: secret, var: secret}, {name: singleUse, var: single_use}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    callback: $callback, enabled: $enabled, events: $events, expires_at: $expires_at, fields: $fields, id: $id, name: $name, non_strict_ssl: $non_strict_ssl, resource: $resource, secret: $secret, single_use: $single_use
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find webhook resources
#
# GET /webhooks/resources
# Returns: record<items: table<resource: string, supportedEvents: list>>
# operationId: findWebhookResources
export def "find-webhook-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/resources"
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find specific webhook resource
#
# GET /webhooks/resources/{resource}
# Returns: record<resource: string, supportedEvents: list<string>>
# operationId: getWebhookResource
export def "get-webhook-resource" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/resources/{resource}"
    path_params: [{name: resource, var: resource}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    resource: $resource, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook
#
# DELETE /webhooks/{id}
# operationId: deleteWebhook
export def "delete-webhook" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a specific webhook
#
# GET /webhooks/{id}
# Returns: record<callback: string, createdAt: int, enabled: bool, events: list<string>, expiresAt: int, fields: string, id: int, name: string, nonStrictSsl: bool, resource: string, secret: string, singleUse: bool, updatedAt: int>
# operationId: getWebhook
export def "get-webhook" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook
#
# PUT /webhooks/{id}
# operationId: updateWebhook
export def "update-webhook" [
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
  --callback: string # URL that webhook will send POST to on resource event trigger
  --enabled: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --events: list<string> # Comma separated list of events on resource that will trigger callbacks (ex: STARTED, STOPPED, FINISHED, etc...).
  --expires-at: int # ~ (format: int64)
  --fields: string # A limit callback response to a particular fields
  --body-id: int # An id of a webhook (format: int64) (spec name: id)
  --name: string # A name of a webhook
  --non-strict-ssl: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --resource: string # A resource name that webhook is watching events on. Use GET /webhooks/resources to determine resources and events available (ex: InboundCall, OutboundCall, InboundText, OutboundText, CallBroadcast, TextBroadcast, etc...)
  --secret: string # Webhook secret token which is used as a signing key to HmacSHA1 hash of json payload which is returned in 'X-CallFire-Signature' header. This header can be used to verify callback POST is coming from CallFire. See [security guide](https://developers.callfire.com/security-guide.html)
  --single-use: oneof<nothing, bool> # If true is set then webhook triggers only once. Afterwards the webhook will be deleted
]: any -> any {
  $in | http-request {
    method: put
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: callback, var: callback}, {name: enabled, var: enabled}, {name: events, var: events}, {name: expiresAt, var: expires_at}, {name: fields, var: fields}, {name: id, var: body_id}, {name: name, var: name}, {name: nonStrictSsl, var: non_strict_ssl}, {name: resource, var: resource}, {name: secret, var: secret}, {name: singleUse, var: single_use}]}
    accept: ["application/json"]
    ok: []
    auth: basic
  } {
    id: $id, callback: $callback, enabled: $enabled, events: $events, expires_at: $expires_at, fields: $fields, body_id: $body_id, name: $name, non_strict_ssl: $non_strict_ssl, resource: $resource, secret: $secret, single_use: $single_use
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
