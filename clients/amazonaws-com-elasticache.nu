# Auto-generated client for Amazon ElastiCache v2015-02-02
# Source: https://api.apis.guru/v2/specs/amazonaws.com/elasticache/2015-02-02/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTICACHE_TOKEN

const CLIENT = {
  base_url: "http://elasticache.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_ELASTICACHE_TOKEN"
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

def base-url-completer [] { ["http://elasticache.us-east-1.amazonaws.com" "http://elasticache.us-east-2.amazonaws.com" "http://elasticache.us-west-1.amazonaws.com" "http://elasticache.us-west-2.amazonaws.com" "http://elasticache.us-gov-west-1.amazonaws.com" "http://elasticache.us-gov-east-1.amazonaws.com" "http://elasticache.ca-central-1.amazonaws.com" "http://elasticache.eu-north-1.amazonaws.com" "http://elasticache.eu-west-1.amazonaws.com" "http://elasticache.eu-west-2.amazonaws.com" "http://elasticache.eu-west-3.amazonaws.com" "http://elasticache.eu-central-1.amazonaws.com" "http://elasticache.eu-south-1.amazonaws.com" "http://elasticache.af-south-1.amazonaws.com" "http://elasticache.ap-northeast-1.amazonaws.com" "http://elasticache.ap-northeast-2.amazonaws.com" "http://elasticache.ap-northeast-3.amazonaws.com" "http://elasticache.ap-southeast-1.amazonaws.com" "http://elasticache.ap-southeast-2.amazonaws.com" "http://elasticache.ap-east-1.amazonaws.com" "http://elasticache.ap-south-1.amazonaws.com" "http://elasticache.sa-east-1.amazonaws.com" "http://elasticache.me-south-1.amazonaws.com" "https://elasticache.us-east-1.amazonaws.com" "https://elasticache.us-east-2.amazonaws.com" "https://elasticache.us-west-1.amazonaws.com" "https://elasticache.us-west-2.amazonaws.com" "https://elasticache.us-gov-west-1.amazonaws.com" "https://elasticache.us-gov-east-1.amazonaws.com" "https://elasticache.ca-central-1.amazonaws.com" "https://elasticache.eu-north-1.amazonaws.com" "https://elasticache.eu-west-1.amazonaws.com" "https://elasticache.eu-west-2.amazonaws.com" "https://elasticache.eu-west-3.amazonaws.com" "https://elasticache.eu-central-1.amazonaws.com" "https://elasticache.eu-south-1.amazonaws.com" "https://elasticache.af-south-1.amazonaws.com" "https://elasticache.ap-northeast-1.amazonaws.com" "https://elasticache.ap-northeast-2.amazonaws.com" "https://elasticache.ap-northeast-3.amazonaws.com" "https://elasticache.ap-southeast-1.amazonaws.com" "https://elasticache.ap-southeast-2.amazonaws.com" "https://elasticache.ap-east-1.amazonaws.com" "https://elasticache.ap-south-1.amazonaws.com" "https://elasticache.sa-east-1.amazonaws.com" "https://elasticache.me-south-1.amazonaws.com" "http://elasticache.cn-north-1.amazonaws.com.cn" "http://elasticache.cn-northwest-1.amazonaws.com.cn" "https://elasticache.cn-north-1.amazonaws.com.cn" "https://elasticache.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AddTagsToResource"] }
def version-completer [] { ["2015-02-02"] }
def action-completer-1 [] { ["AuthorizeCacheSecurityGroupIngress"] }
def action-completer-2 [] { ["BatchApplyUpdateAction"] }
def action-completer-3 [] { ["BatchStopUpdateAction"] }
def action-completer-4 [] { ["CompleteMigration"] }
def action-completer-5 [] { ["CopySnapshot"] }
def az-mode-completer [] { ["cross-az" "single-az"] }
def outpost-mode-completer [] { ["cross-outpost" "single-outpost"] }
def network-type-completer [] { ["dual_stack" "ipv4" "ipv6"] }
def ip-discovery-completer [] { ["ipv4" "ipv6"] }
def action-completer-6 [] { ["CreateCacheCluster"] }
def action-completer-7 [] { ["CreateCacheParameterGroup"] }
def action-completer-8 [] { ["CreateCacheSecurityGroup"] }
def action-completer-9 [] { ["CreateCacheSubnetGroup"] }
def action-completer-10 [] { ["CreateGlobalReplicationGroup"] }
def transit-encryption-mode-completer [] { ["preferred" "required"] }
def action-completer-11 [] { ["CreateReplicationGroup"] }
def action-completer-12 [] { ["CreateSnapshot"] }
def action-completer-13 [] { ["CreateUser"] }
def action-completer-14 [] { ["CreateUserGroup"] }
def action-completer-15 [] { ["DecreaseNodeGroupsInGlobalReplicationGroup"] }
def action-completer-16 [] { ["DecreaseReplicaCount"] }
def action-completer-17 [] { ["DeleteCacheCluster"] }
def action-completer-18 [] { ["DeleteCacheParameterGroup"] }
def action-completer-19 [] { ["DeleteCacheSecurityGroup"] }
def action-completer-20 [] { ["DeleteCacheSubnetGroup"] }
def action-completer-21 [] { ["DeleteGlobalReplicationGroup"] }
def action-completer-22 [] { ["DeleteReplicationGroup"] }
def action-completer-23 [] { ["DeleteSnapshot"] }
def action-completer-24 [] { ["DeleteUser"] }
def action-completer-25 [] { ["DeleteUserGroup"] }
def action-completer-26 [] { ["DescribeCacheClusters"] }
def action-completer-27 [] { ["DescribeCacheEngineVersions"] }
def action-completer-28 [] { ["DescribeCacheParameterGroups"] }
def action-completer-29 [] { ["DescribeCacheParameters"] }
def action-completer-30 [] { ["DescribeCacheSecurityGroups"] }
def action-completer-31 [] { ["DescribeCacheSubnetGroups"] }
def action-completer-32 [] { ["DescribeEngineDefaultParameters"] }
def source-type-completer [] { ["cache-cluster" "cache-parameter-group" "cache-security-group" "cache-subnet-group" "replication-group" "user" "user-group"] }
def action-completer-33 [] { ["DescribeEvents"] }
def action-completer-34 [] { ["DescribeGlobalReplicationGroups"] }
def action-completer-35 [] { ["DescribeReplicationGroups"] }
def action-completer-36 [] { ["DescribeReservedCacheNodes"] }
def action-completer-37 [] { ["DescribeReservedCacheNodesOfferings"] }
def action-completer-38 [] { ["DescribeServiceUpdates"] }
def action-completer-39 [] { ["DescribeSnapshots"] }
def action-completer-40 [] { ["DescribeUpdateActions"] }
def action-completer-41 [] { ["DescribeUserGroups"] }
def action-completer-42 [] { ["DescribeUsers"] }
def action-completer-43 [] { ["DisassociateGlobalReplicationGroup"] }
def action-completer-44 [] { ["FailoverGlobalReplicationGroup"] }
def action-completer-45 [] { ["IncreaseNodeGroupsInGlobalReplicationGroup"] }
def action-completer-46 [] { ["IncreaseReplicaCount"] }
def action-completer-47 [] { ["ListAllowedNodeTypeModifications"] }
def action-completer-48 [] { ["ListTagsForResource"] }
def auth-token-update-strategy-completer [] { ["DELETE" "ROTATE" "SET"] }
def action-completer-49 [] { ["ModifyCacheCluster"] }
def action-completer-50 [] { ["ModifyCacheParameterGroup"] }
def action-completer-51 [] { ["ModifyCacheSubnetGroup"] }
def action-completer-52 [] { ["ModifyGlobalReplicationGroup"] }
def action-completer-53 [] { ["ModifyReplicationGroup"] }
def action-completer-54 [] { ["ModifyReplicationGroupShardConfiguration"] }
def action-completer-55 [] { ["ModifyUser"] }
def action-completer-56 [] { ["ModifyUserGroup"] }
def action-completer-57 [] { ["PurchaseReservedCacheNodesOffering"] }
def action-completer-58 [] { ["RebalanceSlotsInGlobalReplicationGroup"] }
def action-completer-59 [] { ["RebootCacheCluster"] }
def action-completer-60 [] { ["RemoveTagsFromResource"] }
def action-completer-61 [] { ["ResetCacheParameterGroup"] }
def action-completer-62 [] { ["RevokeCacheSecurityGroupIngress"] }
def action-completer-63 [] { ["StartMigration"] }
def action-completer-64 [] { ["TestFailover"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-add-tags-to-resource" "post-add-tags-to-resource" "get-authorize-cache-security-group-ingress" "post-authorize-cache-security-group-ingress" "get-batch-apply-update-action" "post-batch-apply-update-action" "get-batch-stop-update-action" "post-batch-stop-update-action" "get-complete-migration" "post-complete-migration" "get-copy-snapshot" "post-copy-snapshot" "get-create-cache-cluster" "post-create-cache-cluster" "get-create-cache-parameter-group" "post-create-cache-parameter-group" "get-create-cache-security-group" "post-create-cache-security-group" "get-create-cache-subnet-group" "post-create-cache-subnet-group" "get-create-global-replication-group" "post-create-global-replication-group" "get-create-replication-group" "post-create-replication-group" "get-create-snapshot" "post-create-snapshot" "get-create-user" "post-create-user" "get-create-user-group" "post-create-user-group" "get-decrease-node-groups-in-global-replication-group" "post-decrease-node-groups-in-global-replication-group" "get-decrease-replica-count" "post-decrease-replica-count" "get-delete-cache-cluster" "post-delete-cache-cluster" "get-delete-cache-parameter-group" "post-delete-cache-parameter-group" "get-delete-cache-security-group" "post-delete-cache-security-group" "get-delete-cache-subnet-group" "post-delete-cache-subnet-group" "get-delete-global-replication-group" "post-delete-global-replication-group" "get-delete-replication-group" "post-delete-replication-group" "get-delete-snapshot" "post-delete-snapshot" "get-delete-user" "post-delete-user" "get-delete-user-group" "post-delete-user-group" "get-describe-cache-clusters" "post-describe-cache-clusters" "get-describe-cache-engine-versions" "post-describe-cache-engine-versions" "get-describe-cache-parameter-groups" "post-describe-cache-parameter-groups" "get-describe-cache-parameters" "post-describe-cache-parameters" "get-describe-cache-security-groups" "post-describe-cache-security-groups" "get-describe-cache-subnet-groups" "post-describe-cache-subnet-groups" "get-describe-engine-default-parameters" "post-describe-engine-default-parameters" "get-describe-events" "post-describe-events" "get-describe-global-replication-groups" "post-describe-global-replication-groups" "get-describe-replication-groups" "post-describe-replication-groups" "get-describe-reserved-cache-nodes" "post-describe-reserved-cache-nodes" "get-describe-reserved-cache-nodes-offerings" "post-describe-reserved-cache-nodes-offerings" "get-describe-service-updates" "post-describe-service-updates" "get-describe-snapshots" "post-describe-snapshots" "get-describe-update-actions" "post-describe-update-actions" "get-describe-user-groups" "post-describe-user-groups" "get-describe-users" "post-describe-users" "get-disassociate-global-replication-group" "post-disassociate-global-replication-group" "get-failover-global-replication-group" "post-failover-global-replication-group" "get-increase-node-groups-in-global-replication-group" "post-increase-node-groups-in-global-replication-group" "get-increase-replica-count" "post-increase-replica-count" "get-list-allowed-node-type-modifications" "post-list-allowed-node-type-modifications" "get-list-tags-for-resource" "post-list-tags-for-resource" "get-modify-cache-cluster" "post-modify-cache-cluster" "get-modify-cache-parameter-group" "post-modify-cache-parameter-group" "get-modify-cache-subnet-group" "post-modify-cache-subnet-group" "get-modify-global-replication-group" "post-modify-global-replication-group" "get-modify-replication-group" "post-modify-replication-group" "get-modify-replication-group-shard-configuration" "post-modify-replication-group-shard-configuration" "get-modify-user" "post-modify-user" "get-modify-user-group" "post-modify-user-group" "get-purchase-reserved-cache-nodes-offering" "post-purchase-reserved-cache-nodes-offering" "get-rebalance-slots-in-global-replication-group" "post-rebalance-slots-in-global-replication-group" "get-reboot-cache-cluster" "post-reboot-cache-cluster" "get-remove-tags-from-resource" "post-remove-tags-from-resource" "get-reset-cache-parameter-group" "post-reset-cache-parameter-group" "get-revoke-cache-security-group-ingress" "post-revoke-cache-security-group-ingress" "get-start-migration" "post-start-migration" "get-test-failover" "post-test-failover" "commands"] | sort) } | get name | first)
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

# A tag is a key-value pair where the key and value are case-sensitive. You can use tags to categorize and track all your ElastiCache resources, with the exception of global replication group. When you add or remove tags on replication groups, those actions will be replicated to all nodes in the replication group. For more information, see Resource-level permissions (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.ResourceLevelPermissions.html). For example, you can use cost-allocation tags to your ElastiCache resources, Amazon generates a cost allocation report as a comma-separated value (CSV) file with your usage and costs aggregated by your tags. You can apply tags that represent business categories (such as cost centers, application names, or owners) to organize your costs across multiple services. For more information, see Using Cost Allocation Tags in Amazon ElastiCache (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Tagging.html) in the ElastiCache User Guide.
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
  --resource-name: string # The Amazon Resource Name (ARN) of the resource to which the tags are to be added, for example arn:aws:elasticache:us-west-2:0123456789:cluster:myCluster or arn:aws:elasticache:us-west-2:0123456789:snapshot:mySnapshot. ElastiCache resources are cluster and snapshot. For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html). (required)
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted. (required)
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
    query: [{name: ResourceName, var: resource_name, required: true}, {name: Tags, var: tags, style: multi, required: true}, {name: Action, var: action, required: true, default: AddTagsToResource}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A tag is a key-value pair where the key and value are case-sensitive. You can use tags to categorize and track all your ElastiCache resources, with the exception of global replication group. When you add or remove tags on replication groups, those actions will be replicated to all nodes in the replication group. For more information, see Resource-level permissions (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.ResourceLevelPermissions.html). For example, you can use cost-allocation tags to your ElastiCache resources, Amazon generates a cost allocation report as a comma-separated value (CSV) file with your usage and costs aggregated by your tags. You can apply tags that represent business categories (such as cost centers, application names, or owners) to organize your costs across multiple services. For more information, see Using Cost Allocation Tags in Amazon ElastiCache (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Tagging.html) in the ElastiCache User Guide.
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
    query: [{name: Action, var: action, required: true, default: AddTagsToResource}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Allows network ingress to a cache security group. Applications using ElastiCache must be running on Amazon EC2, and Amazon EC2 security groups are used as the authorization mechanism. You cannot authorize ingress from an Amazon EC2 security group in one region to an ElastiCache cluster in another region.
#
# GET /
# operationId: GET_AuthorizeCacheSecurityGroupIngress
export def "get-authorize-cache-security-group-ingress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-security-group-name: string # The cache security group that allows network ingress. (required)
  --ec2-security-group-name: string # The Amazon EC2 security group to be authorized for ingress to the cache security group. (required)
  --ec2-security-group-owner-id: string # The Amazon account number of the Amazon EC2 security group owner. Note that this is not the same thing as an Amazon access key ID - you must provide a valid Amazon account number for this parameter. (required)
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
    query: [{name: CacheSecurityGroupName, var: cache_security_group_name, required: true}, {name: EC2SecurityGroupName, var: ec2_security_group_name, required: true}, {name: EC2SecurityGroupOwnerId, var: ec2_security_group_owner_id, required: true}, {name: Action, var: action, required: true, default: AuthorizeCacheSecurityGroupIngress}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_security_group_name: $cache_security_group_name, ec2_security_group_name: $ec2_security_group_name, ec2_security_group_owner_id: $ec2_security_group_owner_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows network ingress to a cache security group. Applications using ElastiCache must be running on Amazon EC2, and Amazon EC2 security groups are used as the authorization mechanism. You cannot authorize ingress from an Amazon EC2 security group in one region to an ElastiCache cluster in another region.
#
# POST /
# operationId: POST_AuthorizeCacheSecurityGroupIngress
export def "post-authorize-cache-security-group-ingress" [
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
    query: [{name: Action, var: action, required: true, default: AuthorizeCacheSecurityGroupIngress}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Apply the service update. For more information on service updates and applying them, see Applying Service Updates (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/applying-updates.html).
#
# GET /
# operationId: GET_BatchApplyUpdateAction
export def "get-batch-apply-update-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-ids: list<string> # The replication group IDs
  --cache-cluster-ids: list<string> # The cache cluster IDs
  --service-update-name: string # The unique ID of the service update (required)
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
    query: [{name: ReplicationGroupIds, var: replication_group_ids, style: multi}, {name: CacheClusterIds, var: cache_cluster_ids, style: multi}, {name: ServiceUpdateName, var: service_update_name, required: true}, {name: Action, var: action, required: true, default: BatchApplyUpdateAction}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_ids: $replication_group_ids, cache_cluster_ids: $cache_cluster_ids, service_update_name: $service_update_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply the service update. For more information on service updates and applying them, see Applying Service Updates (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/applying-updates.html).
#
# POST /
# operationId: POST_BatchApplyUpdateAction
export def "post-batch-apply-update-action" [
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
    query: [{name: Action, var: action, required: true, default: BatchApplyUpdateAction}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Stop the service update. For more information on service updates and stopping them, see Stopping Service Updates (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/stopping-self-service-updates.html).
#
# GET /
# operationId: GET_BatchStopUpdateAction
export def "get-batch-stop-update-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-ids: list<string> # The replication group IDs
  --cache-cluster-ids: list<string> # The cache cluster IDs
  --service-update-name: string # The unique ID of the service update (required)
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
    query: [{name: ReplicationGroupIds, var: replication_group_ids, style: multi}, {name: CacheClusterIds, var: cache_cluster_ids, style: multi}, {name: ServiceUpdateName, var: service_update_name, required: true}, {name: Action, var: action, required: true, default: BatchStopUpdateAction}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_ids: $replication_group_ids, cache_cluster_ids: $cache_cluster_ids, service_update_name: $service_update_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop the service update. For more information on service updates and stopping them, see Stopping Service Updates (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/stopping-self-service-updates.html).
#
# POST /
# operationId: POST_BatchStopUpdateAction
export def "post-batch-stop-update-action" [
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
    query: [{name: Action, var: action, required: true, default: BatchStopUpdateAction}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Complete the migration of data.
#
# GET /
# operationId: GET_CompleteMigration
export def "get-complete-migration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The ID of the replication group to which data is being migrated. (required)
  --force: oneof<nothing, bool> # Forces the migration to stop without ensuring that data is in sync. It is recommended to use this option only to abort the migration and not recommended when application wants to continue migration to ElastiCache.
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: Force, var: force}, {name: Action, var: action, required: true, default: CompleteMigration}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, force: $force, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete the migration of data.
#
# POST /
# operationId: POST_CompleteMigration
export def "post-complete-migration" [
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
    query: [{name: Action, var: action, required: true, default: CompleteMigration}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Makes a copy of an existing snapshot. This operation is valid for Redis only. Users or groups that have permissions to use the CopySnapshot operation can create their own Amazon S3 buckets and copy snapshots to it. To control access to your snapshots, use an IAM policy to control who has the ability to use the CopySnapshot operation. For more information about using IAM to control the use of ElastiCache operations, see Exporting Snapshots (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html) and Authentication & Access Control (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.html). You could receive the following error messages. Error Messages Error Message: The S3 bucket %s is outside of the region. Solution: Create an Amazon S3 bucket in the same region as your snapshot. For more information, see Step 1: Create an Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-create-s3-bucket) in the ElastiCache User Guide. Error Message: The S3 bucket %s does not exist. Solution: Create an Amazon S3 bucket in the same region as your snapshot. For more information, see Step 1: Create an Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-create-s3-bucket) in the ElastiCache User Guide. Error Message: The S3 bucket %s is not owned by the authenticated user. Solution: Create an Amazon S3 bucket in the same region as your snapshot. For more information, see Step 1: Create an Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-create-s3-bucket) in the ElastiCache User Guide. Error Message: The authenticated user does not have sufficient permissions to perform the desired activity. Solution: Contact your system administrator to get the needed permissions. Error Message: The S3 bucket %s already contains an object with key %s. Solution: Give the TargetSnapshotName a new and unique value. If exporting a snapshot, you could alternatively create a new Amazon S3 bucket and use this same value for TargetSnapshotName. Error Message: ElastiCache has not been granted READ permissions %s on the S3 Bucket. Solution: Add List and Read permissions on the bucket. For more information, see Step 2: Grant ElastiCache Access to Your Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-grant-access) in the ElastiCache User Guide. Error Message: ElastiCache has not been granted WRITE permissions %s on the S3 Bucket. Solution: Add Upload/Delete permissions on the bucket. For more information, see Step 2: Grant ElastiCache Access to Your Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-grant-access) in the ElastiCache User Guide. Error Message: ElastiCache has not been granted READ_ACP permissions %s on the S3 Bucket. Solution: Add View Permissions on the bucket. For more information, see Step 2: Grant ElastiCache Access to Your Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-grant-access) in the ElastiCache User Guide.
#
# GET /
# operationId: GET_CopySnapshot
export def "get-copy-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-snapshot-name: string # The name of an existing snapshot from which to make a copy. (required)
  --target-snapshot-name: string # A name for the snapshot copy. ElastiCache does not permit overwriting a snapshot, therefore this name must be unique within its context - ElastiCache or an Amazon S3 bucket if exporting. (required)
  --target-bucket: string # The Amazon S3 bucket to which the snapshot is exported. This parameter is used only when exporting a snapshot for external access. When using this parameter to export a snapshot, be sure Amazon ElastiCache has the needed permissions to this S3 bucket. For more information, see Step 2: Grant ElastiCache Access to Your Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-grant-access) in the Amazon ElastiCache User Guide. For more information, see Exporting a Snapshot (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html) in the Amazon ElastiCache User Guide.
  --kms-key-id: string # The ID of the KMS key used to encrypt the target snapshot.
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
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
    query: [{name: SourceSnapshotName, var: source_snapshot_name, required: true}, {name: TargetSnapshotName, var: target_snapshot_name, required: true}, {name: TargetBucket, var: target_bucket}, {name: KmsKeyId, var: kms_key_id}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CopySnapshot}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_snapshot_name: $source_snapshot_name, target_snapshot_name: $target_snapshot_name, target_bucket: $target_bucket, kms_key_id: $kms_key_id, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Makes a copy of an existing snapshot. This operation is valid for Redis only. Users or groups that have permissions to use the CopySnapshot operation can create their own Amazon S3 buckets and copy snapshots to it. To control access to your snapshots, use an IAM policy to control who has the ability to use the CopySnapshot operation. For more information about using IAM to control the use of ElastiCache operations, see Exporting Snapshots (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html) and Authentication & Access Control (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.html). You could receive the following error messages. Error Messages Error Message: The S3 bucket %s is outside of the region. Solution: Create an Amazon S3 bucket in the same region as your snapshot. For more information, see Step 1: Create an Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-create-s3-bucket) in the ElastiCache User Guide. Error Message: The S3 bucket %s does not exist. Solution: Create an Amazon S3 bucket in the same region as your snapshot. For more information, see Step 1: Create an Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-create-s3-bucket) in the ElastiCache User Guide. Error Message: The S3 bucket %s is not owned by the authenticated user. Solution: Create an Amazon S3 bucket in the same region as your snapshot. For more information, see Step 1: Create an Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-create-s3-bucket) in the ElastiCache User Guide. Error Message: The authenticated user does not have sufficient permissions to perform the desired activity. Solution: Contact your system administrator to get the needed permissions. Error Message: The S3 bucket %s already contains an object with key %s. Solution: Give the TargetSnapshotName a new and unique value. If exporting a snapshot, you could alternatively create a new Amazon S3 bucket and use this same value for TargetSnapshotName. Error Message: ElastiCache has not been granted READ permissions %s on the S3 Bucket. Solution: Add List and Read permissions on the bucket. For more information, see Step 2: Grant ElastiCache Access to Your Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-grant-access) in the ElastiCache User Guide. Error Message: ElastiCache has not been granted WRITE permissions %s on the S3 Bucket. Solution: Add Upload/Delete permissions on the bucket. For more information, see Step 2: Grant ElastiCache Access to Your Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-grant-access) in the ElastiCache User Guide. Error Message: ElastiCache has not been granted READ_ACP permissions %s on the S3 Bucket. Solution: Add View Permissions on the bucket. For more information, see Step 2: Grant ElastiCache Access to Your Amazon S3 Bucket (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-exporting.html#backups-exporting-grant-access) in the ElastiCache User Guide.
#
# POST /
# operationId: POST_CopySnapshot
export def "post-copy-snapshot" [
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
    query: [{name: Action, var: action, required: true, default: CopySnapshot}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Creates a cluster. All nodes in the cluster run the same protocol-compliant cache engine software, either Memcached or Redis. This operation is not supported for Redis (cluster mode enabled) clusters.
#
# GET /
# operationId: GET_CreateCacheCluster
export def "get-create-cache-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-cluster-id: string # The node group (shard) identifier. This parameter is stored as a lowercase string. Constraints: A name must contain from 1 to 50 alphanumeric characters or hyphens. The first character must be a letter. A name cannot end with a hyphen or contain two consecutive hyphens. (required)
  --replication-group-id: string # The ID of the replication group to which this cluster should belong. If this parameter is specified, the cluster is added to the specified replication group as a read replica; otherwise, the cluster is a standalone primary that is not part of any replication group. If the specified replication group is Multi-AZ enabled and the Availability Zone is not specified, the cluster is created in Availability Zones that provide the best spread of read replicas across Availability Zones. This parameter is only valid if the Engine parameter is redis.
  --az-mode: string@az-mode-completer # Specifies whether the nodes in this Memcached cluster are created in a single Availability Zone or created across multiple Availability Zones in the cluster's region. This parameter is only supported for Memcached clusters. If the AZMode and PreferredAvailabilityZones are not specified, ElastiCache assumes single-az mode.
  --preferred-availability-zone: string # The EC2 Availability Zone in which the cluster is created. All nodes belonging to this cluster are placed in the preferred Availability Zone. If you want to create your nodes across multiple Availability Zones, use PreferredAvailabilityZones. Default: System chosen Availability Zone.
  --preferred-availability-zones: list<string> # A list of the Availability Zones in which cache nodes are created. The order of the zones in the list is not important. This option is only supported on Memcached. If you are creating your cluster in an Amazon VPC (recommended) you can only locate nodes in Availability Zones that are associated with the subnets in the selected subnet group. The number of Availability Zones listed must equal the value of NumCacheNodes. If you want all the nodes in the same Availability Zone, use PreferredAvailabilityZone instead, or repeat the Availability Zone multiple times in the list. Default: System chosen Availability Zones.
  --num-cache-nodes: int # The initial number of cache nodes that the cluster has. For clusters running Redis, this value must be 1. For clusters running Memcached, this value must be between 1 and 40. If you need more than 40 nodes for your Memcached cluster, please fill out the ElastiCache Limit Increase Request form at http://aws.amazon.com/contact-us/elasticache-node-limit-request/ (http://aws.amazon.com/contact-us/elasticache-node-limit-request/).
  --cache-node-type: string # The compute and memory capacity of the nodes in the node group (shard). The following node types are supported by ElastiCache. Generally speaking, the current generation types provide more memory and computational power at lower cost when compared to their equivalent previous generation counterparts. General purpose: Current generation: M6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward): cache.m6g.large, cache.m6g.xlarge, cache.m6g.2xlarge, cache.m6g.4xlarge, cache.m6g.8xlarge, cache.m6g.12xlarge, cache.m6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) M5 node types: cache.m5.large, cache.m5.xlarge, cache.m5.2xlarge, cache.m5.4xlarge, cache.m5.12xlarge, cache.m5.24xlarge M4 node types: cache.m4.large, cache.m4.xlarge, cache.m4.2xlarge, cache.m4.4xlarge, cache.m4.10xlarge T4g node types (available only for Redis engine version 5.0.6 onward and Memcached engine version 1.5.16 onward): cache.t4g.micro, cache.t4g.small, cache.t4g.medium T3 node types: cache.t3.micro, cache.t3.small, cache.t3.medium T2 node types: cache.t2.micro, cache.t2.small, cache.t2.medium Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) T1 node types: cache.t1.micro M1 node types: cache.m1.small, cache.m1.medium, cache.m1.large, cache.m1.xlarge M3 node types: cache.m3.medium, cache.m3.large, cache.m3.xlarge, cache.m3.2xlarge Compute optimized: Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) C1 node types: cache.c1.xlarge Memory optimized: Current generation: R6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward). cache.r6g.large, cache.r6g.xlarge, cache.r6g.2xlarge, cache.r6g.4xlarge, cache.r6g.8xlarge, cache.r6g.12xlarge, cache.r6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) R5 node types: cache.r5.large, cache.r5.xlarge, cache.r5.2xlarge, cache.r5.4xlarge, cache.r5.12xlarge, cache.r5.24xlarge R4 node types: cache.r4.large, cache.r4.xlarge, cache.r4.2xlarge, cache.r4.4xlarge, cache.r4.8xlarge, cache.r4.16xlarge Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) M2 node types: cache.m2.xlarge, cache.m2.2xlarge, cache.m2.4xlarge R3 node types: cache.r3.large, cache.r3.xlarge, cache.r3.2xlarge, cache.r3.4xlarge, cache.r3.8xlarge Additional node type info All current generation instance types are created in Amazon VPC by default. Redis append-only files (AOF) are not supported for T1 or T2 instances. Redis Multi-AZ with automatic failover is not supported on T1 instances. Redis configuration variables appendonly and appendfsync are not supported on Redis version 2.8.22 and later.
  --engine: string # The name of the cache engine to be used for this cluster. Valid values for this parameter are: memcached | redis
  --engine-version: string # The version number of the cache engine to be used for this cluster. To view the supported cache engine versions, use the DescribeCacheEngineVersions operation. Important: You can upgrade to a newer engine version (see Selecting a Cache Engine and Version (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SelectEngine.html#VersionManagement)), but you cannot downgrade to an earlier engine version. If you want to use an earlier engine version, you must delete the existing cluster or replication group and create it anew with the earlier engine version.
  --cache-parameter-group-name: string # The name of the parameter group to associate with this cluster. If this argument is omitted, the default parameter group for the specified engine is used. You cannot use any parameter group which has cluster-enabled='yes' when creating a cluster.
  --cache-subnet-group-name: string # The name of the subnet group to be used for the cluster. Use this parameter only when you are creating a cluster in an Amazon Virtual Private Cloud (Amazon VPC). If you're going to launch your cluster in an Amazon VPC, you need to create a subnet group before you start creating a cluster. For more information, see Subnets and Subnet Groups (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SubnetGroups.html).
  --cache-security-group-names: list<string> # A list of security group names to associate with this cluster. Use this parameter only when you are creating a cluster outside of an Amazon Virtual Private Cloud (Amazon VPC).
  --security-group-ids: list<string> # One or more VPC security groups associated with the cluster. Use this parameter only when you are creating a cluster in an Amazon Virtual Private Cloud (Amazon VPC).
  --tags: list # A list of tags to be added to this resource.
  --snapshot-arns: list<string> # A single-element string list containing an Amazon Resource Name (ARN) that uniquely identifies a Redis RDB snapshot file stored in Amazon S3. The snapshot file is used to populate the node group (shard). The Amazon S3 object name in the ARN cannot contain any commas. This parameter is only valid if the Engine parameter is redis. Example of an Amazon S3 ARN: arn:aws:s3:::my_bucket/snapshot1.rdb
  --snapshot-name: string # The name of a Redis snapshot from which to restore data into the new node group (shard). The snapshot status changes to restoring while the new node group (shard) is being created. This parameter is only valid if the Engine parameter is redis.
  --preferred-maintenance-window: string # Specifies the weekly time range during which maintenance on the cluster is performed. It is specified as a range in the format ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period.
  --port: int # The port number on which each of the cache nodes accepts connections.
  --notification-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon Simple Notification Service (SNS) topic to which notifications are sent. The Amazon SNS topic owner must be the same as the cluster owner.
  --auto-minor-version-upgrade: oneof<nothing, bool> # If you are running Redis engine version 6.0 or later, set this parameter to yes if you want to opt-in to the next auto minor version upgrade campaign. This parameter is disabled for previous versions.
  --snapshot-retention-limit: int # The number of days for which ElastiCache retains automatic snapshots before deleting them. For example, if you set SnapshotRetentionLimit to 5, a snapshot taken today is retained for 5 days before being deleted. This parameter is only valid if the Engine parameter is redis. Default: 0 (i.e., automatic backups are disabled for this cache cluster).
  --snapshot-window: string # The daily time range (in UTC) during which ElastiCache begins taking a daily snapshot of your node group (shard). Example: 05:00-09:00 If you do not specify this parameter, ElastiCache automatically chooses an appropriate time range. This parameter is only valid if the Engine parameter is redis.
  --auth-token: string # Reserved parameter. The password used to access a password protected server. Password constraints: Must be only printable ASCII characters. Must be at least 16 characters and no more than 128 characters in length. The only permitted printable special characters are !, &, #, $, ^, <, >, and -. Other printable special characters cannot be used in the AUTH token. For more information, see AUTH password (http://redis.io/commands/AUTH) at http://redis.io/commands/AUTH.
  --outpost-mode: string@outpost-mode-completer # Specifies whether the nodes in the cluster are created in a single outpost or across multiple outposts.
  --preferred-outpost-arn: string # The outpost ARN in which the cache cluster is created.
  --preferred-outpost-arns: list<string> # The outpost ARNs in which the cache cluster is created.
  --log-delivery-configurations: list # Specifies the destination, format and type of the logs.
  --transit-encryption-enabled: oneof<nothing, bool> # A flag that enables in-transit encryption when set to true. Only available when creating a cache cluster in an Amazon VPC using Memcached version 1.6.12 or later.
  --network-type: string@network-type-completer # Must be either ipv4 | ipv6 | dual_stack. IPv6 is supported for workloads using Redis engine version 6.2 onward or Memcached engine version 1.6.6 on all instances built on the Nitro system (https://aws.amazon.com/ec2/nitro/).
  --ip-discovery: string@ip-discovery-completer # The network type you choose when modifying a cluster, either ipv4 | ipv6. IPv6 is supported for workloads using Redis engine version 6.2 onward or Memcached engine version 1.6.6 on all instances built on the Nitro system (https://aws.amazon.com/ec2/nitro/).
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
    query: [{name: CacheClusterId, var: cache_cluster_id, required: true}, {name: ReplicationGroupId, var: replication_group_id}, {name: AZMode, var: az_mode}, {name: PreferredAvailabilityZone, var: preferred_availability_zone}, {name: PreferredAvailabilityZones, var: preferred_availability_zones, style: multi}, {name: NumCacheNodes, var: num_cache_nodes}, {name: CacheNodeType, var: cache_node_type}, {name: Engine, var: engine}, {name: EngineVersion, var: engine_version}, {name: CacheParameterGroupName, var: cache_parameter_group_name}, {name: CacheSubnetGroupName, var: cache_subnet_group_name}, {name: CacheSecurityGroupNames, var: cache_security_group_names, style: multi}, {name: SecurityGroupIds, var: security_group_ids, style: multi}, {name: Tags, var: tags, style: multi}, {name: SnapshotArns, var: snapshot_arns, style: multi}, {name: SnapshotName, var: snapshot_name}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: Port, var: port}, {name: NotificationTopicArn, var: notification_topic_arn}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: SnapshotRetentionLimit, var: snapshot_retention_limit}, {name: SnapshotWindow, var: snapshot_window}, {name: AuthToken, var: auth_token}, {name: OutpostMode, var: outpost_mode}, {name: PreferredOutpostArn, var: preferred_outpost_arn}, {name: PreferredOutpostArns, var: preferred_outpost_arns, style: multi}, {name: LogDeliveryConfigurations, var: log_delivery_configurations, style: multi}, {name: TransitEncryptionEnabled, var: transit_encryption_enabled}, {name: NetworkType, var: network_type}, {name: IpDiscovery, var: ip_discovery}, {name: Action, var: action, required: true, default: CreateCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_cluster_id: $cache_cluster_id, replication_group_id: $replication_group_id, az_mode: $az_mode, preferred_availability_zone: $preferred_availability_zone, preferred_availability_zones: $preferred_availability_zones, num_cache_nodes: $num_cache_nodes, cache_node_type: $cache_node_type, engine: $engine, engine_version: $engine_version, cache_parameter_group_name: $cache_parameter_group_name, cache_subnet_group_name: $cache_subnet_group_name, cache_security_group_names: $cache_security_group_names, security_group_ids: $security_group_ids, tags: $tags, snapshot_arns: $snapshot_arns, snapshot_name: $snapshot_name, preferred_maintenance_window: $preferred_maintenance_window, port: $port, notification_topic_arn: $notification_topic_arn, auto_minor_version_upgrade: $auto_minor_version_upgrade, snapshot_retention_limit: $snapshot_retention_limit, snapshot_window: $snapshot_window, auth_token: $auth_token, outpost_mode: $outpost_mode, preferred_outpost_arn: $preferred_outpost_arn, preferred_outpost_arns: $preferred_outpost_arns, log_delivery_configurations: $log_delivery_configurations, transit_encryption_enabled: $transit_encryption_enabled, network_type: $network_type, ip_discovery: $ip_discovery, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a cluster. All nodes in the cluster run the same protocol-compliant cache engine software, either Memcached or Redis. This operation is not supported for Redis (cluster mode enabled) clusters.
#
# POST /
# operationId: POST_CreateCacheCluster
export def "post-create-cache-cluster" [
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
    query: [{name: Action, var: action, required: true, default: CreateCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Creates a new Amazon ElastiCache cache parameter group. An ElastiCache cache parameter group is a collection of parameters and their values that are applied to all of the nodes in any cluster or replication group using the CacheParameterGroup. A newly created CacheParameterGroup is an exact duplicate of the default parameter group for the CacheParameterGroupFamily. To customize the newly created CacheParameterGroup you can change the values of specific parameters. For more information, see: ModifyCacheParameterGroup (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_ModifyCacheParameterGroup.html) in the ElastiCache API Reference. Parameters and Parameter Groups (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/ParameterGroups.html) in the ElastiCache User Guide.
#
# GET /
# operationId: GET_CreateCacheParameterGroup
export def "get-create-cache-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-parameter-group-name: string # A user-specified name for the cache parameter group. (required)
  --cache-parameter-group-family: string # The name of the cache parameter group family that the cache parameter group can be used with. Valid values are: memcached1.4 | memcached1.5 | memcached1.6 | redis2.6 | redis2.8 | redis3.2 | redis4.0 | redis5.0 | redis6.x (required)
  --description: string # A user-specified description for the cache parameter group. (required)
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
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
    query: [{name: CacheParameterGroupName, var: cache_parameter_group_name, required: true}, {name: CacheParameterGroupFamily, var: cache_parameter_group_family, required: true}, {name: Description, var: description, required: true}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_parameter_group_name: $cache_parameter_group_name, cache_parameter_group_family: $cache_parameter_group_family, description: $description, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Amazon ElastiCache cache parameter group. An ElastiCache cache parameter group is a collection of parameters and their values that are applied to all of the nodes in any cluster or replication group using the CacheParameterGroup. A newly created CacheParameterGroup is an exact duplicate of the default parameter group for the CacheParameterGroupFamily. To customize the newly created CacheParameterGroup you can change the values of specific parameters. For more information, see: ModifyCacheParameterGroup (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_ModifyCacheParameterGroup.html) in the ElastiCache API Reference. Parameters and Parameter Groups (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/ParameterGroups.html) in the ElastiCache User Guide.
#
# POST /
# operationId: POST_CreateCacheParameterGroup
export def "post-create-cache-parameter-group" [
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
    query: [{name: Action, var: action, required: true, default: CreateCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Creates a new cache security group. Use a cache security group to control access to one or more clusters. Cache security groups are only used when you are creating a cluster outside of an Amazon Virtual Private Cloud (Amazon VPC). If you are creating a cluster inside of a VPC, use a cache subnet group instead. For more information, see CreateCacheSubnetGroup (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_CreateCacheSubnetGroup.html).
#
# GET /
# operationId: GET_CreateCacheSecurityGroup
export def "get-create-cache-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-security-group-name: string # A name for the cache security group. This value is stored as a lowercase string. Constraints: Must contain no more than 255 alphanumeric characters. Cannot be the word "Default". Example: mysecuritygroup (required)
  --description: string # A description for the cache security group. (required)
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
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
    query: [{name: CacheSecurityGroupName, var: cache_security_group_name, required: true}, {name: Description, var: description, required: true}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateCacheSecurityGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_security_group_name: $cache_security_group_name, description: $description, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new cache security group. Use a cache security group to control access to one or more clusters. Cache security groups are only used when you are creating a cluster outside of an Amazon Virtual Private Cloud (Amazon VPC). If you are creating a cluster inside of a VPC, use a cache subnet group instead. For more information, see CreateCacheSubnetGroup (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_CreateCacheSubnetGroup.html).
#
# POST /
# operationId: POST_CreateCacheSecurityGroup
export def "post-create-cache-security-group" [
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
    query: [{name: Action, var: action, required: true, default: CreateCacheSecurityGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Creates a new cache subnet group. Use this parameter only when you are creating a cluster in an Amazon Virtual Private Cloud (Amazon VPC).
#
# GET /
# operationId: GET_CreateCacheSubnetGroup
export def "get-create-cache-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-subnet-group-name: string # A name for the cache subnet group. This value is stored as a lowercase string. Constraints: Must contain no more than 255 alphanumeric characters or hyphens. Example: mysubnetgroup (required)
  --cache-subnet-group-description: string # A description for the cache subnet group. (required)
  --subnet-ids: list<string> # A list of VPC subnet IDs for the cache subnet group. (required)
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
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
    query: [{name: CacheSubnetGroupName, var: cache_subnet_group_name, required: true}, {name: CacheSubnetGroupDescription, var: cache_subnet_group_description, required: true}, {name: SubnetIds, var: subnet_ids, style: multi, required: true}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateCacheSubnetGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_subnet_group_name: $cache_subnet_group_name, cache_subnet_group_description: $cache_subnet_group_description, subnet_ids: $subnet_ids, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new cache subnet group. Use this parameter only when you are creating a cluster in an Amazon Virtual Private Cloud (Amazon VPC).
#
# POST /
# operationId: POST_CreateCacheSubnetGroup
export def "post-create-cache-subnet-group" [
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
    query: [{name: Action, var: action, required: true, default: CreateCacheSubnetGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Global Datastore for Redis offers fully managed, fast, reliable and secure cross-region replication. Using Global Datastore for Redis, you can create cross-region read replica clusters for ElastiCache for Redis to enable low-latency reads and disaster recovery across regions. For more information, see Replication Across Regions Using Global Datastore (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Redis-Global-Datastore.html). The GlobalReplicationGroupIdSuffix is the name of the Global datastore. The PrimaryReplicationGroupId represents the name of the primary cluster that accepts writes and will replicate updates to the secondary cluster.
#
# GET /
# operationId: GET_CreateGlobalReplicationGroup
export def "get-create-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id-suffix: string # The suffix name of a Global datastore. Amazon ElastiCache automatically applies a prefix to the Global datastore ID when it is created. Each Amazon Region has its own prefix. For instance, a Global datastore ID created in the US-West-1 region will begin with "dsdfu" along with the suffix name you provide. The suffix, combined with the auto-generated prefix, guarantees uniqueness of the Global datastore name across multiple regions. For a full list of Amazon Regions and their respective Global datastore iD prefixes, see Using the Amazon CLI with Global datastores (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Redis-Global-Datastores-CLI.html). (required)
  --global-replication-group-description: string # Provides details of the Global datastore
  --primary-replication-group-id: string # The name of the primary cluster that accepts writes and will replicate updates to the secondary cluster. (required)
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
    query: [{name: GlobalReplicationGroupIdSuffix, var: global_replication_group_id_suffix, required: true}, {name: GlobalReplicationGroupDescription, var: global_replication_group_description}, {name: PrimaryReplicationGroupId, var: primary_replication_group_id, required: true}, {name: Action, var: action, required: true, default: CreateGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id_suffix: $global_replication_group_id_suffix, global_replication_group_description: $global_replication_group_description, primary_replication_group_id: $primary_replication_group_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Global Datastore for Redis offers fully managed, fast, reliable and secure cross-region replication. Using Global Datastore for Redis, you can create cross-region read replica clusters for ElastiCache for Redis to enable low-latency reads and disaster recovery across regions. For more information, see Replication Across Regions Using Global Datastore (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Redis-Global-Datastore.html). The GlobalReplicationGroupIdSuffix is the name of the Global datastore. The PrimaryReplicationGroupId represents the name of the primary cluster that accepts writes and will replicate updates to the secondary cluster.
#
# POST /
# operationId: POST_CreateGlobalReplicationGroup
export def "post-create-global-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: CreateGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Creates a Redis (cluster mode disabled) or a Redis (cluster mode enabled) replication group. This API can be used to create a standalone regional replication group or a secondary replication group associated with a Global datastore. A Redis (cluster mode disabled) replication group is a collection of clusters, where one of the clusters is a read/write primary and the others are read-only replicas. Writes to the primary are asynchronously propagated to the replicas. A Redis cluster-mode enabled cluster is comprised of from 1 to 90 shards (API/CLI: node groups). Each shard has a primary node and up to 5 read-only replica nodes. The configuration can range from 90 shards and 0 replicas to 15 shards and 5 replicas, which is the maximum number or replicas allowed. The node or shard limit can be increased to a maximum of 500 per cluster if the Redis engine version is 5.0.6 or higher. For example, you can choose to configure a 500 node cluster that ranges between 83 shards (one primary and 5 replicas per shard) and 500 shards (single primary and no replicas). Make sure there are enough available IP addresses to accommodate the increase. Common pitfalls include the subnets in the subnet group have too small a CIDR range or the subnets are shared and heavily used by other clusters. For more information, see Creating a Subnet Group (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SubnetGroups.Creating.html). For versions below 5.0.6, the limit is 250 per cluster. To request a limit increase, see Amazon Service Limits (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html) and choose the limit type Nodes per cluster per instance type. When a Redis (cluster mode disabled) replication group has been successfully created, you can add one or more read replicas to it, up to a total of 5 read replicas. If you need to increase or decrease the number of node groups (console: shards), you can avail yourself of ElastiCache for Redis' scaling. For more information, see Scaling ElastiCache for Redis Clusters (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Scaling.html) in the ElastiCache User Guide. This operation is valid for Redis only.
#
# GET /
# operationId: GET_CreateReplicationGroup
export def "get-create-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The replication group identifier. This parameter is stored as a lowercase string. Constraints: A name must contain from 1 to 40 alphanumeric characters or hyphens. The first character must be a letter. A name cannot end with a hyphen or contain two consecutive hyphens. (required)
  --replication-group-description: string # A user-created description for the replication group. (required)
  --global-replication-group-id: string # The name of the Global datastore
  --primary-cluster-id: string # The identifier of the cluster that serves as the primary for this replication group. This cluster must already exist and have a status of available. This parameter is not required if NumCacheClusters, NumNodeGroups, or ReplicasPerNodeGroup is specified.
  --automatic-failover-enabled: oneof<nothing, bool> # Specifies whether a read-only replica is automatically promoted to read/write primary if the existing primary fails. AutomaticFailoverEnabled must be enabled for Redis (cluster mode enabled) replication groups. Default: false
  --multi-az-enabled: oneof<nothing, bool> # A flag indicating if you have Multi-AZ enabled to enhance fault tolerance. For more information, see Minimizing Downtime: Multi-AZ (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/AutoFailover.html).
  --num-cache-clusters: int # The number of clusters this replication group initially has. This parameter is not used if there is more than one node group (shard). You should use ReplicasPerNodeGroup instead. If AutomaticFailoverEnabled is true, the value of this parameter must be at least 2. If AutomaticFailoverEnabled is false you can omit this parameter (it will default to 1), or you can explicitly set it to a value between 2 and 6. The maximum permitted value for NumCacheClusters is 6 (1 primary plus 5 replicas).
  --preferred-cache-cluster-a-zs: list<string> # A list of EC2 Availability Zones in which the replication group's clusters are created. The order of the Availability Zones in the list is the order in which clusters are allocated. The primary cluster is created in the first AZ in the list. This parameter is not used if there is more than one node group (shard). You should use NodeGroupConfiguration instead. If you are creating your replication group in an Amazon VPC (recommended), you can only locate clusters in Availability Zones associated with the subnets in the selected subnet group. The number of Availability Zones listed must equal the value of NumCacheClusters. Default: system chosen Availability Zones.
  --num-node-groups: int # An optional parameter that specifies the number of node groups (shards) for this Redis (cluster mode enabled) replication group. For Redis (cluster mode disabled) either omit this parameter or set it to 1. Default: 1
  --replicas-per-node-group: int # An optional parameter that specifies the number of replica nodes in each node group (shard). Valid values are 0 to 5.
  --node-group-configuration: list # A list of node group (shard) configuration options. Each node group (shard) configuration has the following members: PrimaryAvailabilityZone, ReplicaAvailabilityZones, ReplicaCount, and Slots. If you're creating a Redis (cluster mode disabled) or a Redis (cluster mode enabled) replication group, you can use this parameter to individually configure each node group (shard), or you can omit this parameter. However, it is required when seeding a Redis (cluster mode enabled) cluster from a S3 rdb file. You must configure each node group (shard) using this parameter because you must specify the slots for each node group.
  --cache-node-type: string # The compute and memory capacity of the nodes in the node group (shard). The following node types are supported by ElastiCache. Generally speaking, the current generation types provide more memory and computational power at lower cost when compared to their equivalent previous generation counterparts. General purpose: Current generation: M6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward): cache.m6g.large, cache.m6g.xlarge, cache.m6g.2xlarge, cache.m6g.4xlarge, cache.m6g.8xlarge, cache.m6g.12xlarge, cache.m6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) M5 node types: cache.m5.large, cache.m5.xlarge, cache.m5.2xlarge, cache.m5.4xlarge, cache.m5.12xlarge, cache.m5.24xlarge M4 node types: cache.m4.large, cache.m4.xlarge, cache.m4.2xlarge, cache.m4.4xlarge, cache.m4.10xlarge T4g node types (available only for Redis engine version 5.0.6 onward and Memcached engine version 1.5.16 onward): cache.t4g.micro, cache.t4g.small, cache.t4g.medium T3 node types: cache.t3.micro, cache.t3.small, cache.t3.medium T2 node types: cache.t2.micro, cache.t2.small, cache.t2.medium Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) T1 node types: cache.t1.micro M1 node types: cache.m1.small, cache.m1.medium, cache.m1.large, cache.m1.xlarge M3 node types: cache.m3.medium, cache.m3.large, cache.m3.xlarge, cache.m3.2xlarge Compute optimized: Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) C1 node types: cache.c1.xlarge Memory optimized: Current generation: R6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward). cache.r6g.large, cache.r6g.xlarge, cache.r6g.2xlarge, cache.r6g.4xlarge, cache.r6g.8xlarge, cache.r6g.12xlarge, cache.r6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) R5 node types: cache.r5.large, cache.r5.xlarge, cache.r5.2xlarge, cache.r5.4xlarge, cache.r5.12xlarge, cache.r5.24xlarge R4 node types: cache.r4.large, cache.r4.xlarge, cache.r4.2xlarge, cache.r4.4xlarge, cache.r4.8xlarge, cache.r4.16xlarge Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) M2 node types: cache.m2.xlarge, cache.m2.2xlarge, cache.m2.4xlarge R3 node types: cache.r3.large, cache.r3.xlarge, cache.r3.2xlarge, cache.r3.4xlarge, cache.r3.8xlarge Additional node type info All current generation instance types are created in Amazon VPC by default. Redis append-only files (AOF) are not supported for T1 or T2 instances. Redis Multi-AZ with automatic failover is not supported on T1 instances. Redis configuration variables appendonly and appendfsync are not supported on Redis version 2.8.22 and later.
  --engine: string # The name of the cache engine to be used for the clusters in this replication group. The value must be set to Redis.
  --engine-version: string # The version number of the cache engine to be used for the clusters in this replication group. To view the supported cache engine versions, use the DescribeCacheEngineVersions operation. Important: You can upgrade to a newer engine version (see Selecting a Cache Engine and Version (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SelectEngine.html#VersionManagement)) in the ElastiCache User Guide, but you cannot downgrade to an earlier engine version. If you want to use an earlier engine version, you must delete the existing cluster or replication group and create it anew with the earlier engine version.
  --cache-parameter-group-name: string # The name of the parameter group to associate with this replication group. If this argument is omitted, the default cache parameter group for the specified engine is used. If you are running Redis version 3.2.4 or later, only one node group (shard), and want to use a default parameter group, we recommend that you specify the parameter group by name. To create a Redis (cluster mode disabled) replication group, use CacheParameterGroupName=default.redis3.2. To create a Redis (cluster mode enabled) replication group, use CacheParameterGroupName=default.redis3.2.cluster.on.
  --cache-subnet-group-name: string # The name of the cache subnet group to be used for the replication group. If you're going to launch your cluster in an Amazon VPC, you need to create a subnet group before you start creating a cluster. For more information, see Subnets and Subnet Groups (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SubnetGroups.html).
  --cache-security-group-names: list<string> # A list of cache security group names to associate with this replication group.
  --security-group-ids: list<string> # One or more Amazon VPC security groups associated with this replication group. Use this parameter only when you are creating a replication group in an Amazon Virtual Private Cloud (Amazon VPC).
  --tags: list # A list of tags to be added to this resource. Tags are comma-separated key,value pairs (e.g. Key=myKey, Value=myKeyValue. You can include multiple tags as shown following: Key=myKey, Value=myKeyValue Key=mySecondKey, Value=mySecondKeyValue. Tags on replication groups will be replicated to all nodes.
  --snapshot-arns: list<string> # A list of Amazon Resource Names (ARN) that uniquely identify the Redis RDB snapshot files stored in Amazon S3. The snapshot files are used to populate the new replication group. The Amazon S3 object name in the ARN cannot contain any commas. The new replication group will have the number of node groups (console: shards) specified by the parameter NumNodeGroups or the number of node groups configured by NodeGroupConfiguration regardless of the number of ARNs specified here. Example of an Amazon S3 ARN: arn:aws:s3:::my_bucket/snapshot1.rdb
  --snapshot-name: string # The name of a snapshot from which to restore data into the new replication group. The snapshot status changes to restoring while the new replication group is being created.
  --preferred-maintenance-window: string # Specifies the weekly time range during which maintenance on the cluster is performed. It is specified as a range in the format ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Valid values for ddd are: Specifies the weekly time range during which maintenance on the cluster is performed. It is specified as a range in the format ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Valid values for ddd are: sun mon tue wed thu fri sat Example: sun:23:00-mon:01:30
  --port: int # The port number on which each member of the replication group accepts connections.
  --notification-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon Simple Notification Service (SNS) topic to which notifications are sent. The Amazon SNS topic owner must be the same as the cluster owner.
  --auto-minor-version-upgrade: oneof<nothing, bool> # If you are running Redis engine version 6.0 or later, set this parameter to yes if you want to opt-in to the next auto minor version upgrade campaign. This parameter is disabled for previous versions.
  --snapshot-retention-limit: int # The number of days for which ElastiCache retains automatic snapshots before deleting them. For example, if you set SnapshotRetentionLimit to 5, a snapshot that was taken today is retained for 5 days before being deleted. Default: 0 (i.e., automatic backups are disabled for this cluster).
  --snapshot-window: string # The daily time range (in UTC) during which ElastiCache begins taking a daily snapshot of your node group (shard). Example: 05:00-09:00 If you do not specify this parameter, ElastiCache automatically chooses an appropriate time range.
  --auth-token: string # Reserved parameter. The password used to access a password protected server. AuthToken can be specified only on replication groups where TransitEncryptionEnabled is true. For HIPAA compliance, you must specify TransitEncryptionEnabled as true, an AuthToken, and a CacheSubnetGroup. Password constraints: Must be only printable ASCII characters. Must be at least 16 characters and no more than 128 characters in length. The only permitted printable special characters are !, &, #, $, ^, <, >, and -. Other printable special characters cannot be used in the AUTH token. For more information, see AUTH password (http://redis.io/commands/AUTH) at http://redis.io/commands/AUTH.
  --transit-encryption-enabled: oneof<nothing, bool> # A flag that enables in-transit encryption when set to true. This parameter is valid only if the Engine parameter is redis, the EngineVersion parameter is 3.2.6, 4.x or later, and the cluster is being created in an Amazon VPC. If you enable in-transit encryption, you must also specify a value for CacheSubnetGroup. Required: Only available when creating a replication group in an Amazon VPC using redis version 3.2.6, 4.x or later. Default: false For HIPAA compliance, you must specify TransitEncryptionEnabled as true, an AuthToken, and a CacheSubnetGroup.
  --at-rest-encryption-enabled: oneof<nothing, bool> # A flag that enables encryption at rest when set to true. You cannot modify the value of AtRestEncryptionEnabled after the replication group is created. To enable encryption at rest on a replication group you must set AtRestEncryptionEnabled to true when you create the replication group. Required: Only available when creating a replication group in an Amazon VPC using redis version 3.2.6, 4.x or later. Default: false
  --kms-key-id: string # The ID of the KMS key used to encrypt the disk in the cluster.
  --user-group-ids: list<string> # The user group to associate with the replication group.
  --log-delivery-configurations: list # Specifies the destination, format and type of the logs.
  --data-tiering-enabled: oneof<nothing, bool> # Enables data tiering. Data tiering is only supported for replication groups using the r6gd node type. This parameter must be set to true when using r6gd nodes. For more information, see Data tiering (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/data-tiering.html).
  --network-type: string@network-type-completer # Must be either ipv4 | ipv6 | dual_stack. IPv6 is supported for workloads using Redis engine version 6.2 onward or Memcached engine version 1.6.6 on all instances built on the Nitro system (https://aws.amazon.com/ec2/nitro/).
  --ip-discovery: string@ip-discovery-completer # The network type you choose when creating a replication group, either ipv4 | ipv6. IPv6 is supported for workloads using Redis engine version 6.2 onward or Memcached engine version 1.6.6 on all instances built on the Nitro system (https://aws.amazon.com/ec2/nitro/).
  --transit-encryption-mode: string@transit-encryption-mode-completer # A setting that allows you to migrate your clients to use in-transit encryption, with no downtime. When setting TransitEncryptionEnabled to true, you can set your TransitEncryptionMode to preferred in the same request, to allow both encrypted and unencrypted connections at the same time. Once you migrate all your Redis clients to use encrypted connections you can modify the value to required to allow encrypted connections only. Setting TransitEncryptionMode to required is a two-step process that requires you to first set the TransitEncryptionMode to preferred first, after that you can set TransitEncryptionMode to required.
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: ReplicationGroupDescription, var: replication_group_description, required: true}, {name: GlobalReplicationGroupId, var: global_replication_group_id}, {name: PrimaryClusterId, var: primary_cluster_id}, {name: AutomaticFailoverEnabled, var: automatic_failover_enabled}, {name: MultiAZEnabled, var: multi_az_enabled}, {name: NumCacheClusters, var: num_cache_clusters}, {name: PreferredCacheClusterAZs, var: preferred_cache_cluster_a_zs, style: multi}, {name: NumNodeGroups, var: num_node_groups}, {name: ReplicasPerNodeGroup, var: replicas_per_node_group}, {name: NodeGroupConfiguration, var: node_group_configuration, style: multi}, {name: CacheNodeType, var: cache_node_type}, {name: Engine, var: engine}, {name: EngineVersion, var: engine_version}, {name: CacheParameterGroupName, var: cache_parameter_group_name}, {name: CacheSubnetGroupName, var: cache_subnet_group_name}, {name: CacheSecurityGroupNames, var: cache_security_group_names, style: multi}, {name: SecurityGroupIds, var: security_group_ids, style: multi}, {name: Tags, var: tags, style: multi}, {name: SnapshotArns, var: snapshot_arns, style: multi}, {name: SnapshotName, var: snapshot_name}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: Port, var: port}, {name: NotificationTopicArn, var: notification_topic_arn}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: SnapshotRetentionLimit, var: snapshot_retention_limit}, {name: SnapshotWindow, var: snapshot_window}, {name: AuthToken, var: auth_token}, {name: TransitEncryptionEnabled, var: transit_encryption_enabled}, {name: AtRestEncryptionEnabled, var: at_rest_encryption_enabled}, {name: KmsKeyId, var: kms_key_id}, {name: UserGroupIds, var: user_group_ids, style: multi}, {name: LogDeliveryConfigurations, var: log_delivery_configurations, style: multi}, {name: DataTieringEnabled, var: data_tiering_enabled}, {name: NetworkType, var: network_type}, {name: IpDiscovery, var: ip_discovery}, {name: TransitEncryptionMode, var: transit_encryption_mode}, {name: Action, var: action, required: true, default: CreateReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, replication_group_description: $replication_group_description, global_replication_group_id: $global_replication_group_id, primary_cluster_id: $primary_cluster_id, automatic_failover_enabled: $automatic_failover_enabled, multi_az_enabled: $multi_az_enabled, num_cache_clusters: $num_cache_clusters, preferred_cache_cluster_a_zs: $preferred_cache_cluster_a_zs, num_node_groups: $num_node_groups, replicas_per_node_group: $replicas_per_node_group, node_group_configuration: $node_group_configuration, cache_node_type: $cache_node_type, engine: $engine, engine_version: $engine_version, cache_parameter_group_name: $cache_parameter_group_name, cache_subnet_group_name: $cache_subnet_group_name, cache_security_group_names: $cache_security_group_names, security_group_ids: $security_group_ids, tags: $tags, snapshot_arns: $snapshot_arns, snapshot_name: $snapshot_name, preferred_maintenance_window: $preferred_maintenance_window, port: $port, notification_topic_arn: $notification_topic_arn, auto_minor_version_upgrade: $auto_minor_version_upgrade, snapshot_retention_limit: $snapshot_retention_limit, snapshot_window: $snapshot_window, auth_token: $auth_token, transit_encryption_enabled: $transit_encryption_enabled, at_rest_encryption_enabled: $at_rest_encryption_enabled, kms_key_id: $kms_key_id, user_group_ids: $user_group_ids, log_delivery_configurations: $log_delivery_configurations, data_tiering_enabled: $data_tiering_enabled, network_type: $network_type, ip_discovery: $ip_discovery, transit_encryption_mode: $transit_encryption_mode, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Redis (cluster mode disabled) or a Redis (cluster mode enabled) replication group. This API can be used to create a standalone regional replication group or a secondary replication group associated with a Global datastore. A Redis (cluster mode disabled) replication group is a collection of clusters, where one of the clusters is a read/write primary and the others are read-only replicas. Writes to the primary are asynchronously propagated to the replicas. A Redis cluster-mode enabled cluster is comprised of from 1 to 90 shards (API/CLI: node groups). Each shard has a primary node and up to 5 read-only replica nodes. The configuration can range from 90 shards and 0 replicas to 15 shards and 5 replicas, which is the maximum number or replicas allowed. The node or shard limit can be increased to a maximum of 500 per cluster if the Redis engine version is 5.0.6 or higher. For example, you can choose to configure a 500 node cluster that ranges between 83 shards (one primary and 5 replicas per shard) and 500 shards (single primary and no replicas). Make sure there are enough available IP addresses to accommodate the increase. Common pitfalls include the subnets in the subnet group have too small a CIDR range or the subnets are shared and heavily used by other clusters. For more information, see Creating a Subnet Group (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SubnetGroups.Creating.html). For versions below 5.0.6, the limit is 250 per cluster. To request a limit increase, see Amazon Service Limits (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html) and choose the limit type Nodes per cluster per instance type. When a Redis (cluster mode disabled) replication group has been successfully created, you can add one or more read replicas to it, up to a total of 5 read replicas. If you need to increase or decrease the number of node groups (console: shards), you can avail yourself of ElastiCache for Redis' scaling. For more information, see Scaling ElastiCache for Redis Clusters (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Scaling.html) in the ElastiCache User Guide. This operation is valid for Redis only.
#
# POST /
# operationId: POST_CreateReplicationGroup
export def "post-create-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: CreateReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Creates a copy of an entire cluster or replication group at a specific moment in time. This operation is valid for Redis only.
#
# GET /
# operationId: GET_CreateSnapshot
export def "get-create-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The identifier of an existing replication group. The snapshot is created from this replication group.
  --cache-cluster-id: string # The identifier of an existing cluster. The snapshot is created from this cluster.
  --snapshot-name: string # A name for the snapshot being created. (required)
  --kms-key-id: string # The ID of the KMS key used to encrypt the snapshot.
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
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
    query: [{name: ReplicationGroupId, var: replication_group_id}, {name: CacheClusterId, var: cache_cluster_id}, {name: SnapshotName, var: snapshot_name, required: true}, {name: KmsKeyId, var: kms_key_id}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateSnapshot}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, cache_cluster_id: $cache_cluster_id, snapshot_name: $snapshot_name, kms_key_id: $kms_key_id, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a copy of an entire cluster or replication group at a specific moment in time. This operation is valid for Redis only.
#
# POST /
# operationId: POST_CreateSnapshot
export def "post-create-snapshot" [
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
    query: [{name: Action, var: action, required: true, default: CreateSnapshot}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# For Redis engine version 6.0 onwards: Creates a Redis user. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html).
#
# GET /
# operationId: GET_CreateUser
export def "get-create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user. (required)
  --user-name: string # The username of the user. (required)
  --engine: string # The current supported value is Redis. (required)
  --passwords: list<string> # Passwords used for this user. You can create up to two passwords for each user.
  --access-string: string # Access permissions string used for this user. (required)
  --no-password-required: oneof<nothing, bool> # Indicates a password is not required for this user.
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
  --authentication-mode: record # Specifies how to authenticate the user.
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
    query: [{name: UserId, var: user_id, required: true}, {name: UserName, var: user_name, required: true}, {name: Engine, var: engine, required: true}, {name: Passwords, var: passwords, style: multi}, {name: AccessString, var: access_string, required: true}, {name: NoPasswordRequired, var: no_password_required}, {name: Tags, var: tags, style: multi}, {name: AuthenticationMode, var: authentication_mode, style: multi}, {name: Action, var: action, required: true, default: CreateUser}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, user_name: $user_name, engine: $engine, passwords: $passwords, access_string: $access_string, no_password_required: $no_password_required, tags: $tags, authentication_mode: $authentication_mode, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For Redis engine version 6.0 onwards: Creates a Redis user. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html).
#
# POST /
# operationId: POST_CreateUser
export def "post-create-user" [
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
    query: [{name: Action, var: action, required: true, default: CreateUser}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# For Redis engine version 6.0 onwards: Creates a Redis user group. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html)
#
# GET /
# operationId: GET_CreateUserGroup
export def "get-create-user-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-group-id: string # The ID of the user group. (required)
  --engine: string # The current supported value is Redis. (required)
  --user-ids: list<string> # The list of user IDs that belong to the user group.
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
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
    query: [{name: UserGroupId, var: user_group_id, required: true}, {name: Engine, var: engine, required: true}, {name: UserIds, var: user_ids, style: multi}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: CreateUserGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_group_id: $user_group_id, engine: $engine, user_ids: $user_ids, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For Redis engine version 6.0 onwards: Creates a Redis user group. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html)
#
# POST /
# operationId: POST_CreateUserGroup
export def "post-create-user-group" [
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
    query: [{name: Action, var: action, required: true, default: CreateUserGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Decreases the number of node groups in a Global datastore
#
# GET /
# operationId: GET_DecreaseNodeGroupsInGlobalReplicationGroup
export def "get-decrease-node-groups-in-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore (required)
  --node-group-count: int # The number of node groups (shards) that results from the modification of the shard configuration (required)
  --global-node-groups-to-remove: list<string> # If the value of NodeGroupCount is less than the current number of node groups (shards), then either NodeGroupsToRemove or NodeGroupsToRetain is required. GlobalNodeGroupsToRemove is a list of NodeGroupIds to remove from the cluster. ElastiCache for Redis will attempt to remove all node groups listed by GlobalNodeGroupsToRemove from the cluster.
  --global-node-groups-to-retain: list<string> # If the value of NodeGroupCount is less than the current number of node groups (shards), then either NodeGroupsToRemove or NodeGroupsToRetain is required. GlobalNodeGroupsToRetain is a list of NodeGroupIds to retain from the cluster. ElastiCache for Redis will attempt to retain all node groups listed by GlobalNodeGroupsToRetain from the cluster.
  --apply-immediately: oneof<nothing, bool> # Indicates that the shard reconfiguration process begins immediately. At present, the only permitted value for this parameter is true. (required)
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id, required: true}, {name: NodeGroupCount, var: node_group_count, required: true}, {name: GlobalNodeGroupsToRemove, var: global_node_groups_to_remove, style: multi}, {name: GlobalNodeGroupsToRetain, var: global_node_groups_to_retain, style: multi}, {name: ApplyImmediately, var: apply_immediately, required: true}, {name: Action, var: action, required: true, default: DecreaseNodeGroupsInGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, node_group_count: $node_group_count, global_node_groups_to_remove: $global_node_groups_to_remove, global_node_groups_to_retain: $global_node_groups_to_retain, apply_immediately: $apply_immediately, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decreases the number of node groups in a Global datastore
#
# POST /
# operationId: POST_DecreaseNodeGroupsInGlobalReplicationGroup
export def "post-decrease-node-groups-in-global-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: DecreaseNodeGroupsInGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Dynamically decreases the number of replicas in a Redis (cluster mode disabled) replication group or the number of replica nodes in one or more node groups (shards) of a Redis (cluster mode enabled) replication group. This operation is performed with no cluster down time.
#
# GET /
# operationId: GET_DecreaseReplicaCount
export def "get-decrease-replica-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The id of the replication group from which you want to remove replica nodes. (required)
  --new-replica-count: int # The number of read replica nodes you want at the completion of this operation. For Redis (cluster mode disabled) replication groups, this is the number of replica nodes in the replication group. For Redis (cluster mode enabled) replication groups, this is the number of replica nodes in each of the replication group's node groups. The minimum number of replicas in a shard or replication group is: Redis (cluster mode disabled) If Multi-AZ is enabled: 1 If Multi-AZ is not enabled: 0 Redis (cluster mode enabled): 0 (though you will not be able to failover to a replica if your primary node fails)
  --replica-configuration: list # A list of ConfigureShard objects that can be used to configure each shard in a Redis (cluster mode enabled) replication group. The ConfigureShard has three members: NewReplicaCount, NodeGroupId, and PreferredAvailabilityZones.
  --replicas-to-remove: list<string> # A list of the node ids to remove from the replication group or node group (shard).
  --apply-immediately: oneof<nothing, bool> # If True, the number of replica nodes is decreased immediately. ApplyImmediately=False is not currently supported. (required)
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: NewReplicaCount, var: new_replica_count}, {name: ReplicaConfiguration, var: replica_configuration, style: multi}, {name: ReplicasToRemove, var: replicas_to_remove, style: multi}, {name: ApplyImmediately, var: apply_immediately, required: true}, {name: Action, var: action, required: true, default: DecreaseReplicaCount}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, new_replica_count: $new_replica_count, replica_configuration: $replica_configuration, replicas_to_remove: $replicas_to_remove, apply_immediately: $apply_immediately, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dynamically decreases the number of replicas in a Redis (cluster mode disabled) replication group or the number of replica nodes in one or more node groups (shards) of a Redis (cluster mode enabled) replication group. This operation is performed with no cluster down time.
#
# POST /
# operationId: POST_DecreaseReplicaCount
export def "post-decrease-replica-count" [
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
    query: [{name: Action, var: action, required: true, default: DecreaseReplicaCount}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Deletes a previously provisioned cluster. DeleteCacheCluster deletes all associated cache nodes, node endpoints and the cluster itself. When you receive a successful response from this operation, Amazon ElastiCache immediately begins deleting the cluster; you cannot cancel or revert this operation. This operation is not valid for: Redis (cluster mode enabled) clusters Redis (cluster mode disabled) clusters A cluster that is the last read replica of a replication group A cluster that is the primary node of a replication group A node group (shard) that has Multi-AZ mode enabled A cluster from a Redis (cluster mode enabled) replication group A cluster that is not in the available state
#
# GET /
# operationId: GET_DeleteCacheCluster
export def "get-delete-cache-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-cluster-id: string # The cluster identifier for the cluster to be deleted. This parameter is not case sensitive. (required)
  --final-snapshot-identifier: string # The user-supplied name of a final cluster snapshot. This is the unique name that identifies the snapshot. ElastiCache creates the snapshot, and then deletes the cluster immediately afterward.
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
    query: [{name: CacheClusterId, var: cache_cluster_id, required: true}, {name: FinalSnapshotIdentifier, var: final_snapshot_identifier}, {name: Action, var: action, required: true, default: DeleteCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_cluster_id: $cache_cluster_id, final_snapshot_identifier: $final_snapshot_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously provisioned cluster. DeleteCacheCluster deletes all associated cache nodes, node endpoints and the cluster itself. When you receive a successful response from this operation, Amazon ElastiCache immediately begins deleting the cluster; you cannot cancel or revert this operation. This operation is not valid for: Redis (cluster mode enabled) clusters Redis (cluster mode disabled) clusters A cluster that is the last read replica of a replication group A cluster that is the primary node of a replication group A node group (shard) that has Multi-AZ mode enabled A cluster from a Redis (cluster mode enabled) replication group A cluster that is not in the available state
#
# POST /
# operationId: POST_DeleteCacheCluster
export def "post-delete-cache-cluster" [
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
    query: [{name: Action, var: action, required: true, default: DeleteCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Deletes the specified cache parameter group. You cannot delete a cache parameter group if it is associated with any cache clusters. You cannot delete the default cache parameter groups in your account.
#
# GET /
# operationId: GET_DeleteCacheParameterGroup
export def "get-delete-cache-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-parameter-group-name: string # The name of the cache parameter group to delete. The specified cache security group must not be associated with any clusters. (required)
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
    query: [{name: CacheParameterGroupName, var: cache_parameter_group_name, required: true}, {name: Action, var: action, required: true, default: DeleteCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cache_parameter_group_name: $cache_parameter_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified cache parameter group. You cannot delete a cache parameter group if it is associated with any cache clusters. You cannot delete the default cache parameter groups in your account.
#
# POST /
# operationId: POST_DeleteCacheParameterGroup
export def "post-delete-cache-parameter-group" [
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
    query: [{name: Action, var: action, required: true, default: DeleteCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Deletes a cache security group. You cannot delete a cache security group if it is associated with any clusters.
#
# GET /
# operationId: GET_DeleteCacheSecurityGroup
export def "get-delete-cache-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-security-group-name: string # The name of the cache security group to delete. You cannot delete the default security group. (required)
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
    query: [{name: CacheSecurityGroupName, var: cache_security_group_name, required: true}, {name: Action, var: action, required: true, default: DeleteCacheSecurityGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cache_security_group_name: $cache_security_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a cache security group. You cannot delete a cache security group if it is associated with any clusters.
#
# POST /
# operationId: POST_DeleteCacheSecurityGroup
export def "post-delete-cache-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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
    query: [{name: Action, var: action, required: true, default: DeleteCacheSecurityGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Deletes a cache subnet group. You cannot delete a default cache subnet group or one that is associated with any clusters.
#
# GET /
# operationId: GET_DeleteCacheSubnetGroup
export def "get-delete-cache-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-subnet-group-name: string # The name of the cache subnet group to delete. Constraints: Must contain no more than 255 alphanumeric characters or hyphens. (required)
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
    query: [{name: CacheSubnetGroupName, var: cache_subnet_group_name, required: true}, {name: Action, var: action, required: true, default: DeleteCacheSubnetGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cache_subnet_group_name: $cache_subnet_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a cache subnet group. You cannot delete a default cache subnet group or one that is associated with any clusters.
#
# POST /
# operationId: POST_DeleteCacheSubnetGroup
export def "post-delete-cache-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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
    query: [{name: Action, var: action, required: true, default: DeleteCacheSubnetGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Deleting a Global datastore is a two-step process: First, you must DisassociateGlobalReplicationGroup to remove the secondary clusters in the Global datastore. Once the Global datastore contains only the primary cluster, you can use the DeleteGlobalReplicationGroup API to delete the Global datastore while retainining the primary cluster using RetainPrimaryReplicationGroup=true. Since the Global Datastore has only a primary cluster, you can delete the Global Datastore while retaining the primary by setting RetainPrimaryReplicationGroup=true. The primary cluster is never deleted when deleting a Global Datastore. It can only be deleted when it no longer is associated with any Global Datastore. When you receive a successful response from this operation, Amazon ElastiCache immediately begins deleting the selected resources; you cannot cancel or revert this operation.
#
# GET /
# operationId: GET_DeleteGlobalReplicationGroup
export def "get-delete-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore (required)
  --retain-primary-replication-group: oneof<nothing, bool> # The primary replication group is retained as a standalone replication group. (required)
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id, required: true}, {name: RetainPrimaryReplicationGroup, var: retain_primary_replication_group, required: true}, {name: Action, var: action, required: true, default: DeleteGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, retain_primary_replication_group: $retain_primary_replication_group, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deleting a Global datastore is a two-step process: First, you must DisassociateGlobalReplicationGroup to remove the secondary clusters in the Global datastore. Once the Global datastore contains only the primary cluster, you can use the DeleteGlobalReplicationGroup API to delete the Global datastore while retainining the primary cluster using RetainPrimaryReplicationGroup=true. Since the Global Datastore has only a primary cluster, you can delete the Global Datastore while retaining the primary by setting RetainPrimaryReplicationGroup=true. The primary cluster is never deleted when deleting a Global Datastore. It can only be deleted when it no longer is associated with any Global Datastore. When you receive a successful response from this operation, Amazon ElastiCache immediately begins deleting the selected resources; you cannot cancel or revert this operation.
#
# POST /
# operationId: POST_DeleteGlobalReplicationGroup
export def "post-delete-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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
    query: [{name: Action, var: action, required: true, default: DeleteGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Deletes an existing replication group. By default, this operation deletes the entire replication group, including the primary/primaries and all of the read replicas. If the replication group has only one primary, you can optionally delete only the read replicas, while retaining the primary by setting RetainPrimaryCluster=true. When you receive a successful response from this operation, Amazon ElastiCache immediately begins deleting the selected resources; you cannot cancel or revert this operation. This operation is valid for Redis only.
#
# GET /
# operationId: GET_DeleteReplicationGroup
export def "get-delete-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The identifier for the cluster to be deleted. This parameter is not case sensitive. (required)
  --retain-primary-cluster: oneof<nothing, bool> # If set to true, all of the read replicas are deleted, but the primary node is retained.
  --final-snapshot-identifier: string # The name of a final node group (shard) snapshot. ElastiCache creates the snapshot from the primary node in the cluster, rather than one of the replicas; this is to ensure that it captures the freshest data. After the final snapshot is taken, the replication group is immediately deleted.
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: RetainPrimaryCluster, var: retain_primary_cluster}, {name: FinalSnapshotIdentifier, var: final_snapshot_identifier}, {name: Action, var: action, required: true, default: DeleteReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, retain_primary_cluster: $retain_primary_cluster, final_snapshot_identifier: $final_snapshot_identifier, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing replication group. By default, this operation deletes the entire replication group, including the primary/primaries and all of the read replicas. If the replication group has only one primary, you can optionally delete only the read replicas, while retaining the primary by setting RetainPrimaryCluster=true. When you receive a successful response from this operation, Amazon ElastiCache immediately begins deleting the selected resources; you cannot cancel or revert this operation. This operation is valid for Redis only.
#
# POST /
# operationId: POST_DeleteReplicationGroup
export def "post-delete-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: DeleteReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Deletes an existing snapshot. When you receive a successful response from this operation, ElastiCache immediately begins deleting the snapshot; you cannot cancel or revert this operation. This operation is valid for Redis only.
#
# GET /
# operationId: GET_DeleteSnapshot
export def "get-delete-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-name: string # The name of the snapshot to be deleted. (required)
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
    query: [{name: SnapshotName, var: snapshot_name, required: true}, {name: Action, var: action, required: true, default: DeleteSnapshot}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    snapshot_name: $snapshot_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing snapshot. When you receive a successful response from this operation, ElastiCache immediately begins deleting the snapshot; you cannot cancel or revert this operation. This operation is valid for Redis only.
#
# POST /
# operationId: POST_DeleteSnapshot
export def "post-delete-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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
    query: [{name: Action, var: action, required: true, default: DeleteSnapshot}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# For Redis engine version 6.0 onwards: Deletes a user. The user will be removed from all user groups and in turn removed from all replication groups. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html).
#
# GET /
# operationId: GET_DeleteUser
export def "get-delete-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user. (required)
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
    query: [{name: UserId, var: user_id, required: true}, {name: Action, var: action, required: true, default: DeleteUser}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For Redis engine version 6.0 onwards: Deletes a user. The user will be removed from all user groups and in turn removed from all replication groups. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html).
#
# POST /
# operationId: POST_DeleteUser
export def "post-delete-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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
    query: [{name: Action, var: action, required: true, default: DeleteUser}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# For Redis engine version 6.0 onwards: Deletes a user group. The user group must first be disassociated from the replication group before it can be deleted. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html).
#
# GET /
# operationId: GET_DeleteUserGroup
export def "get-delete-user-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-group-id: string # The ID of the user group. (required)
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
    query: [{name: UserGroupId, var: user_group_id, required: true}, {name: Action, var: action, required: true, default: DeleteUserGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_group_id: $user_group_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For Redis engine version 6.0 onwards: Deletes a user group. The user group must first be disassociated from the replication group before it can be deleted. For more information, see Using Role Based Access Control (RBAC) (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.RBAC.html).
#
# POST /
# operationId: POST_DeleteUserGroup
export def "post-delete-user-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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
    query: [{name: Action, var: action, required: true, default: DeleteUserGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns information about all provisioned clusters if no cluster identifier is specified, or about a specific cache cluster if a cluster identifier is supplied. By default, abbreviated information about the clusters is returned. You can use the optional ShowCacheNodeInfo flag to retrieve detailed information about the cache nodes associated with the clusters. These details include the DNS address and port for the cache node endpoint. If the cluster is in the creating state, only cluster-level information is displayed until all of the nodes are successfully provisioned. If the cluster is in the deleting state, only cluster-level information is displayed. If cache nodes are currently being added to the cluster, node endpoint information and creation time for the additional nodes are not displayed until they are completely provisioned. When the cluster state is available, the cluster is ready for use. If cache nodes are currently being removed from the cluster, no endpoint information for the removed nodes is displayed.
#
# GET /
# operationId: GET_DescribeCacheClusters
export def "get-describe-cache-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-cluster-id: string # The user-supplied cluster identifier. If this parameter is specified, only information about that specific cluster is returned. This parameter isn't case sensitive.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --show-cache-node-info: oneof<nothing, bool> # An optional flag that can be included in the DescribeCacheCluster request to retrieve information about the individual cache nodes.
  --show-cache-clusters-not-in-replication-groups: oneof<nothing, bool> # An optional flag that can be included in the DescribeCacheCluster request to show only nodes (API/CLI: clusters) that are not members of a replication group. In practice, this mean Memcached and single node Redis clusters.
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
    query: [{name: CacheClusterId, var: cache_cluster_id}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: ShowCacheNodeInfo, var: show_cache_node_info}, {name: ShowCacheClustersNotInReplicationGroups, var: show_cache_clusters_not_in_replication_groups}, {name: Action, var: action, required: true, default: DescribeCacheClusters}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_cluster_id: $cache_cluster_id, max_records: $max_records, marker: $marker, show_cache_node_info: $show_cache_node_info, show_cache_clusters_not_in_replication_groups: $show_cache_clusters_not_in_replication_groups, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all provisioned clusters if no cluster identifier is specified, or about a specific cache cluster if a cluster identifier is supplied. By default, abbreviated information about the clusters is returned. You can use the optional ShowCacheNodeInfo flag to retrieve detailed information about the cache nodes associated with the clusters. These details include the DNS address and port for the cache node endpoint. If the cluster is in the creating state, only cluster-level information is displayed until all of the nodes are successfully provisioned. If the cluster is in the deleting state, only cluster-level information is displayed. If cache nodes are currently being added to the cluster, node endpoint information and creation time for the additional nodes are not displayed until they are completely provisioned. When the cluster state is available, the cluster is ready for use. If cache nodes are currently being removed from the cluster, no endpoint information for the removed nodes is displayed.
#
# POST /
# operationId: POST_DescribeCacheClusters
export def "post-describe-cache-clusters" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheClusters}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns a list of the available cache engines and their versions.
#
# GET /
# operationId: GET_DescribeCacheEngineVersions
export def "get-describe-cache-engine-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string # The cache engine to return. Valid values: memcached | redis
  --engine-version: string # The cache engine version to return. Example: 1.4.14
  --cache-parameter-group-family: string # The name of a specific cache parameter group family to return details for. Valid values are: memcached1.4 | memcached1.5 | memcached1.6 | redis2.6 | redis2.8 | redis3.2 | redis4.0 | redis5.0 | redis6.x | redis6.2 | redis7 Constraints: Must be 1 to 255 alphanumeric characters First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --default-only: oneof<nothing, bool> # If true, specifies that only the default version of the specified engine or engine and major version combination is to be returned.
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
    query: [{name: Engine, var: engine}, {name: EngineVersion, var: engine_version}, {name: CacheParameterGroupFamily, var: cache_parameter_group_family}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: DefaultOnly, var: default_only}, {name: Action, var: action, required: true, default: DescribeCacheEngineVersions}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    engine: $engine, engine_version: $engine_version, cache_parameter_group_family: $cache_parameter_group_family, max_records: $max_records, marker: $marker, default_only: $default_only, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the available cache engines and their versions.
#
# POST /
# operationId: POST_DescribeCacheEngineVersions
export def "post-describe-cache-engine-versions" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheEngineVersions}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns a list of cache parameter group descriptions. If a cache parameter group name is specified, the list contains only the descriptions for that group.
#
# GET /
# operationId: GET_DescribeCacheParameterGroups
export def "get-describe-cache-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-parameter-group-name: string # The name of a specific cache parameter group to return details for.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: CacheParameterGroupName, var: cache_parameter_group_name}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheParameterGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_parameter_group_name: $cache_parameter_group_name, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of cache parameter group descriptions. If a cache parameter group name is specified, the list contains only the descriptions for that group.
#
# POST /
# operationId: POST_DescribeCacheParameterGroups
export def "post-describe-cache-parameter-groups" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheParameterGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns the detailed parameter list for a particular cache parameter group.
#
# GET /
# operationId: GET_DescribeCacheParameters
export def "get-describe-cache-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-parameter-group-name: string # The name of a specific cache parameter group to return details for. (required)
  --source: string # The parameter types to return. Valid values: user | system | engine-default
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: CacheParameterGroupName, var: cache_parameter_group_name, required: true}, {name: Source, var: source}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheParameters}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_parameter_group_name: $cache_parameter_group_name, source: $source, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the detailed parameter list for a particular cache parameter group.
#
# POST /
# operationId: POST_DescribeCacheParameters
export def "post-describe-cache-parameters" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheParameters}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns a list of cache security group descriptions. If a cache security group name is specified, the list contains only the description of that group. This applicable only when you have ElastiCache in Classic setup
#
# GET /
# operationId: GET_DescribeCacheSecurityGroups
export def "get-describe-cache-security-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-security-group-name: string # The name of the cache security group to return details for.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: CacheSecurityGroupName, var: cache_security_group_name}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheSecurityGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_security_group_name: $cache_security_group_name, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of cache security group descriptions. If a cache security group name is specified, the list contains only the description of that group. This applicable only when you have ElastiCache in Classic setup
#
# POST /
# operationId: POST_DescribeCacheSecurityGroups
export def "post-describe-cache-security-groups" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheSecurityGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns a list of cache subnet group descriptions. If a subnet group name is specified, the list contains only the description of that group. This is applicable only when you have ElastiCache in VPC setup. All ElastiCache clusters now launch in VPC by default.
#
# GET /
# operationId: GET_DescribeCacheSubnetGroups
export def "get-describe-cache-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-subnet-group-name: string # The name of the cache subnet group to return details for.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: CacheSubnetGroupName, var: cache_subnet_group_name}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheSubnetGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_subnet_group_name: $cache_subnet_group_name, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of cache subnet group descriptions. If a subnet group name is specified, the list contains only the description of that group. This is applicable only when you have ElastiCache in VPC setup. All ElastiCache clusters now launch in VPC by default.
#
# POST /
# operationId: POST_DescribeCacheSubnetGroups
export def "post-describe-cache-subnet-groups" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeCacheSubnetGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns the default engine and system parameter information for the specified cache engine.
#
# GET /
# operationId: GET_DescribeEngineDefaultParameters
export def "get-describe-engine-default-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-parameter-group-family: string # The name of the cache parameter group family. Valid values are: memcached1.4 | memcached1.5 | memcached1.6 | redis2.6 | redis2.8 | redis3.2 | redis4.0 | redis5.0 | redis6.x | redis6.2 | redis7 (required)
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: CacheParameterGroupFamily, var: cache_parameter_group_family, required: true}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEngineDefaultParameters}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_parameter_group_family: $cache_parameter_group_family, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the default engine and system parameter information for the specified cache engine.
#
# POST /
# operationId: POST_DescribeEngineDefaultParameters
export def "post-describe-engine-default-parameters" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEngineDefaultParameters}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns events related to clusters, cache security groups, and cache parameter groups. You can obtain events specific to a particular cluster, cache security group, or cache parameter group by providing the name as a parameter. By default, only the events occurring within the last hour are returned; however, you can retrieve up to 14 days' worth of events if necessary.
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
  --source-identifier: string # The identifier of the event source for which events are returned. If not specified, all sources are included in the response.
  --source-type: string@source-type-completer # The event source to retrieve events for. If no value is specified, all events are returned.
  --start-time: string # The beginning of the time interval to retrieve events for, specified in ISO 8601 format. Example: 2017-03-30T07:03:49.555Z (format: date-time)
  --end-time: string # The end of the time interval for which to retrieve events, specified in ISO 8601 format. Example: 2017-03-30T07:03:49.555Z (format: date-time)
  --duration: int # The number of minutes worth of events to retrieve.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: SourceIdentifier, var: source_identifier}, {name: SourceType, var: source_type}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: Duration, var: duration}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEvents}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_identifier: $source_identifier, source_type: $source_type, start_time: $start_time, end_time: $end_time, duration: $duration, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns events related to clusters, cache security groups, and cache parameter groups. You can obtain events specific to a particular cluster, cache security group, or cache parameter group by providing the name as a parameter. By default, only the events occurring within the last hour are returned; however, you can retrieve up to 14 days' worth of events if necessary.
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeEvents}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns information about a particular global replication group. If no identifier is specified, returns information about all Global datastores.
#
# GET /
# operationId: GET_DescribeGlobalReplicationGroups
export def "get-describe-global-replication-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --show-member-info: oneof<nothing, bool> # Returns the list of members that comprise the Global datastore.
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: ShowMemberInfo, var: show_member_info}, {name: Action, var: action, required: true, default: DescribeGlobalReplicationGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, max_records: $max_records, marker: $marker, show_member_info: $show_member_info, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a particular global replication group. If no identifier is specified, returns information about all Global datastores.
#
# POST /
# operationId: POST_DescribeGlobalReplicationGroups
export def "post-describe-global-replication-groups" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeGlobalReplicationGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns information about a particular replication group. If no identifier is specified, DescribeReplicationGroups returns information about all replication groups. This operation is valid for Redis only.
#
# GET /
# operationId: GET_DescribeReplicationGroups
export def "get-describe-replication-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The identifier for the replication group to be described. This parameter is not case sensitive. If you do not specify this parameter, information about all replication groups is returned.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: ReplicationGroupId, var: replication_group_id}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeReplicationGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a particular replication group. If no identifier is specified, DescribeReplicationGroups returns information about all replication groups. This operation is valid for Redis only.
#
# POST /
# operationId: POST_DescribeReplicationGroups
export def "post-describe-replication-groups" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeReplicationGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns information about reserved cache nodes for this account, or about a specified reserved cache node.
#
# GET /
# operationId: GET_DescribeReservedCacheNodes
export def "get-describe-reserved-cache-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-cache-node-id: string # The reserved cache node identifier filter value. Use this parameter to show only the reservation that matches the specified reservation ID.
  --reserved-cache-nodes-offering-id: string # The offering identifier filter value. Use this parameter to show only purchased reservations matching the specified offering identifier.
  --cache-node-type: string # The cache node type filter value. Use this parameter to show only those reservations matching the specified cache node type. The following node types are supported by ElastiCache. Generally speaking, the current generation types provide more memory and computational power at lower cost when compared to their equivalent previous generation counterparts. General purpose: Current generation: M6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward): cache.m6g.large, cache.m6g.xlarge, cache.m6g.2xlarge, cache.m6g.4xlarge, cache.m6g.8xlarge, cache.m6g.12xlarge, cache.m6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) M5 node types: cache.m5.large, cache.m5.xlarge, cache.m5.2xlarge, cache.m5.4xlarge, cache.m5.12xlarge, cache.m5.24xlarge M4 node types: cache.m4.large, cache.m4.xlarge, cache.m4.2xlarge, cache.m4.4xlarge, cache.m4.10xlarge T4g node types (available only for Redis engine version 5.0.6 onward and Memcached engine version 1.5.16 onward): cache.t4g.micro, cache.t4g.small, cache.t4g.medium T3 node types: cache.t3.micro, cache.t3.small, cache.t3.medium T2 node types: cache.t2.micro, cache.t2.small, cache.t2.medium Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) T1 node types: cache.t1.micro M1 node types: cache.m1.small, cache.m1.medium, cache.m1.large, cache.m1.xlarge M3 node types: cache.m3.medium, cache.m3.large, cache.m3.xlarge, cache.m3.2xlarge Compute optimized: Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) C1 node types: cache.c1.xlarge Memory optimized: Current generation: R6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward). cache.r6g.large, cache.r6g.xlarge, cache.r6g.2xlarge, cache.r6g.4xlarge, cache.r6g.8xlarge, cache.r6g.12xlarge, cache.r6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) R5 node types: cache.r5.large, cache.r5.xlarge, cache.r5.2xlarge, cache.r5.4xlarge, cache.r5.12xlarge, cache.r5.24xlarge R4 node types: cache.r4.large, cache.r4.xlarge, cache.r4.2xlarge, cache.r4.4xlarge, cache.r4.8xlarge, cache.r4.16xlarge Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) M2 node types: cache.m2.xlarge, cache.m2.2xlarge, cache.m2.4xlarge R3 node types: cache.r3.large, cache.r3.xlarge, cache.r3.2xlarge, cache.r3.4xlarge, cache.r3.8xlarge Additional node type info All current generation instance types are created in Amazon VPC by default. Redis append-only files (AOF) are not supported for T1 or T2 instances. Redis Multi-AZ with automatic failover is not supported on T1 instances. Redis configuration variables appendonly and appendfsync are not supported on Redis version 2.8.22 and later.
  --duration: string # The duration filter value, specified in years or seconds. Use this parameter to show only reservations for this duration. Valid Values: 1 | 3 | 31536000 | 94608000
  --product-description: string # The product description filter value. Use this parameter to show only those reservations matching the specified product description.
  --offering-type: string # The offering type filter value. Use this parameter to show only the available offerings matching the specified offering type. Valid values: "Light Utilization"|"Medium Utilization"|"Heavy Utilization"|"All Upfront"|"Partial Upfront"| "No Upfront"
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: ReservedCacheNodeId, var: reserved_cache_node_id}, {name: ReservedCacheNodesOfferingId, var: reserved_cache_nodes_offering_id}, {name: CacheNodeType, var: cache_node_type}, {name: Duration, var: duration}, {name: ProductDescription, var: product_description}, {name: OfferingType, var: offering_type}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeReservedCacheNodes}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    reserved_cache_node_id: $reserved_cache_node_id, reserved_cache_nodes_offering_id: $reserved_cache_nodes_offering_id, cache_node_type: $cache_node_type, duration: $duration, product_description: $product_description, offering_type: $offering_type, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about reserved cache nodes for this account, or about a specified reserved cache node.
#
# POST /
# operationId: POST_DescribeReservedCacheNodes
export def "post-describe-reserved-cache-nodes" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeReservedCacheNodes}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Lists available reserved cache node offerings.
#
# GET /
# operationId: GET_DescribeReservedCacheNodesOfferings
export def "get-describe-reserved-cache-nodes-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-cache-nodes-offering-id: string # The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier. Example: 438012d3-4052-4cc7-b2e3-8d3372e0e706
  --cache-node-type: string # The cache node type filter value. Use this parameter to show only the available offerings matching the specified cache node type. The following node types are supported by ElastiCache. Generally speaking, the current generation types provide more memory and computational power at lower cost when compared to their equivalent previous generation counterparts. General purpose: Current generation: M6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward): cache.m6g.large, cache.m6g.xlarge, cache.m6g.2xlarge, cache.m6g.4xlarge, cache.m6g.8xlarge, cache.m6g.12xlarge, cache.m6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) M5 node types: cache.m5.large, cache.m5.xlarge, cache.m5.2xlarge, cache.m5.4xlarge, cache.m5.12xlarge, cache.m5.24xlarge M4 node types: cache.m4.large, cache.m4.xlarge, cache.m4.2xlarge, cache.m4.4xlarge, cache.m4.10xlarge T4g node types (available only for Redis engine version 5.0.6 onward and Memcached engine version 1.5.16 onward): cache.t4g.micro, cache.t4g.small, cache.t4g.medium T3 node types: cache.t3.micro, cache.t3.small, cache.t3.medium T2 node types: cache.t2.micro, cache.t2.small, cache.t2.medium Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) T1 node types: cache.t1.micro M1 node types: cache.m1.small, cache.m1.medium, cache.m1.large, cache.m1.xlarge M3 node types: cache.m3.medium, cache.m3.large, cache.m3.xlarge, cache.m3.2xlarge Compute optimized: Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) C1 node types: cache.c1.xlarge Memory optimized: Current generation: R6g node types (available only for Redis engine version 5.0.6 onward and for Memcached engine version 1.5.16 onward). cache.r6g.large, cache.r6g.xlarge, cache.r6g.2xlarge, cache.r6g.4xlarge, cache.r6g.8xlarge, cache.r6g.12xlarge, cache.r6g.16xlarge For region availability, see Supported Node Types (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html#CacheNodes.SupportedTypesByRegion) R5 node types: cache.r5.large, cache.r5.xlarge, cache.r5.2xlarge, cache.r5.4xlarge, cache.r5.12xlarge, cache.r5.24xlarge R4 node types: cache.r4.large, cache.r4.xlarge, cache.r4.2xlarge, cache.r4.4xlarge, cache.r4.8xlarge, cache.r4.16xlarge Previous generation: (not recommended. Existing clusters are still supported but creation of new clusters is not supported for these types.) M2 node types: cache.m2.xlarge, cache.m2.2xlarge, cache.m2.4xlarge R3 node types: cache.r3.large, cache.r3.xlarge, cache.r3.2xlarge, cache.r3.4xlarge, cache.r3.8xlarge Additional node type info All current generation instance types are created in Amazon VPC by default. Redis append-only files (AOF) are not supported for T1 or T2 instances. Redis Multi-AZ with automatic failover is not supported on T1 instances. Redis configuration variables appendonly and appendfsync are not supported on Redis version 2.8.22 and later.
  --duration: string # Duration filter value, specified in years or seconds. Use this parameter to show only reservations for a given duration. Valid Values: 1 | 3 | 31536000 | 94608000
  --product-description: string # The product description filter value. Use this parameter to show only the available offerings matching the specified product description.
  --offering-type: string # The offering type filter value. Use this parameter to show only the available offerings matching the specified offering type. Valid Values: "Light Utilization"|"Medium Utilization"|"Heavy Utilization" |"All Upfront"|"Partial Upfront"| "No Upfront"
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: minimum 20; maximum 100.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: ReservedCacheNodesOfferingId, var: reserved_cache_nodes_offering_id}, {name: CacheNodeType, var: cache_node_type}, {name: Duration, var: duration}, {name: ProductDescription, var: product_description}, {name: OfferingType, var: offering_type}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeReservedCacheNodesOfferings}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    reserved_cache_nodes_offering_id: $reserved_cache_nodes_offering_id, cache_node_type: $cache_node_type, duration: $duration, product_description: $product_description, offering_type: $offering_type, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available reserved cache node offerings.
#
# POST /
# operationId: POST_DescribeReservedCacheNodesOfferings
export def "post-describe-reserved-cache-nodes-offerings" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeReservedCacheNodesOfferings}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns details of the service updates
#
# GET /
# operationId: GET_DescribeServiceUpdates
export def "get-describe-service-updates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-update-name: string # The unique ID of the service update
  --service-update-status: list<string> # The status of the service update
  --max-records: int # The maximum number of records to include in the response
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: ServiceUpdateName, var: service_update_name}, {name: ServiceUpdateStatus, var: service_update_status, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeServiceUpdates}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    service_update_name: $service_update_name, service_update_status: $service_update_status, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details of the service updates
#
# POST /
# operationId: POST_DescribeServiceUpdates
export def "post-describe-service-updates" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeServiceUpdates}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns information about cluster or replication group snapshots. By default, DescribeSnapshots lists all of your snapshots; it can optionally describe a single snapshot, or just the snapshots associated with a particular cache cluster. This operation is valid for Redis only.
#
# GET /
# operationId: GET_DescribeSnapshots
export def "get-describe-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # A user-supplied replication group identifier. If this parameter is specified, only snapshots associated with that specific replication group are described.
  --cache-cluster-id: string # A user-supplied cluster identifier. If this parameter is specified, only snapshots associated with that specific cluster are described.
  --snapshot-name: string # A user-supplied name of the snapshot. If this parameter is specified, only this snapshot are described.
  --snapshot-source: string # If set to system, the output shows snapshots that were automatically created by ElastiCache. If set to user the output shows snapshots that were manually created. If omitted, the output shows both automatically and manually created snapshots.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved. Default: 50 Constraints: minimum 20; maximum 50.
  --show-node-group-config: oneof<nothing, bool> # A Boolean value which if true, the node group (shard) configuration is included in the snapshot description.
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
    query: [{name: ReplicationGroupId, var: replication_group_id}, {name: CacheClusterId, var: cache_cluster_id}, {name: SnapshotName, var: snapshot_name}, {name: SnapshotSource, var: snapshot_source}, {name: Marker, var: marker}, {name: MaxRecords, var: max_records}, {name: ShowNodeGroupConfig, var: show_node_group_config}, {name: Action, var: action, required: true, default: DescribeSnapshots}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, cache_cluster_id: $cache_cluster_id, snapshot_name: $snapshot_name, snapshot_source: $snapshot_source, marker: $marker, max_records: $max_records, show_node_group_config: $show_node_group_config, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about cluster or replication group snapshots. By default, DescribeSnapshots lists all of your snapshots; it can optionally describe a single snapshot, or just the snapshots associated with a particular cache cluster. This operation is valid for Redis only.
#
# POST /
# operationId: POST_DescribeSnapshots
export def "post-describe-snapshots" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeSnapshots}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns details of the update actions
#
# GET /
# operationId: GET_DescribeUpdateActions
export def "get-describe-update-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-update-name: string # The unique ID of the service update
  --replication-group-ids: list<string> # The replication group IDs
  --cache-cluster-ids: list<string> # The cache cluster IDs
  --engine: string # The Elasticache engine to which the update applies. Either Redis or Memcached
  --service-update-status: list<string> # The status of the service update
  --service-update-time-range: record # The range of time specified to search for service updates that are in available status
  --update-action-status: list<string> # The status of the update action.
  --show-node-level-update-status: oneof<nothing, bool> # Dictates whether to include node level update status in the response
  --max-records: int # The maximum number of records to include in the response
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
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
    query: [{name: ServiceUpdateName, var: service_update_name}, {name: ReplicationGroupIds, var: replication_group_ids, style: multi}, {name: CacheClusterIds, var: cache_cluster_ids, style: multi}, {name: Engine, var: engine}, {name: ServiceUpdateStatus, var: service_update_status, style: multi}, {name: ServiceUpdateTimeRange, var: service_update_time_range, style: multi}, {name: UpdateActionStatus, var: update_action_status, style: multi}, {name: ShowNodeLevelUpdateStatus, var: show_node_level_update_status}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeUpdateActions}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    service_update_name: $service_update_name, replication_group_ids: $replication_group_ids, cache_cluster_ids: $cache_cluster_ids, engine: $engine, service_update_status: $service_update_status, service_update_time_range: $service_update_time_range, update_action_status: $update_action_status, show_node_level_update_status: $show_node_level_update_status, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details of the update actions
#
# POST /
# operationId: POST_DescribeUpdateActions
export def "post-describe-update-actions" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeUpdateActions}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns a list of user groups.
#
# GET /
# operationId: GET_DescribeUserGroups
export def "get-describe-user-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-group-id: string # The ID of the user group.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. >
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
    query: [{name: UserGroupId, var: user_group_id}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeUserGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_group_id: $user_group_id, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user groups.
#
# POST /
# operationId: POST_DescribeUserGroups
export def "post-describe-user-groups" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeUserGroups}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Returns a list of users.
#
# GET /
# operationId: GET_DescribeUsers
export def "get-describe-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string # The Redis engine.
  --user-id: string # The ID of the user.
  --filters: list # Filter to determine the list of User IDs to return.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a marker is included in the response so that the remaining results can be retrieved.
  --marker: string # An optional marker returned from a prior request. Use this marker for pagination of results from this operation. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. >
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
    query: [{name: Engine, var: engine}, {name: UserId, var: user_id}, {name: Filters, var: filters, style: multi}, {name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeUsers}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    engine: $engine, user_id: $user_id, filters: $filters, max_records: $max_records, marker: $marker, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users.
#
# POST /
# operationId: POST_DescribeUsers
export def "post-describe-users" [
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
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}, {name: Action, var: action, required: true, default: DescribeUsers}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Remove a secondary cluster from the Global datastore using the Global datastore name. The secondary cluster will no longer receive updates from the primary cluster, but will remain as a standalone cluster in that Amazon region.
#
# GET /
# operationId: GET_DisassociateGlobalReplicationGroup
export def "get-disassociate-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore (required)
  --replication-group-id: string # The name of the secondary cluster you wish to remove from the Global datastore (required)
  --replication-group-region: string # The Amazon region of secondary cluster you wish to remove from the Global datastore (required)
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id, required: true}, {name: ReplicationGroupId, var: replication_group_id, required: true}, {name: ReplicationGroupRegion, var: replication_group_region, required: true}, {name: Action, var: action, required: true, default: DisassociateGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, replication_group_id: $replication_group_id, replication_group_region: $replication_group_region, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a secondary cluster from the Global datastore using the Global datastore name. The secondary cluster will no longer receive updates from the primary cluster, but will remain as a standalone cluster in that Amazon region.
#
# POST /
# operationId: POST_DisassociateGlobalReplicationGroup
export def "post-disassociate-global-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: DisassociateGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Used to failover the primary region to a secondary region. The secondary region will become primary, and all other clusters will become secondary.
#
# GET /
# operationId: GET_FailoverGlobalReplicationGroup
export def "get-failover-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore (required)
  --primary-region: string # The Amazon region of the primary cluster of the Global datastore (required)
  --primary-replication-group-id: string # The name of the primary replication group (required)
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id, required: true}, {name: PrimaryRegion, var: primary_region, required: true}, {name: PrimaryReplicationGroupId, var: primary_replication_group_id, required: true}, {name: Action, var: action, required: true, default: FailoverGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, primary_region: $primary_region, primary_replication_group_id: $primary_replication_group_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to failover the primary region to a secondary region. The secondary region will become primary, and all other clusters will become secondary.
#
# POST /
# operationId: POST_FailoverGlobalReplicationGroup
export def "post-failover-global-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: FailoverGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Increase the number of node groups in the Global datastore
#
# GET /
# operationId: GET_IncreaseNodeGroupsInGlobalReplicationGroup
export def "get-increase-node-groups-in-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore (required)
  --node-group-count: int # The number of node groups you wish to add (required)
  --regional-configurations: list # Describes the replication group IDs, the Amazon regions where they are stored and the shard configuration for each that comprise the Global datastore
  --apply-immediately: oneof<nothing, bool> # Indicates that the process begins immediately. At present, the only permitted value for this parameter is true. (required)
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id, required: true}, {name: NodeGroupCount, var: node_group_count, required: true}, {name: RegionalConfigurations, var: regional_configurations, style: multi}, {name: ApplyImmediately, var: apply_immediately, required: true}, {name: Action, var: action, required: true, default: IncreaseNodeGroupsInGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, node_group_count: $node_group_count, regional_configurations: $regional_configurations, apply_immediately: $apply_immediately, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Increase the number of node groups in the Global datastore
#
# POST /
# operationId: POST_IncreaseNodeGroupsInGlobalReplicationGroup
export def "post-increase-node-groups-in-global-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: IncreaseNodeGroupsInGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Dynamically increases the number of replicas in a Redis (cluster mode disabled) replication group or the number of replica nodes in one or more node groups (shards) of a Redis (cluster mode enabled) replication group. This operation is performed with no cluster down time.
#
# GET /
# operationId: GET_IncreaseReplicaCount
export def "get-increase-replica-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The id of the replication group to which you want to add replica nodes. (required)
  --new-replica-count: int # The number of read replica nodes you want at the completion of this operation. For Redis (cluster mode disabled) replication groups, this is the number of replica nodes in the replication group. For Redis (cluster mode enabled) replication groups, this is the number of replica nodes in each of the replication group's node groups.
  --replica-configuration: list # A list of ConfigureShard objects that can be used to configure each shard in a Redis (cluster mode enabled) replication group. The ConfigureShard has three members: NewReplicaCount, NodeGroupId, and PreferredAvailabilityZones.
  --apply-immediately: oneof<nothing, bool> # If True, the number of replica nodes is increased immediately. ApplyImmediately=False is not currently supported. (required)
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: NewReplicaCount, var: new_replica_count}, {name: ReplicaConfiguration, var: replica_configuration, style: multi}, {name: ApplyImmediately, var: apply_immediately, required: true}, {name: Action, var: action, required: true, default: IncreaseReplicaCount}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, new_replica_count: $new_replica_count, replica_configuration: $replica_configuration, apply_immediately: $apply_immediately, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dynamically increases the number of replicas in a Redis (cluster mode disabled) replication group or the number of replica nodes in one or more node groups (shards) of a Redis (cluster mode enabled) replication group. This operation is performed with no cluster down time.
#
# POST /
# operationId: POST_IncreaseReplicaCount
export def "post-increase-replica-count" [
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
    query: [{name: Action, var: action, required: true, default: IncreaseReplicaCount}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Lists all available node types that you can scale your Redis cluster's or replication group's current node type. When you use the ModifyCacheCluster or ModifyReplicationGroup operations to scale your cluster or replication group, the value of the CacheNodeType parameter must be one of the node types returned by this operation.
#
# GET /
# operationId: GET_ListAllowedNodeTypeModifications
export def "get-list-allowed-node-type-modifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-cluster-id: string # The name of the cluster you want to scale up to a larger node instanced type. ElastiCache uses the cluster id to identify the current node type of this cluster and from that to create a list of node types you can scale up to. You must provide a value for either the CacheClusterId or the ReplicationGroupId.
  --replication-group-id: string # The name of the replication group want to scale up to a larger node type. ElastiCache uses the replication group id to identify the current node type being used by this replication group, and from that to create a list of node types you can scale up to. You must provide a value for either the CacheClusterId or the ReplicationGroupId.
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
    query: [{name: CacheClusterId, var: cache_cluster_id}, {name: ReplicationGroupId, var: replication_group_id}, {name: Action, var: action, required: true, default: ListAllowedNodeTypeModifications}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_cluster_id: $cache_cluster_id, replication_group_id: $replication_group_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all available node types that you can scale your Redis cluster's or replication group's current node type. When you use the ModifyCacheCluster or ModifyReplicationGroup operations to scale your cluster or replication group, the value of the CacheNodeType parameter must be one of the node types returned by this operation.
#
# POST /
# operationId: POST_ListAllowedNodeTypeModifications
export def "post-list-allowed-node-type-modifications" [
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
    query: [{name: Action, var: action, required: true, default: ListAllowedNodeTypeModifications}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Lists all tags currently on a named resource. A tag is a key-value pair where the key and value are case-sensitive. You can use tags to categorize and track all your ElastiCache resources, with the exception of global replication group. When you add or remove tags on replication groups, those actions will be replicated to all nodes in the replication group. For more information, see Resource-level permissions (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.ResourceLevelPermissions.html). If the cluster is not in the available state, ListTagsForResource returns an error.
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
  --resource-name: string # The Amazon Resource Name (ARN) of the resource for which you want the list of tags, for example arn:aws:elasticache:us-west-2:0123456789:cluster:myCluster or arn:aws:elasticache:us-west-2:0123456789:snapshot:mySnapshot. For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html). (required)
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
    query: [{name: ResourceName, var: resource_name, required: true}, {name: Action, var: action, required: true, default: ListTagsForResource}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all tags currently on a named resource. A tag is a key-value pair where the key and value are case-sensitive. You can use tags to categorize and track all your ElastiCache resources, with the exception of global replication group. When you add or remove tags on replication groups, those actions will be replicated to all nodes in the replication group. For more information, see Resource-level permissions (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.ResourceLevelPermissions.html). If the cluster is not in the available state, ListTagsForResource returns an error.
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
    query: [{name: Action, var: action, required: true, default: ListTagsForResource}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Modifies the settings for a cluster. You can use this operation to change one or more cluster configuration parameters by specifying the parameters and the new values.
#
# GET /
# operationId: GET_ModifyCacheCluster
export def "get-modify-cache-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-cluster-id: string # The cluster identifier. This value is stored as a lowercase string. (required)
  --num-cache-nodes: int # The number of cache nodes that the cluster should have. If the value for NumCacheNodes is greater than the sum of the number of current cache nodes and the number of cache nodes pending creation (which may be zero), more nodes are added. If the value is less than the number of existing cache nodes, nodes are removed. If the value is equal to the number of current cache nodes, any pending add or remove requests are canceled. If you are removing cache nodes, you must use the CacheNodeIdsToRemove parameter to provide the IDs of the specific cache nodes to remove. For clusters running Redis, this value must be 1. For clusters running Memcached, this value must be between 1 and 40. Adding or removing Memcached cache nodes can be applied immediately or as a pending operation (see ApplyImmediately). A pending operation to modify the number of cache nodes in a cluster during its maintenance window, whether by adding or removing nodes in accordance with the scale out architecture, is not queued. The customer's latest request to add or remove nodes to the cluster overrides any previous pending operations to modify the number of cache nodes in the cluster. For example, a request to remove 2 nodes would override a previous pending operation to remove 3 nodes. Similarly, a request to add 2 nodes would override a previous pending operation to remove 3 nodes and vice versa. As Memcached cache nodes may now be provisioned in different Availability Zones with flexible cache node placement, a request to add nodes does not automatically override a previous pending operation to add nodes. The customer can modify the previous pending operation to add more nodes or explicitly cancel the pending request and retry the new request. To cancel pending operations to modify the number of cache nodes in a cluster, use the ModifyCacheCluster request and set NumCacheNodes equal to the number of cache nodes currently in the cluster.
  --cache-node-ids-to-remove: list<string> # A list of cache node IDs to be removed. A node ID is a numeric identifier (0001, 0002, etc.). This parameter is only valid when NumCacheNodes is less than the existing number of cache nodes. The number of cache node IDs supplied in this parameter must match the difference between the existing number of cache nodes in the cluster or pending cache nodes, whichever is greater, and the value of NumCacheNodes in the request. For example: If you have 3 active cache nodes, 7 pending cache nodes, and the number of cache nodes in this ModifyCacheCluster call is 5, you must list 2 (7 - 5) cache node IDs to remove.
  --az-mode: string@az-mode-completer # Specifies whether the new nodes in this Memcached cluster are all created in a single Availability Zone or created across multiple Availability Zones. Valid values: single-az | cross-az. This option is only supported for Memcached clusters. You cannot specify single-az if the Memcached cluster already has cache nodes in different Availability Zones. If cross-az is specified, existing Memcached nodes remain in their current Availability Zone. Only newly created nodes are located in different Availability Zones.
  --new-availability-zones: list<string> # This option is only supported on Memcached clusters. The list of Availability Zones where the new Memcached cache nodes are created. This parameter is only valid when NumCacheNodes in the request is greater than the sum of the number of active cache nodes and the number of cache nodes pending creation (which may be zero). The number of Availability Zones supplied in this list must match the cache nodes being added in this request. Scenarios: Scenario 1: You have 3 active nodes and wish to add 2 nodes. Specify NumCacheNodes=5 (3 + 2) and optionally specify two Availability Zones for the two new nodes. Scenario 2: You have 3 active nodes and 2 nodes pending creation (from the scenario 1 call) and want to add 1 more node. Specify NumCacheNodes=6 ((3 + 2) + 1) and optionally specify an Availability Zone for the new node. Scenario 3: You want to cancel all pending operations. Specify NumCacheNodes=3 to cancel all pending operations. The Availability Zone placement of nodes pending creation cannot be modified. If you wish to cancel any nodes pending creation, add 0 nodes by setting NumCacheNodes to the number of current nodes. If cross-az is specified, existing Memcached nodes remain in their current Availability Zone. Only newly created nodes can be located in different Availability Zones. For guidance on how to move existing Memcached nodes to different Availability Zones, see the Availability Zone Considerations section of Cache Node Considerations for Memcached (https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/CacheNodes.SupportedTypes.html). Impact of new add/remove requests upon pending requests Scenario-1 Pending Action: Delete New Request: Delete Result: The new delete, pending or immediate, replaces the pending delete. Scenario-2 Pending Action: Delete New Request: Create Result: The new create, pending or immediate, replaces the pending delete. Scenario-3 Pending Action: Create New Request: Delete Result: The new delete, pending or immediate, replaces the pending create. Scenario-4 Pending Action: Create New Request: Create Result: The new create is added to the pending create. Important: If the new create request is Apply Immediately - Yes, all creates are performed immediately. If the new create request is Apply Immediately - No, all creates are pending.
  --cache-security-group-names: list<string> # A list of cache security group names to authorize on this cluster. This change is asynchronously applied as soon as possible. You can use this parameter only with clusters that are created outside of an Amazon Virtual Private Cloud (Amazon VPC). Constraints: Must contain no more than 255 alphanumeric characters. Must not be "Default".
  --security-group-ids: list<string> # Specifies the VPC Security Groups associated with the cluster. This parameter can be used only with clusters that are created in an Amazon Virtual Private Cloud (Amazon VPC).
  --preferred-maintenance-window: string # Specifies the weekly time range during which maintenance on the cluster is performed. It is specified as a range in the format ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Valid values for ddd are: sun mon tue wed thu fri sat Example: sun:23:00-mon:01:30
  --notification-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic to which notifications are sent. The Amazon SNS topic owner must be same as the cluster owner.
  --cache-parameter-group-name: string # The name of the cache parameter group to apply to this cluster. This change is asynchronously applied as soon as possible for parameters when the ApplyImmediately parameter is specified as true for this request.
  --notification-topic-status: string # The status of the Amazon SNS notification topic. Notifications are sent only if the status is active. Valid values: active | inactive
  --apply-immediately: oneof<nothing, bool> # If true, this parameter causes the modifications in this request and any pending modifications to be applied, asynchronously and as soon as possible, regardless of the PreferredMaintenanceWindow setting for the cluster. If false, changes to the cluster are applied on the next maintenance reboot, or the next failure reboot, whichever occurs first. If you perform a ModifyCacheCluster before a pending modification is applied, the pending modification is replaced by the newer modification. Valid values: true | false Default: false
  --engine-version: string # The upgraded version of the cache engine to be run on the cache nodes. Important: You can upgrade to a newer engine version (see Selecting a Cache Engine and Version (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SelectEngine.html#VersionManagement)), but you cannot downgrade to an earlier engine version. If you want to use an earlier engine version, you must delete the existing cluster and create it anew with the earlier engine version.
  --auto-minor-version-upgrade: oneof<nothing, bool> # If you are running Redis engine version 6.0 or later, set this parameter to yes if you want to opt-in to the next auto minor version upgrade campaign. This parameter is disabled for previous versions.
  --snapshot-retention-limit: int # The number of days for which ElastiCache retains automatic cluster snapshots before deleting them. For example, if you set SnapshotRetentionLimit to 5, a snapshot that was taken today is retained for 5 days before being deleted. If the value of SnapshotRetentionLimit is set to zero (0), backups are turned off.
  --snapshot-window: string # The daily time range (in UTC) during which ElastiCache begins taking a daily snapshot of your cluster.
  --cache-node-type: string # A valid cache node type that you want to scale this cluster up to.
  --auth-token: string # Reserved parameter. The password used to access a password protected server. This parameter must be specified with the auth-token-update parameter. Password constraints: Must be only printable ASCII characters Must be at least 16 characters and no more than 128 characters in length Cannot contain any of the following characters: '/', '"', or '@', '%' For more information, see AUTH password at AUTH (http://redis.io/commands/AUTH).
  --auth-token-update-strategy: string@auth-token-update-strategy-completer # Specifies the strategy to use to update the AUTH token. This parameter must be specified with the auth-token parameter. Possible values: Rotate Set For more information, see Authenticating Users with Redis AUTH (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/auth.html)
  --log-delivery-configurations: list # Specifies the destination, format and type of the logs.
  --ip-discovery: string@ip-discovery-completer # The network type you choose when modifying a cluster, either ipv4 | ipv6. IPv6 is supported for workloads using Redis engine version 6.2 onward or Memcached engine version 1.6.6 on all instances built on the Nitro system (https://aws.amazon.com/ec2/nitro/).
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
    query: [{name: CacheClusterId, var: cache_cluster_id, required: true}, {name: NumCacheNodes, var: num_cache_nodes}, {name: CacheNodeIdsToRemove, var: cache_node_ids_to_remove, style: multi}, {name: AZMode, var: az_mode}, {name: NewAvailabilityZones, var: new_availability_zones, style: multi}, {name: CacheSecurityGroupNames, var: cache_security_group_names, style: multi}, {name: SecurityGroupIds, var: security_group_ids, style: multi}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: NotificationTopicArn, var: notification_topic_arn}, {name: CacheParameterGroupName, var: cache_parameter_group_name}, {name: NotificationTopicStatus, var: notification_topic_status}, {name: ApplyImmediately, var: apply_immediately}, {name: EngineVersion, var: engine_version}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: SnapshotRetentionLimit, var: snapshot_retention_limit}, {name: SnapshotWindow, var: snapshot_window}, {name: CacheNodeType, var: cache_node_type}, {name: AuthToken, var: auth_token}, {name: AuthTokenUpdateStrategy, var: auth_token_update_strategy}, {name: LogDeliveryConfigurations, var: log_delivery_configurations, style: multi}, {name: IpDiscovery, var: ip_discovery}, {name: Action, var: action, required: true, default: ModifyCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_cluster_id: $cache_cluster_id, num_cache_nodes: $num_cache_nodes, cache_node_ids_to_remove: $cache_node_ids_to_remove, az_mode: $az_mode, new_availability_zones: $new_availability_zones, cache_security_group_names: $cache_security_group_names, security_group_ids: $security_group_ids, preferred_maintenance_window: $preferred_maintenance_window, notification_topic_arn: $notification_topic_arn, cache_parameter_group_name: $cache_parameter_group_name, notification_topic_status: $notification_topic_status, apply_immediately: $apply_immediately, engine_version: $engine_version, auto_minor_version_upgrade: $auto_minor_version_upgrade, snapshot_retention_limit: $snapshot_retention_limit, snapshot_window: $snapshot_window, cache_node_type: $cache_node_type, auth_token: $auth_token, auth_token_update_strategy: $auth_token_update_strategy, log_delivery_configurations: $log_delivery_configurations, ip_discovery: $ip_discovery, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the settings for a cluster. You can use this operation to change one or more cluster configuration parameters by specifying the parameters and the new values.
#
# POST /
# operationId: POST_ModifyCacheCluster
export def "post-modify-cache-cluster" [
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
    query: [{name: Action, var: action, required: true, default: ModifyCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Modifies the parameters of a cache parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
#
# GET /
# operationId: GET_ModifyCacheParameterGroup
export def "get-modify-cache-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-parameter-group-name: string # The name of the cache parameter group to modify. (required)
  --parameter-name-values: list # An array of parameter names and values for the parameter update. You must supply at least one parameter name and value; subsequent arguments are optional. A maximum of 20 parameters may be modified per request. (required)
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
    query: [{name: CacheParameterGroupName, var: cache_parameter_group_name, required: true}, {name: ParameterNameValues, var: parameter_name_values, style: multi, required: true}, {name: Action, var: action, required: true, default: ModifyCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_parameter_group_name: $cache_parameter_group_name, parameter_name_values: $parameter_name_values, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the parameters of a cache parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
#
# POST /
# operationId: POST_ModifyCacheParameterGroup
export def "post-modify-cache-parameter-group" [
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
    query: [{name: Action, var: action, required: true, default: ModifyCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Modifies an existing cache subnet group.
#
# GET /
# operationId: GET_ModifyCacheSubnetGroup
export def "get-modify-cache-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-subnet-group-name: string # The name for the cache subnet group. This value is stored as a lowercase string. Constraints: Must contain no more than 255 alphanumeric characters or hyphens. Example: mysubnetgroup (required)
  --cache-subnet-group-description: string # A description of the cache subnet group.
  --subnet-ids: list<string> # The EC2 subnet IDs for the cache subnet group.
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
    query: [{name: CacheSubnetGroupName, var: cache_subnet_group_name, required: true}, {name: CacheSubnetGroupDescription, var: cache_subnet_group_description}, {name: SubnetIds, var: subnet_ids, style: multi}, {name: Action, var: action, required: true, default: ModifyCacheSubnetGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_subnet_group_name: $cache_subnet_group_name, cache_subnet_group_description: $cache_subnet_group_description, subnet_ids: $subnet_ids, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing cache subnet group.
#
# POST /
# operationId: POST_ModifyCacheSubnetGroup
export def "post-modify-cache-subnet-group" [
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
    query: [{name: Action, var: action, required: true, default: ModifyCacheSubnetGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Modifies the settings for a Global datastore.
#
# GET /
# operationId: GET_ModifyGlobalReplicationGroup
export def "get-modify-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore (required)
  --apply-immediately: oneof<nothing, bool> # This parameter causes the modifications in this request and any pending modifications to be applied, asynchronously and as soon as possible. Modifications to Global Replication Groups cannot be requested to be applied in PreferredMaintenceWindow. (required)
  --cache-node-type: string # A valid cache node type that you want to scale this Global datastore to.
  --engine-version: string # The upgraded version of the cache engine to be run on the clusters in the Global datastore.
  --cache-parameter-group-name: string # The name of the cache parameter group to use with the Global datastore. It must be compatible with the major engine version used by the Global datastore.
  --global-replication-group-description: string # A description of the Global datastore
  --automatic-failover-enabled: oneof<nothing, bool> # Determines whether a read replica is automatically promoted to read/write primary if the existing primary encounters a failure.
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id, required: true}, {name: ApplyImmediately, var: apply_immediately, required: true}, {name: CacheNodeType, var: cache_node_type}, {name: EngineVersion, var: engine_version}, {name: CacheParameterGroupName, var: cache_parameter_group_name}, {name: GlobalReplicationGroupDescription, var: global_replication_group_description}, {name: AutomaticFailoverEnabled, var: automatic_failover_enabled}, {name: Action, var: action, required: true, default: ModifyGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, apply_immediately: $apply_immediately, cache_node_type: $cache_node_type, engine_version: $engine_version, cache_parameter_group_name: $cache_parameter_group_name, global_replication_group_description: $global_replication_group_description, automatic_failover_enabled: $automatic_failover_enabled, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the settings for a Global datastore.
#
# POST /
# operationId: POST_ModifyGlobalReplicationGroup
export def "post-modify-global-replication-group" [
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
    query: [{name: Action, var: action, required: true, default: ModifyGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Modifies the settings for a replication group. Scaling for Amazon ElastiCache for Redis (cluster mode enabled) (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/scaling-redis-cluster-mode-enabled.html) in the ElastiCache User Guide ModifyReplicationGroupShardConfiguration (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_ModifyReplicationGroupShardConfiguration.html) in the ElastiCache API Reference This operation is valid for Redis only.
#
# GET /
# operationId: GET_ModifyReplicationGroup
export def "get-modify-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The identifier of the replication group to modify. (required)
  --replication-group-description: string # A description for the replication group. Maximum length is 255 characters.
  --primary-cluster-id: string # For replication groups with a single primary, if this parameter is specified, ElastiCache promotes the specified cluster in the specified replication group to the primary role. The nodes of all other clusters in the replication group are read replicas.
  --snapshotting-cluster-id: string # The cluster ID that is used as the daily snapshot source for the replication group. This parameter cannot be set for Redis (cluster mode enabled) replication groups.
  --automatic-failover-enabled: oneof<nothing, bool> # Determines whether a read replica is automatically promoted to read/write primary if the existing primary encounters a failure. Valid values: true | false
  --multi-az-enabled: oneof<nothing, bool> # A flag to indicate MultiAZ is enabled.
  --node-group-id: string # Deprecated. This parameter is not used.
  --cache-security-group-names: list<string> # A list of cache security group names to authorize for the clusters in this replication group. This change is asynchronously applied as soon as possible. This parameter can be used only with replication group containing clusters running outside of an Amazon Virtual Private Cloud (Amazon VPC). Constraints: Must contain no more than 255 alphanumeric characters. Must not be Default.
  --security-group-ids: list<string> # Specifies the VPC Security Groups associated with the clusters in the replication group. This parameter can be used only with replication group containing clusters running in an Amazon Virtual Private Cloud (Amazon VPC).
  --preferred-maintenance-window: string # Specifies the weekly time range during which maintenance on the cluster is performed. It is specified as a range in the format ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Valid values for ddd are: sun mon tue wed thu fri sat Example: sun:23:00-mon:01:30
  --notification-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic to which notifications are sent. The Amazon SNS topic owner must be same as the replication group owner.
  --cache-parameter-group-name: string # The name of the cache parameter group to apply to all of the clusters in this replication group. This change is asynchronously applied as soon as possible for parameters when the ApplyImmediately parameter is specified as true for this request.
  --notification-topic-status: string # The status of the Amazon SNS notification topic for the replication group. Notifications are sent only if the status is active. Valid values: active | inactive
  --apply-immediately: oneof<nothing, bool> # If true, this parameter causes the modifications in this request and any pending modifications to be applied, asynchronously and as soon as possible, regardless of the PreferredMaintenanceWindow setting for the replication group. If false, changes to the nodes in the replication group are applied on the next maintenance reboot, or the next failure reboot, whichever occurs first. Valid values: true | false Default: false
  --engine-version: string # The upgraded version of the cache engine to be run on the clusters in the replication group. Important: You can upgrade to a newer engine version (see Selecting a Cache Engine and Version (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/SelectEngine.html#VersionManagement)), but you cannot downgrade to an earlier engine version. If you want to use an earlier engine version, you must delete the existing replication group and create it anew with the earlier engine version.
  --auto-minor-version-upgrade: oneof<nothing, bool> # If you are running Redis engine version 6.0 or later, set this parameter to yes if you want to opt-in to the next auto minor version upgrade campaign. This parameter is disabled for previous versions.
  --snapshot-retention-limit: int # The number of days for which ElastiCache retains automatic node group (shard) snapshots before deleting them. For example, if you set SnapshotRetentionLimit to 5, a snapshot that was taken today is retained for 5 days before being deleted. Important If the value of SnapshotRetentionLimit is set to zero (0), backups are turned off.
  --snapshot-window: string # The daily time range (in UTC) during which ElastiCache begins taking a daily snapshot of the node group (shard) specified by SnapshottingClusterId. Example: 05:00-09:00 If you do not specify this parameter, ElastiCache automatically chooses an appropriate time range.
  --cache-node-type: string # A valid cache node type that you want to scale this replication group to.
  --auth-token: string # Reserved parameter. The password used to access a password protected server. This parameter must be specified with the auth-token-update-strategy parameter. Password constraints: Must be only printable ASCII characters Must be at least 16 characters and no more than 128 characters in length Cannot contain any of the following characters: '/', '"', or '@', '%' For more information, see AUTH password at AUTH (http://redis.io/commands/AUTH).
  --auth-token-update-strategy: string@auth-token-update-strategy-completer # Specifies the strategy to use to update the AUTH token. This parameter must be specified with the auth-token parameter. Possible values: Rotate Set For more information, see Authenticating Users with Redis AUTH (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/auth.html)
  --user-group-ids-to-add: list<string> # The ID of the user group you are associating with the replication group.
  --user-group-ids-to-remove: list<string> # The ID of the user group to disassociate from the replication group, meaning the users in the group no longer can access the replication group.
  --remove-user-groups: oneof<nothing, bool> # Removes the user group associated with this replication group.
  --log-delivery-configurations: list # Specifies the destination, format and type of the logs.
  --ip-discovery: string@ip-discovery-completer # The network type you choose when modifying a cluster, either ipv4 | ipv6. IPv6 is supported for workloads using Redis engine version 6.2 onward or Memcached engine version 1.6.6 on all instances built on the Nitro system (https://aws.amazon.com/ec2/nitro/).
  --transit-encryption-enabled: oneof<nothing, bool> # A flag that enables in-transit encryption when set to true. If you are enabling in-transit encryption for an existing cluster, you must also set TransitEncryptionMode to preferred.
  --transit-encryption-mode: string@transit-encryption-mode-completer # A setting that allows you to migrate your clients to use in-transit encryption, with no downtime. You must set TransitEncryptionEnabled to true, for your existing cluster, and set TransitEncryptionMode to preferred in the same request to allow both encrypted and unencrypted connections at the same time. Once you migrate all your Redis clients to use encrypted connections you can set the value to required to allow encrypted connections only. Setting TransitEncryptionMode to required is a two-step process that requires you to first set the TransitEncryptionMode to preferred first, after that you can set TransitEncryptionMode to required.
  --action: string@action-completer-53 # required
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: ReplicationGroupDescription, var: replication_group_description}, {name: PrimaryClusterId, var: primary_cluster_id}, {name: SnapshottingClusterId, var: snapshotting_cluster_id}, {name: AutomaticFailoverEnabled, var: automatic_failover_enabled}, {name: MultiAZEnabled, var: multi_az_enabled}, {name: NodeGroupId, var: node_group_id}, {name: CacheSecurityGroupNames, var: cache_security_group_names, style: multi}, {name: SecurityGroupIds, var: security_group_ids, style: multi}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: NotificationTopicArn, var: notification_topic_arn}, {name: CacheParameterGroupName, var: cache_parameter_group_name}, {name: NotificationTopicStatus, var: notification_topic_status}, {name: ApplyImmediately, var: apply_immediately}, {name: EngineVersion, var: engine_version}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: SnapshotRetentionLimit, var: snapshot_retention_limit}, {name: SnapshotWindow, var: snapshot_window}, {name: CacheNodeType, var: cache_node_type}, {name: AuthToken, var: auth_token}, {name: AuthTokenUpdateStrategy, var: auth_token_update_strategy}, {name: UserGroupIdsToAdd, var: user_group_ids_to_add, style: multi}, {name: UserGroupIdsToRemove, var: user_group_ids_to_remove, style: multi}, {name: RemoveUserGroups, var: remove_user_groups}, {name: LogDeliveryConfigurations, var: log_delivery_configurations, style: multi}, {name: IpDiscovery, var: ip_discovery}, {name: TransitEncryptionEnabled, var: transit_encryption_enabled}, {name: TransitEncryptionMode, var: transit_encryption_mode}, {name: Action, var: action, required: true, default: ModifyReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, replication_group_description: $replication_group_description, primary_cluster_id: $primary_cluster_id, snapshotting_cluster_id: $snapshotting_cluster_id, automatic_failover_enabled: $automatic_failover_enabled, multi_az_enabled: $multi_az_enabled, node_group_id: $node_group_id, cache_security_group_names: $cache_security_group_names, security_group_ids: $security_group_ids, preferred_maintenance_window: $preferred_maintenance_window, notification_topic_arn: $notification_topic_arn, cache_parameter_group_name: $cache_parameter_group_name, notification_topic_status: $notification_topic_status, apply_immediately: $apply_immediately, engine_version: $engine_version, auto_minor_version_upgrade: $auto_minor_version_upgrade, snapshot_retention_limit: $snapshot_retention_limit, snapshot_window: $snapshot_window, cache_node_type: $cache_node_type, auth_token: $auth_token, auth_token_update_strategy: $auth_token_update_strategy, user_group_ids_to_add: $user_group_ids_to_add, user_group_ids_to_remove: $user_group_ids_to_remove, remove_user_groups: $remove_user_groups, log_delivery_configurations: $log_delivery_configurations, ip_discovery: $ip_discovery, transit_encryption_enabled: $transit_encryption_enabled, transit_encryption_mode: $transit_encryption_mode, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the settings for a replication group. Scaling for Amazon ElastiCache for Redis (cluster mode enabled) (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/scaling-redis-cluster-mode-enabled.html) in the ElastiCache User Guide ModifyReplicationGroupShardConfiguration (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_ModifyReplicationGroupShardConfiguration.html) in the ElastiCache API Reference This operation is valid for Redis only.
#
# POST /
# operationId: POST_ModifyReplicationGroup
export def "post-modify-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-53 # required
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
    query: [{name: Action, var: action, required: true, default: ModifyReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Modifies a replication group's shards (node groups) by allowing you to add shards, remove shards, or rebalance the keyspaces among existing shards.
#
# GET /
# operationId: GET_ModifyReplicationGroupShardConfiguration
export def "get-modify-replication-group-shard-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The name of the Redis (cluster mode enabled) cluster (replication group) on which the shards are to be configured. (required)
  --node-group-count: int # The number of node groups (shards) that results from the modification of the shard configuration. (required)
  --apply-immediately: oneof<nothing, bool> # Indicates that the shard reconfiguration process begins immediately. At present, the only permitted value for this parameter is true. Value: true (required)
  --resharding-configuration: list # Specifies the preferred availability zones for each node group in the cluster. If the value of NodeGroupCount is greater than the current number of node groups (shards), you can use this parameter to specify the preferred availability zones of the cluster's shards. If you omit this parameter ElastiCache selects availability zones for you. You can specify this parameter only if the value of NodeGroupCount is greater than the current number of node groups (shards).
  --node-groups-to-remove: list<string> # If the value of NodeGroupCount is less than the current number of node groups (shards), then either NodeGroupsToRemove or NodeGroupsToRetain is required. NodeGroupsToRemove is a list of NodeGroupIds to remove from the cluster. ElastiCache for Redis will attempt to remove all node groups listed by NodeGroupsToRemove from the cluster.
  --node-groups-to-retain: list<string> # If the value of NodeGroupCount is less than the current number of node groups (shards), then either NodeGroupsToRemove or NodeGroupsToRetain is required. NodeGroupsToRetain is a list of NodeGroupIds to retain in the cluster. ElastiCache for Redis will attempt to remove all node groups except those listed by NodeGroupsToRetain from the cluster.
  --action: string@action-completer-54 # required
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: NodeGroupCount, var: node_group_count, required: true}, {name: ApplyImmediately, var: apply_immediately, required: true}, {name: ReshardingConfiguration, var: resharding_configuration, style: multi}, {name: NodeGroupsToRemove, var: node_groups_to_remove, style: multi}, {name: NodeGroupsToRetain, var: node_groups_to_retain, style: multi}, {name: Action, var: action, required: true, default: ModifyReplicationGroupShardConfiguration}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, node_group_count: $node_group_count, apply_immediately: $apply_immediately, resharding_configuration: $resharding_configuration, node_groups_to_remove: $node_groups_to_remove, node_groups_to_retain: $node_groups_to_retain, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies a replication group's shards (node groups) by allowing you to add shards, remove shards, or rebalance the keyspaces among existing shards.
#
# POST /
# operationId: POST_ModifyReplicationGroupShardConfiguration
export def "post-modify-replication-group-shard-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-54 # required
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
    query: [{name: Action, var: action, required: true, default: ModifyReplicationGroupShardConfiguration}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Changes user password(s) and/or access string.
#
# GET /
# operationId: GET_ModifyUser
export def "get-modify-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The ID of the user. (required)
  --access-string: string # Access permissions string used for this user.
  --append-access-string: string # Adds additional user permissions to the access string.
  --passwords: list<string> # The passwords belonging to the user. You are allowed up to two.
  --no-password-required: oneof<nothing, bool> # Indicates no password is required for the user.
  --authentication-mode: record # Specifies how to authenticate the user.
  --action: string@action-completer-55 # required
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
    query: [{name: UserId, var: user_id, required: true}, {name: AccessString, var: access_string}, {name: AppendAccessString, var: append_access_string}, {name: Passwords, var: passwords, style: multi}, {name: NoPasswordRequired, var: no_password_required}, {name: AuthenticationMode, var: authentication_mode, style: multi}, {name: Action, var: action, required: true, default: ModifyUser}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, access_string: $access_string, append_access_string: $append_access_string, passwords: $passwords, no_password_required: $no_password_required, authentication_mode: $authentication_mode, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes user password(s) and/or access string.
#
# POST /
# operationId: POST_ModifyUser
export def "post-modify-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-55 # required
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
    query: [{name: Action, var: action, required: true, default: ModifyUser}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Changes the list of users that belong to the user group.
#
# GET /
# operationId: GET_ModifyUserGroup
export def "get-modify-user-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-group-id: string # The ID of the user group. (required)
  --user-ids-to-add: list<string> # The list of user IDs to add to the user group.
  --user-ids-to-remove: list<string> # The list of user IDs to remove from the user group.
  --action: string@action-completer-56 # required
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
    query: [{name: UserGroupId, var: user_group_id, required: true}, {name: UserIdsToAdd, var: user_ids_to_add, style: multi}, {name: UserIdsToRemove, var: user_ids_to_remove, style: multi}, {name: Action, var: action, required: true, default: ModifyUserGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_group_id: $user_group_id, user_ids_to_add: $user_ids_to_add, user_ids_to_remove: $user_ids_to_remove, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the list of users that belong to the user group.
#
# POST /
# operationId: POST_ModifyUserGroup
export def "post-modify-user-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-56 # required
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
    query: [{name: Action, var: action, required: true, default: ModifyUserGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Allows you to purchase a reserved cache node offering. Reserved nodes are not eligible for cancellation and are non-refundable. For more information, see Managing Costs with Reserved Nodes (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/reserved-nodes.html) for Redis or Managing Costs with Reserved Nodes (https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/reserved-nodes.html) for Memcached.
#
# GET /
# operationId: GET_PurchaseReservedCacheNodesOffering
export def "get-purchase-reserved-cache-nodes-offering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-cache-nodes-offering-id: string # The ID of the reserved cache node offering to purchase. Example: 438012d3-4052-4cc7-b2e3-8d3372e0e706 (required)
  --reserved-cache-node-id: string # A customer-specified identifier to track this reservation. The Reserved Cache Node ID is an unique customer-specified identifier to track this reservation. If this parameter is not specified, ElastiCache automatically generates an identifier for the reservation. Example: myreservationID
  --cache-node-count: int # The number of cache node instances to reserve. Default: 1
  --tags: list # A list of tags to be added to this resource. A tag is a key-value pair. A tag key must be accompanied by a tag value, although null is accepted.
  --action: string@action-completer-57 # required
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
    query: [{name: ReservedCacheNodesOfferingId, var: reserved_cache_nodes_offering_id, required: true}, {name: ReservedCacheNodeId, var: reserved_cache_node_id}, {name: CacheNodeCount, var: cache_node_count}, {name: Tags, var: tags, style: multi}, {name: Action, var: action, required: true, default: PurchaseReservedCacheNodesOffering}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    reserved_cache_nodes_offering_id: $reserved_cache_nodes_offering_id, reserved_cache_node_id: $reserved_cache_node_id, cache_node_count: $cache_node_count, tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to purchase a reserved cache node offering. Reserved nodes are not eligible for cancellation and are non-refundable. For more information, see Managing Costs with Reserved Nodes (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/reserved-nodes.html) for Redis or Managing Costs with Reserved Nodes (https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/reserved-nodes.html) for Memcached.
#
# POST /
# operationId: POST_PurchaseReservedCacheNodesOffering
export def "post-purchase-reserved-cache-nodes-offering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-57 # required
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
    query: [{name: Action, var: action, required: true, default: PurchaseReservedCacheNodesOffering}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Redistribute slots to ensure uniform distribution across existing shards in the cluster.
#
# GET /
# operationId: GET_RebalanceSlotsInGlobalReplicationGroup
export def "get-rebalance-slots-in-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-replication-group-id: string # The name of the Global datastore (required)
  --apply-immediately: oneof<nothing, bool> # If True, redistribution is applied immediately. (required)
  --action: string@action-completer-58 # required
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
    query: [{name: GlobalReplicationGroupId, var: global_replication_group_id, required: true}, {name: ApplyImmediately, var: apply_immediately, required: true}, {name: Action, var: action, required: true, default: RebalanceSlotsInGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    global_replication_group_id: $global_replication_group_id, apply_immediately: $apply_immediately, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Redistribute slots to ensure uniform distribution across existing shards in the cluster.
#
# POST /
# operationId: POST_RebalanceSlotsInGlobalReplicationGroup
export def "post-rebalance-slots-in-global-replication-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-58 # required
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
    query: [{name: Action, var: action, required: true, default: RebalanceSlotsInGlobalReplicationGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Reboots some, or all, of the cache nodes within a provisioned cluster. This operation applies any modified cache parameter groups to the cluster. The reboot operation takes place as soon as possible, and results in a momentary outage to the cluster. During the reboot, the cluster status is set to REBOOTING. The reboot causes the contents of the cache (for each cache node being rebooted) to be lost. When the reboot is complete, a cluster event is created. Rebooting a cluster is currently supported on Memcached and Redis (cluster mode disabled) clusters. Rebooting is not supported on Redis (cluster mode enabled) clusters. If you make changes to parameters that require a Redis (cluster mode enabled) cluster reboot for the changes to be applied, see Rebooting a Cluster (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/nodes.rebooting.html) for an alternate process.
#
# GET /
# operationId: GET_RebootCacheCluster
export def "get-reboot-cache-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-cluster-id: string # The cluster identifier. This parameter is stored as a lowercase string. (required)
  --cache-node-ids-to-reboot: list<string> # A list of cache node IDs to reboot. A node ID is a numeric identifier (0001, 0002, etc.). To reboot an entire cluster, specify all of the cache node IDs. (required)
  --action: string@action-completer-59 # required
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
    query: [{name: CacheClusterId, var: cache_cluster_id, required: true}, {name: CacheNodeIdsToReboot, var: cache_node_ids_to_reboot, style: multi, required: true}, {name: Action, var: action, required: true, default: RebootCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_cluster_id: $cache_cluster_id, cache_node_ids_to_reboot: $cache_node_ids_to_reboot, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reboots some, or all, of the cache nodes within a provisioned cluster. This operation applies any modified cache parameter groups to the cluster. The reboot operation takes place as soon as possible, and results in a momentary outage to the cluster. During the reboot, the cluster status is set to REBOOTING. The reboot causes the contents of the cache (for each cache node being rebooted) to be lost. When the reboot is complete, a cluster event is created. Rebooting a cluster is currently supported on Memcached and Redis (cluster mode disabled) clusters. Rebooting is not supported on Redis (cluster mode enabled) clusters. If you make changes to parameters that require a Redis (cluster mode enabled) cluster reboot for the changes to be applied, see Rebooting a Cluster (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/nodes.rebooting.html) for an alternate process.
#
# POST /
# operationId: POST_RebootCacheCluster
export def "post-reboot-cache-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-59 # required
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
    query: [{name: Action, var: action, required: true, default: RebootCacheCluster}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Removes the tags identified by the TagKeys list from the named resource. A tag is a key-value pair where the key and value are case-sensitive. You can use tags to categorize and track all your ElastiCache resources, with the exception of global replication group. When you add or remove tags on replication groups, those actions will be replicated to all nodes in the replication group. For more information, see Resource-level permissions (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.ResourceLevelPermissions.html).
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
  --resource-name: string # The Amazon Resource Name (ARN) of the resource from which you want the tags removed, for example arn:aws:elasticache:us-west-2:0123456789:cluster:myCluster or arn:aws:elasticache:us-west-2:0123456789:snapshot:mySnapshot. For more information about ARNs, see Amazon Resource Names (ARNs) and Amazon Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html). (required)
  --tag-keys: list<string> # A list of TagKeys identifying the tags you want removed from the named resource. (required)
  --action: string@action-completer-60 # required
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
    query: [{name: ResourceName, var: resource_name, required: true}, {name: TagKeys, var: tag_keys, style: multi, required: true}, {name: Action, var: action, required: true, default: RemoveTagsFromResource}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, tag_keys: $tag_keys, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the tags identified by the TagKeys list from the named resource. A tag is a key-value pair where the key and value are case-sensitive. You can use tags to categorize and track all your ElastiCache resources, with the exception of global replication group. When you add or remove tags on replication groups, those actions will be replicated to all nodes in the replication group. For more information, see Resource-level permissions (http://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/IAM.ResourceLevelPermissions.html).
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
  --action: string@action-completer-60 # required
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
    query: [{name: Action, var: action, required: true, default: RemoveTagsFromResource}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Modifies the parameters of a cache parameter group to the engine or system default value. You can reset specific parameters by submitting a list of parameter names. To reset the entire cache parameter group, specify the ResetAllParameters and CacheParameterGroupName parameters.
#
# GET /
# operationId: GET_ResetCacheParameterGroup
export def "get-reset-cache-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-parameter-group-name: string # The name of the cache parameter group to reset. (required)
  --reset-all-parameters: oneof<nothing, bool> # If true, all parameters in the cache parameter group are reset to their default values. If false, only the parameters listed by ParameterNameValues are reset to their default values. Valid values: true | false
  --parameter-name-values: list # An array of parameter names to reset to their default values. If ResetAllParameters is true, do not use ParameterNameValues. If ResetAllParameters is false, you must specify the name of at least one parameter to reset.
  --action: string@action-completer-61 # required
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
    query: [{name: CacheParameterGroupName, var: cache_parameter_group_name, required: true}, {name: ResetAllParameters, var: reset_all_parameters}, {name: ParameterNameValues, var: parameter_name_values, style: multi}, {name: Action, var: action, required: true, default: ResetCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_parameter_group_name: $cache_parameter_group_name, reset_all_parameters: $reset_all_parameters, parameter_name_values: $parameter_name_values, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the parameters of a cache parameter group to the engine or system default value. You can reset specific parameters by submitting a list of parameter names. To reset the entire cache parameter group, specify the ResetAllParameters and CacheParameterGroupName parameters.
#
# POST /
# operationId: POST_ResetCacheParameterGroup
export def "post-reset-cache-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-61 # required
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
    query: [{name: Action, var: action, required: true, default: ResetCacheParameterGroup}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Revokes ingress from a cache security group. Use this operation to disallow access from an Amazon EC2 security group that had been previously authorized.
#
# GET /
# operationId: GET_RevokeCacheSecurityGroupIngress
export def "get-revoke-cache-security-group-ingress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-security-group-name: string # The name of the cache security group to revoke ingress from. (required)
  --ec2-security-group-name: string # The name of the Amazon EC2 security group to revoke access from. (required)
  --ec2-security-group-owner-id: string # The Amazon account number of the Amazon EC2 security group owner. Note that this is not the same thing as an Amazon access key ID - you must provide a valid Amazon account number for this parameter. (required)
  --action: string@action-completer-62 # required
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
    query: [{name: CacheSecurityGroupName, var: cache_security_group_name, required: true}, {name: EC2SecurityGroupName, var: ec2_security_group_name, required: true}, {name: EC2SecurityGroupOwnerId, var: ec2_security_group_owner_id, required: true}, {name: Action, var: action, required: true, default: RevokeCacheSecurityGroupIngress}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    cache_security_group_name: $cache_security_group_name, ec2_security_group_name: $ec2_security_group_name, ec2_security_group_owner_id: $ec2_security_group_owner_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes ingress from a cache security group. Use this operation to disallow access from an Amazon EC2 security group that had been previously authorized.
#
# POST /
# operationId: POST_RevokeCacheSecurityGroupIngress
export def "post-revoke-cache-security-group-ingress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-62 # required
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
    query: [{name: Action, var: action, required: true, default: RevokeCacheSecurityGroupIngress}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Start the migration of data.
#
# GET /
# operationId: GET_StartMigration
export def "get-start-migration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The ID of the replication group to which data should be migrated. (required)
  --customer-node-endpoint-list: list # List of endpoints from which data should be migrated. For Redis (cluster mode disabled), list should have only one element. (required)
  --action: string@action-completer-63 # required
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: CustomerNodeEndpointList, var: customer_node_endpoint_list, style: multi, required: true}, {name: Action, var: action, required: true, default: StartMigration}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, customer_node_endpoint_list: $customer_node_endpoint_list, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the migration of data.
#
# POST /
# operationId: POST_StartMigration
export def "post-start-migration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-63 # required
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
    query: [{name: Action, var: action, required: true, default: StartMigration}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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

# Represents the input of a TestFailover operation which test automatic failover on a specified node group (called shard in the console) in a replication group (called cluster in the console). This API is designed for testing the behavior of your application in case of ElastiCache failover. It is not designed to be an operational tool for initiating a failover to overcome a problem you may have with the cluster. Moreover, in certain conditions such as large-scale operational events, Amazon may block this API. Note the following A customer can use this operation to test automatic failover on up to 5 shards (called node groups in the ElastiCache API and Amazon CLI) in any rolling 24-hour period. If calling this operation on shards in different clusters (called replication groups in the API and CLI), the calls can be made concurrently. If calling this operation multiple times on different shards in the same Redis (cluster mode enabled) replication group, the first node replacement must complete before a subsequent call can be made. To determine whether the node replacement is complete you can check Events using the Amazon ElastiCache console, the Amazon CLI, or the ElastiCache API. Look for the following automatic failover related events, listed here in order of occurrance: Replication group message: Test Failover API called for node group <node-group-id> Cache cluster message: Failover from primary node <primary-node-id> to replica node <node-id> completed Replication group message: Failover from primary node <primary-node-id> to replica node <node-id> completed Cache cluster message: Recovering cache nodes <node-id> Cache cluster message: Finished recovery for cache nodes <node-id> For more information see: Viewing ElastiCache Events (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/ECEvents.Viewing.html) in the ElastiCache User Guide DescribeEvents (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_DescribeEvents.html) in the ElastiCache API Reference Also see, Testing Multi-AZ (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/AutoFailover.html#auto-failover-test) in the ElastiCache User Guide.
#
# GET /
# operationId: GET_TestFailover
export def "get-test-failover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replication-group-id: string # The name of the replication group (console: cluster) whose automatic failover is being tested by this operation. (required)
  --node-group-id: string # The name of the node group (called shard in the console) in this replication group on which automatic failover is to be tested. You may test automatic failover on up to 5 node groups in any rolling 24-hour period. (required)
  --action: string@action-completer-64 # required
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
    query: [{name: ReplicationGroupId, var: replication_group_id, required: true}, {name: NodeGroupId, var: node_group_id, required: true}, {name: Action, var: action, required: true, default: TestFailover}, {name: Version, var: version, required: true, default: "2015-02-02"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    replication_group_id: $replication_group_id, node_group_id: $node_group_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Represents the input of a TestFailover operation which test automatic failover on a specified node group (called shard in the console) in a replication group (called cluster in the console). This API is designed for testing the behavior of your application in case of ElastiCache failover. It is not designed to be an operational tool for initiating a failover to overcome a problem you may have with the cluster. Moreover, in certain conditions such as large-scale operational events, Amazon may block this API. Note the following A customer can use this operation to test automatic failover on up to 5 shards (called node groups in the ElastiCache API and Amazon CLI) in any rolling 24-hour period. If calling this operation on shards in different clusters (called replication groups in the API and CLI), the calls can be made concurrently. If calling this operation multiple times on different shards in the same Redis (cluster mode enabled) replication group, the first node replacement must complete before a subsequent call can be made. To determine whether the node replacement is complete you can check Events using the Amazon ElastiCache console, the Amazon CLI, or the ElastiCache API. Look for the following automatic failover related events, listed here in order of occurrance: Replication group message: Test Failover API called for node group <node-group-id> Cache cluster message: Failover from primary node <primary-node-id> to replica node <node-id> completed Replication group message: Failover from primary node <primary-node-id> to replica node <node-id> completed Cache cluster message: Recovering cache nodes <node-id> Cache cluster message: Finished recovery for cache nodes <node-id> For more information see: Viewing ElastiCache Events (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/ECEvents.Viewing.html) in the ElastiCache User Guide DescribeEvents (https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_DescribeEvents.html) in the ElastiCache API Reference Also see, Testing Multi-AZ (https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/AutoFailover.html#auto-failover-test) in the ElastiCache User Guide.
#
# POST /
# operationId: POST_TestFailover
export def "post-test-failover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-64 # required
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
    query: [{name: Action, var: action, required: true, default: TestFailover}, {name: Version, var: version, required: true, default: "2015-02-02"}]
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
