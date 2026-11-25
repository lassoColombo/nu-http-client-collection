# Auto-generated client for Noosh API application v1.0
# Source: https://api.apis.guru/v2/specs/noosh.com/1.0/openapi.json
# Auth: --token flag or $env.NOOSH_API_APPLICATION_TOKEN

const CLIENT = {
  base_url: "http://example.com:80/v1"
  token_env_var: "NOOSH_API_APPLICATION_TOKEN"
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

def base-url-completer [] { ["http://example.com:80/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "application/json" "application/x-json-smile" "application/x-yaml" "application/xml" "text/csv" "text/x-yaml" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-file-tags: "record<result: table<isSpec: bool, tagId: int, tagName: string>, status_code: int, status_reason: string>"
    get-files: "record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>"
    upload-file: "record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>"
    get-file: "record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>"
    get-spec: "record<result: record<client_status: string, create_date: string, created_by: record<email: string, first_name: string, last_name: string, middle_name: string>, first_level_custom_fields: record<property_attributes: list, property_id: int, property_name: string>, header_custom_fields: record<property_attributes: list, property_id: int, property_name: string>, job_id: int, last_updated: string, product_type: string, product_type_info: record<label: string, product_type_id: int>, quantity_1: int, quantity_2: int, quantity_3: int, quantity_4: int, quantity_5: int, reference_number: string, second_level_custom_fields: list<record>, sku: string, spec_id: int, spec_name: string, spec_options: list<record>, spec_options_complete: list<record>, spec_original: record<spec_id: int, spec_name: string>, spec_type: record<spec_type_id: int, spec_type_name: string>, supplier_status: string, uofms: list<record>, user_state: string>, status_code: int, status_reason: string>"
    put-spec: "record<spec_id: int, spec_name: string, status_code: int, status_reason: string>"
    post-team-member-of-project: "record<results: table<role: record, team_member_id: int, user: record, was_invited_before: bool>, status_code: int, status_reason: string>"
    get-spec-type-fields: "record<result: any, status_code: int, status_reason: string>"
    get-country-list: "record<result: table<constant_token: string, country: string, country_id: int>, status_code: int, status_reason: string>"
    get-workgroup-list: "record<results: table<is_default: bool, parent_workgroup: record, workgroup_id: int, workgroup_name: string>, status_code: int, status_reason: string>"
    get-automatic-invitation-list: "record<results: table<automatic_invitation_type_name: string, team_template: record>, status_code: int, status_reason: string>"
    get-billing-recipients: "record<results: table<address: string, company_name: string, email: string, first_name: string, last_name: string, primary_phone: string, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>"
    get-buy-order-list-of-workgroup: "record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, project: record, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>"
    get-buy-order-of-workgroup: "record<result: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: list<record>, classification: string, closed_date: string, closing_change_orders: list<record>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list<record>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: list<record>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, status_code: int, status_reason: string>"
    get-client-workgroup-list: "record<results: table<client_ac_workgroup_id: int, client_workgroup_id: int, client_workgroup_name: string>, status_code: int, status_reason: string>"
    get-specific-client-workgroup: "record<result: record<client_ac_workgroup_id: int, client_workgroup_id: int, client_workgroup_name: string, custom_fields: list<record>, margin_percent: any, markup: any, markup_percent: any>, status_code: int, status_reason: string>"
    get-project-category-list-of-client: "record<results: table<project_category_id: int, project_category_name: string>, status_code: int, status_reason: string>"
    get-project-home-user-field-list-of-client: "record<results: table<is_required: bool, label: string, ordinal_number: int, param_name: string, type: string, user_field_id: int>, status_code: int, status_reason: string>"
    get-project-status-of-client: "record<results: table<project_status_id: int, project_status_name: string>, status_code: int, status_reason: string>"
    get-contact-list: "record<results: table<address: string, company_name: string, email: string, first_name: string, last_name: string, primary_phone: string, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>"
    get-contact-user-info: "record<result: record<address: any, company_name: string, email: string, fax_number: string, first_name: string, last_name: string, locale: string, middle_name: string, organization: string, phone_number: string, time_zone: string, title: string, user_id: int>, status_code: int, status_reason: string>"
    get-wg-task-status-list-of-workgroup: "record<result: table<description: string, is_active: bool, is_default: bool, task_status_name: string, tasks_status_id: int>, status_code: int, status_reason: string>"
    get-custom-task-types-of-wg: "record<results: table<task_type: string, task_type_id: int>, status_code: int, status_reason: string>"
    get-deactivation-reason-list: "record<results: table<deactivation_reason_id: int, deactivation_reason_name: string>, status_code: int, status_reason: string>"
    task-priority-list: "record<results: table<task_priority_id: int, task_priority_name: string>, status_code: int, status_reason: string>"
    get-default-task-status-list: "record<results: table<task_status_id: int, task_status_name: string>, status_code: int, status_reason: string>"
    get-workgroup-detail: "record<result: record<address_line1: string, address_line2: string, address_line3: string, city: string, country: string, country_code: string, custom_fields: list<record>, default_currency: string, portal: string, postal: string, state: string, workgroup_id: int, workgroup_name: string>, status_code: int, status_reason: string>"
    put-workgroup: "record<status_code: int, status_reason: string, workgroup_id: int, workgroup_name: string>"
    get-exchange-rate-list: "record<status_code: int, status_reason: string>"
    get-my-time-card-list: "record<results: table<is_submit: bool, last_updated_date: string, no_of_workdays: int, submit_date: string, timecard_id: int, total_hours: any, week_beginning: string>, status_code: int, status_reason: string>"
    get-my-time-card: "record<billable_hours: any, is_submit: bool, last_updated_date: string, no_of_workdays: int, nonbillable_hours: any, submit_date: string, time_card_line: table<activity_name: string, day1_hours_spent: any, day2_hours_spent: any, day3_hours_spent: any, day4_hours_spent: any, day5_hours_spent: any, day6_hours_spent: any, day7_hours_spent: any, project: record, task: record, time_card_line_id: int, total_hours_spent: any>, timecard_id: int, total_hours: any, week_beginning: string>"
    get-product-type-list-of-workgroup: "record<result: table<is_checked: bool, label: string, product_type_id: int>, status_code: int, status_reason: string>"
    get-spec-product-type-list-of-workgroup: "record<result: table<is_checked: bool, label: string, product_type_id: int>, status_code: int, status_reason: string>"
    post-spec-product-type-list-of-workgroup: "record<enableDifferentiatePrdTypePreference: bool, spec_prdType_list: table<prdType_labels: list, spec_type_id: int>>"
    upload-profile-image: "record<profileImgUrl: string, status_code: int, status_reason: string>"
    get-project-category-list: "record<results: table<project_category_id: int, project_category_name: string>, status_code: int, status_reason: string>"
    get-project-home-user-fields-list: "record<results: table<is_required: bool, label: string, ordinal_number: int, param_name: string, type: string, user_field_id: int>, status_code: int, status_reason: string>"
    get-project-status: "record<results: table<project_status_id: int, project_status_name: string>, status_code: int, status_reason: string>"
    get-project-list: "record<results: table<client_account: string, client_workgroup_id: int, completion_date: string, is_active: bool, is_hot: bool, last_spec_update: string, project_id: int, project_name: string, project_number: string, project_status: string>, status_code: int, status_reason: string>"
    post-project: "record<project_id: int, status_code: int, status_reason: string>"
    delete-project: "record<status_code: int, status_reason: string>"
    get-project: "record<result: record<category: string, client_account: string, client_user: string, client_user_id: int, client_workgroup_id: int, comments: string, completion_date: string, custom_fields: list<record>, deactivation_reason: string, is_active: bool, is_hot: bool, last_spec_update: string, mod_date: string, owner_workgroup: string, parent_project: record<client_account: string, client_user: string, client_user_id: int, client_workgroup_id: int, comments: string, created_by: record, project_create_date: string, project_description: string, project_id: int, project_name: string, project_number: string>, project_create_date: string, project_description: string, project_id: int, project_name: string, project_number: string, project_status: string, team_owners: string>, status_code: int, status_reason: string>"
    patch-project: "record<status_code: int, status_reason: string>"
    put-project: "record<status_code: int, status_reason: string>"
    get-buy-order-list: "record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>"
    post-buy-order: "record<buyer_user_id: int, comments: string, custom_fields: table<date_value: string, number_value: any, param_name: string, string_value: string>, invoice_or_billing_recipient: int, order_completion_date: string, order_items: table<completion_date: string, custom_fields: list, ex_tax_value_calculated: any, notes: string, per: int, price: any, quantity: any, shipping: any, spec_id: int, spec_reference_id: int, tax: string>, other_selection_reason: string, payment_method_id: int, payment_reference_no: string, sellOrder: bool, shipping: any, supplier_reference: string, supplier_selection_reason_id: int, supplier_user_id: int, tax: string, title: string>"
    get-buy-order: "record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>"
    put-buy-order: "record<order_id: int, status_code: int, status_reason: string>"
    attach-project: "record<status_code: int, status_reason: string>"
    get-estimate-list: "record<result: table<create_date: string, currency: string, estimate_id: int, estimate_title: string, expiration_date: string, project: record, rfe: record, status: string, submit_date: string, supplier_workgroup: record, transactional_currency: string>, status_code: int, status_reason: string>"
    post-estimate: "record<comments: string, description: string, estimate_items: table<paper_items: list, quantity_1_price: any, quantity_1_shipping: any, quantity_1_tax: any, quantity_2_price: any, quantity_2_shipping: any, quantity_2_tax: any, quantity_3_price: any, quantity_3_shipping: any, quantity_3_tax: any, quantity_4_price: any, quantity_4_shipping: any, quantity_4_tax: any, quantity_5_price: any, quantity_5_shipping: any, quantity_5_tax: any, rfe_item_id: int>, estimate_title: string, expiration_date: string, owner_reference: string, rfe_id: int>"
    get-estimate: "record<result: record<comments: string, create_date: string, currency: string, custom_fields: list<record>, description: string, estimate_id: int, estimate_title: string, expiration_date: string, items: list<record>, project: record<project_id: int, project_name: string, project_number: string>, reference_number: string, rfe: record<rfe_due_date: string, rfe_id: int, rfe_title: string, status: string>, status: string, submit_date: string, submitted_by: string, submitted_by_user_id: int, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, transactional_currency: string>, status_code: int, status_reason: string>"
    get-invoices: "record<result: table<comments: string, currency: string, custom_fields: list, grand_total: any, invoice_date: string, invoice_due_date: string, invoice_id: int, invoice_number: string, invoice_to: string, is_final: int, is_nonBillable: int, items: list, order_reference: string, order_title: string, payment_method: string, prepared_by: string, project_number: int, reference_number: string, shipping: any, status: string, sub_total: any, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_shipping: any, transactional_sub_total: any, transactional_tax: any>, status_code: int, status_reason: string>"
    get-invoice: "record<result: record<comments: string, currency: string, custom_fields: list<record>, grand_total: any, invoice_date: string, invoice_due_date: string, invoice_id: int, invoice_number: string, invoice_to: string, is_final: int, is_nonBillable: int, items: list<record>, order_reference: string, order_title: string, payment_method: string, prepared_by: string, project_number: int, reference_number: string, shipping: any, status: string, sub_total: any, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_shipping: any, transactional_sub_total: any, transactional_tax: any>, status_code: int, status_reason: string>"
    get-invoice-files: "record<result: table<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>"
    get-member-roles: "record<result: table<role_id: int, role_name: string>, status_code: int, status_reason: string>"
    get-order: "record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, is_sell_order: bool, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>"
    get-quote-list: "record<result: table<currency: string, grand_total: any, quote_id: int, quote_title: string, rfq: record, status: string, submit_date: string, transactional_currency: string, transactional_grand_total: any>, status_code: int, status_reason: string>"
    get-quote: "record<result: record<client: string, client_user_id: int, comments: string, creator_user_id: int, currency: string, custom_fields: list<record>, description: string, grand_total: any, is_show_supplier_information: bool, last_update_by_user_id: int, proposed_order_completion_date: string, quote_expiration_date: string, quote_id: int, quote_items: list<record>, quote_items_total: any, quote_title: string, shipping: any, status: string, submit_date: string, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_quote_items_total: any, transactional_shipping: any, transactional_tax: any, vat_code: string, vat_rate: any>, status_code: int, status_reason: string>"
    put-quote: "record<status_code: int, status_reason: string>"
    get-rfe-list: "record<results: table<estimate_due_date: string, rfe_id: int, rfe_items: list, rfe_title: string, supplier_estimates: list>, status_code: int, status_reason: string>"
    post-rfe: "record<rfq_id: int, status_code: int, status_reason: string>"
    get-rfe: "record<result: record<description: string, details: string, estimate_due_date: string, estimators: list<string>, itemized_tax_and_shipping: int, proposed_order_completion_date: string, reference_number: string, requestor: string, rfe_id: int, rfe_items: list<record>, status: string, submitted_date: string, supplier_estimates: list<record>, title: string>, status_code: int, status_reason: string>"
    get-rfq-list: "record<result: table<quotes: list, received_date: string, rfq_id: int, rfq_title: string, status: string>, status_code: int, status_reason: string>"
    get-rfq: "record<result: record<comments: string, description: string, proposed_completion_date: string, quote_due_date: string, quotes: list<record>, received_date: string, recipient_name: string, requestor_name: string, rfq_id: int, rfq_items: list<record>, rfq_title: string, status: string>, status_code: int, status_reason: string>"
    get-sell-order-list: "record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>"
    get-sell-order: "record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>"
    put-sell-order: "record<order_id: int, status_code: int, status_reason: string>"
    get-shipment-list: "record<result: table<locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record>, status_code: int, status_reason: string>"
    post-shipment: "record<results: table<location_id: int, shipment_id: int, spec_id: int>, status_code: int, status_reason: string>"
    get-shipment: "record<result: record<locations: list<record>, locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record<job_id: int, reference_number: string, spec_id: int, spec_name: string>>, resut: record<locations: list<record>, locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record<job_id: int, reference_number: string, spec_id: int, spec_name: string>>, status_code: int, status_reason: string>"
    put-shipment-location: "record<status_code: int, status_reason: string>"
    get-spec-list: "record<results: table<client_status: string, create_date: string, created_by: record, job_id: int, last_updated: string, reference_number: string, spec_id: int, spec_name: string, spec_options_complete: list, supplier_status: string, uofms: list, user_state: string>, status_code: int, status_reason: string>"
    post-spec: "record<spec_id: int, status_code: int, status_reason: string>"
    get-v1-workgroups-workgroup-id-projects-project-id-specs-spec-id: "record<results: table<client_status: string, create_date: string, created_by: record, job_id: int, last_updated: string, reference_number: string, spec_id: int, spec_name: string, spec_options_complete: list, supplier_status: string, uofms: list, user_state: string>, status_code: int, status_reason: string>"
    put-v1-workgroups-workgroup-id-projects-project-id-specs-spec-id: "record<spec_id: int, spec_name: string, status_code: int, status_reason: string>"
    get-task-list-of-project: "record<results: table<actual_end: string, actual_hours: any, actual_start: string, assign_to: record, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, current_duration: any, is_milestone: bool, mod_date: string, plan_end: string, plan_start: string, priority: string, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>"
    post-task-for-project: "record<status_code: int, status_reason: string, task_id: int>"
    get-task-of-project: "record<result: record<actual_duration: any, actual_end: string, actual_hours: any, actual_start: string, assign_to: record<email: string, first_name: string, last_name: string, middle_name: string>, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, comments: string, create_date: string, creator_workgroup_name: string, current_duration: any, description: string, is_milestone: bool, last_updated_by: record<email: string, first_name: string, last_name: string, middle_name: string>, mod_date: string, percent_complete: int, plan_duration: any, plan_end: string, plan_start: string, priority: string, requested_by: record<email: string, first_name: string, last_name: string, middle_name: string>, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>"
    get-team-member-list-of-client-project: "record<results: table<company_name: string, name: string, phone: string, role: string, teammember_id: int, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>"
    get-team-member-list-of-project: "record<results: table<company_name: string, name: string, phone: string, role: string, teammember_id: int, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>"
    post-v1-workgroups-workgroup-id-projects-project-id-teammembers: "record<status_code: int, status_reason: string, teammember_id: int>"
    delete-team-member-of-project: "record<status_code: int, status_reason: string, teammember_id: int>"
    get-quote-state-list: "record<results: table<object_state_id: int, object_state_name: string>, status_code: int, status_reason: string>"
    get-v1-workgroups-workgroup-id-quotes: "record<currency: string, grand_total: any, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, quote_title: string, rfq: record<received_date: string, rfq_id: int, rfq_title: string, status: string>, status: string, submit_date: string, transactional_currency: string, transactional_grand_total: any>"
    get-received-time-card-list: "record<results: table<is_submit: bool, last_updated_date: string, no_of_workdays: int, submit_date: string, timecard_id: int, total_hours: any, week_beginning: string>, status_code: int, status_reason: string>"
    get-received-time-card: "record<billable_hours: any, is_submit: bool, last_updated_date: string, no_of_workdays: int, nonbillable_hours: any, owner: record<email: string, first_name: string, last_name: string, middle_name: string>, submit_date: string, time_card_line: table<activity_name: string, day1_hours_spent: any, day2_hours_spent: any, day3_hours_spent: any, day4_hours_spent: any, day5_hours_spent: any, day6_hours_spent: any, day7_hours_spent: any, project: record, task: record, time_card_line_id: int, total_hours_spent: any>, timecard_id: int, total_hours: any, week_beginning: string>"
    get-sell-order-list-of-workgroup: "record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, project: record, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>"
    get-sell-order-of-workgroup: "record<result: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: list<record>, classification: string, closed_date: string, closing_change_orders: list<record>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list<record>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: list<record>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, status_code: int, status_reason: string>"
    get-spec-template-list: "record<results: table<created_by: record, created_date: string, is_active: bool, is_externally_published: bool, is_locked: bool, last_updated_date: string, spec_template_id: int, spec_template_name: string>, status_code: int, status_reason: string>"
    get-spec-template: "record<result: record<created_by: record<email: string, first_name: string, last_name: string, middle_name: string>, created_date: string, is_active: bool, is_externally_published: bool, is_locked: bool, last_updated_date: string, product_type: string, product_type_info: record<label: string, product_type_id: int>, spec_template_id: int, spec_template_name: string, spec_type: record<spec_type_id: int, spec_type_name: string>>, status_code: int, status_reason: string>"
    get-v1-workgroups-workgroup-id-spec-types-spec-type-id-spec-type-fields: "record<result: table<data_type: string, param_name: string>, status_code: int, status_reason: string>"
    get-supplier-workgroup-list: "record<result: table<bu_supplier_workgroup_id: int, bu_supplier_workgroup_name: string, client_workgroup_id: int, client_workgroup_name: string, is_approved: bool, supplier_code: string, supplier_workgroup_id: int, supplier_workgroup_name: string>, status_code: int, status_reason: string>"
    get-supplier-workgroup-detail: "record<result: record<additional_workgroups_contain_same_supplier: list<record>, bu_supplier_workgroup_id: int, bu_supplier_workgroup_name: string, client_workgroup_id: int, client_workgroup_name: string, is_approved: bool, supplier_code: string, supplier_workgroup_id: int, supplier_workgroup_name: string>, status_code: int, status_reason: string>"
    get-task-types-of-workgroup: "record<results: table<task_type: string, task_type_id: int>, status_code: int, status_reason: string>"
    get-task-list-of-workgroup: "record<results: table<actual_end: string, actual_hours: any, actual_start: string, assign_to: record, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, current_duration: any, is_milestone: bool, mod_date: string, plan_end: string, plan_start: string, priority: string, project: record, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>"
    get-task-of-workgroup: "record<result: record<actual_duration: any, actual_end: string, actual_hours: any, actual_start: string, assign_to: record<email: string, first_name: string, last_name: string, middle_name: string>, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, comments: string, create_date: string, creator_workgroup_name: string, current_duration: any, description: string, is_milestone: bool, last_updated_by: record<email: string, first_name: string, last_name: string, middle_name: string>, mod_date: string, percent_complete: int, plan_duration: any, plan_end: string, plan_start: string, priority: string, project: record<project_id: int, project_name: string, project_number: string>, requested_by: record<email: string, first_name: string, last_name: string, middle_name: string>, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>"
    get-team-template-list: "record<results: table<team_template_id: int, team_template_name: string>, status_code: int, status_reason: string>"
    get-team-template-detail: "record<results: record<team_teample_item: list<record>, team_template_id: int, team_template_name: string>, status_code: int, status_reason: string>"
    get-workgroup-member-list: "record<results: table<email: string, first_name: string, last_name: string, user_id: int>, status_code: int, status_reason: string>"
    get-workgroup-member-info: "record<result: record<address: any, company_name: string, email: string, fax_number: string, first_name: string, last_name: string, locale: string, middle_name: string, organization: string, phone_number: string, time_zone: string, title: string, user_id: int>, status_code: int, status_reason: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-file-tags" "get-files" "upload-file" "get-file" "get-spec" "put-spec" "post-team-member-of-project" "get-spec-type-fields" "get-country-list" "get-workgroup-list" "get-automatic-invitation-list" "get-billing-recipients" "get-buy-order-list-of-workgroup" "get-buy-order-of-workgroup" "get-client-workgroup-list" "get-specific-client-workgroup" "get-project-category-list-of-client" "get-project-home-user-field-list-of-client" "get-project-status-of-client" "get-contact-list" "get-contact-user-info" "get-wg-task-status-list-of-workgroup" "get-custom-task-types-of-wg" "get-deactivation-reason-list" "task-priority-list" "get-default-task-status-list" "get-workgroup-detail" "put-workgroup" "get-exchange-rate-list" "post-exchange-rate" "get-my-time-card-list" "get-my-time-card" "get-product-type-list-of-workgroup" "get-spec-product-type-list-of-workgroup" "post-spec-product-type-list-of-workgroup" "upload-profile-image" "get-project-category-list" "get-project-home-user-fields-list" "get-project-status" "get-project-list" "post-project" "delete-project" "get-project" "patch-project" "put-project" "get-buy-order-list" "post-buy-order" "get-buy-order" "put-buy-order" "attach-project" "get-estimate-list" "post-estimate" "get-estimate" "get-invoices" "get-invoice" "get-invoice-files" "get-member-roles" "get-order" "get-quote-list" "get-quote" "put-quote" "get-rfe-list" "post-rfe" "get-rfe" "get-rfq-list" "get-rfq" "get-sell-order-list" "get-sell-order" "put-sell-order" "get-shipment-list" "post-shipment" "get-shipment" "put-shipment-location" "get-spec-list" "post-spec" "get-v1-workgroups-workgroup-id-projects-project-id-specs-spec-id" "put-v1-workgroups-workgroup-id-projects-project-id-specs-spec-id" "get-task-list-of-project" "post-task-for-project" "get-task-of-project" "get-team-member-list-of-client-project" "get-team-member-list-of-project" "post-v1-workgroups-workgroup-id-projects-project-id-teammembers" "delete-team-member-of-project" "get-quote-state-list" "get-v1-workgroups-workgroup-id-quotes" "get-received-time-card-list" "get-received-time-card" "get-sell-order-list-of-workgroup" "get-sell-order-of-workgroup" "get-spec-template-list" "get-spec-template" "get-v1-workgroups-workgroup-id-spec-types-spec-type-id-spec-type-fields" "get-supplier-workgroup-list" "get-supplier-workgroup-detail" "get-task-types-of-workgroup" "get-task-list-of-workgroup" "get-task-of-workgroup" "get-team-template-list" "get-team-template-detail" "get-workgroup-member-list" "get-workgroup-member-info" "commands"] | sort) } | get name | first)
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

# List Tags from Workgroup and Project.
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/fileTags
# Returns: record<result: table<isSpec: bool, tagId: int, tagName: string>, status_code: int, status_reason: string>
# operationId: getFileTags
export def "get-file-tags" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/1.1/workgroups/{workgroup_id}/projects/{project_id}/fileTags"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Files from Project. Works for Regular and Remote Files
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/files
# Returns: record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>
# operationId: getFiles
export def "get-files" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/1.1/workgroups/{workgroup_id}/projects/{project_id}/files"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Upload File to Project. A multipart/form-data request with a name "file"
#
# POST /1.1/workgroups/{workgroup_id}/projects/{project_id}/files
# Returns: record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>
# operationId: uploadFile
export def "upload-file" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/1.1/workgroups/{workgroup_id}/projects/{project_id}/files"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "multipart/form-data", kind: multipart, accepts: scalar}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get File from Project. Works for Regular and Remote Files
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/files/{file_id}
# Returns: record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>
# operationId: getFile
export def "get-file" [
  workgroup_id: string
  project_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/1.1/workgroups/{workgroup_id}/projects/{project_id}/files/{file_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: file_id, var: file_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a specific spec of project Level
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
# Returns: record<result: record<client_status: string, create_date: string, created_by: record<email: string, first_name: string, last_name: string, middle_name: string>, first_level_custom_fields: record<property_attributes: list, property_id: int, property_name: string>, header_custom_fields: record<property_attributes: list, property_id: int, property_name: string>, job_id: int, last_updated: string, product_type: string, product_type_info: record<label: string, product_type_id: int>, quantity_1: int, quantity_2: int, quantity_3: int, quantity_4: int, quantity_5: int, reference_number: string, second_level_custom_fields: list<record>, sku: string, spec_id: int, spec_name: string, spec_options: list<record>, spec_options_complete: list<record>, spec_original: record<spec_id: int, spec_name: string>, spec_type: record<spec_type_id: int, spec_type_name: string>, supplier_status: string, uofms: list<record>, user_state: string>, status_code: int, status_reason: string>
# operationId: getSpec
export def "get-spec" [
  workgroup_id: string
  project_id: string
  spec_id: string
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
    path: "/1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: spec_id, var: spec_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific Spec
#
# PUT /1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
# Returns: record<spec_id: int, spec_name: string, status_code: int, status_reason: string>
# operationId: putSpec
export def "put-spec" [
  workgroup_id: string
  project_id: string
  spec_id: string
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
  --first-level-custom-fields: any # Java type: com.noosh.domain.nooshapi.persist.po.v1x1.V1x1ProperyPO — shape: {property_attributes?: list, property_id?: int, property_name?: string}
  --header-custom-fields: any # Java type: com.noosh.domain.nooshapi.persist.po.v1x1.V1x1ProperyPO — shape: {property_attributes?: list, property_id?: int, property_name?: string}
  --product-type-id: int # format: int64, e.g. 1
  --quantity-1: int # format: int64, e.g. 1
  --quantity-2: int # format: int64, e.g. 1
  --quantity-3: int # format: int64, e.g. 1
  --quantity-4: int # format: int64, e.g. 1
  --quantity-5: int # format: int64, e.g. 1
  --second-level-custom-fields: list # item shape: {property_attributes?: list, property_id?: int, property_name?: string}
  --sku: string # e.g. sample sku
  --spec-name: string # e.g. sample spec_name
  --spec-type-id: int # format: int64, e.g. 1
  --versions: list # item shape: {description?: string, qty?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: spec_id, var: spec_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: first_level_custom_fields, var: first_level_custom_fields}, {name: header_custom_fields, var: header_custom_fields}, {name: product_type_id, var: product_type_id}, {name: quantity_1, var: quantity_1}, {name: quantity_2, var: quantity_2}, {name: quantity_3, var: quantity_3}, {name: quantity_4, var: quantity_4}, {name: quantity_5, var: quantity_5}, {name: second_level_custom_fields, var: second_level_custom_fields}, {name: sku, var: sku}, {name: spec_name, var: spec_name}, {name: spec_type_id, var: spec_type_id}, {name: versions, var: versions}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id, first_level_custom_fields: $first_level_custom_fields, header_custom_fields: $header_custom_fields, product_type_id: $product_type_id, quantity_1: $quantity_1, quantity_2: $quantity_2, quantity_3: $quantity_3, quantity_4: $quantity_4, quantity_5: $quantity_5, second_level_custom_fields: $second_level_custom_fields, sku: $sku, spec_name: $spec_name, spec_type_id: $spec_type_id, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Invite a team member or all the members of team template for the specific project.
#
# POST /1.1/workgroups/{workgroup_id}/projects/{project_id}/teammembers
# Returns: record<results: table<role: record, team_member_id: int, user: record, was_invited_before: bool>, status_code: int, status_reason: string>
# operationId: postTeamMemberOfProject
export def "post-team-member-of-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --role-id: int # format: int64, e.g. 1
  --team-template-id: int # format: int64, e.g. 1
  --user-id: int # format: int64, e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/1.1/workgroups/{workgroup_id}/projects/{project_id}/teammembers"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: role_id, var: role_id}, {name: team_template_id, var: team_template_id}, {name: user_id, var: user_id}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, role_id: $role_id, team_template_id: $team_template_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Spec Type Fields
#
# GET /1.1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields
# Returns: record<result: any, status_code: int, status_reason: string>
# operationId: getSpecTypeFields
export def "get-spec-type-fields" [
  workgroup_id: string
  spec_type_id: string
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
    path: "/1.1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: spec_type_id, var: spec_type_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, spec_type_id: $spec_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all countries
#
# GET /v1/countries
# Returns: record<result: table<constant_token: string, country: string, country_id: int>, status_code: int, status_reason: string>
# operationId: getCountryList
export def "get-country-list" [
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
    path: "/v1/countries"
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the workgroups
#
# GET /v1/workgroups
# Returns: record<results: table<is_default: bool, parent_workgroup: record, workgroup_id: int, workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getWorkgroupList
export def "get-workgroup-list" [
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
  --workgroup-name: string # Workgroup Name
  --workgroup-types: list<string> # 1000001 for Buyer, 1000002 for supplier, 1000003 for agent, 1000004 for Broker/Outsourcer and 1000005 for Partner
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups"
    query: [{name: workgroup_name, var: workgroup_name}, {name: workgroup_types, var: workgroup_types, style: csv}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_name: $workgroup_name, workgroup_types: $workgroup_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List current user's automatic invitations info
#
# GET /v1/workgroups/{workgroup_id}/automaticInvitations
# Returns: record<results: table<automatic_invitation_type_name: string, team_template: record>, status_code: int, status_reason: string>
# operationId: getAutomaticInvitationList
export def "get-automatic-invitation-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/automaticInvitations"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Billing Recipients
#
# GET /v1/workgroups/{workgroup_id}/billingRecipients
# Returns: record<results: table<address: string, company_name: string, email: string, first_name: string, last_name: string, primary_phone: string, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getBillingRecipients
export def "get-billing-recipients" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/billingRecipients"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the buy orders of workgroup
#
# GET /v1/workgroups/{workgroup_id}/buyOrders
# Returns: record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, project: record, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>
# operationId: getBuyOrderListOfWorkgroup
export def "get-buy-order-list-of-workgroup" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/buyOrders"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific buy order of workgroup
#
# GET /v1/workgroups/{workgroup_id}/buyOrders/{order_id}
# Returns: record<result: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: list<record>, classification: string, closed_date: string, closing_change_orders: list<record>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list<record>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: list<record>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, status_code: int, status_reason: string>
# operationId: getBuyOrderOfWorkgroup
export def "get-buy-order-of-workgroup" [
  workgroup_id: string
  order_id: string
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
    path: "/v1/workgroups/{workgroup_id}/buyOrders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: order_id, var: order_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List client workgroups
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups
# Returns: record<results: table<client_ac_workgroup_id: int, client_workgroup_id: int, client_workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getClientWorkgroupList
export def "get-client-workgroup-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/clientWorkgroups"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific client workgroups
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}
# Returns: record<result: record<client_ac_workgroup_id: int, client_workgroup_id: int, client_workgroup_name: string, custom_fields: list<record>, margin_percent: any, markup: any, markup_percent: any>, status_code: int, status_reason: string>
# operationId: getSpecificClientWorkgroup
export def "get-specific-client-workgroup" [
  workgroup_id: string
  client_workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: client_workgroup_id, var: client_workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the project categories of client side
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectCategory
# Returns: record<results: table<project_category_id: int, project_category_name: string>, status_code: int, status_reason: string>
# operationId: getProjectCategoryListOfClient
export def "get-project-category-list-of-client" [
  workgroup_id: string
  client_workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectCategory"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: client_workgroup_id, var: client_workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List projec home user fields of client workgroup
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectHomeUserFields
# Returns: record<results: table<is_required: bool, label: string, ordinal_number: int, param_name: string, type: string, user_field_id: int>, status_code: int, status_reason: string>
# operationId: getProjectHomeUserFieldListOfClient
export def "get-project-home-user-field-list-of-client" [
  workgroup_id: string
  client_workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectHomeUserFields"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: client_workgroup_id, var: client_workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the project status of client
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectStatus
# Returns: record<results: table<project_status_id: int, project_status_name: string>, status_code: int, status_reason: string>
# operationId: getProjectStatusOfClient
export def "get-project-status-of-client" [
  workgroup_id: string
  client_workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectStatus"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: client_workgroup_id, var: client_workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the contacts
#
# GET /v1/workgroups/{workgroup_id}/contacts
# Returns: record<results: table<address: string, company_name: string, email: string, first_name: string, last_name: string, primary_phone: string, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getContactList
export def "get-contact-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/contacts"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Contact Info
#
# GET /v1/workgroups/{workgroup_id}/contacts/{user_id}
# Returns: record<result: record<address: any, company_name: string, email: string, fax_number: string, first_name: string, last_name: string, locale: string, middle_name: string, organization: string, phone_number: string, time_zone: string, title: string, user_id: int>, status_code: int, status_reason: string>
# operationId: getContactUserInfo
export def "get-contact-user-info" [
  workgroup_id: string
  user_id: string
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
    path: "/v1/workgroups/{workgroup_id}/contacts/{user_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: user_id, var: user_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get custom task status of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/customTaskStatus
# Returns: record<result: table<description: string, is_active: bool, is_default: bool, task_status_name: string, tasks_status_id: int>, status_code: int, status_reason: string>
# operationId: getWgTaskStatusListOfWorkgroup
export def "get-wg-task-status-list-of-workgroup" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/customTaskStatus"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get custom task types of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/customTaskTypes
# Returns: record<results: table<task_type: string, task_type_id: int>, status_code: int, status_reason: string>
# operationId: getCustomTaskTypesOfWg
export def "get-custom-task-types-of-wg" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/customTaskTypes"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all deactivation reasons
#
# GET /v1/workgroups/{workgroup_id}/deactivationReasons
# Returns: record<results: table<deactivation_reason_id: int, deactivation_reason_name: string>, status_code: int, status_reason: string>
# operationId: getDeactivationReasonList
export def "get-deactivation-reason-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/deactivationReasons"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get default task priority list
#
# GET /v1/workgroups/{workgroup_id}/defaultTaskPriority
# Returns: record<results: table<task_priority_id: int, task_priority_name: string>, status_code: int, status_reason: string>
# operationId: TaskPriorityList
export def "task-priority-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/defaultTaskPriority"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get default task status list
#
# GET /v1/workgroups/{workgroup_id}/defaultTaskStatus
# Returns: record<results: table<task_status_id: int, task_status_name: string>, status_code: int, status_reason: string>
# operationId: getDefaultTaskStatusList
export def "get-default-task-status-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/defaultTaskStatus"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Detail workgroup info
#
# GET /v1/workgroups/{workgroup_id}/detail
# Returns: record<result: record<address_line1: string, address_line2: string, address_line3: string, city: string, country: string, country_code: string, custom_fields: list<record>, default_currency: string, portal: string, postal: string, state: string, workgroup_id: int, workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getWorkgroupDetail
export def "get-workgroup-detail" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/detail"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific Workgroup
#
# PUT /v1/workgroups/{workgroup_id}/detail
# Returns: record<status_code: int, status_reason: string, workgroup_id: int, workgroup_name: string>
# operationId: putWorkgroup
export def "put-workgroup" [
  workgroup_id: string
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
  --address-line1: string # e.g. sample address_line1
  --address-line2: string # e.g. sample address_line2
  --address-line3: string # e.g. sample address_line3
  --city: string # e.g. sample city
  --country: string # e.g. sample country
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --decimal-places: int # format: int64, e.g. 1
  --postal: string # e.g. sample postal
  --state: string # e.g. sample state
  --workgroup-name: string # e.g. sample workgroup_name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/workgroups/{workgroup_id}/detail"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_line1, var: address_line1}, {name: address_line2, var: address_line2}, {name: address_line3, var: address_line3}, {name: city, var: city}, {name: country, var: country}, {name: custom_fields, var: custom_fields}, {name: decimal_places, var: decimal_places}, {name: postal, var: postal}, {name: state, var: state}, {name: workgroup_name, var: workgroup_name}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, address_line1: $address_line1, address_line2: $address_line2, address_line3: $address_line3, city: $city, country: $country, custom_fields: $custom_fields, decimal_places: $decimal_places, postal: $postal, state: $state, workgroup_name: $workgroup_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Exchange Rate List
#
# GET /v1/workgroups/{workgroup_id}/exchangeRate
# Returns: record<status_code: int, status_reason: string>
# operationId: getExchangeRateList
export def "get-exchange-rate-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/exchangeRate"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Exchange Rates
#
# POST /v1/workgroups/{workgroup_id}/exchangeRate
# operationId: postExchangeRate
export def "post-exchange-rate" [
  workgroup_id: string
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
  --exchange-rates: list # item shape: {activate_date?: string, buClientWorkgroupId?: int, currency?: string, rate?: any, target?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/exchangeRate"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: exchange_rates, var: exchange_rates}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, exchange_rates: $exchange_rates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List my time cards
#
# GET /v1/workgroups/{workgroup_id}/myTimeCards
# Returns: record<results: table<is_submit: bool, last_updated_date: string, no_of_workdays: int, submit_date: string, timecard_id: int, total_hours: any, week_beginning: string>, status_code: int, status_reason: string>
# operationId: getMyTimeCardList
export def "get-my-time-card-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/myTimeCards"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific my time cards
#
# GET /v1/workgroups/{workgroup_id}/myTimeCards/{timeCard_id}
# Returns: record<billable_hours: any, is_submit: bool, last_updated_date: string, no_of_workdays: int, nonbillable_hours: any, submit_date: string, time_card_line: table<activity_name: string, day1_hours_spent: any, day2_hours_spent: any, day3_hours_spent: any, day4_hours_spent: any, day5_hours_spent: any, day6_hours_spent: any, day7_hours_spent: any, project: record, task: record, time_card_line_id: int, total_hours_spent: any>, timecard_id: int, total_hours: any, week_beginning: string>
# operationId: getMyTimeCard
export def "get-my-time-card" [
  workgroup_id: string
  time_card_id: string
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
    path: "/v1/workgroups/{workgroup_id}/myTimeCards/{timeCard_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: timeCard_id, var: time_card_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, time_card_id: $time_card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get product type of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/productTypes
# Returns: record<result: table<is_checked: bool, label: string, product_type_id: int>, status_code: int, status_reason: string>
# operationId: getProductTypeListOfWorkgroup
export def "get-product-type-list-of-workgroup" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/productTypes"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get product type of spec level by workgroupId
#
# GET /v1/workgroups/{workgroup_id}/productTypesOfSpecTypes
# Returns: record<result: table<is_checked: bool, label: string, product_type_id: int>, status_code: int, status_reason: string>
# operationId: getSpecProductTypeListOfWorkgroup
export def "get-spec-product-type-list-of-workgroup" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/productTypesOfSpecTypes"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Register product types for spec types
#
# POST /v1/workgroups/{workgroup_id}/productTypesOfSpecTypes
# Returns: record<enableDifferentiatePrdTypePreference: bool, spec_prdType_list: table<prdType_labels: list, spec_type_id: int>>
# operationId: postSpecProductTypeListOfWorkgroup
export def "post-spec-product-type-list-of-workgroup" [
  workgroup_id: string
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
  --enable-differentiate-prd-type-preference: oneof<nothing, bool> # e.g. false
  --spec-prd-type-list: list # item shape: {prdType_labels?: list<string>, spec_type_id?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/productTypesOfSpecTypes"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enableDifferentiatePrdTypePreference, var: enable_differentiate_prd_type_preference}, {name: spec_prdType_list, var: spec_prd_type_list}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, enable_differentiate_prd_type_preference: $enable_differentiate_prd_type_preference, spec_prd_type_list: $spec_prd_type_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Upload Profile Image. A multipart/form-data request with a name "file"
#
# POST /v1/workgroups/{workgroup_id}/profileImage
# Returns: record<profileImgUrl: string, status_code: int, status_reason: string>
# operationId: uploadProfileImage
export def "upload-profile-image" [
  workgroup_id: string
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
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/profileImage"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the project categories
#
# GET /v1/workgroups/{workgroup_id}/projectCategory
# Returns: record<results: table<project_category_id: int, project_category_name: string>, status_code: int, status_reason: string>
# operationId: getProjectCategoryList
export def "get-project-category-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projectCategory"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List projec home user fields
#
# GET /v1/workgroups/{workgroup_id}/projectHomeUserFields
# Returns: record<results: table<is_required: bool, label: string, ordinal_number: int, param_name: string, type: string, user_field_id: int>, status_code: int, status_reason: string>
# operationId: getProjectHomeUserFieldsList
export def "get-project-home-user-fields-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projectHomeUserFields"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the project status
#
# GET /v1/workgroups/{workgroup_id}/projectStatus
# Returns: record<results: table<project_status_id: int, project_status_name: string>, status_code: int, status_reason: string>
# operationId: getProjectStatus
export def "get-project-status" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projectStatus"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the projects
#
# GET /v1/workgroups/{workgroup_id}/projects
# Returns: record<results: table<client_account: string, client_workgroup_id: int, completion_date: string, is_active: bool, is_hot: bool, last_spec_update: string, project_id: int, project_name: string, project_number: string, project_status: string>, status_code: int, status_reason: string>
# operationId: getProjectList
export def "get-project-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Project
#
# POST /v1/workgroups/{workgroup_id}/projects
# Returns: record<project_id: int, status_code: int, status_reason: string>
# operationId: postProject
export def "post-project" [
  workgroup_id: string
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
  --client-account: string # e.g. sample client_account
  --client-user-id: int # format: int64, e.g. 1
  --client-workgroup-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --completion-date: string # format: date
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --deactivation-reason-id: int # format: int64, e.g. 1
  --is-active: oneof<nothing, bool> # e.g. false
  --is-hot: oneof<nothing, bool> # e.g. false
  --is-paper-direct: oneof<nothing, bool> # e.g. false
  --project-category-id: int # format: int64, e.g. 1
  --project-description: string # e.g. sample project_description
  --project-name: string # e.g. sample project_name
  --project-number: string # e.g. sample project_number
  --project-owner-user-id: int # format: int64, e.g. 1
  project_status_id: int # format: int64, e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_account, var: client_account}, {name: client_user_id, var: client_user_id}, {name: client_workgroup_id, var: client_workgroup_id}, {name: comments, var: comments}, {name: completion_date, var: completion_date}, {name: custom_fields, var: custom_fields}, {name: deactivation_reason_id, var: deactivation_reason_id}, {name: is_active, var: is_active}, {name: is_hot, var: is_hot}, {name: is_paper_direct, var: is_paper_direct}, {name: project_category_id, var: project_category_id}, {name: project_description, var: project_description}, {name: project_name, var: project_name}, {name: project_number, var: project_number}, {name: project_owner_user_id, var: project_owner_user_id}, {name: project_status_id, var: project_status_id}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, client_account: $client_account, client_user_id: $client_user_id, client_workgroup_id: $client_workgroup_id, comments: $comments, completion_date: $completion_date, custom_fields: $custom_fields, deactivation_reason_id: $deactivation_reason_id, is_active: $is_active, is_hot: $is_hot, is_paper_direct: $is_paper_direct, project_category_id: $project_category_id, project_description: $project_description, project_name: $project_name, project_number: $project_number, project_owner_user_id: $project_owner_user_id, project_status_id: $project_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Archieve a specific Project
#
# DELETE /v1/workgroups/{workgroup_id}/projects/{project_id}
# Returns: record<status_code: int, status_reason: string>
# operationId: deleteProject
export def "delete-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific Project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}
# Returns: record<result: record<category: string, client_account: string, client_user: string, client_user_id: int, client_workgroup_id: int, comments: string, completion_date: string, custom_fields: list<record>, deactivation_reason: string, is_active: bool, is_hot: bool, last_spec_update: string, mod_date: string, owner_workgroup: string, parent_project: record<client_account: string, client_user: string, client_user_id: int, client_workgroup_id: int, comments: string, created_by: record, project_create_date: string, project_description: string, project_id: int, project_name: string, project_number: string>, project_create_date: string, project_description: string, project_id: int, project_name: string, project_number: string, project_status: string, team_owners: string>, status_code: int, status_reason: string>
# operationId: getProject
export def "get-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Patch a specific Project
#
# PATCH /v1/workgroups/{workgroup_id}/projects/{project_id}
# Returns: record<status_code: int, status_reason: string>
# operationId: patchProject
export def "patch-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --client-user-id: int # format: int64, e.g. 1
  --client-workgroup-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --completion-date: string # format: date
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --deactivation-reason-id: int # format: int64, e.g. 1
  --is-active: oneof<nothing, bool> # e.g. false
  --is-hot: oneof<nothing, bool> # e.g. false
  --project-category-id: int # format: int64, e.g. 1
  --project-description: string # e.g. sample project_description
  --project-name: string # e.g. sample project_name
  --project-number: string # e.g. sample project_number
  --project-status-id: int # format: int64, e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_user_id, var: client_user_id}, {name: client_workgroup_id, var: client_workgroup_id}, {name: comments, var: comments}, {name: completion_date, var: completion_date}, {name: custom_fields, var: custom_fields}, {name: deactivation_reason_id, var: deactivation_reason_id}, {name: is_active, var: is_active}, {name: is_hot, var: is_hot}, {name: project_category_id, var: project_category_id}, {name: project_description, var: project_description}, {name: project_name, var: project_name}, {name: project_number, var: project_number}, {name: project_status_id, var: project_status_id}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, client_user_id: $client_user_id, client_workgroup_id: $client_workgroup_id, comments: $comments, completion_date: $completion_date, custom_fields: $custom_fields, deactivation_reason_id: $deactivation_reason_id, is_active: $is_active, is_hot: $is_hot, project_category_id: $project_category_id, project_description: $project_description, project_name: $project_name, project_number: $project_number, project_status_id: $project_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific Project
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}
# Returns: record<status_code: int, status_reason: string>
# operationId: putProject
export def "put-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --client-account: string # e.g. sample client_account
  --client-user-id: int # format: int64, e.g. 1
  --client-workgroup-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --completion-date: string # format: date
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --deactivation-reason-id: int # format: int64, e.g. 1
  --is-active: oneof<nothing, bool> # e.g. false
  --is-hot: oneof<nothing, bool> # e.g. false
  --is-paper-direct: oneof<nothing, bool> # e.g. false
  --project-category-id: int # format: int64, e.g. 1
  --project-description: string # e.g. sample project_description
  --project-name: string # e.g. sample project_name
  --project-number: string # e.g. sample project_number
  --project-owner-user-id: int # format: int64, e.g. 1
  project_status_id: int # format: int64, e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_account, var: client_account}, {name: client_user_id, var: client_user_id}, {name: client_workgroup_id, var: client_workgroup_id}, {name: comments, var: comments}, {name: completion_date, var: completion_date}, {name: custom_fields, var: custom_fields}, {name: deactivation_reason_id, var: deactivation_reason_id}, {name: is_active, var: is_active}, {name: is_hot, var: is_hot}, {name: is_paper_direct, var: is_paper_direct}, {name: project_category_id, var: project_category_id}, {name: project_description, var: project_description}, {name: project_name, var: project_name}, {name: project_number, var: project_number}, {name: project_owner_user_id, var: project_owner_user_id}, {name: project_status_id, var: project_status_id}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, client_account: $client_account, client_user_id: $client_user_id, client_workgroup_id: $client_workgroup_id, comments: $comments, completion_date: $completion_date, custom_fields: $custom_fields, deactivation_reason_id: $deactivation_reason_id, is_active: $is_active, is_hot: $is_hot, is_paper_direct: $is_paper_direct, project_category_id: $project_category_id, project_description: $project_description, project_name: $project_name, project_number: $project_number, project_owner_user_id: $project_owner_user_id, project_status_id: $project_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the buy orders
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders
# Returns: record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>
# operationId: getBuyOrderList
export def "get-buy-order-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a quick buy order
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders
# Returns: record<buyer_user_id: int, comments: string, custom_fields: table<date_value: string, number_value: any, param_name: string, string_value: string>, invoice_or_billing_recipient: int, order_completion_date: string, order_items: table<completion_date: string, custom_fields: list, ex_tax_value_calculated: any, notes: string, per: int, price: any, quantity: any, shipping: any, spec_id: int, spec_reference_id: int, tax: string>, other_selection_reason: string, payment_method_id: int, payment_reference_no: string, sellOrder: bool, shipping: any, supplier_reference: string, supplier_selection_reason_id: int, supplier_user_id: int, tax: string, title: string>
# operationId: postBuyOrder
export def "post-buy-order" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --buyer-user-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --invoice-or-billing-recipient: int # format: int64, e.g. 1
  --order-completion-date: string # format: date
  --order-items: list # item shape: {completion_date?: string, custom_fields?: list, ex_tax_value_calculated?: any, notes?: string, per?: int, price?: any, quantity?: any, shipping?: any, spec_id?: int, spec_reference_id?: int, tax?: string}
  --other-selection-reason: string # e.g. sample other_selection_reason
  --payment-method-id: int # format: int64, e.g. 1
  --payment-reference-no: string # e.g. sample payment_reference_no
  --sell-order: oneof<nothing, bool> # e.g. false
  --shipping: any # Java type: java.math.BigDecimal
  --supplier-reference: string # e.g. sample supplier_reference
  --supplier-selection-reason-id: int # format: int64, e.g. 1
  --supplier-user-id: int # format: int64, e.g. 1
  --tax: string # e.g. sample tax
  --title: string # e.g. sample title
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: buyer_user_id, var: buyer_user_id}, {name: comments, var: comments}, {name: custom_fields, var: custom_fields}, {name: invoice_or_billing_recipient, var: invoice_or_billing_recipient}, {name: order_completion_date, var: order_completion_date}, {name: order_items, var: order_items}, {name: other_selection_reason, var: other_selection_reason}, {name: payment_method_id, var: payment_method_id}, {name: payment_reference_no, var: payment_reference_no}, {name: sellOrder, var: sell_order}, {name: shipping, var: shipping}, {name: supplier_reference, var: supplier_reference}, {name: supplier_selection_reason_id, var: supplier_selection_reason_id}, {name: supplier_user_id, var: supplier_user_id}, {name: tax, var: tax}, {name: title, var: title}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, buyer_user_id: $buyer_user_id, comments: $comments, custom_fields: $custom_fields, invoice_or_billing_recipient: $invoice_or_billing_recipient, order_completion_date: $order_completion_date, order_items: $order_items, other_selection_reason: $other_selection_reason, payment_method_id: $payment_method_id, payment_reference_no: $payment_reference_no, sell_order: $sell_order, shipping: $shipping, supplier_reference: $supplier_reference, supplier_selection_reason_id: $supplier_selection_reason_id, supplier_user_id: $supplier_user_id, tax: $tax, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific buy order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}
# Returns: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>
# operationId: getBuyOrder
export def "get-buy-order" [
  workgroup_id: string
  project_id: string
  order_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: order_id, var: order_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific buy order
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}
# Returns: record<order_id: int, status_code: int, status_reason: string>
# operationId: putBuyOrder
export def "put-buy-order" [
  workgroup_id: string
  project_id: string
  order_id: string
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
  --action: string # accept or reject (e.g. sample action)
  --budget-type-field-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --order-completion-date: string # format: date
  --body-order-id: int # format: int64, e.g. 1 (spec name: order_id)
  --other-selection-reason: string # e.g. sample other_selection_reason
  --overs-percent: any # Java type: java.math.BigDecimal
  --payment-method-id: int # format: int64, e.g. 1
  --payment-reference-no: string # e.g. sample payment_reference_no
  --reject-reason: string # e.g. sample reject_reason
  --supplier-selection-reason-id: int # format: int64, e.g. 1
  --unders-percent: any # Java type: java.math.BigDecimal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: order_id, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: budget_type_field_id, var: budget_type_field_id}, {name: comments, var: comments}, {name: custom_fields, var: custom_fields}, {name: order_completion_date, var: order_completion_date}, {name: order_id, var: body_order_id}, {name: other_selection_reason, var: other_selection_reason}, {name: overs_percent, var: overs_percent}, {name: payment_method_id, var: payment_method_id}, {name: payment_reference_no, var: payment_reference_no}, {name: reject_reason, var: reject_reason}, {name: supplier_selection_reason_id, var: supplier_selection_reason_id}, {name: unders_percent, var: unders_percent}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id, action: $action, budget_type_field_id: $budget_type_field_id, comments: $comments, custom_fields: $custom_fields, order_completion_date: $order_completion_date, body_order_id: $body_order_id, other_selection_reason: $other_selection_reason, overs_percent: $overs_percent, payment_method_id: $payment_method_id, payment_reference_no: $payment_reference_no, reject_reason: $reject_reason, supplier_selection_reason_id: $supplier_selection_reason_id, unders_percent: $unders_percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Attach children projects to specific Project
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/children
# Returns: record<status_code: int, status_reason: string>
# operationId: attachProject
export def "attach-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --child-project-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/children"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: childProjectIds, var: child_project_ids}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, child_project_ids: $child_project_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the Estimates
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/estimates
# Returns: record<result: table<create_date: string, currency: string, estimate_id: int, estimate_title: string, expiration_date: string, project: record, rfe: record, status: string, submit_date: string, supplier_workgroup: record, transactional_currency: string>, status_code: int, status_reason: string>
# operationId: getEstimateList
export def "get-estimate-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/estimates"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Estimate
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/estimates
# Returns: record<comments: string, description: string, estimate_items: table<paper_items: list, quantity_1_price: any, quantity_1_shipping: any, quantity_1_tax: any, quantity_2_price: any, quantity_2_shipping: any, quantity_2_tax: any, quantity_3_price: any, quantity_3_shipping: any, quantity_3_tax: any, quantity_4_price: any, quantity_4_shipping: any, quantity_4_tax: any, quantity_5_price: any, quantity_5_shipping: any, quantity_5_tax: any, rfe_item_id: int>, estimate_title: string, expiration_date: string, owner_reference: string, rfe_id: int>
# operationId: postEstimate
export def "post-estimate" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --comments: string # e.g. sample comments
  --description: string # e.g. sample description
  --estimate-items: list # item shape: {paper_items?: list, quantity_1_price?: any, quantity_1_shipping?: any, quantity_1_tax?: any, quantity_2_price?: any, quantity_2_shipping?: any, quantity_2_tax?: any, quantity_3_price?: any, quantity_3_shipping?: any, quantity_3_tax?: any, quantity_4_price?: any, quantity_4_shipping?: any, quantity_4_tax?: any, quantity_5_price?: any, quantity_5_shipping?: any, quantity_5_tax?: any, rfe_item_id?: int}
  --estimate-title: string # e.g. sample estimate_title
  --expiration-date: string # format: date
  --owner-reference: string # e.g. sample owner_reference
  --rfe-id: int # format: int64, e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/estimates"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comments, var: comments}, {name: description, var: description}, {name: estimate_items, var: estimate_items}, {name: estimate_title, var: estimate_title}, {name: expiration_date, var: expiration_date}, {name: owner_reference, var: owner_reference}, {name: rfe_id, var: rfe_id}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, comments: $comments, description: $description, estimate_items: $estimate_items, estimate_title: $estimate_title, expiration_date: $expiration_date, owner_reference: $owner_reference, rfe_id: $rfe_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific estimate of project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/estimates/{estimate_id}
# Returns: record<result: record<comments: string, create_date: string, currency: string, custom_fields: list<record>, description: string, estimate_id: int, estimate_title: string, expiration_date: string, items: list<record>, project: record<project_id: int, project_name: string, project_number: string>, reference_number: string, rfe: record<rfe_due_date: string, rfe_id: int, rfe_title: string, status: string>, status: string, submit_date: string, submitted_by: string, submitted_by_user_id: int, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, transactional_currency: string>, status_code: int, status_reason: string>
# operationId: getEstimate
export def "get-estimate" [
  workgroup_id: string
  project_id: string
  estimate_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/estimates/{estimate_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: estimate_id, var: estimate_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, estimate_id: $estimate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List invoices by a specific order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/orders/{order_id}
# Returns: record<result: table<comments: string, currency: string, custom_fields: list, grand_total: any, invoice_date: string, invoice_due_date: string, invoice_id: int, invoice_number: string, invoice_to: string, is_final: int, is_nonBillable: int, items: list, order_reference: string, order_title: string, payment_method: string, prepared_by: string, project_number: int, reference_number: string, shipping: any, status: string, sub_total: any, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_shipping: any, transactional_sub_total: any, transactional_tax: any>, status_code: int, status_reason: string>
# operationId: getInvoices
export def "get-invoices" [
  workgroup_id: string
  project_id: string
  order_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/orders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: order_id, var: order_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a specific invoice of project Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}
# Returns: record<result: record<comments: string, currency: string, custom_fields: list<record>, grand_total: any, invoice_date: string, invoice_due_date: string, invoice_id: int, invoice_number: string, invoice_to: string, is_final: int, is_nonBillable: int, items: list<record>, order_reference: string, order_title: string, payment_method: string, prepared_by: string, project_number: int, reference_number: string, shipping: any, status: string, sub_total: any, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_shipping: any, transactional_sub_total: any, transactional_tax: any>, status_code: int, status_reason: string>
# operationId: getInvoice
export def "get-invoice" [
  workgroup_id: string
  project_id: string
  invoice_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: invoice_id, var: invoice_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List files of invoice Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}/files
# Returns: record<result: table<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string>
# operationId: getInvoiceFiles
export def "get-invoice-files" [
  workgroup_id: string
  project_id: string
  invoice_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}/files"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: invoice_id, var: invoice_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all the role options for the user
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/memberroles/{user_id}
# Returns: record<result: table<role_id: int, role_name: string>, status_code: int, status_reason: string>
# operationId: getMemberRoles
export def "get-member-roles" [
  workgroup_id: string
  project_id: string
  user_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/memberroles/{user_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: user_id, var: user_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific buy/sell order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/orders/{order_id}
# Returns: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, is_sell_order: bool, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>
# operationId: getOrder
export def "get-order" [
  workgroup_id: string
  project_id: string
  order_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/orders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: order_id, var: order_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the quotes
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/quotes
# Returns: record<result: table<currency: string, grand_total: any, quote_id: int, quote_title: string, rfq: record, status: string, submit_date: string, transactional_currency: string, transactional_grand_total: any>, status_code: int, status_reason: string>
# operationId: getQuoteList
export def "get-quote-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --quote-state-id-use-filters-quote-state-id-111111: string # Quote Object State Id, use /workgroups/{workgroup_id}/quoteStates to get correct value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/quotes"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    query: [{name: "quote_state_id, use filters={\"quote_state_id\":111111}", var: quote_state_id_use_filters_quote_state_id_111111}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, quote_state_id_use_filters_quote_state_id_111111: $quote_state_id_use_filters_quote_state_id_111111
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific quote of project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}
# Returns: record<result: record<client: string, client_user_id: int, comments: string, creator_user_id: int, currency: string, custom_fields: list<record>, description: string, grand_total: any, is_show_supplier_information: bool, last_update_by_user_id: int, proposed_order_completion_date: string, quote_expiration_date: string, quote_id: int, quote_items: list<record>, quote_items_total: any, quote_title: string, shipping: any, status: string, submit_date: string, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_quote_items_total: any, transactional_shipping: any, transactional_tax: any, vat_code: string, vat_rate: any>, status_code: int, status_reason: string>
# operationId: getQuote
export def "get-quote" [
  workgroup_id: string
  project_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: quote_id, var: quote_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, quote_id: $quote_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Accept / Reject a Quote
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}
# Returns: record<status_code: int, status_reason: string>
# operationId: putQuote
export def "put-quote" [
  workgroup_id: string
  project_id: string
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
  --accept: string@accept-completer # Response content type
  --action: string # e.g. sample action
  --po-number: string # e.g. sample po_number
  --body-quote-id: int # format: int64, e.g. 1 (spec name: quote_id)
  --state-change-comments: string # e.g. sample state_change_comments
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: quote_id, var: quote_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: po_number, var: po_number}, {name: quote_id, var: body_quote_id}, {name: state_change_comments, var: state_change_comments}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, quote_id: $quote_id, action: $action, po_number: $po_number, body_quote_id: $body_quote_id, state_change_comments: $state_change_comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the RFES
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfes
# Returns: record<results: table<estimate_due_date: string, rfe_id: int, rfe_items: list, rfe_title: string, supplier_estimates: list>, status_code: int, status_reason: string>
# operationId: getRfeList
export def "get-rfe-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfes"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a RFE
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/rfes
# Returns: record<rfq_id: int, status_code: int, status_reason: string>
# operationId: postRfe
export def "post-rfe" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --description: string # e.g. sample description
  --details: string # e.g. sample details
  --estimate-due-date: string # format: date
  --proposed-order-completion-date: string # format: date
  --rfe-number: string # e.g. sample rfe_number
  --rfe-title: string # e.g. sample rfe_title
  --specs: list # item shape: {quantity_1?: int, quantity_2?: int, quantity_3?: int, quantity_4?: int, quantity_5?: int, spec_id?: int}
  --supplier-user-ids: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfes"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: details, var: details}, {name: estimate_due_date, var: estimate_due_date}, {name: proposed_order_completion_date, var: proposed_order_completion_date}, {name: rfe_number, var: rfe_number}, {name: rfe_title, var: rfe_title}, {name: specs, var: specs}, {name: supplier_user_ids, var: supplier_user_ids}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, description: $description, details: $details, estimate_due_date: $estimate_due_date, proposed_order_completion_date: $proposed_order_completion_date, rfe_number: $rfe_number, rfe_title: $rfe_title, specs: $specs, supplier_user_ids: $supplier_user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific Rfe
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfes/{rfe_id}
# Returns: record<result: record<description: string, details: string, estimate_due_date: string, estimators: list<string>, itemized_tax_and_shipping: int, proposed_order_completion_date: string, reference_number: string, requestor: string, rfe_id: int, rfe_items: list<record>, status: string, submitted_date: string, supplier_estimates: list<record>, title: string>, status_code: int, status_reason: string>
# operationId: getRfe
export def "get-rfe" [
  workgroup_id: string
  project_id: string
  rfe_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfes/{rfe_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: rfe_id, var: rfe_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, rfe_id: $rfe_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the rfqs
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs
# Returns: record<result: table<quotes: list, received_date: string, rfq_id: int, rfq_title: string, status: string>, status_code: int, status_reason: string>
# operationId: getRfqList
export def "get-rfq-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific Rfq
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs/{rfq_id}
# Returns: record<result: record<comments: string, description: string, proposed_completion_date: string, quote_due_date: string, quotes: list<record>, received_date: string, recipient_name: string, requestor_name: string, rfq_id: int, rfq_items: list<record>, rfq_title: string, status: string>, status_code: int, status_reason: string>
# operationId: getRfq
export def "get-rfq" [
  workgroup_id: string
  project_id: string
  rfq_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs/{rfq_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: rfq_id, var: rfq_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, rfq_id: $rfq_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the sell orders
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders
# Returns: record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>
# operationId: getSellOrderList
export def "get-sell-order-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific sell order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}
# Returns: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>
# operationId: getSellOrder
export def "get-sell-order" [
  workgroup_id: string
  project_id: string
  order_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: order_id, var: order_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update / Accept or Reject a specific sell order
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}
# Returns: record<order_id: int, status_code: int, status_reason: string>
# operationId: putSellOrder
export def "put-sell-order" [
  workgroup_id: string
  project_id: string
  order_id: string
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
  --action: string # accept or reject (e.g. sample action)
  --budget-type-field-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --order-completion-date: string # format: date
  --body-order-id: int # format: int64, e.g. 1 (spec name: order_id)
  --other-selection-reason: string # e.g. sample other_selection_reason
  --overs-percent: any # Java type: java.math.BigDecimal
  --payment-method-id: int # format: int64, e.g. 1
  --payment-reference-no: string # e.g. sample payment_reference_no
  --reject-reason: string # e.g. sample reject_reason
  --supplier-selection-reason-id: int # format: int64, e.g. 1
  --unders-percent: any # Java type: java.math.BigDecimal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: order_id, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: budget_type_field_id, var: budget_type_field_id}, {name: comments, var: comments}, {name: custom_fields, var: custom_fields}, {name: order_completion_date, var: order_completion_date}, {name: order_id, var: body_order_id}, {name: other_selection_reason, var: other_selection_reason}, {name: overs_percent, var: overs_percent}, {name: payment_method_id, var: payment_method_id}, {name: payment_reference_no, var: payment_reference_no}, {name: reject_reason, var: reject_reason}, {name: supplier_selection_reason_id, var: supplier_selection_reason_id}, {name: unders_percent, var: unders_percent}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id, action: $action, budget_type_field_id: $budget_type_field_id, comments: $comments, custom_fields: $custom_fields, order_completion_date: $order_completion_date, body_order_id: $body_order_id, other_selection_reason: $other_selection_reason, overs_percent: $overs_percent, payment_method_id: $payment_method_id, payment_reference_no: $payment_reference_no, reject_reason: $reject_reason, supplier_selection_reason_id: $supplier_selection_reason_id, unders_percent: $unders_percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List shipments of project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments
# Returns: record<result: table<locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record>, status_code: int, status_reason: string>
# operationId: getShipmentList
export def "get-shipment-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a shipment
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments
# Returns: record<results: table<location_id: int, shipment_id: int, spec_id: int>, status_code: int, status_reason: string>
# operationId: postShipment
export def "post-shipment" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --address-line1: string # e.g. sample address_line1
  --address-line2: string # e.g. sample address_line2
  --address-line3: string # e.g. sample address_line3
  --batch-label: string # e.g. sample batch_label
  --city: string # e.g. sample city
  --company-name: string # e.g. sample company_name
  --country-iso-code: string # e.g. sample country_iso_code
  --delivery-date: string # format: date
  --description-or-title: string # e.g. sample description_or_title
  --email: string # e.g. sample email
  --first-name: string # e.g. sample first_name
  --inner-carton-label: string # e.g. sample inner_carton_label
  --last-name: string # e.g. sample last_name
  --middle-name: string # e.g. sample middle_name
  --outer-carton-label: string # e.g. sample outer_carton_label
  --pallet-lablel: string # e.g. sample pallet_lablel
  --poof-type: string # e.g. sample poof_type
  --postal-code: string # e.g. sample postal_code
  --request-type: string # e.g. sample request_type
  --requested-quantity: int # format: int64, e.g. 1
  --shipment-custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --shipment-request-custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --shipping-carrier: string # e.g. sample shipping_carrier
  --shipping-instruction: string # e.g. sample shipping_instruction
  --shpping-method: string # e.g. sample shpping_method
  --spec-ids: string # e.g. sample spec_ids
  --state: string # e.g. sample state
  --work-phone-number: string # e.g. sample work_phone_number
  --workgroup-name: string # e.g. sample workgroup_name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_line1, var: address_line1}, {name: address_line2, var: address_line2}, {name: address_line3, var: address_line3}, {name: batch_label, var: batch_label}, {name: city, var: city}, {name: company_name, var: company_name}, {name: country_iso_code, var: country_iso_code}, {name: delivery_date, var: delivery_date}, {name: description_or_title, var: description_or_title}, {name: email, var: email}, {name: first_name, var: first_name}, {name: inner_carton_label, var: inner_carton_label}, {name: last_name, var: last_name}, {name: middle_name, var: middle_name}, {name: outer_carton_label, var: outer_carton_label}, {name: pallet_lablel, var: pallet_lablel}, {name: poof_type, var: poof_type}, {name: postal_code, var: postal_code}, {name: request_type, var: request_type}, {name: requested_quantity, var: requested_quantity}, {name: shipment_custom_fields, var: shipment_custom_fields}, {name: shipment_request_custom_fields, var: shipment_request_custom_fields}, {name: shipping_carrier, var: shipping_carrier}, {name: shipping_instruction, var: shipping_instruction}, {name: shpping_method, var: shpping_method}, {name: spec_ids, var: spec_ids}, {name: state, var: state}, {name: work_phone_number, var: work_phone_number}, {name: workgroup_name, var: workgroup_name}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, address_line1: $address_line1, address_line2: $address_line2, address_line3: $address_line3, batch_label: $batch_label, city: $city, company_name: $company_name, country_iso_code: $country_iso_code, delivery_date: $delivery_date, description_or_title: $description_or_title, email: $email, first_name: $first_name, inner_carton_label: $inner_carton_label, last_name: $last_name, middle_name: $middle_name, outer_carton_label: $outer_carton_label, pallet_lablel: $pallet_lablel, poof_type: $poof_type, postal_code: $postal_code, request_type: $request_type, requested_quantity: $requested_quantity, shipment_custom_fields: $shipment_custom_fields, shipment_request_custom_fields: $shipment_request_custom_fields, shipping_carrier: $shipping_carrier, shipping_instruction: $shipping_instruction, shpping_method: $shpping_method, spec_ids: $spec_ids, state: $state, work_phone_number: $work_phone_number, workgroup_name: $workgroup_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific shipment.
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}
# Returns: record<result: record<locations: list<record>, locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record<job_id: int, reference_number: string, spec_id: int, spec_name: string>>, resut: record<locations: list<record>, locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record<job_id: int, reference_number: string, spec_id: int, spec_name: string>>, status_code: int, status_reason: string>
# operationId: getShipment
export def "get-shipment" [
  workgroup_id: string
  project_id: string
  shipment_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: shipment_id, var: shipment_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, shipment_id: $shipment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific shipment location
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}/locations/{location_id}
# Returns: record<status_code: int, status_reason: string>
# operationId: putShipmentLocation
export def "put-shipment-location" [
  workgroup_id: string
  project_id: string
  shipment_id: string
  location_id: string
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
  --due-date: string # format: date
  --qty-received: int # format: int64, e.g. 1
  --qty-requested: int # format: int64, e.g. 1
  --qty-shipped: int # format: int64, e.g. 1
  --received-date: string # format: date
  --shipped-date: string # format: date
  --shipping-cost: any # Java type: java.math.BigDecimal
  --type: string # e.g. sample type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}/locations/{location_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: shipment_id, var: shipment_id}, {name: location_id, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: due_date, var: due_date}, {name: qty_received, var: qty_received}, {name: qty_requested, var: qty_requested}, {name: qty_shipped, var: qty_shipped}, {name: received_date, var: received_date}, {name: shipped_date, var: shipped_date}, {name: shipping_cost, var: shipping_cost}, {name: type, var: type}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, shipment_id: $shipment_id, location_id: $location_id, due_date: $due_date, qty_received: $qty_received, qty_requested: $qty_requested, qty_shipped: $qty_shipped, received_date: $received_date, shipped_date: $shipped_date, shipping_cost: $shipping_cost, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List specs of project Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/specs
# Returns: record<results: table<client_status: string, create_date: string, created_by: record, job_id: int, last_updated: string, reference_number: string, spec_id: int, spec_name: string, spec_options_complete: list, supplier_status: string, uofms: list, user_state: string>, status_code: int, status_reason: string>
# operationId: getSpecList
export def "get-spec-list" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Spec
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/specs
# Returns: record<spec_id: int, status_code: int, status_reason: string>
# operationId: postSpec
export def "post-spec" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --json-body: oneof<nothing, bool> # e.g. false
  --product-type-id: int # format: int64, e.g. 1
  --quantity-1: int # format: int64, e.g. 1
  --quantity-2: int # format: int64, e.g. 1
  --quantity-3: int # format: int64, e.g. 1
  --quantity-4: int # format: int64, e.g. 1
  --quantity-5: int # format: int64, e.g. 1
  --sku: string # e.g. sample sku
  --spec-name: string # e.g. sample spec_name
  --spec-template-id: int # format: int64, e.g. 1
  --spec-type-id: int # format: int64, e.g. 1
  --versions: list # item shape: {description?: string, qty?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: jsonBody, var: json_body}, {name: product_type_id, var: product_type_id}, {name: quantity_1, var: quantity_1}, {name: quantity_2, var: quantity_2}, {name: quantity_3, var: quantity_3}, {name: quantity_4, var: quantity_4}, {name: quantity_5, var: quantity_5}, {name: sku, var: sku}, {name: spec_name, var: spec_name}, {name: spec_template_id, var: spec_template_id}, {name: spec_type_id, var: spec_type_id}, {name: versions, var: versions}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, json_body: $json_body, product_type_id: $product_type_id, quantity_1: $quantity_1, quantity_2: $quantity_2, quantity_3: $quantity_3, quantity_4: $quantity_4, quantity_5: $quantity_5, sku: $sku, spec_name: $spec_name, spec_template_id: $spec_template_id, spec_type_id: $spec_type_id, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a specific spec of project Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
# Returns: record<results: table<client_status: string, create_date: string, created_by: record, job_id: int, last_updated: string, reference_number: string, spec_id: int, spec_name: string, spec_options_complete: list, supplier_status: string, uofms: list, user_state: string>, status_code: int, status_reason: string>
export def "get-v1-workgroups-workgroup-id-projects-project-id-specs-spec-id" [
  workgroup_id: string
  project_id: string
  spec_id: string
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
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: spec_id, var: spec_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a specific Spec
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
# Returns: record<spec_id: int, spec_name: string, status_code: int, status_reason: string>
export def "put-v1-workgroups-workgroup-id-projects-project-id-specs-spec-id" [
  workgroup_id: string
  project_id: string
  spec_id: string
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
  --inks-and-paper: list # item shape: {custom_fields?: list, paper_id?: int}
  --product-type-id: int # format: int64, e.g. 1
  --quantity-1: int # format: int64, e.g. 1
  --quantity-2: int # format: int64, e.g. 1
  --quantity-3: int # format: int64, e.g. 1
  --quantity-4: int # format: int64, e.g. 1
  --quantity-5: int # format: int64, e.g. 1
  --sku: string # e.g. sample sku
  --spec-name: string # e.g. sample spec_name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: spec_id, var: spec_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: inks_and_paper, var: inks_and_paper}, {name: product_type_id, var: product_type_id}, {name: quantity_1, var: quantity_1}, {name: quantity_2, var: quantity_2}, {name: quantity_3, var: quantity_3}, {name: quantity_4, var: quantity_4}, {name: quantity_5, var: quantity_5}, {name: sku, var: sku}, {name: spec_name, var: spec_name}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id, inks_and_paper: $inks_and_paper, product_type_id: $product_type_id, quantity_1: $quantity_1, quantity_2: $quantity_2, quantity_3: $quantity_3, quantity_4: $quantity_4, quantity_5: $quantity_5, sku: $sku, spec_name: $spec_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get task list of project level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/tasks
# Returns: record<results: table<actual_end: string, actual_hours: any, actual_start: string, assign_to: record, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, current_duration: any, is_milestone: bool, mod_date: string, plan_end: string, plan_start: string, priority: string, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>
# operationId: getTaskListOfProject
export def "get-task-list-of-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/tasks"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new task
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/tasks
# Returns: record<status_code: int, status_reason: string, task_id: int>
# operationId: postTaskForProject
export def "post-task-for-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  --actual-duration: float # format: double, e.g. 1.1
  --actual-duration-hour: float # format: double, e.g. 1.1
  --actual-end-date: string # format: date
  --actual-start-date: string # format: date
  --assign-to-user-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --contributors: string # e.g. sample contributors
  --custom-status-id: int # format: int64, e.g. 1
  --description: string # e.g. sample description
  --name: string # e.g. sample name
  --percentage-complete: int # format: int64, e.g. 1
  --priority: int # format: int64, e.g. 1
  --revised-duration: float # format: double, e.g. 1.1
  --revised-duration-hour: float # format: double, e.g. 1.1
  --revised-end-date: string # format: date
  --revised-start-date: string # format: date
  --status-id: int # format: int64, e.g. 1
  --task-id: int # format: int64, e.g. 1
  --task-type-id: int # format: int64, e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/tasks"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actual_duration, var: actual_duration}, {name: actual_duration_hour, var: actual_duration_hour}, {name: actual_end_date, var: actual_end_date}, {name: actual_start_date, var: actual_start_date}, {name: assign_to_user_id, var: assign_to_user_id}, {name: comments, var: comments}, {name: contributors, var: contributors}, {name: custom_status_id, var: custom_status_id}, {name: description, var: description}, {name: name, var: name}, {name: percentage_complete, var: percentage_complete}, {name: priority, var: priority}, {name: revised_duration, var: revised_duration}, {name: revised_duration_hour, var: revised_duration_hour}, {name: revised_end_date, var: revised_end_date}, {name: revised_start_date, var: revised_start_date}, {name: status_id, var: status_id}, {name: task_id, var: task_id}, {name: task_type_id, var: task_type_id}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, actual_duration: $actual_duration, actual_duration_hour: $actual_duration_hour, actual_end_date: $actual_end_date, actual_start_date: $actual_start_date, assign_to_user_id: $assign_to_user_id, comments: $comments, contributors: $contributors, custom_status_id: $custom_status_id, description: $description, name: $name, percentage_complete: $percentage_complete, priority: $priority, revised_duration: $revised_duration, revised_duration_hour: $revised_duration_hour, revised_end_date: $revised_end_date, revised_start_date: $revised_start_date, status_id: $status_id, task_id: $task_id, task_type_id: $task_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a sepcific task of project level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/tasks/{task_id}
# Returns: record<result: record<actual_duration: any, actual_end: string, actual_hours: any, actual_start: string, assign_to: record<email: string, first_name: string, last_name: string, middle_name: string>, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, comments: string, create_date: string, creator_workgroup_name: string, current_duration: any, description: string, is_milestone: bool, last_updated_by: record<email: string, first_name: string, last_name: string, middle_name: string>, mod_date: string, percent_complete: int, plan_duration: any, plan_end: string, plan_start: string, priority: string, requested_by: record<email: string, first_name: string, last_name: string, middle_name: string>, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>
# operationId: getTaskOfProject
export def "get-task-of-project" [
  workgroup_id: string
  project_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/tasks/{task_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: task_id, var: task_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List team member of client project side.
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/teamMembersOfClientProject
# Returns: record<results: table<company_name: string, name: string, phone: string, role: string, teammember_id: int, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getTeamMemberListOfClientProject
export def "get-team-member-list-of-client-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/teamMembersOfClientProject"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List team member of project.
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers
# Returns: record<results: table<company_name: string, name: string, phone: string, role: string, teammember_id: int, user_id: int, workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getTeamMemberListOfProject
export def "get-team-member-list-of-project" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deprecated, please use 1.1 Version
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers
# Returns: record<status_code: int, status_reason: string, teammember_id: int>
export def "post-v1-workgroups-workgroup-id-projects-project-id-teammembers" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
  role_id: int # format: int64, e.g. 1
  user_id: int # format: int64, e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: role_id, var: role_id}, {name: user_id, var: user_id}]}
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, role_id: $role_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a team member for the specific project.
#
# DELETE /v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers/{teammember_id}
# Returns: record<status_code: int, status_reason: string, teammember_id: int>
# operationId: deleteTeamMemberOfProject
export def "delete-team-member-of-project" [
  workgroup_id: string
  project_id: string
  teammember_id: string
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
    method: delete
    path: "/v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers/{teammember_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: project_id, var: project_id}, {name: teammember_id, var: teammember_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, project_id: $project_id, teammember_id: $teammember_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the quote states
#
# GET /v1/workgroups/{workgroup_id}/quoteStates
# Returns: record<results: table<object_state_id: int, object_state_name: string>, status_code: int, status_reason: string>
# operationId: getQuoteStateList
export def "get-quote-state-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/quoteStates"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the quotes of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/quotes
# Returns: record<currency: string, grand_total: any, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, quote_title: string, rfq: record<received_date: string, rfq_id: int, rfq_title: string, status: string>, status: string, submit_date: string, transactional_currency: string, transactional_grand_total: any>
export def "get-v1-workgroups-workgroup-id-quotes" [
  workgroup_id: string
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
  --quote-state-id-use-filters-quote-state-id-111111: string # Quote Object State Id, use /workgroups/{workgroup_id}/quoteStates to get correct value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/quotes"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    query: [{name: "quote_state_id, use filters={\"quote_state_id\":111111}", var: quote_state_id_use_filters_quote_state_id_111111}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, quote_state_id_use_filters_quote_state_id_111111: $quote_state_id_use_filters_quote_state_id_111111
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List received time cards
#
# GET /v1/workgroups/{workgroup_id}/receivedTimeCards
# Returns: record<results: table<is_submit: bool, last_updated_date: string, no_of_workdays: int, submit_date: string, timecard_id: int, total_hours: any, week_beginning: string>, status_code: int, status_reason: string>
# operationId: getReceivedTimeCardList
export def "get-received-time-card-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/receivedTimeCards"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a specific received time cards
#
# GET /v1/workgroups/{workgroup_id}/receivedTimeCards/{timeCard_id}
# Returns: record<billable_hours: any, is_submit: bool, last_updated_date: string, no_of_workdays: int, nonbillable_hours: any, owner: record<email: string, first_name: string, last_name: string, middle_name: string>, submit_date: string, time_card_line: table<activity_name: string, day1_hours_spent: any, day2_hours_spent: any, day3_hours_spent: any, day4_hours_spent: any, day5_hours_spent: any, day6_hours_spent: any, day7_hours_spent: any, project: record, task: record, time_card_line_id: int, total_hours_spent: any>, timecard_id: int, total_hours: any, week_beginning: string>
# operationId: getReceivedTimeCard
export def "get-received-time-card" [
  workgroup_id: string
  time_card_id: string
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
    path: "/v1/workgroups/{workgroup_id}/receivedTimeCards/{timeCard_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: timeCard_id, var: time_card_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, time_card_id: $time_card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the sell orders of workgrop
#
# GET /v1/workgroups/{workgroup_id}/sellOrders
# Returns: record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, project: record, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string>
# operationId: getSellOrderListOfWorkgroup
export def "get-sell-order-list-of-workgroup" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/sellOrders"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific sell order
#
# GET /v1/workgroups/{workgroup_id}/sellOrders/{order_id}
# Returns: record<result: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: list<record>, classification: string, closed_date: string, closing_change_orders: list<record>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list<record>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: list<record>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, status_code: int, status_reason: string>
# operationId: getSellOrderOfWorkgroup
export def "get-sell-order-of-workgroup" [
  workgroup_id: string
  order_id: string
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
    path: "/v1/workgroups/{workgroup_id}/sellOrders/{order_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: order_id, var: order_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Spec Templates of Workgroup Level
#
# GET /v1/workgroups/{workgroup_id}/specTemplates
# Returns: record<results: table<created_by: record, created_date: string, is_active: bool, is_externally_published: bool, is_locked: bool, last_updated_date: string, spec_template_id: int, spec_template_name: string>, status_code: int, status_reason: string>
# operationId: getSpecTemplateList
export def "get-spec-template-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/specTemplates"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific Spec Template
#
# GET /v1/workgroups/{workgroup_id}/specTemplates/{spec_template_id}
# Returns: record<result: record<created_by: record<email: string, first_name: string, last_name: string, middle_name: string>, created_date: string, is_active: bool, is_externally_published: bool, is_locked: bool, last_updated_date: string, product_type: string, product_type_info: record<label: string, product_type_id: int>, spec_template_id: int, spec_template_name: string, spec_type: record<spec_type_id: int, spec_type_name: string>>, status_code: int, status_reason: string>
# operationId: getSpecTemplate
export def "get-spec-template" [
  workgroup_id: string
  spec_template_id: string
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
    path: "/v1/workgroups/{workgroup_id}/specTemplates/{spec_template_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: spec_template_id, var: spec_template_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, spec_template_id: $spec_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Spec Type Fields
#
# GET /v1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields
# Returns: record<result: table<data_type: string, param_name: string>, status_code: int, status_reason: string>
export def "get-v1-workgroups-workgroup-id-spec-types-spec-type-id-spec-type-fields" [
  workgroup_id: string
  spec_type_id: string
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
    path: "/v1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: spec_type_id, var: spec_type_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, spec_type_id: $spec_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List supplier workgroups
#
# GET /v1/workgroups/{workgroup_id}/supplierWorkgroups
# Returns: record<result: table<bu_supplier_workgroup_id: int, bu_supplier_workgroup_name: string, client_workgroup_id: int, client_workgroup_name: string, is_approved: bool, supplier_code: string, supplier_workgroup_id: int, supplier_workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getSupplierWorkgroupList
export def "get-supplier-workgroup-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/supplierWorkgroups"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the specific supplier of My Group
#
# GET /v1/workgroups/{workgroup_id}/supplierWorkgroups/{bu_supplier_workgroup_id}
# Returns: record<result: record<additional_workgroups_contain_same_supplier: list<record>, bu_supplier_workgroup_id: int, bu_supplier_workgroup_name: string, client_workgroup_id: int, client_workgroup_name: string, is_approved: bool, supplier_code: string, supplier_workgroup_id: int, supplier_workgroup_name: string>, status_code: int, status_reason: string>
# operationId: getSupplierWorkgroupDetail
export def "get-supplier-workgroup-detail" [
  workgroup_id: string
  bu_supplier_workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/supplierWorkgroups/{bu_supplier_workgroup_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: bu_supplier_workgroup_id, var: bu_supplier_workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, bu_supplier_workgroup_id: $bu_supplier_workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get task types of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/taskTypes
# Returns: record<results: table<task_type: string, task_type_id: int>, status_code: int, status_reason: string>
# operationId: getTaskTypesOfWorkgroup
export def "get-task-types-of-workgroup" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/taskTypes"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get task list of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/tasks
# Returns: record<results: table<actual_end: string, actual_hours: any, actual_start: string, assign_to: record, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, current_duration: any, is_milestone: bool, mod_date: string, plan_end: string, plan_start: string, priority: string, project: record, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>
# operationId: getTaskListOfWorkgroup
export def "get-task-list-of-workgroup" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/tasks"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a sepcific task of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/tasks/{task_id}
# Returns: record<result: record<actual_duration: any, actual_end: string, actual_hours: any, actual_start: string, assign_to: record<email: string, first_name: string, last_name: string, middle_name: string>, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, comments: string, create_date: string, creator_workgroup_name: string, current_duration: any, description: string, is_milestone: bool, last_updated_by: record<email: string, first_name: string, last_name: string, middle_name: string>, mod_date: string, percent_complete: int, plan_duration: any, plan_end: string, plan_start: string, priority: string, project: record<project_id: int, project_name: string, project_number: string>, requested_by: record<email: string, first_name: string, last_name: string, middle_name: string>, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string>
# operationId: getTaskOfWorkgroup
export def "get-task-of-workgroup" [
  workgroup_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/workgroups/{workgroup_id}/tasks/{task_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: task_id, var: task_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List current user's team templates info
#
# GET /v1/workgroups/{workgroup_id}/teamTemplates
# Returns: record<results: table<team_template_id: int, team_template_name: string>, status_code: int, status_reason: string>
# operationId: getTeamTemplateList
export def "get-team-template-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/teamTemplates"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get current user's team template detal info
#
# GET /v1/workgroups/{workgroup_id}/teamTemplates/{team_template_id}
# Returns: record<results: record<team_teample_item: list<record>, team_template_id: int, team_template_name: string>, status_code: int, status_reason: string>
# operationId: getTeamTemplateDetail
export def "get-team-template-detail" [
  workgroup_id: string
  team_template_id: string
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
    path: "/v1/workgroups/{workgroup_id}/teamTemplates/{team_template_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: team_template_id, var: team_template_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, team_template_id: $team_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List the workgroup members
#
# GET /v1/workgroups/{workgroup_id}/workgroupMembers
# Returns: record<results: table<email: string, first_name: string, last_name: string, user_id: int>, status_code: int, status_reason: string>
# operationId: getWorkgroupMemberList
export def "get-workgroup-member-list" [
  workgroup_id: string
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
    path: "/v1/workgroups/{workgroup_id}/workgroupMembers"
    path_params: [{name: workgroup_id, var: workgroup_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Workgroup Member Info
#
# GET /v1/workgroups/{workgroup_id}/workgroupMembers/{user_id}
# Returns: record<result: record<address: any, company_name: string, email: string, fax_number: string, first_name: string, last_name: string, locale: string, middle_name: string, organization: string, phone_number: string, time_zone: string, title: string, user_id: int>, status_code: int, status_reason: string>
# operationId: getWorkgroupMemberInfo
export def "get-workgroup-member-info" [
  workgroup_id: string
  user_id: string
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
    path: "/v1/workgroups/{workgroup_id}/workgroupMembers/{user_id}"
    path_params: [{name: workgroup_id, var: workgroup_id}, {name: user_id, var: user_id}]
    accept: ["*/*", "application/json", "application/x-json-smile", "application/x-yaml", "application/xml", "text/csv", "text/x-yaml", "text/xml"]
    ok: [200]
    auth: basic
  } {
    workgroup_id: $workgroup_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
