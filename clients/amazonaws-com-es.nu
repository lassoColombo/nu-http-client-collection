# Auto-generated client for Amazon Elasticsearch Service v2015-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/es/2015-01-01/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTICSEARCH_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://es.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_ELASTICSEARCH_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://es.us-east-1.amazonaws.com" "http://es.us-east-2.amazonaws.com" "http://es.us-west-1.amazonaws.com" "http://es.us-west-2.amazonaws.com" "http://es.us-gov-west-1.amazonaws.com" "http://es.us-gov-east-1.amazonaws.com" "http://es.ca-central-1.amazonaws.com" "http://es.eu-north-1.amazonaws.com" "http://es.eu-west-1.amazonaws.com" "http://es.eu-west-2.amazonaws.com" "http://es.eu-west-3.amazonaws.com" "http://es.eu-central-1.amazonaws.com" "http://es.eu-south-1.amazonaws.com" "http://es.af-south-1.amazonaws.com" "http://es.ap-northeast-1.amazonaws.com" "http://es.ap-northeast-2.amazonaws.com" "http://es.ap-northeast-3.amazonaws.com" "http://es.ap-southeast-1.amazonaws.com" "http://es.ap-southeast-2.amazonaws.com" "http://es.ap-east-1.amazonaws.com" "http://es.ap-south-1.amazonaws.com" "http://es.sa-east-1.amazonaws.com" "http://es.me-south-1.amazonaws.com" "https://es.us-east-1.amazonaws.com" "https://es.us-east-2.amazonaws.com" "https://es.us-west-1.amazonaws.com" "https://es.us-west-2.amazonaws.com" "https://es.us-gov-west-1.amazonaws.com" "https://es.us-gov-east-1.amazonaws.com" "https://es.ca-central-1.amazonaws.com" "https://es.eu-north-1.amazonaws.com" "https://es.eu-west-1.amazonaws.com" "https://es.eu-west-2.amazonaws.com" "https://es.eu-west-3.amazonaws.com" "https://es.eu-central-1.amazonaws.com" "https://es.eu-south-1.amazonaws.com" "https://es.af-south-1.amazonaws.com" "https://es.ap-northeast-1.amazonaws.com" "https://es.ap-northeast-2.amazonaws.com" "https://es.ap-northeast-3.amazonaws.com" "https://es.ap-southeast-1.amazonaws.com" "https://es.ap-southeast-2.amazonaws.com" "https://es.ap-east-1.amazonaws.com" "https://es.ap-south-1.amazonaws.com" "https://es.sa-east-1.amazonaws.com" "https://es.me-south-1.amazonaws.com" "http://es.cn-north-1.amazonaws.com.cn" "http://es.cn-northwest-1.amazonaws.com.cn" "https://es.cn-north-1.amazonaws.com.cn" "https://es.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def package-type-completer [] { ["TXT-DICTIONARY"] }
def instance-type-completer [] { ["c4.2xlarge.elasticsearch" "c4.4xlarge.elasticsearch" "c4.8xlarge.elasticsearch" "c4.large.elasticsearch" "c4.xlarge.elasticsearch" "c5.18xlarge.elasticsearch" "c5.2xlarge.elasticsearch" "c5.4xlarge.elasticsearch" "c5.9xlarge.elasticsearch" "c5.large.elasticsearch" "c5.xlarge.elasticsearch" "d2.2xlarge.elasticsearch" "d2.4xlarge.elasticsearch" "d2.8xlarge.elasticsearch" "d2.xlarge.elasticsearch" "i2.2xlarge.elasticsearch" "i2.xlarge.elasticsearch" "i3.16xlarge.elasticsearch" "i3.2xlarge.elasticsearch" "i3.4xlarge.elasticsearch" "i3.8xlarge.elasticsearch" "i3.large.elasticsearch" "i3.xlarge.elasticsearch" "m3.2xlarge.elasticsearch" "m3.large.elasticsearch" "m3.medium.elasticsearch" "m3.xlarge.elasticsearch" "m4.10xlarge.elasticsearch" "m4.2xlarge.elasticsearch" "m4.4xlarge.elasticsearch" "m4.large.elasticsearch" "m4.xlarge.elasticsearch" "m5.12xlarge.elasticsearch" "m5.2xlarge.elasticsearch" "m5.4xlarge.elasticsearch" "m5.large.elasticsearch" "m5.xlarge.elasticsearch" "r3.2xlarge.elasticsearch" "r3.4xlarge.elasticsearch" "r3.8xlarge.elasticsearch" "r3.large.elasticsearch" "r3.xlarge.elasticsearch" "r4.16xlarge.elasticsearch" "r4.2xlarge.elasticsearch" "r4.4xlarge.elasticsearch" "r4.8xlarge.elasticsearch" "r4.large.elasticsearch" "r4.xlarge.elasticsearch" "r5.12xlarge.elasticsearch" "r5.2xlarge.elasticsearch" "r5.4xlarge.elasticsearch" "r5.large.elasticsearch" "r5.xlarge.elasticsearch" "t2.medium.elasticsearch" "t2.micro.elasticsearch" "t2.small.elasticsearch" "ultrawarm1.large.elasticsearch" "ultrawarm1.medium.elasticsearch"] }
def engine-type-completer [] { ["Elasticsearch" "OpenSearch"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-inbound-cross-cluster-search-connection: "record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>"
    associate-package: "record<DomainPackageDetails: record<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>"
    authorize-vpc-endpoint-access: "record<AuthorizedPrincipal: record<PrincipalType: string, Principal: string>>"
    cancel-elasticsearch-service-software-update: "record<ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>>"
    create-elasticsearch-domain: "record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>"
    create-outbound-cross-cluster-search-connection: "record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, ConnectionAlias: string, ConnectionStatus: record<StatusCode: string, Message: string>, CrossClusterSearchConnectionId: string>"
    create-package: "record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>"
    create-vpc-endpoint: "record<VpcEndpoint: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, Status: string, Endpoint: string>>"
    list-vpc-endpoints: "record<VpcEndpointSummaryList: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>, NextToken: string>"
    delete-elasticsearch-domain: "record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>"
    describe-elasticsearch-domain: "record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>"
    delete-inbound-cross-cluster-search-connection: "record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>"
    delete-outbound-cross-cluster-search-connection: "record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionAlias: string, ConnectionStatus: record<StatusCode: string, Message: string>>>"
    delete-package: "record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>"
    delete-vpc-endpoint: "record<VpcEndpointSummary: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>>"
    describe-domain-auto-tunes: "record<AutoTunes: table<AutoTuneType: string, AutoTuneDetails: record>, NextToken: string>"
    describe-domain-change-progress: "record<ChangeProgressStatus: record<ChangeId: string, StartTime: string, Status: string, PendingProperties: list<string>, CompletedProperties: list<string>, TotalNumberOfStages: int, ChangeProgressStages: list<record>>>"
    describe-elasticsearch-domain-config: "record<DomainConfig: record<ElasticsearchVersion: record<Options: string, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: string, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>"
    update-elasticsearch-domain-config: "record<DomainConfig: record<ElasticsearchVersion: record<Options: string, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: string, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: string, Message: string>>, DryRunResults: record<DeploymentType: string, Message: string>>"
    describe-elasticsearch-domains: "record<DomainStatusList: table<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record, EBSOptions: record, AccessPolicies: string, SnapshotOptions: record, VPCOptions: record, CognitoOptions: record, EncryptionAtRestOptions: record, NodeToNodeEncryptionOptions: record, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record, DomainEndpointOptions: record, AdvancedSecurityOptions: record, AutoTuneOptions: record, ChangeProgressDetails: record>>"
    describe-elasticsearch-instance-type-limits: "record<LimitsByRole: record>"
    describe-inbound-cross-cluster-search-connections: "record<CrossClusterSearchConnections: table<SourceDomainInfo: record, DestinationDomainInfo: record, CrossClusterSearchConnectionId: string, ConnectionStatus: record>, NextToken: string>"
    describe-outbound-cross-cluster-search-connections: "record<CrossClusterSearchConnections: table<SourceDomainInfo: record, DestinationDomainInfo: record, CrossClusterSearchConnectionId: string, ConnectionAlias: string, ConnectionStatus: record>, NextToken: string>"
    describe-packages: "record<PackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record>, NextToken: string>"
    describe-reserved-elasticsearch-instance-offerings: "record<NextToken: string, ReservedElasticsearchInstanceOfferings: table<ReservedElasticsearchInstanceOfferingId: string, ElasticsearchInstanceType: string, Duration: int, FixedPrice: float, UsagePrice: float, CurrencyCode: string, PaymentOption: string, RecurringCharges: list>>"
    describe-reserved-elasticsearch-instances: "record<NextToken: string, ReservedElasticsearchInstances: table<ReservationName: string, ReservedElasticsearchInstanceId: string, ReservedElasticsearchInstanceOfferingId: string, ElasticsearchInstanceType: string, StartTime: string, Duration: int, FixedPrice: float, UsagePrice: float, CurrencyCode: string, ElasticsearchInstanceCount: int, State: string, PaymentOption: string, RecurringCharges: list>>"
    describe-vpc-endpoints: "record<VpcEndpoints: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record, Status: string, Endpoint: string>, VpcEndpointErrors: table<VpcEndpointId: string, ErrorCode: string, ErrorMessage: string>>"
    dissociate-package: "record<DomainPackageDetails: record<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>"
    get-compatible-elasticsearch-versions: "record<CompatibleElasticsearchVersions: table<SourceVersion: string, TargetVersions: list>>"
    get-package-version-history: "record<PackageID: string, PackageVersionHistoryList: table<PackageVersion: string, CommitMessage: string, CreatedAt: string>, NextToken: string>"
    get-upgrade-history: "record<UpgradeHistories: table<UpgradeName: string, StartTimestamp: string, UpgradeStatus: string, StepsList: list>, NextToken: string>"
    get-upgrade-status: "record<UpgradeStep: string, StepStatus: string, UpgradeName: string>"
    list-domain-names: "record<DomainNames: table<DomainName: string, EngineType: string>>"
    list-domains-for-package: "record<DomainPackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record>, NextToken: string>"
    list-elasticsearch-instance-types: "record<ElasticsearchInstanceTypes: list<string>, NextToken: string>"
    list-elasticsearch-versions: "record<ElasticsearchVersions: list<string>, NextToken: string>"
    list-packages-for-domain: "record<DomainPackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record>, NextToken: string>"
    list-tags: "record<TagList: table<Key: string, Value: string>>"
    list-vpc-endpoint-access: "record<AuthorizedPrincipalList: table<PrincipalType: string, Principal: string>, NextToken: string>"
    list-vpc-endpoints-for-domain: "record<VpcEndpointSummaryList: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>, NextToken: string>"
    purchase-reserved-elasticsearch-instance-offering: "record<ReservedElasticsearchInstanceId: string, ReservationName: string>"
    reject-inbound-cross-cluster-search-connection: "record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>"
    revoke-vpc-endpoint-access: "record"
    start-elasticsearch-service-software-update: "record<ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>>"
    update-package: "record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>"
    update-vpc-endpoint: "record<VpcEndpoint: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, Status: string, Endpoint: string>>"
    upgrade-elasticsearch-domain: "record<DomainName: string, TargetVersion: string, PerformCheckOnly: bool, ChangeProgressDetails: record<ChangeId: string, Message: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-inbound-cross-cluster-search-connection" "add-tags" "associate-package" "authorize-vpc-endpoint-access" "cancel-elasticsearch-service-software-update" "create-elasticsearch-domain" "create-outbound-cross-cluster-search-connection" "create-package" "create-vpc-endpoint" "list-vpc-endpoints" "delete-elasticsearch-domain" "describe-elasticsearch-domain" "delete-elasticsearch-service-role" "delete-inbound-cross-cluster-search-connection" "delete-outbound-cross-cluster-search-connection" "delete-package" "delete-vpc-endpoint" "describe-domain-auto-tunes" "describe-domain-change-progress" "describe-elasticsearch-domain-config" "update-elasticsearch-domain-config" "describe-elasticsearch-domains" "describe-elasticsearch-instance-type-limits" "describe-inbound-cross-cluster-search-connections" "describe-outbound-cross-cluster-search-connections" "describe-packages" "describe-reserved-elasticsearch-instance-offerings" "describe-reserved-elasticsearch-instances" "describe-vpc-endpoints" "dissociate-package" "get-compatible-elasticsearch-versions" "get-package-version-history" "get-upgrade-history" "get-upgrade-status" "list-domain-names" "list-domains-for-package" "list-elasticsearch-instance-types" "list-elasticsearch-versions" "list-packages-for-domain" "list-tags" "list-vpc-endpoint-access" "list-vpc-endpoints-for-domain" "purchase-reserved-elasticsearch-instance-offering" "reject-inbound-cross-cluster-search-connection" "remove-tags" "revoke-vpc-endpoint-access" "start-elasticsearch-service-software-update" "update-package" "update-vpc-endpoint" "upgrade-elasticsearch-domain" "commands"] | sort) } | get name | first)
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

# Allows the destination domain owner to accept an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/accept
# Returns: record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>
# operationId: AcceptInboundCrossClusterSearchConnection
export def "accept-inbound-cross-cluster-search-connection" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/2015-01-01/es/ccs/inboundConnection/{ConnectionId}/accept"
    path_params: [{name: ConnectionId, var: connection_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See Tagging Amazon Elasticsearch Service Domains for more information. (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging)
#
# POST /2015-01-01/tags
# operationId: AddTags
export def "add-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  arn: string # The Amazon Resource Name (ARN) of the Elasticsearch domain. See Identifiers for IAM Entities (http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html) in Using AWS Identity and Access Management for more information.
  tag_list: list # A list of Tag — item shape: {Key: string, Value: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/2015-01-01/tags"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ARN, var: arn}, {name: TagList, var: tag_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, arn: $arn, tag_list: $tag_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a package with an Amazon ES domain.
#
# POST /2015-01-01/packages/associate/{PackageID}/{DomainName}
# Returns: record<DomainPackageDetails: record<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>
# operationId: AssociatePackage
export def "associate-package" [
  package_id: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/2015-01-01/packages/associate/{PackageID}/{DomainName}"
    path_params: [{name: PackageID, var: package_id}, {name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id, domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides access to an Amazon OpenSearch Service domain through the use of an interface VPC endpoint.
#
# POST /2015-01-01/es/domain/{DomainName}/authorizeVpcEndpointAccess
# Returns: record<AuthorizedPrincipal: record<PrincipalType: string, Principal: string>>
# operationId: AuthorizeVpcEndpointAccess
export def "authorize-vpc-endpoint-access" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  account: string # The account ID to grant access to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/domain/{DomainName}/authorizeVpcEndpointAccess"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Account, var: account}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the AutomatedUpdateDate and when the UpdateStatus is in the PENDING_UPDATE state.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/cancel
# Returns: record<ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>>
# operationId: CancelElasticsearchServiceSoftwareUpdate
export def "cancel-elasticsearch-service-software-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/serviceSoftwareUpdate/cancel"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Elasticsearch domain. For more information, see Creating Elasticsearch Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains) in the Amazon Elasticsearch Service Developer Guide.
#
# POST /2015-01-01/es/domain
# Returns: record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>
# operationId: CreateElasticsearchDomain
export def "create-elasticsearch-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  --elasticsearch-version: string # String of format X.Y to specify version for the Elasticsearch domain eg. "1.5" or "2.3". For more information, see Creating Elasticsearch Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains) in the Amazon Elasticsearch Service Developer Guide.
  --elasticsearch-cluster-config: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: "m3.medium.elasticsearch"|"m3.large.elasticsearch"|"m3.xlarge.elasticsearch"|"m3.2xlarge.elasticsearch"|"m4.large.elasticsearch"|"m4.xlarge.elasticsearch"|"m4.2xlarge.elasticsearch"|"m4.4xlarge.elasticsearch"|"m4.10xlarge.elasticsearch"|"m5.large.elasticsearch"|"m5.xlarge.elasticsearch"|"m5.2xlarge.elasticsearch"|"m5.4xlarge.elasticsearch"|"m5.12xlarge.elasticsearch"|"r5.large.elasticsearch"|"r5.xlarge.elasticsearch"|"r5.2xlarge.elasticsearch"|"r5.4xlarge.elasticsearch"|"r5.12xlarge.elasticsearch"|"c5.large.elasticsearch"|"c5.xlarge.elasticsearch"|"c5.2xlarge.elasticsearch"|"c5.4xlarge.elasticsearch"|"c5.9xlarge.elasticsearch"|"c5.18xlarge.elasticsearch"|"ultrawarm1.medium.elasticsearch"|"ultrawarm1.large.elasticsearch"|"t2.micro.elasticsearch"|"t2.small.elasticsearch"|"t2.medium.elasticsearch"|"r3.large.elasticsearch"|"r3.xlarge.elasticsearch"|"r3.2xlarge.elasticsearch"|"r3.4xlarge.elasticsearch"|"r3.8xlarge.elasticsearch"|"i2.xlarge.elasticsearch"|"i2.2xlarge.elasticsearch"|"d2.xlarge.elasticsearch"|"d2.2xlarge.elasticsearch"|"d2.4xlarge.elasticsearch"|"d2.8xlarge.elasticsearch"|"c4.large.elasticsearch"|"c4.xlarge.elasticsearch"|"c4.2xlarge.elasticsearch"|"c4.4xlarge.elasticsearch"|"c4.8xlarge.elasticsearch"|"r4.large.elasticsearch"|"r4.xlarge.elasticsearch"|"r4.2xlarge.elasticsearch"|"r4.4xlarge.elasticsearch"|"r4.8xlarge.elasticsearch"|"r4.16xlarge.elasticsearch"|"i3.large.elasticsearch"|"i3.xlarge.elasticsearch"|"i3.2xlarge.elasticsearch"|"i3.4xlarge.elasticsearch"|"i3.8xlarge.elasticsearch"|"i3.16xlarge.elasticsearch", ... (10 more fields)}
  --ebs-options: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see Configuring EBS-based Storage (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs). — shape: {EBSEnabled?: bool, VolumeType?: "standard"|"gp2"|"io1"|"gp3", VolumeSize?: int, Iops?: int, Throughput?: int}
  --access-policies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see Configuring Access Policies (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies) in the Amazon Elasticsearch Service Developer Guide. The maximum size of a policy document is 100 KB.
  --snapshot-options: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is 0 hours. — shape: {AutomatedSnapshotStartHour?: int}
  --vpc-options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --cognito-options: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see Amazon Cognito Authentication for Kibana (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html). — shape: {Enabled?: bool, UserPoolId?: string, IdentityPoolId?: string, RoleArn?: string}
  --encryption-at-rest-options: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: bool, KmsKeyId?: string}
  --node-to-node-encryption-options: record # Specifies the node-to-node encryption options. — shape: {Enabled?: bool}
  --advanced-options: record # Exposes select native Elasticsearch configuration values from elasticsearch.yml. Currently, the following advanced options are available: Option to allow references to indices in an HTTP request body. Must be false when configuring access to individual sub-resources. By default, the value is true. See Configuration Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options) for more information. Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded. For more information, see Configuring Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options).
  --log-publishing-options: record # Map of LogType and LogPublishingOption, each containing options to publish a given type of Elasticsearch log.
  --domain-endpoint-options: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: bool, TLSSecurityPolicy?: "Policy-Min-TLS-1-0-2019-07"|"Policy-Min-TLS-1-2-2019-07", CustomEndpointEnabled?: bool, CustomEndpoint?: string, CustomEndpointCertificateArn?: string}
  --advanced-security-options: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: bool, InternalUserDatabaseEnabled?: bool, MasterUserOptions?: record, SAMLOptions?: record, AnonymousAuthEnabled?: bool}
  --auto-tune-options: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain and list of maintenance schedules. — shape: {DesiredState?: "ENABLED"|"DISABLED", MaintenanceSchedules?: list}
  --tag-list: list # A list of Tag — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/domain"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: ElasticsearchVersion, var: elasticsearch_version}, {name: ElasticsearchClusterConfig, var: elasticsearch_cluster_config}, {name: EBSOptions, var: ebs_options}, {name: AccessPolicies, var: access_policies}, {name: SnapshotOptions, var: snapshot_options}, {name: VPCOptions, var: vpc_options}, {name: CognitoOptions, var: cognito_options}, {name: EncryptionAtRestOptions, var: encryption_at_rest_options}, {name: NodeToNodeEncryptionOptions, var: node_to_node_encryption_options}, {name: AdvancedOptions, var: advanced_options}, {name: LogPublishingOptions, var: log_publishing_options}, {name: DomainEndpointOptions, var: domain_endpoint_options}, {name: AdvancedSecurityOptions, var: advanced_security_options}, {name: AutoTuneOptions, var: auto_tune_options}, {name: TagList, var: tag_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name, elasticsearch_version: $elasticsearch_version, elasticsearch_cluster_config: $elasticsearch_cluster_config, ebs_options: $ebs_options, access_policies: $access_policies, snapshot_options: $snapshot_options, vpc_options: $vpc_options, cognito_options: $cognito_options, encryption_at_rest_options: $encryption_at_rest_options, node_to_node_encryption_options: $node_to_node_encryption_options, advanced_options: $advanced_options, log_publishing_options: $log_publishing_options, domain_endpoint_options: $domain_endpoint_options, advanced_security_options: $advanced_security_options, auto_tune_options: $auto_tune_options, tag_list: $tag_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new cross-cluster search connection from a source domain to a destination domain.
#
# POST /2015-01-01/es/ccs/outboundConnection
# Returns: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, ConnectionAlias: string, ConnectionStatus: record<StatusCode: string, Message: string>, CrossClusterSearchConnectionId: string>
# operationId: CreateOutboundCrossClusterSearchConnection
export def "create-outbound-cross-cluster-search-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_domain_info: record # Specifies the DomainInformation for the source Elasticsearch domain. — shape: {OwnerId?: string, DomainName?: string, Region?: string}
  destination_domain_info: record # Specifies the DomainInformation for the destination Elasticsearch domain. — shape: {OwnerId?: string, DomainName?: string, Region?: string}
  connection_alias: string # Specifies the connection alias that will be used by the customer for this connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/ccs/outboundConnection"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceDomainInfo, var: source_domain_info}, {name: DestinationDomainInfo, var: destination_domain_info}, {name: ConnectionAlias, var: connection_alias}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_domain_info: $source_domain_info, destination_domain_info: $destination_domain_info, connection_alias: $connection_alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages
# Returns: record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>
# operationId: CreatePackage
export def "create-package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  package_name: string # Unique identifier for the package.
  package_type: string@package-type-completer # Type of package. Currently supports only TXT-DICTIONARY.
  --package-description: string # Description of the package.
  package_source: record # The S3 location for importing the package specified as S3BucketName and S3Key — shape: {S3BucketName?: string, S3Key?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/packages"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PackageName, var: package_name}, {name: PackageType, var: package_type}, {name: PackageDescription, var: package_description}, {name: PackageSource, var: package_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, package_name: $package_name, package_type: $package_type, package_description: $package_description, package_source: $package_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon OpenSearch Service-managed VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints
# Returns: record<VpcEndpoint: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, Status: string, Endpoint: string>>
# operationId: CreateVpcEndpoint
export def "create-vpc-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_arn: string # The Amazon Resource Name (ARN) of the domain to grant access to.
  vpc_options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --client-token: string # Unique, case-sensitive identifier to ensure idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/vpcEndpoints"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainArn, var: domain_arn}, {name: VpcOptions, var: vpc_options}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_arn: $domain_arn, vpc_options: $vpc_options, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all Amazon OpenSearch Service-managed VPC endpoints in the current account and Region.
#
# GET /2015-01-01/es/vpcEndpoints
# Returns: record<VpcEndpointSummaryList: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>, NextToken: string>
# operationId: ListVpcEndpoints
export def "list-vpc-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Identifier to allow retrieval of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/vpcEndpoints"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
#
# DELETE /2015-01-01/es/domain/{DomainName}
# Returns: record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>
# operationId: DeleteElasticsearchDomain
export def "delete-elasticsearch-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2015-01-01/es/domain/{DomainName}"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
#
# GET /2015-01-01/es/domain/{DomainName}
# Returns: record<DomainStatus: record<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: string, InstanceCount: int, DedicatedMasterEnabled: bool, ZoneAwarenessEnabled: bool, ZoneAwarenessConfig: record, DedicatedMasterType: string, DedicatedMasterCount: int, WarmEnabled: bool, WarmType: string, WarmCount: int, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: bool, VolumeType: string, VolumeSize: int, Iops: int, Throughput: int>, AccessPolicies: string, SnapshotOptions: record<AutomatedSnapshotStartHour: int>, VPCOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, CognitoOptions: record<Enabled: bool, UserPoolId: string, IdentityPoolId: string, RoleArn: string>, EncryptionAtRestOptions: record<Enabled: bool, KmsKeyId: string>, NodeToNodeEncryptionOptions: record<Enabled: bool>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>, DomainEndpointOptions: record<EnforceHTTPS: bool, TLSSecurityPolicy: string, CustomEndpointEnabled: bool, CustomEndpoint: string, CustomEndpointCertificateArn: string>, AdvancedSecurityOptions: record<Enabled: bool, InternalUserDatabaseEnabled: bool, SAMLOptions: record, AnonymousAuthDisableDate: string, AnonymousAuthEnabled: bool>, AutoTuneOptions: record<State: string, ErrorMessage: string>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>
# operationId: DescribeElasticsearchDomain
export def "describe-elasticsearch-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/domain/{DomainName}"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See Deleting Elasticsearch Service Role (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr) in VPC Endpoints for Amazon Elasticsearch Service Domains.
#
# DELETE /2015-01-01/es/role
# operationId: DeleteElasticsearchServiceRole
export def "delete-elasticsearch-service-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/2015-01-01/es/role"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the destination domain owner to delete an existing inbound cross-cluster search connection.
#
# DELETE /2015-01-01/es/ccs/inboundConnection/{ConnectionId}
# Returns: record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>
# operationId: DeleteInboundCrossClusterSearchConnection
export def "delete-inbound-cross-cluster-search-connection" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2015-01-01/es/ccs/inboundConnection/{ConnectionId}"
    path_params: [{name: ConnectionId, var: connection_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the source domain owner to delete an existing outbound cross-cluster search connection.
#
# DELETE /2015-01-01/es/ccs/outboundConnection/{ConnectionId}
# Returns: record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionAlias: string, ConnectionStatus: record<StatusCode: string, Message: string>>>
# operationId: DeleteOutboundCrossClusterSearchConnection
export def "delete-outbound-cross-cluster-search-connection" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2015-01-01/es/ccs/outboundConnection/{ConnectionId}"
    path_params: [{name: ConnectionId, var: connection_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the package.
#
# DELETE /2015-01-01/packages/{PackageID}
# Returns: record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>
# operationId: DeletePackage
export def "delete-package" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2015-01-01/packages/{PackageID}"
    path_params: [{name: PackageID, var: package_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon OpenSearch Service-managed interface VPC endpoint.
#
# DELETE /2015-01-01/es/vpcEndpoints/{VpcEndpointId}
# Returns: record<VpcEndpointSummary: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>>
# operationId: DeleteVpcEndpoint
export def "delete-vpc-endpoint" [
  vpc_endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/2015-01-01/es/vpcEndpoints/{VpcEndpointId}"
    path_params: [{name: VpcEndpointId, var: vpc_endpoint_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vpc_endpoint_id: $vpc_endpoint_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides scheduled Auto-Tune action details for the Elasticsearch domain, such as Auto-Tune action type, description, severity, and scheduled date.
#
# GET /2015-01-01/es/domain/{DomainName}/autoTunes
# Returns: record<AutoTunes: table<AutoTuneType: string, AutoTuneDetails: record>, NextToken: string>
# operationId: DescribeDomainAutoTunes
export def "describe-domain-auto-tunes" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/domain/{DomainName}/autoTunes"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the current blue/green deployment happening on a domain, including a change ID, status, and progress stages.
#
# GET /2015-01-01/es/domain/{DomainName}/progress
# Returns: record<ChangeProgressStatus: record<ChangeId: string, StartTime: string, Status: string, PendingProperties: list<string>, CompletedProperties: list<string>, TotalNumberOfStages: int, ChangeProgressStages: list<record>>>
# operationId: DescribeDomainChangeProgress
export def "describe-domain-change-progress" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changeid: string # The specific change ID for which you want to get progress information. This is an optional parameter. If omitted, the service returns information about the most recent configuration change.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/domain/{DomainName}/progress"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: changeid, var: changeid}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, changeid: $changeid, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
#
# GET /2015-01-01/es/domain/{DomainName}/config
# Returns: record<DomainConfig: record<ElasticsearchVersion: record<Options: string, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: string, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: string, Message: string>>>
# operationId: DescribeElasticsearchDomainConfig
export def "describe-elasticsearch-domain-config" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/domain/{DomainName}/config"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances.
#
# POST /2015-01-01/es/domain/{DomainName}/config
# Returns: record<DomainConfig: record<ElasticsearchVersion: record<Options: string, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: string, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: string, Message: string>>, DryRunResults: record<DeploymentType: string, Message: string>>
# operationId: UpdateElasticsearchDomainConfig
export def "update-elasticsearch-domain-config" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --elasticsearch-cluster-config: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: "m3.medium.elasticsearch"|"m3.large.elasticsearch"|"m3.xlarge.elasticsearch"|"m3.2xlarge.elasticsearch"|"m4.large.elasticsearch"|"m4.xlarge.elasticsearch"|"m4.2xlarge.elasticsearch"|"m4.4xlarge.elasticsearch"|"m4.10xlarge.elasticsearch"|"m5.large.elasticsearch"|"m5.xlarge.elasticsearch"|"m5.2xlarge.elasticsearch"|"m5.4xlarge.elasticsearch"|"m5.12xlarge.elasticsearch"|"r5.large.elasticsearch"|"r5.xlarge.elasticsearch"|"r5.2xlarge.elasticsearch"|"r5.4xlarge.elasticsearch"|"r5.12xlarge.elasticsearch"|"c5.large.elasticsearch"|"c5.xlarge.elasticsearch"|"c5.2xlarge.elasticsearch"|"c5.4xlarge.elasticsearch"|"c5.9xlarge.elasticsearch"|"c5.18xlarge.elasticsearch"|"ultrawarm1.medium.elasticsearch"|"ultrawarm1.large.elasticsearch"|"t2.micro.elasticsearch"|"t2.small.elasticsearch"|"t2.medium.elasticsearch"|"r3.large.elasticsearch"|"r3.xlarge.elasticsearch"|"r3.2xlarge.elasticsearch"|"r3.4xlarge.elasticsearch"|"r3.8xlarge.elasticsearch"|"i2.xlarge.elasticsearch"|"i2.2xlarge.elasticsearch"|"d2.xlarge.elasticsearch"|"d2.2xlarge.elasticsearch"|"d2.4xlarge.elasticsearch"|"d2.8xlarge.elasticsearch"|"c4.large.elasticsearch"|"c4.xlarge.elasticsearch"|"c4.2xlarge.elasticsearch"|"c4.4xlarge.elasticsearch"|"c4.8xlarge.elasticsearch"|"r4.large.elasticsearch"|"r4.xlarge.elasticsearch"|"r4.2xlarge.elasticsearch"|"r4.4xlarge.elasticsearch"|"r4.8xlarge.elasticsearch"|"r4.16xlarge.elasticsearch"|"i3.large.elasticsearch"|"i3.xlarge.elasticsearch"|"i3.2xlarge.elasticsearch"|"i3.4xlarge.elasticsearch"|"i3.8xlarge.elasticsearch"|"i3.16xlarge.elasticsearch", ... (10 more fields)}
  --ebs-options: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see Configuring EBS-based Storage (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs). — shape: {EBSEnabled?: bool, VolumeType?: "standard"|"gp2"|"io1"|"gp3", VolumeSize?: int, Iops?: int, Throughput?: int}
  --snapshot-options: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is 0 hours. — shape: {AutomatedSnapshotStartHour?: int}
  --vpc-options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
  --cognito-options: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see Amazon Cognito Authentication for Kibana (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html). — shape: {Enabled?: bool, UserPoolId?: string, IdentityPoolId?: string, RoleArn?: string}
  --advanced-options: record # Exposes select native Elasticsearch configuration values from elasticsearch.yml. Currently, the following advanced options are available: Option to allow references to indices in an HTTP request body. Must be false when configuring access to individual sub-resources. By default, the value is true. See Configuration Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options) for more information. Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded. For more information, see Configuring Advanced Options (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options).
  --access-policies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see Configuring Access Policies (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies) in the Amazon Elasticsearch Service Developer Guide. The maximum size of a policy document is 100 KB.
  --log-publishing-options: record # Map of LogType and LogPublishingOption, each containing options to publish a given type of Elasticsearch log.
  --domain-endpoint-options: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: bool, TLSSecurityPolicy?: "Policy-Min-TLS-1-0-2019-07"|"Policy-Min-TLS-1-2-2019-07", CustomEndpointEnabled?: bool, CustomEndpoint?: string, CustomEndpointCertificateArn?: string}
  --advanced-security-options: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: bool, InternalUserDatabaseEnabled?: bool, MasterUserOptions?: record, SAMLOptions?: record, AnonymousAuthEnabled?: bool}
  --node-to-node-encryption-options: record # Specifies the node-to-node encryption options. — shape: {Enabled?: bool}
  --encryption-at-rest-options: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: bool, KmsKeyId?: string}
  --auto-tune-options: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain, rollback state when disabling Auto-Tune options and list of maintenance schedules. — shape: {DesiredState?: "ENABLED"|"DISABLED", RollbackOnDisable?: "NO_ROLLBACK"|"DEFAULT_ROLLBACK", MaintenanceSchedules?: list}
  --body-dry-run: oneof<nothing, bool> # This flag, when set to True, specifies whether the UpdateElasticsearchDomain request should return the results of validation checks without actually applying the change. This flag, when set to True, specifies the deployment mechanism through which the update shall be applied on the domain. This will not actually perform the Update. (spec name: DryRun)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/domain/{DomainName}/config"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticsearchClusterConfig, var: elasticsearch_cluster_config}, {name: EBSOptions, var: ebs_options}, {name: SnapshotOptions, var: snapshot_options}, {name: VPCOptions, var: vpc_options}, {name: CognitoOptions, var: cognito_options}, {name: AdvancedOptions, var: advanced_options}, {name: AccessPolicies, var: access_policies}, {name: LogPublishingOptions, var: log_publishing_options}, {name: DomainEndpointOptions, var: domain_endpoint_options}, {name: AdvancedSecurityOptions, var: advanced_security_options}, {name: NodeToNodeEncryptionOptions, var: node_to_node_encryption_options}, {name: EncryptionAtRestOptions, var: encryption_at_rest_options}, {name: AutoTuneOptions, var: auto_tune_options}, {name: DryRun, var: body_dry_run}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, elasticsearch_cluster_config: $elasticsearch_cluster_config, ebs_options: $ebs_options, snapshot_options: $snapshot_options, vpc_options: $vpc_options, cognito_options: $cognito_options, advanced_options: $advanced_options, access_policies: $access_policies, log_publishing_options: $log_publishing_options, domain_endpoint_options: $domain_endpoint_options, advanced_security_options: $advanced_security_options, node_to_node_encryption_options: $node_to_node_encryption_options, encryption_at_rest_options: $encryption_at_rest_options, auto_tune_options: $auto_tune_options, body_dry_run: $body_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
#
# POST /2015-01-01/es/domain-info
# Returns: record<DomainStatusList: table<DomainId: string, DomainName: string, ARN: string, Created: bool, Deleted: bool, Endpoint: string, Endpoints: record, Processing: bool, UpgradeProcessing: bool, ElasticsearchVersion: string, ElasticsearchClusterConfig: record, EBSOptions: record, AccessPolicies: string, SnapshotOptions: record, VPCOptions: record, CognitoOptions: record, EncryptionAtRestOptions: record, NodeToNodeEncryptionOptions: record, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record, DomainEndpointOptions: record, AdvancedSecurityOptions: record, AutoTuneOptions: record, ChangeProgressDetails: record>>
# operationId: DescribeElasticsearchDomains
export def "describe-elasticsearch-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_names: list<string> # A list of Elasticsearch domain names.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/domain-info"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainNames, var: domain_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_names: $domain_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the DomainName to know what Limits are supported for modifying.
#
# GET /2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}
# Returns: record<LimitsByRole: record>
# operationId: DescribeElasticsearchInstanceTypeLimits
export def "describe-elasticsearch-instance-type-limits" [
  elasticsearch_version: string
  instance_type: string@instance-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # DomainName represents the name of the Domain that we are trying to modify. This should be present only if we are querying for Elasticsearch Limits for existing domain.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}"
    path_params: [{name: ElasticsearchVersion, var: elasticsearch_version}, {name: InstanceType, var: instance_type}]
    query: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    elasticsearch_version: $elasticsearch_version, instance_type: $instance_type, domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the inbound cross-cluster search connections for a destination domain.
#
# POST /2015-01-01/es/ccs/inboundConnection/search
# Returns: record<CrossClusterSearchConnections: table<SourceDomainInfo: record, DestinationDomainInfo: record, CrossClusterSearchConnectionId: string, ConnectionStatus: record>, NextToken: string>
# operationId: DescribeInboundCrossClusterSearchConnections
export def "describe-inbound-cross-cluster-search-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: list # A list of filters used to match properties for inbound cross-cluster search connection. Available Filter names for this operation are: cross-cluster-search-connection-id source-domain-info.domain-name source-domain-info.owner-id source-domain-info.region destination-domain-info.domain-name — item shape: {Name?: string, Values?: list<string>}
  --body-max-results: int # Set this value to limit the number of results returned. (spec name: MaxResults)
  --body-next-token: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/ccs/inboundConnection/search"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the outbound cross-cluster search connections for a source domain.
#
# POST /2015-01-01/es/ccs/outboundConnection/search
# Returns: record<CrossClusterSearchConnections: table<SourceDomainInfo: record, DestinationDomainInfo: record, CrossClusterSearchConnectionId: string, ConnectionAlias: string, ConnectionStatus: record>, NextToken: string>
# operationId: DescribeOutboundCrossClusterSearchConnections
export def "describe-outbound-cross-cluster-search-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: list # A list of filters used to match properties for outbound cross-cluster search connection. Available Filter names for this operation are: cross-cluster-search-connection-id destination-domain-info.domain-name destination-domain-info.owner-id destination-domain-info.region source-domain-info.domain-name — item shape: {Name?: string, Values?: list<string>}
  --body-max-results: int # Set this value to limit the number of results returned. (spec name: MaxResults)
  --body-next-token: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/ccs/outboundConnection/search"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes all packages available to Amazon ES. Includes options for filtering, limiting the number of results, and pagination.
#
# POST /2015-01-01/packages/describe
# Returns: record<PackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record>, NextToken: string>
# operationId: DescribePackages
export def "describe-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: list # A list of DescribePackagesFilter to filter the packages included in a DescribePackages response. — item shape: {Name?: "PackageID"|"PackageName"|"PackageStatus", Value?: list<string>}
  --body-max-results: int # Set this value to limit the number of results returned. (spec name: MaxResults)
  --body-next-token: string # Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/packages/describe"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists available reserved Elasticsearch instance offerings.
#
# GET /2015-01-01/es/reservedInstanceOfferings
# Returns: record<NextToken: string, ReservedElasticsearchInstanceOfferings: table<ReservedElasticsearchInstanceOfferingId: string, ElasticsearchInstanceType: string, Duration: int, FixedPrice: float, UsagePrice: float, CurrencyCode: string, PaymentOption: string, RecurringCharges: list>>
# operationId: DescribeReservedElasticsearchInstanceOfferings
export def "describe-reserved-elasticsearch-instance-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offering-id: string # The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  --max-results: int # Set this value to limit the number of results returned. If not specified, defaults to 100.
  --next-token: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/reservedInstanceOfferings"
    query: [{name: offeringId, var: offering_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offering_id: $offering_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about reserved Elasticsearch instances for this account.
#
# GET /2015-01-01/es/reservedInstances
# Returns: record<NextToken: string, ReservedElasticsearchInstances: table<ReservationName: string, ReservedElasticsearchInstanceId: string, ReservedElasticsearchInstanceOfferingId: string, ElasticsearchInstanceType: string, StartTime: string, Duration: int, FixedPrice: float, UsagePrice: float, CurrencyCode: string, ElasticsearchInstanceCount: int, State: string, PaymentOption: string, RecurringCharges: list>>
# operationId: DescribeReservedElasticsearchInstances
export def "describe-reserved-elasticsearch-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation-id: string # The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  --max-results: int # Set this value to limit the number of results returned. If not specified, defaults to 100.
  --next-token: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/reservedInstances"
    query: [{name: reservationId, var: reservation_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reservation_id: $reservation_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes one or more Amazon OpenSearch Service-managed VPC endpoints.
#
# POST /2015-01-01/es/vpcEndpoints/describe
# Returns: record<VpcEndpoints: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record, Status: string, Endpoint: string>, VpcEndpointErrors: table<VpcEndpointId: string, ErrorCode: string, ErrorMessage: string>>
# operationId: DescribeVpcEndpoints
export def "describe-vpc-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  vpc_endpoint_ids: list<string> # The unique identifiers of the endpoints to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/vpcEndpoints/describe"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcEndpointIds, var: vpc_endpoint_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, vpc_endpoint_ids: $vpc_endpoint_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dissociates a package from the Amazon ES domain.
#
# POST /2015-01-01/packages/dissociate/{PackageID}/{DomainName}
# Returns: record<DomainPackageDetails: record<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>
# operationId: DissociatePackage
export def "dissociate-package" [
  package_id: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/2015-01-01/packages/dissociate/{PackageID}/{DomainName}"
    path_params: [{name: PackageID, var: package_id}, {name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id, domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a DomainName to get all upgrade compatible Elasticsearch versions for that specific domain.
#
# GET /2015-01-01/es/compatibleVersions
# Returns: record<CompatibleElasticsearchVersions: table<SourceVersion: string, TargetVersions: list>>
# operationId: GetCompatibleElasticsearchVersions
export def "get-compatible-elasticsearch-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/compatibleVersions"
    query: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of versions of the package, along with their creation time and commit message.
#
# GET /2015-01-01/packages/{PackageID}/history
# Returns: record<PackageID: string, PackageVersionHistoryList: table<PackageVersion: string, CommitMessage: string, CreatedAt: string>, NextToken: string>
# operationId: GetPackageVersionHistory
export def "get-package-version-history" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Limits results to a maximum number of versions.
  --next-token: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/packages/{PackageID}/history"
    path_params: [{name: PackageID, var: package_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the complete history of the last 10 upgrades that were performed on the domain.
#
# GET /2015-01-01/es/upgradeDomain/{DomainName}/history
# Returns: record<UpgradeHistories: table<UpgradeName: string, StartTimestamp: string, UpgradeStatus: string, StepsList: list>, NextToken: string>
# operationId: GetUpgradeHistory
export def "get-upgrade-history" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/upgradeDomain/{DomainName}/history"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
#
# GET /2015-01-01/es/upgradeDomain/{DomainName}/status
# Returns: record<UpgradeStep: string, StepStatus: string, UpgradeName: string>
# operationId: GetUpgradeStatus
export def "get-upgrade-status" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/upgradeDomain/{DomainName}/status"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the name of all Elasticsearch domains owned by the current user's account.
#
# GET /2015-01-01/domain
# Returns: record<DomainNames: table<DomainName: string, EngineType: string>>
# operationId: ListDomainNames
export def "list-domain-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine-type: string@engine-type-completer # Optional parameter to filter the output by domain engine type. Acceptable values are 'Elasticsearch' and 'OpenSearch'.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/domain"
    query: [{name: engineType, var: engine_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    engine_type: $engine_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Amazon ES domains associated with the package.
#
# GET /2015-01-01/packages/{PackageID}/domains
# Returns: record<DomainPackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record>, NextToken: string>
# operationId: ListDomainsForPackage
export def "list-domains-for-package" [
  package_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Limits results to a maximum number of domains.
  --next-token: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/packages/{PackageID}/domains"
    path_params: [{name: PackageID, var: package_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    package_id: $package_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Elasticsearch instance types that are supported for given ElasticsearchVersion
#
# GET /2015-01-01/es/instanceTypes/{ElasticsearchVersion}
# Returns: record<ElasticsearchInstanceTypes: list<string>, NextToken: string>
# operationId: ListElasticsearchInstanceTypes
export def "list-elasticsearch-instance-types" [
  elasticsearch_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # DomainName represents the name of the Domain that we are trying to modify. This should be present only if we are querying for list of available Elasticsearch instance types when modifying existing domain.
  --max-results: int # Set this value to limit the number of results returned. Value provided must be greater than 30 else it wont be honored.
  --next-token: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/instanceTypes/{ElasticsearchVersion}"
    path_params: [{name: ElasticsearchVersion, var: elasticsearch_version}]
    query: [{name: domainName, var: domain_name}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    elasticsearch_version: $elasticsearch_version, domain_name: $domain_name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all supported Elasticsearch versions
#
# GET /2015-01-01/es/versions
# Returns: record<ElasticsearchVersions: list<string>, NextToken: string>
# operationId: ListElasticsearchVersions
export def "list-elasticsearch-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Set this value to limit the number of results returned. Value provided must be greater than 10 else it wont be honored.
  --next-token: string
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/versions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all packages associated with the Amazon ES domain.
#
# GET /2015-01-01/domain/{DomainName}/packages
# Returns: record<DomainPackageDetailsList: table<PackageID: string, PackageName: string, PackageType: string, LastUpdated: string, DomainName: string, DomainPackageStatus: string, PackageVersion: string, ReferencePath: string, ErrorDetails: record>, NextToken: string>
# operationId: ListPackagesForDomain
export def "list-packages-for-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Limits results to a maximum number of packages.
  --next-token: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/domain/{DomainName}/packages"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all tags for the given Elasticsearch domain.
#
# GET /2015-01-01/tags/
# Returns: record<TagList: table<Key: string, Value: string>>
# operationId: ListTags
export def "list-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string # Specify the ARN for the Elasticsearch domain to which the tags are attached that you want to view. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/tags/"
    query: [{name: arn, var: arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about each principal that is allowed to access a given Amazon OpenSearch Service domain through the use of an interface VPC endpoint.
#
# GET /2015-01-01/es/domain/{DomainName}/listVpcEndpointAccess
# Returns: record<AuthorizedPrincipalList: table<PrincipalType: string, Principal: string>, NextToken: string>
# operationId: ListVpcEndpointAccess
export def "list-vpc-endpoint-access" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Provides an identifier to allow retrieval of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/domain/{DomainName}/listVpcEndpointAccess"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all Amazon OpenSearch Service-managed VPC endpoints associated with a particular domain.
#
# GET /2015-01-01/es/domain/{DomainName}/vpcEndpoints
# Returns: record<VpcEndpointSummaryList: table<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, Status: string>, NextToken: string>
# operationId: ListVpcEndpointsForDomain
export def "list-vpc-endpoints-for-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Provides an identifier to allow retrieval of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/2015-01-01/es/domain/{DomainName}/vpcEndpoints"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to purchase reserved Elasticsearch instances.
#
# POST /2015-01-01/es/purchaseReservedInstanceOffering
# Returns: record<ReservedElasticsearchInstanceId: string, ReservationName: string>
# operationId: PurchaseReservedElasticsearchInstanceOffering
export def "purchase-reserved-elasticsearch-instance-offering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  reserved_elasticsearch_instance_offering_id: string # The ID of the reserved Elasticsearch instance offering to purchase.
  reservation_name: string # A customer-specified identifier to track this reservation.
  --instance-count: int # Specifies the number of EC2 instances in the Elasticsearch domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/purchaseReservedInstanceOffering"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReservedElasticsearchInstanceOfferingId, var: reserved_elasticsearch_instance_offering_id}, {name: ReservationName, var: reservation_name}, {name: InstanceCount, var: instance_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, reserved_elasticsearch_instance_offering_id: $reserved_elasticsearch_instance_offering_id, reservation_name: $reservation_name, instance_count: $instance_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the destination domain owner to reject an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/reject
# Returns: record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: string, ConnectionStatus: record<StatusCode: string, Message: string>>>
# operationId: RejectInboundCrossClusterSearchConnection
export def "reject-inbound-cross-cluster-search-connection" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/2015-01-01/es/ccs/inboundConnection/{ConnectionId}/reject"
    path_params: [{name: ConnectionId, var: connection_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connection_id: $connection_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified set of tags from the specified Elasticsearch domain.
#
# POST /2015-01-01/tags-removal
# operationId: RemoveTags
export def "remove-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  arn: string # The Amazon Resource Name (ARN) of the Elasticsearch domain. See Identifiers for IAM Entities (http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html) in Using AWS Identity and Access Management for more information.
  tag_keys: list<string> # Specifies the TagKey list which you want to remove from the Elasticsearch domain.
]: any -> any {
  $in | http-request {
    method: post
    path: "/2015-01-01/tags-removal"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ARN, var: arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, arn: $arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes access to an Amazon OpenSearch Service domain that was provided through an interface VPC endpoint.
#
# POST /2015-01-01/es/domain/{DomainName}/revokeVpcEndpointAccess
# Returns: record
# operationId: RevokeVpcEndpointAccess
export def "revoke-vpc-endpoint-access" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  account: string # The account ID to revoke access from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/domain/{DomainName}/revokeVpcEndpointAccess"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Account, var: account}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedules a service software update for an Amazon ES domain.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/start
# Returns: record<ServiceSoftwareOptions: record<CurrentVersion: string, NewVersion: string, UpdateAvailable: bool, Cancellable: bool, UpdateStatus: string, Description: string, AutomatedUpdateDate: string, OptionalDeployment: bool>>
# operationId: StartElasticsearchServiceSoftwareUpdate
export def "start-elasticsearch-service-software-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/serviceSoftwareUpdate/start"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages/update
# Returns: record<PackageDetails: record<PackageID: string, PackageName: string, PackageType: string, PackageDescription: string, PackageStatus: string, CreatedAt: string, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>>
# operationId: UpdatePackage
export def "update-package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  package_id: string # Unique identifier for the package.
  package_source: record # The S3 location for importing the package specified as S3BucketName and S3Key — shape: {S3BucketName?: string, S3Key?: string}
  --package-description: string # New description of the package.
  --commit-message: string # An info message for the new version which will be shown as part of GetPackageVersionHistoryResponse.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/packages/update"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PackageID, var: package_id}, {name: PackageSource, var: package_source}, {name: PackageDescription, var: package_description}, {name: CommitMessage, var: commit_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, package_id: $package_id, package_source: $package_source, package_description: $package_description, commit_message: $commit_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an Amazon OpenSearch Service-managed interface VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints/update
# Returns: record<VpcEndpoint: record<VpcEndpointId: string, VpcEndpointOwner: string, DomainArn: string, VpcOptions: record<VPCId: string, SubnetIds: list, AvailabilityZones: list, SecurityGroupIds: list>, Status: string, Endpoint: string>>
# operationId: UpdateVpcEndpoint
export def "update-vpc-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  vpc_endpoint_id: string # Unique identifier of the VPC endpoint to be updated.
  vpc_options: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see VPC Endpoints for Amazon Elasticsearch Service Domains (http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html). — shape: {SubnetIds?: list<string>, SecurityGroupIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/vpcEndpoints/update"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: VpcEndpointId, var: vpc_endpoint_id}, {name: VpcOptions, var: vpc_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, vpc_endpoint_id: $vpc_endpoint_id, vpc_options: $vpc_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
#
# POST /2015-01-01/es/upgradeDomain
# Returns: record<DomainName: string, TargetVersion: string, PerformCheckOnly: bool, ChangeProgressDetails: record<ChangeId: string, Message: string>>
# operationId: UpgradeElasticsearchDomain
export def "upgrade-elasticsearch-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  target_version: string # The version of Elasticsearch that you intend to upgrade the domain to.
  --perform-check-only: oneof<nothing, bool> # This flag, when set to True, indicates that an Upgrade Eligibility Check needs to be performed. This will not actually perform the Upgrade.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2015-01-01/es/upgradeDomain"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: TargetVersion, var: target_version}, {name: PerformCheckOnly, var: perform_check_only}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name, target_version: $target_version, perform_check_only: $perform_check_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
