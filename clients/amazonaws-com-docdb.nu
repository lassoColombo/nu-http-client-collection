# Auto-generated client for Amazon DocumentDB with MongoDB compatibility v2014-10-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/docdb/2014-10-31/openapi.json
# Auth: --token flag or $env.AMAZON_DOCUMENTDB_WITH_MONGODB_COMPATIBILITY_TOKEN

const CLIENT = {
  base_url: "http://rds.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_DOCUMENTDB_WITH_MONGODB_COMPATIBILITY_TOKEN"
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

def base-url-completer [] { ["http://rds.us-east-1.amazonaws.com" "http://rds.us-east-2.amazonaws.com" "http://rds.us-west-1.amazonaws.com" "http://rds.us-west-2.amazonaws.com" "http://rds.us-gov-west-1.amazonaws.com" "http://rds.us-gov-east-1.amazonaws.com" "http://rds.ca-central-1.amazonaws.com" "http://rds.eu-north-1.amazonaws.com" "http://rds.eu-west-1.amazonaws.com" "http://rds.eu-west-2.amazonaws.com" "http://rds.eu-west-3.amazonaws.com" "http://rds.eu-central-1.amazonaws.com" "http://rds.eu-south-1.amazonaws.com" "http://rds.af-south-1.amazonaws.com" "http://rds.ap-northeast-1.amazonaws.com" "http://rds.ap-northeast-2.amazonaws.com" "http://rds.ap-northeast-3.amazonaws.com" "http://rds.ap-southeast-1.amazonaws.com" "http://rds.ap-southeast-2.amazonaws.com" "http://rds.ap-east-1.amazonaws.com" "http://rds.ap-south-1.amazonaws.com" "http://rds.sa-east-1.amazonaws.com" "http://rds.me-south-1.amazonaws.com" "https://rds.us-east-1.amazonaws.com" "https://rds.us-east-2.amazonaws.com" "https://rds.us-west-1.amazonaws.com" "https://rds.us-west-2.amazonaws.com" "https://rds.us-gov-west-1.amazonaws.com" "https://rds.us-gov-east-1.amazonaws.com" "https://rds.ca-central-1.amazonaws.com" "https://rds.eu-north-1.amazonaws.com" "https://rds.eu-west-1.amazonaws.com" "https://rds.eu-west-2.amazonaws.com" "https://rds.eu-west-3.amazonaws.com" "https://rds.eu-central-1.amazonaws.com" "https://rds.eu-south-1.amazonaws.com" "https://rds.af-south-1.amazonaws.com" "https://rds.ap-northeast-1.amazonaws.com" "https://rds.ap-northeast-2.amazonaws.com" "https://rds.ap-northeast-3.amazonaws.com" "https://rds.ap-southeast-1.amazonaws.com" "https://rds.ap-southeast-2.amazonaws.com" "https://rds.ap-east-1.amazonaws.com" "https://rds.ap-south-1.amazonaws.com" "https://rds.sa-east-1.amazonaws.com" "https://rds.me-south-1.amazonaws.com" "http://rds.amazonaws.com" "https://rds.amazonaws.com" "http://rds.cn-north-1.amazonaws.com.cn" "http://rds.cn-northwest-1.amazonaws.com.cn" "https://rds.cn-north-1.amazonaws.com.cn" "https://rds.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AddSourceIdentifierToSubscription"] }
def version-completer [] { ["2014-10-31"] }
def action-completer-1 [] { ["AddTagsToResource"] }
def action-completer-2 [] { ["ApplyPendingMaintenanceAction"] }
def action-completer-3 [] { ["CopyDBClusterParameterGroup"] }
def action-completer-4 [] { ["CopyDBClusterSnapshot"] }
def action-completer-5 [] { ["CreateDBCluster"] }
def action-completer-6 [] { ["CreateDBClusterParameterGroup"] }
def action-completer-7 [] { ["CreateDBClusterSnapshot"] }
def action-completer-8 [] { ["CreateDBInstance"] }
def action-completer-9 [] { ["CreateDBSubnetGroup"] }
def action-completer-10 [] { ["CreateEventSubscription"] }
def action-completer-11 [] { ["CreateGlobalCluster"] }
def action-completer-12 [] { ["DeleteDBCluster"] }
def action-completer-13 [] { ["DeleteDBClusterParameterGroup"] }
def action-completer-14 [] { ["DeleteDBClusterSnapshot"] }
def action-completer-15 [] { ["DeleteDBInstance"] }
def action-completer-16 [] { ["DeleteDBSubnetGroup"] }
def action-completer-17 [] { ["DeleteEventSubscription"] }
def action-completer-18 [] { ["DeleteGlobalCluster"] }
def action-completer-19 [] { ["DescribeCertificates"] }
def action-completer-20 [] { ["DescribeDBClusterParameterGroups"] }
def action-completer-21 [] { ["DescribeDBClusterParameters"] }
def action-completer-22 [] { ["DescribeDBClusterSnapshotAttributes"] }
def action-completer-23 [] { ["DescribeDBClusterSnapshots"] }
def action-completer-24 [] { ["DescribeDBClusters"] }
def action-completer-25 [] { ["DescribeDBEngineVersions"] }
def action-completer-26 [] { ["DescribeDBInstances"] }
def action-completer-27 [] { ["DescribeDBSubnetGroups"] }
def action-completer-28 [] { ["DescribeEngineDefaultClusterParameters"] }
def action-completer-29 [] { ["DescribeEventCategories"] }
def action-completer-30 [] { ["DescribeEventSubscriptions"] }
def source-type-completer [] { ["db-cluster" "db-cluster-snapshot" "db-instance" "db-parameter-group" "db-security-group" "db-snapshot"] }
def action-completer-31 [] { ["DescribeEvents"] }
def action-completer-32 [] { ["DescribeGlobalClusters"] }
def action-completer-33 [] { ["DescribeOrderableDBInstanceOptions"] }
def action-completer-34 [] { ["DescribePendingMaintenanceActions"] }
def action-completer-35 [] { ["FailoverDBCluster"] }
def action-completer-36 [] { ["ListTagsForResource"] }
def action-completer-37 [] { ["ModifyDBCluster"] }
def action-completer-38 [] { ["ModifyDBClusterParameterGroup"] }
def action-completer-39 [] { ["ModifyDBClusterSnapshotAttribute"] }
def action-completer-40 [] { ["ModifyDBInstance"] }
def action-completer-41 [] { ["ModifyDBSubnetGroup"] }
def action-completer-42 [] { ["ModifyEventSubscription"] }
def action-completer-43 [] { ["ModifyGlobalCluster"] }
def action-completer-44 [] { ["RebootDBInstance"] }
def action-completer-45 [] { ["RemoveFromGlobalCluster"] }
def action-completer-46 [] { ["RemoveSourceIdentifierFromSubscription"] }
def action-completer-47 [] { ["RemoveTagsFromResource"] }
def action-completer-48 [] { ["ResetDBClusterParameterGroup"] }
def action-completer-49 [] { ["RestoreDBClusterFromSnapshot"] }
def action-completer-50 [] { ["RestoreDBClusterToPointInTime"] }
def action-completer-51 [] { ["StartDBCluster"] }
def action-completer-52 [] { ["StopDBCluster"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-add-source-identifier-to-subscription" "post-add-source-identifier-to-subscription" "get-add-tags-to-resource" "post-add-tags-to-resource" "get-apply-pending-maintenance-action" "post-apply-pending-maintenance-action" "get-copy-db-cluster-parameter-group" "post-copy-db-cluster-parameter-group" "get-copy-db-cluster-snapshot" "post-copy-db-cluster-snapshot" "get-create-db-cluster" "post-create-db-cluster" "get-create-db-cluster-parameter-group" "post-create-db-cluster-parameter-group" "get-create-db-cluster-snapshot" "post-create-db-cluster-snapshot" "get-create-db-instance" "post-create-db-instance" "get-create-db-subnet-group" "post-create-db-subnet-group" "get-create-event-subscription" "post-create-event-subscription" "get-create-global-cluster" "post-create-global-cluster" "get-delete-db-cluster" "post-delete-db-cluster" "get-delete-db-cluster-parameter-group" "post-delete-db-cluster-parameter-group" "get-delete-db-cluster-snapshot" "post-delete-db-cluster-snapshot" "get-delete-db-instance" "post-delete-db-instance" "get-delete-db-subnet-group" "post-delete-db-subnet-group" "get-delete-event-subscription" "post-delete-event-subscription" "get-delete-global-cluster" "post-delete-global-cluster" "get-describe-certificates" "post-describe-certificates" "get-describe-db-cluster-parameter-groups" "post-describe-db-cluster-parameter-groups" "get-describe-db-cluster-parameters" "post-describe-db-cluster-parameters" "get-describe-db-cluster-snapshot-attributes" "post-describe-db-cluster-snapshot-attributes" "get-describe-db-cluster-snapshots" "post-describe-db-cluster-snapshots" "get-describe-db-clusters" "post-describe-db-clusters" "get-describe-db-engine-versions" "post-describe-db-engine-versions" "get-describe-db-instances" "post-describe-db-instances" "get-describe-db-subnet-groups" "post-describe-db-subnet-groups" "get-describe-engine-default-cluster-parameters" "post-describe-engine-default-cluster-parameters" "get-describe-event-categories" "post-describe-event-categories" "get-describe-event-subscriptions" "post-describe-event-subscriptions" "get-describe-events" "post-describe-events" "get-describe-global-clusters" "post-describe-global-clusters" "get-describe-orderable-db-instance-options" "post-describe-orderable-db-instance-options" "get-describe-pending-maintenance-actions" "post-describe-pending-maintenance-actions" "get-failover-db-cluster" "post-failover-db-cluster" "get-list-tags-for-resource" "post-list-tags-for-resource" "get-modify-db-cluster" "post-modify-db-cluster" "get-modify-db-cluster-parameter-group" "post-modify-db-cluster-parameter-group" "get-modify-db-cluster-snapshot-attribute" "post-modify-db-cluster-snapshot-attribute" "get-modify-db-instance" "post-modify-db-instance" "get-modify-db-subnet-group" "post-modify-db-subnet-group" "get-modify-event-subscription" "post-modify-event-subscription" "get-modify-global-cluster" "post-modify-global-cluster" "get-reboot-db-instance" "post-reboot-db-instance" "get-remove-from-global-cluster" "post-remove-from-global-cluster" "get-remove-source-identifier-from-subscription" "post-remove-source-identifier-from-subscription" "get-remove-tags-from-resource" "post-remove-tags-from-resource" "get-reset-db-cluster-parameter-group" "post-reset-db-cluster-parameter-group" "get-restore-db-cluster-from-snapshot" "post-restore-db-cluster-from-snapshot" "get-restore-db-cluster-to-point-in-time" "post-restore-db-cluster-to-point-in-time" "get-start-db-cluster" "post-start-db-cluster" "get-stop-db-cluster" "post-stop-db-cluster" "commands"] | sort) } | get name | first)
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

# Adds a source identifier to an existing event notification subscription.
#
# GET /
# operationId: GET_AddSourceIdentifierToSubscription
export def "get-add-source-identifier-to-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the Amazon DocumentDB event notification subscription that you want to add a source identifier to. (required)
  --source-identifier: string # The identifier of the event source to be added: If the source type is an instance, a DBInstanceIdentifier must be provided. If the source type is a security group, a DBSecurityGroupName must be provided. If the source type is a parameter group, a DBParameterGroupName must be provided. If the source type is a snapshot, a DBSnapshotIdentifier must be provided. (required)
  --action: string@action-completer # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SubscriptionName, var: subscription_name, required: true}, {name: SourceIdentifier, var: source_identifier, required: true}, {name: Action, var: action, required: true, default: AddSourceIdentifierToSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_name: $subscription_name, source_identifier: $source_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a source identifier to an existing event notification subscription.
#
# POST /
# operationId: POST_AddSourceIdentifierToSubscription
export def "post-add-source-identifier-to-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: AddSourceIdentifierToSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources or in a Condition statement in an Identity and Access Management (IAM) policy for Amazon DocumentDB.
#
# GET /
# operationId: GET_AddTagsToResource
export def "get-add-tags-to-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name . (required)
  --tags: list # The tags to be assigned to the Amazon DocumentDB resource. (required)
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: ResourceName, var: resource_name, required: true}, {name: Tags, var: tags, style: multi, required: true}, {name: Action, var: action, required: true, default: AddTagsToResource}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources or in a Condition statement in an Identity and Access Management (IAM) policy for Amazon DocumentDB.
#
# POST /
# operationId: POST_AddTagsToResource
export def "post-add-tags-to-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: AddTagsToResource}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a pending maintenance action to a resource (for example, to an Amazon DocumentDB instance).
#
# GET /
# operationId: GET_ApplyPendingMaintenanceAction
export def "get-apply-pending-maintenance-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-identifier: string # The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to. (required)
  --apply-action: string # The pending maintenance action to apply to this resource. Valid values: system-update, db-upgrade (required)
  --opt-in-type: string # A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type immediate can't be undone. Valid values: immediate - Apply the maintenance action immediately. next-maintenance - Apply the maintenance action during the next maintenance window for the resource. undo-opt-in - Cancel any existing next-maintenance opt-in requests. (required)
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: ResourceIdentifier, var: resource_identifier, required: true}, {name: ApplyAction, var: apply_action, required: true}, {name: OptInType, var: opt_in_type, required: true}, {name: Action, var: action, required: true, default: ApplyPendingMaintenanceAction}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    resource_identifier: $resource_identifier, apply_action: $apply_action, opt_in_type: $opt_in_type, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a pending maintenance action to a resource (for example, to an Amazon DocumentDB instance).
#
# POST /
# operationId: POST_ApplyPendingMaintenanceAction
export def "post-apply-pending-maintenance-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ApplyPendingMaintenanceAction}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies the specified cluster parameter group.
#
# GET /
# operationId: GET_CopyDBClusterParameterGroup
export def "get-copy-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-db-cluster-parameter-group-identifier: string # The identifier or Amazon Resource Name (ARN) for the source cluster parameter group. Constraints: Must specify a valid cluster parameter group. If the source cluster parameter group is in the same Amazon Web Services Region as the copy, specify a valid parameter group identifier; for example, my-db-cluster-param-group, or a valid ARN. If the source parameter group is in a different Amazon Web Services Region than the copy, specify a valid cluster parameter group ARN; for example, arn:aws:rds:us-east-1:123456789012:sample-cluster:sample-parameter-group. (required)
  --target-db-cluster-parameter-group-identifier: string # The identifier for the copied cluster parameter group. Constraints: Cannot be null, empty, or blank. Must contain from 1 to 255 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster-param-group1 (required)
  --target-db-cluster-parameter-group-description: string # A description for the copied cluster parameter group. (required)
  --tags: list # The tags that are to be assigned to the parameter group.
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SourceDBClusterParameterGroupIdentifier, var: source_db_cluster_parameter_group_identifier, required: true}, {name: TargetDBClusterParameterGroupIdentifier, var: target_db_cluster_parameter_group_identifier, required: true}, {name: TargetDBClusterParameterGroupDescription, var: target_db_cluster_parameter_group_description, required: true}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CopyDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_db_cluster_parameter_group_identifier: $source_db_cluster_parameter_group_identifier, target_db_cluster_parameter_group_identifier: $target_db_cluster_parameter_group_identifier, target_db_cluster_parameter_group_description: $target_db_cluster_parameter_group_description, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies the specified cluster parameter group.
#
# POST /
# operationId: POST_CopyDBClusterParameterGroup
export def "post-copy-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CopyDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies a snapshot of a cluster. To copy a cluster snapshot from a shared manual cluster snapshot, SourceDBClusterSnapshotIdentifier must be the Amazon Resource Name (ARN) of the shared cluster snapshot. You can only copy a shared DB cluster snapshot, whether encrypted or not, in the same Amazon Web Services Region. To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by TargetDBClusterSnapshotIdentifier while that cluster snapshot is in the copying status.
#
# GET /
# operationId: GET_CopyDBClusterSnapshot
export def "get-copy-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-db-cluster-snapshot-identifier: string # The identifier of the cluster snapshot to copy. This parameter is not case sensitive. Constraints: Must specify a valid system snapshot in the available state. If the source snapshot is in the same Amazon Web Services Region as the copy, specify a valid snapshot identifier. If the source snapshot is in a different Amazon Web Services Region than the copy, specify a valid cluster snapshot ARN. Example: my-cluster-snapshot1 (required)
  --target-db-cluster-snapshot-identifier: string # The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster-snapshot2 (required)
  --kms-key-id: string # The KMS key ID for an encrypted cluster snapshot. The KMS key ID is the Amazon Resource Name (ARN), KMS key identifier, or the KMS key alias for the KMS encryption key. If you copy an encrypted cluster snapshot from your Amazon Web Services account, you can specify a value for KmsKeyId to encrypt the copy with a new KMS encryption key. If you don't specify a value for KmsKeyId, then the copy of the cluster snapshot is encrypted with the same KMS key as the source cluster snapshot. If you copy an encrypted cluster snapshot that is shared from another Amazon Web Services account, then you must specify a value for KmsKeyId. To copy an encrypted cluster snapshot to another Amazon Web Services Region, set KmsKeyId to the KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. KMS encryption keys are specific to the Amazon Web Services Region that they are created in, and you can't use encryption keys from one Amazon Web Services Region in another Amazon Web Services Region. If you copy an unencrypted cluster snapshot and specify a value for the KmsKeyId parameter, an error is returned.
  --pre-signed-url: string # The URL that contains a Signature Version 4 signed request for theCopyDBClusterSnapshot API action in the Amazon Web Services Region that contains the source cluster snapshot to copy. You must use the PreSignedUrl parameter when copying a cluster snapshot from another Amazon Web Services Region. If you are using an Amazon Web Services SDK tool or the CLI, you can specify SourceRegion (or --source-region for the CLI) instead of specifying PreSignedUrl manually. Specifying SourceRegion autogenerates a pre-signed URL that is a valid request for the operation that can be executed in the source Amazon Web Services Region. The presigned URL must be a valid request for the CopyDBClusterSnapshot API action that can be executed in the source Amazon Web Services Region that contains the cluster snapshot to be copied. The presigned URL request must contain the following parameter values: SourceRegion - The ID of the region that contains the snapshot to be copied. SourceDBClusterSnapshotIdentifier - The identifier for the the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source Amazon Web Services Region. For example, if you are copying an encrypted cluster snapshot from the us-east-1 Amazon Web Services Region, then your SourceDBClusterSnapshotIdentifier looks something like the following: arn:aws:rds:us-east-1:12345678012:sample-cluster:sample-cluster-snapshot. TargetDBClusterSnapshotIdentifier - The identifier for the new cluster snapshot to be created. This parameter isn't case sensitive.
  --copy-tags: oneof<nothing, bool> # Set to true to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise false. The default is false.
  --tags: list # The tags to be assigned to the cluster snapshot.
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SourceDBClusterSnapshotIdentifier, var: source_db_cluster_snapshot_identifier, required: true}, {name: TargetDBClusterSnapshotIdentifier, var: target_db_cluster_snapshot_identifier, required: true}, {name: KmsKeyId, var: kms_key_id}, {name: PreSignedUrl, var: pre_signed_url}, {name: CopyTags, var: copy_tags}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CopyDBClusterSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_db_cluster_snapshot_identifier: $source_db_cluster_snapshot_identifier, target_db_cluster_snapshot_identifier: $target_db_cluster_snapshot_identifier, kms_key_id: $kms_key_id, pre_signed_url: $pre_signed_url, copy_tags: $copy_tags, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies a snapshot of a cluster. To copy a cluster snapshot from a shared manual cluster snapshot, SourceDBClusterSnapshotIdentifier must be the Amazon Resource Name (ARN) of the shared cluster snapshot. You can only copy a shared DB cluster snapshot, whether encrypted or not, in the same Amazon Web Services Region. To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by TargetDBClusterSnapshotIdentifier while that cluster snapshot is in the copying status.
#
# POST /
# operationId: POST_CopyDBClusterSnapshot
export def "post-copy-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CopyDBClusterSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon DocumentDB cluster.
#
# GET /
# operationId: GET_CreateDBCluster
export def "get-create-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability-zones: list<string> # A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  --backup-retention-period: int # The number of days for which automated backups are retained. You must specify a minimum value of 1. Default: 1 Constraints: Must be a value from 1 to 35.
  --db-cluster-identifier: string # The cluster identifier. This parameter is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster (required)
  --db-cluster-parameter-group-name: string # The name of the cluster parameter group to associate with this cluster.
  --vpc-security-group-ids: list<string> # A list of EC2 VPC security groups to associate with this cluster.
  --db-subnet-group-name: string # A subnet group to associate with this cluster. Constraints: Must match the name of an existing DBSubnetGroup. Must not be default. Example: mySubnetgroup
  --engine: string # The name of the database engine to be used for this cluster. Valid values: docdb (required)
  --engine-version: string # The version number of the database engine to use. The --engine-version will default to the latest major engine version. For production workloads, we recommend explicitly declaring this parameter with the intended major engine version.
  --port: int # The port number on which the instances in the cluster accept connections.
  --master-username: string # The name of the master user for the cluster. Constraints: Must be from 1 to 63 letters or numbers. The first character must be a letter. Cannot be a reserved word for the chosen database engine.
  --master-user-password: string # The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@). Constraints: Must contain from 8 to 100 characters.
  --preferred-backup-window: string # The daily time range during which automated backups are created if automated backups are enabled using the BackupRetentionPeriod parameter. The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Web Services Region. Constraints: Must be in the format hh24:mi-hh24:mi. Must be in Universal Coordinated Time (UTC). Must not conflict with the preferred maintenance window. Must be at least 30 minutes.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Web Services Region, occurring on a random day of the week. Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun Constraints: Minimum 30-minute window.
  --tags: list # The tags to be assigned to the cluster.
  --storage-encrypted: oneof<nothing, bool> # Specifies whether the cluster is encrypted.
  --kms-key-id: string # The KMS key identifier for an encrypted cluster. The KMS key identifier is the Amazon Resource Name (ARN) for the KMS encryption key. If you are creating a cluster using the same Amazon Web Services account that owns the KMS encryption key that is used to encrypt the new cluster, you can use the KMS key alias instead of the ARN for the KMS encryption key. If an encryption key is not specified in KmsKeyId: If the StorageEncrypted parameter is true, Amazon DocumentDB uses your default encryption key. KMS creates the default encryption key for your Amazon Web Services account. Your Amazon Web Services account has a different default encryption key for each Amazon Web Services Regions.
  --pre-signed-url: string # Not currently supported.
  --enable-cloudwatch-logs-exports: list<string> # A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs. You can enable audit logs or profiler logs. For more information, see Auditing Amazon DocumentDB Events (https://docs.aws.amazon.com/documentdb/latest/developerguide/event-auditing.html) and Profiling Amazon DocumentDB Operations (https://docs.aws.amazon.com/documentdb/latest/developerguide/profiling.html).
  --deletion-protection: oneof<nothing, bool> # Specifies whether this cluster can be deleted. If DeletionProtection is enabled, the cluster cannot be deleted unless it is modified and DeletionProtection is disabled. DeletionProtection protects clusters from being accidentally deleted.
  --global-cluster-identifier: string # The cluster identifier of the new global cluster.
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AvailabilityZones, var: availability_zones, style: multi}, {name: BackupRetentionPeriod, var: backup_retention_period}, {name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name}, {name: VpcSecurityGroupIds, var: vpc_security_group_ids, style: multi}, {name: DBSubnetGroupName, var: db_subnet_group_name}, {name: Engine, var: engine, required: true}, {name: EngineVersion, var: engine_version}, {name: Port, var: port}, {name: MasterUsername, var: master_username}, {name: MasterUserPassword, var: master_user_password}, {name: PreferredBackupWindow, var: preferred_backup_window}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: Tags, var: tags, style: multi}, {name: StorageEncrypted, var: storage_encrypted}, {name: KmsKeyId, var: kms_key_id}, {name: PreSignedUrl, var: pre_signed_url}, {name: EnableCloudwatchLogsExports, var: enable_cloudwatch_logs_exports, style: multi}, {name: DeletionProtection, var: deletion_protection}, {name: GlobalClusterIdentifier, var: global_cluster_identifier}, {name: Action, var: action, required: true, default: CreateDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    availability_zones: $availability_zones, backup_retention_period: $backup_retention_period, db_cluster_identifier: $db_cluster_identifier, db_cluster_parameter_group_name: $db_cluster_parameter_group_name, vpc_security_group_ids: $vpc_security_group_ids, db_subnet_group_name: $db_subnet_group_name, engine: $engine, engine_version: $engine_version, port: $port, master_username: $master_username, master_user_password: $master_user_password, preferred_backup_window: $preferred_backup_window, preferred_maintenance_window: $preferred_maintenance_window, tags: $tags, storage_encrypted: $storage_encrypted, kms_key_id: $kms_key_id, pre_signed_url: $pre_signed_url, enable_cloudwatch_logs_exports: $enable_cloudwatch_logs_exports, deletion_protection: $deletion_protection, global_cluster_identifier: $global_cluster_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon DocumentDB cluster.
#
# POST /
# operationId: POST_CreateDBCluster
export def "post-create-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new cluster parameter group. Parameters in a cluster parameter group apply to all of the instances in a cluster. A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. In Amazon DocumentDB, you cannot make modifications directly to the default.docdb3.6 cluster parameter group. If your Amazon DocumentDB cluster is using the default cluster parameter group and you want to modify a value in it, you must first create a new parameter group (https://docs.aws.amazon.com/documentdb/latest/developerguide/cluster_parameter_group-create.html) or copy an existing parameter group (https://docs.aws.amazon.com/documentdb/latest/developerguide/cluster_parameter_group-copy.html), modify it, and then apply the modified parameter group to your cluster. For the new cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover. For more information, see Modifying Amazon DocumentDB Cluster Parameter Groups (https://docs.aws.amazon.com/documentdb/latest/developerguide/cluster_parameter_group-modify.html).
#
# GET /
# operationId: GET_CreateDBClusterParameterGroup
export def "get-create-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the cluster parameter group. Constraints: Must not match the name of an existing DBClusterParameterGroup. This value is stored as a lowercase string. (required)
  --db-parameter-group-family: string # The cluster parameter group family name. (required)
  --description: string # The description for the cluster parameter group. (required)
  --tags: list # The tags to be assigned to the cluster parameter group.
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name, required: true}, {name: DBParameterGroupFamily, var: db_parameter_group_family, required: true}, {name: Description, var: description, required: true}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_parameter_group_name: $db_cluster_parameter_group_name, db_parameter_group_family: $db_parameter_group_family, description: $description, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new cluster parameter group. Parameters in a cluster parameter group apply to all of the instances in a cluster. A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. In Amazon DocumentDB, you cannot make modifications directly to the default.docdb3.6 cluster parameter group. If your Amazon DocumentDB cluster is using the default cluster parameter group and you want to modify a value in it, you must first create a new parameter group (https://docs.aws.amazon.com/documentdb/latest/developerguide/cluster_parameter_group-create.html) or copy an existing parameter group (https://docs.aws.amazon.com/documentdb/latest/developerguide/cluster_parameter_group-copy.html), modify it, and then apply the modified parameter group to your cluster. For the new cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover. For more information, see Modifying Amazon DocumentDB Cluster Parameter Groups (https://docs.aws.amazon.com/documentdb/latest/developerguide/cluster_parameter_group-modify.html).
#
# POST /
# operationId: POST_CreateDBClusterParameterGroup
export def "post-create-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a snapshot of a cluster.
#
# GET /
# operationId: GET_CreateDBClusterSnapshot
export def "get-create-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier of the cluster snapshot. This parameter is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster-snapshot1 (required)
  --db-cluster-identifier: string # The identifier of the cluster to create a snapshot for. This parameter is not case sensitive. Constraints: Must match the identifier of an existing DBCluster. Example: my-cluster (required)
  --tags: list # The tags to be assigned to the cluster snapshot.
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterSnapshotIdentifier, var: db_cluster_snapshot_identifier, required: true}, {name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateDBClusterSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_snapshot_identifier: $db_cluster_snapshot_identifier, db_cluster_identifier: $db_cluster_identifier, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a snapshot of a cluster.
#
# POST /
# operationId: POST_CreateDBClusterSnapshot
export def "post-create-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateDBClusterSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new instance.
#
# GET /
# operationId: GET_CreateDBInstance
export def "get-create-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The instance identifier. This parameter is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: mydbinstance (required)
  --db-instance-class: string # The compute and memory capacity of the instance; for example, db.r5.large. (required)
  --engine: string # The name of the database engine to be used for this instance. Valid value: docdb (required)
  --availability-zone: string # The Amazon EC2 Availability Zone that the instance is created in. Default: A random, system-chosen Availability Zone in the endpoint's Amazon Web Services Region. Example: us-east-1d
  --preferred-maintenance-window: string # The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Web Services Region, occurring on a random day of the week. Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun Constraints: Minimum 30-minute window.
  --auto-minor-version-upgrade: oneof<nothing, bool> # This parameter does not apply to Amazon DocumentDB. Amazon DocumentDB does not perform minor version upgrades regardless of the value set. Default: false
  --tags: list # The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  --db-cluster-identifier: string # The identifier of the cluster that the instance will belong to. (required)
  --copy-tags-to-snapshot: oneof<nothing, bool> # A value that indicates whether to copy tags from the DB instance to snapshots of the DB instance. By default, tags are not copied.
  --promotion-tier: int # A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance. Default: 1 Valid values: 0-15
  --enable-performance-insights: oneof<nothing, bool> # A value that indicates whether to enable Performance Insights for the DB Instance. For more information, see Using Amazon Performance Insights (https://docs.aws.amazon.com/documentdb/latest/developerguide/performance-insights.html).
  --performance-insights-kms-key-id: string # The KMS key identifier for encryption of Performance Insights data. The KMS key identifier is the key ARN, key ID, alias ARN, or alias name for the KMS key. If you do not specify a value for PerformanceInsightsKMSKeyId, then Amazon DocumentDB uses your default KMS key. There is a default KMS key for your Amazon Web Services account. Your Amazon Web Services account has a different default KMS key for each Amazon Web Services region.
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBInstanceIdentifier, var: db_instance_identifier, required: true}, {name: DBInstanceClass, var: db_instance_class, required: true}, {name: Engine, var: engine, required: true}, {name: AvailabilityZone, var: availability_zone}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: Tags, var: tags, style: multi}, {name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: CopyTagsToSnapshot, var: copy_tags_to_snapshot}, {name: PromotionTier, var: promotion_tier}, {name: EnablePerformanceInsights, var: enable_performance_insights}, {name: PerformanceInsightsKMSKeyId, var: performance_insights_kms_key_id}, {name: Action, var: action, required: true, default: CreateDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_instance_identifier: $db_instance_identifier, db_instance_class: $db_instance_class, engine: $engine, availability_zone: $availability_zone, preferred_maintenance_window: $preferred_maintenance_window, auto_minor_version_upgrade: $auto_minor_version_upgrade, tags: $tags, db_cluster_identifier: $db_cluster_identifier, copy_tags_to_snapshot: $copy_tags_to_snapshot, promotion_tier: $promotion_tier, enable_performance_insights: $enable_performance_insights, performance_insights_kms_key_id: $performance_insights_kms_key_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new instance.
#
# POST /
# operationId: POST_CreateDBInstance
export def "post-create-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the Amazon Web Services Region.
#
# GET /
# operationId: GET_CreateDBSubnetGroup
export def "get-create-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name for the subnet group. This value is stored as a lowercase string. Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default. Example: mySubnetgroup (required)
  --db-subnet-group-description: string # The description for the subnet group. (required)
  --subnet-ids: list<string> # The Amazon EC2 subnet IDs for the subnet group. (required)
  --tags: list # The tags to be assigned to the subnet group.
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBSubnetGroupName, var: db_subnet_group_name, required: true}, {name: DBSubnetGroupDescription, var: db_subnet_group_description, required: true}, {name: SubnetIds, var: subnet_ids, style: multi, required: true}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateDBSubnetGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_subnet_group_name: $db_subnet_group_name, db_subnet_group_description: $db_subnet_group_description, subnet_ids: $subnet_ids, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the Amazon Web Services Region.
#
# POST /
# operationId: POST_CreateDBSubnetGroup
export def "post-create-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateDBSubnetGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon DocumentDB event notification subscription. This action requires a topic Amazon Resource Name (ARN) created by using the Amazon DocumentDB console, the Amazon SNS console, or the Amazon SNS API. To obtain an ARN with Amazon SNS, you must create a topic in Amazon SNS and subscribe to the topic. The ARN is displayed in the Amazon SNS console. You can specify the type of source (SourceType) that you want to be notified of. You can also provide a list of Amazon DocumentDB sources (SourceIds) that trigger the events, and you can provide a list of event categories (EventCategories) for events that you want to be notified of. For example, you can specify SourceType = db-instance, SourceIds = mydbinstance1, mydbinstance2 and EventCategories = Availability, Backup. If you specify both the SourceType and SourceIds (such as SourceType = db-instance and SourceIdentifier = myDBInstance1), you are notified of all the db-instance events for the specified source. If you specify a SourceType but do not specify a SourceIdentifier, you receive notice of the events for that source type for all your Amazon DocumentDB sources. If you do not specify either the SourceType or the SourceIdentifier, you are notified of events generated from all Amazon DocumentDB sources belonging to your customer account.
#
# GET /
# operationId: GET_CreateEventSubscription
export def "get-create-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the subscription. Constraints: The name must be fewer than 255 characters. (required)
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the SNS topic created for event notification. Amazon SNS creates the ARN when you create a topic and subscribe to it. (required)
  --source-type: string # The type of source that is generating the events. For example, if you want to be notified of events generated by an instance, you would set this parameter to db-instance. If this value is not specified, all events are returned. Valid values: db-instance, db-cluster, db-parameter-group, db-security-group, db-cluster-snapshot
  --event-categories: list<string> # A list of event categories for a SourceType that you want to subscribe to.
  --source-ids: list<string> # The list of identifiers of the event sources for which events are returned. If not specified, then all sources are included in the response. An identifier must begin with a letter and must contain only ASCII letters, digits, and hyphens; it can't end with a hyphen or contain two consecutive hyphens. Constraints: If SourceIds are provided, SourceType must also be provided. If the source type is an instance, a DBInstanceIdentifier must be provided. If the source type is a security group, a DBSecurityGroupName must be provided. If the source type is a parameter group, a DBParameterGroupName must be provided. If the source type is a snapshot, a DBSnapshotIdentifier must be provided.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription, set to false to create the subscription but not active it.
  --tags: list # The tags to be assigned to the event subscription.
  --action: string@action-completer-10 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SubscriptionName, var: subscription_name, required: true}, {name: SnsTopicArn, var: sns_topic_arn, required: true}, {name: SourceType, var: source_type}, {name: EventCategories, var: event_categories, style: multi}, {name: SourceIds, var: source_ids, style: multi}, {name: Enabled, var: enabled}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateEventSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_name: $subscription_name, sns_topic_arn: $sns_topic_arn, source_type: $source_type, event_categories: $event_categories, source_ids: $source_ids, enabled: $enabled, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon DocumentDB event notification subscription. This action requires a topic Amazon Resource Name (ARN) created by using the Amazon DocumentDB console, the Amazon SNS console, or the Amazon SNS API. To obtain an ARN with Amazon SNS, you must create a topic in Amazon SNS and subscribe to the topic. The ARN is displayed in the Amazon SNS console. You can specify the type of source (SourceType) that you want to be notified of. You can also provide a list of Amazon DocumentDB sources (SourceIds) that trigger the events, and you can provide a list of event categories (EventCategories) for events that you want to be notified of. For example, you can specify SourceType = db-instance, SourceIds = mydbinstance1, mydbinstance2 and EventCategories = Availability, Backup. If you specify both the SourceType and SourceIds (such as SourceType = db-instance and SourceIdentifier = myDBInstance1), you are notified of all the db-instance events for the specified source. If you specify a SourceType but do not specify a SourceIdentifier, you receive notice of the events for that source type for all your Amazon DocumentDB sources. If you do not specify either the SourceType or the SourceIdentifier, you are notified of events generated from all Amazon DocumentDB sources belonging to your customer account.
#
# POST /
# operationId: POST_CreateEventSubscription
export def "post-create-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-10 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateEventSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon DocumentDB global cluster that can span multiple multiple Amazon Web Services Regions. The global cluster contains one primary cluster with read-write capability, and up-to give read-only secondary clusters. Global clusters uses storage-based fast replication across regions with latencies less than one second, using dedicated infrastructure with no impact to your workload’s performance. You can create a global cluster that is initially empty, and then add a primary and a secondary to it. Or you can specify an existing cluster during the create operation, and this cluster becomes the primary of the global cluster. This action only applies to Amazon DocumentDB clusters.
#
# GET /
# operationId: GET_CreateGlobalCluster
export def "get-create-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The cluster identifier of the new global cluster. (required)
  --source-db-cluster-identifier: string # The Amazon Resource Name (ARN) to use as the primary cluster of the global cluster. This parameter is optional.
  --engine: string # The name of the database engine to be used for this cluster.
  --engine-version: string # The engine version of the global cluster.
  --deletion-protection: oneof<nothing, bool> # The deletion protection setting for the new global cluster. The global cluster can't be deleted when deletion protection is enabled.
  --database-name: string # The name for your database of up to 64 alpha-numeric characters. If you do not provide a name, Amazon DocumentDB will not create a database in the global cluster you are creating.
  --storage-encrypted: oneof<nothing, bool> # The storage encryption setting for the new global cluster.
  --action: string@action-completer-11 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: GlobalClusterIdentifier, var: global_cluster_identifier, required: true}, {name: SourceDBClusterIdentifier, var: source_db_cluster_identifier}, {name: Engine, var: engine}, {name: EngineVersion, var: engine_version}, {name: DeletionProtection, var: deletion_protection}, {name: DatabaseName, var: database_name}, {name: StorageEncrypted, var: storage_encrypted}, {name: Action, var: action, required: true, default: CreateGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_cluster_identifier: $global_cluster_identifier, source_db_cluster_identifier: $source_db_cluster_identifier, engine: $engine, engine_version: $engine_version, deletion_protection: $deletion_protection, database_name: $database_name, storage_encrypted: $storage_encrypted, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon DocumentDB global cluster that can span multiple multiple Amazon Web Services Regions. The global cluster contains one primary cluster with read-write capability, and up-to give read-only secondary clusters. Global clusters uses storage-based fast replication across regions with latencies less than one second, using dedicated infrastructure with no impact to your workload’s performance. You can create a global cluster that is initially empty, and then add a primary and a secondary to it. Or you can specify an existing cluster during the create operation, and this cluster becomes the primary of the global cluster. This action only applies to Amazon DocumentDB clusters.
#
# POST /
# operationId: POST_CreateGlobalCluster
export def "post-create-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-11 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.
#
# GET /
# operationId: GET_DeleteDBCluster
export def "get-delete-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive. Constraints: Must match an existing DBClusterIdentifier. (required)
  --skip-final-snapshot: oneof<nothing, bool> # Determines whether a final cluster snapshot is created before the cluster is deleted. If true is specified, no cluster snapshot is created. If false is specified, a cluster snapshot is created before the DB cluster is deleted. If SkipFinalSnapshot is false, you must specify a FinalDBSnapshotIdentifier parameter. Default: false
  --final-db-snapshot-identifier: string # The cluster snapshot identifier of the new cluster snapshot created when SkipFinalSnapshot is set to false. Specifying this parameter and also setting the SkipFinalShapshot parameter to true results in an error. Constraints: Must be from 1 to 255 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --action: string@action-completer-12 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: SkipFinalSnapshot, var: skip_final_snapshot}, {name: FinalDBSnapshotIdentifier, var: final_db_snapshot_identifier}, {name: Action, var: action, required: true, default: DeleteDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, skip_final_snapshot: $skip_final_snapshot, final_db_snapshot_identifier: $final_db_snapshot_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.
#
# POST /
# operationId: POST_DeleteDBCluster
export def "post-delete-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
#
# GET /
# operationId: GET_DeleteDBClusterParameterGroup
export def "get-delete-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the cluster parameter group. Constraints: Must be the name of an existing cluster parameter group. You can't delete a default cluster parameter group. Cannot be associated with any clusters. (required)
  --action: string@action-completer-13 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name, required: true}, {name: Action, var: action, required: true, default: DeleteDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_parameter_group_name: $db_cluster_parameter_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
#
# POST /
# operationId: POST_DeleteDBClusterParameterGroup
export def "post-delete-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-13 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated. The cluster snapshot must be in the available state to be deleted.
#
# GET /
# operationId: GET_DeleteDBClusterSnapshot
export def "get-delete-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier of the cluster snapshot to delete. Constraints: Must be the name of an existing cluster snapshot in the available state. (required)
  --action: string@action-completer-14 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterSnapshotIdentifier, var: db_cluster_snapshot_identifier, required: true}, {name: Action, var: action, required: true, default: DeleteDBClusterSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_snapshot_identifier: $db_cluster_snapshot_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated. The cluster snapshot must be in the available state to be deleted.
#
# POST /
# operationId: POST_DeleteDBClusterSnapshot
export def "post-delete-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-14 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteDBClusterSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously provisioned instance.
#
# GET /
# operationId: GET_DeleteDBInstance
export def "get-delete-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The instance identifier for the instance to be deleted. This parameter isn't case sensitive. Constraints: Must match the name of an existing instance. (required)
  --action: string@action-completer-15 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBInstanceIdentifier, var: db_instance_identifier, required: true}, {name: Action, var: action, required: true, default: DeleteDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_instance_identifier: $db_instance_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously provisioned instance.
#
# POST /
# operationId: POST_DeleteDBInstance
export def "post-delete-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-15 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subnet group. The specified database subnet group must not be associated with any DB instances.
#
# GET /
# operationId: GET_DeleteDBSubnetGroup
export def "get-delete-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name of the database subnet group to delete. You can't delete the default subnet group. Constraints: Must match the name of an existing DBSubnetGroup. Must not be default. Example: mySubnetgroup (required)
  --action: string@action-completer-16 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBSubnetGroupName, var: db_subnet_group_name, required: true}, {name: Action, var: action, required: true, default: DeleteDBSubnetGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    db_subnet_group_name: $db_subnet_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subnet group. The specified database subnet group must not be associated with any DB instances.
#
# POST /
# operationId: POST_DeleteDBSubnetGroup
export def "post-delete-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-16 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteDBSubnetGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon DocumentDB event notification subscription.
#
# GET /
# operationId: GET_DeleteEventSubscription
export def "get-delete-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the Amazon DocumentDB event notification subscription that you want to delete. (required)
  --action: string@action-completer-17 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SubscriptionName, var: subscription_name, required: true}, {name: Action, var: action, required: true, default: DeleteEventSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_name: $subscription_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon DocumentDB event notification subscription.
#
# POST /
# operationId: POST_DeleteEventSubscription
export def "post-delete-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-17 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteEventSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a global cluster. The primary and secondary clusters must already be detached or deleted before attempting to delete a global cluster. This action only applies to Amazon DocumentDB clusters.
#
# GET /
# operationId: GET_DeleteGlobalCluster
export def "get-delete-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The cluster identifier of the global cluster being deleted. (required)
  --action: string@action-completer-18 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: GlobalClusterIdentifier, var: global_cluster_identifier, required: true}, {name: Action, var: action, required: true, default: DeleteGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_cluster_identifier: $global_cluster_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a global cluster. The primary and secondary clusters must already be detached or deleted before attempting to delete a global cluster. This action only applies to Amazon DocumentDB clusters.
#
# POST /
# operationId: POST_DeleteGlobalCluster
export def "post-delete-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-18 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this Amazon Web Services account.
#
# GET /
# operationId: GET_DescribeCertificates
export def "get-describe-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-identifier: string # The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to MaxRecords certificates is returned. This parameter is not case sensitive. Constraints Must match an existing CertificateIdentifier.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum: 20 Maximum: 100
  --marker: string # An optional pagination token provided by a previous DescribeCertificates request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-19 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: CertificateIdentifier, var: certificate_identifier}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCertificates}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    certificate_identifier: $certificate_identifier, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this Amazon Web Services account.
#
# POST /
# operationId: POST_DescribeCertificates
export def "post-describe-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-19 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCertificates}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DBClusterParameterGroup descriptions. If a DBClusterParameterGroupName parameter is specified, the list contains only the description of the specified cluster parameter group.
#
# GET /
# operationId: GET_DescribeDBClusterParameterGroups
export def "get-describe-db-cluster-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of a specific cluster parameter group to return details for. Constraints: If provided, must match the name of an existing DBClusterParameterGroup.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-20 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBClusterParameterGroups}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_parameter_group_name: $db_cluster_parameter_group_name, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DBClusterParameterGroup descriptions. If a DBClusterParameterGroupName parameter is specified, the list contains only the description of the specified cluster parameter group.
#
# POST /
# operationId: POST_DescribeDBClusterParameterGroups
export def "post-describe-db-cluster-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-20 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBClusterParameterGroups}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the detailed parameter list for a particular cluster parameter group.
#
# GET /
# operationId: GET_DescribeDBClusterParameters
export def "get-describe-db-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of a specific cluster parameter group to return parameter details for. Constraints: If provided, must match the name of an existing DBClusterParameterGroup. (required)
  --source: string # A value that indicates to return only parameters for a specific source. Parameter sources can be engine, service, or customer.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-21 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name, required: true}, {name: Source, var: source}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBClusterParameters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_parameter_group_name: $db_cluster_parameter_group_name, source: $source, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the detailed parameter list for a particular cluster parameter group.
#
# POST /
# operationId: POST_DescribeDBClusterParameters
export def "post-describe-db-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-21 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBClusterParameters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot. When you share snapshots with other Amazon Web Services accounts, DescribeDBClusterSnapshotAttributes returns the restore attribute and a list of IDs for the Amazon Web Services accounts that are authorized to copy or restore the manual cluster snapshot. If all is included in the list of values for the restore attribute, then the manual cluster snapshot is public and can be copied or restored by all Amazon Web Services accounts.
#
# GET /
# operationId: GET_DescribeDBClusterSnapshotAttributes
export def "get-describe-db-cluster-snapshot-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier for the cluster snapshot to describe the attributes for. (required)
  --action: string@action-completer-22 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterSnapshotIdentifier, var: db_cluster_snapshot_identifier, required: true}, {name: Action, var: action, required: true, default: DescribeDBClusterSnapshotAttributes}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_snapshot_identifier: $db_cluster_snapshot_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot. When you share snapshots with other Amazon Web Services accounts, DescribeDBClusterSnapshotAttributes returns the restore attribute and a list of IDs for the Amazon Web Services accounts that are authorized to copy or restore the manual cluster snapshot. If all is included in the list of values for the restore attribute, then the manual cluster snapshot is public and can be copied or restored by all Amazon Web Services accounts.
#
# POST /
# operationId: POST_DescribeDBClusterSnapshotAttributes
export def "post-describe-db-cluster-snapshot-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-22 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeDBClusterSnapshotAttributes}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about cluster snapshots. This API operation supports pagination.
#
# GET /
# operationId: GET_DescribeDBClusterSnapshots
export def "get-describe-db-cluster-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the DBClusterSnapshotIdentifier parameter. This parameter is not case sensitive. Constraints: If provided, must match the identifier of an existing DBCluster.
  --db-cluster-snapshot-identifier: string # A specific cluster snapshot identifier to describe. This parameter can't be used with the DBClusterIdentifier parameter. This value is stored as a lowercase string. Constraints: If provided, must match the identifier of an existing DBClusterSnapshot. If this identifier is for an automated snapshot, the SnapshotType parameter must also be specified.
  --snapshot-type: string # The type of cluster snapshots to be returned. You can specify one of the following values: automated - Return all cluster snapshots that Amazon DocumentDB has automatically created for your Amazon Web Services account. manual - Return all cluster snapshots that you have manually created for your Amazon Web Services account. shared - Return all manual cluster snapshots that have been shared to your Amazon Web Services account. public - Return all cluster snapshots that have been marked as public. If you don't specify a SnapshotType value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the IncludeShared parameter to true. You can include public cluster snapshots with these results by setting theIncludePublic parameter to true. The IncludeShared and IncludePublic parameters don't apply for SnapshotType values of manual or automated. The IncludePublic parameter doesn't apply when SnapshotType is set to shared. The IncludeShared parameter doesn't apply when SnapshotType is set to public.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --include-shared: oneof<nothing, bool> # Set to true to include shared manual cluster snapshots from other Amazon Web Services accounts that this Amazon Web Services account has been given permission to copy or restore, and otherwise false. The default is false.
  --include-public: oneof<nothing, bool> # Set to true to include manual cluster snapshots that are public and can be copied or restored by any Amazon Web Services account, and otherwise false. The default is false.
  --action: string@action-completer-23 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier}, {name: DBClusterSnapshotIdentifier, var: db_cluster_snapshot_identifier}, {name: SnapshotType, var: snapshot_type}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: IncludeShared, var: include_shared}, {name: IncludePublic, var: include_public}, {name: Action, var: action, required: true, default: DescribeDBClusterSnapshots}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, db_cluster_snapshot_identifier: $db_cluster_snapshot_identifier, snapshot_type: $snapshot_type, filters: $filters, max_records: $max_records, marker: $marker, include_shared: $include_shared, include_public: $include_public, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about cluster snapshots. This API operation supports pagination.
#
# POST /
# operationId: POST_DescribeDBClusterSnapshots
export def "post-describe-db-cluster-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-23 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBClusterSnapshots}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the filterName=engine,Values=docdb filter parameter to return only Amazon DocumentDB clusters.
#
# GET /
# operationId: GET_DescribeDBClusters
export def "get-describe-db-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive. Constraints: If provided, must match an existing DBClusterIdentifier.
  --filters: list # A filter that specifies one or more clusters to describe. Supported filters: db-cluster-id - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-24 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBClusters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the filterName=engine,Values=docdb filter parameter to return only Amazon DocumentDB clusters.
#
# POST /
# operationId: POST_DescribeDBClusters
export def "post-describe-db-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-24 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBClusters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the available engines.
#
# GET /
# operationId: GET_DescribeDBEngineVersions
export def "get-describe-db-engine-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string # The database engine to return.
  --engine-version: string # The database engine version to return. Example: 3.6.0
  --db-parameter-group-family: string # The name of a specific parameter group family to return details for. Constraints: If provided, must match an existing DBParameterGroupFamily.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --default-only: oneof<nothing, bool> # Indicates that only the default version of the specified engine or engine and major version combination is returned.
  --list-supported-character-sets: oneof<nothing, bool> # If this parameter is specified and the requested engine supports the CharacterSetName parameter for CreateDBInstance, the response includes a list of supported character sets for each engine version.
  --list-supported-timezones: oneof<nothing, bool> # If this parameter is specified and the requested engine supports the TimeZone parameter for CreateDBInstance, the response includes a list of supported time zones for each engine version.
  --action: string@action-completer-25 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Engine, var: engine}, {name: EngineVersion, var: engine_version}, {name: DBParameterGroupFamily, var: db_parameter_group_family}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: DefaultOnly, var: default_only}, {name: ListSupportedCharacterSets, var: list_supported_character_sets}, {name: ListSupportedTimezones, var: list_supported_timezones}, {name: Action, var: action, required: true, default: DescribeDBEngineVersions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    engine: $engine, engine_version: $engine_version, db_parameter_group_family: $db_parameter_group_family, filters: $filters, max_records: $max_records, marker: $marker, default_only: $default_only, list_supported_character_sets: $list_supported_character_sets, list_supported_timezones: $list_supported_timezones, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the available engines.
#
# POST /
# operationId: POST_DescribeDBEngineVersions
export def "post-describe-db-engine-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-25 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBEngineVersions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
#
# GET /
# operationId: GET_DescribeDBInstances
export def "get-describe-db-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive. Constraints: If provided, must match the identifier of an existing DBInstance.
  --filters: list # A filter that specifies one or more instances to describe. Supported filters: db-cluster-id - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs. db-instance-id - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-26 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBInstanceIdentifier, var: db_instance_identifier}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBInstances}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_instance_identifier: $db_instance_identifier, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
#
# POST /
# operationId: POST_DescribeDBInstances
export def "post-describe-db-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-26 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBInstances}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DBSubnetGroup descriptions. If a DBSubnetGroupName is specified, the list will contain only the descriptions of the specified DBSubnetGroup.
#
# GET /
# operationId: GET_DescribeDBSubnetGroups
export def "get-describe-db-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name of the subnet group to return details for.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-27 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBSubnetGroupName, var: db_subnet_group_name}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBSubnetGroups}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_subnet_group_name: $db_subnet_group_name, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DBSubnetGroup descriptions. If a DBSubnetGroupName is specified, the list will contain only the descriptions of the specified DBSubnetGroup.
#
# POST /
# operationId: POST_DescribeDBSubnetGroups
export def "post-describe-db-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-27 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeDBSubnetGroups}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default engine and system parameter information for the cluster database engine.
#
# GET /
# operationId: GET_DescribeEngineDefaultClusterParameters
export def "get-describe-engine-default-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-family: string # The name of the cluster parameter group family to return the engine parameter information for. (required)
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-28 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBParameterGroupFamily, var: db_parameter_group_family, required: true}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEngineDefaultClusterParameters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_parameter_group_family: $db_parameter_group_family, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default engine and system parameter information for the cluster database engine.
#
# POST /
# operationId: POST_DescribeEngineDefaultClusterParameters
export def "post-describe-engine-default-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-28 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeEngineDefaultClusterParameters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of categories for all event source types, or, if specified, for a specified source type.
#
# GET /
# operationId: GET_DescribeEventCategories
export def "get-describe-event-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-type: string # The type of source that is generating the events. Valid values: db-instance, db-parameter-group, db-security-group
  --filters: list # This parameter is not currently supported.
  --action: string@action-completer-29 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SourceType, var: source_type}, {name: Filters, var: filters, style: multi}, {name: Action, var: action, required: true, default: DescribeEventCategories}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_type: $source_type, filters: $filters, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays a list of categories for all event source types, or, if specified, for a specified source type.
#
# POST /
# operationId: POST_DescribeEventCategories
export def "post-describe-event-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-29 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeEventCategories}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the subscription descriptions for a customer account. The description for a subscription includes SubscriptionName, SNSTopicARN, CustomerID, SourceType, SourceID, CreationTime, and Status. If you specify a SubscriptionName, lists the description for that subscription.
#
# GET /
# operationId: GET_DescribeEventSubscriptions
export def "get-describe-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the Amazon DocumentDB event notification subscription that you want to describe.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-30 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SubscriptionName, var: subscription_name}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEventSubscriptions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_name: $subscription_name, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the subscription descriptions for a customer account. The description for a subscription includes SubscriptionName, SNSTopicARN, CustomerID, SourceType, SourceID, CreationTime, and Status. If you specify a SubscriptionName, lists the description for that subscription.
#
# POST /
# operationId: POST_DescribeEventSubscriptions
export def "post-describe-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-30 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEventSubscriptions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
#
# GET /
# operationId: GET_DescribeEvents
export def "get-describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-identifier: string # The identifier of the event source for which events are returned. If not specified, then all sources are included in the response. Constraints: If SourceIdentifier is provided, SourceType must also be provided. If the source type is DBInstance, a DBInstanceIdentifier must be provided. If the source type is DBSecurityGroup, a DBSecurityGroupName must be provided. If the source type is DBParameterGroup, a DBParameterGroupName must be provided. If the source type is DBSnapshot, a DBSnapshotIdentifier must be provided. Cannot end with a hyphen or contain two consecutive hyphens.
  --source-type: string@source-type-completer # The event source to retrieve events for. If no value is specified, all events are returned.
  --start-time: string # The beginning of the time interval to retrieve events for, specified in ISO 8601 format. Example: 2009-07-08T18:00Z (format: date-time)
  --end-time: string # The end of the time interval for which to retrieve events, specified in ISO 8601 format. Example: 2009-07-08T18:00Z (format: date-time)
  --duration: int # The number of minutes to retrieve events for. Default: 60
  --event-categories: list<string> # A list of event categories that trigger notifications for an event notification subscription.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-31 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SourceIdentifier, var: source_identifier}, {name: SourceType, var: source_type}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: Duration, var: duration}, {name: EventCategories, var: event_categories, style: multi}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEvents}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_identifier: $source_identifier, source_type: $source_type, start_time: $start_time, end_time: $end_time, duration: $duration, event_categories: $event_categories, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
#
# POST /
# operationId: POST_DescribeEvents
export def "post-describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-31 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEvents}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about Amazon DocumentDB global clusters. This API supports pagination. This action only applies to Amazon DocumentDB clusters.
#
# GET /
# operationId: GET_DescribeGlobalClusters
export def "get-describe-global-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The user-supplied cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case-sensitive.
  --filters: list # A filter that specifies one or more global DB clusters to describe. Supported filters: db-cluster-id accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list will only include information about the clusters identified by these ARNs.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that you can retrieve the remaining results.
  --marker: string # An optional pagination token provided by a previous DescribeGlobalClusters request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-32 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: GlobalClusterIdentifier, var: global_cluster_identifier}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeGlobalClusters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_cluster_identifier: $global_cluster_identifier, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about Amazon DocumentDB global clusters. This API supports pagination. This action only applies to Amazon DocumentDB clusters.
#
# POST /
# operationId: POST_DescribeGlobalClusters
export def "post-describe-global-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-32 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeGlobalClusters}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of orderable instance options for the specified engine.
#
# GET /
# operationId: GET_DescribeOrderableDBInstanceOptions
export def "get-describe-orderable-db-instance-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string # The name of the engine to retrieve instance options for. (required)
  --engine-version: string # The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  --db-instance-class: string # The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  --license-model: string # The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  --vpc: oneof<nothing, bool> # The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-33 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Engine, var: engine, required: true}, {name: EngineVersion, var: engine_version}, {name: DBInstanceClass, var: db_instance_class}, {name: LicenseModel, var: license_model}, {name: Vpc, var: vpc}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeOrderableDBInstanceOptions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    engine: $engine, engine_version: $engine_version, db_instance_class: $db_instance_class, license_model: $license_model, vpc: $vpc, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of orderable instance options for the specified engine.
#
# POST /
# operationId: POST_DescribeOrderableDBInstanceOptions
export def "post-describe-orderable-db-instance-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-33 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeOrderableDBInstanceOptions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resources (for example, instances) that have at least one pending maintenance action.
#
# GET /
# operationId: GET_DescribePendingMaintenanceActions
export def "get-describe-pending-maintenance-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-identifier: string # The ARN of a resource to return pending maintenance actions for.
  --filters: list # A filter that specifies one or more resources to return pending maintenance actions for. Supported filters: db-cluster-id - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs. db-instance-id - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token (marker) is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --action: string@action-completer-34 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: ResourceIdentifier, var: resource_identifier}, {name: Filters, var: filters, style: multi}, {name: Marker, var: marker}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribePendingMaintenanceActions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    resource_identifier: $resource_identifier, filters: $filters, marker: $marker, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resources (for example, instances) that have at least one pending maintenance action.
#
# POST /
# operationId: POST_DescribePendingMaintenanceActions
export def "post-describe-pending-maintenance-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-34 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribePendingMaintenanceActions}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forces a failover for a cluster. A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer). If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.
#
# GET /
# operationId: GET_FailoverDBCluster
export def "get-failover-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # A cluster identifier to force a failover for. This parameter is not case sensitive. Constraints: Must match the identifier of an existing DBCluster.
  --target-db-instance-identifier: string # The name of the instance to promote to the primary instance. You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, mydbcluster-replica1.
  --action: string@action-completer-35 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier}, {name: TargetDBInstanceIdentifier, var: target_db_instance_identifier}, {name: Action, var: action, required: true, default: FailoverDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, target_db_instance_identifier: $target_db_instance_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forces a failover for a cluster. A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer). If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.
#
# POST /
# operationId: POST_FailoverDBCluster
export def "post-failover-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-35 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: FailoverDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all tags on an Amazon DocumentDB resource.
#
# GET /
# operationId: GET_ListTagsForResource
export def "get-list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN). (required)
  --filters: list # This parameter is not currently supported.
  --action: string@action-completer-36 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: ResourceName, var: resource_name, required: true}, {name: Filters, var: filters, style: multi}, {name: Action, var: action, required: true, default: ListTagsForResource}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, filters: $filters, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all tags on an Amazon DocumentDB resource.
#
# POST /
# operationId: POST_ListTagsForResource
export def "post-list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-36 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ListTagsForResource}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
#
# GET /
# operationId: GET_ModifyDBCluster
export def "get-modify-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The cluster identifier for the cluster that is being modified. This parameter is not case sensitive. Constraints: Must match the identifier of an existing DBCluster. (required)
  --new-db-cluster-identifier: string # The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster2
  --apply-immediately: oneof<nothing, bool> # A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the PreferredMaintenanceWindow setting for the cluster. If this parameter is set to false, changes to the cluster are applied during the next maintenance window. The ApplyImmediately parameter affects only the NewDBClusterIdentifier and MasterUserPassword values. If you set this parameter value to false, the changes to the NewDBClusterIdentifier and MasterUserPassword values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the ApplyImmediately parameter. Default: false
  --backup-retention-period: int # The number of days for which automated backups are retained. You must specify a minimum value of 1. Default: 1 Constraints: Must be a value from 1 to 35.
  --db-cluster-parameter-group-name: string # The name of the cluster parameter group to use for the cluster.
  --vpc-security-group-ids: list<string> # A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  --port: int # The port number on which the cluster accepts connections. Constraints: Must be a value from 1150 to 65535. Default: The same port as the original cluster.
  --master-user-password: string # The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@). Constraints: Must contain from 8 to 100 characters.
  --preferred-backup-window: string # The daily time range during which automated backups are created if automated backups are enabled, using the BackupRetentionPeriod parameter. The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Web Services Region. Constraints: Must be in the format hh24:mi-hh24:mi. Must be in Universal Coordinated Time (UTC). Must not conflict with the preferred maintenance window. Must be at least 30 minutes.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Web Services Region, occurring on a random day of the week. Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun Constraints: Minimum 30-minute window.
  --cloudwatch-logs-export-configuration: record # The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster. The EnableLogTypes and DisableLogTypes arrays determine which logs are exported (or not exported) to CloudWatch Logs.
  --engine-version: string # The version number of the database engine to which you want to upgrade. Modifying engine version is not supported on Amazon DocumentDB.
  --deletion-protection: oneof<nothing, bool> # Specifies whether this cluster can be deleted. If DeletionProtection is enabled, the cluster cannot be deleted unless it is modified and DeletionProtection is disabled. DeletionProtection protects clusters from being accidentally deleted.
  --action: string@action-completer-37 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: NewDBClusterIdentifier, var: new_db_cluster_identifier}, {name: ApplyImmediately, var: apply_immediately}, {name: BackupRetentionPeriod, var: backup_retention_period}, {name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name}, {name: VpcSecurityGroupIds, var: vpc_security_group_ids, style: multi}, {name: Port, var: port}, {name: MasterUserPassword, var: master_user_password}, {name: PreferredBackupWindow, var: preferred_backup_window}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: CloudwatchLogsExportConfiguration, var: cloudwatch_logs_export_configuration, style: multi}, {name: EngineVersion, var: engine_version}, {name: DeletionProtection, var: deletion_protection}, {name: Action, var: action, required: true, default: ModifyDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, new_db_cluster_identifier: $new_db_cluster_identifier, apply_immediately: $apply_immediately, backup_retention_period: $backup_retention_period, db_cluster_parameter_group_name: $db_cluster_parameter_group_name, vpc_security_group_ids: $vpc_security_group_ids, port: $port, master_user_password: $master_user_password, preferred_backup_window: $preferred_backup_window, preferred_maintenance_window: $preferred_maintenance_window, cloudwatch_logs_export_configuration: $cloudwatch_logs_export_configuration, engine_version: $engine_version, deletion_protection: $deletion_protection, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
#
# POST /
# operationId: POST_ModifyDBCluster
export def "post-modify-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-37 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ModifyDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: ParameterName, ParameterValue, and ApplyMethod. A maximum of 20 parameters can be modified in a single request. Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect. After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the character_set_database parameter.
#
# GET /
# operationId: GET_ModifyDBClusterParameterGroup
export def "get-modify-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the cluster parameter group to modify. (required)
  --parameters: list # A list of parameters in the cluster parameter group to modify. (required)
  --action: string@action-completer-38 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name, required: true}, {name: Parameters, var: parameters, style: multi, required: true}, {name: Action, var: action, required: true, default: ModifyDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_parameter_group_name: $db_cluster_parameter_group_name, parameters: $parameters, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: ParameterName, ParameterValue, and ApplyMethod. A maximum of 20 parameters can be modified in a single request. Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect. After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the character_set_database parameter.
#
# POST /
# operationId: POST_ModifyDBClusterParameterGroup
export def "post-modify-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-38 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ModifyDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an attribute and values to, or removes an attribute and values from, a manual cluster snapshot. To share a manual cluster snapshot with other Amazon Web Services accounts, specify restore as the AttributeName, and use the ValuesToAdd parameter to add a list of IDs of the Amazon Web Services accounts that are authorized to restore the manual cluster snapshot. Use the value all to make the manual cluster snapshot public, which means that it can be copied or restored by all Amazon Web Services accounts. Do not add the all value for any manual cluster snapshots that contain private information that you don't want available to all Amazon Web Services accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized Amazon Web Services account IDs for the ValuesToAdd parameter. You can't use all as a value for that parameter in this case.
#
# GET /
# operationId: GET_ModifyDBClusterSnapshotAttribute
export def "get-modify-db-cluster-snapshot-attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier for the cluster snapshot to modify the attributes for. (required)
  --attribute-name: string # The name of the cluster snapshot attribute to modify. To manage authorization for other Amazon Web Services accounts to copy or restore a manual cluster snapshot, set this value to restore. (required)
  --values-to-add: list<string> # A list of cluster snapshot attributes to add to the attribute specified by AttributeName. To authorize other Amazon Web Services accounts to copy or restore a manual cluster snapshot, set this list to include one or more Amazon Web Services account IDs. To make the manual cluster snapshot restorable by any Amazon Web Services account, set it to all. Do not add the all value for any manual cluster snapshots that contain private information that you don't want to be available to all Amazon Web Services accounts.
  --values-to-remove: list<string> # A list of cluster snapshot attributes to remove from the attribute specified by AttributeName. To remove authorization for other Amazon Web Services accounts to copy or restore a manual cluster snapshot, set this list to include one or more Amazon Web Services account identifiers. To remove authorization for any Amazon Web Services account to copy or restore the cluster snapshot, set it to all . If you specify all, an Amazon Web Services account whose account ID is explicitly added to the restore attribute can still copy or restore a manual cluster snapshot.
  --action: string@action-completer-39 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterSnapshotIdentifier, var: db_cluster_snapshot_identifier, required: true}, {name: AttributeName, var: attribute_name, required: true}, {name: ValuesToAdd, var: values_to_add, style: multi}, {name: ValuesToRemove, var: values_to_remove, style: multi}, {name: Action, var: action, required: true, default: ModifyDBClusterSnapshotAttribute}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_snapshot_identifier: $db_cluster_snapshot_identifier, attribute_name: $attribute_name, values_to_add: $values_to_add, values_to_remove: $values_to_remove, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an attribute and values to, or removes an attribute and values from, a manual cluster snapshot. To share a manual cluster snapshot with other Amazon Web Services accounts, specify restore as the AttributeName, and use the ValuesToAdd parameter to add a list of IDs of the Amazon Web Services accounts that are authorized to restore the manual cluster snapshot. Use the value all to make the manual cluster snapshot public, which means that it can be copied or restored by all Amazon Web Services accounts. Do not add the all value for any manual cluster snapshots that contain private information that you don't want available to all Amazon Web Services accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized Amazon Web Services account IDs for the ValuesToAdd parameter. You can't use all as a value for that parameter in this case.
#
# POST /
# operationId: POST_ModifyDBClusterSnapshotAttribute
export def "post-modify-db-cluster-snapshot-attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-39 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ModifyDBClusterSnapshotAttribute}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
#
# GET /
# operationId: GET_ModifyDBInstance
export def "get-modify-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The instance identifier. This value is stored as a lowercase string. Constraints: Must match the identifier of an existing DBInstance. (required)
  --db-instance-class: string # The new compute and memory capacity of the instance; for example, db.r5.large. Not all instance classes are available in all Amazon Web Services Regions. If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless ApplyImmediately is specified as true for this request. Default: Uses existing setting.
  --apply-immediately: oneof<nothing, bool> # Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the PreferredMaintenanceWindow setting for the instance. If this parameter is set to false, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot. Default: false
  --preferred-maintenance-window: string # The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied. Default: Uses existing setting. Format: ddd:hh24:mi-ddd:hh24:mi Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun Constraints: Must be at least 30 minutes.
  --auto-minor-version-upgrade: oneof<nothing, bool> # This parameter does not apply to Amazon DocumentDB. Amazon DocumentDB does not perform minor version upgrades regardless of the value set.
  --new-db-instance-identifier: string # The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set Apply Immediately to true. It occurs during the next maintenance window if you set Apply Immediately to false. This value is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: mydbinstance
  --ca-certificate-identifier: string # Indicates the certificate that needs to be associated with the instance.
  --copy-tags-to-snapshot: oneof<nothing, bool> # A value that indicates whether to copy all tags from the DB instance to snapshots of the DB instance. By default, tags are not copied.
  --promotion-tier: int # A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance. Default: 1 Valid values: 0-15
  --enable-performance-insights: oneof<nothing, bool> # A value that indicates whether to enable Performance Insights for the DB Instance. For more information, see Using Amazon Performance Insights (https://docs.aws.amazon.com/documentdb/latest/developerguide/performance-insights.html).
  --performance-insights-kms-key-id: string # The KMS key identifier for encryption of Performance Insights data. The KMS key identifier is the key ARN, key ID, alias ARN, or alias name for the KMS key. If you do not specify a value for PerformanceInsightsKMSKeyId, then Amazon DocumentDB uses your default KMS key. There is a default KMS key for your Amazon Web Services account. Your Amazon Web Services account has a different default KMS key for each Amazon Web Services region.
  --action: string@action-completer-40 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBInstanceIdentifier, var: db_instance_identifier, required: true}, {name: DBInstanceClass, var: db_instance_class}, {name: ApplyImmediately, var: apply_immediately}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: NewDBInstanceIdentifier, var: new_db_instance_identifier}, {name: CACertificateIdentifier, var: ca_certificate_identifier}, {name: CopyTagsToSnapshot, var: copy_tags_to_snapshot}, {name: PromotionTier, var: promotion_tier}, {name: EnablePerformanceInsights, var: enable_performance_insights}, {name: PerformanceInsightsKMSKeyId, var: performance_insights_kms_key_id}, {name: Action, var: action, required: true, default: ModifyDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_instance_identifier: $db_instance_identifier, db_instance_class: $db_instance_class, apply_immediately: $apply_immediately, preferred_maintenance_window: $preferred_maintenance_window, auto_minor_version_upgrade: $auto_minor_version_upgrade, new_db_instance_identifier: $new_db_instance_identifier, ca_certificate_identifier: $ca_certificate_identifier, copy_tags_to_snapshot: $copy_tags_to_snapshot, promotion_tier: $promotion_tier, enable_performance_insights: $enable_performance_insights, performance_insights_kms_key_id: $performance_insights_kms_key_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
#
# POST /
# operationId: POST_ModifyDBInstance
export def "post-modify-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-40 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ModifyDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the Amazon Web Services Region.
#
# GET /
# operationId: GET_ModifyDBSubnetGroup
export def "get-modify-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. Constraints: Must match the name of an existing DBSubnetGroup. Must not be default. Example: mySubnetgroup (required)
  --db-subnet-group-description: string # The description for the subnet group.
  --subnet-ids: list<string> # The Amazon EC2 subnet IDs for the subnet group. (required)
  --action: string@action-completer-41 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBSubnetGroupName, var: db_subnet_group_name, required: true}, {name: DBSubnetGroupDescription, var: db_subnet_group_description}, {name: SubnetIds, var: subnet_ids, style: multi, required: true}, {name: Action, var: action, required: true, default: ModifyDBSubnetGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_subnet_group_name: $db_subnet_group_name, db_subnet_group_description: $db_subnet_group_description, subnet_ids: $subnet_ids, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the Amazon Web Services Region.
#
# POST /
# operationId: POST_ModifyDBSubnetGroup
export def "post-modify-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-41 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ModifyDBSubnetGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing Amazon DocumentDB event notification subscription.
#
# GET /
# operationId: GET_ModifyEventSubscription
export def "get-modify-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the Amazon DocumentDB event notification subscription. (required)
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the SNS topic created for event notification. The ARN is created by Amazon SNS when you create a topic and subscribe to it.
  --source-type: string # The type of source that is generating the events. For example, if you want to be notified of events generated by an instance, set this parameter to db-instance. If this value is not specified, all events are returned. Valid values: db-instance, db-parameter-group, db-security-group
  --event-categories: list<string> # A list of event categories for a SourceType that you want to subscribe to.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription.
  --action: string@action-completer-42 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SubscriptionName, var: subscription_name, required: true}, {name: SnsTopicArn, var: sns_topic_arn}, {name: SourceType, var: source_type}, {name: EventCategories, var: event_categories, style: multi}, {name: Enabled, var: enabled}, {name: Action, var: action, required: true, default: ModifyEventSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_name: $subscription_name, sns_topic_arn: $sns_topic_arn, source_type: $source_type, event_categories: $event_categories, enabled: $enabled, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing Amazon DocumentDB event notification subscription.
#
# POST /
# operationId: POST_ModifyEventSubscription
export def "post-modify-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-42 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ModifyEventSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a setting for an Amazon DocumentDB global cluster. You can change one or more configuration parameters (for example: deletion protection), or the global cluster identifier by specifying these parameters and the new values in the request. This action only applies to Amazon DocumentDB clusters.
#
# GET /
# operationId: GET_ModifyGlobalCluster
export def "get-modify-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The identifier for the global cluster being modified. This parameter isn't case-sensitive. Constraints: Must match the identifier of an existing global cluster. (required)
  --new-global-cluster-identifier: string # The new identifier for a global cluster when you modify a global cluster. This value is stored as a lowercase string. Must contain from 1 to 63 letters, numbers, or hyphens The first character must be a letter Can't end with a hyphen or contain two consecutive hyphens Example: my-cluster2
  --deletion-protection: oneof<nothing, bool> # Indicates if the global cluster has deletion protection enabled. The global cluster can't be deleted when deletion protection is enabled.
  --action: string@action-completer-43 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: GlobalClusterIdentifier, var: global_cluster_identifier, required: true}, {name: NewGlobalClusterIdentifier, var: new_global_cluster_identifier}, {name: DeletionProtection, var: deletion_protection}, {name: Action, var: action, required: true, default: ModifyGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_cluster_identifier: $global_cluster_identifier, new_global_cluster_identifier: $new_global_cluster_identifier, deletion_protection: $deletion_protection, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a setting for an Amazon DocumentDB global cluster. You can change one or more configuration parameters (for example: deletion protection), or the global cluster identifier by specifying these parameters and the new values in the request. This action only applies to Amazon DocumentDB clusters.
#
# POST /
# operationId: POST_ModifyGlobalCluster
export def "post-modify-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-43 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ModifyGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to rebooting.
#
# GET /
# operationId: GET_RebootDBInstance
export def "get-reboot-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The instance identifier. This parameter is stored as a lowercase string. Constraints: Must match the identifier of an existing DBInstance. (required)
  --force-failover: oneof<nothing, bool> # When true, the reboot is conducted through a Multi-AZ failover. Constraint: You can't specify true if the instance is not configured for Multi-AZ.
  --action: string@action-completer-44 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBInstanceIdentifier, var: db_instance_identifier, required: true}, {name: ForceFailover, var: force_failover}, {name: Action, var: action, required: true, default: RebootDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_instance_identifier: $db_instance_identifier, force_failover: $force_failover, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to rebooting.
#
# POST /
# operationId: POST_RebootDBInstance
export def "post-reboot-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-44 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RebootDBInstance}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches an Amazon DocumentDB secondary cluster from a global cluster. The cluster becomes a standalone cluster with read-write capability instead of being read-only and receiving data from a primary in a different region. This action only applies to Amazon DocumentDB clusters.
#
# GET /
# operationId: GET_RemoveFromGlobalCluster
export def "get-remove-from-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The cluster identifier to detach from the Amazon DocumentDB global cluster. (required)
  --db-cluster-identifier: string # The Amazon Resource Name (ARN) identifying the cluster that was detached from the Amazon DocumentDB global cluster. (required)
  --action: string@action-completer-45 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: GlobalClusterIdentifier, var: global_cluster_identifier, required: true}, {name: DbClusterIdentifier, var: db_cluster_identifier, required: true}, {name: Action, var: action, required: true, default: RemoveFromGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_cluster_identifier: $global_cluster_identifier, db_cluster_identifier: $db_cluster_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches an Amazon DocumentDB secondary cluster from a global cluster. The cluster becomes a standalone cluster with read-write capability instead of being read-only and receiving data from a primary in a different region. This action only applies to Amazon DocumentDB clusters.
#
# POST /
# operationId: POST_RemoveFromGlobalCluster
export def "post-remove-from-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-45 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RemoveFromGlobalCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a source identifier from an existing Amazon DocumentDB event notification subscription.
#
# GET /
# operationId: GET_RemoveSourceIdentifierFromSubscription
export def "get-remove-source-identifier-from-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the Amazon DocumentDB event notification subscription that you want to remove a source identifier from. (required)
  --source-identifier: string # The source identifier to be removed from the subscription, such as the instance identifier for an instance, or the name of a security group. (required)
  --action: string@action-completer-46 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: SubscriptionName, var: subscription_name, required: true}, {name: SourceIdentifier, var: source_identifier, required: true}, {name: Action, var: action, required: true, default: RemoveSourceIdentifierFromSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_name: $subscription_name, source_identifier: $source_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a source identifier from an existing Amazon DocumentDB event notification subscription.
#
# POST /
# operationId: POST_RemoveSourceIdentifierFromSubscription
export def "post-remove-source-identifier-from-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-46 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RemoveSourceIdentifierFromSubscription}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes metadata tags from an Amazon DocumentDB resource.
#
# GET /
# operationId: GET_RemoveTagsFromResource
export def "get-remove-tags-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN). (required)
  --tag-keys: list<string> # The tag key (name) of the tag to be removed. (required)
  --action: string@action-completer-47 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: ResourceName, var: resource_name, required: true}, {name: TagKeys, var: tag_keys, style: multi, required: true}, {name: Action, var: action, required: true, default: RemoveTagsFromResource}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, tag_keys: $tag_keys, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes metadata tags from an Amazon DocumentDB resource.
#
# POST /
# operationId: POST_RemoveTagsFromResource
export def "post-remove-tags-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-47 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RemoveTagsFromResource}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: ParameterName and ApplyMethod. To reset the entire cluster parameter group, specify the DBClusterParameterGroupName and ResetAllParameters parameters. When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to pending-reboot to take effect on the next DB instance reboot.
#
# GET /
# operationId: GET_ResetDBClusterParameterGroup
export def "get-reset-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the cluster parameter group to reset. (required)
  --reset-all-parameters: oneof<nothing, bool> # A value that is set to true to reset all parameters in the cluster parameter group to their default values, and false otherwise. You can't use this parameter if there is a list of parameter names specified for the Parameters parameter.
  --parameters: list # A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the ResetAllParameters parameter is set to true.
  --action: string@action-completer-48 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name, required: true}, {name: ResetAllParameters, var: reset_all_parameters}, {name: Parameters, var: parameters, style: multi}, {name: Action, var: action, required: true, default: ResetDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_parameter_group_name: $db_cluster_parameter_group_name, reset_all_parameters: $reset_all_parameters, parameters: $parameters, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: ParameterName and ApplyMethod. To reset the entire cluster parameter group, specify the DBClusterParameterGroupName and ResetAllParameters parameters. When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to pending-reboot to take effect on the next DB instance reboot.
#
# POST /
# operationId: POST_ResetDBClusterParameterGroup
export def "post-reset-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-48 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ResetDBClusterParameterGroup}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new cluster from a snapshot or cluster snapshot. If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group. If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.
#
# GET /
# operationId: GET_RestoreDBClusterFromSnapshot
export def "get-restore-db-cluster-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability-zones: list<string> # Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  --db-cluster-identifier: string # The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-snapshot-id (required)
  --snapshot-identifier: string # The identifier for the snapshot or cluster snapshot to restore from. You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot. Constraints: Must match the identifier of an existing snapshot. (required)
  --engine: string # The database engine to use for the new cluster. Default: The same as source. Constraint: Must be compatible with the engine of the source. (required)
  --engine-version: string # The version of the database engine to use for the new cluster.
  --port: int # The port number on which the new cluster accepts connections. Constraints: Must be a value from 1150 to 65535. Default: The same port as the original cluster.
  --db-subnet-group-name: string # The name of the subnet group to use for the new cluster. Constraints: If provided, must match the name of an existing DBSubnetGroup. Example: mySubnetgroup
  --vpc-security-group-ids: list<string> # A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  --tags: list # The tags to be assigned to the restored cluster.
  --kms-key-id: string # The KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot. The KMS key identifier is the Amazon Resource Name (ARN) for the KMS encryption key. If you are restoring a cluster with the same Amazon Web Services account that owns the KMS encryption key used to encrypt the new cluster, then you can use the KMS key alias instead of the ARN for the KMS encryption key. If you do not specify a value for the KmsKeyId parameter, then the following occurs: If the snapshot or cluster snapshot in SnapshotIdentifier is encrypted, then the restored cluster is encrypted using the KMS key that was used to encrypt the snapshot or the cluster snapshot. If the snapshot or the cluster snapshot in SnapshotIdentifier is not encrypted, then the restored DB cluster is not encrypted.
  --enable-cloudwatch-logs-exports: list<string> # A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  --deletion-protection: oneof<nothing, bool> # Specifies whether this cluster can be deleted. If DeletionProtection is enabled, the cluster cannot be deleted unless it is modified and DeletionProtection is disabled. DeletionProtection protects clusters from being accidentally deleted.
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group to associate with this DB cluster. Type: String. Required: No. If this argument is omitted, the default DB cluster parameter group is used. If supplied, must match the name of an existing default DB cluster parameter group. The string must consist of from 1 to 255 letters, numbers or hyphens. Its first character must be a letter, and it cannot end with a hyphen or contain two consecutive hyphens.
  --action: string@action-completer-49 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AvailabilityZones, var: availability_zones, style: multi}, {name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: SnapshotIdentifier, var: snapshot_identifier, required: true}, {name: Engine, var: engine, required: true}, {name: EngineVersion, var: engine_version}, {name: Port, var: port}, {name: DBSubnetGroupName, var: db_subnet_group_name}, {name: VpcSecurityGroupIds, var: vpc_security_group_ids, style: multi}, {name: Tags, var: tags, style: multi}, {name: KmsKeyId, var: kms_key_id}, {name: EnableCloudwatchLogsExports, var: enable_cloudwatch_logs_exports, style: multi}, {name: DeletionProtection, var: deletion_protection}, {name: DBClusterParameterGroupName, var: db_cluster_parameter_group_name}, {name: Action, var: action, required: true, default: RestoreDBClusterFromSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    availability_zones: $availability_zones, db_cluster_identifier: $db_cluster_identifier, snapshot_identifier: $snapshot_identifier, engine: $engine, engine_version: $engine_version, port: $port, db_subnet_group_name: $db_subnet_group_name, vpc_security_group_ids: $vpc_security_group_ids, tags: $tags, kms_key_id: $kms_key_id, enable_cloudwatch_logs_exports: $enable_cloudwatch_logs_exports, deletion_protection: $deletion_protection, db_cluster_parameter_group_name: $db_cluster_parameter_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new cluster from a snapshot or cluster snapshot. If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group. If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.
#
# POST /
# operationId: POST_RestoreDBClusterFromSnapshot
export def "post-restore-db-cluster-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-49 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RestoreDBClusterFromSnapshot}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a cluster to an arbitrary point in time. Users can restore to any point in time before LatestRestorableTime for up to BackupRetentionPeriod days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group.
#
# GET /
# operationId: GET_RestoreDBClusterToPointInTime
export def "get-restore-db-cluster-to-point-in-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The name of the new cluster to be created. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. (required)
  --restore-type: string # The type of restore to be performed. You can specify one of the following values: full-copy - The new DB cluster is restored as a full copy of the source DB cluster. copy-on-write - The new DB cluster is restored as a clone of the source DB cluster. Constraints: You can't specify copy-on-write if the engine version of the source DB cluster is earlier than 1.11. If you don't specify a RestoreType value, then the new DB cluster is restored as a full copy of the source DB cluster.
  --source-db-cluster-identifier: string # The identifier of the source cluster from which to restore. Constraints: Must match the identifier of an existing DBCluster. (required)
  --restore-to-time: string # The date and time to restore the cluster to. Valid values: A time in Universal Coordinated Time (UTC) format. Constraints: Must be before the latest restorable time for the instance. Must be specified if the UseLatestRestorableTime parameter is not provided. Cannot be specified if the UseLatestRestorableTime parameter is true. Cannot be specified if the RestoreType parameter is copy-on-write. Example: 2015-03-07T23:45:00Z (format: date-time)
  --use-latest-restorable-time: oneof<nothing, bool> # A value that is set to true to restore the cluster to the latest restorable backup time, and false otherwise. Default: false Constraints: Cannot be specified if the RestoreToTime parameter is provided.
  --port: int # The port number on which the new cluster accepts connections. Constraints: Must be a value from 1150 to 65535. Default: The default port for the engine.
  --db-subnet-group-name: string # The subnet group name to use for the new cluster. Constraints: If provided, must match the name of an existing DBSubnetGroup. Example: mySubnetgroup
  --vpc-security-group-ids: list<string> # A list of VPC security groups that the new cluster belongs to.
  --tags: list # The tags to be assigned to the restored cluster.
  --kms-key-id: string # The KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster. The KMS key identifier is the Amazon Resource Name (ARN) for the KMS encryption key. If you are restoring a cluster with the same Amazon Web Services account that owns the KMS encryption key used to encrypt the new cluster, then you can use the KMS key alias instead of the ARN for the KMS encryption key. You can restore to a new cluster and encrypt the new cluster with an KMS key that is different from the KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the KMS key identified by the KmsKeyId parameter. If you do not specify a value for the KmsKeyId parameter, then the following occurs: If the cluster is encrypted, then the restored cluster is encrypted using the KMS key that was used to encrypt the source cluster. If the cluster is not encrypted, then the restored cluster is not encrypted. If DBClusterIdentifier refers to a cluster that is not encrypted, then the restore request is rejected.
  --enable-cloudwatch-logs-exports: list<string> # A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  --deletion-protection: oneof<nothing, bool> # Specifies whether this cluster can be deleted. If DeletionProtection is enabled, the cluster cannot be deleted unless it is modified and DeletionProtection is disabled. DeletionProtection protects clusters from being accidentally deleted.
  --action: string@action-completer-50 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: RestoreType, var: restore_type}, {name: SourceDBClusterIdentifier, var: source_db_cluster_identifier, required: true}, {name: RestoreToTime, var: restore_to_time}, {name: UseLatestRestorableTime, var: use_latest_restorable_time}, {name: Port, var: port}, {name: DBSubnetGroupName, var: db_subnet_group_name}, {name: VpcSecurityGroupIds, var: vpc_security_group_ids, style: multi}, {name: Tags, var: tags, style: multi}, {name: KmsKeyId, var: kms_key_id}, {name: EnableCloudwatchLogsExports, var: enable_cloudwatch_logs_exports, style: multi}, {name: DeletionProtection, var: deletion_protection}, {name: Action, var: action, required: true, default: RestoreDBClusterToPointInTime}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, restore_type: $restore_type, source_db_cluster_identifier: $source_db_cluster_identifier, restore_to_time: $restore_to_time, use_latest_restorable_time: $use_latest_restorable_time, port: $port, db_subnet_group_name: $db_subnet_group_name, vpc_security_group_ids: $vpc_security_group_ids, tags: $tags, kms_key_id: $kms_key_id, enable_cloudwatch_logs_exports: $enable_cloudwatch_logs_exports, deletion_protection: $deletion_protection, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a cluster to an arbitrary point in time. Users can restore to any point in time before LatestRestorableTime for up to BackupRetentionPeriod days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group.
#
# POST /
# operationId: POST_RestoreDBClusterToPointInTime
export def "post-restore-db-cluster-to-point-in-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-50 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RestoreDBClusterToPointInTime}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts the stopped cluster that is specified by DBClusterIdentifier. For more information, see Stopping and Starting an Amazon DocumentDB Cluster (https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html).
#
# GET /
# operationId: GET_StartDBCluster
export def "get-start-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The identifier of the cluster to restart. Example: docdb-2019-05-28-15-24-52 (required)
  --action: string@action-completer-51 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: Action, var: action, required: true, default: StartDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts the stopped cluster that is specified by DBClusterIdentifier. For more information, see Stopping and Starting an Amazon DocumentDB Cluster (https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html).
#
# POST /
# operationId: POST_StartDBCluster
export def "post-start-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-51 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: StartDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the running cluster that is specified by DBClusterIdentifier. The cluster must be in the available state. For more information, see Stopping and Starting an Amazon DocumentDB Cluster (https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html).
#
# GET /
# operationId: GET_StopDBCluster
export def "get-stop-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The identifier of the cluster to stop. Example: docdb-2019-05-28-15-24-52 (required)
  --action: string@action-completer-52 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: DBClusterIdentifier, var: db_cluster_identifier, required: true}, {name: Action, var: action, required: true, default: StopDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    db_cluster_identifier: $db_cluster_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the running cluster that is specified by DBClusterIdentifier. The cluster must be in the available state. For more information, see Stopping and Starting an Amazon DocumentDB Cluster (https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html).
#
# POST /
# operationId: POST_StopDBCluster
export def "post-stop-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-52 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: StopDBCluster}, {name: Version, var: version, required: true, default: "2014-10-31"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
