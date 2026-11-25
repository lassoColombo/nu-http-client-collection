# Auto-generated client for SalesLoft Platform v2
# Source: https://api.apis.guru/v2/specs/salesloft.com/v2/openapi.json
# Auth: --token flag or $env.SALESLOFT_PLATFORM_TOKEN

const CLIENT = {
  base_url: "https://api.salesloft.com"
  token_env_var: "SALESLOFT_PLATFORM_TOKEN"
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

def base-url-completer [] { ["https://api.salesloft.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-v2-account-stages-json: "table<created_at: string, id: int, name: string, order: int, updated_at: string>"
    get-v2-account-stages-id-json: "record<created_at: string, id: int, name: string, order: int, updated_at: string>"
    get-v2-account-tiers-json: "table<created_at: string, id: int, name: string, order: int, updated_at: string>"
    get-v2-account-tiers-id-json: "record<created_at: string, id: int, name: string, order: int, updated_at: string>"
    post-v2-account-upserts-json: "record<account: record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>, upsert_type: string>"
    get-v2-accounts-json: "table<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>"
    post-v2-accounts-json: "record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>"
    get-v2-accounts-id-json: "record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>"
    put-v2-accounts-id-json: "record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>"
    get-v2-action-details-call-instructions-json: "table<created_at: string, id: int, instructions: string, updated_at: string>"
    get-v2-action-details-call-instructions-id-json: "record<created_at: string, id: int, instructions: string, updated_at: string>"
    get-v2-actions-json: "table<action_details: record<_href: string, id: int>, cadence: record<_href: string, id: int>, created_at: string, due: bool, due_on: string, id: int, multitouch_group_id: int, person: record<_href: string, id: int>, status: string, step: record<_href: string, id: int>, type: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-actions-id-json: "record<action_details: record<_href: string, id: int>, cadence: record<_href: string, id: int>, created_at: string, due: bool, due_on: string, id: int, multitouch_group_id: int, person: record<_href: string, id: int>, status: string, step: record<_href: string, id: int>, type: string, updated_at: string, user: record<_href: string, id: int>>"
    post-v2-activities-json: "record<updated_at: string>"
    get-v2-activities-calls-json: "table<action: record<_href: string, id: int>, cadence: record<_href: string, id: int>, called_person: record<_href: string, id: int>, created_at: string, crm_activity: record<_href: string, id: int>, disposition: string, duration: int, id: int, note: record<_href: string, id: int>, recordings: list<record>, sentiment: string, step: record<_href: string, id: int>, to: string, updated_at: string, user: record<_href: string, id: int>>"
    post-v2-activities-calls-json: "record<action: record<_href: string, id: int>, cadence: record<_href: string, id: int>, called_person: record<_href: string, id: int>, created_at: string, crm_activity: record<_href: string, id: int>, disposition: string, duration: int, id: int, note: record<_href: string, id: int>, recordings: table<recording_status: string, status: string, url: string>, sentiment: string, step: record<_href: string, id: int>, to: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-activities-calls-id-json: "record<action: record<_href: string, id: int>, cadence: record<_href: string, id: int>, called_person: record<_href: string, id: int>, created_at: string, crm_activity: record<_href: string, id: int>, disposition: string, duration: int, id: int, note: record<_href: string, id: int>, recordings: table<recording_status: string, status: string, url: string>, sentiment: string, step: record<_href: string, id: int>, to: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-activities-emails-json: "table<action: record<_href: string, id: int>, bounced: bool, cadence: record<_href: string, id: int>, click_tracking: bool, counts: record<attachments: int, clicks: int, replies: int, unique_devices: int, unique_locations: int, views: int>, created_at: string, crm_activity: record<_href: string, id: int>, email_template: record<_href: string, id: int>, error_message: string, headers: record, id: int, mailing: record<_href: string, id: int>, personalization: string, recipient: record<_href: string, id: int>, recipient_email_address: string, send_after: string, sent_at: string, status: string, step: record<_href: string, id: int>, subject: string, task: record<_href: string, id: int>, updated_at: string, user: record<_href: string, id: int>, view_tracking: bool>"
    get-v2-activities-emails-id-json: "record<action: record<_href: string, id: int>, bounced: bool, cadence: record<_href: string, id: int>, click_tracking: bool, counts: record<attachments: int, clicks: int, replies: int, unique_devices: int, unique_locations: int, views: int>, created_at: string, crm_activity: record<_href: string, id: int>, email_template: record<_href: string, id: int>, error_message: string, headers: record, id: int, mailing: record<_href: string, id: int>, personalization: string, recipient: record<_href: string, id: int>, recipient_email_address: string, send_after: string, sent_at: string, status: string, step: record<_href: string, id: int>, subject: string, task: record<_href: string, id: int>, updated_at: string, user: record<_href: string, id: int>, view_tracking: bool>"
    get-v2-activity-histories: "record<created_at: string, dynamic_data: record, failed_dynamic_resources: record, id: int, occurred_at: string, pinned_at: string, resource_id: int, resource_type: int, static_data: record, type: string, updated_at: string, user_guid: string>"
    get-v2-bulk-jobs: "table<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>"
    post-v2-bulk-jobs: "record<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>"
    get-v2-bulk-jobs-bulk-jobs-id-job-data: "table<error: string, id: int, record: record, resource: record, status: string>"
    post-v2-bulk-jobs-bulk-jobs-id-job-data: "record<records: int>"
    get-v2-bulk-jobs-bulk-jobs-id-results: "table<error: string, id: int, record: record, resource: record, status: string>"
    get-v2-bulk-jobs-id: "record<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>"
    put-v2-bulk-jobs-id: "record<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>"
    get-v2-cadence-exports-id-json: "record<cadence_content: record>"
    post-v2-cadence-imports-json: "record<cadence: record<_href: string, id: int>>"
    get-v2-cadence-memberships-json: "table<added_at: string, cadence: record<_href: string, id: int>, counts: record<bounces: int, calls: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, current_state: string, currently_on_cadence: bool, id: int, latest_action: record<_href: string, id: int>, person: record<_href: string, id: int>, person_deleted: bool, updated_at: string, user: record<_href: string, id: int>>"
    post-v2-cadence-memberships-json: "record<added_at: string, cadence: record<_href: string, id: int>, counts: record<bounces: int, calls: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, current_state: string, currently_on_cadence: bool, id: int, latest_action: record<_href: string, id: int>, person: record<_href: string, id: int>, person_deleted: bool, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-cadence-memberships-id-json: "record<added_at: string, cadence: record<_href: string, id: int>, counts: record<bounces: int, calls: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, current_state: string, currently_on_cadence: bool, id: int, latest_action: record<_href: string, id: int>, person: record<_href: string, id: int>, person_deleted: bool, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-cadences-json: "table<added_stage: record<_href: string, id: int>, archived_at: string, bounced_stage: record<_href: string, id: int>, cadence_framework_id: int, cadence_function: string, cadence_priority: record<_href: string, id: int>, counts: record<cadence_people: int, meetings_booked: int, opportunities_created: int, people_acted_on_count: int, target_daily_people: int>, created_at: string, creator: record<_href: string, id: int>, draft: bool, external_identifier: string, finished_stage: record<_href: string, id: int>, groups: list<record>, id: int, name: string, opt_out_link_included: bool, owner: record<_href: string, id: int>, remove_bounces_enabled: bool, remove_replies_enabled: bool, replied_stage: record<_href: string, id: int>, shared: bool, tags: list<string>, team_cadence: bool, updated_at: string>"
    get-v2-cadences-id-json: "record<added_stage: record<_href: string, id: int>, archived_at: string, bounced_stage: record<_href: string, id: int>, cadence_framework_id: int, cadence_function: string, cadence_priority: record<_href: string, id: int>, counts: record<cadence_people: int, meetings_booked: int, opportunities_created: int, people_acted_on_count: int, target_daily_people: int>, created_at: string, creator: record<_href: string, id: int>, draft: bool, external_identifier: string, finished_stage: record<_href: string, id: int>, groups: table<_href: string, id: int>, id: int, name: string, opt_out_link_included: bool, owner: record<_href: string, id: int>, remove_bounces_enabled: bool, remove_replies_enabled: bool, replied_stage: record<_href: string, id: int>, shared: bool, tags: list<string>, team_cadence: bool, updated_at: string>"
    get-v2-calendar-events: "table<all_day: string, attendees: record, body_html: string, busy: bool, calendar_id: string, canceled_at: string, conference_data: record, created_at: string, creator: record, description: string, end_time: string, extended_properties: record, html_link: string, i_cal_uid: string, id: string, location: string, organizer: string, provider: string, recurring: string, start_time: string, status: string, tenant_id: int, title: string, updated_at: string, user_guid: string>"
    post-v2-calendar-events-upsert: "record<all_day: string, attendees: record, body_html: string, busy: bool, calendar_id: string, canceled_at: string, conference_data: record, created_at: string, creator: record, description: string, end_time: string, extended_properties: record, html_link: string, i_cal_uid: string, id: string, location: string, organizer: string, provider: string, recurring: string, start_time: string, status: string, tenant_id: int, title: string, updated_at: string, user_guid: string>"
    get-v2-call-data-records-json: "table<call: record<_href: string, id: int>, call_type: string, call_uuid: string, called_person: record<_href: string, id: int>, created_at: string, direction: string, duration: int, from: string, id: int, recording: record<recording_status: string, status: string, url: string>, status: string, to: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-call-data-records-id-json: "record<call: record<_href: string, id: int>, call_type: string, call_uuid: string, called_person: record<_href: string, id: int>, created_at: string, direction: string, duration: int, from: string, id: int, recording: record<recording_status: string, status: string, url: string>, status: string, to: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-call-dispositions-json: "table<created_at: string, id: int, name: string, updated_at: string>"
    get-v2-call-sentiments-json: "table<created_at: string, id: int, name: string, updated_at: string>"
    post-v2-conversations-calls: "record<call_created_at: string, direction: string, duration: float, from: string, recording: record, to: string, user_guid: string>"
    get-v2-crm-activities-json: "table<activity_type: string, created_at: string, crm_id: string, custom_crm_fields: record, description: string, error: string, id: int, person: record<_href: string, id: int>, subject: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-crm-activities-id-json: "record<activity_type: string, created_at: string, crm_id: string, custom_crm_fields: record, description: string, error: string, id: int, person: record<_href: string, id: int>, subject: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-crm-activity-fields-json: "table<created_at: string, crm_object_type: string, field: string, field_type: string, id: int, picklist_values: record, salesforce_object_type: string, source: string, title: string, updated_at: string, value: string>"
    get-v2-crm-users-json: "table<created_at: string, crm_id: string, id: int, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-custom-fields-json: "table<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>"
    post-v2-custom-fields-json: "record<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>"
    get-v2-custom-fields-id-json: "record<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>"
    put-v2-custom-fields-id-json: "record<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>"
    get-v2-email-template-attachments-json: "table<attachment_content_type: string, attachment_file_size: int, attachment_fingerprint: int, attachment_id: int, download_url: string, email_template: record<_href: string, id: int>, id: int, name: string, scanned: bool>"
    get-v2-email-templates-json: "table<_links: record, archived_at: string, body: string, body_preview: string, cadence_template: bool, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, groups: list<record>, id: int, last_used_at: string, open_tracking_enabled: bool, shared: bool, subject: string, tags: list<string>, team_template: record<_href: string, id: int>, template_owner: record<_href: string, id: int>, title: string, updated_at: string>"
    get-v2-email-templates-id-json: "record<_links: record, archived_at: string, body: string, body_preview: string, cadence_template: bool, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, groups: table<_href: string, id: int>, id: int, last_used_at: string, open_tracking_enabled: bool, shared: bool, subject: string, tags: list<string>, team_template: record<_href: string, id: int>, template_owner: record<_href: string, id: int>, title: string, updated_at: string>"
    post-v2-external-emails-json: "record<message_id: string>"
    get-v2-groups-json: "table<accessible_groups: list<record>, id: int, name: string, parent_id: int>"
    get-v2-groups-id-json: "record<accessible_groups: table<_href: string, id: int>, id: int, name: string, parent_id: int>"
    get-v2-imports-json: "table<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>"
    post-v2-imports-json: "record<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>"
    get-v2-imports-id-json: "record<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>"
    put-v2-imports-id-json: "record<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>"
    post-v2-live-website-tracking-parameters-json: "record<parameters: list<record>>"
    get-v2-me-json: "record<_private_fields: record, active: bool, bcc_email_address: string, click_to_call_enabled: bool, created_at: string, crm_connected: bool, email: string, email_client_configured: bool, email_client_email_address: string, email_signature: string, email_signature_click_tracking_disabled: bool, email_signature_type: string, external_feature_flags: record, first_name: string, from_address: string, full_email_address: string, group: record<_href: string, id: int>, guid: string, id: int, job_role: string, last_name: string, local_dial_enabled: bool, name: string, phone_client: record<_href: string, id: int>, phone_number_assignment: record<_href: string, id: int>, role: record<_href: string, id: int>, sending_email_address: string, slack_username: string, team: record<_href: string, id: int>, team_admin: bool, time_zone: string, twitter_handle: string, updated_at: string, work_country: string>"
    get-v2-meetings-json: "table<account_id: string, all_day: bool, attendees: list<record>, booked_by_meetings_settings: record<email_address: string>, booked_by_user: record<_href: string, id: int>, cadence: record<_href: string, id: int>, calendar_id: string, calendar_type: string, canceled_at: string, created_at: string, crm_custom_fields: record, crm_references: record, description: string, end_time: string, event_id: string, event_source: string, guests: list<string>, i_cal_uid: string, id: int, location: string, meeting_type: string, no_show: bool, owned_by_meetings_settings: record<email_address: string>, person: record<_href: string, id: int>, recipient_email: string, recipient_name: string, start_time: string, status: string, step: record<_href: string, id: int>, strict_attribution: bool, task_id: string, title: string, updated_at: string>"
    post-v2-meetings-settings-searches-json: "table<active_meeting_url: record<created_at: string, updated_at: string, url: string>, allow_booking_on_behalf: bool, allow_booking_overtime: bool, allow_event_overlap: bool, availability_limit: int, availability_limit_enabled: bool, buffer_time_duration: int, calendar_type: string, created_at: string, default_meeting_length: int, description: string, email_address: string, enable_calendar_sync: bool, enable_dynamic_location: bool, id: int, location: string, primary_calendar_connection_failed: bool, primary_calendar_id: string, primary_calendar_name: string, schedule_buffer_enabled: bool, schedule_delay: int, share_event_detail: bool, time_zone: string, times_available: record, title: string, updated_at: string, user: record<_href: string, id: int>, user_details: record, user_slug: string>"
    put-v2-meetings-settings-id-json: "record<active_meeting_url: record<created_at: string, updated_at: string, url: string>, allow_booking_on_behalf: bool, allow_booking_overtime: bool, allow_event_overlap: bool, availability_limit: int, availability_limit_enabled: bool, buffer_time_duration: int, calendar_type: string, created_at: string, default_meeting_length: int, description: string, email_address: string, enable_calendar_sync: bool, enable_dynamic_location: bool, id: int, location: string, primary_calendar_connection_failed: bool, primary_calendar_id: string, primary_calendar_name: string, schedule_buffer_enabled: bool, schedule_delay: int, share_event_detail: bool, time_zone: string, times_available: record, title: string, updated_at: string, user: record<_href: string, id: int>, user_details: record, user_slug: string>"
    put-v2-meetings-id-json: "record<account_id: string, all_day: bool, attendees: table<deleted_at: string, email: string, name: string, organizer: bool, status: string, status_changed: bool>, booked_by_meetings_settings: record<email_address: string>, booked_by_user: record<_href: string, id: int>, cadence: record<_href: string, id: int>, calendar_id: string, calendar_type: string, canceled_at: string, created_at: string, crm_custom_fields: record, crm_references: record, description: string, end_time: string, event_id: string, event_source: string, guests: list<string>, i_cal_uid: string, id: int, location: string, meeting_type: string, no_show: bool, owned_by_meetings_settings: record<email_address: string>, person: record<_href: string, id: int>, recipient_email: string, recipient_name: string, start_time: string, status: string, step: record<_href: string, id: int>, strict_attribution: bool, task_id: string, title: string, updated_at: string>"
    get-v2-mime-email-payloads-id-json: "record<id: int, mailbox: string, message_id: string, raw: string>"
    get-v2-notes-json: "table<associated_type: string, associated_with: record<_href: string, id: int>, call: record<_href: string, id: int>, content: string, created_at: string, id: int, updated_at: string, user: record<_href: string, id: int>>"
    post-v2-notes-json: "record<associated_type: string, associated_with: record<_href: string, id: int>, call: record<_href: string, id: int>, content: string, created_at: string, id: int, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-notes-id-json: "record<associated_type: string, associated_with: record<_href: string, id: int>, call: record<_href: string, id: int>, content: string, created_at: string, id: int, updated_at: string, user: record<_href: string, id: int>>"
    put-v2-notes-id-json: "record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>"
    post-v2-ongoing-actions-json: "record<action_details: record<_href: string, id: int>, cadence: record<_href: string, id: int>, created_at: string, due: bool, due_on: string, id: int, multitouch_group_id: int, person: record<_href: string, id: int>, status: string, step: record<_href: string, id: int>, type: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-pending-emails-json: "table<id: int, mailbox: string, mime_email_payload: record<_href: string, id: int>>"
    put-v2-pending-emails-id-json: "record<id: int, mailbox: string, mime_email_payload: record<_href: string, id: int>>"
    get-v2-people-json: "table<account: record<_href: string, id: int>, bouncing: bool, cadences: list<record>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>"
    post-v2-people-json: "record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>"
    get-v2-people-id-json: "record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>"
    put-v2-people-id-json: "record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>"
    get-v2-person-stages-json: "table<created_at: string, id: int, name: string, order: int, updated_at: string>"
    post-v2-person-stages-json: "record<created_at: string, id: int, name: string, order: int, updated_at: string>"
    get-v2-person-stages-id-json: "record<created_at: string, id: int, name: string, order: int, updated_at: string>"
    put-v2-person-stages-id-json: "record<created_at: string, id: int, name: string, order: int, updated_at: string>"
    post-v2-person-upserts-json: "record<person: record<account: record<_href: string, id: int>, bouncing: bool, cadences: list<record>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>, upsert_type: string>"
    get-v2-phone-number-assignments-json: "table<id: int, number: string, user: record<_href: string, id: int>>"
    get-v2-phone-number-assignments-id-json: "record<id: int, number: string, user: record<_href: string, id: int>>"
    get-v2-phone-numbers-caller-ids-json: "table<account_name: string, display_name: string, person: record<_href: string, id: int>, title: string>"
    get-v2-phone-numbers-recording-settings-id-json: "record<recording_default: bool>"
    get-v2-saved-list-views-json: "table<id: int, is_default: bool, name: string, view: string, view_params: record>"
    post-v2-saved-list-views-json: "record<id: int, is_default: bool, name: string, view: string, view_params: record>"
    get-v2-saved-list-views-id-json: "record<id: int, is_default: bool, name: string, view: string, view_params: record>"
    put-v2-saved-list-views-id-json: "record<id: int, is_default: bool, name: string, view: string, view_params: record>"
    get-v2-steps-json: "table<cadence: record<_href: string, id: int>, created_at: string, day: int, details: record<_href: string, id: int>, disabled: bool, display_name: string, id: int, multitouch_enabled: bool, name: string, step_number: int, type: string, updated_at: string>"
    get-v2-steps-id-json: "record<cadence: record<_href: string, id: int>, created_at: string, day: int, details: record<_href: string, id: int>, disabled: bool, display_name: string, id: int, multitouch_enabled: bool, name: string, step_number: int, type: string, updated_at: string>"
    get-v2-successes-json: "table<counts: record<total_calls: int, total_emails: int, total_other_touches: int>, created_at: string, id: int, latest_action: record<_href: string, id: int>, latest_cadence: record<_href: string, id: int>, latest_call: record<_href: string, id: int>, latest_email: record<_href: string, id: int>, latest_step: record<_href: string, id: int>, person: record<_href: string, id: int>, succeeded_at: string, success_window_started_at: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-tags-json: "table<id: int, name: string>"
    get-v2-tasks-json: "table<completed_at: string, completed_by: record<_href: string, id: int>, created_at: string, created_by_user: record<_href: string, id: int>, current_state: string, description: string, due_at: string, due_date: string, id: int, person: record<_href: string, id: int>, remind_at: string, subject: string, task_type: string, updated_at: string, user: record<_href: string, id: int>>"
    post-v2-tasks-json: "record<completed_at: string, completed_by: record<_href: string, id: int>, created_at: string, created_by_user: record<_href: string, id: int>, current_state: string, description: string, due_at: string, due_date: string, id: int, person: record<_href: string, id: int>, remind_at: string, subject: string, task_type: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-tasks-id-json: "record<cadence: record<_href: string, id: int>, created_at: string, day: int, details: record<_href: string, id: int>, disabled: bool, display_name: string, id: int, multitouch_enabled: bool, name: string, step_number: int, type: string, updated_at: string>"
    put-v2-tasks-id-json: "record<completed_at: string, completed_by: record<_href: string, id: int>, created_at: string, created_by_user: record<_href: string, id: int>, current_state: string, description: string, due_at: string, due_date: string, id: int, person: record<_href: string, id: int>, remind_at: string, subject: string, task_type: string, updated_at: string, user: record<_href: string, id: int>>"
    get-v2-team-json: "record<_private_fields: record, allow_automated_email_steps: bool, call_recording_disabled: bool, click_tracking_default: bool, created_at: string, custom_tracking_domain: string, deactivated: bool, dispositions_required: bool, email_daily_limit: int, group_privacy_setting: string, id: int, license_limit: int, local_dial_enabled: bool, name: string, plan: string, plan_features: record, record_by_default: bool, sentiments_required: bool, team_visibility_default: string, updated_at: string>"
    get-v2-team-template-attachments-json: "table<attachment_file_size: int, attachment_id: int, download_url: string, id: int, name: string, team_template: record<_href: string, id: int>>"
    get-v2-team-templates-json: "table<_links: record, archived_at: string, body: string, body_preview: string, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, id: string, last_modified_at: string, last_modified_user: record<_href: string, id: int>, last_used_at: string, open_tracking_enabled: bool, subject: string, tags: list<string>, title: string, updated_at: string>"
    get-v2-team-templates-id-json: "record<_links: record, archived_at: string, body: string, body_preview: string, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, id: string, last_modified_at: string, last_modified_user: record<_href: string, id: int>, last_used_at: string, open_tracking_enabled: bool, subject: string, tags: list<string>, title: string, updated_at: string>"
    post-v2-third-party-live-feed-items: "table<alert_metadata: record, event_occurred_at: string, event_type: string, id: int, message: string, metadata: record, path: string, rollup_key: string, title: string, user_guid: string>"
    get-v2-users-json: "table<_private_fields: record, active: bool, bcc_email_address: string, click_to_call_enabled: bool, created_at: string, crm_connected: bool, email: string, email_client_configured: bool, email_client_email_address: string, email_signature: string, email_signature_click_tracking_disabled: bool, email_signature_type: string, external_feature_flags: record, first_name: string, from_address: string, full_email_address: string, group: record<_href: string, id: int>, guid: string, id: int, job_role: string, last_name: string, local_dial_enabled: bool, name: string, phone_client: record<_href: string, id: int>, phone_number_assignment: record<_href: string, id: int>, role: record<_href: string, id: int>, sending_email_address: string, slack_username: string, team: record<_href: string, id: int>, team_admin: bool, time_zone: string, twitter_handle: string, updated_at: string, work_country: string>"
    get-v2-users-id-json: "record<_private_fields: record, active: bool, bcc_email_address: string, click_to_call_enabled: bool, created_at: string, crm_connected: bool, email: string, email_client_configured: bool, email_client_email_address: string, email_signature: string, email_signature_click_tracking_disabled: bool, email_signature_type: string, external_feature_flags: record, first_name: string, from_address: string, full_email_address: string, group: record<_href: string, id: int>, guid: string, id: int, job_role: string, last_name: string, local_dial_enabled: bool, name: string, phone_client: record<_href: string, id: int>, phone_number_assignment: record<_href: string, id: int>, role: record<_href: string, id: int>, sending_email_address: string, slack_username: string, team: record<_href: string, id: int>, team_admin: bool, time_zone: string, twitter_handle: string, updated_at: string, work_country: string>"
    get-v2-webhook-subscriptions: "table<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>"
    post-v2-webhook-subscriptions: "record<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>"
    get-v2-webhook-subscriptions-id: "record<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>"
    put-v2-webhook-subscriptions-id: "record<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-v2-account-stages-json" "get-v2-account-stages-id-json" "get-v2-account-tiers-json" "get-v2-account-tiers-id-json" "post-v2-account-upserts-json" "get-v2-accounts-json" "post-v2-accounts-json" "delete-v2-accounts-id-json" "get-v2-accounts-id-json" "put-v2-accounts-id-json" "get-v2-action-details-call-instructions-json" "get-v2-action-details-call-instructions-id-json" "get-v2-actions-json" "get-v2-actions-id-json" "post-v2-activities-json" "get-v2-activities-calls-json" "post-v2-activities-calls-json" "get-v2-activities-calls-id-json" "get-v2-activities-emails-json" "get-v2-activities-emails-id-json" "get-v2-activity-histories" "get-v2-bulk-jobs" "post-v2-bulk-jobs" "get-v2-bulk-jobs-bulk-jobs-id-job-data" "post-v2-bulk-jobs-bulk-jobs-id-job-data" "get-v2-bulk-jobs-bulk-jobs-id-results" "get-v2-bulk-jobs-id" "put-v2-bulk-jobs-id" "get-v2-cadence-exports-id-json" "post-v2-cadence-imports-json" "get-v2-cadence-memberships-json" "post-v2-cadence-memberships-json" "delete-v2-cadence-memberships-id-json" "get-v2-cadence-memberships-id-json" "get-v2-cadences-json" "get-v2-cadences-id-json" "get-v2-calendar-events" "post-v2-calendar-events-upsert" "get-v2-call-data-records-json" "get-v2-call-data-records-id-json" "get-v2-call-dispositions-json" "get-v2-call-sentiments-json" "post-v2-conversations-calls" "get-v2-crm-activities-json" "get-v2-crm-activities-id-json" "get-v2-crm-activity-fields-json" "get-v2-crm-users-json" "get-v2-custom-fields-json" "post-v2-custom-fields-json" "delete-v2-custom-fields-id-json" "get-v2-custom-fields-id-json" "put-v2-custom-fields-id-json" "get-v2-email-template-attachments-json" "get-v2-email-templates-json" "get-v2-email-templates-id-json" "post-v2-external-emails-json" "get-v2-groups-json" "get-v2-groups-id-json" "get-v2-imports-json" "post-v2-imports-json" "delete-v2-imports-id-json" "get-v2-imports-id-json" "put-v2-imports-id-json" "post-v2-live-website-tracking-parameters-json" "get-v2-me-json" "get-v2-meetings-json" "post-v2-meetings-settings-searches-json" "put-v2-meetings-settings-id-json" "put-v2-meetings-id-json" "get-v2-mime-email-payloads-id-json" "get-v2-notes-json" "post-v2-notes-json" "delete-v2-notes-id-json" "get-v2-notes-id-json" "put-v2-notes-id-json" "post-v2-ongoing-actions-json" "get-v2-pending-emails-json" "put-v2-pending-emails-id-json" "get-v2-people-json" "post-v2-people-json" "delete-v2-people-id-json" "get-v2-people-id-json" "put-v2-people-id-json" "get-v2-person-stages-json" "post-v2-person-stages-json" "delete-v2-person-stages-id-json" "get-v2-person-stages-id-json" "put-v2-person-stages-id-json" "post-v2-person-upserts-json" "get-v2-phone-number-assignments-json" "get-v2-phone-number-assignments-id-json" "get-v2-phone-numbers-caller-ids-json" "get-v2-phone-numbers-recording-settings-id-json" "get-v2-saved-list-views-json" "post-v2-saved-list-views-json" "delete-v2-saved-list-views-id-json" "get-v2-saved-list-views-id-json" "put-v2-saved-list-views-id-json" "get-v2-steps-json" "get-v2-steps-id-json" "get-v2-successes-json" "get-v2-tags-json" "get-v2-tasks-json" "post-v2-tasks-json" "get-v2-tasks-id-json" "put-v2-tasks-id-json" "get-v2-team-json" "get-v2-team-template-attachments-json" "get-v2-team-templates-json" "get-v2-team-templates-id-json" "post-v2-third-party-live-feed-items" "get-v2-users-json" "get-v2-users-id-json" "get-v2-webhook-subscriptions" "post-v2-webhook-subscriptions" "delete-v2-webhook-subscriptions-id" "get-v2-webhook-subscriptions-id" "put-v2-webhook-subscriptions-id" "commands"] | sort) } | get name | first)
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

# List account stages
#
# GET /v2/account_stages.json
# Returns: table<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "get-v2-account-stages-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of account stages to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, order. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/account_stages.json"
    query: [{name: ids, var: ids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, updated_at: $updated_at, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an account stage
#
# GET /v2/account_stages/{id}.json
# Returns: record<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "get-v2-account-stages-id-json" [
  id: string
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
    path: "/v2/account_stages/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Account Tiers
#
# GET /v2/account_tiers.json
# Returns: table<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "get-v2-account-tiers-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of Account Tiers to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --name: list<string> # Filters Account Tiers by name. Multiple names can be applied
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, order. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/account_tiers.json"
    query: [{name: ids, var: ids, style: csv}, {name: name, var: name, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, name: $name, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an account tier
#
# GET /v2/account_tiers/{id}.json
# Returns: record<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "get-v2-account-tiers-id-json" [
  id: string
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
    path: "/v2/account_tiers/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert an account
#
# POST /v2/account_upserts.json
# Returns: record<account: record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>, upsert_type: string>
export def "post-v2-account-upserts-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-tier-id: int # ID of the Account Tier for this Account
  --city: string # City
  --company-stage-id: int # ID of the CompanyStage assigned to this Account
  --company-type: string # Type of the Account's company
  --conversational-name: string # Conversational name of the Account
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either an Account (001) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "account:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: list # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --description: string # Description
  --do-not-contact: oneof<nothing, bool> # Whether this company can not be contacted. Values are either true or false. Setting this to true will remove all associated people from all active communications
  domain: string # Website domain, not a fully qualified URI
  --founded: string # Date or year of founding
  --id: int # ID of the account to update. Used if the upsert_key=id. When id and another upsert_key are provided, the request will fail if the upsert record id and id parameter don't match.
  --industry: string # Industry
  --linkedin-url: string # Full LinkedIn url
  --locale: string # Time locale
  name: string # Account Full Name
  --owner-id: int # ID of the User that owns this Account
  --phone: string # Phone number without formatting
  --postal-code: string # Postal code
  --revenue-range: string # Estimated revenue range
  --size: string # Estimated number of people in employment
  --state: string # State
  --street: string # Street name and number
  --tags: list<string> # All tags applied to this Account
  --twitter-handle: string # Twitter handle, with @
  --upsert-key: string # Name of the parameter to upsert on. The field must be provided in the input parameters, or the request will fail. The request will also fail if there are multiple records matched by the upsert field. If upsert_key is not provided, this endpoint will not update an existing record. Valid options are: id, crm_id, domain. If crm_id is provided, then a valid crm_id_type must be provided, as documented for the account create and update endpoints.
  --website: string # Website
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/account_upserts.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: account_tier_id, var: account_tier_id}, {name: city, var: city}, {name: company_stage_id, var: company_stage_id}, {name: company_type, var: company_type}, {name: conversational_name, var: conversational_name}, {name: country, var: country}, {name: crm_id, var: crm_id}, {name: crm_id_type, var: crm_id_type}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: do_not_contact, var: do_not_contact}, {name: domain, var: domain}, {name: founded, var: founded}, {name: id, var: id}, {name: industry, var: industry}, {name: linkedin_url, var: linkedin_url}, {name: locale, var: locale}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: phone, var: phone}, {name: postal_code, var: postal_code}, {name: revenue_range, var: revenue_range}, {name: size, var: size}, {name: state, var: state}, {name: street, var: street}, {name: tags, var: tags}, {name: twitter_handle, var: twitter_handle}, {name: upsert_key, var: upsert_key}, {name: website, var: website}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    account_tier_id: $account_tier_id, city: $city, company_stage_id: $company_stage_id, company_type: $company_type, conversational_name: $conversational_name, country: $country, crm_id: $crm_id, crm_id_type: $crm_id_type, custom_fields: $custom_fields, description: $description, do_not_contact: $do_not_contact, domain: $domain, founded: $founded, id: $id, industry: $industry, linkedin_url: $linkedin_url, locale: $locale, name: $name, owner_id: $owner_id, phone: $phone, postal_code: $postal_code, revenue_range: $revenue_range, size: $size, state: $state, street: $street, tags: $tags, twitter_handle: $twitter_handle, upsert_key: $upsert_key, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounts
#
# GET /v2/accounts.json
# Returns: table<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>
export def "get-v2-accounts-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of accounts to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --crm-id: list<string> # Filters accounts by crm_id. Multiple crm ids can be applied
  --tag: list<string> # Filters accounts by the tags applied to the account. Multiple tags can be applied
  --tag-id: list<int> # Filters accounts by the tag id's applied to the account. Multiple tag id's can be applied
  --created-at: list<string> # Equality filters that are applied to the created_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --domain: string # Domain of the accounts to fetch. Domains are unique and lowercase
  --website: list<string> # Filters accounts by website. Multiple websites can be applied. An additional value of "_is_null" can be passed to filter accounts that do not have a website.
  --archived: oneof<nothing, bool> # Filters accounts by archived_at status. Returns only accounts where archived_at is not null if this field is true. Returns only accounts where archived_at is null if this field is false. Do not pass this parameter to return both archived and unarchived accounts. This filter is not applied if any value other than "true" or "false" is passed.
  --name: list<string> # Names of accounts to fetch. Name matches are exact and case sensitive. Multiple names can be fetched.
  --account-stage-id: list<int> # Filters accounts by account_stage_id. Multiple account_stage_ids can be applied. An additional value of "_is_null" can be passed to filter accounts that do not have account_stage_id
  --account-tier-id: list<int> # Filters accounts by account_tier_id. Multiple account tier ids can be applied
  --owner-id: list<string> # Filters accounts by owner_id. Multiple owner_ids can be applied. An additional value of "_is_null" can be passed to filter accounts that are unowned
  --owner-is-active: oneof<nothing, bool> # Filters accounts by whether the owner is active or not.
  --last-contacted: record # Equality filters that are applied to the last_contacted field. A single filter can be used by itself or combined with other filters to create a range. Additional values of "_is_null" or "_is_not_null" can be passed to filter records that either have no timestamp value or any timestamp value. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --custom-fields: record # Filters by accounts matching all given custom fields. The custom field names are case-sensitive, but the provided values are case-insensitive. Example: v2/accounts?custom_fields[custom_field_name]=custom_field_value
  --industry: list<string> # Filters accounts by industry by exact match. Supports partial matching
  --country: list<string> # Filters accounts by country by exact match. Supports partial matching
  --state: list<string> # Filters accounts by state by exact match. Supports partial matching
  --city: list<string> # Filters accounts by city by exact match. Supports partial matching
  --owner-crm-id: list<string> # Filters accounts by owner_crm_id. Multiple owner_crm_ids can be applied. An additional value of "_is_null" can be passed to filter accounts that are unowned. A "_not_in" modifier can be used to exclude specific owner_crm_ids. Example: v2/accounts?owner_crm_id[_not_in]=id
  --locales: list<string> # Filters accounts by locale. Multiple locales are allowed
  --user-relationships: record # Filters by accounts matching all given user relationship fields, _is_null or _unmapped can be passed to filter accounts with null or unmapped user relationship values. Example: v2/accounts?user_relationships[name]=value
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_contacted_at, account_stage, account_stage_name, account_tier, account_tier_name, name, counts_people. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/accounts.json"
    query: [{name: ids, var: ids, style: csv}, {name: crm_id, var: crm_id, style: csv}, {name: tag, var: tag, style: csv}, {name: tag_id, var: tag_id, style: csv}, {name: created_at, var: created_at, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: domain, var: domain}, {name: website, var: website, style: csv}, {name: archived, var: archived}, {name: name, var: name, style: csv}, {name: account_stage_id, var: account_stage_id, style: csv}, {name: account_tier_id, var: account_tier_id, style: csv}, {name: owner_id, var: owner_id, style: csv}, {name: owner_is_active, var: owner_is_active}, {name: last_contacted, var: last_contacted, style: multi}, {name: custom_fields, var: custom_fields, style: multi}, {name: industry, var: industry, style: csv}, {name: country, var: country, style: csv}, {name: state, var: state, style: csv}, {name: city, var: city, style: csv}, {name: owner_crm_id, var: owner_crm_id, style: csv}, {name: locales, var: locales, style: csv}, {name: user_relationships, var: user_relationships, style: multi}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, crm_id: $crm_id, tag: $tag, tag_id: $tag_id, created_at: $created_at, updated_at: $updated_at, domain: $domain, website: $website, archived: $archived, name: $name, account_stage_id: $account_stage_id, account_tier_id: $account_tier_id, owner_id: $owner_id, owner_is_active: $owner_is_active, last_contacted: $last_contacted, custom_fields: $custom_fields, industry: $industry, country: $country, state: $state, city: $city, owner_crm_id: $owner_crm_id, locales: $locales, user_relationships: $user_relationships, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an account
#
# POST /v2/accounts.json
# Returns: record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>
export def "post-v2-accounts-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-tier-id: int # ID of the Account Tier for this Account
  --city: string # City
  --company-stage-id: int # ID of the CompanyStage assigned to this Account
  --company-type: string # Type of the Account's company
  --conversational-name: string # Conversational name of the Account
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either an Account (001) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "account:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: list # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --description: string # Description
  --do-not-contact: oneof<nothing, bool> # Whether this company can not be contacted. Values are either true or false. Setting this to true will remove all associated people from all active communications
  domain: string # Website domain, not a fully qualified URI
  --founded: string # Date or year of founding
  --industry: string # Industry
  --linkedin-url: string # Full LinkedIn url
  --locale: string # Time locale
  name: string # Account Full Name
  --owner-id: int # ID of the User that owns this Account
  --phone: string # Phone number without formatting
  --postal-code: string # Postal code
  --revenue-range: string # Estimated revenue range
  --size: string # Estimated number of people in employment
  --state: string # State
  --street: string # Street name and number
  --tags: list<string> # All tags applied to this Account
  --twitter-handle: string # Twitter handle, with @
  --website: string # Website
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/accounts.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: account_tier_id, var: account_tier_id}, {name: city, var: city}, {name: company_stage_id, var: company_stage_id}, {name: company_type, var: company_type}, {name: conversational_name, var: conversational_name}, {name: country, var: country}, {name: crm_id, var: crm_id}, {name: crm_id_type, var: crm_id_type}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: do_not_contact, var: do_not_contact}, {name: domain, var: domain}, {name: founded, var: founded}, {name: industry, var: industry}, {name: linkedin_url, var: linkedin_url}, {name: locale, var: locale}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: phone, var: phone}, {name: postal_code, var: postal_code}, {name: revenue_range, var: revenue_range}, {name: size, var: size}, {name: state, var: state}, {name: street, var: street}, {name: tags, var: tags}, {name: twitter_handle, var: twitter_handle}, {name: website, var: website}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    account_tier_id: $account_tier_id, city: $city, company_stage_id: $company_stage_id, company_type: $company_type, conversational_name: $conversational_name, country: $country, crm_id: $crm_id, crm_id_type: $crm_id_type, custom_fields: $custom_fields, description: $description, do_not_contact: $do_not_contact, domain: $domain, founded: $founded, industry: $industry, linkedin_url: $linkedin_url, locale: $locale, name: $name, owner_id: $owner_id, phone: $phone, postal_code: $postal_code, revenue_range: $revenue_range, size: $size, state: $state, street: $street, tags: $tags, twitter_handle: $twitter_handle, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an account
#
# DELETE /v2/accounts/{id}.json
export def "delete-v2-accounts-id-json" [
  id: string
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
    path: "/v2/accounts/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an account
#
# GET /v2/accounts/{id}.json
# Returns: record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>
export def "get-v2-accounts-id-json" [
  id: string
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
    path: "/v2/accounts/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing Account
#
# PUT /v2/accounts/{id}.json
# Returns: record<account_tier: record<_href: string, id: int>, archived_at: string, city: string, company_stage: record<_href: string, id: int>, company_type: string, conversational_name: string, country: string, counts: record<people: int>, created_at: string, creator: record<_href: string, id: int>, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, description: string, do_not_contact: bool, domain: string, founded: string, id: int, industry: string, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_person: record<_href: string, id: int>, last_contacted_type: string, linkedin_url: string, locale: string, name: string, owner: record<_href: string, id: int>, owner_crm_id: string, phone: string, postal_code: string, revenue_range: string, size: string, state: string, street: string, tags: list<string>, twitter_handle: string, updated_at: string, user_relationships: record, website: string>
export def "put-v2-accounts-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-tier-id: int # ID of the Account Tier for this Account
  --archived: oneof<nothing, bool> # Whether this Account should be archived or not. Setting this to true sets archived_at to the current time if it's not already set. Setting this to false will set archived_at to null
  --city: string # City
  --company-stage-id: int # ID of the CompanyStage assigned to this Account
  --company-type: string # Type of the Account's company
  --conversational-name: string # Conversational name of the Account
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either an Account (001) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "account:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: list # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --description: string # Description
  --do-not-contact: oneof<nothing, bool> # Whether this company can not be contacted. Values are either true or false. Setting this to true will remove all associated people from all active communications
  domain: string # Website domain, not a fully qualified URI
  --founded: string # Date or year of founding
  --industry: string # Industry
  --linkedin-url: string # Full LinkedIn url
  --locale: string # Time locale
  name: string # Account Full Name
  --owner-id: int # ID of the User that owns this Account
  --phone: string # Phone number without formatting
  --postal-code: string # Postal code
  --revenue-range: string # Estimated revenue range
  --size: string # Estimated number of people in employment
  --state: string # State
  --street: string # Street name and number
  --tags: list<string> # All tags applied to this Account
  --twitter-handle: string # Twitter handle, with @
  --website: string # Website
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/accounts/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: account_tier_id, var: account_tier_id}, {name: archived, var: archived}, {name: city, var: city}, {name: company_stage_id, var: company_stage_id}, {name: company_type, var: company_type}, {name: conversational_name, var: conversational_name}, {name: country, var: country}, {name: crm_id, var: crm_id}, {name: crm_id_type, var: crm_id_type}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: do_not_contact, var: do_not_contact}, {name: domain, var: domain}, {name: founded, var: founded}, {name: industry, var: industry}, {name: linkedin_url, var: linkedin_url}, {name: locale, var: locale}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: phone, var: phone}, {name: postal_code, var: postal_code}, {name: revenue_range, var: revenue_range}, {name: size, var: size}, {name: state, var: state}, {name: street, var: street}, {name: tags, var: tags}, {name: twitter_handle, var: twitter_handle}, {name: website, var: website}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, account_tier_id: $account_tier_id, archived: $archived, city: $city, company_stage_id: $company_stage_id, company_type: $company_type, conversational_name: $conversational_name, country: $country, crm_id: $crm_id, crm_id_type: $crm_id_type, custom_fields: $custom_fields, description: $description, do_not_contact: $do_not_contact, domain: $domain, founded: $founded, industry: $industry, linkedin_url: $linkedin_url, locale: $locale, name: $name, owner_id: $owner_id, phone: $phone, postal_code: $postal_code, revenue_range: $revenue_range, size: $size, state: $state, street: $street, tags: $tags, twitter_handle: $twitter_handle, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List call instructions
#
# GET /v2/action_details/call_instructions.json
# Returns: table<created_at: string, id: int, instructions: string, updated_at: string>
export def "get-v2-action-details-call-instructions-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of call instructions to fetch.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/action_details/call_instructions.json"
    query: [{name: ids, var: ids, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a call instructions
#
# GET /v2/action_details/call_instructions/{id}.json
# Returns: record<created_at: string, id: int, instructions: string, updated_at: string>
export def "get-v2-action-details-call-instructions-id-json" [
  id: string
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
    path: "/v2/action_details/call_instructions/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List actions
#
# GET /v2/actions.json
# Returns: table<action_details: record<_href: string, id: int>, cadence: record<_href: string, id: int>, created_at: string, due: bool, due_on: string, id: int, multitouch_group_id: int, person: record<_href: string, id: int>, status: string, step: record<_href: string, id: int>, type: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-actions-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of actions to fetch.
  --step-id: int # Fetch actions by step ID
  --type: string # Filter actions by type
  --due-on: list<string> # Equality filters that are applied to the due_on field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guid: list<string> # Filters actions by the user's guid. Multiple user guids can be applied. The user must be a team admin to filter other users' actions
  --person-id: list<int> # Filters actions by person_id. Multiple person ids can be applied
  --cadence-id: list<int> # Filters actions by cadence_id. Multiple cadence ids can be applied
  --multitouch-group-id: list<int> # Filters actions by multitouch_group_id. Multiple multitouch group ids can be applied
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/actions.json"
    query: [{name: ids, var: ids, style: csv}, {name: step_id, var: step_id}, {name: type, var: type}, {name: due_on, var: due_on, style: csv}, {name: user_guid, var: user_guid, style: csv}, {name: person_id, var: person_id, style: csv}, {name: cadence_id, var: cadence_id, style: csv}, {name: multitouch_group_id, var: multitouch_group_id, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, step_id: $step_id, type: $type, due_on: $due_on, user_guid: $user_guid, person_id: $person_id, cadence_id: $cadence_id, multitouch_group_id: $multitouch_group_id, updated_at: $updated_at, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an action
#
# GET /v2/actions/{id}.json
# Returns: record<action_details: record<_href: string, id: int>, cadence: record<_href: string, id: int>, created_at: string, due: bool, due_on: string, id: int, multitouch_group_id: int, person: record<_href: string, id: int>, status: string, step: record<_href: string, id: int>, type: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-actions-id-json" [
  id: string
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
    path: "/v2/actions/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an activity
#
# POST /v2/activities.json
# Returns: record<updated_at: string>
export def "post-v2-activities-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-id: int # Action that is being completed. This will validate that the action is still valid before completed it. The same action can never be successfully passed twice to this endpoint. The action must have a type of 'integration'.
  --task-id: int # Task that is being completed. This will validate that the task is still valid before completed it. The same action can never be successfully passed twice to this endpoint. The task must have a type of 'integration'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/activities.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: action_id, var: action_id}, {name: task_id, var: task_id}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    action_id: $action_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List calls
#
# GET /v2/activities/calls.json
# Returns: table<action: record<_href: string, id: int>, cadence: record<_href: string, id: int>, called_person: record<_href: string, id: int>, created_at: string, crm_activity: record<_href: string, id: int>, disposition: string, duration: int, id: int, note: record<_href: string, id: int>, recordings: list<record>, sentiment: string, step: record<_href: string, id: int>, to: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-activities-calls-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of calls to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --created-at: list<string> # Equality filters that are applied to the created_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guid: list<string> # Filters list to only include guids
  --person-id: list<int> # Filters calls by person_id. Multiple person ids can be applied
  --sentiment: list<string> # Filters calls by sentiment. Sentiment matches are exact and case sensitive. Multiple sentiments are allowed.
  --disposition: list<string> # Filters calls by disposition. Disposition matches are exact and case sensitive. Multiple dispositions are allowed.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/activities/calls.json"
    query: [{name: ids, var: ids, style: csv}, {name: created_at, var: created_at, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: user_guid, var: user_guid, style: csv}, {name: person_id, var: person_id, style: csv}, {name: sentiment, var: sentiment, style: csv}, {name: disposition, var: disposition, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, created_at: $created_at, updated_at: $updated_at, user_guid: $user_guid, person_id: $person_id, sentiment: $sentiment, disposition: $disposition, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a call
#
# POST /v2/activities/calls.json
# Returns: record<action: record<_href: string, id: int>, cadence: record<_href: string, id: int>, called_person: record<_href: string, id: int>, created_at: string, crm_activity: record<_href: string, id: int>, disposition: string, duration: int, id: int, note: record<_href: string, id: int>, recordings: table<recording_status: string, status: string, url: string>, sentiment: string, step: record<_href: string, id: int>, to: string, updated_at: string, user: record<_href: string, id: int>>
export def "post-v2-activities-calls-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-id: int # Action that this call is being logged for. This will validate that the action is still valid before completing it. The same action can never be successfully passed twice to this endpoint. The action must have a type of 'phone'.
  --crm-params: record # CRM specific parameters. Some parameters are required on a per-team basis. Consume the CrmActivityFields endpoint to receive a list of valid parameters. The "field" property is passed as the key of this object, and the value of this object is the value that you would like to set. If CrmActivityField has a non-null value, then that value must be submitted, or excluded from API calls, as these values are automatically applied.
  --disposition: string # The disposition of the call. Can be required on a per-team basis. Must be present in the disposition list.
  --duration: int # The length of the call, in seconds
  --linked-call-data-record-ids: list<int> # CallDataRecord associations that will become linked to the created call. It is possible to pass multiple CallDataRecord ids in this field; this can be used to represent multiple phone calls that made up a single call. Any call data record that is used must not already be linked to a call. It is not possible to link a call data record to multiple calls, and it is not possible to re-assign a call data record to a different call.
  --notes: string # Notes to log for the call. This is similar to the notes endpoint, but ensures that the notes get synced to the user's CRM
  person_id: int # The ID of the person whom this call will be logged for
  --sentiment: string # The sentiment of the call. Can be required on a per-team basis. Must be present in the sentiment list.
  --to: string # The phone number that was called
  --user-guid: string # Guid of the user whom this call should be logged for. Defaults to the authenticated user. Only team admins can pass another user's guid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/activities/calls.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: action_id, var: action_id}, {name: crm_params, var: crm_params}, {name: disposition, var: disposition}, {name: duration, var: duration}, {name: linked_call_data_record_ids, var: linked_call_data_record_ids}, {name: notes, var: notes}, {name: person_id, var: person_id}, {name: sentiment, var: sentiment}, {name: to, var: to}, {name: user_guid, var: user_guid}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    action_id: $action_id, crm_params: $crm_params, disposition: $disposition, duration: $duration, linked_call_data_record_ids: $linked_call_data_record_ids, notes: $notes, person_id: $person_id, sentiment: $sentiment, to: $to, user_guid: $user_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a call
#
# GET /v2/activities/calls/{id}.json
# Returns: record<action: record<_href: string, id: int>, cadence: record<_href: string, id: int>, called_person: record<_href: string, id: int>, created_at: string, crm_activity: record<_href: string, id: int>, disposition: string, duration: int, id: int, note: record<_href: string, id: int>, recordings: table<recording_status: string, status: string, url: string>, sentiment: string, step: record<_href: string, id: int>, to: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-activities-calls-id-json" [
  id: string
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
    path: "/v2/activities/calls/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List emails
#
# GET /v2/activities/emails.json
# Returns: table<action: record<_href: string, id: int>, bounced: bool, cadence: record<_href: string, id: int>, click_tracking: bool, counts: record<attachments: int, clicks: int, replies: int, unique_devices: int, unique_locations: int, views: int>, created_at: string, crm_activity: record<_href: string, id: int>, email_template: record<_href: string, id: int>, error_message: string, headers: record, id: int, mailing: record<_href: string, id: int>, personalization: string, recipient: record<_href: string, id: int>, recipient_email_address: string, send_after: string, sent_at: string, status: string, step: record<_href: string, id: int>, subject: string, task: record<_href: string, id: int>, updated_at: string, user: record<_href: string, id: int>, view_tracking: bool>
export def "get-v2-activities-emails-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of emails to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --bounced: oneof<nothing, bool> # Filters emails by whether they have bounced or not
  --crm-activity-id: list<int> # Filters emails by crm_activity_id. Multiple crm activty ids can be applied
  --action-id: list<int> # Filters emails by action_id. Multiple action ids can be applied
  --user-id: list<int> # Filters emails by user_id. Multiple User ids can be applied
  --status: list<string> # Filters emails by status. Multiple status can be applied, possible values are sent, sent_from_gmail, sent_from_external, pending, pending_reply_check, scheduled, sending, delivering, failed, cancelled, pending_through_gmail, pending_through_external
  --cadence-id: list<int> # Filters emails by cadence. Multiple cadence ids can be applied
  --step-id: list<int> # Filters emails by step. Multiple step ids can be applied
  --one-off: oneof<nothing, bool> # Filters emails by one-off only
  --scoped-fields: list<string> # Specify explicit scoped fields desired on the Email Resource.
  --person-id: list<int> # Filters emails by person_id. Multiple person ids can be applied
  --email-addresses: list<string> # Filters emails by recipient email address. Multiple emails can be applied.
  --personalization: list<string> # Filters emails by personalization score
  --sent-at: list<string> # Equality filters that are applied to the sent_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: updated_at, send_time. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/activities/emails.json"
    query: [{name: ids, var: ids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: bounced, var: bounced}, {name: crm_activity_id, var: crm_activity_id, style: csv}, {name: action_id, var: action_id, style: csv}, {name: user_id, var: user_id, style: csv}, {name: status, var: status, style: csv}, {name: cadence_id, var: cadence_id, style: csv}, {name: step_id, var: step_id, style: csv}, {name: one_off, var: one_off}, {name: scoped_fields, var: scoped_fields, style: csv}, {name: person_id, var: person_id, style: csv}, {name: email_addresses, var: email_addresses, style: csv}, {name: personalization, var: personalization, style: csv}, {name: sent_at, var: sent_at, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, updated_at: $updated_at, bounced: $bounced, crm_activity_id: $crm_activity_id, action_id: $action_id, user_id: $user_id, status: $status, cadence_id: $cadence_id, step_id: $step_id, one_off: $one_off, scoped_fields: $scoped_fields, person_id: $person_id, email_addresses: $email_addresses, personalization: $personalization, sent_at: $sent_at, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an email
#
# GET /v2/activities/emails/{id}.json
# Returns: record<action: record<_href: string, id: int>, bounced: bool, cadence: record<_href: string, id: int>, click_tracking: bool, counts: record<attachments: int, clicks: int, replies: int, unique_devices: int, unique_locations: int, views: int>, created_at: string, crm_activity: record<_href: string, id: int>, email_template: record<_href: string, id: int>, error_message: string, headers: record, id: int, mailing: record<_href: string, id: int>, personalization: string, recipient: record<_href: string, id: int>, recipient_email_address: string, send_after: string, sent_at: string, status: string, step: record<_href: string, id: int>, subject: string, task: record<_href: string, id: int>, updated_at: string, user: record<_href: string, id: int>, view_tracking: bool>
export def "get-v2-activities-emails-id-json" [
  id: string
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
    path: "/v2/activities/emails/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Past Activities
#
# GET /v2/activity_histories
# Returns: record<created_at: string, dynamic_data: record, failed_dynamic_resources: record, id: int, occurred_at: string, pinned_at: string, resource_id: int, resource_type: int, static_data: record, type: string, updated_at: string, user_guid: string>
export def "get-v2-activity-histories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --sort-by: string # Key to sort on, must be one of: occurred_at, updated_at. Defaults to occurred_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --type: string # Filter by the type of activity. Must be one of: added_to_cadence, completed_action, call, requested_email, sent_email, received_email, email_reply, note, success, dnc_event, residency_change, meeting, meeting_held, message_conversation, task, voicemail, opportunity_stage_change, opportunity_amount_change, opportunity_close_date_change. Can be provided as an array, or as an object of type[resource_type][]=type
  --resource: string # For internal use only. This field does not comply with our backwards compatibility policies. This filter is for authenticated users of Salesloft only and will not work for OAuth Applications. Filter by the {resource_type, resource_id} of activity. Provide this in the format resource[]=person,1234
  --occurred-at: record # Equality filters that are applied to the occurred_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"keys":[{"description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gt","type":"iso8601 string"},{"description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gte","type":"iso8601 string"},{"description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lt","type":"iso8601 string"},{"description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lte","type":"iso8601 string"}],"type":"object"}
  --pinned: oneof<nothing, bool> # Filter by the pinned status of activity. Must be 'true' or 'false'
  --resource-type: string # Filter by the resource type. A resource is a Salesloft object that the activity is attributed to. A valid resource types must be one of person, account, crm_opportunity. Can be provided as an array
  --resource-id: list<string> # Filter by the resource id. "resource_type" filter is required to use this filter.
  --updated-at: record # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"keys":[{"description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gt","type":"iso8601 string"},{"description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gte","type":"iso8601 string"},{"description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lt","type":"iso8601 string"},{"description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lte","type":"iso8601 string"}],"type":"object"}
  --user-guid: string # Filter activities by a user's guid.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/activity_histories"
    query: [{name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: type, var: type}, {name: _resource, var: resource}, {name: occurred_at, var: occurred_at, style: multi}, {name: pinned, var: pinned}, {name: resource_type, var: resource_type}, {name: resource_id, var: resource_id, style: csv}, {name: updated_at, var: updated_at, style: multi}, {name: user_guid, var: user_guid}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, sort_by: $sort_by, sort_direction: $sort_direction, type: $type, resource: $resource, occurred_at: $occurred_at, pinned: $pinned, resource_type: $resource_type, resource_id: $resource_id, updated_at: $updated_at, user_guid: $user_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bulk jobs
#
# GET /v2/bulk_jobs
# Returns: table<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>
export def "get-v2-bulk-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: list<string> # The state of the bulk job. Accepts multiple states. Each state must be one of: open, executing, done
  --id: record # Filter by id using comparison operators. Only supports greater than (gt) comparison (i.e. id[gt]=123)
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/bulk_jobs"
    query: [{name: state, var: state, style: csv}, {name: id, var: id, style: multi}, {name: per_page, var: per_page}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    state: $state, id: $id, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a bulk job
#
# POST /v2/bulk_jobs
# Returns: record<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>
export def "post-v2-bulk-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name for your bulk job
  type: string # Type of bulk job. Must be a valid type. Follow link to the bulk job details page above to view supported types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/bulk_jobs"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: type, var: type}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List job data for a bulk job
#
# GET /v2/bulk_jobs/{bulk_jobs_id}/job_data
# Returns: table<error: string, id: int, record: record, resource: record, status: string>
export def "get-v2-bulk-jobs-bulk-jobs-id-job-data" [
  bulk_jobs_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list<string> # Filter by result status. Accepts multiple statuses. Each status must be one of pending, success, error, retrying
  --id: record # Filter by id using comparison operators. Only supports greater than (gt) comparison (i.e. id[gt]=123)
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/bulk_jobs/{bulk_jobs_id}/job_data"
    path_params: [{name: bulk_jobs_id, var: bulk_jobs_id}]
    query: [{name: status, var: status, style: csv}, {name: id, var: id, style: multi}, {name: per_page, var: per_page}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    bulk_jobs_id: $bulk_jobs_id, status: $status, id: $id, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create job data for a bulk job
#
# POST /v2/bulk_jobs/{bulk_jobs_id}/job_data
# Returns: record<records: int>
export def "post-v2-bulk-jobs-bulk-jobs-id-job-data" [
  bulk_jobs_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list<string> # Array of objects containing parameters to be used to execute an instance of each. Array must be 5,000 records or less.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/bulk_jobs/{bulk_jobs_id}/job_data"
    path_params: [{name: bulk_jobs_id, var: bulk_jobs_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: data, var: data}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    bulk_jobs_id: $bulk_jobs_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List job data for a completed bulk job.
#
# GET /v2/bulk_jobs/{bulk_jobs_id}/results
# Returns: table<error: string, id: int, record: record, resource: record, status: string>
export def "get-v2-bulk-jobs-bulk-jobs-id-results" [
  bulk_jobs_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: list<string> # Filter by result status. Accepts multiple statuses. Each status must be one of pending, success, error, retrying
  --id: record # Filter by id using comparison operators. Only supports greater than (gt) comparison (i.e. id[gt]=123)
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/bulk_jobs/{bulk_jobs_id}/results"
    path_params: [{name: bulk_jobs_id, var: bulk_jobs_id}]
    query: [{name: status, var: status, style: csv}, {name: id, var: id, style: multi}, {name: per_page, var: per_page}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    bulk_jobs_id: $bulk_jobs_id, status: $status, id: $id, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a bulk job
#
# GET /v2/bulk_jobs/{id}
# Returns: record<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>
export def "get-v2-bulk-jobs-id" [
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
    path: "/v2/bulk_jobs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a bulk job
#
# PUT /v2/bulk_jobs/{id}
# Returns: record<created_at: string, errors: int, finished_at: string, id: int, marked_ready_at: string, name: string, processed: int, ready_to_execute: bool, scopes: list<any>, started_at: string, state: string, total: int, type: string, updated_at: string>
export def "put-v2-bulk-jobs-id" [
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
  --name: string # Name for your bulk job
  --ready-to-execute: oneof<nothing, bool> # Whether the job is ready to be executed. Must be true or false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/bulk_jobs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: ready_to_execute, var: ready_to_execute}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, ready_to_execute: $ready_to_execute
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export a cadence
#
# GET /v2/cadence_exports/{id}.json
# Returns: record<cadence_content: record>
export def "get-v2-cadence-exports-id-json" [
  id: string
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
    path: "/v2/cadence_exports/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import cadences from JSON
#
# POST /v2/cadence_imports.json
# Returns: record<cadence: record<_href: string, id: int>>
export def "post-v2-cadence-imports-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cadence-content: record # Import data for cadence
  --settings: record # Settings for a cadence
  --sharing-settings: record # The shared settings for a cadence
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/cadence_imports.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: cadence_content, var: cadence_content}, {name: settings, var: settings}, {name: sharing_settings, var: sharing_settings}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    cadence_content: $cadence_content, settings: $settings, sharing_settings: $sharing_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List cadence memberships
#
# GET /v2/cadence_memberships.json
# Returns: table<added_at: string, cadence: record<_href: string, id: int>, counts: record<bounces: int, calls: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, current_state: string, currently_on_cadence: bool, id: int, latest_action: record<_href: string, id: int>, person: record<_href: string, id: int>, person_deleted: bool, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-cadence-memberships-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of cadence memberships to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --person-id: int # ID of the person to find cadence memberships for
  --cadence-id: int # ID of the cadence to find cadence memberships for
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --currently-on-cadence: oneof<nothing, bool> # If true, return only cadence memberships for people currently on cadences. If false, return cadence memberships for people who have been removed from or have completed a cadence.
  --sort-by: string # Key to sort on, must be one of: added_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/cadence_memberships.json"
    query: [{name: ids, var: ids, style: csv}, {name: person_id, var: person_id}, {name: cadence_id, var: cadence_id}, {name: updated_at, var: updated_at, style: csv}, {name: currently_on_cadence, var: currently_on_cadence}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, person_id: $person_id, cadence_id: $cadence_id, updated_at: $updated_at, currently_on_cadence: $currently_on_cadence, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a cadence membership
#
# POST /v2/cadence_memberships.json
# Returns: record<added_at: string, cadence: record<_href: string, id: int>, counts: record<bounces: int, calls: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, current_state: string, currently_on_cadence: bool, id: int, latest_action: record<_href: string, id: int>, person: record<_href: string, id: int>, person_deleted: bool, updated_at: string, user: record<_href: string, id: int>>
export def "post-v2-cadence-memberships-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --person-id: int # ID of the person to create a cadence membership for (required)
  --cadence-id: int # ID of the cadence to create a cadence membership for (required)
  --user-id: int # ID of the user to create a cadence membership for. The associated cadence must be owned by the user, or it must be a team cadence
  --step-id: int # ID of the step on which the person should start the cadence. Start on first step is the default behavior without this parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v2/cadence_memberships.json"
    query: [{name: person_id, var: person_id, required: true}, {name: cadence_id, var: cadence_id, required: true}, {name: user_id, var: user_id}, {name: step_id, var: step_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    person_id: $person_id, cadence_id: $cadence_id, user_id: $user_id, step_id: $step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a cadence membership
#
# DELETE /v2/cadence_memberships/{id}.json
export def "delete-v2-cadence-memberships-id-json" [
  id: string
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
    path: "/v2/cadence_memberships/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a cadence membership
#
# GET /v2/cadence_memberships/{id}.json
# Returns: record<added_at: string, cadence: record<_href: string, id: int>, counts: record<bounces: int, calls: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, current_state: string, currently_on_cadence: bool, id: int, latest_action: record<_href: string, id: int>, person: record<_href: string, id: int>, person_deleted: bool, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-cadence-memberships-id-json" [
  id: string
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
    path: "/v2/cadence_memberships/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List cadences
#
# GET /v2/cadences.json
# Returns: table<added_stage: record<_href: string, id: int>, archived_at: string, bounced_stage: record<_href: string, id: int>, cadence_framework_id: int, cadence_function: string, cadence_priority: record<_href: string, id: int>, counts: record<cadence_people: int, meetings_booked: int, opportunities_created: int, people_acted_on_count: int, target_daily_people: int>, created_at: string, creator: record<_href: string, id: int>, draft: bool, external_identifier: string, finished_stage: record<_href: string, id: int>, groups: list<record>, id: int, name: string, opt_out_link_included: bool, owner: record<_href: string, id: int>, remove_bounces_enabled: bool, remove_replies_enabled: bool, replied_stage: record<_href: string, id: int>, shared: bool, tags: list<string>, team_cadence: bool, updated_at: string>
export def "get-v2-cadences-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of cadences to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --team-cadence: oneof<nothing, bool> # Filters cadences by whether they are a team cadence or not
  --shared: oneof<nothing, bool> # Filters cadences by whether they are shared
  --owned-by-guid: list<string> # Filters cadences by the owner's guid. Multiple owner guids can be applied
  --people-addable: oneof<nothing, bool> # Filters cadences by whether they are able to have people added to them
  --name: list<string> # Filters cadences by name
  --group-ids: string # Filters by group ids. Also supports group ids passed in as a JSON array string
  --archived: oneof<nothing, bool> # Filters by whether the Cadences have been archived. Excluding this field will result in both archived and unarchived Cadences to return.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, name. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/cadences.json"
    query: [{name: ids, var: ids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: team_cadence, var: team_cadence}, {name: shared, var: shared}, {name: owned_by_guid, var: owned_by_guid, style: csv}, {name: people_addable, var: people_addable}, {name: name, var: name, style: csv}, {name: group_ids, var: group_ids}, {name: archived, var: archived}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, updated_at: $updated_at, team_cadence: $team_cadence, shared: $shared, owned_by_guid: $owned_by_guid, people_addable: $people_addable, name: $name, group_ids: $group_ids, archived: $archived, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a cadence
#
# GET /v2/cadences/{id}.json
# Returns: record<added_stage: record<_href: string, id: int>, archived_at: string, bounced_stage: record<_href: string, id: int>, cadence_framework_id: int, cadence_function: string, cadence_priority: record<_href: string, id: int>, counts: record<cadence_people: int, meetings_booked: int, opportunities_created: int, people_acted_on_count: int, target_daily_people: int>, created_at: string, creator: record<_href: string, id: int>, draft: bool, external_identifier: string, finished_stage: record<_href: string, id: int>, groups: table<_href: string, id: int>, id: int, name: string, opt_out_link_included: bool, owner: record<_href: string, id: int>, remove_bounces_enabled: bool, remove_replies_enabled: bool, replied_stage: record<_href: string, id: int>, shared: bool, tags: list<string>, team_cadence: bool, updated_at: string>
export def "get-v2-cadences-id-json" [
  id: string
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
    path: "/v2/cadences/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List calendar events
#
# GET /v2/calendar/events
# Returns: table<all_day: string, attendees: record, body_html: string, busy: bool, calendar_id: string, canceled_at: string, conference_data: record, created_at: string, creator: record, description: string, end_time: string, extended_properties: record, html_link: string, i_cal_uid: string, id: string, location: string, organizer: string, provider: string, recurring: string, start_time: string, status: string, tenant_id: int, title: string, updated_at: string, user_guid: string>
export def "get-v2-calendar-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --sort-by: string # Key to sort on, must be one of: start_time. Defaults to start_time
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --start-time: string # Lower bound (inclusive) for a calendar event's end time to filter by. Must be in ISO 8601 format. Example: `2022-02-14T10:12:59+00:00`.
  --end-time: string # Upper bound (exclusive) for a calendar event's start time to filter by. Must be in ISO 8601 format. Example: `2022-02-14T10:12:59+00:00`.
  --user-guid: string # user_guid of the user who created or included as a guest to the event.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/calendar/events"
    query: [{name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: user_guid, var: user_guid}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, sort_by: $sort_by, sort_direction: $sort_direction, start_time: $start_time, end_time: $end_time, user_guid: $user_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert a calendar event
#
# POST /v2/calendar/events/upsert
# Returns: record<all_day: string, attendees: record, body_html: string, busy: bool, calendar_id: string, canceled_at: string, conference_data: record, created_at: string, creator: record, description: string, end_time: string, extended_properties: record, html_link: string, i_cal_uid: string, id: string, location: string, organizer: string, provider: string, recurring: string, start_time: string, status: string, tenant_id: int, title: string, updated_at: string, user_guid: string>
export def "post-v2-calendar-events-upsert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all-day: oneof<nothing, bool> # Should be set to `true` for all day calendar events.
  --attendees: record # List of attendees of the calendar event. Example: ``` { ... "attendees": [ { "name": "Alice", "email": "alice@example.com", "status": "accepted", "organizer": true }, { "name": "Bob", "email": "bob@example.com", "status": "needsAction", "organizer": false } ] } ``` `name`: full name of the attendee `email`: email address of the attendee `status`: one of the following - needsAction, accepted, tentative, declined `organizer`: whether the attendee is the organizer of the calendar event
  calendar_id: string # Calendar ID of the calendar event owner. For the External Calendar connection use `external_{salesloft_user_guid}` format. Example: `external_00210d1a-df8a-459f-af75-89b953b618b0`.
  --canceled-at: string # Cancellation time of the calendar event, as a combined date-time value in the ISO 8601 format with a time zone offset. Example: `2022-02-14T10:12:59+00:00`.
  --description: string # Description of the calendar event
  end_time: string # End time of the calendar event, as a combined date-time value in the ISO 8601 format with a time zone offset. Example: `2022-02-14T10:12:59+00:00`. (format: date)
  i_cal_uid: string # icalUID of the calendar event. Unique identifier for a calendar event across calendars. Used as an upsert key.
  id: string # Id of the calendar event, different for each occurrence in a recurring series. Used as an upsert key.
  --location: string # Location of the calendar event as free-form text.
  --organizer: string # Email address of the organizer
  --recurring: oneof<nothing, bool> # Should be set to `true` if this is one of recurring series calendar event.
  start_time: string # Start time of the calendar event, as a combined date-time value in the ISO 8601 format with a time zone offset. Example: `2022-02-14T10:12:59+00:00`. (format: date)
  --status: string # Status of the calendar event. Depending on the status, the calendar event will or will not impact user's availability. Possible values: `confirmed`, `tentative`, `cancelled`. Example: `confirmed`.
  --title: string # Title of the calendar event
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/calendar/events/upsert"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: all_day, var: all_day}, {name: attendees, var: attendees}, {name: calendar_id, var: calendar_id}, {name: canceled_at, var: canceled_at}, {name: description, var: description}, {name: end_time, var: end_time}, {name: i_cal_uid, var: i_cal_uid}, {name: id, var: id}, {name: location, var: location}, {name: organizer, var: organizer}, {name: recurring, var: recurring}, {name: start_time, var: start_time}, {name: status, var: status}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [201]
    auth: bearer
  } {
    all_day: $all_day, attendees: $attendees, calendar_id: $calendar_id, canceled_at: $canceled_at, description: $description, end_time: $end_time, i_cal_uid: $i_cal_uid, id: $id, location: $location, organizer: $organizer, recurring: $recurring, start_time: $start_time, status: $status, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List call data records
#
# GET /v2/call_data_records.json
# Returns: table<call: record<_href: string, id: int>, call_type: string, call_uuid: string, called_person: record<_href: string, id: int>, created_at: string, direction: string, duration: int, from: string, id: int, recording: record<recording_status: string, status: string, url: string>, status: string, to: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-call-data-records-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of call data records to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --has-call: oneof<nothing, bool> # Return only call data records which have or do not have a call logged for them
  --created-at: list<string> # Equality filters that are applied to the created_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guid: list<string> # Filters list to only include guids
  --person-id: list<int> # Filters list by person_id. Multiple person ids can be applied
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/call_data_records.json"
    query: [{name: ids, var: ids, style: csv}, {name: has_call, var: has_call}, {name: created_at, var: created_at, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: user_guid, var: user_guid, style: csv}, {name: person_id, var: person_id, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, has_call: $has_call, created_at: $created_at, updated_at: $updated_at, user_guid: $user_guid, person_id: $person_id, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a call data record
#
# GET /v2/call_data_records/{id}.json
# Returns: record<call: record<_href: string, id: int>, call_type: string, call_uuid: string, called_person: record<_href: string, id: int>, created_at: string, direction: string, duration: int, from: string, id: int, recording: record<recording_status: string, status: string, url: string>, status: string, to: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-call-data-records-id-json" [
  id: string
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
    path: "/v2/call_data_records/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List call dispositions
#
# GET /v2/call_dispositions.json
# Returns: table<created_at: string, id: int, name: string, updated_at: string>
export def "get-v2-call-dispositions-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # Key to sort on, must be one of: name, updated_at. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/call_dispositions.json"
    query: [{name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List call sentiments
#
# GET /v2/call_sentiments.json
# Returns: table<created_at: string, id: int, name: string, updated_at: string>
export def "get-v2-call-sentiments-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filters call sentiments by name
  --sort-by: string # Key to sort on, must be one of: name, updated_at. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/call_sentiments.json"
    query: [{name: name, var: name}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Conversations Call
#
# POST /v2/conversations/calls
# Returns: record<call_created_at: string, direction: string, duration: float, from: string, recording: record, to: string, user_guid: string>
export def "post-v2-conversations-calls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-created-at: string # Timestamp for when the call started. If not provided, will default to the time the request was received
  --direction: string # Call direction
  duration: float # Duration of call in seconds
  from: string # Phone number that call was made from
  recording: record # Object containing recording info including the audio file (.mp3, .wav, .ogg, .m4a)
  to: string # Phone number that was called
  --user-guid: string # Guid of the Salesloft User to assign the call to. If not provided, will default to the user within the authentication token
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/conversations/calls"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: call_created_at, var: call_created_at}, {name: direction, var: direction}, {name: duration, var: duration}, {name: from, var: from}, {name: recording, var: recording}, {name: to, var: to}, {name: user_guid, var: user_guid}]}
    accept: ["*/*"]
    ok: [201]
    auth: bearer
  } {
    call_created_at: $call_created_at, direction: $direction, duration: $duration, from: $from, recording: $recording, to: $to, user_guid: $user_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List crm activities
#
# GET /v2/crm_activities.json
# Returns: table<activity_type: string, created_at: string, crm_id: string, custom_crm_fields: record, description: string, error: string, id: int, person: record<_href: string, id: int>, subject: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-crm-activities-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of crm activities to fetch.
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/crm_activities.json"
    query: [{name: ids, var: ids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, updated_at: $updated_at, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a crm activity
#
# GET /v2/crm_activities/{id}.json
# Returns: record<activity_type: string, created_at: string, crm_id: string, custom_crm_fields: record, description: string, error: string, id: int, person: record<_href: string, id: int>, subject: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-crm-activities-id-json" [
  id: string
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
    path: "/v2/crm_activities/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List crm activity fields
#
# GET /v2/crm_activity_fields.json
# Returns: table<created_at: string, crm_object_type: string, field: string, field_type: string, id: int, picklist_values: record, salesforce_object_type: string, source: string, title: string, updated_at: string, value: string>
export def "get-v2-crm-activity-fields-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # Return only records with this source
  --sort-by: string # Key to sort on, must be one of: title, updated_at. Defaults to title
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/crm_activity_fields.json"
    query: [{name: source, var: source}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    source: $source, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List crm users
#
# GET /v2/crm_users.json
# Returns: table<created_at: string, crm_id: string, id: int, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-crm-users-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of crm users to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --crm-id: list<string> # Filters crm users by crm_ids
  --user-id: list<int> # Filters crm users by user_ids
  --user-guid: list<string> # Filters crm users by user guids
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
  --sort-by: string # Key to sort on, must be one of: id, updated_at. Defaults to id
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/crm_users.json"
    query: [{name: ids, var: ids, style: csv}, {name: crm_id, var: crm_id, style: csv}, {name: user_id, var: user_id, style: csv}, {name: user_guid, var: user_guid, style: csv}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, crm_id: $crm_id, user_id: $user_id, user_guid: $user_guid, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts, sort_by: $sort_by, sort_direction: $sort_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List custom fields
#
# GET /v2/custom_fields.json
# Returns: table<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>
export def "get-v2-custom-fields-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of custom fields to fetch.
  --field-type: string # Type of field to fetch. Value must be one of: person, company, opportunity
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, name. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/custom_fields.json"
    query: [{name: ids, var: ids, style: csv}, {name: field_type, var: field_type}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, field_type: $field_type, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a custom field
#
# POST /v2/custom_fields.json
# Returns: record<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>
export def "post-v2-custom-fields-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-type: string # The field type of the custom field. Value must be one of: person, company, opportunity
  name: string # The name of the custom field
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/custom_fields.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: field_type, var: field_type}, {name: name, var: name}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    field_type: $field_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a custom field
#
# DELETE /v2/custom_fields/{id}.json
export def "delete-v2-custom-fields-id-json" [
  id: string
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
    path: "/v2/custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a custom field
#
# GET /v2/custom_fields/{id}.json
# Returns: record<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>
export def "get-v2-custom-fields-id-json" [
  id: string
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
    path: "/v2/custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a custom field
#
# PUT /v2/custom_fields/{id}.json
# Returns: record<created_at: string, field_type: string, id: int, name: string, updated_at: string, value_type: string>
export def "put-v2-custom-fields-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-type: string # The field type of the custom field. Value must be one of: person, company, opportunity
  --name: string # The name of the custom field
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: field_type, var: field_type}, {name: name, var: name}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, field_type: $field_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List email template attachments
#
# GET /v2/email_template_attachments.json
# Returns: table<attachment_content_type: string, attachment_file_size: int, attachment_fingerprint: int, attachment_id: int, download_url: string, email_template: record<_href: string, id: int>, id: int, name: string, scanned: bool>
export def "get-v2-email-template-attachments-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of email template attachments to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --email-template-id: list<int> # Filters email template attachments by email template IDs
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/email_template_attachments.json"
    query: [{name: ids, var: ids, style: csv}, {name: email_template_id, var: email_template_id, style: csv}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, email_template_id: $email_template_id, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List email templates
#
# GET /v2/email_templates.json
# Returns: table<_links: record, archived_at: string, body: string, body_preview: string, cadence_template: bool, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, groups: list<record>, id: int, last_used_at: string, open_tracking_enabled: bool, shared: bool, subject: string, tags: list<string>, team_template: record<_href: string, id: int>, template_owner: record<_href: string, id: int>, title: string, updated_at: string>
export def "get-v2-email-templates-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of email templates to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --linked-to-team-template: oneof<nothing, bool> # Filters email templates by whether they are linked to a team template or not
  --search: string # Filters email templates by title or subject
  --tag-ids: list<int> # Filters email templates by tags applied to the template by tag ID, not to exceed 100 IDs
  --tag: list<string> # Filters email templates by tags applied to the template, not to exceed 100 tags
  --filter-by-owner: oneof<nothing, bool> # Filters email templates by current authenticated user
  --group-id: list<int> # Filters email templates by groups applied to the template by group ID. Not to exceed 500 IDs. Returns templates that are assigned to any of the group ids.
  --include-cadence-templates: oneof<nothing, bool> # Filters email templates based on whether or not the template has been used on a cadence
  --include-archived-templates: oneof<nothing, bool> # Filters email templates to include archived templates or not
  --cadence-id: list<int> # Filters email templates to those belonging to the cadence. Not to exceed 100 IDs. If a record can't be found, that record won't be returned and your request will be successful
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_used_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/email_templates.json"
    query: [{name: ids, var: ids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: linked_to_team_template, var: linked_to_team_template}, {name: search, var: search}, {name: tag_ids, var: tag_ids, style: csv}, {name: tag, var: tag, style: csv}, {name: filter_by_owner, var: filter_by_owner}, {name: group_id, var: group_id, style: csv}, {name: include_cadence_templates, var: include_cadence_templates}, {name: include_archived_templates, var: include_archived_templates}, {name: cadence_id, var: cadence_id, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, updated_at: $updated_at, linked_to_team_template: $linked_to_team_template, search: $search, tag_ids: $tag_ids, tag: $tag, filter_by_owner: $filter_by_owner, group_id: $group_id, include_cadence_templates: $include_cadence_templates, include_archived_templates: $include_archived_templates, cadence_id: $cadence_id, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an email template
#
# GET /v2/email_templates/{id}.json
# Returns: record<_links: record, archived_at: string, body: string, body_preview: string, cadence_template: bool, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, groups: table<_href: string, id: int>, id: int, last_used_at: string, open_tracking_enabled: bool, shared: bool, subject: string, tags: list<string>, team_template: record<_href: string, id: int>, template_owner: record<_href: string, id: int>, title: string, updated_at: string>
export def "get-v2-email-templates-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-signature: oneof<nothing, bool> # Optionally will return the templates with the current user's email signature
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/email_templates/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: include_signature, var: include_signature}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_signature: $include_signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an External Email
#
# POST /v2/external_emails.json
# Returns: record<message_id: string>
export def "post-v2-external-emails-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  mailbox: string # Email address of mailbox email was sent to
  --body-raw: string # Base64 encoded MIME email content (spec name: raw)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/external_emails.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: mailbox, var: mailbox}, {name: raw, var: body_raw, required: true}]}
    accept: ["*/*"]
    ok: [201]
    auth: bearer
  } {
    mailbox: $mailbox, body_raw: $body_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List groups
#
# GET /v2/groups.json
# Returns: table<accessible_groups: list<record>, id: int, name: string, parent_id: int>
export def "get-v2-groups-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of groups to fetch.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/groups.json"
    query: [{name: ids, var: ids, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, sort_by: $sort_by, sort_direction: $sort_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a group
#
# GET /v2/groups/{id}.json
# Returns: record<accessible_groups: table<_href: string, id: int>, id: int, name: string, parent_id: int>
export def "get-v2-groups-id-json" [
  id: string
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
    path: "/v2/groups/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List imports
#
# GET /v2/imports.json
# Returns: table<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>
export def "get-v2-imports-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of imports to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --user-ids: list<int> # ID of users to fetch imports for. Using this filter will return an empty array for non-admin users who request other user's imports
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to created_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/imports.json"
    query: [{name: ids, var: ids, style: csv}, {name: user_ids, var: user_ids, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, user_ids: $user_ids, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an import
#
# POST /v2/imports.json
# Returns: record<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>
export def "post-v2-imports-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name, recommended to be easily identifiable to a user
  --user-id: int # ID of the User that owns this Import
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/imports.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: user_id, var: user_id}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an import
#
# DELETE /v2/imports/{id}.json
export def "delete-v2-imports-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --undo: string # Whether to delete people on this Import. Possible values are: [not present], all, single. 'single' will delete people who are only present in this Import. 'all' will delete people even if they are present in other Imports. Not specifying this parameter will not delete any people
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/imports/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: undo, var: undo}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, undo: $undo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an import
#
# GET /v2/imports/{id}.json
# Returns: record<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>
export def "get-v2-imports-id-json" [
  id: string
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
    path: "/v2/imports/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an import
#
# PUT /v2/imports/{id}.json
# Returns: record<created_at: string, current_people_count: int, id: int, imported_people_count: int, name: string, updated_at: string>
export def "put-v2-imports-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name, recommended to be easily identifiable to a user
  --user-id: int # ID of the User that owns this Import
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/imports/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: user_id, var: user_id}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Live Website Tracking Parameter
#
# POST /v2/live_website_tracking_parameters.json
# Returns: record<parameters: list<record>>
export def "post-v2-live-website-tracking-parameters-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  person_id: int # The person to create the LiveWebsiteTrackingParameter for
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/live_website_tracking_parameters.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: person_id, var: person_id}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    person_id: $person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch current user
#
# GET /v2/me.json
# Returns: record<_private_fields: record, active: bool, bcc_email_address: string, click_to_call_enabled: bool, created_at: string, crm_connected: bool, email: string, email_client_configured: bool, email_client_email_address: string, email_signature: string, email_signature_click_tracking_disabled: bool, email_signature_type: string, external_feature_flags: record, first_name: string, from_address: string, full_email_address: string, group: record<_href: string, id: int>, guid: string, id: int, job_role: string, last_name: string, local_dial_enabled: bool, name: string, phone_client: record<_href: string, id: int>, phone_number_assignment: record<_href: string, id: int>, role: record<_href: string, id: int>, sending_email_address: string, slack_username: string, team: record<_href: string, id: int>, team_admin: bool, time_zone: string, twitter_handle: string, updated_at: string, work_country: string>
export def "get-v2-me-json" [
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
    path: "/v2/me.json"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List meetings
#
# GET /v2/meetings.json
# Returns: table<account_id: string, all_day: bool, attendees: list<record>, booked_by_meetings_settings: record<email_address: string>, booked_by_user: record<_href: string, id: int>, cadence: record<_href: string, id: int>, calendar_id: string, calendar_type: string, canceled_at: string, created_at: string, crm_custom_fields: record, crm_references: record, description: string, end_time: string, event_id: string, event_source: string, guests: list<string>, i_cal_uid: string, id: int, location: string, meeting_type: string, no_show: bool, owned_by_meetings_settings: record<email_address: string>, person: record<_href: string, id: int>, recipient_email: string, recipient_name: string, start_time: string, status: string, step: record<_href: string, id: int>, strict_attribution: bool, task_id: string, title: string, updated_at: string>
export def "get-v2-meetings-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of meetings to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --status: string # Filters meetings by status. Possible values are: pending, booked, failed, retry
  --person-id: string # Filters meetings by person_id. Multiple person ids can be applied
  --account-id: string # Filters meetings by account_id. Multiple account ids can be applied
  --person-ids: list<int> # Filters meetings by person_id. Multiple person ids can be applied
  --event-ids: list<int> # Filters meetings by event IDs
  --i-cal-uids: list<string> # Filters meetings by UIDs provided by calendar provider
  --task-ids: list<int> # Filters meetings by task_id. Multiple task ids can be applied
  --include-meetings-settings: oneof<nothing, bool> # Flag to indicate whether to include owned_by_meetings_settings and booked_by_meetings_settings objects
  --start-time: list<string> # Equality filters that are applied to the start_time field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --user-guids: list<string> # Filters meetings by user_guid. Multiple user guids can be applied
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events in the result
  --sort-by: string # Key to sort on, must be one of: start_time, created_at, updated_at. Defaults to start_time
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/meetings.json"
    query: [{name: ids, var: ids, style: csv}, {name: status, var: status}, {name: person_id, var: person_id}, {name: account_id, var: account_id}, {name: person_ids, var: person_ids, style: csv}, {name: event_ids, var: event_ids, style: csv}, {name: i_cal_uids, var: i_cal_uids, style: csv}, {name: task_ids, var: task_ids, style: csv}, {name: include_meetings_settings, var: include_meetings_settings}, {name: start_time, var: start_time, style: csv}, {name: user_guids, var: user_guids, style: csv}, {name: show_deleted, var: show_deleted}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, status: $status, person_id: $person_id, account_id: $account_id, person_ids: $person_ids, event_ids: $event_ids, i_cal_uids: $i_cal_uids, task_ids: $task_ids, include_meetings_settings: $include_meetings_settings, start_time: $start_time, user_guids: $user_guids, show_deleted: $show_deleted, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List meeting settings
#
# POST /v2/meetings/settings/searches.json
# Returns: table<active_meeting_url: record<created_at: string, updated_at: string, url: string>, allow_booking_on_behalf: bool, allow_booking_overtime: bool, allow_event_overlap: bool, availability_limit: int, availability_limit_enabled: bool, buffer_time_duration: int, calendar_type: string, created_at: string, default_meeting_length: int, description: string, email_address: string, enable_calendar_sync: bool, enable_dynamic_location: bool, id: int, location: string, primary_calendar_connection_failed: bool, primary_calendar_id: string, primary_calendar_name: string, schedule_buffer_enabled: bool, schedule_delay: int, share_event_detail: bool, time_zone: string, times_available: record, title: string, updated_at: string, user: record<_href: string, id: int>, user_details: record, user_slug: string>
export def "post-v2-meetings-settings-searches-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-guids: list<string> # Filters meeting settings by array of user_guids
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --calendar-type: string # Filters meeting settings by calendar type
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/v2/meetings/settings/searches.json"
    query: [{name: user_guids, var: user_guids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: calendar_type, var: calendar_type}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    user_guids: $user_guids, updated_at: $updated_at, calendar_type: $calendar_type, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a meeting setting
#
# PUT /v2/meetings/settings/{id}.json
# Returns: record<active_meeting_url: record<created_at: string, updated_at: string, url: string>, allow_booking_on_behalf: bool, allow_booking_overtime: bool, allow_event_overlap: bool, availability_limit: int, availability_limit_enabled: bool, buffer_time_duration: int, calendar_type: string, created_at: string, default_meeting_length: int, description: string, email_address: string, enable_calendar_sync: bool, enable_dynamic_location: bool, id: int, location: string, primary_calendar_connection_failed: bool, primary_calendar_id: string, primary_calendar_name: string, schedule_buffer_enabled: bool, schedule_delay: int, share_event_detail: bool, time_zone: string, times_available: record, title: string, updated_at: string, user: record<_href: string, id: int>, user_details: record, user_slug: string>
export def "put-v2-meetings-settings-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-booking-on-behalf: oneof<nothing, bool> # Allow other team members to schedule on you behalf.
  --allow-booking-overtime: oneof<nothing, bool> # Allow team members to insert available time outside your working hours.
  --allow-event-overlap: oneof<nothing, bool> # Allow team members to double book events on your calendar.
  --availability-limit: int # The number of days out the user allows a prospect to schedule a meeting
  --availability-limit-enabled: oneof<nothing, bool> # If Availability Limits have been turned on
  --buffer-time-duration: int # Default buffer duration in minutes set by a user
  --calendar-type: string # Calendar type
  --default-meeting-length: int # Default meeting length in minutes set by the user
  --description: string # Default description of the meeting
  --enable-calendar-sync: oneof<nothing, bool> # Determines if a user enabled Calendar Sync feature
  --enable-dynamic-location: oneof<nothing, bool> # Determines if location will be filled via third-party service (Zoom, GoToMeeting, etc.)
  --location: string # Default location of the meeting
  --primary-calendar-connection-failed: oneof<nothing, bool> # Determines if the user lost calendar connection
  --primary-calendar-id: string # ID of the primary calendar
  --primary-calendar-name: string # Display name of the primary calendar
  --schedule-buffer-enabled: oneof<nothing, bool> # Determines if meetings are scheduled with a 15 minute buffer between them
  --schedule-delay: int # The number of hours in advance a user requires someone to a book a meeting with them
  --share-event-detail: oneof<nothing, bool> # Allow team members to see the details of events on your calendar.
  --time-zone: string # Time zone for current calendar
  --times-available: record # Times available set by a user that can be used to book meetings
  --title: string # Default title of the meeting
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/meetings/settings/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: allow_booking_on_behalf, var: allow_booking_on_behalf}, {name: allow_booking_overtime, var: allow_booking_overtime}, {name: allow_event_overlap, var: allow_event_overlap}, {name: availability_limit, var: availability_limit}, {name: availability_limit_enabled, var: availability_limit_enabled}, {name: buffer_time_duration, var: buffer_time_duration}, {name: calendar_type, var: calendar_type}, {name: default_meeting_length, var: default_meeting_length}, {name: description, var: description}, {name: enable_calendar_sync, var: enable_calendar_sync}, {name: enable_dynamic_location, var: enable_dynamic_location}, {name: location, var: location}, {name: primary_calendar_connection_failed, var: primary_calendar_connection_failed}, {name: primary_calendar_id, var: primary_calendar_id}, {name: primary_calendar_name, var: primary_calendar_name}, {name: schedule_buffer_enabled, var: schedule_buffer_enabled}, {name: schedule_delay, var: schedule_delay}, {name: share_event_detail, var: share_event_detail}, {name: time_zone, var: time_zone}, {name: times_available, var: times_available}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, allow_booking_on_behalf: $allow_booking_on_behalf, allow_booking_overtime: $allow_booking_overtime, allow_event_overlap: $allow_event_overlap, availability_limit: $availability_limit, availability_limit_enabled: $availability_limit_enabled, buffer_time_duration: $buffer_time_duration, calendar_type: $calendar_type, default_meeting_length: $default_meeting_length, description: $description, enable_calendar_sync: $enable_calendar_sync, enable_dynamic_location: $enable_dynamic_location, location: $location, primary_calendar_connection_failed: $primary_calendar_connection_failed, primary_calendar_id: $primary_calendar_id, primary_calendar_name: $primary_calendar_name, schedule_buffer_enabled: $schedule_buffer_enabled, schedule_delay: $schedule_delay, share_event_detail: $share_event_detail, time_zone: $time_zone, times_available: $times_available, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a meeting
#
# PUT /v2/meetings/{id}.json
# Returns: record<account_id: string, all_day: bool, attendees: table<deleted_at: string, email: string, name: string, organizer: bool, status: string, status_changed: bool>, booked_by_meetings_settings: record<email_address: string>, booked_by_user: record<_href: string, id: int>, cadence: record<_href: string, id: int>, calendar_id: string, calendar_type: string, canceled_at: string, created_at: string, crm_custom_fields: record, crm_references: record, description: string, end_time: string, event_id: string, event_source: string, guests: list<string>, i_cal_uid: string, id: int, location: string, meeting_type: string, no_show: bool, owned_by_meetings_settings: record<email_address: string>, person: record<_href: string, id: int>, recipient_email: string, recipient_name: string, start_time: string, status: string, step: record<_href: string, id: int>, strict_attribution: bool, task_id: string, title: string, updated_at: string>
export def "put-v2-meetings-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-id: string # Meeting ID from the calendar provider
  --i-cal-uid: string # Meeting unique identifier (iCalUID)
  --no-show: oneof<nothing, bool> # Whether the meeting is a No Show meeting
  --status: string # Status of the meeting creation progress. Possible values are: pending, booked, failed, retry
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/meetings/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: event_id, var: event_id}, {name: i_cal_uid, var: i_cal_uid}, {name: no_show, var: no_show}, {name: status, var: status}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, event_id: $event_id, i_cal_uid: $i_cal_uid, no_show: $no_show, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the MIME content for email
#
# GET /v2/mime_email_payloads/{id}.json
# Returns: record<id: int, mailbox: string, message_id: string, raw: string>
export def "get-v2-mime-email-payloads-id-json" [
  id: string
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
    path: "/v2/mime_email_payloads/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List notes
#
# GET /v2/notes.json
# Returns: table<associated_type: string, associated_with: record<_href: string, id: int>, call: record<_href: string, id: int>, content: string, created_at: string, id: int, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-notes-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associated-with-type: string # Case insensitive type of item with which the note is associated. Value must be one of: person, account
  --associated-with-id: int # ID of the item with which the note is associated. The associated_with_type must also be present if this parameter is used
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --ids: list<int> # IDs of notes to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/notes.json"
    query: [{name: associated_with_type, var: associated_with_type}, {name: associated_with_id, var: associated_with_id}, {name: updated_at, var: updated_at, style: csv}, {name: ids, var: ids, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    associated_with_type: $associated_with_type, associated_with_id: $associated_with_id, updated_at: $updated_at, ids: $ids, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a note
#
# POST /v2/notes.json
# Returns: record<associated_type: string, associated_with: record<_href: string, id: int>, call: record<_href: string, id: int>, content: string, created_at: string, id: int, updated_at: string, user: record<_href: string, id: int>>
export def "post-v2-notes-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  associated_with_id: int # ID of the item with which the note is associated
  associated_with_type: string # Case insensitive type of item with which the note is associated. Value must be one of: person, account
  --call-id: int # ID of the call with which the note is associated. The call cannot already have a note
  content: string # The content of the note
  --skip-crm-sync: oneof<nothing, bool> # Boolean indicating if the CRM sync should be skipped. No syncing will occur if true
  --subject: string # The subject of the note's crm activity, defaults to 'Note'
  --user-guid: string # The user to create the note for. Only team admins may create notes on behalf of other users. Defaults to the requesting user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/notes.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: associated_with_id, var: associated_with_id}, {name: associated_with_type, var: associated_with_type}, {name: call_id, var: call_id}, {name: content, var: content}, {name: skip_crm_sync, var: skip_crm_sync}, {name: subject, var: subject}, {name: user_guid, var: user_guid}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    associated_with_id: $associated_with_id, associated_with_type: $associated_with_type, call_id: $call_id, content: $content, skip_crm_sync: $skip_crm_sync, subject: $subject, user_guid: $user_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a note
#
# DELETE /v2/notes/{id}.json
export def "delete-v2-notes-id-json" [
  id: string
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
    path: "/v2/notes/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a note
#
# GET /v2/notes/{id}.json
# Returns: record<associated_type: string, associated_with: record<_href: string, id: int>, call: record<_href: string, id: int>, content: string, created_at: string, id: int, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-notes-id-json" [
  id: string
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
    path: "/v2/notes/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a note
#
# PUT /v2/notes/{id}.json
# Returns: record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>
export def "put-v2-notes-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-id: int # ID of the call with which the note is associated. The call cannot already have a note. If the note is associated to a call already, it will become associated to the requested call
  content: string # The content of the note
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/notes/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: call_id, var: call_id}, {name: content, var: content}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, call_id: $call_id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an ongoing action
#
# POST /v2/ongoing_actions.json
# Returns: record<action_details: record<_href: string, id: int>, cadence: record<_href: string, id: int>, created_at: string, due: bool, due_on: string, id: int, multitouch_group_id: int, person: record<_href: string, id: int>, status: string, step: record<_href: string, id: int>, type: string, updated_at: string, user: record<_href: string, id: int>>
export def "post-v2-ongoing-actions-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-id: int # Action that is being marked ongoing. This will validate that the action is still valid before modifying it. Ongoing actions can not be marked ongoing.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/ongoing_actions.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: action_id, var: action_id}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a list of emails ready to be sent by an external email service. Only emails sent with an External Email Client will appear here.
#
# GET /v2/pending_emails.json
# Returns: table<id: int, mailbox: string, mime_email_payload: record<_href: string, id: int>>
export def "get-v2-pending-emails-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/pending_emails.json"
    query: [{name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of an email sent by an External Email Client
#
# PUT /v2/pending_emails/{id}.json
# Returns: record<id: int, mailbox: string, mime_email_payload: record<_href: string, id: int>>
export def "put-v2-pending-emails-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --error-message: string # The error message indicating why the email failed to send
  message_id: string # The message id of the email that was sent
  --sent-at: string # The time that the email was actually sent in iso8601 format
  status: string # Delivery status of the email. Valid statuses are 'sent' and 'failed'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/pending_emails/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: error_message, var: error_message}, {name: message_id, var: message_id}, {name: sent_at, var: sent_at}, {name: status, var: status}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, error_message: $error_message, message_id: $message_id, sent_at: $sent_at, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List people
#
# GET /v2/people.json
# Returns: table<account: record<_href: string, id: int>, bouncing: bool, cadences: list<record>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>
export def "get-v2-people-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of people to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --email-addresses: list<string> # Filters people by email address. Multiple emails can be applied. An additional value of "_is_null" can be passed to filter people that do not have an email address.
  --owned-by-guid: list<string> # Filters people by the owner's guid. Multiple owner guids can be applied
  --person-stage-id: list<int> # Includes people that have a given person_stage. Multiple person stage ids can be applied. An additional value of "_is_null" can be passed to filter people that do not have a stage set.
  --crm-id: list<string> # Filters people by crm_id. Multiple crm ids can be applied
  --owner-crm-id: list<string> # Filters people by owner_crm_id. Multiple owner_crm_ids can be applied. An additional value of "_is_null" can be passed to filter people that are unowned. A "_not_in" modifier can be used to exclude specific owner_crm_ids. Example: v2/people?owner_crm_id[_not_in]=id
  --do-not-contact: oneof<nothing, bool> # Includes people that have a given do_not_contact property
  --can-email: oneof<nothing, bool> # Includes people that can be emailed given do_not_contact and contact_restrictions property
  --can-call: oneof<nothing, bool> # Includes people that can be called given do_not_contact and contact_restrictions property
  --can-text: oneof<nothing, bool> # Includes people that can be sent a text message given do_not_contact and contact_restrictions property
  --account-id: list<int> # Filters people by the account they are linked to. Multiple account ids can be applied
  --custom-fields: record # Filters by people matching all given custom fields. The custom field names are case-sensitive, but the provided values are case-insensitive. Example: v2/people?custom_fields[custom_field_name]=custom_field_value
  --import-id: list<int> # Filters people that were imported by the given import ids. Multiple import ids can be applied. An additional value of "_is_null" can be passed to filter people that were not imported.
  --job-seniority: list<string> # Filters people by job seniorty. Multiple job seniorities can be applied. An additional value of "_is_null" can be passed to filter people do not have a job_seniority.
  --tag-id: list<int> # Filters people by the tag ids applied to the person. Multiple tag ids can be applied.
  --owner-is-active: oneof<nothing, bool> # Filters people by whether the owner is active or not.
  --cadence-id: list<int> # Filters people by the cadence that they are currently on. Multiple cadence_ids can be applied. An additional value of "_is_null" can be passed to filter people that are not on a cadence.
  --starred-by-guid: list<string> # Filters people who have been starred by the user guids given.
  --replied: oneof<nothing, bool> # Filters people by whether or not they have replied to an email or not.
  --bounced: oneof<nothing, bool> # Filters people by whether an email that was sent to them bounced or not.
  --success: oneof<nothing, bool> # Filters people by whether or not they have been marked as a success or not.
  --eu-resident: oneof<nothing, bool> # Filters people by whether or not they are marked as an European Union Resident or not.
  --title: list<string> # Filters people by their title by exact match. Supports partial matching
  --country: list<string> # Filters people by their country by exact match. Supports partial matching
  --state: list<string> # Filters people by their state by exact match. Supports partial matching
  --city: list<string> # Filters people by their city by exact match. Supports partial matching
  --last-contacted: record # Equality filters that are applied to the last_contacted field. A single filter can be used by itself or combined with other filters to create a range. Additional values of "_is_null" or "_is_not_null" can be passed to filter records that either have no timestamp value or any timestamp value. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --created-at: record # Equality filters that are applied to the last_contacted field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --new: oneof<nothing, bool> # Filters people by whether or not that person is on a cadence or if they have been contacted in any way.
  --phone-number: oneof<nothing, bool> # Filter people by whether or not they have a phone number or not
  --locales: list<string> # Filters people by locales. Multiple locales can be applied. An additional value of "Null" can be passed to filter people that do not have a locale.
  --owner-id: list<int> # Filters people by owner_id. Multiple owner_ids can be applied.
  --query: string # For internal use only. This field does not comply with our backwards compatibility policies. This filter is for authenticated users of Salesloft only and will not work for OAuth Applications. Filters people by the string provided. Can search and filter by name, title, industry, email_address and linked account name.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_contacted_at, name, title, job_seniority, call_count, sent_emails, clicked_emails, replied_emails, viewed_emails, account, cadence_stage_name. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/people.json"
    query: [{name: ids, var: ids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: email_addresses, var: email_addresses, style: csv}, {name: owned_by_guid, var: owned_by_guid, style: csv}, {name: person_stage_id, var: person_stage_id, style: csv}, {name: crm_id, var: crm_id, style: csv}, {name: owner_crm_id, var: owner_crm_id, style: csv}, {name: do_not_contact, var: do_not_contact}, {name: can_email, var: can_email}, {name: can_call, var: can_call}, {name: can_text, var: can_text}, {name: account_id, var: account_id, style: csv}, {name: custom_fields, var: custom_fields, style: multi}, {name: import_id, var: import_id, style: csv}, {name: job_seniority, var: job_seniority, style: csv}, {name: tag_id, var: tag_id, style: csv}, {name: owner_is_active, var: owner_is_active}, {name: cadence_id, var: cadence_id, style: csv}, {name: starred_by_guid, var: starred_by_guid, style: csv}, {name: replied, var: replied}, {name: bounced, var: bounced}, {name: success, var: success}, {name: eu_resident, var: eu_resident}, {name: title, var: title, style: csv}, {name: country, var: country, style: csv}, {name: state, var: state, style: csv}, {name: city, var: city, style: csv}, {name: last_contacted, var: last_contacted, style: multi}, {name: created_at, var: created_at, style: multi}, {name: new, var: new}, {name: phone_number, var: phone_number}, {name: locales, var: locales, style: csv}, {name: owner_id, var: owner_id, style: csv}, {name: _query, var: query}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, updated_at: $updated_at, email_addresses: $email_addresses, owned_by_guid: $owned_by_guid, person_stage_id: $person_stage_id, crm_id: $crm_id, owner_crm_id: $owner_crm_id, do_not_contact: $do_not_contact, can_email: $can_email, can_call: $can_call, can_text: $can_text, account_id: $account_id, custom_fields: $custom_fields, import_id: $import_id, job_seniority: $job_seniority, tag_id: $tag_id, owner_is_active: $owner_is_active, cadence_id: $cadence_id, starred_by_guid: $starred_by_guid, replied: $replied, bounced: $bounced, success: $success, eu_resident: $eu_resident, title: $title, country: $country, state: $state, city: $city, last_contacted: $last_contacted, created_at: $created_at, new: $new, phone_number: $phone_number, locales: $locales, owner_id: $owner_id, query: $query, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a person
#
# POST /v2/people.json
# Returns: record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>
export def "post-v2-people-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # ID of the Account to link this person to
  --autotag-date: oneof<nothing, bool> # Whether the date should be added to this person as a tag. Default is false. The tag will be Y-m-d format.
  --city: string # City
  --contact-restrictions: list<string> # Specific methods of communication to prevent for this person. This will prevent individual execution of these communication types as well as automatically skip cadence steps of this communication type for this person in SalesLoft. Values currently accepted: call, email, message
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either a Lead (00Q) or Contact (003) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "person:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: record # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --do-not-contact: oneof<nothing, bool> # Whether or not this person has opted out of all communication. Setting this value to true prevents this person from being called, emailed, or added to a cadence in SalesLoft. If this person is currently in a cadence, they will be removed.
  --email-address: string # Email address
  --first-name: string # First name
  --home-phone: string # Home phone without formatting
  --import-id: int # ID of the Import this person is a part of. A person can be part of multiple imports, but this ID will always be the most recent Import
  --job-seniority: string # The Job Seniority of a Person, must be one of director, executive, individual_contributor, manager, vice_president, unknown
  --last-name: string # Last name
  --linkedin-url: string # Linkedin URL
  --locale: string # Time locale of the person
  --mobile-phone: string # Mobile phone without formatting
  --owner-id: int # ID of the User that owns this person
  --person-company-industry: string # Company industry. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-name: string # Company name. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-website: string # Company website. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-stage-id: int # ID of the PersonStage of this person
  --personal-email-address: string # Personal email address
  --personal-website: string # The website of this person
  --phone: string # Phone without formatting
  --phone-extension: string # Phone extension without formatting
  --secondary-email-address: string # Alternate email address
  --state: string # State
  --tags: list<string> # All tags applied to this person
  --title: string # Job title
  --twitter-handle: string # The twitter handle of this person
  --work-city: string # Work location - city
  --work-country: string # Work location - country
  --work-state: string # Work location - state
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/people.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: account_id, var: account_id}, {name: autotag_date, var: autotag_date}, {name: city, var: city}, {name: contact_restrictions, var: contact_restrictions}, {name: country, var: country}, {name: crm_id, var: crm_id}, {name: crm_id_type, var: crm_id_type}, {name: custom_fields, var: custom_fields}, {name: do_not_contact, var: do_not_contact}, {name: email_address, var: email_address}, {name: first_name, var: first_name}, {name: home_phone, var: home_phone}, {name: import_id, var: import_id}, {name: job_seniority, var: job_seniority}, {name: last_name, var: last_name}, {name: linkedin_url, var: linkedin_url}, {name: locale, var: locale}, {name: mobile_phone, var: mobile_phone}, {name: owner_id, var: owner_id}, {name: person_company_industry, var: person_company_industry}, {name: person_company_name, var: person_company_name}, {name: person_company_website, var: person_company_website}, {name: person_stage_id, var: person_stage_id}, {name: personal_email_address, var: personal_email_address}, {name: personal_website, var: personal_website}, {name: phone, var: phone}, {name: phone_extension, var: phone_extension}, {name: secondary_email_address, var: secondary_email_address}, {name: state, var: state}, {name: tags, var: tags}, {name: title, var: title}, {name: twitter_handle, var: twitter_handle}, {name: work_city, var: work_city}, {name: work_country, var: work_country}, {name: work_state, var: work_state}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, autotag_date: $autotag_date, city: $city, contact_restrictions: $contact_restrictions, country: $country, crm_id: $crm_id, crm_id_type: $crm_id_type, custom_fields: $custom_fields, do_not_contact: $do_not_contact, email_address: $email_address, first_name: $first_name, home_phone: $home_phone, import_id: $import_id, job_seniority: $job_seniority, last_name: $last_name, linkedin_url: $linkedin_url, locale: $locale, mobile_phone: $mobile_phone, owner_id: $owner_id, person_company_industry: $person_company_industry, person_company_name: $person_company_name, person_company_website: $person_company_website, person_stage_id: $person_stage_id, personal_email_address: $personal_email_address, personal_website: $personal_website, phone: $phone, phone_extension: $phone_extension, secondary_email_address: $secondary_email_address, state: $state, tags: $tags, title: $title, twitter_handle: $twitter_handle, work_city: $work_city, work_country: $work_country, work_state: $work_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a person
#
# DELETE /v2/people/{id}.json
export def "delete-v2-people-id-json" [
  id: string
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
    path: "/v2/people/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a person
#
# GET /v2/people/{id}.json
# Returns: record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>
export def "get-v2-people-id-json" [
  id: string
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
    path: "/v2/people/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a person
#
# PUT /v2/people/{id}.json
# Returns: record<account: record<_href: string, id: int>, bouncing: bool, cadences: table<_href: string, id: int>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>
export def "put-v2-people-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # ID of the Account to link this person to
  --city: string # City
  --contact-restrictions: list<string> # Specific methods of communication to prevent for this person. This will prevent individual execution of these communication types as well as automatically skip cadence steps of this communication type for this person in SalesLoft. Values currently accepted: call, email, message
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either a Lead (00Q) or Contact (003) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "person:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: record # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --do-not-contact: oneof<nothing, bool> # Whether or not this person has opted out of all communication. Setting this value to true prevents this person from being called, emailed, or added to a cadence in SalesLoft. If this person is currently in a cadence, they will be removed.
  --email-address: string # Email address
  --first-name: string # First name
  --home-phone: string # Home phone without formatting
  --import-id: int # ID of the Import this person is a part of. A person can be part of multiple imports, but this ID will always be the most recent Import
  --job-seniority: string # The Job Seniority of a Person, must be one of director, executive, individual_contributor, manager, vice_president, unknown
  --last-name: string # Last name
  --linkedin-url: string # Linkedin URL
  --locale: string # Time locale of the person
  --mobile-phone: string # Mobile phone without formatting
  --owner-id: int # ID of the User that owns this person
  --person-company-industry: string # Company industry. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-name: string # Company name. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-website: string # Company website. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-stage-id: int # ID of the PersonStage of this person
  --personal-email-address: string # Personal email address
  --personal-website: string # The website of this person
  --phone: string # Phone without formatting
  --phone-extension: string # Phone extension without formatting
  --secondary-email-address: string # Alternate email address
  --state: string # State
  --tags: list<string> # All tags applied to this person
  --title: string # Job title
  --twitter-handle: string # The twitter handle of this person
  --work-city: string # Work location - city
  --work-country: string # Work location - country
  --work-state: string # Work location - state
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/people/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: account_id, var: account_id}, {name: city, var: city}, {name: contact_restrictions, var: contact_restrictions}, {name: country, var: country}, {name: crm_id, var: crm_id}, {name: crm_id_type, var: crm_id_type}, {name: custom_fields, var: custom_fields}, {name: do_not_contact, var: do_not_contact}, {name: email_address, var: email_address}, {name: first_name, var: first_name}, {name: home_phone, var: home_phone}, {name: import_id, var: import_id}, {name: job_seniority, var: job_seniority}, {name: last_name, var: last_name}, {name: linkedin_url, var: linkedin_url}, {name: locale, var: locale}, {name: mobile_phone, var: mobile_phone}, {name: owner_id, var: owner_id}, {name: person_company_industry, var: person_company_industry}, {name: person_company_name, var: person_company_name}, {name: person_company_website, var: person_company_website}, {name: person_stage_id, var: person_stage_id}, {name: personal_email_address, var: personal_email_address}, {name: personal_website, var: personal_website}, {name: phone, var: phone}, {name: phone_extension, var: phone_extension}, {name: secondary_email_address, var: secondary_email_address}, {name: state, var: state}, {name: tags, var: tags}, {name: title, var: title}, {name: twitter_handle, var: twitter_handle}, {name: work_city, var: work_city}, {name: work_country, var: work_country}, {name: work_state, var: work_state}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, account_id: $account_id, city: $city, contact_restrictions: $contact_restrictions, country: $country, crm_id: $crm_id, crm_id_type: $crm_id_type, custom_fields: $custom_fields, do_not_contact: $do_not_contact, email_address: $email_address, first_name: $first_name, home_phone: $home_phone, import_id: $import_id, job_seniority: $job_seniority, last_name: $last_name, linkedin_url: $linkedin_url, locale: $locale, mobile_phone: $mobile_phone, owner_id: $owner_id, person_company_industry: $person_company_industry, person_company_name: $person_company_name, person_company_website: $person_company_website, person_stage_id: $person_stage_id, personal_email_address: $personal_email_address, personal_website: $personal_website, phone: $phone, phone_extension: $phone_extension, secondary_email_address: $secondary_email_address, state: $state, tags: $tags, title: $title, twitter_handle: $twitter_handle, work_city: $work_city, work_country: $work_country, work_state: $work_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List person stages
#
# GET /v2/person_stages.json
# Returns: table<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "get-v2-person-stages-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of person stages to fetch.
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/person_stages.json"
    query: [{name: ids, var: ids, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a person stage
#
# POST /v2/person_stages.json
# Returns: record<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "post-v2-person-stages-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new stage
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/person_stages.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an person stage
#
# DELETE /v2/person_stages/{id}.json
export def "delete-v2-person-stages-id-json" [
  id: string
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
    path: "/v2/person_stages/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a person stage
#
# GET /v2/person_stages/{id}.json
# Returns: record<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "get-v2-person-stages-id-json" [
  id: string
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
    path: "/v2/person_stages/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a person stage
#
# PUT /v2/person_stages/{id}.json
# Returns: record<created_at: string, id: int, name: string, order: int, updated_at: string>
export def "put-v2-person-stages-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the stage.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/person_stages/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert a person
#
# POST /v2/person_upserts.json
# Returns: record<person: record<account: record<_href: string, id: int>, bouncing: bool, cadences: list<record>, city: string, contact_restrictions: list<string>, country: string, counts: record<calls: int, emails_bounced: int, emails_clicked: int, emails_replied_to: int, emails_sent: int, emails_viewed: int>, created_at: string, crm_id: string, crm_object_type: string, crm_url: string, custom_fields: record, display_name: string, do_not_contact: bool, email_address: string, eu_resident: bool, first_name: string, full_email_address: string, home_phone: string, id: int, import: record<_href: string, id: int>, job_seniority: string, last_completed_step: record<_href: string, id: int>, last_completed_step_cadence: record<_href: string, id: int>, last_contacted_at: string, last_contacted_by: record<_href: string, id: int>, last_contacted_type: string, last_name: string, last_replied_at: string, linkedin_url: string, locale: string, locale_utc_offset: int, mobile_phone: string, most_recent_cadence: record<_href: string, id: int>, owner: record<_href: string, id: int>, owner_crm_id: string, person_company_industry: string, person_company_name: string, person_company_website: string, person_stage: record<_href: string, id: int>, personal_email_address: string, personal_website: string, phone: string, phone_extension: string, secondary_email_address: string, starred: bool, state: string, success_count: int, tags: list<string>, title: string, twitter_handle: string, untouched: bool, updated_at: string, work_city: string, work_country: string, work_state: string>, upsert_type: string>
export def "post-v2-person-upserts-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # ID of the Account to link this person to
  --city: string # City
  --contact-restrictions: list<string> # Specific methods of communication to prevent for this person. This will prevent individual execution of these communication types as well as automatically skip cadence steps of this communication type for this person in SalesLoft. Values currently accepted: call, email, message
  --country: string # Country
  --crm-id: string # Requires Salesforce. ID of the person in your external CRM. You must provide a crm_id_type if this is included. Validations will be applied to the crm_id depending on the crm_id_type. A "salesforce" ID must be exactly 18 characters. A "salesforce" ID must be either a Lead (00Q) or Contact (003) object. The type will be validated using the 18 character ID. This field can only be used if your application or API key has the "person:set_crm_id" scope.
  --crm-id-type: string # The CRM that the provided crm_id is for. Must be one of: salesforce
  --custom-fields: record # Custom fields are defined by the user's team. Only fields with values are presented in the API.
  --do-not-contact: oneof<nothing, bool> # Whether or not this person has opted out of all communication. Setting this value to true prevents this person from being called, emailed, or added to a cadence in SalesLoft. If this person is currently in a cadence, they will be removed.
  --email-address: string # Email address
  --first-name: string # First name
  --home-phone: string # Home phone without formatting
  --id: int # ID of the person to update. Used if the upsert_key=id. When id and another upsert_key are provided, the request will fail if the upsert record id and id parameter don't match.
  --import-id: int # ID of the Import this person is a part of. A person can be part of multiple imports, but this ID will always be the most recent Import
  --job-seniority: string # The Job Seniority of a Person, must be one of director, executive, individual_contributor, manager, vice_president, unknown
  --last-name: string # Last name
  --linkedin-url: string # Linkedin URL
  --locale: string # Time locale of the person
  --mobile-phone: string # Mobile phone without formatting
  --owner-id: int # ID of the User that owns this person
  --person-company-industry: string # Company industry. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-name: string # Company name. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-company-website: string # Company website. This property is specific to this person, unrelated to the company object. Updating the company object associated with this person is recommended
  --person-stage-id: int # ID of the PersonStage of this person
  --personal-email-address: string # Personal email address
  --personal-website: string # The website of this person
  --phone: string # Phone without formatting
  --phone-extension: string # Phone extension without formatting
  --secondary-email-address: string # Alternate email address
  --state: string # State
  --tags: list<string> # All tags applied to this person
  --title: string # Job title
  --twitter-handle: string # The twitter handle of this person
  --upsert-key: string # Name of the parameter to upsert on. The field must be provided in the input parameters, or the request will fail. The request will also fail if there are multiple records matched by the upsert field. This can occur if intentional duplicates by email address is enabled. If upsert_key is not provided, this endpoint will not update an existing record. Valid options are: id, crm_id, email_address. If crm_id is provided, then a valid crm_id_type must be provided, as documented for the person create and update endpoints.
  --work-city: string # Work location - city
  --work-country: string # Work location - country
  --work-state: string # Work location - state
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/person_upserts.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: account_id, var: account_id}, {name: city, var: city}, {name: contact_restrictions, var: contact_restrictions}, {name: country, var: country}, {name: crm_id, var: crm_id}, {name: crm_id_type, var: crm_id_type}, {name: custom_fields, var: custom_fields}, {name: do_not_contact, var: do_not_contact}, {name: email_address, var: email_address}, {name: first_name, var: first_name}, {name: home_phone, var: home_phone}, {name: id, var: id}, {name: import_id, var: import_id}, {name: job_seniority, var: job_seniority}, {name: last_name, var: last_name}, {name: linkedin_url, var: linkedin_url}, {name: locale, var: locale}, {name: mobile_phone, var: mobile_phone}, {name: owner_id, var: owner_id}, {name: person_company_industry, var: person_company_industry}, {name: person_company_name, var: person_company_name}, {name: person_company_website, var: person_company_website}, {name: person_stage_id, var: person_stage_id}, {name: personal_email_address, var: personal_email_address}, {name: personal_website, var: personal_website}, {name: phone, var: phone}, {name: phone_extension, var: phone_extension}, {name: secondary_email_address, var: secondary_email_address}, {name: state, var: state}, {name: tags, var: tags}, {name: title, var: title}, {name: twitter_handle, var: twitter_handle}, {name: upsert_key, var: upsert_key}, {name: work_city, var: work_city}, {name: work_country, var: work_country}, {name: work_state, var: work_state}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, city: $city, contact_restrictions: $contact_restrictions, country: $country, crm_id: $crm_id, crm_id_type: $crm_id_type, custom_fields: $custom_fields, do_not_contact: $do_not_contact, email_address: $email_address, first_name: $first_name, home_phone: $home_phone, id: $id, import_id: $import_id, job_seniority: $job_seniority, last_name: $last_name, linkedin_url: $linkedin_url, locale: $locale, mobile_phone: $mobile_phone, owner_id: $owner_id, person_company_industry: $person_company_industry, person_company_name: $person_company_name, person_company_website: $person_company_website, person_stage_id: $person_stage_id, personal_email_address: $personal_email_address, personal_website: $personal_website, phone: $phone, phone_extension: $phone_extension, secondary_email_address: $secondary_email_address, state: $state, tags: $tags, title: $title, twitter_handle: $twitter_handle, upsert_key: $upsert_key, work_city: $work_city, work_country: $work_country, work_state: $work_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List phone number assignments
#
# GET /v2/phone_number_assignments.json
# Returns: table<id: int, number: string, user: record<_href: string, id: int>>
export def "get-v2-phone-number-assignments-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of phone number assignments to fetch
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/phone_number_assignments.json"
    query: [{name: ids, var: ids, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a phone number assignment
#
# GET /v2/phone_number_assignments/{id}.json
# Returns: record<id: int, number: string, user: record<_href: string, id: int>>
export def "get-v2-phone-number-assignments-id-json" [
  id: string
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
    path: "/v2/phone_number_assignments/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List caller ids
#
# GET /v2/phone_numbers/caller_ids.json
# Returns: table<account_name: string, display_name: string, person: record<_href: string, id: int>, title: string>
export def "get-v2-phone-numbers-caller-ids-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-number: string # E.164 Phone Number (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/phone_numbers/caller_ids.json"
    query: [{name: phone_number, var: phone_number, required: true}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch recording setting
#
# GET /v2/phone_numbers/recording_settings/{id}.json
# Returns: record<recording_default: bool>
export def "get-v2-phone-numbers-recording-settings-id-json" [
  id: string
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
    path: "/v2/phone_numbers/recording_settings/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List saved list views
#
# GET /v2/saved_list_views.json
# Returns: table<id: int, is_default: bool, name: string, view: string, view_params: record>
export def "get-v2-saved-list-views-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of saved list views to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --view: string # Type of saved list views to fetch.
  --sort-by: string # Key to sort on, must be one of: name. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/saved_list_views.json"
    query: [{name: ids, var: ids, style: csv}, {name: view, var: view}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, view: $view, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a saved list view
#
# POST /v2/saved_list_views.json
# Returns: record<id: int, is_default: bool, name: string, view: string, view_params: record>
export def "post-v2-saved-list-views-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-default: oneof<nothing, bool> # Whether the saved list view is the default
  name: string # The name of the saved list view
  view: string # The type of objects in the saved list view. Value must be one of: people, companies, or recordings
  --view-params: string # JSON object of list view parameters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/saved_list_views.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: is_default, var: is_default}, {name: name, var: name}, {name: view, var: view}, {name: view_params, var: view_params}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    is_default: $is_default, name: $name, view: $view, view_params: $view_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a saved list view
#
# DELETE /v2/saved_list_views/{id}.json
export def "delete-v2-saved-list-views-id-json" [
  id: string
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
    path: "/v2/saved_list_views/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a saved list view
#
# GET /v2/saved_list_views/{id}.json
# Returns: record<id: int, is_default: bool, name: string, view: string, view_params: record>
export def "get-v2-saved-list-views-id-json" [
  id: string
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
    path: "/v2/saved_list_views/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a saved list view
#
# PUT /v2/saved_list_views/{id}.json
# Returns: record<id: int, is_default: bool, name: string, view: string, view_params: record>
export def "put-v2-saved-list-views-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-default: oneof<nothing, bool> # Whether the saved list view is the default
  --name: string # The name of the saved list view
  --view-params: string # JSON object of list view parameters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/saved_list_views/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: is_default, var: is_default}, {name: name, var: name}, {name: view_params, var: view_params}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, is_default: $is_default, name: $name, view_params: $view_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List steps
#
# GET /v2/steps.json
# Returns: table<cadence: record<_href: string, id: int>, created_at: string, day: int, details: record<_href: string, id: int>, disabled: bool, display_name: string, id: int, multitouch_enabled: bool, name: string, step_number: int, type: string, updated_at: string>
export def "get-v2-steps-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of steps to fetch.
  --cadence-id: int # Filter by cadence ID
  --type: string # Filter by step type
  --has-due-actions: oneof<nothing, bool> # Filter by whether a step has due actions
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/steps.json"
    query: [{name: ids, var: ids, style: csv}, {name: cadence_id, var: cadence_id}, {name: type, var: type}, {name: has_due_actions, var: has_due_actions}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, cadence_id: $cadence_id, type: $type, has_due_actions: $has_due_actions, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a step
#
# GET /v2/steps/{id}.json
# Returns: record<cadence: record<_href: string, id: int>, created_at: string, day: int, details: record<_href: string, id: int>, disabled: bool, display_name: string, id: int, multitouch_enabled: bool, name: string, step_number: int, type: string, updated_at: string>
export def "get-v2-steps-id-json" [
  id: string
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
    path: "/v2/steps/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List successes
#
# GET /v2/successes.json
# Returns: table<counts: record<total_calls: int, total_emails: int, total_other_touches: int>, created_at: string, id: int, latest_action: record<_href: string, id: int>, latest_cadence: record<_href: string, id: int>, latest_call: record<_href: string, id: int>, latest_email: record<_href: string, id: int>, latest_step: record<_href: string, id: int>, person: record<_href: string, id: int>, succeeded_at: string, success_window_started_at: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-successes-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of successes to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --person-id: list<int> # Filters successes by person_id. Multiple person ids can be applied
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, succeeded_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/successes.json"
    query: [{name: ids, var: ids, style: csv}, {name: person_id, var: person_id, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, person_id: $person_id, updated_at: $updated_at, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List team tags
#
# GET /v2/tags.json
# Returns: table<id: int, name: string>
export def "get-v2-tags-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filters tags by name
  --ids: list<int> # Filters tags by their IDs
  --sort-by: string # Key to sort on, must be one of: name. Defaults to name
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tags.json"
    query: [{name: search, var: search}, {name: ids, var: ids, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    search: $search, ids: $ids, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tasks
#
# GET /v2/tasks.json
# Returns: table<completed_at: string, completed_by: record<_href: string, id: int>, created_at: string, created_by_user: record<_href: string, id: int>, current_state: string, description: string, due_at: string, due_date: string, id: int, person: record<_href: string, id: int>, remind_at: string, subject: string, task_type: string, updated_at: string, user: record<_href: string, id: int>>
export def "get-v2-tasks-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of tasks to fetch.
  --user-id: list<int> # Filters tasks by the user to which they are assigned.
  --person-id: list<int> # Filters tasks by the person to which they are associated.
  --account-id: list<int> # Filters tasks by the account to which they are associated.
  --current-state: list<string> # Filters tasks by their current state. Valid current_states include: ['scheduled', 'completed'].
  --task-type: list<string> # Filters tasks by their task type. Valid task_types include: ['call', 'email', 'general'].
  --time-interval-filter: string # Filters tasks by time interval. Valid time_intervals include: ['overdue', 'today', 'tomorrow', 'this_week', 'next_week'].
  --idempotency-key: string # Filters tasks by idempotency key.
  --locale: list<string> # Filters tasks by locale of the person to which they are associated.
  --sort-by: string # Key to sort on, must be one of: due_date, due_at. Defaults to due_date
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to ASC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/tasks.json"
    query: [{name: ids, var: ids, style: csv}, {name: user_id, var: user_id, style: csv}, {name: person_id, var: person_id, style: csv}, {name: account_id, var: account_id, style: csv}, {name: current_state, var: current_state, style: csv}, {name: task_type, var: task_type, style: csv}, {name: time_interval_filter, var: time_interval_filter}, {name: idempotency_key, var: idempotency_key}, {name: locale, var: locale, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, user_id: $user_id, person_id: $person_id, account_id: $account_id, current_state: $current_state, task_type: $task_type, time_interval_filter: $time_interval_filter, idempotency_key: $idempotency_key, locale: $locale, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Task
#
# POST /v2/tasks.json
# Returns: record<completed_at: string, completed_by: record<_href: string, id: int>, created_at: string, created_by_user: record<_href: string, id: int>, current_state: string, description: string, due_at: string, due_date: string, id: int, person: record<_href: string, id: int>, remind_at: string, subject: string, task_type: string, updated_at: string, user: record<_href: string, id: int>>
export def "post-v2-tasks-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  current_state: string # Current state of the task, valid options are: scheduled
  --description: string # A description of the task recorded for person at completion time
  due_date: string # Date of when the Task is due, ISO-8601 date format required
  --idempotency-key: string # Establishes a unique identifier to prevent duplicates from being created
  person_id: string # ID of the person to be contacted
  --remind-at: string # Datetime of when the user will be reminded of the task, ISO-8601 datetime format required
  subject: string # Subject line of the task.
  task_type: string # Task type, valid options are: call, email, general
  user_id: int # ID of the user linked to the task
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/tasks.json"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: current_state, var: current_state}, {name: description, var: description}, {name: due_date, var: due_date}, {name: idempotency_key, var: idempotency_key}, {name: person_id, var: person_id}, {name: remind_at, var: remind_at}, {name: subject, var: subject}, {name: task_type, var: task_type}, {name: user_id, var: user_id}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    current_state: $current_state, description: $description, due_date: $due_date, idempotency_key: $idempotency_key, person_id: $person_id, remind_at: $remind_at, subject: $subject, task_type: $task_type, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a task
#
# GET /v2/tasks/{id}.json
# Returns: record<cadence: record<_href: string, id: int>, created_at: string, day: int, details: record<_href: string, id: int>, disabled: bool, display_name: string, id: int, multitouch_enabled: bool, name: string, step_number: int, type: string, updated_at: string>
export def "get-v2-tasks-id-json" [
  id: string
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
    path: "/v2/tasks/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Task
#
# PUT /v2/tasks/{id}.json
# Returns: record<completed_at: string, completed_by: record<_href: string, id: int>, created_at: string, created_by_user: record<_href: string, id: int>, current_state: string, description: string, due_at: string, due_date: string, id: int, person: record<_href: string, id: int>, remind_at: string, subject: string, task_type: string, updated_at: string, user: record<_href: string, id: int>>
export def "put-v2-tasks-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-state: string # Current state of the task, valid options are: completed
  --description: string # A description of the task recorded for person at completion time
  --due-date: string # Date of when the Task is due, ISO-8601 date format required
  --is-logged: oneof<nothing, bool> # A flag to indicate that the task should only be logged
  --remind-at: string # Datetime of when the user will be reminded of the task, ISO-8601 datetime format required
  --subject: string # Subject line of the task
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/tasks/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: current_state, var: current_state}, {name: description, var: description}, {name: due_date, var: due_date}, {name: is_logged, var: is_logged}, {name: remind_at, var: remind_at}, {name: subject, var: subject}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, current_state: $current_state, description: $description, due_date: $due_date, is_logged: $is_logged, remind_at: $remind_at, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch current team
#
# GET /v2/team.json
# Returns: record<_private_fields: record, allow_automated_email_steps: bool, call_recording_disabled: bool, click_tracking_default: bool, created_at: string, custom_tracking_domain: string, deactivated: bool, dispositions_required: bool, email_daily_limit: int, group_privacy_setting: string, id: int, license_limit: int, local_dial_enabled: bool, name: string, plan: string, plan_features: record, record_by_default: bool, sentiments_required: bool, team_visibility_default: string, updated_at: string>
export def "get-v2-team-json" [
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
    path: "/v2/team.json"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List team template attachments
#
# GET /v2/team_template_attachments.json
# Returns: table<attachment_file_size: int, attachment_id: int, download_url: string, id: int, name: string, team_template: record<_href: string, id: int>>
export def "get-v2-team-template-attachments-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of team template attachments to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --team-template-id: list<int> # Filters template attachments by team template IDs
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/team_template_attachments.json"
    query: [{name: ids, var: ids, style: csv}, {name: team_template_id, var: team_template_id, style: csv}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, team_template_id: $team_template_id, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List team templates
#
# GET /v2/team_templates.json
# Returns: table<_links: record, archived_at: string, body: string, body_preview: string, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, id: string, last_modified_at: string, last_modified_user: record<_href: string, id: int>, last_used_at: string, open_tracking_enabled: bool, subject: string, tags: list<string>, title: string, updated_at: string>
export def "get-v2-team-templates-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # IDs of team templates to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --updated-at: list<string> # Equality filters that are applied to the updated_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"type":"object","keys":[{"name":"gt","type":"iso8601 string","description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"gte","type":"iso8601 string","description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lt","type":"iso8601 string","description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision."},{"name":"lte","type":"iso8601 string","description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision."}]}
  --search: string # Filters email templates by title or subject
  --tag-ids: list<int> # Filters email templates by tags applied to the template by tag ID, not to exceed 100 IDs
  --tag: list<string> # Filters team templates by tags applied to the template, not to exceed 100 tags
  --include-archived-templates: oneof<nothing, bool> # Filters email templates to include archived templates or not
  --sort-by: string # Key to sort on, must be one of: created_at, updated_at, last_used_at. Defaults to updated_at
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
  --per-page: int # How many records to show per page in the range [1, 100]. Defaults to 25
  --page: int # The current page to fetch results from. Defaults to 1
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --limit-paging-counts: oneof<nothing, bool> # Specifies whether the max limit of 10k records should be applied to pagination counts. Affects the total_count and total_pages data
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/team_templates.json"
    query: [{name: ids, var: ids, style: csv}, {name: updated_at, var: updated_at, style: csv}, {name: search, var: search}, {name: tag_ids, var: tag_ids, style: csv}, {name: tag, var: tag, style: csv}, {name: include_archived_templates, var: include_archived_templates}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: limit_paging_counts, var: limit_paging_counts}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, updated_at: $updated_at, search: $search, tag_ids: $tag_ids, tag: $tag, include_archived_templates: $include_archived_templates, sort_by: $sort_by, sort_direction: $sort_direction, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, limit_paging_counts: $limit_paging_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a team template
#
# GET /v2/team_templates/{id}.json
# Returns: record<_links: record, archived_at: string, body: string, body_preview: string, click_tracking_enabled: bool, counts: record<bounces: int, clicks: int, replies: int, sent_emails: int, views: int>, created_at: string, id: string, last_modified_at: string, last_modified_user: record<_href: string, id: int>, last_used_at: string, open_tracking_enabled: bool, subject: string, tags: list<string>, title: string, updated_at: string>
export def "get-v2-team-templates-id-json" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-signature: oneof<nothing, bool> # Optionally will return the templates with the current user's email signature
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/team_templates/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: include_signature, var: include_signature}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_signature: $include_signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a live feed item
#
# POST /v2/third_party_live_feed_items
# Returns: table<alert_metadata: record, event_occurred_at: string, event_type: string, id: int, message: string, metadata: record, path: string, rollup_key: string, title: string, user_guid: string>
export def "post-v2-third-party-live-feed-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event_occurred_at: string # Equality filters that are applied to the event_occurred_at field. A single filter can be used by itself or combined with other filters to create a range. ---CUSTOM--- {"keys":[{"description":"Returns all matching records that are greater than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gt","type":"iso8601 string"},{"description":"Returns all matching records that are greater than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"gte","type":"iso8601 string"},{"description":"Returns all matching records that are less than the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lt","type":"iso8601 string"},{"description":"Returns all matching records that are less than or equal to the provided iso8601 timestamp. The comparison is done using microsecond precision.","name":"lte","type":"iso8601 string"}],"type":"object"}
  idempotency_key: string # Uniquely provided string specific to this event. This should be a value which can't be duplicated between external systems, meaning that an id is not sufficient.
  message: string # The message that relates to the subject. This message should start with a lower-case past-tense verb and end with a period (e.g. "received a package."). When live feed items are displayed to users, the subject's name is concatenated with the message and a joining space. Only HTML tags with an "href" attribute are allowed. Other attributes and tags will be stripped.
  subject_id: int # The ID of the subject of the live feed item (i.e. the "person" id).
  subject_type: string # The type of the subject of the live feed item. Currently only "person" is supported.
  user_guid: string # The guid for the user that this live feed item should be shown to.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/third_party_live_feed_items"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: event_occurred_at, var: event_occurred_at}, {name: idempotency_key, var: idempotency_key}, {name: message, var: message}, {name: subject_id, var: subject_id}, {name: subject_type, var: subject_type}, {name: user_guid, var: user_guid}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    event_occurred_at: $event_occurred_at, idempotency_key: $idempotency_key, message: $message, subject_id: $subject_id, subject_type: $subject_type, user_guid: $user_guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /v2/users.json
# Returns: table<_private_fields: record, active: bool, bcc_email_address: string, click_to_call_enabled: bool, created_at: string, crm_connected: bool, email: string, email_client_configured: bool, email_client_email_address: string, email_signature: string, email_signature_click_tracking_disabled: bool, email_signature_type: string, external_feature_flags: record, first_name: string, from_address: string, full_email_address: string, group: record<_href: string, id: int>, guid: string, id: int, job_role: string, last_name: string, local_dial_enabled: bool, name: string, phone_client: record<_href: string, id: int>, phone_number_assignment: record<_href: string, id: int>, role: record<_href: string, id: int>, sending_email_address: string, slack_username: string, team: record<_href: string, id: int>, team_admin: bool, time_zone: string, twitter_handle: string, updated_at: string, work_country: string>
export def "get-v2-users-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # IDs of users to fetch. If a record can't be found, that record won't be returned and your request will be successful
  --guid: list<string> # Filters list to only include guids
  --group-id: list<string> # Filters users by group_id. An additional value of "_is_null" can be passed to filter users that are not in a group
  --role-id: list<string> # Filters users by role_id
  --search: string # Space-separated list of keywords used to find case-insensitive substring matches against First Name, Last Name, or Email
  --active: oneof<nothing, bool> # Filters users based on active attribute. Defaults to not applied
  --visible-only: oneof<nothing, bool> # Defaults to true. When true, only shows users that are actionable based on the team's privacy settings. When false, shows all users on the team, even if you can't take action on that user. Deactivated users are also included when false.
  --per-page: int # How many users to show per page in the range [1, 100]. Defaults to 25. Results are only paginated if the page parameter is defined
  --page: int # The current page to fetch users from. Defaults to returning all users
  --include-paging-counts: oneof<nothing, bool> # Whether to include total_pages and total_count in the metadata. Defaults to false
  --has-crm-user: oneof<nothing, bool> # Filters users based on if they have a crm user mapped or not.
  --work-country: list<string> # Filters users based on assigned work_country.
  --sort-by: string # Key to sort on, must be one of: id, email, name, group, role. Defaults to id
  --sort-direction: string # Direction to sort in, must be one of: ASC, DESC. Defaults to DESC
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/users.json"
    query: [{name: ids, var: ids, style: csv}, {name: guid, var: guid, style: csv}, {name: group_id, var: group_id, style: csv}, {name: role_id, var: role_id, style: csv}, {name: search, var: search}, {name: active, var: active}, {name: visible_only, var: visible_only}, {name: per_page, var: per_page}, {name: page, var: page}, {name: include_paging_counts, var: include_paging_counts}, {name: has_crm_user, var: has_crm_user}, {name: work_country, var: work_country, style: csv}, {name: sort_by, var: sort_by}, {name: sort_direction, var: sort_direction}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, guid: $guid, group_id: $group_id, role_id: $role_id, search: $search, active: $active, visible_only: $visible_only, per_page: $per_page, page: $page, include_paging_counts: $include_paging_counts, has_crm_user: $has_crm_user, work_country: $work_country, sort_by: $sort_by, sort_direction: $sort_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a user
#
# GET /v2/users/{id}.json
# Returns: record<_private_fields: record, active: bool, bcc_email_address: string, click_to_call_enabled: bool, created_at: string, crm_connected: bool, email: string, email_client_configured: bool, email_client_email_address: string, email_signature: string, email_signature_click_tracking_disabled: bool, email_signature_type: string, external_feature_flags: record, first_name: string, from_address: string, full_email_address: string, group: record<_href: string, id: int>, guid: string, id: int, job_role: string, last_name: string, local_dial_enabled: bool, name: string, phone_client: record<_href: string, id: int>, phone_number_assignment: record<_href: string, id: int>, role: record<_href: string, id: int>, sending_email_address: string, slack_username: string, team: record<_href: string, id: int>, team_admin: bool, time_zone: string, twitter_handle: string, updated_at: string, work_country: string>
export def "get-v2-users-id-json" [
  id: string
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
    path: "/v2/users/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webhook subscriptions
#
# GET /v2/webhook_subscriptions
# Returns: table<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>
export def "get-v2-webhook-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Filters webhook subscriptions by whether is enabled or not.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/webhook_subscriptions"
    query: [{name: enabled, var: enabled}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a webhook subscription
#
# POST /v2/webhook_subscriptions
# Returns: record<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>
export def "post-v2-webhook-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  callback_token: string # Any string to be used as a shared secret when subscription events are published. SalesLoft will send the value of this callback_token in the payload of each event so the receiver may verify it matches the original value. This ensures webhook events are being delivered by SalesLoft.
  callback_url: string # URL for your callback handler
  event_type: string # Type of event the subscription is for. Visit the "Event Types" section of the webhooks page to find a list of supported event types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/webhook_subscriptions"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: callback_token, var: callback_token}, {name: callback_url, var: callback_url}, {name: event_type, var: event_type}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    callback_token: $callback_token, callback_url: $callback_url, event_type: $event_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook subscription
#
# DELETE /v2/webhook_subscriptions/{id}
export def "delete-v2-webhook-subscriptions-id" [
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
    path: "/v2/webhook_subscriptions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a webhook subscription
#
# GET /v2/webhook_subscriptions/{id}
# Returns: record<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>
export def "get-v2-webhook-subscriptions-id" [
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
    path: "/v2/webhook_subscriptions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook subscription
#
# PUT /v2/webhook_subscriptions/{id}
# Returns: record<callback_token: string, callback_url: string, enabled: bool, event_type: string, id: int, tenant_id: int, user_guid: string>
export def "put-v2-webhook-subscriptions-id" [
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
  --enabled: oneof<nothing, bool> # Enable or disable the webhook subscription
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/webhook_subscriptions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: enabled, var: enabled}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
