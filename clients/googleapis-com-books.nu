# Auto-generated client for Books API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/books/v1/openapi.json
# Auth: --token flag or $env.BOOKS_API_TOKEN

const CLIENT = {
  base_url: "https://books.googleapis.com"
  token_env_var: "BOOKS_API_TOKEN"
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

def base-url-completer [] { ["https://books.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def license-types-completer [] { ["BOTH" "CONCURRENT" "DOWNLOAD" "LICENSE_TYPES_UNDEFINED"] }
def reason-completer [] { ["IOS_PREX" "IOS_SEARCH" "ONBOARDING" "REASON_UNDEFINED"] }
def reason-completer-1 [] { ["ONBOARDING" "REASON_UNDEFINED"] }
def projection-completer [] { ["FULL" "LITE" "PROJECTION_UNDEFINED"] }
def action-completer [] { ["ACTION_UNDEFINED" "bookmark" "chapter" "next-page" "prev-page" "scroll" "search"] }
def max-allowed-maturity-rating-completer [] { ["MATURE" "MAX_ALLOWED_MATURITY_RATING_UNDEFINED" "not-mature"] }
def download-completer [] { ["DOWNLOAD_UNDEFINED" "EPUB"] }
def filter-completer [] { ["FILTER_UNDEFINED" "ebooks" "free-ebooks" "full" "paid-ebooks" "partial"] }
def library-restrict-completer [] { ["LIBRARY_RESTRICT_UNDEFINED" "my-library" "no-restrict"] }
def order-by-completer [] { ["ORDER_BY_UNDEFINED" "newest" "relevance"] }
def print-type-completer [] { ["ALL" "BOOKS" "MAGAZINES" "PRINT_TYPE_UNDEFINED"] }
def rating-completer [] { ["HAVE_IT" "NOT_INTERESTED" "RATING_UNDEFINED"] }
def association-completer [] { ["ASSOCIATION_UNDEFINED" "end-of-sample" "end-of-volume" "related-for-play"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    books-cloudloading-add-book: "record<author: string, processingState: string, title: string, volumeId: string>"
    books-cloudloading-delete-book: "record"
    books-cloudloading-update-book: "record<author: string, processingState: string, title: string, volumeId: string>"
    books-dictionary-list-offline-metadata: "record<items: table<download_url: string, encrypted_key: string, language: string, size: string, version: string>, kind: string>"
    books-familysharing-get-family-info: "record<kind: string, membership: record<acquirePermission: string, ageGroup: string, allowedMaturityRating: string, isInFamily: bool, role: string>>"
    books-familysharing-share: "record"
    books-familysharing-unshare: "record"
    books-myconfig-get-user-settings: "record<kind: string, notesExport: record<folderName: string, isEnabled: bool>, notification: record<matchMyInterests: record<opted_state: string>, moreFromAuthors: record<opted_state: string>, moreFromSeries: record<opted_state: string>, priceDrop: record<opted_state: string>, rewardExpirations: record<opted_state: string>>>"
    books-myconfig-release-download-access: "record<downloadAccessList: table<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, kind: string>"
    books-myconfig-request-access: "record<concurrentAccess: record<deviceAllowed: bool, kind: string, maxConcurrentDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, timeWindowSeconds: int, volumeId: string>, downloadAccess: record<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, kind: string>"
    books-myconfig-sync-volume-licenses: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-myconfig-update-user-settings: "record<kind: string, notesExport: record<folderName: string, isEnabled: bool>, notification: record<matchMyInterests: record<opted_state: string>, moreFromAuthors: record<opted_state: string>, moreFromSeries: record<opted_state: string>, priceDrop: record<opted_state: string>, rewardExpirations: record<opted_state: string>>>"
    books-mylibrary-annotations-list: "record<items: table<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record, created: string, currentVersionRanges: record, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record, pageIds: list, selectedText: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int>"
    books-mylibrary-annotations-insert: "record<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, created: string, currentVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int>, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string>"
    books-mylibrary-annotations-summary: "record<kind: string, layers: table<allowedCharacterCount: int, layerId: string, limitType: string, remainingCharacterCount: int, updated: string>>"
    books-mylibrary-annotations-delete: "record"
    books-mylibrary-annotations-update: "record<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, created: string, currentVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int>, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string>"
    books-mylibrary-bookshelves-list: "record<items: table<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>, kind: string>"
    books-mylibrary-bookshelves-get: "record<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>"
    books-mylibrary-bookshelves-add-volume: "record"
    books-mylibrary-bookshelves-clear-volumes: "record"
    books-mylibrary-bookshelves-move-volume: "record"
    books-mylibrary-bookshelves-remove-volume: "record"
    books-mylibrary-bookshelves-volumes-list: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-mylibrary-readingpositions-get: "record<epubCfiPosition: string, gbImagePosition: string, gbTextPosition: string, kind: string, pdfPosition: string, updated: string, volumeId: string>"
    books-mylibrary-readingpositions-set-position: "record"
    books-notification-get: "record<body: string, crmExperimentIds: list<string>, doc_id: string, doc_type: string, dont_show_notification: bool, iconUrl: string, is_document_mature: bool, kind: string, notificationGroup: string, notification_type: string, pcampaign_id: string, reason: string, show_notification_settings_action: bool, targetUrl: string, timeToExpireMs: string, title: string>"
    books-onboarding-list-categories: "record<items: table<badgeUrl: string, categoryId: string, name: string>, kind: string>"
    books-onboarding-list-category-volumes: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, nextPageToken: string>"
    books-personalizedstream-get: "record<clusters: table<banner_with_content_container: record, subTitle: string, title: string, totalVolumes: int, uid: string, volumes: list>, kind: string, totalClusters: int>"
    books-promooffer-accept: "record"
    books-promooffer-dismiss: "record"
    books-promooffer-get: "record<items: table<artUrl: string, gservicesKey: string, id: string, items: list>, kind: string>"
    books-series-get: "record<kind: string, series: table<bannerImageUrl: string, eligibleForSubscription: bool, imageUrl: string, isComplete: bool, seriesFormatType: string, seriesId: string, seriesSubscriptionReleaseInfo: record, seriesType: string, subscriptionId: string, title: string>>"
    books-series-membership-get: "record<kind: string, member: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, nextPageToken: string>"
    books-bookshelves-list: "record<items: table<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>, kind: string>"
    books-bookshelves-get: "record<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>"
    books-bookshelves-volumes-list: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-volumes-list: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-volumes-mybooks-list: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-volumes-recommended-list: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-volumes-recommended-rate: "record<consistency_token: string>"
    books-volumes-useruploaded-list: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-volumes-get: "record<accessInfo: record<accessViewStatus: string, country: string, downloadAccess: record<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, driveImportedContentLink: string, embeddable: bool, epub: record<acsTokenLink: string, downloadLink: string, isAvailable: bool>, explicitOfflineLicenseManagement: bool, pdf: record<acsTokenLink: string, downloadLink: string, isAvailable: bool>, publicDomain: bool, quoteSharingAllowed: bool, textToSpeechPermission: string, viewOrderUrl: string, viewability: string, webReaderLink: string>, etag: string, id: string, kind: string, layerInfo: record<layers: list<record>>, recommendedInfo: record<explanation: string>, saleInfo: record<buyLink: string, country: string, isEbook: bool, listPrice: record<amount: float, currencyCode: string>, offers: list<record>, onSaleDate: string, retailPrice: record<amount: float, currencyCode: string>, saleability: string>, searchInfo: record<textSnippet: string>, selfLink: string, userInfo: record<acquiredTime: string, acquisitionType: int, copy: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int, updated: string>, entitlementType: int, familySharing: record<familyRole: string, isSharingAllowed: bool, isSharingDisabledByFop: bool>, isFamilySharedFromUser: bool, isFamilySharedToUser: bool, isFamilySharingAllowed: bool, isFamilySharingDisabledByFop: bool, isInMyBooks: bool, isPreordered: bool, isPurchased: bool, isUploaded: bool, readingPosition: record<epubCfiPosition: string, gbImagePosition: string, gbTextPosition: string, kind: string, pdfPosition: string, updated: string, volumeId: string>, rentalPeriod: record<endUtcSec: string, startUtcSec: string>, rentalState: string, review: record<author: record, content: string, date: string, fullTextUrl: string, kind: string, rating: string, source: record, title: string, type: string, volumeId: string>, updated: string, userUploadedVolumeInfo: record<processingState: string>>, volumeInfo: record<allowAnonLogging: bool, authors: list<string>, averageRating: float, canonicalVolumeLink: string, categories: list<string>, comicsContent: bool, contentVersion: string, description: string, dimensions: record<height: string, thickness: string, width: string>, imageLinks: record<extraLarge: string, large: string, medium: string, small: string, smallThumbnail: string, thumbnail: string>, industryIdentifiers: list<record>, infoLink: string, language: string, mainCategory: string, maturityRating: string, pageCount: int, panelizationSummary: record<containsEpubBubbles: bool, containsImageBubbles: bool, epubBubbleVersion: string, imageBubbleVersion: string>, previewLink: string, printType: string, printedPageCount: int, publishedDate: string, publisher: string, ratingsCount: int, readingModes: record<image: bool, text: bool>, samplePageCount: int, seriesInfo: record<bookDisplayNumber: string, kind: string, shortSeriesBookTitle: string, volumeSeries: list>, subtitle: string, title: string>>"
    books-volumes-associated-list: "record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>"
    books-layers-volume-annotations-list: "record<items: table<annotationDataId: string, annotationDataLink: string, annotationType: string, contentRanges: record, data: string, deleted: bool, id: string, kind: string, layerId: string, pageIds: list, selectedText: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int, version: string>"
    books-layers-volume-annotations-get: "record<annotationDataId: string, annotationDataLink: string, annotationType: string, contentRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, id: string, kind: string, layerId: string, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string>"
    books-layers-annotation-data-list: "record<items: table<annotationType: string, data: record, encodedData: string, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int>"
    books-layers-annotation-data-get: "record<annotationType: string, data: record<common: record<title: string>, dict: record<source: record, words: list>, kind: string>, encodedData: string, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeId: string>"
    books-layers-list: "record<items: table<annotationCount: int, annotationTypes: list, annotationsDataLink: string, annotationsLink: string, contentVersion: string, dataCount: int, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeAnnotationsVersion: string, volumeId: string>, kind: string, totalItems: int>"
    books-layers-get: "record<annotationCount: int, annotationTypes: list<string>, annotationsDataLink: string, annotationsLink: string, contentVersion: string, dataCount: int, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeAnnotationsVersion: string, volumeId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["books-cloudloading-add-book" "books-cloudloading-delete-book" "books-cloudloading-update-book" "books-dictionary-list-offline-metadata" "books-familysharing-get-family-info" "books-familysharing-share" "books-familysharing-unshare" "books-myconfig-get-user-settings" "books-myconfig-release-download-access" "books-myconfig-request-access" "books-myconfig-sync-volume-licenses" "books-myconfig-update-user-settings" "books-mylibrary-annotations-list" "books-mylibrary-annotations-insert" "books-mylibrary-annotations-summary" "books-mylibrary-annotations-delete" "books-mylibrary-annotations-update" "books-mylibrary-bookshelves-list" "books-mylibrary-bookshelves-get" "books-mylibrary-bookshelves-add-volume" "books-mylibrary-bookshelves-clear-volumes" "books-mylibrary-bookshelves-move-volume" "books-mylibrary-bookshelves-remove-volume" "books-mylibrary-bookshelves-volumes-list" "books-mylibrary-readingpositions-get" "books-mylibrary-readingpositions-set-position" "books-notification-get" "books-onboarding-list-categories" "books-onboarding-list-category-volumes" "books-personalizedstream-get" "books-promooffer-accept" "books-promooffer-dismiss" "books-promooffer-get" "books-series-get" "books-series-membership-get" "books-bookshelves-list" "books-bookshelves-get" "books-bookshelves-volumes-list" "books-volumes-list" "books-volumes-mybooks-list" "books-volumes-recommended-list" "books-volumes-recommended-rate" "books-volumes-useruploaded-list" "books-volumes-get" "books-volumes-associated-list" "books-layers-volume-annotations-list" "books-layers-volume-annotations-get" "books-layers-annotation-data-list" "books-layers-annotation-data-get" "books-layers-list" "books-layers-get" "commands"] | sort) } | get name | first)
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

# Add a user-upload volume and triggers processing.
#
# POST /books/v1/cloudloading/addBook
# Returns: record<author: string, processingState: string, title: string, volumeId: string>
# operationId: books.cloudloading.addBook
export def "books-cloudloading-add-book" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --drive-document-id: string # A drive document id. The upload_client_token must not be set.
  --mime-type: string # The document MIME type. It can be set only if the drive_document_id is set.
  --name: string # The document name. It can be set only if the drive_document_id is set.
  --upload-client-token: string # Scotty upload token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/cloudloading/addBook"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: drive_document_id, var: drive_document_id}, {name: mime_type, var: mime_type}, {name: name, var: name}, {name: upload_client_token, var: upload_client_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, drive_document_id: $drive_document_id, mime_type: $mime_type, name: $name, upload_client_token: $upload_client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the book and its contents
#
# POST /books/v1/cloudloading/deleteBook
# Returns: record
# operationId: books.cloudloading.deleteBook
export def "books-cloudloading-delete-book" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --volume-id: string # The id of the book to be removed. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/cloudloading/deleteBook"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: volumeId, var: volume_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a user-upload volume.
#
# POST /books/v1/cloudloading/updateBook
# Returns: record<author: string, processingState: string, title: string, volumeId: string>
# operationId: books.cloudloading.updateBook
export def "books-cloudloading-update-book" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --author: string
  --processing-state: string
  --title: string
  --volume-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/books/v1/cloudloading/updateBook"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: processingState, var: processing_state}, {name: title, var: title}, {name: volumeId, var: volume_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, author: $author, processing_state: $processing_state, title: $title, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of offline dictionary metadata available
#
# GET /books/v1/dictionary/listOfflineMetadata
# Returns: record<items: table<download_url: string, encrypted_key: string, language: string, size: string, version: string>, kind: string>
# operationId: books.dictionary.listOfflineMetadata
export def "books-dictionary-list-offline-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cpksver: string # The device/version ID from which to request the data. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/dictionary/listOfflineMetadata"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: cpksver, var: cpksver, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cpksver: $cpksver
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information regarding the family that the user is part of.
#
# GET /books/v1/familysharing/getFamilyInfo
# Returns: record<kind: string, membership: record<acquirePermission: string, ageGroup: string, allowedMaturityRating: string, isInFamily: bool, role: string>>
# operationId: books.familysharing.getFamilyInfo
export def "books-familysharing-get-family-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/familysharing/getFamilyInfo"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates sharing of the content with the user's family. Empty response indicates success.
#
# POST /books/v1/familysharing/share
# Returns: record
# operationId: books.familysharing.share
export def "books-familysharing-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --doc-id: string # The docid to share.
  --source: string # String to identify the originator of this request.
  --volume-id: string # The volume to share.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/familysharing/share"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: docId, var: doc_id}, {name: source, var: source}, {name: volumeId, var: volume_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, doc_id: $doc_id, source: $source, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates revoking content that has already been shared with the user's family. Empty response indicates success.
#
# POST /books/v1/familysharing/unshare
# Returns: record
# operationId: books.familysharing.unshare
export def "books-familysharing-unshare" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --doc-id: string # The docid to unshare.
  --source: string # String to identify the originator of this request.
  --volume-id: string # The volume to unshare.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/familysharing/unshare"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: docId, var: doc_id}, {name: source, var: source}, {name: volumeId, var: volume_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, doc_id: $doc_id, source: $source, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the current settings for the user.
#
# GET /books/v1/myconfig/getUserSettings
# Returns: record<kind: string, notesExport: record<folderName: string, isEnabled: bool>, notification: record<matchMyInterests: record<opted_state: string>, moreFromAuthors: record<opted_state: string>, moreFromSeries: record<opted_state: string>, priceDrop: record<opted_state: string>, rewardExpirations: record<opted_state: string>>>
# operationId: books.myconfig.getUserSettings
export def "books-myconfig-get-user-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # Unused. Added only to workaround TEX mandatory request template requirement
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/myconfig/getUserSettings"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Release downloaded content access restriction.
#
# POST /books/v1/myconfig/releaseDownloadAccess
# Returns: record<downloadAccessList: table<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, kind: string>
# operationId: books.myconfig.releaseDownloadAccess
export def "books-myconfig-release-download-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cpksver: string # The device/version ID from which to release the restriction. (required)
  --volume-ids: list<string> # The volume(s) to release restrictions for. (required)
  --locale: string # ISO-639-1, ISO-3166-1 codes for message localization, i.e. en_US.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/myconfig/releaseDownloadAccess"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: cpksver, var: cpksver, required: true}, {name: volumeIds, var: volume_ids, style: multi, required: true}, {name: locale, var: locale}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cpksver: $cpksver, volume_ids: $volume_ids, locale: $locale, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request concurrent and download access restrictions.
#
# POST /books/v1/myconfig/requestAccess
# Returns: record<concurrentAccess: record<deviceAllowed: bool, kind: string, maxConcurrentDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, timeWindowSeconds: int, volumeId: string>, downloadAccess: record<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, kind: string>
# operationId: books.myconfig.requestAccess
export def "books-myconfig-request-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cpksver: string # The device/version ID from which to request the restrictions. (required)
  --nonce: string # The client nonce value. (required)
  --source: string # String to identify the originator of this request. (required)
  --volume-id: string # The volume to request concurrent/download restrictions for. (required)
  --license-types: string@license-types-completer # The type of access license to request. If not specified, the default is BOTH.
  --locale: string # ISO-639-1, ISO-3166-1 codes for message localization, i.e. en_US.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/myconfig/requestAccess"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: cpksver, var: cpksver, required: true}, {name: nonce, var: nonce, required: true}, {name: source, var: source, required: true}, {name: volumeId, var: volume_id, required: true}, {name: licenseTypes, var: license_types}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cpksver: $cpksver, nonce: $nonce, source: $source, volume_id: $volume_id, license_types: $license_types, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request downloaded content access for specified volumes on the My eBooks shelf.
#
# POST /books/v1/myconfig/syncVolumeLicenses
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.myconfig.syncVolumeLicenses
export def "books-myconfig-sync-volume-licenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cpksver: string # The device/version ID from which to release the restriction. (required)
  --nonce: string # The client nonce value. (required)
  --source: string # String to identify the originator of this request. (required)
  --features: list<string> # List of features supported by the client, i.e., 'RENTALS'
  --include-non-comics-series: oneof<nothing, bool> # Set to true to include non-comics series. Defaults to false.
  --locale: string # ISO-639-1, ISO-3166-1 codes for message localization, i.e. en_US.
  --show-preorders: oneof<nothing, bool> # Set to true to show pre-ordered books. Defaults to false.
  --volume-ids: list<string> # The volume(s) to request download restrictions for.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/myconfig/syncVolumeLicenses"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: cpksver, var: cpksver, required: true}, {name: nonce, var: nonce, required: true}, {name: source, var: source, required: true}, {name: features, var: features, style: multi}, {name: includeNonComicsSeries, var: include_non_comics_series}, {name: locale, var: locale}, {name: showPreorders, var: show_preorders}, {name: volumeIds, var: volume_ids, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cpksver: $cpksver, nonce: $nonce, source: $source, features: $features, include_non_comics_series: $include_non_comics_series, locale: $locale, show_preorders: $show_preorders, volume_ids: $volume_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the settings for the user. If a sub-object is specified, it will overwrite the existing sub-object stored in the server. Unspecified sub-objects will retain the existing value.
#
# POST /books/v1/myconfig/updateUserSettings
# Returns: record<kind: string, notesExport: record<folderName: string, isEnabled: bool>, notification: record<matchMyInterests: record<opted_state: string>, moreFromAuthors: record<opted_state: string>, moreFromSeries: record<opted_state: string>, priceDrop: record<opted_state: string>, rewardExpirations: record<opted_state: string>>>
# operationId: books.myconfig.updateUserSettings
export def "books-myconfig-update-user-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --kind: string # Resource type.
  --notes-export: record # User settings in sub-objects, each for different purposes. — shape: {folderName?: string, isEnabled?: bool}
  --notification: record # shape: {matchMyInterests?: record, moreFromAuthors?: record, moreFromSeries?: record, priceDrop?: record, rewardExpirations?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/books/v1/myconfig/updateUserSettings"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: kind, var: kind}, {name: notesExport, var: notes_export}, {name: notification, var: notification}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, kind: $kind, notes_export: $notes_export, notification: $notification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of annotations, possibly filtered.
#
# GET /books/v1/mylibrary/annotations
# Returns: record<items: table<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record, created: string, currentVersionRanges: record, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record, pageIds: list, selectedText: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int>
# operationId: books.mylibrary.annotations.list
export def "books-mylibrary-annotations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-version: string # The content version for the requested volume.
  --layer-id: string # The layer ID to limit annotation by.
  --layer-ids: list<string> # The layer ID(s) to limit annotation by.
  --max-results: int # Maximum number of results to return
  --page-token: string # The value of the nextToken from the previous page.
  --show-deleted: oneof<nothing, bool> # Set to true to return deleted annotations. updatedMin must be in the request to use this. Defaults to false.
  --source: string # String to identify the originator of this request.
  --updated-max: string # RFC 3339 timestamp to restrict to items updated prior to this timestamp (exclusive).
  --updated-min: string # RFC 3339 timestamp to restrict to items updated since this timestamp (inclusive).
  --volume-id: string # The volume to restrict annotations to.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/mylibrary/annotations"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: contentVersion, var: content_version}, {name: layerId, var: layer_id}, {name: layerIds, var: layer_ids, style: multi}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}, {name: source, var: source}, {name: updatedMax, var: updated_max}, {name: updatedMin, var: updated_min}, {name: volumeId, var: volume_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_version: $content_version, layer_id: $layer_id, layer_ids: $layer_ids, max_results: $max_results, page_token: $page_token, show_deleted: $show_deleted, source: $source, updated_max: $updated_max, updated_min: $updated_min, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new annotation.
#
# POST /books/v1/mylibrary/annotations
# Returns: record<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, created: string, currentVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int>, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string>
# operationId: books.mylibrary.annotations.insert
export def "books-mylibrary-annotations-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --annotation-id: string # The ID for the annotation to insert.
  --country: string # ISO-3166-1 code to override the IP-based location.
  --show-only-summary-in-response: oneof<nothing, bool> # Requests that only the summary of the specified layer be provided in the response.
  --source: string # String to identify the originator of this request.
  --after-selected-text: string # Anchor text after excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --before-selected-text: string # Anchor text before excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --client-version-ranges: record # Selection ranges sent from the client. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --created: string # Timestamp for the created time of this annotation.
  --current-version-ranges: record # Selection ranges for the most recent content version. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --data: string # User-created data for this annotation.
  --deleted: oneof<nothing, bool> # Indicates that this annotation is deleted.
  --highlight-style: string # The highlight style for this annotation.
  --id: string # Id of this annotation, in the form of a GUID.
  --kind: string # Resource type.
  --layer-id: string # The layer this annotation is for.
  --layer-summary: record # shape: {allowedCharacterCount?: int, limitType?: string, remainingCharacterCount?: int}
  --page-ids: list<string> # Pages that this annotation spans.
  --selected-text: string # Excerpt from the volume.
  --self-link: string # URL to this resource.
  --updated: string # Timestamp for the last time this annotation was modified.
  --volume-id: string # The volume that this annotation belongs to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/books/v1/mylibrary/annotations"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: annotationId, var: annotation_id}, {name: country, var: country}, {name: showOnlySummaryInResponse, var: show_only_summary_in_response}, {name: source, var: source}]
    body: {content_type: "application/json", kind: json, fields: [{name: afterSelectedText, var: after_selected_text}, {name: beforeSelectedText, var: before_selected_text}, {name: clientVersionRanges, var: client_version_ranges}, {name: created, var: created}, {name: currentVersionRanges, var: current_version_ranges}, {name: data, var: data}, {name: deleted, var: deleted}, {name: highlightStyle, var: highlight_style}, {name: id, var: id}, {name: kind, var: kind}, {name: layerId, var: layer_id}, {name: layerSummary, var: layer_summary}, {name: pageIds, var: page_ids}, {name: selectedText, var: selected_text}, {name: selfLink, var: self_link}, {name: updated, var: updated}, {name: volumeId, var: volume_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, annotation_id: $annotation_id, country: $country, show_only_summary_in_response: $show_only_summary_in_response, source: $source, after_selected_text: $after_selected_text, before_selected_text: $before_selected_text, client_version_ranges: $client_version_ranges, created: $created, current_version_ranges: $current_version_ranges, data: $data, deleted: $deleted, highlight_style: $highlight_style, id: $id, kind: $kind, layer_id: $layer_id, layer_summary: $layer_summary, page_ids: $page_ids, selected_text: $selected_text, self_link: $self_link, updated: $updated, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the summary of specified layers.
#
# POST /books/v1/mylibrary/annotations/summary
# Returns: record<kind: string, layers: table<allowedCharacterCount: int, layerId: string, limitType: string, remainingCharacterCount: int, updated: string>>
# operationId: books.mylibrary.annotations.summary
export def "books-mylibrary-annotations-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --layer-ids: list<string> # Array of layer IDs to get the summary for. (required)
  --volume-id: string # Volume id to get the summary for. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/mylibrary/annotations/summary"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: layerIds, var: layer_ids, style: multi, required: true}, {name: volumeId, var: volume_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, layer_ids: $layer_ids, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an annotation.
#
# DELETE /books/v1/mylibrary/annotations/{annotationId}
# Returns: record
# operationId: books.mylibrary.annotations.delete
export def "books-mylibrary-annotations-delete" [
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/books/v1/mylibrary/annotations/{annotationId}"
    path_params: [{name: annotationId, var: annotation_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    annotation_id: $annotation_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing annotation.
#
# PUT /books/v1/mylibrary/annotations/{annotationId}
# Returns: record<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, created: string, currentVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int>, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string>
# operationId: books.mylibrary.annotations.update
export def "books-mylibrary-annotations-update" [
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
  --after-selected-text: string # Anchor text after excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --before-selected-text: string # Anchor text before excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --client-version-ranges: record # Selection ranges sent from the client. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --created: string # Timestamp for the created time of this annotation.
  --current-version-ranges: record # Selection ranges for the most recent content version. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --data: string # User-created data for this annotation.
  --deleted: oneof<nothing, bool> # Indicates that this annotation is deleted.
  --highlight-style: string # The highlight style for this annotation.
  --id: string # Id of this annotation, in the form of a GUID.
  --kind: string # Resource type.
  --layer-id: string # The layer this annotation is for.
  --layer-summary: record # shape: {allowedCharacterCount?: int, limitType?: string, remainingCharacterCount?: int}
  --page-ids: list<string> # Pages that this annotation spans.
  --selected-text: string # Excerpt from the volume.
  --self-link: string # URL to this resource.
  --updated: string # Timestamp for the last time this annotation was modified.
  --volume-id: string # The volume that this annotation belongs to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/books/v1/mylibrary/annotations/{annotationId}"
    path_params: [{name: annotationId, var: annotation_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    body: {content_type: "application/json", kind: json, fields: [{name: afterSelectedText, var: after_selected_text}, {name: beforeSelectedText, var: before_selected_text}, {name: clientVersionRanges, var: client_version_ranges}, {name: created, var: created}, {name: currentVersionRanges, var: current_version_ranges}, {name: data, var: data}, {name: deleted, var: deleted}, {name: highlightStyle, var: highlight_style}, {name: id, var: id}, {name: kind, var: kind}, {name: layerId, var: layer_id}, {name: layerSummary, var: layer_summary}, {name: pageIds, var: page_ids}, {name: selectedText, var: selected_text}, {name: selfLink, var: self_link}, {name: updated, var: updated}, {name: volumeId, var: volume_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    annotation_id: $annotation_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source, after_selected_text: $after_selected_text, before_selected_text: $before_selected_text, client_version_ranges: $client_version_ranges, created: $created, current_version_ranges: $current_version_ranges, data: $data, deleted: $deleted, highlight_style: $highlight_style, id: $id, kind: $kind, layer_id: $layer_id, layer_summary: $layer_summary, page_ids: $page_ids, selected_text: $selected_text, self_link: $self_link, updated: $updated, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of bookshelves belonging to the authenticated user.
#
# GET /books/v1/mylibrary/bookshelves
# Returns: record<items: table<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>, kind: string>
# operationId: books.mylibrary.bookshelves.list
export def "books-mylibrary-bookshelves-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/mylibrary/bookshelves"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for a specific bookshelf belonging to the authenticated user.
#
# GET /books/v1/mylibrary/bookshelves/{shelf}
# Returns: record<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>
# operationId: books.mylibrary.bookshelves.get
export def "books-mylibrary-bookshelves-get" [
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/mylibrary/bookshelves/{shelf}"
    path_params: [{name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a volume to a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/addVolume
# Returns: record
# operationId: books.mylibrary.bookshelves.addVolume
export def "books-mylibrary-bookshelves-add-volume" [
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --volume-id: string # ID of volume to add. (required)
  --reason: string@reason-completer # The reason for which the book is added to the library.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/mylibrary/bookshelves/{shelf}/addVolume"
    path_params: [{name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: volumeId, var: volume_id, required: true}, {name: reason, var: reason}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, volume_id: $volume_id, reason: $reason, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears all volumes from a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/clearVolumes
# Returns: record
# operationId: books.mylibrary.bookshelves.clearVolumes
export def "books-mylibrary-bookshelves-clear-volumes" [
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/mylibrary/bookshelves/{shelf}/clearVolumes"
    path_params: [{name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves a volume within a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/moveVolume
# Returns: record
# operationId: books.mylibrary.bookshelves.moveVolume
export def "books-mylibrary-bookshelves-move-volume" [
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --volume-id: string # ID of volume to move. (required)
  --volume-position: int # Position on shelf to move the item (0 puts the item before the current first item, 1 puts it between the first and the second and so on.) (required)
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/mylibrary/bookshelves/{shelf}/moveVolume"
    path_params: [{name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: volumeId, var: volume_id, required: true}, {name: volumePosition, var: volume_position, required: true}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, volume_id: $volume_id, volume_position: $volume_position, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a volume from a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/removeVolume
# Returns: record
# operationId: books.mylibrary.bookshelves.removeVolume
export def "books-mylibrary-bookshelves-remove-volume" [
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --volume-id: string # ID of volume to remove. (required)
  --reason: string@reason-completer-1 # The reason for which the book is removed from the library.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/mylibrary/bookshelves/{shelf}/removeVolume"
    path_params: [{name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: volumeId, var: volume_id, required: true}, {name: reason, var: reason}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, volume_id: $volume_id, reason: $reason, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets volume information for volumes on a bookshelf.
#
# GET /books/v1/mylibrary/bookshelves/{shelf}/volumes
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.mylibrary.bookshelves.volumes.list
export def "books-mylibrary-bookshelves-volumes-list" [
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # ISO-3166-1 code to override the IP-based location.
  --max-results: int # Maximum number of results to return
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --q: string # Full-text search query string in this bookshelf.
  --show-preorders: oneof<nothing, bool> # Set to true to show pre-ordered books. Defaults to false.
  --source: string # String to identify the originator of this request.
  --start-index: int # Index of the first element to return (starts at 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/mylibrary/bookshelves/{shelf}/volumes"
    path_params: [{name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country}, {name: maxResults, var: max_results}, {name: projection, var: projection}, {name: q, var: q}, {name: showPreorders, var: show_preorders}, {name: source, var: source}, {name: startIndex, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, max_results: $max_results, projection: $projection, q: $q, show_preorders: $show_preorders, source: $source, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves my reading position information for a volume.
#
# GET /books/v1/mylibrary/readingpositions/{volumeId}
# Returns: record<epubCfiPosition: string, gbImagePosition: string, gbTextPosition: string, kind: string, pdfPosition: string, updated: string, volumeId: string>
# operationId: books.mylibrary.readingpositions.get
export def "books-mylibrary-readingpositions-get" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-version: string # Volume content version for which this reading position is requested.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/mylibrary/readingpositions/{volumeId}"
    path_params: [{name: volumeId, var: volume_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: contentVersion, var: content_version}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_version: $content_version, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets my reading position information for a volume.
#
# POST /books/v1/mylibrary/readingpositions/{volumeId}/setPosition
# Returns: record
# operationId: books.mylibrary.readingpositions.setPosition
export def "books-mylibrary-readingpositions-set-position" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --position: string # Position string for the new volume reading position. (required)
  --timestamp: string # RFC 3339 UTC format timestamp associated with this reading position. (required)
  --action: string@action-completer # Action that caused this reading position to be set.
  --content-version: string # Volume content version for which this reading position applies.
  --device-cookie: string # Random persistent device cookie optional on set position.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/mylibrary/readingpositions/{volumeId}/setPosition"
    path_params: [{name: volumeId, var: volume_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: position, var: position, required: true}, {name: timestamp, var: timestamp, required: true}, {name: action, var: action}, {name: contentVersion, var: content_version}, {name: deviceCookie, var: device_cookie}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, position: $position, timestamp: $timestamp, action: $action, content_version: $content_version, device_cookie: $device_cookie, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns notification details for a given notification id.
#
# GET /books/v1/notification/get
# Returns: record<body: string, crmExperimentIds: list<string>, doc_id: string, doc_type: string, dont_show_notification: bool, iconUrl: string, is_document_mature: bool, kind: string, notificationGroup: string, notification_type: string, pcampaign_id: string, reason: string, show_notification_settings_action: bool, targetUrl: string, timeToExpireMs: string, title: string>
# operationId: books.notification.get
export def "books-notification-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --notification-id: string # String to identify the notification. (required)
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating notification title and body.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/notification/get"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: notification_id, var: notification_id, required: true}, {name: locale, var: locale}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, notification_id: $notification_id, locale: $locale, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List categories for onboarding experience.
#
# GET /books/v1/onboarding/listCategories
# Returns: record<items: table<badgeUrl: string, categoryId: string, name: string>, kind: string>
# operationId: books.onboarding.listCategories
export def "books-onboarding-list-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Default is en-US if unset.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/onboarding/listCategories"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available volumes under categories for onboarding experience.
#
# GET /books/v1/onboarding/listCategoryVolumes
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, nextPageToken: string>
# operationId: books.onboarding.listCategoryVolumes
export def "books-onboarding-list-category-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --category-id: list<string> # List of category ids requested.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Default is en-US if unset.
  --max-allowed-maturity-rating: string@max-allowed-maturity-rating-completer # The maximum allowed maturity rating of returned volumes. Books with a higher maturity rating are filtered out.
  --page-size: int # Number of maximum results per page to be included in the response.
  --page-token: string # The value of the nextToken from the previous page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/onboarding/listCategoryVolumes"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: categoryId, var: category_id, style: multi}, {name: locale, var: locale}, {name: maxAllowedMaturityRating, var: max_allowed_maturity_rating}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, category_id: $category_id, locale: $locale, max_allowed_maturity_rating: $max_allowed_maturity_rating, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a stream of personalized book clusters
#
# GET /books/v1/personalizedstream/get
# Returns: record<clusters: table<banner_with_content_container: record, subTitle: string, title: string, totalVolumes: int, uid: string, volumes: list>, kind: string, totalClusters: int>
# operationId: books.personalizedstream.get
export def "books-personalizedstream-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --max-allowed-maturity-rating: string@max-allowed-maturity-rating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/personalizedstream/get"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: locale, var: locale}, {name: maxAllowedMaturityRating, var: max_allowed_maturity_rating}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, locale: $locale, max_allowed_maturity_rating: $max_allowed_maturity_rating, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts the promo offer.
#
# POST /books/v1/promooffer/accept
# Returns: record
# operationId: books.promooffer.accept
export def "books-promooffer-accept" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --android-id: string # device android_id
  --device: string # device device
  --manufacturer: string # device manufacturer
  --model: string # device model
  --offer-id: string
  --product: string # device product
  --serial: string # device serial
  --volume-id: string # Volume id to exercise the offer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/promooffer/accept"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: androidId, var: android_id}, {name: device, var: device}, {name: manufacturer, var: manufacturer}, {name: model, var: model}, {name: offerId, var: offer_id}, {name: product, var: product}, {name: serial, var: serial}, {name: volumeId, var: volume_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, android_id: $android_id, device: $device, manufacturer: $manufacturer, model: $model, offer_id: $offer_id, product: $product, serial: $serial, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks the promo offer as dismissed.
#
# POST /books/v1/promooffer/dismiss
# Returns: record
# operationId: books.promooffer.dismiss
export def "books-promooffer-dismiss" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --android-id: string # device android_id
  --device: string # device device
  --manufacturer: string # device manufacturer
  --model: string # device model
  --offer-id: string # Offer to dimiss
  --product: string # device product
  --serial: string # device serial
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/promooffer/dismiss"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: androidId, var: android_id}, {name: device, var: device}, {name: manufacturer, var: manufacturer}, {name: model, var: model}, {name: offerId, var: offer_id}, {name: product, var: product}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, android_id: $android_id, device: $device, manufacturer: $manufacturer, model: $model, offer_id: $offer_id, product: $product, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of promo offers available to the user
#
# GET /books/v1/promooffer/get
# Returns: record<items: table<artUrl: string, gservicesKey: string, id: string, items: list>, kind: string>
# operationId: books.promooffer.get
export def "books-promooffer-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --android-id: string # device android_id
  --device: string # device device
  --manufacturer: string # device manufacturer
  --model: string # device model
  --product: string # device product
  --serial: string # device serial
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/promooffer/get"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: androidId, var: android_id}, {name: device, var: device}, {name: manufacturer, var: manufacturer}, {name: model, var: model}, {name: product, var: product}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, android_id: $android_id, device: $device, manufacturer: $manufacturer, model: $model, product: $product, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Series metadata for the given series ids.
#
# GET /books/v1/series/get
# Returns: record<kind: string, series: table<bannerImageUrl: string, eligibleForSubscription: bool, imageUrl: string, isComplete: bool, seriesFormatType: string, seriesId: string, seriesSubscriptionReleaseInfo: record, seriesType: string, subscriptionId: string, title: string>>
# operationId: books.series.get
export def "books-series-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --series-id: list<string> # String that identifies the series (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/series/get"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: series_id, var: series_id, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, series_id: $series_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns Series membership data given the series id.
#
# GET /books/v1/series/membership/get
# Returns: record<kind: string, member: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, nextPageToken: string>
# operationId: books.series.membership.get
export def "books-series-membership-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --series-id: string # String that identifies the series (required)
  --page-size: int # Number of maximum results per page to be included in the response.
  --page-token: string # The value of the nextToken from the previous page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/series/membership/get"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: series_id, var: series_id, required: true}, {name: page_size, var: page_size}, {name: page_token, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, series_id: $series_id, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of public bookshelves for the specified user.
#
# GET /books/v1/users/{userId}/bookshelves
# Returns: record<items: table<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>, kind: string>
# operationId: books.bookshelves.list
export def "books-bookshelves-list" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/users/{userId}/bookshelves"
    path_params: [{name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves metadata for a specific bookshelf for the specified user.
#
# GET /books/v1/users/{userId}/bookshelves/{shelf}
# Returns: record<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>
# operationId: books.bookshelves.get
export def "books-bookshelves-get" [
  user_id: string
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/users/{userId}/bookshelves/{shelf}"
    path_params: [{name: userId, var: user_id}, {name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves volumes in a specific bookshelf for the specified user.
#
# GET /books/v1/users/{userId}/bookshelves/{shelf}/volumes
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.bookshelves.volumes.list
export def "books-bookshelves-volumes-list" [
  user_id: string
  shelf: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Maximum number of results to return
  --show-preorders: oneof<nothing, bool> # Set to true to show pre-ordered books. Defaults to false.
  --source: string # String to identify the originator of this request.
  --start-index: int # Index of the first element to return (starts at 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/users/{userId}/bookshelves/{shelf}/volumes"
    path_params: [{name: userId, var: user_id}, {name: shelf, var: shelf}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: showPreorders, var: show_preorders}, {name: source, var: source}, {name: startIndex, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, shelf: $shelf, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, show_preorders: $show_preorders, source: $source, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a book search.
#
# GET /books/v1/volumes
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.volumes.list
export def "books-volumes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --q: string # Full-text search query string. (required)
  --download: string@download-completer # Restrict to volumes by download availability.
  --filter: string@filter-completer # Filter search results.
  --lang-restrict: string # Restrict results to books with this language code.
  --library-restrict: string@library-restrict-completer # Restrict search to this user's library.
  --max-allowed-maturity-rating: string@max-allowed-maturity-rating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --max-results: int # Maximum number of results to return.
  --order-by: string@order-by-completer # Sort search results.
  --partner: string # Restrict and brand results for partner ID.
  --print-type: string@print-type-completer # Restrict to books or magazines.
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --show-preorders: oneof<nothing, bool> # Set to true to show books available for preorder. Defaults to false.
  --source: string # String to identify the originator of this request.
  --start-index: int # Index of the first result to return (starts at 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: q, var: q, required: true}, {name: download, var: download}, {name: filter, var: filter}, {name: langRestrict, var: lang_restrict}, {name: libraryRestrict, var: library_restrict}, {name: maxAllowedMaturityRating, var: max_allowed_maturity_rating}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: partner, var: partner}, {name: printType, var: print_type}, {name: projection, var: projection}, {name: showPreorders, var: show_preorders}, {name: source, var: source}, {name: startIndex, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, q: $q, download: $download, filter: $filter, lang_restrict: $lang_restrict, library_restrict: $library_restrict, max_allowed_maturity_rating: $max_allowed_maturity_rating, max_results: $max_results, order_by: $order_by, partner: $partner, print_type: $print_type, projection: $projection, show_preorders: $show_preorders, source: $source, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of books in My Library.
#
# GET /books/v1/volumes/mybooks
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.volumes.mybooks.list
export def "books-volumes-mybooks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --acquire-method: list<string> # How the book was acquired
  --country: string # ISO-3166-1 code to override the IP-based location.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex:'en_US'. Used for generating recommendations.
  --max-results: int # Maximum number of results to return.
  --processing-state: list<string> # The processing state of the user uploaded volumes to be returned. Applicable only if the UPLOADED is specified in the acquireMethod.
  --source: string # String to identify the originator of this request.
  --start-index: int # Index of the first result to return (starts at 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/mybooks"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: acquireMethod, var: acquire_method, style: multi}, {name: country, var: country}, {name: locale, var: locale}, {name: maxResults, var: max_results}, {name: processingState, var: processing_state, style: multi}, {name: source, var: source}, {name: startIndex, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, acquire_method: $acquire_method, country: $country, locale: $locale, max_results: $max_results, processing_state: $processing_state, source: $source, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of recommended books for the current user.
#
# GET /books/v1/volumes/recommended
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.volumes.recommended.list
export def "books-volumes-recommended-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --max-allowed-maturity-rating: string@max-allowed-maturity-rating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/recommended"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: locale, var: locale}, {name: maxAllowedMaturityRating, var: max_allowed_maturity_rating}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, locale: $locale, max_allowed_maturity_rating: $max_allowed_maturity_rating, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rate a recommended book for the current user.
#
# POST /books/v1/volumes/recommended/rate
# Returns: record<consistency_token: string>
# operationId: books.volumes.recommended.rate
export def "books-volumes-recommended-rate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --rating: string@rating-completer # Rating to be given to the volume. (required)
  --volume-id: string # ID of the source volume. (required)
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/books/v1/volumes/recommended/rate"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: rating, var: rating, required: true}, {name: volumeId, var: volume_id, required: true}, {name: locale, var: locale}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, rating: $rating, volume_id: $volume_id, locale: $locale, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of books uploaded by the current user.
#
# GET /books/v1/volumes/useruploaded
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.volumes.useruploaded.list
export def "books-volumes-useruploaded-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --max-results: int # Maximum number of results to return.
  --processing-state: list<string> # The processing state of the user uploaded volumes to be returned.
  --source: string # String to identify the originator of this request.
  --start-index: int # Index of the first result to return (starts at 0)
  --volume-id: list<string> # The ids of the volumes to be returned. If not specified all that match the processingState are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/useruploaded"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: locale, var: locale}, {name: maxResults, var: max_results}, {name: processingState, var: processing_state, style: multi}, {name: source, var: source}, {name: startIndex, var: start_index}, {name: volumeId, var: volume_id, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, locale: $locale, max_results: $max_results, processing_state: $processing_state, source: $source, start_index: $start_index, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets volume information for a single volume.
#
# GET /books/v1/volumes/{volumeId}
# Returns: record<accessInfo: record<accessViewStatus: string, country: string, downloadAccess: record<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, driveImportedContentLink: string, embeddable: bool, epub: record<acsTokenLink: string, downloadLink: string, isAvailable: bool>, explicitOfflineLicenseManagement: bool, pdf: record<acsTokenLink: string, downloadLink: string, isAvailable: bool>, publicDomain: bool, quoteSharingAllowed: bool, textToSpeechPermission: string, viewOrderUrl: string, viewability: string, webReaderLink: string>, etag: string, id: string, kind: string, layerInfo: record<layers: list<record>>, recommendedInfo: record<explanation: string>, saleInfo: record<buyLink: string, country: string, isEbook: bool, listPrice: record<amount: float, currencyCode: string>, offers: list<record>, onSaleDate: string, retailPrice: record<amount: float, currencyCode: string>, saleability: string>, searchInfo: record<textSnippet: string>, selfLink: string, userInfo: record<acquiredTime: string, acquisitionType: int, copy: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int, updated: string>, entitlementType: int, familySharing: record<familyRole: string, isSharingAllowed: bool, isSharingDisabledByFop: bool>, isFamilySharedFromUser: bool, isFamilySharedToUser: bool, isFamilySharingAllowed: bool, isFamilySharingDisabledByFop: bool, isInMyBooks: bool, isPreordered: bool, isPurchased: bool, isUploaded: bool, readingPosition: record<epubCfiPosition: string, gbImagePosition: string, gbTextPosition: string, kind: string, pdfPosition: string, updated: string, volumeId: string>, rentalPeriod: record<endUtcSec: string, startUtcSec: string>, rentalState: string, review: record<author: record, content: string, date: string, fullTextUrl: string, kind: string, rating: string, source: record, title: string, type: string, volumeId: string>, updated: string, userUploadedVolumeInfo: record<processingState: string>>, volumeInfo: record<allowAnonLogging: bool, authors: list<string>, averageRating: float, canonicalVolumeLink: string, categories: list<string>, comicsContent: bool, contentVersion: string, description: string, dimensions: record<height: string, thickness: string, width: string>, imageLinks: record<extraLarge: string, large: string, medium: string, small: string, smallThumbnail: string, thumbnail: string>, industryIdentifiers: list<record>, infoLink: string, language: string, mainCategory: string, maturityRating: string, pageCount: int, panelizationSummary: record<containsEpubBubbles: bool, containsImageBubbles: bool, epubBubbleVersion: string, imageBubbleVersion: string>, previewLink: string, printType: string, printedPageCount: int, publishedDate: string, publisher: string, ratingsCount: int, readingModes: record<image: bool, text: bool>, samplePageCount: int, seriesInfo: record<bookDisplayNumber: string, kind: string, shortSeriesBookTitle: string, volumeSeries: list>, subtitle: string, title: string>>
# operationId: books.volumes.get
export def "books-volumes-get" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --country: string # ISO-3166-1 code to override the IP-based location.
  --include-non-comics-series: oneof<nothing, bool> # Set to true to include non-comics series. Defaults to false.
  --partner: string # Brand results for partner ID.
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --source: string # string to identify the originator of this request.
  --user-library-consistent-read: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}"
    path_params: [{name: volumeId, var: volume_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: country, var: country}, {name: includeNonComicsSeries, var: include_non_comics_series}, {name: partner, var: partner}, {name: projection, var: projection}, {name: source, var: source}, {name: user_library_consistent_read, var: user_library_consistent_read}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, country: $country, include_non_comics_series: $include_non_comics_series, partner: $partner, projection: $projection, source: $source, user_library_consistent_read: $user_library_consistent_read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of associated books.
#
# GET /books/v1/volumes/{volumeId}/associated
# Returns: record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int>
# operationId: books.volumes.associated.list
export def "books-volumes-associated-list" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --association: string@association-completer # Association type.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --max-allowed-maturity-rating: string@max-allowed-maturity-rating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}/associated"
    path_params: [{name: volumeId, var: volume_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: association, var: association}, {name: locale, var: locale}, {name: maxAllowedMaturityRating, var: max_allowed_maturity_rating}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, association: $association, locale: $locale, max_allowed_maturity_rating: $max_allowed_maturity_rating, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the volume annotations for a volume and layer.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}
# Returns: record<items: table<annotationDataId: string, annotationDataLink: string, annotationType: string, contentRanges: record, data: string, deleted: bool, id: string, kind: string, layerId: string, pageIds: list, selectedText: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int, version: string>
# operationId: books.layers.volumeAnnotations.list
export def "books-layers-volume-annotations-list" [
  volume_id: string
  layer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-version: string # The content version for the requested volume. (required)
  --end-offset: string # The end offset to end retrieving data from.
  --end-position: string # The end position to end retrieving data from.
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --max-results: int # Maximum number of results to return
  --page-token: string # The value of the nextToken from the previous page.
  --show-deleted: oneof<nothing, bool> # Set to true to return deleted annotations. updatedMin must be in the request to use this. Defaults to false.
  --source: string # String to identify the originator of this request.
  --start-offset: string # The start offset to start retrieving data from.
  --start-position: string # The start position to start retrieving data from.
  --updated-max: string # RFC 3339 timestamp to restrict to items updated prior to this timestamp (exclusive).
  --updated-min: string # RFC 3339 timestamp to restrict to items updated since this timestamp (inclusive).
  --volume-annotations-version: string # The version of the volume annotations that you are requesting.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}/layers/{layerId}"
    path_params: [{name: volumeId, var: volume_id}, {name: layerId, var: layer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: contentVersion, var: content_version, required: true}, {name: endOffset, var: end_offset}, {name: endPosition, var: end_position}, {name: locale, var: locale}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}, {name: source, var: source}, {name: startOffset, var: start_offset}, {name: startPosition, var: start_position}, {name: updatedMax, var: updated_max}, {name: updatedMin, var: updated_min}, {name: volumeAnnotationsVersion, var: volume_annotations_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, layer_id: $layer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_version: $content_version, end_offset: $end_offset, end_position: $end_position, locale: $locale, max_results: $max_results, page_token: $page_token, show_deleted: $show_deleted, source: $source, start_offset: $start_offset, start_position: $start_position, updated_max: $updated_max, updated_min: $updated_min, volume_annotations_version: $volume_annotations_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the volume annotation.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}/annotations/{annotationId}
# Returns: record<annotationDataId: string, annotationDataLink: string, annotationType: string, contentRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, id: string, kind: string, layerId: string, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string>
# operationId: books.layers.volumeAnnotations.get
export def "books-layers-volume-annotations-get" [
  volume_id: string
  layer_id: string
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}/layers/{layerId}/annotations/{annotationId}"
    path_params: [{name: volumeId, var: volume_id}, {name: layerId, var: layer_id}, {name: annotationId, var: annotation_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: locale, var: locale}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, layer_id: $layer_id, annotation_id: $annotation_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, locale: $locale, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the annotation data for a volume and layer.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}/data
# Returns: record<items: table<annotationType: string, data: record, encodedData: string, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int>
# operationId: books.layers.annotationData.list
export def "books-layers-annotation-data-list" [
  volume_id: string
  layer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-version: string # The content version for the requested volume. (required)
  --annotation-data-id: list<string> # The list of Annotation Data Ids to retrieve. Pagination is ignored if this is set.
  --h: int # The requested pixel height for any images. If height is provided width must also be provided.
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --max-results: int # Maximum number of results to return
  --page-token: string # The value of the nextToken from the previous page.
  --scale: int # The requested scale for the image.
  --source: string # String to identify the originator of this request.
  --updated-max: string # RFC 3339 timestamp to restrict to items updated prior to this timestamp (exclusive).
  --updated-min: string # RFC 3339 timestamp to restrict to items updated since this timestamp (inclusive).
  --w: int # The requested pixel width for any images. If width is provided height must also be provided.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}/layers/{layerId}/data"
    path_params: [{name: volumeId, var: volume_id}, {name: layerId, var: layer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: contentVersion, var: content_version, required: true}, {name: annotationDataId, var: annotation_data_id, style: multi}, {name: h, var: h}, {name: locale, var: locale}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: scale, var: scale}, {name: source, var: source}, {name: updatedMax, var: updated_max}, {name: updatedMin, var: updated_min}, {name: w, var: w}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, layer_id: $layer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_version: $content_version, annotation_data_id: $annotation_data_id, h: $h, locale: $locale, max_results: $max_results, page_token: $page_token, scale: $scale, source: $source, updated_max: $updated_max, updated_min: $updated_min, w: $w
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the annotation data.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}/data/{annotationDataId}
# Returns: record<annotationType: string, data: record<common: record<title: string>, dict: record<source: record, words: list>, kind: string>, encodedData: string, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeId: string>
# operationId: books.layers.annotationData.get
export def "books-layers-annotation-data-get" [
  volume_id: string
  layer_id: string
  annotation_data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-version: string # The content version for the volume you are trying to retrieve. (required)
  --allow-web-definitions: oneof<nothing, bool> # For the dictionary layer. Whether or not to allow web definitions.
  --h: int # The requested pixel height for any images. If height is provided width must also be provided.
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --scale: int # The requested scale for the image.
  --source: string # String to identify the originator of this request.
  --w: int # The requested pixel width for any images. If width is provided height must also be provided.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}/layers/{layerId}/data/{annotationDataId}"
    path_params: [{name: volumeId, var: volume_id}, {name: layerId, var: layer_id}, {name: annotationDataId, var: annotation_data_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: contentVersion, var: content_version, required: true}, {name: allowWebDefinitions, var: allow_web_definitions}, {name: h, var: h}, {name: locale, var: locale}, {name: scale, var: scale}, {name: source, var: source}, {name: w, var: w}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, layer_id: $layer_id, annotation_data_id: $annotation_data_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_version: $content_version, allow_web_definitions: $allow_web_definitions, h: $h, locale: $locale, scale: $scale, source: $source, w: $w
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the layer summaries for a volume.
#
# GET /books/v1/volumes/{volumeId}/layersummary
# Returns: record<items: table<annotationCount: int, annotationTypes: list, annotationsDataLink: string, annotationsLink: string, contentVersion: string, dataCount: int, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeAnnotationsVersion: string, volumeId: string>, kind: string, totalItems: int>
# operationId: books.layers.list
export def "books-layers-list" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-version: string # The content version for the requested volume.
  --max-results: int # Maximum number of results to return
  --page-token: string # The value of the nextToken from the previous page.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}/layersummary"
    path_params: [{name: volumeId, var: volume_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: contentVersion, var: content_version}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_version: $content_version, max_results: $max_results, page_token: $page_token, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the layer summary for a volume.
#
# GET /books/v1/volumes/{volumeId}/layersummary/{summaryId}
# Returns: record<annotationCount: int, annotationTypes: list<string>, annotationsDataLink: string, annotationsLink: string, contentVersion: string, dataCount: int, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeAnnotationsVersion: string, volumeId: string>
# operationId: books.layers.get
export def "books-layers-get" [
  volume_id: string
  summary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content-version: string # The content version for the requested volume.
  --source: string # String to identify the originator of this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/books/v1/volumes/{volumeId}/layersummary/{summaryId}"
    path_params: [{name: volumeId, var: volume_id}, {name: summaryId, var: summary_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: contentVersion, var: content_version}, {name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    volume_id: $volume_id, summary_id: $summary_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_version: $content_version, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
