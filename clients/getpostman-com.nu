# Auto-generated client for Postman API v1.20.0
# Source: https://api.apis.guru/v2/specs/getpostman.com/1.20.0/openapi.json
# Auth: --token flag or $env.POSTMAN_API_TOKEN

const CLIENT = {
  base_url: "https://api.getpostman.com"
  token_env_var: "POSTMAN_API_TOKEN"
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

def base-url-completer [] { ["https://api.getpostman.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-api: "record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>"
    delete-an-api: "record<api: record<id: string>>"
    single-api: "record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>"
    update-an-api: "record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>"
    get-all-api-versions: "record<versions: table<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>"
    create-api-version: "record<version: record<api: string, id: string, name: string>>"
    delete-an-api-version: "record<version: record<id: string>>"
    get-an-api-version: "record<version: record<api: string, createdAt: string, createdBy: string, id: string, name: string, schema: list<string>, updatedAt: string, updatedBy: string>>"
    update-an-api-version: "record<version: record<api: string, createdAt: string, createdBy: string, id: string, name: string, updatedAt: string, updatedBy: string>>"
    get-contract-test-relations: "record<contracttest: table<collectionId: string, id: string, name: string, updatedAt: string>>"
    get-documentation-relations: "record<documentation: table<collectionId: string, id: string, name: string, updatedAt: string>>"
    get-environment-relations: "record<environment: table<id: string, name: string, updatedAt: string>>"
    get-integration-test-relations: "record<integrationtest: table<collectionId: string, id: string, name: string, updatedAt: string>>"
    get-monitor-relations: "record<monitor: table<id: string, monitorId: string, name: string, updatedAt: string>>"
    get-linked-relations: "record<relations: record<contracttest: record<\"2a9b8fa8-88b7-4b86-8372-8e3f6f6e07f2\": record>, integrationtest: record<\"521b0486-ab91-4d3a-9189-43c9380a0533\": record, a236b715-e682-460b-97b6-c1db24f7612e: record>, mock: record<\"4ccd755f-2c80-481b-a262-49b55e12f5e1\": record>>>"
    create-relations: "record<contracttest: list<string>, documentation: list<string>, testsuite: list<string>>"
    create-schema: "record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>>"
    get-schema: "record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>>"
    update-schema: "record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>>"
    create-collection-from-schema: "record<collection: record<id: string, uid: string>, relations: table<id: string, type: string>>"
    get-test-suite-relations: "record<testsuite: table<collectionId: string, id: string, name: string, updatedAt: string>>"
    sync-relations-with-schema: "record<success: bool>"
    all-collections: "record<collections: table<id: string, name: string, owner: string, uid: string>>"
    create-collection: "record<collection: record<id: string, name: string, uid: string>>"
    delete-collection: "record<collection: record<id: string, uid: string>>"
    single-collection: "record<collection: record<info: record<_postman_id: string, description: string, name: string, schema: string>, item: list<record>, variables: list<any>>>"
    update-collection: "record<collection: record<id: string, name: string, uid: string>>"
    all-environments: "record<environments: table<id: string, name: string, owner: string, uid: string>>"
    create-environment: "record<environment: record<id: string, name: string, uid: string>>"
    delete-environment: "record<environment: record<id: string, uid: string>>"
    single-environment: "record<environment: record<id: string, name: string, values: list<record>>>"
    update-environment: "record<environment: record<id: string, name: string, uid: string>>"
    import-exported-data: "record<collections: table<id: string, name: string, uid: string>>"
    import-external-api-specification: "record<collections: table<id: string, name: string, uid: string>>"
    api-key-owner: "record<operations: table<limit: float, name: string, overage: float, usage: float>, user: record<avatar: string, email: string, fullName: string, id: string, isPublic: bool, username: string>>"
    all-mocks: "record<mocks: table<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>>"
    create-mock: "record<mock: record<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>>"
    delete-mock: "record<mock: record<id: string, uid: string>>"
    single-mock: "record<mock: record<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>>"
    update-mock: "record<mock: record<collection: string, config: record<headers: list, matchBody: bool, matchQueryParams: bool, matchWildcards: bool>, environment: string, id: string, mockUrl: string, name: string, owner: string, uid: string>>"
    publish-mock: "record<mock: record<id: string>>"
    unpublish-mock: "record<mock: record<id: string>>"
    all-monitors: "record<monitors: table<id: string, name: string, owner: string, uid: string>>"
    create-monitor: "record<monitor: record<id: string, name: string, uid: string>>"
    delete-monitor: "record<monitor: record<id: string, uid: string>>"
    single-monitor: "record<monitor: record<collectionUid: string, distribution: list<any>, environmentUid: string, id: string, lastRun: record<finishedAt: string, startedAt: string, stats: record, status: string>, name: string, notifications: record<onError: list, onFailure: list>, options: record<followRedirects: bool, requestDelay: float, requestTimeout: float, strictSSL: bool>, owner: string, schedule: record<cron: string, nextRun: string, timezone: string>, uid: string>>"
    update-monitor: "record<monitor: record<id: string, name: string, uid: string>>"
    run-a-monitor: "record<run: record<executions: list<record>, failures: list<record>, info: record<collectionUid: string, finishedAt: string, jobId: string, monitorId: string, name: string, startedAt: string, status: string>, stats: record<assertions: record, requests: record>>>"
    all-workspaces: "record<workspaces: table<id: string, name: string, type: string>>"
    create-workspace: "record<workspace: record<id: string, name: string>>"
    delete-workspace: "record<workspace: record<id: string>>"
    single-workspace: "record<workspace: record<collections: list<record>, description: string, environments: list<record>, id: string, name: string, type: string>>"
    update-workspace: "record<workspace: record<id: string, name: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-all-ap-is" "create-api" "delete-an-api" "single-api" "update-an-api" "get-all-api-versions" "create-api-version" "delete-an-api-version" "get-an-api-version" "update-an-api-version" "get-contract-test-relations" "get-documentation-relations" "get-environment-relations" "get-integration-test-relations" "get-monitor-relations" "get-linked-relations" "create-relations" "create-schema" "get-schema" "update-schema" "create-collection-from-schema" "get-test-suite-relations" "sync-relations-with-schema" "all-collections" "create-collection" "create-a-fork" "merge-a-fork" "delete-collection" "single-collection" "update-collection" "all-environments" "create-environment" "delete-environment" "single-environment" "update-environment" "import-exported-data" "import-external-api-specification" "api-key-owner" "all-mocks" "create-mock" "delete-mock" "single-mock" "update-mock" "publish-mock" "unpublish-mock" "all-monitors" "create-monitor" "delete-monitor" "single-monitor" "update-monitor" "run-a-monitor" "create-webhook" "all-workspaces" "create-workspace" "delete-workspace" "single-workspace" "update-workspace" "commands"] | sort) } | get name | first)
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

# Get all APIs
#
# GET /apis
# operationId: getAllApIs
export def "get-all-ap-is" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # Only return APIs that are inside the given workspace. (e.g. {{workspaceId}})
  --since: string # Only return APIs that have been updated after this time. Time is represented using the ISO 8601 date and time format. (e.g. {{since}})
  --until: string # Only return APIs that have been updated before this time. Time is represented using the ISO 8601 date and time format. (e.g. {{until}})
  --created-by: string # Only return APIs that have been created by the user ID represented by the given value. (e.g. {{createdBy}})
  --updated-by: string # Only return APIs that have been updated by the user ID represented by the given value. (e.g. {{updatedBy}})
  --is-public: string # Only return APIs with the corresponding privacy state. Public APIs have the isPublic value true; private APIs have the isPublic value false. (e.g. {{isPublic}})
  --name: string # Only return APIs whose name includes the given value. Matching is case insensitive. (e.g. {{name}})
  --summary: string # Only return APIs whose summary includes the given value. Matching is case insensitive. (e.g. {{summary}})
  --description: string # Only return APIs whose description includes the given value. Matching is case insensitive. (e.g. {{description}})
  --sort: string # The value of sort can be one of the names of the fields included in the response. (e.g. {{sort}})
  --direction: string # The sorting direction, which can be ascending or descending. The value can be asc to specify an ascending direction or desc to specify a descending direction. If none is specified, the default sorting direction is descending for timestamp and numeric fields and ascending otherwise. An ID is not considered a numeric field. (e.g. {{direction}})
]: nothing -> any {
  http-request {
    method: get
    path: "/apis"
    query: [{name: workspace, var: workspace}, {name: since, var: since}, {name: until, var: until}, {name: createdBy, var: created_by}, {name: updatedBy, var: updated_by}, {name: isPublic, var: is_public}, {name: name, var: name}, {name: summary, var: summary}, {name: description, var: description}, {name: sort, var: sort}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, since: $since, until: $until, created_by: $created_by, updated_by: $updated_by, is_public: $is_public, name: $name, summary: $summary, description: $description, sort: $sort, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create API
#
# POST /apis
# Returns: record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>
# operationId: createApi
export def "create-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # e.g. {{workspaceId}}
  --api: record # shape: {description?: string, name?: string, summary?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apis"
    query: [{name: workspace, var: workspace}]
    body: {content_type: "application/json", kind: json, fields: [{name: api, var: api}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, api: $api
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an API
#
# DELETE /apis/{apiId}
# Returns: record<api: record<id: string>>
# operationId: deleteAnApi
export def "delete-an-api" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single API
#
# GET /apis/{apiId}
# Returns: record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>
# operationId: singleApi
export def "single-api" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an API
#
# PUT /apis/{apiId}
# Returns: record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>
# operationId: updateAnApi
export def "update-an-api" [
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
  --api: record # shape: {description?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api, var: api}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api: $api
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All API Versions
#
# GET /apis/{apiId}/versions
# Returns: record<versions: table<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>>
# operationId: getAllApiVersions
export def "get-all-api-versions" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apis/{apiId}/versions"
    path_params: [{name: apiId, var: api_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create API Version
#
# POST /apis/{apiId}/versions
# Returns: record<version: record<api: string, id: string, name: string>>
# operationId: createApiVersion
export def "create-api-version" [
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
  --version: record # shape: {name?: string, source?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apis/{apiId}/versions"
    path_params: [{name: apiId, var: api_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an API Version
#
# DELETE /apis/{apiId}/versions/{apiVersionId}
# Returns: record<version: record<id: string>>
# operationId: deleteAnApiVersion
export def "delete-an-api-version" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apis/{apiId}/versions/{apiVersionId}"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an API Version
#
# GET /apis/{apiId}/versions/{apiVersionId}
# Returns: record<version: record<api: string, createdAt: string, createdBy: string, id: string, name: string, schema: list<string>, updatedAt: string, updatedBy: string>>
# operationId: getAnApiVersion
export def "get-an-api-version" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an API Version
#
# PUT /apis/{apiId}/versions/{apiVersionId}
# Returns: record<version: record<api: string, createdAt: string, createdBy: string, id: string, name: string, updatedAt: string, updatedBy: string>>
# operationId: updateAnApiVersion
export def "update-an-api-version" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: record # shape: {name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apis/{apiId}/versions/{apiVersionId}"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contract test relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/contracttest
# Returns: record<contracttest: table<collectionId: string, id: string, name: string, updatedAt: string>>
# operationId: getContractTestRelations
export def "get-contract-test-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/contracttest"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get documentation relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/documentation
# Returns: record<documentation: table<collectionId: string, id: string, name: string, updatedAt: string>>
# operationId: getDocumentationRelations
export def "get-documentation-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/documentation"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get environment relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/environment
# Returns: record<environment: table<id: string, name: string, updatedAt: string>>
# operationId: getEnvironmentRelations
export def "get-environment-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/environment"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get integration test relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/integrationtest
# Returns: record<integrationtest: table<collectionId: string, id: string, name: string, updatedAt: string>>
# operationId: getIntegrationTestRelations
export def "get-integration-test-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/integrationtest"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get monitor relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/monitor
# Returns: record<monitor: table<id: string, monitorId: string, name: string, updatedAt: string>>
# operationId: getMonitorRelations
export def "get-monitor-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/monitor"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get linked relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/relations
# Returns: record<relations: record<contracttest: record<"2a9b8fa8-88b7-4b86-8372-8e3f6f6e07f2": record>, integrationtest: record<"521b0486-ab91-4d3a-9189-43c9380a0533": record, a236b715-e682-460b-97b6-c1db24f7612e: record>, mock: record<"4ccd755f-2c80-481b-a262-49b55e12f5e1": record>>>
# operationId: getLinkedRelations
export def "get-linked-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/relations"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create relations
#
# POST /apis/{apiId}/versions/{apiVersionId}/relations
# Returns: record<contracttest: list<string>, documentation: list<string>, testsuite: list<string>>
# operationId: createRelations
export def "create-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contracttest: list<string>
  --documentation: list<string>
  --mock: list<string>
  --testsuite: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apis/{apiId}/versions/{apiVersionId}/relations"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contracttest, var: contracttest}, {name: documentation, var: documentation}, {name: mock, var: mock}, {name: testsuite, var: testsuite}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id, contracttest: $contracttest, documentation: $documentation, mock: $mock, testsuite: $testsuite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Schema
#
# POST /apis/{apiId}/versions/{apiVersionId}/schemas
# Returns: record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>>
# operationId: createSchema
export def "create-schema" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: record # shape: {language?: string, schema?: string, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apis/{apiId}/versions/{apiVersionId}/schemas"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: schema, var: schema}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id, schema: $schema
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Schema
#
# GET /apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}
# Returns: record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>>
# operationId: getSchema
export def "get-schema" [
  api_id: string
  api_version_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}, {name: schemaId, var: schema_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id, schema_id: $schema_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Schema
#
# PUT /apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}
# Returns: record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>>
# operationId: updateSchema
export def "update-schema" [
  api_id: string
  api_version_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: record # shape: {language?: string, schema?: string, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}, {name: schemaId, var: schema_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: schema, var: schema}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id, schema_id: $schema_id, schema: $schema
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create collection from schema
#
# POST /apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}/collections
# Returns: record<collection: record<id: string, uid: string>, relations: table<id: string, type: string>>
# operationId: createCollectionFromSchema
export def "create-collection-from-schema" [
  api_id: string
  api_version_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # e.g. {{workspaceId}}
  --name: string # e.g. My generated collection
  --relations: list # item shape: {type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}/collections"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}, {name: schemaId, var: schema_id}]
    query: [{name: workspace, var: workspace}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: relations, var: relations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id, schema_id: $schema_id, workspace: $workspace, name: $name, relations: $relations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get test suite relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/testsuite
# Returns: record<testsuite: table<collectionId: string, id: string, name: string, updatedAt: string>>
# operationId: getTestSuiteRelations
export def "get-test-suite-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/testsuite"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sync relations with schema
#
# PUT /apis/{apiId}/versions/{apiVersionId}/{entityType}/{entityId}/syncWithSchema
# Returns: record<success: bool>
# operationId: syncRelationsWithSchema
export def "sync-relations-with-schema" [
  api_id: string
  api_version_id: string
  entity_type: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apis/{apiId}/versions/{apiVersionId}/{entityType}/{entityId}/syncWithSchema"
    path_params: [{name: apiId, var: api_id}, {name: apiVersionId, var: api_version_id}, {name: entityType, var: entity_type}, {name: entityId, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, api_version_id: $api_version_id, entity_type: $entity_type, entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All Collections
#
# GET /collections
# Returns: record<collections: table<id: string, name: string, owner: string, uid: string>>
# operationId: allCollections
export def "all-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/collections"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Collection
#
# POST /collections
# Returns: record<collection: record<id: string, name: string, uid: string>>
# operationId: createCollection
export def "create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection: record # shape: {info?: record, item?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collections"
    body: {content_type: "application/json", kind: json, fields: [{name: collection, var: collection}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection: $collection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Fork
#
# POST /collections/fork/{collection_uid}
# operationId: createAFork
export def "create-a-fork" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # Workspace ID is required to create a fork (e.g. {{workspace_id}})
  --name: string # e.g. Fork name
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/fork/{collection_uid}"
    path_params: [{name: collection_uid, var: collection_uid}]
    query: [{name: workspace, var: workspace}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_uid: $collection_uid, workspace: $workspace, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge a Fork
#
# POST /collections/merge
# operationId: mergeAFork
export def "merge-a-fork" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination: string # e.g. {{destination_collection_uid}}
  --source: string # e.g. {{source_collection_uid}}
  --strategy: string # e.g. deleteSource
]: any -> any {
  $in | http-request {
    method: post
    path: "/collections/merge"
    body: {content_type: "application/json", kind: json, fields: [{name: destination, var: destination}, {name: source, var: source}, {name: strategy, var: strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    destination: $destination, source: $source, strategy: $strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Collection
#
# DELETE /collections/{collection_uid}
# Returns: record<collection: record<id: string, uid: string>>
# operationId: deleteCollection
export def "delete-collection" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/collections/{collection_uid}"
    path_params: [{name: collection_uid, var: collection_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_uid: $collection_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single Collection
#
# GET /collections/{collection_uid}
# Returns: record<collection: record<info: record<_postman_id: string, description: string, name: string, schema: string>, item: list<record>, variables: list<any>>>
# operationId: singleCollection
export def "single-collection" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/collections/{collection_uid}"
    path_params: [{name: collection_uid, var: collection_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_uid: $collection_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Collection
#
# PUT /collections/{collection_uid}
# Returns: record<collection: record<id: string, name: string, uid: string>>
# operationId: updateCollection
export def "update-collection" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection: record # shape: {info?: record, item?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/collections/{collection_uid}"
    path_params: [{name: collection_uid, var: collection_uid}]
    body: {content_type: "application/json", kind: json, fields: [{name: collection, var: collection}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_uid: $collection_uid, collection: $collection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All Environments
#
# GET /environments
# Returns: record<environments: table<id: string, name: string, owner: string, uid: string>>
# operationId: allEnvironments
export def "all-environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/environments"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Environment
#
# POST /environments
# Returns: record<environment: record<id: string, name: string, uid: string>>
# operationId: createEnvironment
export def "create-environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: record # shape: {name?: string, values?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/environments"
    body: {content_type: "application/json", kind: json, fields: [{name: environment, var: environment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment: $environment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Environment
#
# DELETE /environments/{environment_uid}
# Returns: record<environment: record<id: string, uid: string>>
# operationId: deleteEnvironment
export def "delete-environment" [
  environment_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/environments/{environment_uid}"
    path_params: [{name: environment_uid, var: environment_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment_uid: $environment_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single Environment
#
# GET /environments/{environment_uid}
# Returns: record<environment: record<id: string, name: string, values: list<record>>>
# operationId: singleEnvironment
export def "single-environment" [
  environment_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/environments/{environment_uid}"
    path_params: [{name: environment_uid, var: environment_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment_uid: $environment_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Environment
#
# PUT /environments/{environment_uid}
# Returns: record<environment: record<id: string, name: string, uid: string>>
# operationId: updateEnvironment
export def "update-environment" [
  environment_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: record # shape: {name?: string, values?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/environments/{environment_uid}"
    path_params: [{name: environment_uid, var: environment_uid}]
    body: {content_type: "application/json", kind: json, fields: [{name: environment, var: environment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    environment_uid: $environment_uid, environment: $environment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import exported data
#
# POST /import/exported
# Returns: record<collections: table<id: string, name: string, uid: string>>
# operationId: importExportedData
export def "import-exported-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/import/exported"
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import external API specification
#
# POST /import/openapi
# Returns: record<collections: table<id: string, name: string, uid: string>>
# operationId: importExternalApiSpecification
export def "import-external-api-specification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --input: record # shape: {info?: record, openapi?: string, paths?: record, servers?: list}
  --type: string # e.g. json
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/import/openapi"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    input: $input, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API Key Owner
#
# GET /me
# Returns: record<operations: table<limit: float, name: string, overage: float, usage: float>, user: record<avatar: string, email: string, fullName: string, id: string, isPublic: bool, username: string>>
# operationId: apiKeyOwner
export def "api-key-owner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All Mocks
#
# GET /mocks
# Returns: record<mocks: table<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>>
# operationId: allMocks
export def "all-mocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/mocks"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Mock
#
# POST /mocks
# Returns: record<mock: record<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>>
# operationId: createMock
export def "create-mock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mock: record # shape: {collection?: string, environment?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/mocks"
    body: {content_type: "application/json", kind: json, fields: [{name: mock, var: mock}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mock: $mock
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Mock
#
# DELETE /mocks/{mock_uid}
# Returns: record<mock: record<id: string, uid: string>>
# operationId: deleteMock
export def "delete-mock" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/mocks/{mock_uid}"
    path_params: [{name: mock_uid, var: mock_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mock_uid: $mock_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single Mock
#
# GET /mocks/{mock_uid}
# Returns: record<mock: record<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>>
# operationId: singleMock
export def "single-mock" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/mocks/{mock_uid}"
    path_params: [{name: mock_uid, var: mock_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mock_uid: $mock_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Mock
#
# PUT /mocks/{mock_uid}
# Returns: record<mock: record<collection: string, config: record<headers: list, matchBody: bool, matchQueryParams: bool, matchWildcards: bool>, environment: string, id: string, mockUrl: string, name: string, owner: string, uid: string>>
# operationId: updateMock
export def "update-mock" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mock: record # shape: {description?: string, environment?: string, name?: string, private?: bool, versionTag?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/mocks/{mock_uid}"
    path_params: [{name: mock_uid, var: mock_uid}]
    body: {content_type: "application/json", kind: json, fields: [{name: mock, var: mock}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mock_uid: $mock_uid, mock: $mock
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publish Mock
#
# POST /mocks/{mock_uid}/publish
# Returns: record<mock: record<id: string>>
# operationId: publishMock
export def "publish-mock" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/mocks/{mock_uid}/publish"
    path_params: [{name: mock_uid, var: mock_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mock_uid: $mock_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unpublish Mock
#
# DELETE /mocks/{mock_uid}/unpublish
# Returns: record<mock: record<id: string>>
# operationId: unpublishMock
export def "unpublish-mock" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/mocks/{mock_uid}/unpublish"
    path_params: [{name: mock_uid, var: mock_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mock_uid: $mock_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All Monitors
#
# GET /monitors
# Returns: record<monitors: table<id: string, name: string, owner: string, uid: string>>
# operationId: allMonitors
export def "all-monitors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/monitors"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Monitor
#
# POST /monitors
# Returns: record<monitor: record<id: string, name: string, uid: string>>
# operationId: createMonitor
export def "create-monitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor: record # shape: {collection?: string, environment?: string, name?: string, schedule?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/monitors"
    body: {content_type: "application/json", kind: json, fields: [{name: monitor, var: monitor}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    monitor: $monitor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Monitor
#
# DELETE /monitors/{monitor_uid}
# Returns: record<monitor: record<id: string, uid: string>>
# operationId: deleteMonitor
export def "delete-monitor" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/monitors/{monitor_uid}"
    path_params: [{name: monitor_uid, var: monitor_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    monitor_uid: $monitor_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single Monitor
#
# GET /monitors/{monitor_uid}
# Returns: record<monitor: record<collectionUid: string, distribution: list<any>, environmentUid: string, id: string, lastRun: record<finishedAt: string, startedAt: string, stats: record, status: string>, name: string, notifications: record<onError: list, onFailure: list>, options: record<followRedirects: bool, requestDelay: float, requestTimeout: float, strictSSL: bool>, owner: string, schedule: record<cron: string, nextRun: string, timezone: string>, uid: string>>
# operationId: singleMonitor
export def "single-monitor" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/monitors/{monitor_uid}"
    path_params: [{name: monitor_uid, var: monitor_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    monitor_uid: $monitor_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Monitor
#
# PUT /monitors/{monitor_uid}
# Returns: record<monitor: record<id: string, name: string, uid: string>>
# operationId: updateMonitor
export def "update-monitor" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor: record # shape: {name?: string, schedule?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/monitors/{monitor_uid}"
    path_params: [{name: monitor_uid, var: monitor_uid}]
    body: {content_type: "application/json", kind: json, fields: [{name: monitor, var: monitor}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    monitor_uid: $monitor_uid, monitor: $monitor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run a Monitor
#
# POST /monitors/{monitor_uid}/run
# Returns: record<run: record<executions: list<record>, failures: list<record>, info: record<collectionUid: string, finishedAt: string, jobId: string, monitorId: string, name: string, startedAt: string, status: string>, stats: record<assertions: record, requests: record>>>
# operationId: runAMonitor
export def "run-a-monitor" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/monitors/{monitor_uid}/run"
    path_params: [{name: monitor_uid, var: monitor_uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    monitor_uid: $monitor_uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Webhook
#
# POST /webhooks
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
  --workspace: string # e.g. {{workspace_id}}
  --webhook: record # shape: {collection?: string, name?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/webhooks"
    query: [{name: workspace, var: workspace}]
    body: {content_type: "application/json", kind: json, fields: [{name: webhook, var: webhook}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, webhook: $webhook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All workspaces
#
# GET /workspaces
# Returns: record<workspaces: table<id: string, name: string, type: string>>
# operationId: allWorkspaces
export def "all-workspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/workspaces"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Workspace
#
# POST /workspaces
# Returns: record<workspace: record<id: string, name: string>>
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
  --workspace: record # shape: {collections?: list, description?: string, environments?: list, mocks?: list, monitors?: list, name?: string, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workspaces"
    body: {content_type: "application/json", kind: json, fields: [{name: workspace, var: workspace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Workspace
#
# DELETE /workspaces/{workspace_id}
# Returns: record<workspace: record<id: string>>
# operationId: deleteWorkspace
export def "delete-workspace" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/workspaces/{workspace_id}"
    path_params: [{name: workspace_id, var: workspace_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Single workspace
#
# GET /workspaces/{workspace_id}
# Returns: record<workspace: record<collections: list<record>, description: string, environments: list<record>, id: string, name: string, type: string>>
# operationId: singleWorkspace
export def "single-workspace" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/workspaces/{workspace_id}"
    path_params: [{name: workspace_id, var: workspace_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Workspace
#
# PUT /workspaces/{workspace_id}
# Returns: record<workspace: record<id: string, name: string>>
# operationId: updateWorkspace
export def "update-workspace" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: record # shape: {collections?: list, description?: string, environments?: list, mocks?: list, monitors?: list, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/workspaces/{workspace_id}"
    path_params: [{name: workspace_id, var: workspace_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: workspace, var: workspace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_id: $workspace_id, workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
