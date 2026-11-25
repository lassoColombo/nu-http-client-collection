# Auto-generated client for ART19 Content API Documentation v1.0.0
# Source: https://api.apis.guru/v2/specs/art19.com/1.0.0/openapi.json
# Auth: --token flag or $env.ART19_CONTENT_API_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://art19.com"
  token_env_var: "ART19_CONTENT_API_DOCUMENTATION_TOKEN"
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

def base-url-completer [] { ["https://art19.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def classification-type-completer [] { ["AlternateFeedType" "Genre" "Industry" "Language" "MediaRating"] }
def classified-type-completer [] { ["Episode" "Season" "Series"] }
def type-completer [] { ["AlternateFeedType" "Genre" "Industry" "Language" "MediaRating"] }
def creditable-type-completer [] { ["Episode" "Season" "Series"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-classification-inclusions: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-classification-inclusions-id: "record<data: record<attributes: record<classification_id: string, classification_type: string, classified_id: string, classified_type: string, created_at: string, position: int, primary: bool, updated_at: string>, id: string, relationships: record<classification: record>, type: string>, links: record<self: string>>"
    get-classifications: "record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-classifications-id: "record<data: record<attributes: record<created_at: string, display_name: string, metadata: record, parent_id: string, tree_path: list, type: string, updated_at: string, value: string, value_path: string>, id: string, type: string>, links: record<self: string>>"
    get-credits: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-credits-id: "record<data: record<attributes: record<created_at: string, position: int, type: string, updated_at: string>, id: string, relationships: record<creditable: record, person: record>, type: string>, links: record<self: string>>"
    get-episodes: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-episodes-id: "record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>"
    get-episodes-id-next-sibling: "record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>"
    get-episodes-id-previous-sibling: "record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>"
    get-images: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-images-id: "record<data: record<attributes: record<bucket_id: string, bucket_type: string, created_at: string, crop_data: record, status: string, updated_at: string>, id: string, relationships: record<media_assets: record>, type: string>, links: record<self: string>>"
    get-media-assets: "record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-media-assets-id: "record<data: record<attributes: record<attachment_id: string, attachment_type: string, cdn_url: string, content_type: string, created_at: string, file_name: string, file_size: int, size_height: int, size_width: int, style: string, updated_at: string>, id: string, type: string>, links: record<self: string>>"
    get-networks: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-networks-id: "record<data: record<attributes: record<copyright: string, created_at: string, description: string, description_is_html: bool, description_plain: string, facebook_url: string, instagram_url: string, linkedin_url: string, name: string, public_email: string, public_page_enabled: bool, slug: string, tumblr_url: string, twitter_url: string, updated_at: string, website_url: string>, id: string, relationships: record<cover_image: record, images: record, parent: record, series: record>, type: string>, links: record<self: string>>"
    get-people: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-people-id: "record<data: record<attributes: record<avatar_id: string, biography: string, born: string, created_at: string, died: string, first_name: string, from_country: string, from_locality: string, from_region: string, last_name: string, public_email: string, updated_at: string>, id: string, relationships: record<avatar: record>, type: string>, links: record<self: string>>"
    get-seasons: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-seasons-id: "record<data: record<attributes: record<cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, first_released_episode_id: string, last_released_episode_id: string, season_number: int, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, episodes: record, first_released_episode: record, images: record, last_released_episode: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>"
    get-series: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>"
    get-series-id: "record<data: record<attributes: record<amazon_subscription_url: string, castbox_subscription_url: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, facebook_url: string, google_subscription_url: string, iheart_subscription_url: string, instagram_url: string, itunes_subscription_badge_enabled: bool, itunes_subscription_url: string, linkedin_url: string, pocket_casts_subscription_url: string, podcast_subscription_url: string, public_page_enabled: bool, public_title: string, radio_public_subscription_url: string, rss_author: string, rss_copyright: string, rss_email: string, rss_owner: string, slug: string, sort_title: string, spotify_subscription_badge_enabled: bool, spotify_subscription_url: string, status: string, stitcher_subscription_badge_enabled: bool, stitcher_subscription_url: string, title: string, tumblr_url: string, tune_in_subscription_url: string, twitter_url: string, type: string, updated_at: string, website_url: string>, id: string, relationships: record<classification_inclusions: record, cover_image: record, credits: record, episodes: record, images: record, network: record, seasons: record, taggings: record, tags: record>, type: string>, links: record<self: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-classification-inclusions" "get-classification-inclusions-id" "get-classifications" "get-classifications-id" "get-credits" "get-credits-id" "get-episodes" "get-episodes-id" "get-episodes-id-next-sibling" "get-episodes-id-previous-sibling" "get-images" "get-images-id" "get-media-assets" "get-media-assets-id" "get-networks" "get-networks-id" "get-people" "get-people-id" "get-seasons" "get-seasons-id" "get-series" "get-series-id" "commands"] | sort) } | get name | first)
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

# Get ClassificationInclusion records
#
# GET /classification_inclusions
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-classification-inclusions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --classification-id: string # Limit the result to classification inclusions linked to a classification with this ID. (format: uuid, e.g. a90609c0-9f0c-48fd-8a41-83eb8414bedb)
  --classification-type: string@classification-type-completer # The type of classification that the classification inclusions are linked to. Depending on the permissions of your credential, only a subset of these types are usable.
  --classified-id: string # Limit the result to classification inclusions linked to a resource with this ID. You will have to use this filter together with either `classified_type` or `classification_type`. (format: uuid, e.g. fee1976e-f1bc-48a9-9ee8-58800f4d3462)
  --classified-type: string@classified-type-completer # Limit the result to classification inclusions linked to this type of entity.
  --q: string # Limit the result to classification inclusions linked to a classification containing the parameter value disregarding case.
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: created_at)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/classification_inclusions"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: classification_id, var: classification_id}, {name: classification_type, var: classification_type}, {name: classified_id, var: classified_id}, {name: classified_type, var: classified_type}, {name: q, var: q}, {name: sort, var: sort, style: csv}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, classification_id: $classification_id, classification_type: $classification_type, classified_id: $classified_id, classified_type: $classified_type, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific classification inclusion
#
# GET /classification_inclusions/{id}
# Returns: record<data: record<attributes: record<classification_id: string, classification_type: string, classified_id: string, classified_type: string, created_at: string, position: int, primary: bool, updated_at: string>, id: string, relationships: record<classification: record>, type: string>, links: record<self: string>>
export def "get-classification-inclusions-id" [
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
    path: "/classification_inclusions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of classifications
#
# GET /classifications
# Returns: record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-classifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --type: string@type-completer # Limit the result to classifications of this type. The possible values for types depends on the privileges of the provided credential. (e.g. Genre)
  --q: string # Limit the result to classifications with a value containing the parameter value disregarding case.
  --is-country: string # If this parameter is provided and not empty, limit the result to classifications of type `Geography` representing countries. The credential must have at least one privilege with a network, series, or advertiser profile. (e.g. true)
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: value)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/classifications"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: type, var: type}, {name: q, var: q}, {name: is_country, var: is_country}, {name: sort, var: sort, style: csv}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, type: $type, q: $q, is_country: $is_country, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific classification
#
# GET /classifications/{id}
# Returns: record<data: record<attributes: record<created_at: string, display_name: string, metadata: record, parent_id: string, tree_path: list, type: string, updated_at: string, value: string, value_path: string>, id: string, type: string>, links: record<self: string>>
export def "get-classifications-id" [
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
    path: "/classifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of credits
#
# GET /credits
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-credits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --creditable-id: string # Limit the result to credits for the entity with this ID only. If the entity is not published, the credential needs to have the right privilege to list the credits for it. (format: uuid, e.g. 76654e16-76ce-4945-92e9-e0a381917853)
  --creditable-type: string@creditable-type-completer # Limit the result to credits linked to this type of entity only. Depending on the privileges of the credential, this list might be further reduced to only published entities.
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: position)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/credits"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: creditable_id, var: creditable_id}, {name: creditable_type, var: creditable_type}, {name: sort, var: sort, style: csv}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, creditable_id: $creditable_id, creditable_type: $creditable_type, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific credit
#
# GET /credits/{id}
# Returns: record<data: record<attributes: record<created_at: string, position: int, type: string, updated_at: string>, id: string, relationships: record<creditable: record, person: record>, type: string>, links: record<self: string>>
export def "get-credits-id" [
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
    path: "/credits/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of episodes
#
# GET /episodes
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-episodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1. (required)
  --page-size: int # Indicate how many records to return per page. The maximum is 100. (required)
  --included-in-inventory-calendar: string # Limit the result to episodes usable with an inventory management calendar for the provided AdDeal ID. (format: uuid, e.g. b97239ef-1776-489a-a1df-5f70a8407148)
  --month: string # Limit the result to episodes released in this month.
  --published: oneof<nothing, bool> # If `true`, limit the result to published episodes only. If `false`, limit the result to _unpublished_ episodes only.
  --q: string # Limit the result to episodes with a title containing this parameter in a case-insensitive way.
  --released-after: string # Limit the result to episodes released after this timestamp. (format: date-time)
  --released-before: string # Limit the result to episodes released before this timestamp. (format: date-time)
  --rss: oneof<nothing, bool> # If `true`, limit the result to published and released episodes holding an available media file. If this is `true`, it also changes the default sort order to `-released_at`.
  --season-id: string # Limit result to episodes linked to this season. (format: uuid, e.g. 30e7b568-d099-486b-9a8e-51b7594cab7d)
  --series-id: string # Limit the result to episodes linked to this series. (format: uuid, e.g. d0ceb1ff-b95b-4c1e-a7e5-a36ed7b4d3b7)
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: sort_title)
  --year: string # Limit the result to episodes released in this year.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number, required: true}, {name: "page[size]", var: page_size, required: true}, {name: included_in_inventory_calendar, var: included_in_inventory_calendar}, {name: month, var: month}, {name: published, var: published}, {name: q, var: q}, {name: released_after, var: released_after}, {name: released_before, var: released_before}, {name: rss, var: rss}, {name: season_id, var: season_id}, {name: series_id, var: series_id}, {name: sort, var: sort, style: csv}, {name: year, var: year}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, included_in_inventory_calendar: $included_in_inventory_calendar, month: $month, published: $published, q: $q, released_after: $released_after, released_before: $released_before, rss: $rss, season_id: $season_id, series_id: $series_id, sort: $sort, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific episode
#
# GET /episodes/{id}
# Returns: record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>
export def "get-episodes-id" [
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
    path: "/episodes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the episode released right after the specified one
#
# GET /episodes/{id}/next_sibling
# Returns: record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>
export def "get-episodes-id-next-sibling" [
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
  --rss: oneof<nothing, bool> # If `true`, get the next released and published episode with an available media file.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes/{id}/next_sibling"
    path_params: [{name: id, var: id}]
    query: [{name: rss, var: rss}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rss: $rss
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the episode released right before the specified one
#
# GET /episodes/{id}/previous_sibling
# Returns: record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>
export def "get-episodes-id-previous-sibling" [
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
  --rss: oneof<nothing, bool> # If `true`, get the previously released and published episode with an available media file.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes/{id}/previous_sibling"
    path_params: [{name: id, var: id}]
    query: [{name: rss, var: rss}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rss: $rss
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of images
#
# GET /images
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images"
    query: [{name: "ids[]", var: ids, style: multi, required: true}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific image
#
# GET /images/{id}
# Returns: record<data: record<attributes: record<bucket_id: string, bucket_type: string, created_at: string, crop_data: record, status: string, updated_at: string>, id: string, relationships: record<media_assets: record>, type: string>, links: record<self: string>>
export def "get-images-id" [
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
    path: "/images/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of media assets
#
# GET /media_assets
# Returns: record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-media-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/media_assets"
    query: [{name: "ids[]", var: ids, style: multi, required: true}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific media asset
#
# GET /media_assets/{id}
# Returns: record<data: record<attributes: record<attachment_id: string, attachment_type: string, cdn_url: string, content_type: string, created_at: string, file_name: string, file_size: int, size_height: int, size_width: int, style: string, updated_at: string>, id: string, type: string>, links: record<self: string>>
export def "get-media-assets-id" [
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
    path: "/media_assets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of networks
#
# GET /networks
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --q: string # Limit the result to networks with a name containing this parameter in a case-insensitive way.
  --ad-rep-account-id: string # Limit the result to networks containing at least one series with an ad deal of this Ad Ops profile. (format: uuid)
  --ad-deal-status: list<string> # Limit the result to networks containing at least one series with an ad deal matching one of the values in this parameter.
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: q, var: q}, {name: ad_rep_account_id, var: ad_rep_account_id}, {name: ad_deal_status, var: ad_deal_status, style: csv}, {name: sort, var: sort, style: csv}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, q: $q, ad_rep_account_id: $ad_rep_account_id, ad_deal_status: $ad_deal_status, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific network
#
# GET /networks/{id}
# Returns: record<data: record<attributes: record<copyright: string, created_at: string, description: string, description_is_html: bool, description_plain: string, facebook_url: string, instagram_url: string, linkedin_url: string, name: string, public_email: string, public_page_enabled: bool, slug: string, tumblr_url: string, twitter_url: string, updated_at: string, website_url: string>, id: string, relationships: record<cover_image: record, images: record, parent: record, series: record>, type: string>, links: record<self: string>>
export def "get-networks-id" [
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
    path: "/networks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of people
#
# GET /people
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-people" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --q: string # Limit the result to people with a full name containing this parameter in a case-insensitive way.
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: last_name,first_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/people"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: q, var: q}, {name: sort, var: sort, style: csv}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific person
#
# GET /people/{id}
# Returns: record<data: record<attributes: record<avatar_id: string, biography: string, born: string, created_at: string, died: string, first_name: string, from_country: string, from_locality: string, from_region: string, last_name: string, public_email: string, updated_at: string>, id: string, relationships: record<avatar: record>, type: string>, links: record<self: string>>
export def "get-people-id" [
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
    path: "/people/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of seasons
#
# GET /seasons
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-seasons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --series-id: string # Limit the result to seasons owned by this series. (format: uuid, e.g. 7ebd702d-07c8-4da9-a7a8-cf18ec414d5c)
  --q: string # Limit the result to seasons with a title containing this parameter in a case-insensitive way.
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: sort_title)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/seasons"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: series_id, var: series_id}, {name: q, var: q}, {name: sort, var: sort, style: csv}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, series_id: $series_id, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific season
#
# GET /seasons/{id}
# Returns: record<data: record<attributes: record<cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, first_released_episode_id: string, last_released_episode_id: string, season_number: int, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, episodes: record, first_released_episode: record, images: record, last_released_episode: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>>
export def "get-seasons-id" [
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
    path: "/seasons/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of series
#
# GET /series
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>>
export def "get-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --ad-rep-account-id: string # Limit the result to series with an ad deal of this Ad Ops profile. (format: uuid, e.g. 35eb02fc-54db-4650-98e0-4695b101b71d)
  --network-id: string # Limit the result to series owned by this network. (format: uuid, e.g. 5317358a-527e-4365-a343-361854286cc7)
  --q: string # Limit the result to series with a title or slug containing this parameter in a case-insensitive way.
  --sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: sort_title)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series"
    query: [{name: "ids[]", var: ids, style: multi}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: ad_rep_account_id, var: ad_rep_account_id}, {name: network_id, var: network_id}, {name: q, var: q}, {name: sort, var: sort, style: csv}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_number: $page_number, page_size: $page_size, ad_rep_account_id: $ad_rep_account_id, network_id: $network_id, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific series
#
# GET /series/{id}
# Returns: record<data: record<attributes: record<amazon_subscription_url: string, castbox_subscription_url: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, facebook_url: string, google_subscription_url: string, iheart_subscription_url: string, instagram_url: string, itunes_subscription_badge_enabled: bool, itunes_subscription_url: string, linkedin_url: string, pocket_casts_subscription_url: string, podcast_subscription_url: string, public_page_enabled: bool, public_title: string, radio_public_subscription_url: string, rss_author: string, rss_copyright: string, rss_email: string, rss_owner: string, slug: string, sort_title: string, spotify_subscription_badge_enabled: bool, spotify_subscription_url: string, status: string, stitcher_subscription_badge_enabled: bool, stitcher_subscription_url: string, title: string, tumblr_url: string, tune_in_subscription_url: string, twitter_url: string, type: string, updated_at: string, website_url: string>, id: string, relationships: record<classification_inclusions: record, cover_image: record, credits: record, episodes: record, images: record, network: record, seasons: record, taggings: record, tags: record>, type: string>, links: record<self: string>>
export def "get-series-id" [
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
    path: "/series/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
